return function(S, UI, C, LP, Players, RunService, TweenService, UIS, workspace, Camera, task, pcall, pairs, ipairs, mathfloor, mathclamp, mathhuge, Vector3new, CFramenew, Color3RGB, UDim2new, UDim2offset, Vector2new, table_insert, tw, ClientSounds)

local SD = {}

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

SD.AutoFarmActive = false
SD.AutoFarmStatus = "Idle"
SD.AutoFarmLaps = 0
SD.AutoFarmEarnings = 0
SD.PoliceESP = false
SD.AimCivilian = false
SD.AimPolice = false
SD.TpTarget = ""
SD.TpSearchText = ""

local policeHighlights = {}
local autoFarmConn = nil
local statusLabel = nil

local TEAM_NAMES_POLICE = {
    "Police", "police", "POLICE",
    "Border Patrol", "border patrol", "BORDER PATROL",
    "FBI", "fbi", "SWAT", "swat", "BORTAC", "bortac", "Army", "army"
}

local TEAM_NAMES_CIVILIAN = {
    "Civilian", "civilian", "CIVILIAN"
}

local function isPolice(player)
    if not player then return false end
    local team = player.Team
    if team then
        local tName = team.Name
        for _, n in ipairs(TEAM_NAMES_POLICE) do
            if tName == n or string.find(tName:lower(), n:lower()) then return true end
        end
    end
    local ch = player.Character
    if ch then
        for _, desc in ipairs(ch:GetDescendants()) do
            if desc:IsA("Accessory") or desc:IsA("Shirt") or desc:IsA("Pants") then
                local dName = desc.Name:lower()
                if string.find(dName, "police") or string.find(dName, "officer") or string.find(dName, "patrol") or string.find(dName, "cop") or string.find(dName, "swat") or string.find(dName, "fbi") or string.find(dName, "bortac") then
                    return true
                end
            end
        end
        for _, tool in ipairs(ch:GetChildren()) do
            if tool:IsA("Tool") then
                local tName = tool.Name:lower()
                if string.find(tName, "taser") or string.find(tName, "handcuff") or string.find(tName, "baton") or string.find(tName, "badge") then
                    return true
                end
            end
        end
    end
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                local tName = tool.Name:lower()
                if string.find(tName, "taser") or string.find(tName, "handcuff") or string.find(tName, "baton") or string.find(tName, "badge") then
                    return true
                end
            end
        end
    end
    return false
end

local function isCivilian(player)
    if not player then return false end
    if isPolice(player) then return false end
    local team = player.Team
    if team then
        local tName = team.Name
        for _, n in ipairs(TEAM_NAMES_CIVILIAN) do
            if tName == n or string.find(tName:lower(), n:lower()) then return true end
        end
    end
    return not isPolice(player)
end

function SD.shouldAimAt(player)
    if not player or player == LP then return false end
    if S.AimCivilian and not S.AimPolice then
        return isCivilian(player)
    elseif S.AimPolice and not S.AimCivilian then
        return isPolice(player)
    elseif S.AimCivilian and S.AimPolice then
        return true
    end
    return true
end

function SD.updatePoliceESP()
    for p, hl in pairs(policeHighlights) do
        pcall(function() if hl then hl:Destroy() end end)
    end
    policeHighlights = {}
    if not S.PoliceESP then return end
    local playerList = Players:GetPlayers()
    for i = 1, #playerList do
        local p = playerList[i]
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
    for p, hl in pairs(policeHighlights) do
        pcall(function() if hl then hl:Destroy() end end)
    end
    policeHighlights = {}
end

local function findProximityPrompt(model, actionText)
    if not model then return nil end
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            if actionText then
                if desc.ActionText == actionText or desc.ObjectText == actionText or string.find(desc.ActionText:lower(), actionText:lower()) or string.find(desc.ObjectText:lower(), actionText:lower()) then
                    return desc
                end
            else
                return desc
            end
        end
    end
    return nil
end

local function findClickDetector(model)
    if not model then return nil end
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("ClickDetector") then
            return desc
        end
    end
    return nil
end

local function fireProximityPrompt(prompt)
    if not prompt then return end
    pcall(function()
        prompt.MaxActivationDistance = 9999
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration + 0.1)
        prompt:InputHoldEnd()
    end)
    pcall(function()
        fireproximityprompt(prompt)
    end)
end

local function fireClick(detector)
    if not detector then return end
    pcall(function()
        fireclickdetector(detector)
    end)
end

local function teleportTo(pos)
    local ch = LP.Character
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.CFrame = CFramenew(pos)
end

local function tweenTo(pos, speed)
    local ch = LP.Character
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    speed = speed or 60
    local dist = (hrp.Position - pos).Magnitude
    local t = dist / speed
    if t < 0.1 then t = 0.1 end
    if t > 30 then t = 30 end
    local tween = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = CFramenew(pos)})
    tween:Play()
    tween.Completed:Wait()
end

local function findInWorkspace(name, className)
    for _, child in ipairs(workspace:GetDescendants()) do
        if className then
            if child:IsA(className) and (child.Name == name or string.find(child.Name:lower(), name:lower())) then
                return child
            end
        else
            if child.Name == name or string.find(child.Name:lower(), name:lower()) then
                return child
            end
        end
    end
    return nil
end

local function findAllInWorkspace(name)
    local results = {}
    for _, child in ipairs(workspace:GetDescendants()) do
        if child.Name == name or string.find(child.Name:lower(), name:lower()) then
            table_insert(results, child)
        end
    end
    return results
end

local function findNPC(name)
    for _, child in ipairs(workspace:GetDescendants()) do
        if child:IsA("Model") and (child.Name == name or string.find(child.Name:lower(), name:lower())) then
            local hum = child:FindFirstChildOfClass("Humanoid")
            if hum then return child end
        end
    end
    return nil
end

local function findNPCPrompt(npcName, actionText)
    local npc = findNPC(npcName)
    if npc then
        return findProximityPrompt(npc, actionText), npc
    end
    local allModels = findAllInWorkspace(npcName)
    for _, m in ipairs(allModels) do
        local pp = findProximityPrompt(m, actionText)
        if pp then return pp, m end
    end
    return nil, nil
end

local function findPartByName(name)
    for _, child in ipairs(workspace:GetDescendants()) do
        if child:IsA("BasePart") and (child.Name == name or string.find(child.Name:lower(), name:lower())) then
            return child
        end
    end
    return nil
end

local function findGUI(name)
    local pg = LP.PlayerGui
    if not pg then return nil end
    for _, gui in ipairs(pg:GetDescendants()) do
        if gui.Name == name or string.find(gui.Name:lower(), name:lower()) then
            return gui
        end
    end
    return nil
end

local function findButtonInGUI(guiName, buttonName)
    local pg = LP.PlayerGui
    if not pg then return nil end
    for _, gui in ipairs(pg:GetDescendants()) do
        if gui:IsA("TextButton") or gui:IsA("ImageButton") then
            if gui.Name == buttonName or (gui:IsA("TextButton") and string.find(gui.Text:lower(), buttonName:lower())) then
                return gui
            end
        end
    end
    return nil
end

local function clickButton(btn)
    if not btn then return false end
    pcall(function()
        local ce = btn:FindFirstChild("Activated")
        if ce then
            btn.Activated:Fire()
        end
    end)
    pcall(function()
        firesignal(btn.Activated)
    end)
    pcall(function()
        firesignal(btn.MouseButton1Click)
    end)
    return true
end

local function findRemoteEvent(name)
    local rs = game:GetService("ReplicatedStorage")
    for _, child in ipairs(rs:GetDescendants()) do
        if child:IsA("RemoteEvent") and (child.Name == name or string.find(child.Name:lower(), name:lower())) then
            return child
        end
    end
    return nil
end

local function findRemoteFunction(name)
    local rs = game:GetService("ReplicatedStorage")
    for _, child in ipairs(rs:GetDescendants()) do
        if child:IsA("RemoteFunction") and (child.Name == name or string.find(child.Name:lower(), name:lower())) then
            return child
        end
    end
    return nil
end

local function tryFireRemote(name, ...)
    local re = findRemoteEvent(name)
    if re then
        pcall(function() re:FireServer(...) end)
        return true
    end
    return false
end

local function tryInvokeRemote(name, ...)
    local rf = findRemoteFunction(name)
    if rf then
        local ok, result = pcall(function() return rf:InvokeServer(...) end)
        if ok then return result end
    end
    return nil
end

local function setStatus(text)
    SD.AutoFarmStatus = text
    if statusLabel then
        pcall(function() statusLabel.Text = text end)
    end
end

local function waitAndCheck(t)
    local elapsed = 0
    while elapsed < t do
        if not SD.AutoFarmActive then return false end
        task.wait(0.1)
        elapsed = elapsed + 0.1
    end
    return SD.AutoFarmActive
end

local function interactWithNearestPrompt(name, actionText, maxDist)
    maxDist = maxDist or 200
    local ch = LP.Character
    if not ch then return false end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local prompt, model = findNPCPrompt(name, actionText)
    if not prompt and not model then
        local part = findPartByName(name)
        if part then
            prompt = findProximityPrompt(part.Parent, actionText)
            model = part.Parent
        end
    end
    if prompt then
        local promptPart = prompt.Parent
        if promptPart and promptPart:IsA("BasePart") then
            local dist = (hrp.Position - promptPart.Position).Magnitude
            if dist > 15 then
                teleportTo(promptPart.Position + Vector3new(0, 3, 0))
                task.wait(0.5)
            end
        elseif model then
            local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head") or model:FindFirstChildWhichIsA("BasePart")
            if root then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist > 15 then
                    teleportTo(root.Position + Vector3new(0, 3, 0))
                    task.wait(0.5)
                end
            end
        end
        fireProximityPrompt(prompt)
        return true
    end
    return false
end

local function buyItem(itemName)
    setStatus("Buying: " .. (itemName or "item"))
    local bought = false
    bought = interactWithNearestPrompt("Buy", itemName)
    if not bought then
        bought = interactWithNearestPrompt(itemName, "Buy")
    end
    if not bought then
        bought = interactWithNearestPrompt("Fake Diamond Ring", "Buy")
    end
    if not bought then
        bought = interactWithNearestPrompt("Ring", "Buy")
    end
    if not bought then
        bought = interactWithNearestPrompt("Diamond", "Buy")
    end
    if not bought then
        local possibleNames = {"BuyRing", "PurchaseRing", "BuyItem", "Purchase", "BuyGoods", "Buy"}
        for _, rn in ipairs(possibleNames) do
            if tryFireRemote(rn, itemName or "Fake Diamond Ring") then
                bought = true
                break
            end
        end
    end
    if not bought then
        local btn = findButtonInGUI(nil, "Buy")
        if not btn then btn = findButtonInGUI(nil, "buy") end
        if not btn then btn = findButtonInGUI(nil, "Purchase") end
        if btn then
            clickButton(btn)
            bought = true
        end
    end
    return bought
end

local function sellItem()
    setStatus("Selling goods...")
    local sold = false
    sold = interactWithNearestPrompt("Sell", nil)
    if not sold then sold = interactWithNearestPrompt("Smuggled Goods Seller", "Sell") end
    if not sold then sold = interactWithNearestPrompt("Seller", "Sell") end
    if not sold then sold = interactWithNearestPrompt("Goods", "Sell") end
    if not sold then
        local possibleNames = {"SellGoods", "Sell", "SellItem", "SellAll"}
        for _, rn in ipairs(possibleNames) do
            if tryFireRemote(rn) then sold = true break end
        end
    end
    if not sold then
        local btn = findButtonInGUI(nil, "Sell")
        if btn then clickButton(btn) sold = true end
    end
    return sold
end

local function launderMoney()
    setStatus("Laundering money...")
    local done = false
    done = interactWithNearestPrompt("Launder", nil)
    if not done then done = interactWithNearestPrompt("Money Wash", nil) end
    if not done then done = interactWithNearestPrompt("Wash", "Launder") end
    if not done then
        local possibleNames = {"Launder", "LaunderMoney", "WashMoney", "MoneyWash"}
        for _, rn in ipairs(possibleNames) do
            if tryFireRemote(rn) then done = true break end
        end
    end
    return done
end

local function findBlackMarketArea()
    local possibleNames = {"BlackMarket", "Black Market", "GoodsMarket", "Goods Market", "Market", "Shop", "Jewelry", "JewelryShop"}
    for _, name in ipairs(possibleNames) do
        local found = findInWorkspace(name)
        if found then
            local part = found
            if found:IsA("Model") then
                part = found:FindFirstChild("HumanoidRootPart") or found:FindFirstChildWhichIsA("BasePart")
            end
            if part and part:IsA("BasePart") then
                return part.Position
            end
        end
    end
    return nil
end

local function findSellerArea()
    local possibleNames = {"Smuggled Goods Seller", "GoodsSeller", "Seller", "SellGoods", "SellNPC", "SmuggledGoods"}
    for _, name in ipairs(possibleNames) do
        local found = findNPC(name)
        if found then
            local part = found:FindFirstChild("HumanoidRootPart") or found:FindFirstChildWhichIsA("BasePart")
            if part then return part.Position end
        end
    end
    return nil
end

local function findLaunderArea()
    local possibleNames = {"Launder", "MoneyWash", "Money Wash", "Wash", "Laundering"}
    for _, name in ipairs(possibleNames) do
        local found = findInWorkspace(name)
        if found then
            local part = found
            if found:IsA("Model") then part = found:FindFirstChildWhichIsA("BasePart") end
            if part and part:IsA("BasePart") then return part.Position end
        end
    end
    return nil
end

local function findTruckerNPC()
    local possibleNames = {"Trucker", "TruckDriver", "Truck Driver", "TruckNPC", "Delivery", "DeliveryNPC"}
    for _, name in ipairs(possibleNames) do
        local found = findNPC(name)
        if found then return found end
    end
    local found = findInWorkspace("Trucker")
    if found then return found end
    return nil
end

local function openViewMissions()
    setStatus("Opening missions...")
    local done = false
    done = interactWithNearestPrompt("Trucker", "View")
    if not done then done = interactWithNearestPrompt("Trucker", "Mission") end
    if not done then done = interactWithNearestPrompt("Trucker", nil) end
    if not done then done = interactWithNearestPrompt("Truck", "View") end
    task.wait(1)
    if not done then
        local btn = findButtonInGUI(nil, "View Missions")
        if not btn then btn = findButtonInGUI(nil, "View missions") end
        if not btn then btn = findButtonInGUI(nil, "Missions") end
        if btn then clickButton(btn) done = true end
    end
    return done
end

local function selectTruck(tier)
    setStatus("Selecting truck tier " .. tostring(tier))
    local buttonNames = {}
    if tier == 3 then
        buttonNames = {"Gym Equipment", "GymEquipment", "gym equipment", "Gym", "Equipment", "Tier 3", "tier3", "Best"}
    elseif tier == 2 then
        buttonNames = {"Food Supplies", "FoodSupplies", "food supplies", "Food", "Supplies", "Tier 2", "tier2"}
    else
        buttonNames = {"Car Parts", "CarParts", "car parts", "Parts", "Auto", "Tier 1", "tier1", "Van"}
    end
    task.wait(0.5)
    for _, bName in ipairs(buttonNames) do
        local btn = findButtonInGUI(nil, bName)
        if btn then
            if btn.Visible then
                clickButton(btn)
                setStatus("Selected: " .. bName)
                return true
            end
        end
    end
    local pp = findNPCPrompt("Trucker", buttonNames[1])
    if pp then fireProximityPrompt(pp) return true end
    return false
end

local function pickBestTruck()
    if selectTruck(3) then return 3 end
    task.wait(0.3)
    if selectTruck(2) then return 2 end
    task.wait(0.3)
    if selectTruck(1) then return 1 end
    return 0
end

local function completeTruckDelivery()
    setStatus("Delivering truck...")
    local deliveryPoints = {"Delivery", "DeliveryPoint", "Deliver", "DropOff", "Drop Off", "Destination", "Unload"}
    for _, name in ipairs(deliveryPoints) do
        local found = findInWorkspace(name)
        if found then
            local part = found
            if found:IsA("Model") then part = found:FindFirstChildWhichIsA("BasePart") end
            if part and part:IsA("BasePart") then
                teleportTo(part.Position + Vector3new(0, 3, 0))
                task.wait(1)
                local pp = findProximityPrompt(found)
                if pp then fireProximityPrompt(pp) end
                local cd = findClickDetector(found)
                if cd then fireClick(cd) end
                return true
            end
        end
    end
    return false
end

local function doRingFarmCycle()
    setStatus("Ring Farm: Teleporting to shop...")
    local marketPos = findBlackMarketArea()
    if marketPos then
        teleportTo(marketPos + Vector3new(0, 3, 0))
        task.wait(1)
    end
    for i = 1, 5 do
        if not SD.AutoFarmActive then return end
        setStatus("Ring Farm: Buying ring " .. i .. "/5")
        buyItem("Fake Diamond Ring")
        task.wait(0.8)
    end
    setStatus("Ring Farm: Going to sell...")
    local sellerPos = findSellerArea()
    if sellerPos then
        teleportTo(sellerPos + Vector3new(0, 3, 0))
        task.wait(1)
    end
    sellItem()
    task.wait(1)
    setStatus("Ring Farm: Laundering...")
    local launderPos = findLaunderArea()
    if launderPos then
        teleportTo(launderPos + Vector3new(0, 3, 0))
        task.wait(1)
    end
    launderMoney()
    task.wait(1)
    SD.AutoFarmLaps = SD.AutoFarmLaps + 1
end

local function doTruckerCycle()
    setStatus("Trucker: Finding NPC...")
    local trucker = findTruckerNPC()
    if trucker then
        local root = trucker:FindFirstChild("HumanoidRootPart") or trucker:FindFirstChildWhichIsA("BasePart")
        if root then
            teleportTo(root.Position + Vector3new(0, 3, 3))
            task.wait(1)
        end
    end
    openViewMissions()
    task.wait(1.5)
    local tier = pickBestTruck()
    task.wait(2)
    local startBtn = findButtonInGUI(nil, "Start")
    if not startBtn then startBtn = findButtonInGUI(nil, "Accept") end
    if not startBtn then startBtn = findButtonInGUI(nil, "Begin") end
    if not startBtn then startBtn = findButtonInGUI(nil, "Go") end
    if startBtn then clickButton(startBtn) end
    task.wait(2)
    completeTruckDelivery()
    task.wait(2)
    local collectBtn = findButtonInGUI(nil, "Collect")
    if not collectBtn then collectBtn = findButtonInGUI(nil, "Claim") end
    if not collectBtn then collectBtn = findButtonInGUI(nil, "Complete") end
    if collectBtn then clickButton(collectBtn) end
    task.wait(1)
    SD.AutoFarmLaps = SD.AutoFarmLaps + 1
end

function SD.startAutoFarm()
    if SD.AutoFarmActive then return end
    SD.AutoFarmActive = true
    SD.AutoFarmLaps = 0
    SD.AutoFarmStatus = "Starting..."
    task.spawn(function()
        while SD.AutoFarmActive do
            pcall(function()
                doRingFarmCycle()
            end)
            if not SD.AutoFarmActive then break end
            task.wait(1)
            pcall(function()
                doTruckerCycle()
            end)
            if not SD.AutoFarmActive then break end
            task.wait(2)
        end
        setStatus("Stopped")
    end)
end

function SD.stopAutoFarm()
    SD.AutoFarmActive = false
    setStatus("Stopped")
end

function SD.getPlayerListFiltered(searchText)
    local result = {}
    searchText = searchText or ""
    searchText = searchText:lower()
    local playerList = Players:GetPlayers()
    for i = 1, #playerList do
        local p = playerList[i]
        if p ~= LP then
            local ch = p.Character
            if ch then
                if searchText == "" or string.find(p.Name:lower(), searchText) or string.find(p.DisplayName:lower(), searchText) then
                    local role = "Civilian"
                    if isPolice(p) then role = "Police" end
                    table_insert(result, {
                        player = p,
                        name = p.Name,
                        displayName = p.DisplayName,
                        role = role,
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
    local playerList = Players:GetPlayers()
    for i = 1, #playerList do
        local p = playerList[i]
        if p.Name == playerName or p.DisplayName == playerName then
            local ch = p.Character
            if ch then
                local hrp = ch:FindFirstChild("HumanoidRootPart")
                if hrp then
                    teleportTo(hrp.Position + Vector3new(0, 0, -5))
                    return true
                end
            end
        end
    end
    return false
end

function SD.setStatusLabel(label)
    statusLabel = label
end

local policeESPTick = 0
function SD.heartbeat()
    policeESPTick = policeESPTick + 1
    if policeESPTick >= 30 then
        policeESPTick = 0
        if S.PoliceESP then
            SD.updatePoliceESP()
        else
            SD.clearPoliceESP()
        end
    end
end

function SD.cleanup()
    SD.stopAutoFarm()
    SD.clearPoliceESP()
end

return SD
end
