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
local lastSpawnPos = nil

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

local function stopCurrentFly()
    if currentFlyCleanup then
        pcall(function() currentFlyCleanup() end)
        currentFlyCleanup = nil
    end
end

local function waitFor(condFn, timeout)
    timeout = timeout or 10
    local t = tick()
    while tick() - t < timeout do
        if not SD.AutoFarmActive then return false end
        if condFn() then return true end
        task.wait(0.2)
    end
    return condFn()
end

local function isInVehicle()
    local ch = LP.Character
    if not ch then return false end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    return hum.SeatPart ~= nil
end

local function getSeatPart()
    local ch = LP.Character
    if not ch then return nil end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    return hum.SeatPart
end

local function getVehicleModelFromSeat(seat)
    if not seat then return nil end
    local cur = seat.Parent
    while cur and cur ~= ws do
        if cur:IsA("Model") then return cur end
        cur = cur.Parent
    end
    return nil
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

local function findAllProximityPrompts(parent)
    local result = {}
    if not parent then return result end
    for _, desc in ipairs(parent:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            table_insert(result, desc)
        end
    end
    return result
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
                return true
            end
        end
        clickAllMatching(names[1])
        task.wait(0.5)
    end
    return false
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

local function findNearestVehicle(pos, radius)
    radius = radius or 80
    local best = nil
    local bestDist = radius
    for _, child in ipairs(ws:GetDescendants()) do
        if child:IsA("VehicleSeat") then
            local d = (child.Position - pos).Magnitude
            if d < bestDist then
                local occ = child.Occupant
                if not occ then
                    bestDist = d
                    best = child
                end
            end
        end
    end
    if best then
        return getVehicleModelFromSeat(best), best
    end
    return nil, nil
end

local function exitVehicle()
    local ch = LP.Character
    if not ch then return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    pcall(function() hum.Sit = false end)
    task.wait(0.1)
    pcall(function() hum.Jump = true end)
    task.wait(0.3)
    pcall(function() hum.Jump = true end)
    task.wait(0.3)
    if hum.SeatPart then
        pcall(function()
            local seat = hum.SeatPart
            for _, w in ipairs(seat:GetChildren()) do
                if (w:IsA("Weld") or w:IsA("WeldConstraint")) then
                    local isChar = false
                    pcall(function()
                        if w.Part0 and w.Part0:IsDescendantOf(ch) then isChar = true end
                        if w.Part1 and w.Part1:IsDescendantOf(ch) then isChar = true end
                    end)
                    if isChar then pcall(function() w:Destroy() end) end
                end
            end
        end)
        task.wait(0.2)
        pcall(function() hum.Sit = false end)
    end
    task.wait(0.3)
end

local function enterVehicle(vehicleModel, seat)
    if not vehicleModel then return false end
    local ch = LP.Character
    if not ch then return false end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    if not seat then
        seat = vehicleModel:FindFirstChildWhichIsA("VehicleSeat", true)
    end
    if not seat then
        seat = vehicleModel:FindFirstChildWhichIsA("Seat", true)
    end
    if not seat then return false end

    hrp.CFrame = seat.CFrame + V3new(0, 2, 0)
    task.wait(0.3)
    pcall(function() seat:Sit(hum) end)
    task.wait(0.5)
    if isInVehicle() then return true end

    local pp = findProximityPrompt(vehicleModel)
    if pp then
        fireProximityPrompt(pp)
        task.wait(0.5)
    end
    if isInVehicle() then return true end

    hrp.CFrame = seat.CFrame * CFnew(0, 0, -2)
    task.wait(0.2)
    pcall(function() seat:Sit(hum) end)
    task.wait(0.5)
    if isInVehicle() then return true end

    for _, desc in ipairs(vehicleModel:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            fireProximityPrompt(desc)
            task.wait(0.3)
            if isInVehicle() then return true end
        end
    end

    return isInVehicle()
end

local function flyTo(targetPos, speed)
    stopCurrentFly()
    local ch = LP.Character
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    speed = speed or (S.AutoFarmSpeed or 120)
    local alive = true

    local inVeh = isInVehicle()
    local seat = getSeatPart()
    local vehicleModel = nil
    local vehicleRoot = nil

    if inVeh and seat then
        vehicleModel = getVehicleModelFromSeat(seat)
        if vehicleModel then
            vehicleRoot = vehicleModel.PrimaryPart or seat
        end
    end

    local rayParams = RaycastParams.new()
    local filterList = {ch}
    if vehicleModel then table_insert(filterList, vehicleModel) end
    rayParams.FilterDescendantsInstances = filterList
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local oldWS = hum.WalkSpeed
    local oldJP = hum.JumpPower
    local oldJH = nil
    pcall(function() oldJH = hum.JumpHeight end)

    local noclipConn = RS.Stepped:Connect(function()
        if not alive then return end
        pcall(function()
            if not ch or not ch.Parent then return end
            for _, part in ipairs(ch:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
            if vehicleModel then
                for _, part in ipairs(vehicleModel:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
            if not inVeh then
                hum.WalkSpeed = 0
                hum.JumpPower = 0
                pcall(function() hum.JumpHeight = 0 end)
                hum:ChangeState(Enum.HumanoidStateType.Running)
                hrp.Velocity = V3new(0, 0, 0)
                hrp.RotVelocity = V3new(0, 0, 0)
            end
        end)
    end)

    currentFlyCleanup = function()
        alive = false
        pcall(function() noclipConn:Disconnect() end)
        if not inVeh then
            pcall(function() hum.WalkSpeed = oldWS end)
            pcall(function() hum.JumpPower = oldJP end)
            pcall(function() if oldJH then hum.JumpHeight = oldJH end end)
        end
    end

    local STEP = inVeh and 40 or 25
    local DELAY = inVeh and 0.18 or 0.28

    while alive and SD.AutoFarmActive do
        if not ch or not ch.Parent or not hrp or not hrp.Parent then break end
        if inVeh and not isInVehicle() then break end

        local moveRoot = (inVeh and vehicleRoot) or hrp
        if not moveRoot or not moveRoot.Parent then break end

        local currentPos = moveRoot.Position
        local toTarget = targetPos - currentPos
        local dist = toTarget.Magnitude
        if dist < 6 then break end

        local dir = toTarget.Unit
        local step = math.min(STEP, dist)
        local nextXZ = currentPos + V3new(dir.X * step, 0, dir.Z * step)

        local groundY = currentPos.Y
        local ray = ws:Raycast(V3new(nextXZ.X, currentPos.Y + 500, nextXZ.Z), V3new(0, -1000, 0), rayParams)
        if ray then
            groundY = ray.Position.Y + (inVeh and 4.5 or 3.5)
        end

        local finalPos = V3new(nextXZ.X, groundY, nextXZ.Z)
        local lookAt = V3new(targetPos.X, groundY, targetPos.Z)

        if inVeh and vehicleModel and vehicleRoot then
            local newCF = CFnew(finalPos, lookAt)
            local offset = newCF.Position - vehicleRoot.CFrame.Position
            pcall(function()
                for _, part in ipairs(vehicleModel:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Velocity = V3new(0, 0, 0)
                        part.RotVelocity = V3new(0, 0, 0)
                    end
                end
            end)
            pcall(function() vehicleModel:PivotTo(vehicleModel:GetPivot() + offset) end)
        else
            hrp.CFrame = CFnew(finalPos, lookAt)
            hrp.Velocity = V3new(0, 0, 0)
            hrp.RotVelocity = V3new(0, 0, 0)
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end

        task.wait(DELAY)
    end

    stopCurrentFly()
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
                    if (hrp.Position - pos).Magnitude > 8 then
                        flyTo(pos + V3new(0, 3, 0), S.AutoFarmSpeed or 120)
                        task.wait(0.5)
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
            if pos and (hrp.Position - pos).Magnitude > 8 then
                flyTo(pos + V3new(0, 3, 2), S.AutoFarmSpeed or 120)
                task.wait(0.5)
            end
            fireProximityPrompt(pp)
            return true
        end
    end
    return false
end

local function findSpawnVehicle()
    local names = {"Spawn Vehicle","SpawnVehicle","VehicleSpawn","Vehicle Spawn","CarSpawn","Spawn Car","SpawnCar"}
    for _, name in ipairs(names) do
        local found = findInWorkspace(name)
        if found then return found end
    end
    for _, desc in ipairs(ws:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            local at = (desc.ActionText or ""):lower()
            local ot = (desc.ObjectText or ""):lower()
            if string_find(at, "spawn") or string_find(at, "vehicle") or string_find(ot, "spawn") or string_find(ot, "vehicle") then
                return desc.Parent
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

local function doFarmCycle()
    if not SD.AutoFarmActive then return end

    if isInVehicle() then
        setStatus("Выхожу из машины...")
        exitVehicle()
        waitFor(function() return not isInVehicle() end, 5)
        task.wait(0.5)
    end

    setStatus("Лечу к магазину...")
    local marketPos = findAreaPosition({"BlackMarket","Black Market","GoodsMarket","Market","Shop","Jewelry","JewelryShop"})
    if marketPos then
        flyTo(marketPos + V3new(0, 3, 0), S.AutoFarmSpeed or 120)
        task.wait(0.5)
    end

    for i = 1, 5 do
        if not SD.AutoFarmActive then return end
        setStatus("Покупка кольца " .. i .. "/5")
        local ok = false
        for attempt = 1, 3 do
            if buyRings() then ok = true break end
            task.wait(0.3)
        end
        task.wait(0.5)
    end
    if not SD.AutoFarmActive then return end

    setStatus("Лечу к Spawn Vehicle...")
    local spawnObj = findSpawnVehicle()
    if not spawnObj then
        setStatus("Spawn Vehicle не найден!")
        task.wait(2)
        return
    end
    local spawnPos = getPartPosition(spawnObj)
    if not spawnPos then
        setStatus("Позиция Spawn Vehicle не найдена!")
        task.wait(2)
        return
    end
    lastSpawnPos = spawnPos

    local ch = LP.Character
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    flyTo(spawnPos + V3new(0, 3, 0), S.AutoFarmSpeed or 120)
    task.wait(0.5)
    if not SD.AutoFarmActive then return end

    setStatus("Открываю меню спавна...")
    local prompts = findAllProximityPrompts(spawnObj)
    if #prompts == 0 then
        local parent = spawnObj.Parent
        if parent then prompts = findAllProximityPrompts(parent) end
    end
    for _, pp in ipairs(prompts) do
        fireProximityPrompt(pp)
        task.wait(0.3)
    end
    if #prompts == 0 then
        interactPromptNear("Spawn Vehicle", nil)
        task.wait(0.3)
        interactPromptNear("Spawn", "Vehicle")
        task.wait(0.3)
        interactPromptNear("Vehicle", "Spawn")
    end
    task.wait(1)
    if not SD.AutoFarmActive then return end

    setStatus("Выбираю Tayro Cambria...")
    local carSelected = false
    for attempt = 1, 20 do
        if not SD.AutoFarmActive then return end
        local btn = findButtonInGUI("Tayro Cambria")
        if not btn then btn = findButtonInGUI("TayroCambria") end
        if not btn then btn = findButtonInGUI("Tayro") end
        if not btn then btn = findButtonInGUI("Cambria") end
        if btn then
            clickButton(btn)
            task.wait(0.3)
            clickButton(btn)
            carSelected = true
            break
        end
        clickAllMatching("Tayro")
        clickAllMatching("Cambria")
        task.wait(0.5)
    end
    if not carSelected then
        setStatus("Tayro Cambria не найдена!")
        task.wait(2)
        return
    end
    if not SD.AutoFarmActive then return end

    setStatus("Нажимаю Spawn...")
    task.wait(0.5)
    local spawned = tryClickButton({"Spawn","spawn","Select","select","Confirm","confirm","OK","Ok"}, 15)
    if not spawned then
        setStatus("Кнопка Spawn не найдена!")
        task.wait(2)
        return
    end
    task.wait(1.5)
    if not SD.AutoFarmActive then return end

    setStatus("Ищу машину...")
    local vehicleModel, vehicleSeat = nil, nil
    local foundVeh = waitFor(function()
        vehicleModel, vehicleSeat = findNearestVehicle(spawnPos, 100)
        return vehicleModel ~= nil
    end, 8)

    if not foundVeh or not vehicleModel then
        setStatus("Машина не появилась!")
        task.wait(2)
        return
    end
    if not SD.AutoFarmActive then return end

    setStatus("Сажусь в машину...")
    local entered = enterVehicle(vehicleModel, vehicleSeat)
    if not entered then
        entered = waitFor(function()
            enterVehicle(vehicleModel, vehicleSeat)
            return isInVehicle()
        end, 6)
    end
    if not entered then
        setStatus("Не удалось сесть!")
        task.wait(2)
        return
    end
    if not SD.AutoFarmActive then return end

    setStatus("Еду к продавцу...")
    local sellerPos = findAreaPosition({"Smuggled Goods Seller","GoodsSeller","Seller","SellGoods","SmuggledGoods"})
    if sellerPos then
        flyTo(sellerPos + V3new(0, 3, 0), S.AutoFarmSpeed or 120)
        task.wait(0.5)
    end
    if not SD.AutoFarmActive then return end

    local soldOk = false
    for attempt = 1, 3 do
        if sellGoods() then soldOk = true break end
        task.wait(0.5)
    end
    task.wait(0.5)
    if not SD.AutoFarmActive then return end

    setStatus("Еду отмывать...")
    local launderPos = findAreaPosition({"Launder","MoneyWash","Money Wash","Wash","Laundering"})
    if launderPos then
        flyTo(launderPos + V3new(0, 3, 0), S.AutoFarmSpeed or 120)
        task.wait(0.5)
    end
    for attempt = 1, 3 do
        if launderMoney() then break end
        task.wait(0.5)
    end
    task.wait(0.5)
    if not SD.AutoFarmActive then return end

    setStatus("Еду назад к магазину...")
    if marketPos then
        flyTo(marketPos + V3new(0, 5, 0), S.AutoFarmSpeed or 120)
        task.wait(0.5)
    end
    if not SD.AutoFarmActive then return end

    setStatus("Выхожу из машины...")
    exitVehicle()
    waitFor(function() return not isInVehicle() end, 5)
    task.wait(0.5)

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
            pcall(function() doFarmCycle() end)
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
