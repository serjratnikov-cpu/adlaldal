return function(S, LP, Players, ws, RS, Camera, Color3RGB, V3new, CFnew, mathhuge, pcall, task, table_insert, string_find, string_lower, tostring, mathfloor)

local SD = {}

SD.AutoFarmActive = false
SD.AutoFarmStatus = "Idle"
SD.AutoFarmLaps = 0
SD.PoliceESP = false
SD.AimCivilian = false
SD.AimPolice = false

local policeHighlights = {}
local statusLabel = nil
local currentFlyCleanup = nil

local TEAM_NAMES_POLICE = {
    "police","border patrol","fbi","swat","bortac","army",
    "sheriff","trooper","marshal","officer","cop","patrol"
}

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
            if desc:IsA("Accessory") or desc:IsA("Shirt") or desc:IsA("Pants") then
                local dLow = desc.Name:lower()
                for _, n in ipairs(TEAM_NAMES_POLICE) do
                    if string_find(dLow, n) then return true end
                end
            end
        end
        for _, tool in ipairs(ch:GetChildren()) do
            if tool:IsA("Tool") then
                local tLow = tool.Name:lower()
                if string_find(tLow,"taser") or string_find(tLow,"handcuff") or string_find(tLow,"baton") or string_find(tLow,"badge") then
                    return true
                end
            end
        end
    end
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                local tLow = tool.Name:lower()
                if string_find(tLow,"taser") or string_find(tLow,"handcuff") or string_find(tLow,"baton") or string_find(tLow,"badge") then
                    return true
                end
            end
        end
    end
    return false
end

local function isCivilian(player)
    if not player then return false end
    return not isPolice(player)
end

function SD.shouldAimAt(player)
    if not player or player == LP then return false end
    if S.AimCivilian and not S.AimPolice then return isCivilian(player)
    elseif S.AimPolice and not S.AimCivilian then return isPolice(player)
    elseif S.AimCivilian and S.AimPolice then return true end
    return true
end

function SD.updatePoliceESP()
    for p, hl in pairs(policeHighlights) do pcall(function() if hl then hl:Destroy() end end) end
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
    for p, hl in pairs(policeHighlights) do pcall(function() if hl then hl:Destroy() end end) end
    policeHighlights = {}
end

local function setStatus(text)
    SD.AutoFarmStatus = text
    if statusLabel then pcall(function() statusLabel.Text = "Статус: " .. text end) end
end

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

    speed = speed or (S.AutoFarmSpeed or 300)
    if speed > 300 then speed = 300 end

    local alive = true
    local groundTimer = 0
    local GROUND_EVERY = 3.5
    local stepCount = 0

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {ch}

    local noclipConn = RS.Stepped:Connect(function()
        if not alive then return end
        pcall(function()
            if ch and ch.Parent then
                for _, p in pairs(ch:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.CanCollide = false
                    end
                end
            end
        end)
    end)

    currentFlyCleanup = function()
        alive = false
        pcall(function() noclipConn:Disconnect() end)
        pcall(function()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
    end

    -- Предварительный подъём перед полётом
    local startPos = hrp.Position
    local upPos = startPos + V3new(0, 25, 0)
    for i = 1, 20 do
        if not alive or not SD.AutoFarmActive then break end
        if not hrp or not hrp.Parent then break end
        local cur = hrp.Position
        local d = (cur - upPos).Magnitude
        if d < 3 then break end
        local udir = (upPos - cur).Unit
        local udt = task.wait()
        if udt > 0.05 then udt = 0.05 end
        local ustep = speed * udt
        if ustep > d then ustep = d end
        hrp.CFrame = CFnew(cur + udir * ustep, cur + udir * ustep + (targetPos - cur).Unit)
        pcall(function() hrp.AssemblyLinearVelocity = V3new(0,0,0) end)
        hum:ChangeState(Enum.HumanoidStateType.Freefall)
    end

    while alive and SD.AutoFarmActive do
        if not ch or not ch.Parent or not hrp or not hrp.Parent then break end

        local myPos = hrp.Position
        local totalDist = (myPos - targetPos).Magnitude
        if totalDist < 5 then break end

        local dir = (targetPos - myPos).Unit
        local dt = task.wait()
        if dt > 0.05 then dt = 0.05 end
        groundTimer = groundTimer + dt
        stepCount = stepCount + 1

        -- Обход препятствий: вперёд, вверх, влево, вправо
        local wallFwd = ws:Raycast(myPos, dir * 10, rayParams)
        if wallFwd then
            -- Пробуем вверх
            local upDir = V3new(dir.X, 0.8, dir.Z).Unit
            local wallUp = ws:Raycast(myPos, upDir * 10, rayParams)
            if not wallUp then
                dir = upDir
            else
                -- Пробуем вправо
                local rightDir = V3new(dir.Z, 0, -dir.X).Unit
                local wallRight = ws:Raycast(myPos, rightDir * 10, rayParams)
                if not wallRight then
                    dir = V3new(rightDir.X, 0.4, rightDir.Z).Unit
                else
                    -- Пробуем влево
                    local leftDir = V3new(-dir.Z, 0, dir.X).Unit
                    local wallLeft = ws:Raycast(myPos, leftDir * 10, rayParams)
                    if not wallLeft then
                        dir = V3new(leftDir.X, 0.4, leftDir.Z).Unit
                    else
                        -- Всё заблокировано — идём вверх принудительно
                        dir = V3new(0, 1, 0)
                    end
                end
            end
        end

        local step = speed * dt
        local maxStep = math.min(totalDist, 60)
        if step > maxStep then step = maxStep end

        local newPos = myPos + dir * step

        if groundTimer >= GROUND_EVERY then
            local hit = ws:Raycast(myPos + V3new(0, 10, 0), V3new(0, -150, 0), rayParams)
            if hit then
                local groundY = hit.Position.Y + 3.0
                if math.abs(myPos.Y - groundY) < 60 then
                    local tempPos = V3new(myPos.X, groundY, myPos.Z)
                    hrp.CFrame = CFnew(tempPos, tempPos + (targetPos - tempPos).Unit)
                    hum:ChangeState(Enum.HumanoidStateType.Landed)
                    pcall(function() hrp.AssemblyLinearVelocity = V3new(0,0,0) end)
                    task.wait(0.05)
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
    end

    stopCurrentFly()
end

local function fireProximityPrompt(prompt)
    if not prompt then return end
    pcall(function()
        local oldDist = prompt.MaxActivationDistance
        local oldReq = prompt.RequiresLineOfSight
        prompt.MaxActivationDistance = 9999
        prompt.RequiresLineOfSight = false
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.3)
        prompt.MaxActivationDistance = oldDist
        prompt.RequiresLineOfSight = oldReq
    end)
end

local function waitAndFirePrompt(prompt, attempts)
    attempts = attempts or 5
    for i = 1, attempts do
        if not prompt or not prompt.Parent then break end
        fireProximityPrompt(prompt)
        task.wait(0.4)
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
    pcall(function()
        if firesignal then firesignal(btn.MouseButton1Click) ok = true end
    end)
    pcall(function()
        if firesignal then firesignal(btn.Activated) end
    end)
    pcall(function()
        if fireclickdetector then
            local cd = btn:FindFirstChildOfClass("ClickDetector")
            if cd then fireclickdetector(cd) end
        end
    end)
    if not ok then
        pcall(function() btn.MouseButton1Click:Fire() ok = true end)
    end
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
    if obj:IsA("BasePart") then
        cf = obj.CFrame
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then
            cf = obj.PrimaryPart.CFrame
        elseif obj:FindFirstChild("HumanoidRootPart") then
            cf = obj.HumanoidRootPart.CFrame
        else
            local bp = obj:FindFirstChildWhichIsA("BasePart")
            if bp then cf = bp.CFrame end
        end
    end
    if cf then
        return (cf + cf.LookVector * dist).Position
    end
    return getPartPosition(obj)
end

local function findAreaObj(names)
    for _, name in ipairs(names) do
        local found = findInWorkspace(name)
        if found then return found end
    end
    return nil
end

local function findAreaPosition(names)
    local obj = findAreaObj(names)
    if obj then
        local pos = getPartPosition(obj)
        if pos then return pos end
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

local function flyToFront(obj)
    if not obj then return end
    local frontPos = getFrontPosition(obj, 4)
    if not frontPos then frontPos = getPartPosition(obj) end
    if not frontPos then return end
    local ch = LP.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") then return end
    if (ch.HumanoidRootPart.Position - frontPos).Magnitude > 5 then
        flyTo(frontPos, S.AutoFarmSpeed or 300)
        task.wait(0.3)
    end
end

local function approachAndFire(target, actionText)
    if not target then return false end
    local pos = getFrontPosition(target, 4)
    if not pos then pos = getPartPosition(target) end
    if not pos then return false end

    local ch = LP.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    -- Летим к передней стороне
    if (hrp.Position - pos).Magnitude > 5 then
        flyTo(pos, S.AutoFarmSpeed or 300)
        task.wait(0.3)
    end

    -- Ищем промпт и жмём несколько раз
    local pp = findProximityPrompt(target, actionText)
    if not pp then pp = findProximityPrompt(target, nil) end
    if not pp and target.Parent then
        pp = findProximityPrompt(target.Parent, actionText)
        if not pp then pp = findProximityPrompt(target.Parent, nil) end
    end

    if pp then
        waitAndFirePrompt(pp, 4)
        return true
    end
    return false
end

local function buyRings()
    setStatus("Покупка колец...")
    local bought = false
    local buyTargets = {
        {"Fake Diamond Ring","Buy"}, {"Ring","Buy"}, {"Diamond","Buy"},
        {"BlackMarket","Buy"}, {"Black Market","Buy"},
        {"Market","Buy"}, {"Shop","Buy"}, {"Jewelry","Buy"}
    }
    for _, pair in ipairs(buyTargets) do
        if bought then break end
        local target = findNPC(pair[1])
        if not target then
            local part = findInWorkspace(pair[1])
            if part then target = part end
        end
        if target then
            bought = approachAndFire(target, pair[2])
        end
    end
    if not bought then
        local remotes = {"BuyRing","PurchaseRing","BuyItem","Purchase","BuyGoods","Buy"}
        for _, rn in ipairs(remotes) do
            if tryFireRemote(rn, "Fake Diamond Ring") then bought = true break end
        end
    end
    if not bought then
        local btn = findButtonInGUI("Buy") or findButtonInGUI("Purchase")
        if btn then clickButton(btn) bought = true end
    end
    return bought
end

local function sellGoods()
    setStatus("Продажа товаров...")
    local sold = false
    local sellerNames = {"Smuggled Goods Seller","GoodsSeller","Seller","Goods","Sell"}
    for _, sn in ipairs(sellerNames) do
        if sold then break end
        local target = findNPC(sn)
        if not target then
            local part = findInWorkspace(sn)
            if part then target = part end
        end
        if target then
            sold = approachAndFire(target, "sell")
        end
    end
    if not sold then
        local prompts = findAllPrompts("sell")
        for _, pp in ipairs(prompts) do
            if sold then break end
            local par = pp.Parent
            if par then
                flyToFront(par)
                task.wait(0.3)
                waitAndFirePrompt(pp, 4)
                sold = true
            end
        end
    end
    if not sold then
        local remotes = {"SellGoods","Sell","SellItem","SellAll"}
        for _, rn in ipairs(remotes) do
            if tryFireRemote(rn) then sold = true break end
        end
    end
    if not sold then
        local btn = findButtonInGUI("Sell")
        if btn then clickButton(btn) sold = true end
    end
    if sold then
        task.wait(0.5)
        clickAllGUIButtons("sell")
        task.wait(0.3)
        clickAllGUIButtons("confirm")
        task.wait(0.3)
        clickAllGUIButtons("yes")
        task.wait(0.3)
        clickAllGUIButtons("accept")
        task.wait(0.3)
        clickAllGUIButtons("ok")
    end
    return sold
end

local function launderMoney()
    setStatus("Отмывка денег...")
    local done = false

    local launderPrompts = {"Cash Drop","Launder Cash","Launder","Wash"}
    for _, pName in ipairs(launderPrompts) do
        if done then break end
        local prompts = findAllPrompts(pName)
        for _, pp in ipairs(prompts) do
            if done then break end
            local par = pp.Parent
            if par then
                local frontPos = getFrontPosition(par, 4)
                if not frontPos then frontPos = getPartPosition(par) end
                if frontPos then
                    flyTo(frontPos, S.AutoFarmSpeed or 300)
                    task.wait(0.3)
                end
                waitAndFirePrompt(pp, 4)
                done = true
            end
        end
    end

    if not done then
        local launderNames = {
            "Laundromat","LAUNDROMAT","Launder","MoneyWash",
            "Money Wash","Wash","Laundering","WashingMachine","Washing Machine",
            "Cash Drop","CashDrop","Launder Cash","LaunderCash"
        }
        for _, ln in ipairs(launderNames) do
            if done then break end
            local obj = findInWorkspace(ln)
            if obj then
                done = approachAndFire(obj, "launder") or approachAndFire(obj, "wash") or approachAndFire(obj, nil)
            end
        end
    end

    if not done then
        local remotes = {"Launder","LaunderMoney","WashMoney","MoneyWash","LaunderCash"}
        for _, rn in ipairs(remotes) do
            if tryFireRemote(rn) then done = true break end
        end
    end

    if not done then
        local btn = findButtonInGUI("Launder") or findButtonInGUI("Wash")
        if btn then clickButton(btn) task.wait(0.5) clickButton(btn) done = true end
    end

    if done then
        task.wait(0.5)
        clickAllGUIButtons("launder")
        task.wait(0.3)
        clickAllGUIButtons("confirm")
        task.wait(0.3)
        clickAllGUIButtons("yes")
        task.wait(0.3)
        clickAllGUIButtons("accept")
        task.wait(0.3)
        clickAllGUIButtons("ok")
    end
    return done
end

local function doRingFarmCycle()
    if not SD.AutoFarmActive then return end

    setStatus("Лечу к магазину...")
    local marketPos = findAreaPosition({"BlackMarket","Black Market","GoodsMarket","Market","Shop","Jewelry","JewelryShop"})
    if marketPos then
        flyTo(marketPos, S.AutoFarmSpeed or 300)
        task.wait(0.5)
    end

    for i = 1, 5 do
        if not SD.AutoFarmActive then return end
        setStatus("Покупка " .. i .. "/5")
        buyRings()
        task.wait(0.5)
    end

    if not SD.AutoFarmActive then return end
    setStatus("Лечу к продавцу...")
    local sellerObj = findAreaObj({"Smuggled Goods Seller","GoodsSeller","Seller","SellGoods","SmuggledGoods"})
    if sellerObj then
        flyToFront(sellerObj)
    end

    if not SD.AutoFarmActive then return end
    sellGoods()
    task.wait(0.5)

    if not SD.AutoFarmActive then return end
    setStatus("Лечу отмывать...")
    launderMoney()
    task.wait(0.5)

    SD.AutoFarmLaps = SD.AutoFarmLaps + 1
    setStatus("Круг #" .. SD.AutoFarmLaps .. " завершён!")
end

function SD.startAutoFarm()
    if SD.AutoFarmActive then return end
    SD.AutoFarmActive = true
    SD.AutoFarmLaps = 0
    setStatus("Запуск...")
    task.spawn(function()
        while SD.AutoFarmActive do
            pcall(function() doRingFarmCycle() end)
            if not SD.AutoFarmActive then break end
            task.wait(2)
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
