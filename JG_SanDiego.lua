```lua
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

local MAX_STEP = 42

local function flyTo(targetPos, speed)
    stopCurrentFly()
    local ch = LP.Character
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    speed = speed or (S.AutoFarmSpeed or 120)

    local alive = true
    local stepCount = 0
    local flyTime = 0
    local isPaused = false
    
    local noclipConn = RS.Stepped:Connect(function()
        if not alive then return end
        pcall(function()
            if ch and hrp then
                for _, part in ipairs(ch:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
                hrp.Velocity = V3new(0, 0, 0)
                hrp.RotVelocity = V3new(0, 0, 0)
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
    end)

    currentFlyCleanup = function()
        alive = false
        pcall(function() noclipConn:Disconnect() end)
        pcall(function()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Landed)
            end
        end)
    end

    while alive and SD.AutoFarmActive do
        if not ch or not ch.Parent or not hrp or not hrp.Parent then break end
        local myPos = hrp.Position
        local dist = (myPos - targetPos).Magnitude
        if dist < 6 then break end
        
        if not isPaused and flyTime >= 3.8 then
            isPaused = true
            hum:ChangeState(Enum.HumanoidStateType.Landed)
            pcall(function() hrp.Velocity = V3new(0, -2, 0) end)
            task.wait(0.2)
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            flyTime = 0
            isPaused = false
        end
        
        local dir = (targetPos - myPos).Unit
        local dt = task.wait()
        local step = speed * dt
        if step > 35 then step = 35 end
        if step > dist then step = dist end
        
        local newPos = myPos + dir * step
        
        local ray = RaycastParams.new()
        ray.FilterType = Enum.RaycastFilterType.Blacklist
        ray.FilterDescendantsInstances = {ch}
        local hit = ws:Raycast(newPos + V3new(0, 5, 0), V3new(0, -10, 0), ray)
        if hit and (newPos.Y - hit.Position.Y) > 6 then
            newPos = V3new(newPos.X, hit.Position.Y + 2.5, newPos.Z)
        end
        
        if stepCount % 3 == 0 then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        
        hrp.CFrame = CFnew(newPos, newPos + dir)
        pcall(function() hrp.Velocity = V3new(0, 0, 0) end)
        pcall(function() hrp.AssemblyLinearVelocity = V3new(0, 0, 0) end)
        pcall(function() hrp.AssemblyAngularVelocity = V3new(0, 0, 0) end)
        
        stepCount = stepCount + 1
        flyTime = flyTime + dt
        
        task.wait(0.04)
    end

    stopCurrentFly()
end
    
local function fireProximityPrompt(prompt)
    if not prompt then return end
    pcall(function()
        local oldDist = prompt.MaxActivationDistance
        prompt.MaxActivationDistance = 9999
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.5)
        prompt.MaxActivationDistance = oldDist
    end)
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
        if firesignal then
            firesignal(btn.MouseButton1Click)
            ok = true
        end
    end)
    pcall(function()
        if firesignal then
            firesignal(btn.Activated)
        end
    end)
    pcall(function()
        if fireclickdetector then
            local cd = btn:FindFirstChildOfClass("ClickDetector")
            if cd then fireclickdetector(cd) end
        end
    end)
    if not ok then
        pcall(function()
            btn.MouseButton1Click:Fire()
            ok = true
        end)
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
                if match then
                    clickButton(gui)
                    found = true
                end
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

local function firePromptAndWait(pp)
    if not pp then return end
    fireProximityPrompt(pp)
    task.wait(1)
    fireProximityPrompt(pp)
    task.wait(1)
    fireProximityPrompt(pp)
end

local function flyToFront(obj)
    if not obj then return end
    local frontPos = getFrontPosition(obj, 4)
    if not frontPos then frontPos = getPartPosition(obj) end
    if not frontPos then return end
    local ch = LP.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") then return end
    if (ch.HumanoidRootPart.Position - frontPos).Magnitude > 6 then
        flyTo(frontPos, S.AutoFarmSpeed or 120)
    end
    task.wait(0.5)
end

local function buyRings()
    setStatus("Покупка колец...")
    local bought = false
    local buyTargets = {
        {"Fake Diamond Ring","Buy"}, {"Ring","Buy"}, {"Diamond","Buy"},
        {"Buy","Fake Diamond Ring"}, {"BlackMarket","Buy"}, {"Black Market","Buy"},
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
            flyToFront(target)
            local pp = findProximityPrompt(target, pair[2])
            if not pp and target.Parent then pp = findProximityPrompt(target.Parent, pair[2]) end
            if pp then
                fireProximityPrompt(pp)
                bought = true
            end
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

    for attempt = 1, 10 do
        if sold then break end
        if not SD.AutoFarmActive then return false end
        setStatus("Продажа... попытка " .. attempt)

        local sellerNames = {"Smuggled Goods Seller","GoodsSeller","Seller","Goods","Sell"}
        for _, sn in ipairs(sellerNames) do
            if sold then break end
            local target = findNPC(sn)
            if not target then
                local part = findInWorkspace(sn)
                if part then target = part end
            end
            if target then
                flyToFront(target)
                task.wait(0.3)
                local pp = findProximityPrompt(target, "sell")
                if not pp then pp = findProximityPrompt(target, nil) end
                if not pp and target.Parent then
                    pp = findProximityPrompt(target.Parent, "sell")
                    if not pp then pp = findProximityPrompt(target.Parent, nil) end
                end
                if pp then
                    firePromptAndWait(pp)
                    sold = true
                end
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
                    firePromptAndWait(pp)
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
            if btn then
                clickButton(btn)
                task.wait(1)
                clickButton(btn)
                sold = true
            end
        end

        if sold then
            task.wait(1.5)
            clickAllGUIButtons("sell")
            task.wait(1)
            clickAllGUIButtons("confirm")
            task.wait(0.5)
            clickAllGUIButtons("yes")
            task.wait(0.5)
            clickAllGUIButtons("accept")
            task.wait(0.5)
            clickAllGUIButtons("ok")
            task.wait(1)
        end

        if not sold then task.wait(1) end
    end

    return sold
end

local function launderMoney()
    setStatus("Отмывка денег...")
    local done = false

    for attempt = 1, 10 do
        if done then break end
        if not SD.AutoFarmActive then return false end
        setStatus("Отмывка... попытка " .. attempt)

        local launderNames = {"Laundromat","LAUNDROMAT","Launder","MoneyWash","Money Wash","Wash","Laundering","WashingMachine","Washing Machine"}
        for _, ln in ipairs(launderNames) do
            if done then break end
            local obj = findInWorkspace(ln)
            if obj then
                flyToFront(obj)
                task.wait(0.3)
                local pp = findProximityPrompt(obj, "launder")
                if not pp then pp = findProximityPrompt(obj, "wash") end
                if not pp then pp = findProximityPrompt(obj, nil) end
                if not pp and obj.Parent then
                    pp = findProximityPrompt(obj.Parent, "launder")
                    if not pp then pp = findProximityPrompt(obj.Parent, "wash") end
                    if not pp then pp = findProximityPrompt(obj.Parent, nil) end
                end
                if pp then
                    firePromptAndWait(pp)
                    done = true
                end
            end
        end

        if not done then
            local prompts = findAllPrompts("launder")
            for _, pp in ipairs(prompts) do
                if done then break end
                local par = pp.Parent
                if par then
                    flyToFront(par)
                    task.wait(0.3)
                    firePromptAndWait(pp)
                    done = true
                end
            end
        end

        if not done then
            local prompts = findAllPrompts("wash")
            for _, pp in ipairs(prompts) do
                if done then break end
                local par = pp.Parent
                if par then
                    flyToFront(par)
                    task.wait(0.3)
                    firePromptAndWait(pp)
                    done = true
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
            if btn then
                clickButton(btn)
                task.wait(1)
                clickButton(btn)
                done = true
            end
        end

        if done then
            task.wait(1.5)
            clickAllGUIButtons("launder")
            task.wait(1)
            clickAllGUIButtons("confirm")
            task.wait(0.5)
            clickAllGUIButtons("yes")
            task.wait(0.5)
            clickAllGUIButtons("accept")
            task.wait(0.5)
            clickAllGUIButtons("ok")
            task.wait(1)
        end

        if not done then task.wait(1) end
    end

    return done
end

local function doRingFarmCycle()
    if not SD.AutoFarmActive then return end

    setStatus("Лечу к магазину...")
    local marketPos = findAreaPosition({"BlackMarket","Black Market","GoodsMarket","Market","Shop","Jewelry","JewelryShop"})
    if marketPos then
        flyTo(marketPos, S.AutoFarmSpeed or 120)
        task.wait(0.5)
    end
    for i = 1, 5 do
        if not SD.AutoFarmActive then return end
        setStatus("Покупка " .. i .. "/5")
        buyRings()
        task.wait(0.6)
    end

    if not SD.AutoFarmActive then return end
    setStatus("Лечу к продавцу...")
    local sellerObj = findAreaObj({"Smuggled Goods Seller","GoodsSeller","Seller","SellGoods","SmuggledGoods"})
    if sellerObj then
        flyToFront(sellerObj)
    end

    if not SD.AutoFarmActive then return end
    local soldOk = sellGoods()
    if not soldOk then
        setStatus("НЕ ПРОДАЛ! Пробую ещё...")
        task.wait(2)
        sellGoods()
    end

    if not SD.AutoFarmActive then return end
    setStatus("Лечу отмывать...")
    local launderObj = findAreaObj({"Laundromat","LAUNDROMAT","Launder","MoneyWash","Money Wash","Wash","Laundering","WashingMachine"})
    if launderObj then
        flyToFront(launderObj)
    end

    if not SD.AutoFarmActive then return end
    local launderOk = launderMoney()
    if not launderOk then
        setStatus("НЕ ОТМЫЛ! Пробую ещё...")
        task.wait(2)
        launderMoney()
    end

    task.wait(1)
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
```
