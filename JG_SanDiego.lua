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

local function stopMovement()
    if currentMoveCleanup then
        pcall(function() currentMoveCleanup() end)
        currentMoveCleanup = nil
    end
end

local function groundMoveTo(targetPos, speed)
    stopMovement()
    local ch = LP.Character
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    speed = speed or 300
    local alive = true
    
    local noclipConn = RS.Stepped:Connect(function()
        if not alive then return end
        pcall(function()
            for _, p in pairs(ch:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    end)
    
    currentMoveCleanup = function()
        alive = false
        pcall(function() noclipConn:Disconnect() end)
    end

    while alive and SD.AutoFarmActive do
        local currentPos = hrp.Position
        local diff = targetPos - currentPos
        local dist = diff.Magnitude
        if dist < 4 then break end
        
        local dir = diff.Unit
        local moveStep = dir * (speed * task.wait())
        if moveStep.Magnitude > dist then
            hrp.CFrame = CFnew(targetPos)
        else
            hrp.CFrame = CFnew(currentPos + moveStep, targetPos)
        end
    end
    stopMovement()
end

local function fireProximityPrompt(prompt)
    if not prompt then return end
    pcall(function()
        local oldDist = prompt.MaxActivationDistance
        prompt.MaxActivationDistance = 9999
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.2)
        prompt.MaxActivationDistance = oldDist
    end)
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

local function findNearestArea(names)
    local ch = LP.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = ch.HumanoidRootPart.Position
    local nearestPos = nil
    local nearestDist = mathhuge

    for _, name in ipairs(names) do
        local nameLow = name:lower()
        for _, child in ipairs(ws:GetDescendants()) do
            if child.Name:lower() == nameLow or string_find(child.Name:lower(), nameLow) then
                local pos = getPartPosition(child)
                if pos then
                    local d = (myPos - pos).Magnitude
                    if d < nearestDist then
                        nearestDist = d
                        nearestPos = pos
                    end
                end
            end
        end
    end
    return nearestPos
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
    pcall(function() if firesignal then firesignal(btn.MouseButton1Click) end end)
    pcall(function() if firesignal then firesignal(btn.Activated) end end)
    return true
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

local function interactPromptNear(name, actionText)
    local ch = LP.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") then return false end
    local hrp = ch.HumanoidRootPart

    local target = findNPC(name)
    if not target then
        for _, child in ipairs(ws:GetDescendants()) do
            if child.Name == name or string_find(child.Name:lower(), name:lower()) then
                target = child
                break
            end
        end
    end

    if target then
        local pos = getPartPosition(target)
        if pos then
            if (hrp.Position - pos).Magnitude > 8 then
                groundMoveTo(pos, 300)
                task.wait(0.2)
            end
            local pp = findProximityPrompt(target, actionText) or findProximityPrompt(target.Parent, actionText)
            if pp then
                fireProximityPrompt(pp)
                return true
            end
        end
    end
    return false
end

local function buyRings()
    setStatus("Покупка колец...")
    local bought = false
    local buyTargets = {{"Fake Diamond Ring","Buy"}, {"Ring","Buy"}, {"Jewelry","Buy"}}
    for _, pair in ipairs(buyTargets) do
        if bought then break end
        bought = interactPromptNear(pair[1], pair[2])
    end
    if not bought then
        local remotes = {"BuyRing","PurchaseRing","BuyItem"}
        for _, rn in ipairs(remotes) do
            if tryFireRemote(rn, "Fake Diamond Ring") then bought = true break end
        end
    end
    if not bought then
        local btn = findButtonInGUI("Buy")
        if btn then clickButton(btn) bought = true end
    end
    return bought
end

local function sellGoods()
    setStatus("Продажа...")
    local sold = false
    local sellTargets = {{"Smuggled Goods Seller","Sell"}, {"Seller","Sell"}, {"Goods","Sell"}}
    for _, pair in ipairs(sellTargets) do
        if sold then break end
        sold = interactPromptNear(pair[1], pair[2])
    end
    if not sold then
        tryFireRemote("SellGoods")
    end
    return sold
end

local function launderMoney()
    setStatus("Отмывка...")
    local done = false
    local targets = {{"Launder",nil},{"Money Wash",nil},{"Wash","Launder"}}
    for _, pair in ipairs(targets) do
        if done then break end
        done = interactPromptNear(pair[1], pair[2])
    end
    if not done then
        tryFireRemote("LaunderMoney")
    end
    return done
end

local function doRingFarmCycle()
    if not SD.AutoFarmActive then return end
    local marketPos = findNearestArea({"BlackMarket","Black Market","GoodsMarket","Market","Jewelry"})
    if marketPos then
        groundMoveTo(marketPos, 300)
        task.wait(0.3)
    end
    for i = 1, 5 do
        if not SD.AutoFarmActive then return end
        buyRings()
        task.wait(0.5)
    end
    if not SD.AutoFarmActive then return end
    local sellerPos = findNearestArea({"Smuggled Goods Seller","GoodsSeller","Seller","SellGoods"})
    if sellerPos then
        groundMoveTo(sellerPos, 300)
        task.wait(0.3)
    end
    sellGoods()
    task.wait(0.5)
    if not SD.AutoFarmActive then return end
    local launderPos = findNearestArea({"Launder","MoneyWash","Money Wash","Wash"})
    if launderPos then
        groundMoveTo(launderPos, 300)
        task.wait(0.3)
    end
    launderMoney()
    task.wait(0.5)
    SD.AutoFarmLaps = SD.AutoFarmLaps + 1
end

function SD.startAutoFarm()
    if SD.AutoFarmActive then return end
    SD.AutoFarmActive = true
    SD.AutoFarmLaps = 0
    task.spawn(function()
        while SD.AutoFarmActive do
            pcall(function() doRingFarmCycle() end)
            task.wait(1)
        end
        stopMovement()
        setStatus("Остановлено")
    end)
end

function SD.stopAutoFarm()
    SD.AutoFarmActive = false
    stopMovement()
    setStatus("Остановлено")
end

function SD.getPlayerListFiltered(searchText)
    local result = {}
    searchText = (searchText or ""):lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            if searchText == "" or string_find(p.Name:lower(), searchText) or string_find(p.DisplayName:lower(), searchText) then
                table_insert(result, {
                    player = p,
                    name = p.Name,
                    displayName = p.DisplayName,
                    role = isPolice(p) and "Police" or "Civilian"
                })
            end
        end
    end
    return result
end

function SD.teleportToPlayer(playerName)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == playerName or p.DisplayName == playerName then
            local ch = p.Character
            if ch and ch:FindFirstChild("HumanoidRootPart") then
                local myCh = LP.Character
                if myCh and myCh:FindFirstChild("HumanoidRootPart") then
                    myCh.HumanoidRootPart.CFrame = ch.HumanoidRootPart.CFrame * CFnew(0, 0, 3)
                    return true
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
    stopMovement()
end

return SD
end
