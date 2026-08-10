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
local currentMoveCleanup = nil

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
    if statusLabel then pcall(function() statusLabel.Text = text end) end
end

local function stopCurrentMove()
    if currentMoveCleanup then
        pcall(function() currentMoveCleanup() end)
        currentMoveCleanup = nil
    end
end

local function rayDown(pos, maxDist)
    maxDist = maxDist or 500
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ch = LP.Character
    if ch then params.FilterDescendantsInstances = {ch} end
    local result = ws:Raycast(pos, V3new(0, -maxDist, 0), params)
    if result then return result.Position end
    return nil
end

local function rayForward(pos, dir, dist)
    dist = dist or 8
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ch = LP.Character
    if ch then params.FilterDescendantsInstances = {ch} end
    local result = ws:Raycast(pos, dir * dist, params)
    if result then return result end
    return nil
end

local function groundMoveTo(targetPos, speed)
    stopCurrentMove()
    local ch = LP.Character
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    speed = speed or (S.AutoFarmSpeed or 80)
    local alive = true
    local stuckCount = 0
    local lastPos = hrp.Position
    local MAX_CLIMB = 6

    local moveConn = RS.Heartbeat:Connect(function(dt)
        if not alive then return end
        if not ch or not ch.Parent or not hrp or not hrp.Parent then alive = false return end

        local myPos = hrp.Position
        local flatDist = (V3new(myPos.X, 0, myPos.Z) - V3new(targetPos.X, 0, targetPos.Z)).Magnitude

        if flatDist < 6 then
            local vertDist = math.abs(myPos.Y - targetPos.Y)
            if vertDist < 15 then alive = false return end
        end

        local flatTarget = V3new(targetPos.X, myPos.Y, targetPos.Z)
        local moveDir = (flatTarget - myPos)
        if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end

        local stepDist = speed * dt
        local newFlatPos = myPos + moveDir * stepDist

        local needJump = false
        local jumpHeight = 0

        local feetCheck = rayForward(myPos + V3new(0, -2, 0), moveDir, 4)
        local kneeCheck = rayForward(myPos + V3new(0, 0, 0), moveDir, 4)
        local headCheck = rayForward(myPos + V3new(0, 3, 0), moveDir, 4)

        if kneeCheck and not headCheck then
            local obstacleTop = kneeCheck.Position.Y
            local climbNeeded = obstacleTop - (myPos.Y - 3)
            if climbNeeded > 0 and climbNeeded < MAX_CLIMB then
                needJump = true
                jumpHeight = obstacleTop + 4
            end
        elseif feetCheck and not kneeCheck then
            local stepH = feetCheck.Position.Y - (myPos.Y - 3)
            if stepH > 0 and stepH < 3 then
                needJump = true
                jumpHeight = feetCheck.Position.Y + 4
            end
        end

        if headCheck and kneeCheck then
            local params2 = RaycastParams.new()
            params2.FilterType = Enum.RaycastFilterType.Exclude
            if ch then params2.FilterDescendantsInstances = {ch} end
            local sideDir1 = V3new(-moveDir.Z, 0, moveDir.X)
            local sideHit = ws:Raycast(myPos, sideDir1 * 10, params2)
            if not sideHit then
                newFlatPos = myPos + sideDir1 * stepDist
            else
                newFlatPos = myPos + V3new(moveDir.Z, 0, -moveDir.X) * stepDist
            end
            needJump = false
        end

        local groundPos = rayDown(V3new(newFlatPos.X, myPos.Y + 10, newFlatPos.Z), 50)
        local finalY = myPos.Y

        if needJump and jumpHeight > 0 then
            finalY = finalY + (jumpHeight - finalY) * math.min(dt * 10, 1)
        elseif groundPos then
            local groundY = groundPos.Y + 3.5
            local diff = groundY - finalY
            if diff > 0 and diff < MAX_CLIMB then
                finalY = finalY + diff * math.min(dt * 12, 1)
            elseif diff <= 0 then
                finalY = finalY + diff * math.min(dt * 15, 1)
            end
        end

        hrp.CFrame = CFnew(newFlatPos.X, finalY, newFlatPos.Z) * (hrp.CFrame - hrp.CFrame.Position)
        hrp.AssemblyLinearVelocity = V3new(0, 0, 0)
        hum:ChangeState(Enum.HumanoidStateType.Running)

        if (myPos - lastPos).Magnitude < 0.3 then
            stuckCount = stuckCount + 1
            if stuckCount > 90 then
                local sideDir = V3new(-moveDir.Z, 0, moveDir.X)
                local sidePos = myPos + sideDir * 8
                hrp.CFrame = CFnew(sidePos) * (hrp.CFrame - hrp.CFrame.Position)
                stuckCount = 0
            end
        else
            stuckCount = 0
        end
        lastPos = myPos
    end)

    currentMoveCleanup = function()
        alive = false
        pcall(function() moveConn:Disconnect() end)
    end

    while alive and SD.AutoFarmActive do
        if not ch or not ch.Parent or not hrp or not hrp.Parent then break end
        local totalDist = (hrp.Position - targetPos).Magnitude
        if totalDist < 6 then break end
        task.wait()
    end

    stopCurrentMove()
end

local function fireProximityPrompt(prompt)
    if not prompt then return end
    pcall(function()
        local oldDist = prompt.MaxActivationDistance
        prompt.MaxActivationDistance = 9999
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.4)
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

local function clickAllMatching(buttonName)
    local pg = LP.PlayerGui
    if not pg then return false end
    local bLow = buttonName:lower()
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

local function findAreaPosition(names)
    for _, name in ipairs(names) do
        local found = findInWorkspace(name)
        if found then
            local pos = getPartPosition(found)
            if pos then return pos end
        end
    end
    return nil
end

local function interactPromptNear(name, actionText)
    local ch = LP.Character
    if not ch then return false end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local target = findNPC(name)
    if not target then
        local part = findInWorkspace(name)
        if part then
            if part:IsA("Model") then
                target = part
            elseif part:IsA("BasePart") then
                local pp = findProximityPrompt(part, actionText) or findProximityPrompt(part.Parent, actionText)
                if pp then
                    local pos = part.Position
                    if (hrp.Position - pos).Magnitude > 5 then
                        groundMoveTo(pos + V3new(0, 0, 0), S.AutoFarmSpeed or 80)
                        task.wait(0.3)
                    end
                    fireProximityPrompt(pp)
                    return true
                end
            end
        end
    end
    if target then
        local pp = findProximityPrompt(target, actionText)
        if pp then
            local pos = getPartPosition(target)
            if pos and (hrp.Position - pos).Magnitude > 5 then
                groundMoveTo(pos + V3new(0, 0, 2), S.AutoFarmSpeed or 80)
                task.wait(0.3)
            end
            fireProximityPrompt(pp)
            return true
        end
    end
    return false
end

local function findDeliveryWaypoint()
    for _, desc in ipairs(ws:GetDescendants()) do
        if desc:IsA("BillboardGui") and desc.Enabled then
            for _, child in ipairs(desc:GetDescendants()) do
                if child:IsA("TextLabel") and child.Visible then
                    local txt = child.Text:lower()
                    if string_find(txt, "stud") or string_find(txt, "deliver") or string_find(txt, "drop") then
                        local adornee = desc.Adornee
                        if adornee and adornee:IsA("BasePart") then
                            return adornee.Position
                        end
                        local par = desc.Parent
                        if par then
                            local pos = getPartPosition(par)
                            if pos then return pos end
                        end
                    end
                end
            end
        end
    end

    local deliveryNames = {
        "Delivery","DeliveryPoint","Deliver","DropOff","Drop Off",
        "Destination","Unload","Waypoint","WayPoint","DropPoint",
        "DeliveryZone","UnloadZone","TruckStop","EndPoint"
    }
    for _, name in ipairs(deliveryNames) do
        local found = findInWorkspace(name)
        if found then
            local pos = getPartPosition(found)
            if pos then return pos end
        end
    end

    for _, desc in ipairs(ws:GetDescendants()) do
        if desc:IsA("BasePart") and desc.Transparency < 1 then
            local dLow = desc.Name:lower()
            if string_find(dLow, "deliver") or string_find(dLow, "drop") or string_find(dLow, "waypoint") or string_find(dLow, "unload") or string_find(dLow, "destination") then
                return desc.Position
            end
        end
    end

    return nil
end

local function findDeliveryFromGUI()
    local pg = LP.PlayerGui
    if not pg then return nil end
    for _, gui in ipairs(pg:GetDescendants()) do
        if gui:IsA("TextLabel") and gui.Visible then
            local txt = gui.Text:lower()
            if (string_find(txt, "stud") or string_find(txt, "deliver")) then
                local num = gui.Text:match("(%d+)")
                if num then
                    return tonumber(num)
                end
            end
        end
    end
    return nil
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
        bought = interactPromptNear(pair[1], pair[2])
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
    local sellTargets = {
        {"Sell",nil}, {"Smuggled Goods Seller","Sell"},
        {"Seller","Sell"}, {"Goods","Sell"}
    }
    for _, pair in ipairs(sellTargets) do
        if sold then break end
        sold = interactPromptNear(pair[1], pair[2])
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
    return sold
end

local function launderMoney()
    setStatus("Отмывка денег...")
    local done = false
    local targets = {{"Launder",nil},{"Money Wash",nil},{"Wash","Launder"}}
    for _, pair in ipairs(targets) do
        if done then break end
        done = interactPromptNear(pair[1], pair[2])
    end
    if not done then
        local remotes = {"Launder","LaunderMoney","WashMoney","MoneyWash"}
        for _, rn in ipairs(remotes) do
            if tryFireRemote(rn) then done = true break end
        end
    end
    return done
end

local function doRingFarmCycle()
    if not SD.AutoFarmActive then return end
    setStatus("Кольца: бегу к магазину...")
    local marketPos = findAreaPosition({"BlackMarket","Black Market","GoodsMarket","Market","Shop","Jewelry","JewelryShop"})
    if marketPos then
        groundMoveTo(marketPos, S.AutoFarmSpeed or 80)
        task.wait(0.3)
    end
    for i = 1, 3 do
        if not SD.AutoFarmActive then return end
        setStatus("Кольца: покупка " .. i .. "/3")
        buyRings()
        task.wait(0.5)
    end
    if not SD.AutoFarmActive then return end
    setStatus("Кольца: бегу к продавцу...")
    local sellerPos = findAreaPosition({"Smuggled Goods Seller","GoodsSeller","Seller","SellGoods","SmuggledGoods"})
    if sellerPos then
        groundMoveTo(sellerPos, S.AutoFarmSpeed or 80)
        task.wait(0.3)
    end
    sellGoods()
    task.wait(0.5)
    if not SD.AutoFarmActive then return end
    setStatus("Кольца: бегу отмывать...")
    local launderPos = findAreaPosition({"Launder","MoneyWash","Money Wash","Wash","Laundering"})
    if launderPos then
        groundMoveTo(launderPos, S.AutoFarmSpeed or 80)
        task.wait(0.3)
    end
    launderMoney()
    task.wait(0.5)
    SD.AutoFarmLaps = SD.AutoFarmLaps + 1
end

local function tryClickButton(names, maxAttempts)
    maxAttempts = maxAttempts or 10
    for attempt = 1, maxAttempts do
        if not SD.AutoFarmActive then return false end
        for _, bName in ipairs(names) do
            local btn = findButtonInGUI(bName)
            if btn then
                clickButton(btn)
                task.wait(0.2)
                clickButton(btn)
                setStatus("Нажал: " .. bName)
                return true
            end
        end
        if clickAllMatching(names[1]) then
            setStatus("Нажал: " .. names[1])
            return true
        end
        task.wait(0.5)
    end
    return false
end

local function doTruckerCycle()
    if not SD.AutoFarmActive then return end

    setStatus("Дальнобой: ищу NPC...")
    local truckerNames = {"Trucker","TruckDriver","Truck Driver","TruckNPC","Delivery","DeliveryNPC"}
    for _, name in ipairs(truckerNames) do
        local npc = findNPC(name)
        if npc then
            local pos = getPartPosition(npc)
            if pos then
                setStatus("Дальнобой: бегу к NPC...")
                groundMoveTo(pos + V3new(0, 0, 2), S.AutoFarmSpeed or 80)
                task.wait(0.3)
                break
            end
        end
    end

    if not SD.AutoFarmActive then return end
    setStatus("Дальнобой: открываю миссии...")
    local missionOpened = false
    local missionTargets = {
        {"Trucker","View"},{"Trucker","Mission"},{"Trucker",nil},
        {"Truck","View"},{"TruckDriver",nil},{"Delivery",nil}
    }
    for _, pair in ipairs(missionTargets) do
        if missionOpened then break end
        missionOpened = interactPromptNear(pair[1], pair[2])
    end
    task.wait(1)
    if not missionOpened then
        tryClickButton({"View Missions","View missions","Missions","ViewMissions"}, 5)
    end
    task.wait(1)

    if not SD.AutoFarmActive then return end
    setStatus("Дальнобой: выбираю грузовик...")

    local truckSelected = false
    local truckTiers = {
        {"Gym Equipment","GymEquipment","gym equipment","Gym","Equipment","Tier 3","tier3","Best"},
        {"Food Supplies","FoodSupplies","food supplies","Food","Supplies","Tier 2","tier2"},
        {"Car Parts","CarParts","car parts","Parts","Auto","Tier 1","tier1","Van"}
    }
    for tierIdx, names in ipairs(truckTiers) do
        if truckSelected then break end
        if not SD.AutoFarmActive then return end
        task.wait(0.5)
        for _, bName in ipairs(names) do
            local btn = findButtonInGUI(bName)
            if btn then
                clickButton(btn)
                task.wait(0.3)
                clickButton(btn)
                setStatus("Грузовик: " .. bName)
                truckSelected = true
                break
            end
        end
    end
    task.wait(1)

    if not SD.AutoFarmActive then return end
    setStatus("Дальнобой: нажимаю Start...")
    local startClicked = tryClickButton({"Start","Accept","Begin","Go","start","Confirm"}, 15)
    if not startClicked then
        task.wait(1)
        tryClickButton({"Start","Accept","Begin","Go","start","Confirm","OK","Ok","ok"}, 10)
    end
    task.wait(2)

    if not SD.AutoFarmActive then return end
    setStatus("Дальнобой: ищу точку доставки...")

    local deliveryPos = nil
    for attempt = 1, 20 do
        if not SD.AutoFarmActive then return end
        deliveryPos = findDeliveryWaypoint()
        if deliveryPos then break end
        task.wait(1)
        setStatus("Дальнобой: жду точку... (" .. attempt .. ")")
    end

    if deliveryPos and SD.AutoFarmActive then
        setStatus("Дальнобой: бегу к точке!")
        groundMoveTo(deliveryPos, S.AutoFarmSpeed or 80)
        task.wait(1)

        local newPos = findDeliveryWaypoint()
        if newPos and (newPos - deliveryPos).Magnitude > 20 then
            setStatus("Дальнобой: обновлённая точка...")
            groundMoveTo(newPos, S.AutoFarmSpeed or 80)
            task.wait(1)
        end
    end

    if not SD.AutoFarmActive then return end
    setStatus("Дальнобой: завершаю доставку...")

    local deliveryInteracted = false
    local deliveryTargets = {"Delivery","DeliveryPoint","Deliver","DropOff","Drop Off","Destination","Unload"}
    for _, name in ipairs(deliveryTargets) do
        if deliveryInteracted then break end
        local found = findInWorkspace(name)
        if found then
            local pp = findProximityPrompt(found, nil)
            if pp then
                fireProximityPrompt(pp)
                deliveryInteracted = true
            end
        end
    end

    task.wait(1)
    tryClickButton({"Collect","Claim","Complete","Finish","Done"}, 8)
    task.wait(1)

    SD.AutoFarmLaps = SD.AutoFarmLaps + 1
    setStatus("Круг #" .. SD.AutoFarmLaps)
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
            task.wait(1)
            pcall(function() doTruckerCycle() end)
            if not SD.AutoFarmActive then break end
            task.wait(2)
        end
        stopCurrentMove()
        setStatus("Остановлено")
    end)
end

function SD.stopAutoFarm()
    SD.AutoFarmActive = false
    stopCurrentMove()
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
                            myHrp.CFrame = CFnew(hrp.Position + V3new(0, 0, -3))
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
    stopCurrentMove()
end

return SD
end
