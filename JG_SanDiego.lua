return function(S, LP, Players, ws, RS, Camera, Color3RGB, V3new, CFnew, mathhuge, pcall, task, table_insert, string_find, string_lower, tostring, mathfloor)

local SD = {}
SD.AutoFarmActive = false
SD.AutoFarmStatus = "Idle"
SD.AutoFarmLaps = 0
SD.PoliceESP = false
SD.AimCivilian = false
SD.AimPolice = false
SD.AutoFarmMode = "Smuggle"

local policeHighlights = {}
local statusLabel = nil
local currentFlyCleanup = nil
local antiCheatDied = false

local TEAM_NAMES_POLICE = {"police","border patrol","fbi","swat","bortac","army","sheriff","trooper","marshal","officer","cop","patrol"}

local GOODS_TABLE = {
    {name="Fake Diamond Ring", price=500, sell=2200, profit=1700, priority=1},
    {name="Diamond Ring", price=500, sell=2200, profit=1700, priority=2},
    {name="Gold Watch", price=400, sell=1600, profit=1200, priority=3},
    {name="Avocado Crate", price=150, sell=390, profit=240, priority=6},
    {name="Cocaine", price=350, sell=1400, profit=1050, priority=4},
    {name="Weed", price=200, sell=800, profit=600, priority=5},
}

local TRUCK_GOODS = {
    {name="Truck Cargo", sell=5000, priority=1},
    {name="Smuggle Cargo", sell=3000, priority=2},
    {name="Delivery", sell=2000, priority=3},
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
        local function checkTools(container)
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    local tLow = tool.Name:lower()
                    if string_find(tLow,"taser") or string_find(tLow,"handcuff") or string_find(tLow,"baton") or string_find(tLow,"badge") then return true end
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

function SD.updatePoliceESP()
    for p, hl in pairs(policeHighlights) do pcall(function() hl:Destroy() end) end
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
    for p, hl in pairs(policeHighlights) do pcall(function() hl:Destroy() end) end
    policeHighlights = {}
end

local function setStatus(text)
    SD.AutoFarmStatus = text
    if statusLabel then pcall(function() statusLabel.Text = "Статус: " .. text end) end
end

local function stopCurrentFly()
    if currentFlyCleanup then pcall(function() currentFlyCleanup() end) currentFlyCleanup = nil end
end

local function getHRP()
    local ch = LP.Character
    if not ch then return nil, nil, nil end
    return ch, ch:FindFirstChild("HumanoidRootPart"), ch:FindFirstChildOfClass("Humanoid")
end

local lastGroundTouch = 0

local function flyTo(targetPos, speed)
    stopCurrentFly()
    local ch, hrp, hum = getHRP()
    if not hrp or not hum then return end

    speed = speed or (S.AutoFarmSpeed or 170)
    if speed > 300 then speed = 300 end

    local alive = true
    local groundTimer = 0
    local stepCount = 0
    local startPos = hrp.Position
    local lastTeleportCheck = tick()

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {ch}

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
        pcall(function() if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end end)
    end

    while alive and SD.AutoFarmActive do
        if not ch or not ch.Parent or not hrp or not hrp.Parent then break end
        if not hum or hum.Health <= 0 then antiCheatDied = true break end

        local myPos = hrp.Position
        local totalDist = (myPos - targetPos).Magnitude
        if totalDist < 8 then break end

        local now = tick()
        if now - lastTeleportCheck > 2 then
            if (myPos - startPos).Magnitude < 3 and totalDist > 20 then
                startPos = myPos
            end
            lastTeleportCheck = now
            startPos = myPos
        end

        local dir = (targetPos - myPos).Unit
        local wallCheck = ws:Raycast(myPos, dir * 12, rayParams)
        if wallCheck then
            dir = (V3new(dir.X, 0.7, dir.Z)).Unit
        end

        local dt = task.wait()
        if dt > 0.05 then dt = 0.05 end
        groundTimer = groundTimer + dt
        stepCount = stepCount + 1

        local step = speed * dt
        if step > math.min(totalDist, 50) then step = math.min(totalDist, 50) end

        local newPos = myPos + dir * step

        if groundTimer >= 3.0 then
            local hit = ws:Raycast(myPos + V3new(0, 10, 0), V3new(0, -150, 0), rayParams)
            if hit then
                local groundY = hit.Position.Y + 3.0
                if math.abs(myPos.Y - groundY) < 60 then
                    hrp.CFrame = CFnew(V3new(myPos.X, groundY, myPos.Z), targetPos)
                    hum:ChangeState(Enum.HumanoidStateType.Landed)
                    pcall(function() hrp.AssemblyLinearVelocity = V3new(0,0,0) end)
                    task.wait(0.08)
                end
            else
                hum:ChangeState(Enum.HumanoidStateType.Freefall)
            end
            groundTimer = 0
        elseif stepCount % 5 == 0 then
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
        end

        hrp.CFrame = CFnew(newPos, newPos + (targetPos - newPos).Unit)
        pcall(function() hrp.Velocity = V3new(0,0,0) end)
        pcall(function() hrp.AssemblyLinearVelocity = V3new(0,0,0) end)
        pcall(function() hrp.AssemblyAngularVelocity = V3new(0,0,0) end)
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

local function findInWorkspace(name)
    local nameLow = name:lower()
    for _, child in ipairs(ws:GetDescendants()) do
        if child.Name == name or string_find(child.Name:lower(), nameLow) then return child end
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
        local h = obj:FindFirstChild("HumanoidRootPart")
        if h then return h.Position end
        local p = obj.PrimaryPart
        if p then return p.Position end
        local b = obj:FindFirstChildWhichIsA("BasePart")
        if b then return b.Position end
    end
    return nil
end

local function getFrontPosition(obj, dist)
    dist = dist or 5
    if not obj then return nil end
    local cf
    if obj:IsA("BasePart") then cf = obj.CFrame
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then cf = obj.PrimaryPart.CFrame
        elseif obj:FindFirstChild("HumanoidRootPart") then cf = obj.HumanoidRootPart.CFrame
        else local b = obj:FindFirstChildWhichIsA("BasePart") if b then cf = b.CFrame end end
    end
    if cf then return (cf + cf.LookVector * dist).Position end
    return getPartPosition(obj)
end

local function tryFireRemote(name, ...)
    local args = table.pack(...)
    local rs = game:GetService("ReplicatedStorage")
    for _, child in ipairs(rs:GetDescendants()) do
        if (child:IsA("RemoteEvent") or child:IsA("RemoteFunction")) and (child.Name == name or string_find(child.Name:lower(), name:lower())) then
            pcall(function()
                if child:IsA("RemoteEvent") then child:FireServer(table.unpack(args, 1, args.n))
                else child:InvokeServer(table.unpack(args, 1, args.n)) end
            end)
            return true
        end
    end
    return false
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
    pcall(function() if firesignal then firesignal(btn.MouseButton1Click) end end)
    pcall(function() if firesignal then firesignal(btn.Activated) end end)
    pcall(function() btn.MouseButton1Click:Fire() end)
    return true
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

local function flyToObj(obj, dist)
    if not obj then return end
    local pos = getFrontPosition(obj, dist or 4)
    if not pos then pos = getPartPosition(obj) end
    if not pos then return end
    local _, hrp = getHRP()
    if not hrp then return end
    if (hrp.Position - pos).Magnitude > 8 then
        flyTo(pos, S.AutoFarmSpeed or 170)
        task.wait(0.3)
    end
end

local function approachAndFire(target, actionText)
    if not target then return false end
    flyToObj(target, 4)
    local pp = findProximityPrompt(target, actionText)
    if not pp then pp = findProximityPrompt(target, nil) end
    if not pp and target.Parent then
        pp = findProximityPrompt(target.Parent, actionText)
        if not pp then pp = findProximityPrompt(target.Parent, nil) end
    end
    if pp then
        for i = 1, 4 do
            if not pp or not pp.Parent then break end
            fireProximityPrompt(pp)
            task.wait(0.4)
        end
        return true
    end
    return false
end

local function confirmGUI()
    task.wait(0.4)
    clickAllGUIButtons("confirm")
    task.wait(0.2)
    clickAllGUIButtons("yes")
    task.wait(0.2)
    clickAllGUIButtons("accept")
    task.wait(0.2)
    clickAllGUIButtons("ok")
end

local function findBestGoods()
    local sorted = {}
    for _, g in ipairs(GOODS_TABLE) do table_insert(sorted, g) end
    table.sort(sorted, function(a, b) return a.profit > b.profit end)
    return sorted
end

local function findVehicleSeat()
    local _, hrp = getHRP()
    if not hrp then return nil end
    local best, bestDist = nil, 100
    for _, v in ipairs(ws:GetDescendants()) do
        if v:IsA("VehicleSeat") and not v.Occupant then
            local d = (hrp.Position - v.Position).Magnitude
            if d < bestDist then bestDist = d best = v end
        end
    end
    return best
end

local function findTruckSpawn()
    local names = {"TruckSpawn","Truck Spawn","TruckDepot","Truck Depot","VehicleSpawn","Vehicle Spawn","CarSpawn","Garage","SpawnPad"}
    for _, n in ipairs(names) do
        local obj = findInWorkspace(n)
        if obj then return obj end
    end
    local prompts = findAllPrompts("spawn")
    if #prompts > 0 then return prompts[1].Parent end
    prompts = findAllPrompts("truck")
    for _, pp in ipairs(prompts) do
        local at = (pp.ActionText or ""):lower()
        if string_find(at, "spawn") or string_find(at, "summon") then return pp.Parent end
    end
    return nil
end

local function findTruckPickup()
    local names = {"TruckPickup","Truck Pickup","CargoPickup","Cargo Pickup","LoadingDock","Loading Dock","PickupZone","TruckJob","Truck Job","TruckMission","Truck Mission","StartDelivery","JobBoard","Job Board"}
    for _, n in ipairs(names) do
        local obj = findInWorkspace(n)
        if obj then return obj end
    end
    local prompts = findAllPrompts("delivery")
    if #prompts > 0 then return prompts[1].Parent end
    prompts = findAllPrompts("cargo")
    if #prompts > 0 then return prompts[1].Parent end
    prompts = findAllPrompts("truck")
    for _, pp in ipairs(prompts) do
        local at = (pp.ActionText or ""):lower()
        if string_find(at, "start") or string_find(at, "accept") or string_find(at, "pick") then return pp.Parent end
    end
    return nil
end

local function findDeliveryPoint()
    local names = {"DeliveryPoint","Delivery Point","DropOff","Drop Off","DeliveryZone","Delivery Zone","UnloadZone","Unload","TruckDeliver","CargoDeliver","Warehouse","Export","DeliveryMarker"}
    for _, n in ipairs(names) do
        local obj = findInWorkspace(n)
        if obj then return obj end
    end
    local prompts = findAllPrompts("deliver")
    if #prompts > 0 then return prompts[1].Parent end
    prompts = findAllPrompts("unload")
    if #prompts > 0 then return prompts[1].Parent end
    return nil
end

local function findBlackMarket()
    local names = {"BlackMarket","Black Market","GoodsShop","Goods Shop","BlackMarketGoods","Black Market Goods","MarketShop"}
    for _, n in ipairs(names) do
        local obj = findInWorkspace(n)
        if obj then return obj end
    end
    local npc = findNPC("Black Market")
    if npc then return npc end
    return nil
end

local function findSeller()
    local names = {"Smuggled Goods Seller","SmuggledGoodsSeller","GoodsSeller","Goods Seller","Seller","SellGoods"}
    for _, n in ipairs(names) do
        local npc = findNPC(n)
        if npc then return npc end
        local obj = findInWorkspace(n)
        if obj then return obj end
    end
    return nil
end

local function findLaundromat()
    local names = {"Laundromat","LAUNDROMAT","Launder","MoneyWash","Money Wash","WashingMachine","Washing Machine","Cash Drop","CashDrop","LaunderCash"}
    for _, n in ipairs(names) do
        local obj = findInWorkspace(n)
        if obj then return obj end
    end
    return nil
end

local function findTunnel()
    local names = {"Tunnel","SecretTunnel","Secret Tunnel","Underground","UndergroundTunnel","TunnelEntrance","Tunnel Entrance"}
    for _, n in ipairs(names) do
        local obj = findInWorkspace(n)
        if obj then return obj end
    end
    return nil
end

local function buyGoods()
    setStatus("Покупка товаров...")
    local goods = findBestGoods()
    local bought = false
    local market = findBlackMarket()

    if market then
        flyToObj(market, 5)
        task.wait(0.5)
    end

    for buyAttempt = 1, 5 do
        if not SD.AutoFarmActive then return false end

        for _, g in ipairs(goods) do
            if bought then break end
            local pp = findProximityPrompt(market, "buy")
            if not pp then pp = findProximityPrompt(market, g.name) end
            if pp then
                fireProximityPrompt(pp)
                task.wait(0.3)
                bought = true
            end
        end

        if not bought then
            local buyPrompts = findAllPrompts("buy")
            for _, pp in ipairs(buyPrompts) do
                if bought then break end
                local par = pp.Parent
                if par then
                    flyToObj(par, 4)
                    fireProximityPrompt(pp)
                    task.wait(0.3)
                    bought = true
                end
            end
        end

        if not bought then
            local remotes = {"BuyRing","PurchaseRing","BuyItem","Purchase","BuyGoods","Buy"}
            for _, rn in ipairs(remotes) do
                for _, g in ipairs(goods) do
                    if tryFireRemote(rn, g.name) then bought = true break end
                end
                if bought then break end
            end
        end

        if not bought then
            local btn = findButtonInGUI("buy") or findButtonInGUI("purchase")
            if btn then clickButton(btn) bought = true end
        end

        if bought then
            task.wait(0.3)
            clickAllGUIButtons("buy")
            confirmGUI()
        end

        task.wait(0.3)
    end
    return bought
end

local function sellGoods()
    setStatus("Продажа товаров...")
    local seller = findSeller()
    local sold = false

    if seller then
        flyToObj(seller, 4)
        task.wait(0.5)
        sold = approachAndFire(seller, "sell")
    end

    if not sold then
        local prompts = findAllPrompts("sell")
        for _, pp in ipairs(prompts) do
            if sold then break end
            if pp.Parent then flyToObj(pp.Parent, 4) fireProximityPrompt(pp) sold = true end
        end
    end

    if not sold then
        local remotes = {"SellGoods","Sell","SellItem","SellAll"}
        for _, rn in ipairs(remotes) do if tryFireRemote(rn) then sold = true break end end
    end

    if not sold then
        local btn = findButtonInGUI("sell")
        if btn then clickButton(btn) sold = true end
    end

    if sold then
        task.wait(0.4)
        clickAllGUIButtons("sell")
        confirmGUI()
    end
    return sold
end

local function launderMoney()
    setStatus("Отмывка денег...")
    local done = false
    local laundromat = findLaundromat()

    if laundromat then
        flyToObj(laundromat, 4)
        task.wait(0.5)
        done = approachAndFire(laundromat, "launder") or approachAndFire(laundromat, "wash") or approachAndFire(laundromat, nil)
    end

    if not done then
        local prompts = findAllPrompts("launder")
        for _, pp in ipairs(prompts) do
            if done then break end
            if pp.Parent then flyToObj(pp.Parent, 4) fireProximityPrompt(pp) done = true end
        end
        if not done then
            prompts = findAllPrompts("wash")
            for _, pp in ipairs(prompts) do
                if done then break end
                if pp.Parent then flyToObj(pp.Parent, 4) fireProximityPrompt(pp) done = true end
            end
        end
    end

    if not done then
        local remotes = {"Launder","LaunderMoney","WashMoney","MoneyWash","LaunderCash"}
        for _, rn in ipairs(remotes) do if tryFireRemote(rn) then done = true break end end
    end

    if not done then
        local btn = findButtonInGUI("launder") or findButtonInGUI("wash")
        if btn then clickButton(btn) done = true end
    end

    if done then
        task.wait(0.4)
        clickAllGUIButtons("launder")
        confirmGUI()
    end
    return done
end

local function doTruckCycle()
    if not SD.AutoFarmActive then return end
    antiCheatDied = false

    setStatus("Ищу грузовик/депо...")
    local truckSpawn = findTruckSpawn()
    if truckSpawn then
        flyToObj(truckSpawn, 6)
        task.wait(0.5)
        approachAndFire(truckSpawn, "spawn")
        task.wait(0.3)
        approachAndFire(truckSpawn, "truck")
        task.wait(0.3)
        clickAllGUIButtons("spawn")
        task.wait(0.3)
        clickAllGUIButtons("truck")
        confirmGUI()
        task.wait(1)
    end

    if not SD.AutoFarmActive or antiCheatDied then return end

    local seat = findVehicleSeat()
    if seat then
        setStatus("Сажусь в грузовик...")
        local _, hrp = getHRP()
        if hrp then hrp.CFrame = seat.CFrame + V3new(0, 1, 0) end
        task.wait(0.5)
    end

    if not SD.AutoFarmActive or antiCheatDied then return end

    setStatus("Ищу точку погрузки...")
    local pickup = findTruckPickup()
    if pickup then
        flyToObj(pickup, 6)
        task.wait(0.5)
        approachAndFire(pickup, "start")
        task.wait(0.3)
        approachAndFire(pickup, "accept")
        task.wait(0.3)
        approachAndFire(pickup, "pickup")
        task.wait(0.3)
        approachAndFire(pickup, nil)
        clickAllGUIButtons("start")
        clickAllGUIButtons("accept")
        confirmGUI()
        task.wait(1)
    end

    if not SD.AutoFarmActive or antiCheatDied then return end

    setStatus("Ищу точку доставки...")
    local delivery = findDeliveryPoint()
    if delivery then
        flyToObj(delivery, 6)
        task.wait(0.5)
        approachAndFire(delivery, "deliver")
        task.wait(0.3)
        approachAndFire(delivery, "unload")
        task.wait(0.3)
        approachAndFire(delivery, nil)
        clickAllGUIButtons("deliver")
        clickAllGUIButtons("complete")
        confirmGUI()
        task.wait(1)
    end

    if not SD.AutoFarmActive or antiCheatDied then return end

    local remotes = {"CompleteDelivery","FinishDelivery","FinishJob","CompleteJob","DeliverCargo","TruckDeliver","CompleteTruck"}
    for _, rn in ipairs(remotes) do tryFireRemote(rn) end

    SD.AutoFarmLaps = SD.AutoFarmLaps + 1
    setStatus("Рейс #" .. SD.AutoFarmLaps .. " завершён!")
end

local function doSmuggleCycle()
    if not SD.AutoFarmActive then return end
    antiCheatDied = false

    setStatus("Лечу к магазину...")
    buyGoods()
    if not SD.AutoFarmActive or antiCheatDied then return end

    setStatus("Пересекаю границу...")
    local tunnel = findTunnel()
    if tunnel then
        flyToObj(tunnel, 5)
        task.wait(0.5)
        approachAndFire(tunnel, nil)
        task.wait(1)
    end

    if not SD.AutoFarmActive or antiCheatDied then return end

    setStatus("Лечу к продавцу...")
    sellGoods()
    if not SD.AutoFarmActive or antiCheatDied then return end

    setStatus("Лечу отмывать...")
    launderMoney()
    if not SD.AutoFarmActive or antiCheatDied then return end

    SD.AutoFarmLaps = SD.AutoFarmLaps + 1
    setStatus("Круг #" .. SD.AutoFarmLaps .. " завершён!")
end

local function doFarmCycle()
    if SD.AutoFarmMode == "Truck" then
        doTruckCycle()
    else
        doSmuggleCycle()
    end
end

function SD.startAutoFarm()
    if SD.AutoFarmActive then return end
    SD.AutoFarmActive = true
    SD.AutoFarmLaps = 0
    setStatus("Запуск...")
    task.spawn(function()
        while SD.AutoFarmActive do
            local ok, err = pcall(doFarmCycle)
            if antiCheatDied then
                setStatus("Античит: жду респавн...")
                local timeout = 0
                while timeout < 15 do
                    task.wait(1)
                    timeout = timeout + 1
                    local _, _, hum = getHRP()
                    if hum and hum.Health > 0 then break end
                end
                antiCheatDied = false
                task.wait(2)
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

function SD.getPlayerListFiltered(searchText)
    local result = {}
    searchText = (searchText or ""):lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local ch = p.Character
            if ch then
                if searchText == "" or string_find(p.Name:lower(), searchText) or string_find(p.DisplayName:lower(), searchText) then
                    table_insert(result, {
                        player = p, name = p.Name, displayName = p.DisplayName,
                        role = isPolice(p) and "Police" or "Civilian", character = ch
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
                    local _, myHrp = getHRP()
                    if myHrp then myHrp.CFrame = CFnew(hrp.Position + V3new(0, 0, -5)) return true end
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
