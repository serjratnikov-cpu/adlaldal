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

local TEAM_NAMES_POLICE = {"police","border patrol","fbi","swat","bortac","army","sheriff","trooper","marshal","officer","cop","patrol"}

local function isPolice(player)
    if not player then return false end
    local team = player.Team
    if team then
        local tLow = string_lower(team.Name)
        for _, n in ipairs(TEAM_NAMES_POLICE) do
            if string_find(tLow, n) then return true end
        end
    end
    local ch = player.Character
    if ch then
        for _, desc in ipairs(ch:GetDescendants()) do
            if desc:IsA("Accessory") or desc:IsA("Shirt") or desc:IsA("Pants") then
                local dLow = string_lower(desc.Name)
                for _, n in ipairs(TEAM_NAMES_POLICE) do
                    if string_find(dLow, n) then return true end
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

local function flyTo(targetPos, speed)
    stopCurrentFly()
    local ch = LP.Character
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    speed = speed or (S.AutoFarmSpeed or 70)
    local alive = true
    local noclipConn

    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end)
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end)

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = V3new(mathhuge, mathhuge, mathhuge)
    bv.Velocity = V3new(0, 0, 0)
    bv.Parent = hrp

    currentFlyCleanup = function()
        alive = false
        if noclipConn then noclipConn:Disconnect() end
        if bv then bv:Destroy() end
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true) end)
        currentFlyCleanup = nil
    end

    noclipConn = RS.Stepped:Connect(function()
        if ch then
            for _, p in ipairs(ch:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
    
    while alive and SD.AutoFarmActive do
        if not hrp or not hrp.Parent then break end
        
        local currentPos = hrp.Position
        local dist = (currentPos - targetPos).Magnitude
        
        if dist < 4 then break end
        
        local dir = (targetPos - currentPos).Unit
        local dt = task.wait()
        
        local moveDist = speed * dt
        if moveDist > dist then moveDist = dist end
        
        hrp.CFrame = CFnew(currentPos + (dir * moveDist))
        hrp.Velocity = V3new(0, 0, 0)
        hrp.RotVelocity = V3new(0, 0, 0)
    end<!--citation:2-->

    stopCurrentFly()
    task.wait(0.2)
end

local function findPrompt(keywords)
    for _, desc in ipairs(ws:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            local txt = string_lower(desc.ActionText or "") .. " " .. string_lower(desc.ObjectText or "") .. " " .. string_lower(desc.Parent and desc.Parent.Name or "")
            for _, word in ipairs(keywords) do
                if string_find(txt, word) then
                    return desc
                end
            end
        end
    end
    return nil
end

local function getPromptPos(prompt)
    if not prompt then return nil end
    local p = prompt.Parent
    if p and p:IsA("BasePart") then return p.Position end
    if p and p:IsA("Model") then
        if p.PrimaryPart then return p.PrimaryPart.Position end
        local bp = p:FindFirstChildWhichIsA("BasePart")
        if bp then return bp.Position end
    end
    local p2 = prompt:FindFirstAncestorWhichIsA("BasePart")
    if p2 then return p2.Position end
    return nil
end

local function firePrompt(prompt)
    if not prompt then return end
    pcall(function()
        local oldDist = prompt.MaxActivationDistance
        local oldLoS = prompt.RequiresLineOfSight
        prompt.MaxActivationDistance = mathhuge
        prompt.RequiresLineOfSight = false
        if fireproximityprompt then
            fireproximityprompt(prompt)
        else
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration + 0.1)
            prompt:InputHoldEnd()
        end
        task.wait(0.3)
        prompt.MaxActivationDistance = oldDist
        prompt.RequiresLineOfSight = oldLoS
    end)
end

local function findButtonInGUI(bName)
    local pg = LP.PlayerGui
    if not pg then return nil end
    local bLow = string_lower(bName)
    for _, gui in ipairs(pg:GetDescendants()) do
        if (gui:IsA("TextButton") or gui:IsA("ImageButton")) then
            local vis = true
            pcall(function() vis = gui.Visible end)
            if vis then
                if gui.Name and string_find(string_lower(gui.Name), bLow) then return gui end
                if gui:IsA("TextButton") and gui.Text and string_find(string_lower(gui.Text), bLow) then return gui end
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

local function tryFireRemote(name)
    local rs = game:GetService("ReplicatedStorage")
    for _, child in ipairs(rs:GetDescendants()) do
        if child:IsA("RemoteEvent") and string_find(string_lower(child.Name), string_lower(name)) then
            pcall(function() child:FireServer("Fake Diamond Ring") end)
            return true
        end
    end
    return false
end

local function doFarmCycle()
    if not SD.AutoFarmActive then return end

    local buyPrompt = findPrompt({"buy ring", "fake diamond", "ring", "buy", "black market"})
    local buyPos = getPromptPos(buyPrompt)
    
    if buyPos then
        setStatus("Полет к магазину...")
        flyTo(buyPos + V3new(0, 3, 0), S.AutoFarmSpeed or 70)
        task.wait(0.5)
        for i = 1, 5 do
            if not SD.AutoFarmActive then return end
            setStatus("Покупка " .. i .. "/5")
            firePrompt(buyPrompt)
            tryFireRemote("BuyRing")
            tryFireRemote("Buy")
            local btn = findButtonInGUI("Buy") or findButtonInGUI("Purchase")
            if btn then clickButton(btn) end
            task.wait(0.5)
        end
    else
        setStatus("Не найден магазин (ищите ближе)")
        task.wait(2)
    end

    if not SD.AutoFarmActive then return end

    local sellPrompt = findPrompt({"sell goods", "smuggled", "seller", "smuggler", "sell"})
    local sellPos = getPromptPos(sellPrompt)

    if sellPos then
        setStatus("Полет к продавцу...")
        flyTo(sellPos + V3new(0, 3, 0), S.AutoFarmSpeed or 70)
        task.wait(0.5)
        setStatus("Продажа...")
        firePrompt(sellPrompt)
        tryFireRemote("SellGoods")
        tryFireRemote("Sell")
        local btn = findButtonInGUI("Sell")
        if btn then clickButton(btn) end
        task.wait(1)
    else
        setStatus("Не найден продавец (ищите ближе)")
        task.wait(2)
    end

    if not SD.AutoFarmActive then return end

    local launderPrompt = findPrompt({"launder", "wash money", "money wash", "wash"})
    local washPos = getPromptPos(launderPrompt)

    if washPos then
        setStatus("Полет к отмывке...")
        flyTo(washPos + V3new(0, 3, 0), S.AutoFarmSpeed or 70)
        task.wait(0.5)
        setStatus("Отмывка...")
        firePrompt(launderPrompt)
        tryFireRemote("Launder")
        tryFireRemote("Wash")
        local btn = findButtonInGUI("Launder") or findButtonInGUI("Wash")
        if btn then clickButton(btn) end
        task.wait(1)
    else
        setStatus("Не найдена отмывка (ищите ближе)")
        task.wait(2)
    end

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
    searchText = string_lower(searchText or "")
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local ch = p.Character
            if ch then
                if searchText == "" or string_find(string_lower(p.Name), searchText) or string_find(string_lower(p.DisplayName), searchText) then
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
    table.sort(result, function(a, b) return string_lower(a.name) < string_lower(b.name) end)
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
