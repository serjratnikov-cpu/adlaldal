return function(S, LP, Players, ws, RS, Camera, Color3RGB, V3new, CFnew, mathhuge, pcall, task, table_insert, string_find, string_lower, tostring, mathfloor)

local SD = {}

SD.AutoFarmActive = false
SD.AutoFarmStatus = "Idle"
SD.AutoFarmLaps = 0
SD.AutoFarmEarned = 0
SD.PoliceESP = false
SD.AimCivilian = false
SD.AimPolice = false

local policeHighlights = {}
local statusLabel = nil
local currentFlyCleanup = nil
local lastHrpPos = nil -- Для Anti-Cheat детекции

local TEAM_NAMES_POLICE = {
    "police","border patrol","fbi","swat","bortac","army",
    "sheriff","trooper","marshal","officer","cop","patrol"
}

-- =============================================
-- КОНКРЕТНЫЕ КООРДИНАТЫ ДЛЯ SAN DIEGO BORDER RP
-- (Buy → через тоннель → Sell на крыше → Launder)
-- =============================================

-- Маршрут V1 (Кольца — туннель — крыша — прачечная)
local ROUTE_V1 = {
    BUY  = {name="Black Market Goods", keywords={"BlackMarketGoods","Black Market Goods","GoodsShop","BlackMarket"}},
    SELL = {name="Smuggled Goods Seller", keywords={"SmuggledGoodsSeller","Smuggled Goods Seller","SmuggleNPC","GoodsSeller","Seller"}},
    LAUNDER = {name="Laundromat", keywords={"Laundromat","LAUNDROMAT","LaunderCash","Launder","WashingMachine","Washing Machine","CashDrop","Cash Drop"}},
    TUNNEL = {name="Tunnel", keywords={"Tunnel","TunnelEntrance","UndergroundTunnel","SecretTunnel","TunnelExit"}},
}

-- Товары от самых выгодных к дешёвым
local GOODS_PRIORITY = {
    {name="Fake Diamond Ring", buyAction="Buy", profit=1500},
    {name="Gold Watch",       buyAction="Buy", profit=1200},
    {name="Diamond",          buyAction="Buy", profit=1000},
    {name="Electronics",      buyAction="Buy", profit=800},
    {name="Avocado",          buyAction="Buy", profit=240},
}

-- =============================================
-- УТИЛИТЫ
-- =============================================

local function isPolice(player)
    if not player then return false end
    local team = player.Team
    if team then
        local tLow = team.Name:lower()
        for _, n in ipairs(TEAM_NAMES_POLICE) do
            if string_find(tLow, n) then return true end
        end
    end
    local ch = player.Character
    if ch then
        for _, desc in ipairs(ch:GetDescendants()) do
            if (desc:IsA("Accessory") or desc:IsA("Shirt") or desc:IsA("Pants")) then
                local dLow = desc.Name:lower()
                for _, n in ipairs(TEAM_NAMES_POLICE) do
                    if string_find(dLow, n) then return true end
                end
            end
        end
        local function checkTools(container)
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    local tLow = tool.Name:lower()
                    if string_find(tLow,"taser") or string_find(tLow,"handcuff") or string_find(tLow,"baton") or string_find(tLow,"badge") then
                        return true
                    end
                end
            end
            return false
        end
        if checkTools(ch) then return true end
        local bp = player:FindFirstChild("Backpack")
        if bp and checkTools(bp) then return true end
    end
    return false
end

function SD.shouldAimAt(player)
    if not player or player == LP then return false end
    if S.AimCivilian and not S.AimPolice then return not isPolice(player)
    elseif S.AimPolice and not S.AimCivilian then return isPolice(player)
    elseif S.AimCivilian and S.AimPolice then return true end
    return true
end

-- =============================================
-- POLICE ESP
-- =============================================

function SD.updatePoliceESP()
    for _, hl in pairs(policeHighlights) do pcall(function() hl:Destroy() end) end
    policeHighlights = {}
    if not S.PoliceESP then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isPolice(p) then
            local ch = p.Character
            if ch then
                local hum = ch:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local hl = Instance.new("Highlight")
                    hl.Name = "JG_PoliceESP"
                    hl.Adornee = ch
                    hl.Parent = ch
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.FillColor = Color3RGB(30, 100, 255)
                    hl.OutlineColor = Color3RGB(0, 60, 200)
                    hl.FillTransparency = 0.45
                    hl.OutlineTransparency = 0
                    policeHighlights[p] = hl
                end
            end
        end
    end
end

function SD.clearPoliceESP()
    for _, hl in pairs(policeHighlights) do pcall(function() hl:Destroy() end) end
    policeHighlights = {}
end

-- =============================================
-- СТАТУС
-- =============================================

local function setStatus(text)
    SD.AutoFarmStatus = text
    if statusLabel then pcall(function() statusLabel.Text = "Статус: " .. text end) end
end

-- =============================================
-- ПОЛЁТ (с Anti-Cheat: ground-touch и ограничение скорости)
-- =============================================

local function stopCurrentFly()
    if currentFlyCleanup then
        pcall(function() currentFlyCleanup() end)
        currentFlyCleanup = nil
    end
end

local function flyTo(targetPos, speed)
    stopCurrentFly()
    local ch = LP.Character
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    speed = speed or (S.AutoFarmSpeed or 170)
    if speed > 300 then speed = 300 end

    local alive = true
    local groundTimer = 0
    local GROUND_EVERY = 3.0 -- Каждые 3 сек касание земли (Anti-Cheat)
    local stepCount = 0

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {ch}

    -- Noclip: убираем коллизию чтобы не застревать
    local noclipConn = RS.Stepped:Connect(function()
        if not alive then return end
        pcall(function()
            if ch and ch.Parent then
                for _, p in pairs(ch:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end)

    currentFlyCleanup = function()
        alive = false
        pcall(function() noclipConn:Disconnect() end)
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
    end

    -- Запоминаем стартовую позицию для Anti-Cheat
    lastHrpPos = hrp.Position

    while alive and SD.AutoFarmActive do
        if not ch or not ch.Parent or not hrp or not hrp.Parent then break end
        if not hum or hum.Health <= 0 then break end

        local myPos = hrp.Position
        local totalDist = (myPos - targetPos).Magnitude
        if totalDist < 6 then break end

        local dir = (targetPos - myPos).Unit

        -- Обход стен: raycast вперёд
        local wallCheck = ws:Raycast(myPos, dir * 10, rayParams)
        if wallCheck then
            dir = (V3new(dir.X, 0.7, dir.Z)).Unit
        end

        local dt = task.wait()
        if dt > 0.05 then dt = 0.05 end
        groundTimer = groundTimer + dt
        stepCount = stepCount + 1

        local step = speed * dt
        local maxStep = math.min(totalDist, 55)
        if step > maxStep then step = maxStep end

        local newPos = myPos + dir * step

        -- Anti-Cheat: периодически касаемся земли
        if groundTimer >= GROUND_EVERY then
            local hit = ws:Raycast(myPos + V3new(0, 10, 0), V3new(0, -200, 0), rayParams)
            if hit then
                local groundY = hit.Position.Y + 3.5
                if math.abs(myPos.Y - groundY) < 80 then
                    local tempPos = V3new(myPos.X, groundY, myPos.Z)
                    hrp.CFrame = CFnew(tempPos, tempPos + (targetPos - tempPos).Unit)
                    hum:ChangeState(Enum.HumanoidStateType.Landed)
                    pcall(function() hrp.AssemblyLinearVelocity = V3new(0,0,0) end)
                    task.wait(0.06)
                end
            else
                hum:ChangeState(Enum.HumanoidStateType.Freefall)
            end
            groundTimer = 0
        else
            if stepCount % 4 == 0 then
                hum:ChangeState(Enum.HumanoidStateType.Freefall)
            end
        end

        hrp.CFrame = CFnew(newPos, newPos + (targetPos - newPos).Unit)
        pcall(function() hrp.Velocity = V3new(0, 0, 0) end)
        pcall(function() hrp.AssemblyLinearVelocity = V3new(0, 0, 0) end)
        pcall(function() hrp.AssemblyAngularVelocity = V3new(0, 0, 0) end)

        -- Anti-Cheat: детекция rollback (если нас телепортнуло назад)
        if lastHrpPos then
            local rollbackDist = (hrp.Position - lastHrpPos).Magnitude
            -- Если за 1 кадр нас кинуло куда-то далеко (>100) = ролбэк
            if rollbackDist > 100 and stepCount > 5 then
                setStatus("⚠ Anti-Cheat rollback! Перезапуск...")
                alive = false
                -- Убиваем персонажа и перезапускаем
                pcall(function() hum.Health = 0 end)
                task.wait(3)
                break
            end
        end
        lastHrpPos = hrp.Position
    end

    stopCurrentFly()
end

-- =============================================
-- ПРОМПТЫ И NPC
-- =============================================

local function fireProximityPrompt(prompt)
    if not prompt then return end
    pcall(function()
        local oldDist = prompt.MaxActivationDistance
        local oldReq = prompt.RequiresLineOfSight
        prompt.MaxActivationDistance = 9999
        prompt.RequiresLineOfSight = false
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.25)
        prompt.MaxActivationDistance = oldDist
        prompt.RequiresLineOfSight = oldReq
    end)
end

local function waitAndFirePrompt(prompt, attempts)
    attempts = attempts or 5
    for i = 1, attempts do
        if not prompt or not prompt.Parent then break end
        if not SD.AutoFarmActive then break end
        fireProximityPrompt(prompt)
        task.wait(0.35)
    end
end

local function findInWorkspace(name)
    local nameLow = name:lower()
    for _, child in ipairs(ws:GetDescendants()) do
        if child.Name == name or string_find(child.Name:lower(), nameLow) then
            return child
        end
    end
    return nil
end

local function findNPC(name)
    local nameLow = name:lower()
    for _, child in ipairs(ws:GetDescendants()) do
        if child:IsA("Model") and (child.Name == name or string_find(child.Name:lower(), nameLow)) then
            if child:FindFirstChildOfClass("Humanoid") then return child end
        end
    end
    return nil
end

local function findProximityPrompt(parent, actionText)
    if not parent then return nil end
    for _, desc in ipairs(parent:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            if not actionText then return desc end
            local actLow = actionText:lower()
            if desc.ActionText and string_find(desc.ActionText:lower(), actLow) then return desc end
            if desc.ObjectText and string_find(desc.ObjectText:lower(), actLow) then return desc end
        end
    end
    return nil
end

local function findAllPrompts(name)
    local results = {}
    local nameLow = name:lower()
    for _, desc in ipairs(ws:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            local at = (desc.ActionText or ""):lower()
            local ot = (desc.ObjectText or ""):lower()
            local pn = (desc.Parent and desc.Parent.Name or ""):lower()
            if string_find(at, nameLow) or string_find(ot, nameLow) or string_find(pn, nameLow) then
                table_insert(results, desc)
            end
        end
    end
    return results
end

local function getPartPosition(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local hrp = obj:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp.Position end
        local prim = obj.PrimaryPart
        if prim then return prim.Position end
        local bp = obj:FindFirstChildWhichIsA("BasePart")
        if bp then return bp.Position end
    end
    return nil
end

local function getFrontPosition(obj, dist)
    dist = dist or 5
    if not obj then return nil end
    local cf = nil
    if obj:IsA("BasePart") then cf = obj.CFrame
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then cf = obj.PrimaryPart.CFrame
        elseif obj:FindFirstChild("HumanoidRootPart") then cf = obj.HumanoidRootPart.CFrame
        else local bp = obj:FindFirstChildWhichIsA("BasePart") if bp then cf = bp.CFrame end end
    end
    if cf then return (cf + cf.LookVector * dist).Position end
    return getPartPosition(obj)
end

local function findAreaObj(keywords)
    for _, name in ipairs(keywords) do
        local found = findInWorkspace(name)
        if found then return found end
    end
    return nil
end

local function findAreaPosition(keywords)
    local obj = findAreaObj(keywords)
    if obj then return getPartPosition(obj) end
    return nil
end

local function flyToObj(obj)
    if not obj then return end
    local pos = getFrontPosition(obj, 4) or getPartPosition(obj)
    if not pos then return end
    local ch = LP.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") then return end
    if (ch.HumanoidRootPart.Position - pos).Magnitude > 6 then
        flyTo(pos, S.AutoFarmSpeed or 170)
        task.wait(0.3)
    end
end

-- =============================================
-- REMOTE EVENTS
-- =============================================

local function tryFireRemote(name, ...)
    local args = table.pack(...)
    local rs = game:GetService("ReplicatedStorage")
    for _, child in ipairs(rs:GetDescendants()) do
        if child:IsA("RemoteEvent") and (child.Name == name or string_find(child.Name:lower(), name:lower())) then
            pcall(function() child:FireServer(table.unpack(args, 1, args.n)) end)
            return true
        end
    end
    return false
end

local function tryFireRemoteFunction(name, ...)
    local args = table.pack(...)
    local rs = game:GetService("ReplicatedStorage")
    for _, child in ipairs(rs:GetDescendants()) do
        if child:IsA("RemoteFunction") and (child.Name == name or string_find(child.Name:lower(), name:lower())) then
            local ok, res = pcall(function() return child:InvokeServer(table.unpack(args, 1, args.n)) end)
            if ok then return true, res end
        end
    end
    return false
end

-- =============================================
-- GUI КНОПКИ
-- =============================================

local function findButtonInGUI(buttonName)
    local pg = LP.PlayerGui
    if not pg then return nil end
    local bLow = buttonName:lower()
    for _, gui in ipairs(pg:GetDescendants()) do
        if (gui:IsA("TextButton") or gui:IsA("ImageButton")) then
            local vis = true
            pcall(function() vis = gui.Visible end)
            if vis then
                if gui.Name and string_find(gui.Name:lower(), bLow) then return gui end
                if gui:IsA("TextButton") and gui.Text and string_find(gui.Text:lower(), bLow) then return gui end
            end
        end
    end
    return nil
end

local function clickButton(btn)
    if not btn then return false end
    local ok = false
    pcall(function() if firesignal then firesignal(btn.MouseButton1Click) ok = true end end)
    pcall(function() if firesignal then firesignal(btn.Activated) end end)
    if not ok then pcall(function() btn.MouseButton1Click:Fire() ok = true end) end
    return ok
end

local function clickAllGUIButtons(name)
    local pg = LP.PlayerGui
    if not pg then return false end
    local bLow = name:lower()
    local found = false
    for _, gui in ipairs(pg:GetDescendants()) do
        if (gui:IsA("TextButton") or gui:IsA("ImageButton")) then
            local vis = true
            pcall(function() vis = gui.Visible end)
            if vis then
                local match = false
                if gui.Name and string_find(gui.Name:lower(), bLow) then match = true end
                if gui:IsA("TextButton") and gui.Text and string_find(gui.Text:lower(), bLow) then match = true end
                if match then clickButton(gui) found = true end
            end
        end
    end
    return found
end

-- =============================================
-- NPC ВЗАИМОДЕЙСТВИЕ
-- =============================================

local function approachAndFire(target, actionText)
    if not target then return false end
    local pos = getFrontPosition(target, 4) or getPartPosition(target)
    if not pos then return false end

    local ch = LP.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    if (hrp.Position - pos).Magnitude > 6 then
        flyTo(pos, S.AutoFarmSpeed or 170)
        task.wait(0.3)
    end

    local pp = findProximityPrompt(target, actionText)
        or findProximityPrompt(target, nil)
    if not pp and target.Parent then
        pp = findProximityPrompt(target.Parent, actionText)
            or findProximityPrompt(target.Parent, nil)
    end

    if pp then
        waitAndFirePrompt(pp, 5)
        return true
    end
    return false
end

-- =============================================
-- ФАРМ: ПОКУПКА (самые выгодные товары)
-- =============================================

local function buyGoods()
    setStatus("Покупка товаров...")
    local bought = false

    -- Ищем NPC/магазин
    local shopObj = findAreaObj(ROUTE_V1.BUY.keywords)
    if shopObj then
        flyToObj(shopObj)
        task.wait(0.3)
    end

    -- Покупаем самый выгодный товар по приоритету
    for _, goods in ipairs(GOODS_PRIORITY) do
        if bought then break end
        if not SD.AutoFarmActive then return false end

        -- Через промпт
        local prompts = findAllPrompts(goods.name)
        for _, pp in ipairs(prompts) do
            if bought then break end
            local par = pp.Parent
            if par then
                flyToObj(par)
                task.wait(0.2)
                -- Покупаем 5 штук
                for i = 1, 5 do
                    if not SD.AutoFarmActive then return false end
                    setStatus("Покупка " .. goods.name .. " " .. i .. "/5")
                    fireProximityPrompt(pp)
                    task.wait(0.4)
                end
                bought = true
            end
        end

        -- Через NPC с именем товара
        if not bought then
            local target = findNPC(goods.name)
            if not target then target = findInWorkspace(goods.name) end
            if target then
                bought = approachAndFire(target, goods.buyAction)
            end
        end
    end

    -- Пробуем generic подход
    if not bought then
        local buyTargets = {{"BlackMarketGoods","Buy"},{"Black Market","Buy"},{"Market","Buy"},{"Shop","Buy"},{"Ring","Buy"}}
        for _, pair in ipairs(buyTargets) do
            if bought then break end
            local target = findNPC(pair[1])
            if not target then target = findInWorkspace(pair[1]) end
            if target then bought = approachAndFire(target, pair[2]) end
        end
    end

    -- Через Remote
    if not bought then
        local remotes = {"BuyRing","PurchaseRing","BuyItem","Purchase","BuyGoods","Buy"}
        for _, rn in ipairs(remotes) do
            if tryFireRemote(rn, "Fake Diamond Ring") then bought = true break end
        end
    end

    -- Через GUI
    if not bought then
        local btn = findButtonInGUI("Buy") or findButtonInGUI("Purchase")
        if btn then clickButton(btn) bought = true end
    end

    return bought
end

-- =============================================
-- ФАРМ: ПРОДАЖА
-- =============================================

local function sellGoods()
    setStatus("Продажа товаров...")
    local sold = false

    local sellerObj = findAreaObj(ROUTE_V1.SELL.keywords)
    if sellerObj then
        flyToObj(sellerObj)
        task.wait(0.3)
    end

    local sellerNames = {"Smuggled Goods Seller","SmuggledGoodsSeller","GoodsSeller","Seller","Sell"}
    for _, sn in ipairs(sellerNames) do
        if sold then break end
        local target = findNPC(sn) or findInWorkspace(sn)
        if target then sold = approachAndFire(target, "sell") end
    end

    if not sold then
        local prompts = findAllPrompts("sell")
        for _, pp in ipairs(prompts) do
            if sold then break end
            local par = pp.Parent
            if par then flyToObj(par) task.wait(0.2) waitAndFirePrompt(pp, 4) sold = true end
        end
    end

    if not sold then
        for _, rn in ipairs({"SellGoods","Sell","SellItem","SellAll"}) do
            if tryFireRemote(rn) then sold = true break end
        end
    end

    if not sold then
        local btn = findButtonInGUI("Sell")
        if btn then clickButton(btn) sold = true end
    end

    if sold then
        task.wait(0.4)
        for _, bName in ipairs({"sell","confirm","yes","accept","ok"}) do
            clickAllGUIButtons(bName)
            task.wait(0.25)
        end
    end
    return sold
end

-- =============================================
-- ФАРМ: ОТМЫВКА
-- =============================================

local function launderMoney()
    setStatus("Отмывка денег...")
    local done = false

    local launderObj = findAreaObj(ROUTE_V1.LAUNDER.keywords)
    if launderObj then
        flyToObj(launderObj)
        task.wait(0.3)
    end

    for _, pName in ipairs({"Cash Drop","Launder Cash","Launder","Wash"}) do
        if done then break end
        local prompts = findAllPrompts(pName)
        for _, pp in ipairs(prompts) do
            if done then break end
            local par = pp.Parent
            if par then
                flyToObj(par)
                task.wait(0.2)
                waitAndFirePrompt(pp, 5)
                done = true
            end
        end
    end

    if not done then
        for _, ln in ipairs(ROUTE_V1.LAUNDER.keywords) do
            if done then break end
            local obj = findInWorkspace(ln)
            if obj then
                done = approachAndFire(obj, "launder") or approachAndFire(obj, "wash") or approachAndFire(obj, nil)
            end
        end
    end

    if not done then
        for _, rn in ipairs({"Launder","LaunderMoney","WashMoney","MoneyWash","LaunderCash"}) do
            if tryFireRemote(rn) then done = true break end
        end
    end

    if not done then
        local btn = findButtonInGUI("Launder") or findButtonInGUI("Wash")
        if btn then clickButton(btn) task.wait(0.4) clickButton(btn) done = true end
    end

    if done then
        task.wait(0.4)
        for _, bName in ipairs({"launder","confirm","yes","accept","ok"}) do
            clickAllGUIButtons(bName)
            task.wait(0.25)
        end
    end
    return done
end

-- =============================================
-- ГЛАВНЫЙ ЦИКЛ ФАРМА
-- =============================================

local function doSmuggleCycle()
    if not SD.AutoFarmActive then return end

    -- 1. Летим к магазину и покупаем
    setStatus("Лечу к магазину...")
    local marketPos = findAreaPosition(ROUTE_V1.BUY.keywords)
    if marketPos then
        flyTo(marketPos, S.AutoFarmSpeed or 170)
        task.wait(0.4)
    end

    if not SD.AutoFarmActive then return end
    buyGoods()
    task.wait(0.4)

    -- 2. Летим через тоннель/к границе (ищем тоннель)
    if not SD.AutoFarmActive then return end
    setStatus("Пересекаю границу...")
    local tunnelPos = findAreaPosition(ROUTE_V1.TUNNEL.keywords)
    if tunnelPos then
        flyTo(tunnelPos, S.AutoFarmSpeed or 170)
        task.wait(0.5)
    end

    -- 3. Летим к продавцу и продаём
    if not SD.AutoFarmActive then return end
    setStatus("Лечу к продавцу...")
    local sellerPos = findAreaPosition(ROUTE_V1.SELL.keywords)
    if sellerPos then
        flyTo(sellerPos, S.AutoFarmSpeed or 170)
        task.wait(0.4)
    end

    if not SD.AutoFarmActive then return end
    sellGoods()
    task.wait(0.4)

    -- 4. Летим к прачечной и отмываем
    if not SD.AutoFarmActive then return end
    setStatus("Лечу отмывать...")
    launderMoney()
    task.wait(0.4)

    SD.AutoFarmLaps = SD.AutoFarmLaps + 1
    setStatus("Круг #" .. SD.AutoFarmLaps .. " ✅ завершён!")
end

-- =============================================
-- УПРАВЛЕНИЕ ФАРМОМ
-- =============================================

function SD.startAutoFarm()
    if SD.AutoFarmActive then return end
    SD.AutoFarmActive = true
    SD.AutoFarmLaps = 0
    setStatus("Запуск...")
    task.spawn(function()
        while SD.AutoFarmActive do
            local ok, err = pcall(function() doSmuggleCycle() end)
            if not ok then
                setStatus("Ошибка цикла, повтор через 3с...")
                task.wait(3)
            end
            if not SD.AutoFarmActive then break end
            task.wait(1.5)
        end
        stopCurrentFly()
        setStatus("Остановлено")
    end)
end

function SD.stopAutoFarm()
    SD.AutoFarmActive = false
    stopCurrentFly()
    setStatus("Остановлено")
end

-- =============================================
-- ИГРОКИ
-- =============================================

function SD.getPlayerListFiltered(searchText)
    local result = {}
    searchText = (searchText or ""):lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local ch = p.Character
            if ch then
                if searchText == "" or string_find(p.Name:lower(), searchText) or string_find(p.DisplayName:lower(), searchText) then
                    table_insert(result, {
                        player = p,
                        name = p.Name,
                        displayName = p.DisplayName,
                        role = isPolice(p) and "Police" or "Civilian",
                        character = ch
                    })
                end
            end
        end
    end
    table.sort(result, function(a, b) return a.name:lower() < b.name:lower() end)
    return result
end

function SD.teleportToPlayer(playerName)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == playerName or p.DisplayName == playerName then
            local ch = p.Character
            if ch then
                local hrp = ch:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local myCh = LP.Character
                    if myCh then
                        local myHrp = myCh:FindFirstChild("HumanoidRootPart")
                        if myHrp then
                            myHrp.CFrame = CFnew(hrp.Position + V3new(0, 0, -5))
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

function SD.setStatusLabel(label) statusLabel = label end

local policeESPTick = 0
function SD.heartbeat()
    policeESPTick = policeESPTick + 1
    if policeESPTick >= 30 then
        policeESPTick = 0
        if S.PoliceESP then SD.updatePoliceESP() else SD.clearPoliceESP() end
    end
end

function SD.cleanup()
    SD.stopAutoFarm()
    SD.clearPoliceESP()
    stopCurrentFly()
end

return SD
end
