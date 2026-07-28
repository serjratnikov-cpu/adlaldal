return function(S, getTargets, isValid, Players, LP, mathhuge, mathfloor, Vector3new, CFramenew, Color3RGB, task, pcall, workspace, table_insert)

local VirtualInputManager = game:GetService("VirtualInputManager")
local RS = game:GetService("RunService")

local function aHL(p,n,fc,oc)
    if p:FindFirstChild(n) then return end
    local h=Instance.new("Highlight") h.Name=n h.FillColor=fc h.FillTransparency=0.4
    h.OutlineColor=oc h.OutlineTransparency=0 h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop h.Parent=p
end

local function aBB(p,n,t,co,ad)
    local bb=p:FindFirstChild(n)
    if not bb then
        bb=Instance.new("BillboardGui") bb.Name=n bb.Adornee=ad or p
        bb.Size=UDim2.fromOffset(200,40) bb.StudsOffset=Vector3new(0,3,0) bb.AlwaysOnTop=true bb.ZIndexBehavior=Enum.ZIndexBehavior.Sibling bb.Parent=p
        local tl=Instance.new("TextLabel") tl.Parent=bb tl.BackgroundTransparency=1 tl.Size=UDim2.new(1,0,1,0)
        tl.Font=Enum.Font.GothamBold tl.Text=t tl.TextColor3=co tl.TextSize=14 tl.TextScaled=true
        tl.TextStrokeTransparency=0.5 tl.TextStrokeColor3=Color3RGB(0,0,0) tl.ZIndex=10
    else
        local tl=bb:FindFirstChildOfClass("TextLabel")
        if tl then tl.Text=t tl.TextColor3=co end
    end
end

local function rm(p,a,b)
    local x=p:FindFirstChild(a) if x then x:Destroy() end
    local y=p:FindFirstChild(b) if y then y:Destroy() end
end

local function rmAllGenESP(obj)
    pcall(function()
        for _, d in pairs(obj:GetDescendants()) do
            if d.Name == "_GH" or d.Name == "_GB" then d:Destroy() end
        end
        local a = obj:FindFirstChild("_GH") if a then a:Destroy() end
        local b = obj:FindFirstChild("_GB") if b then b:Destroy() end
    end)
end

local ITEM_NAMES = {
    ["Medkit"]          = {fill = Color3RGB(0, 255, 100),  outline = Color3RGB(0, 200, 80),   label = "Medkit"},
    ["Bloxy Cola"]      = {fill = Color3RGB(0, 170, 255),  outline = Color3RGB(0, 130, 220),  label = "Bloxy Cola"},
    ["Bloxiade"]        = {fill = Color3RGB(0, 170, 255),  outline = Color3RGB(0, 130, 220),  label = "Bloxiade"},
    ["BloxyColaTest"]   = {fill = Color3RGB(0, 170, 255),  outline = Color3RGB(0, 130, 220),  label = "Bloxy Cola Test"},
    ["Fake Bloxy Cola"] = {fill = Color3RGB(180, 80, 80),  outline = Color3RGB(150, 50, 50),  label = "Fake Bloxy Cola"},
    ["Fake Medkit"]     = {fill = Color3RGB(180, 80, 80),  outline = Color3RGB(150, 50, 50),  label = "Fake Medkit"},
    ["Flashlight"]      = {fill = Color3RGB(255, 255, 150),outline = Color3RGB(220, 220, 100),label = "Flashlight"},
    ["Epicsauce"]       = {fill = Color3RGB(255, 120, 0),  outline = Color3RGB(220, 100, 0),  label = "Epicsauce"},
    ["Glock"]           = {fill = Color3RGB(200, 200, 200),outline = Color3RGB(160, 160, 160),label = "Glock"},
    ["Assault Rifle"]   = {fill = Color3RGB(200, 200, 200),outline = Color3RGB(160, 160, 160),label = "Assault Rifle"},
    ["Broadsword"]      = {fill = Color3RGB(200, 200, 200),outline = Color3RGB(160, 160, 160),label = "Broadsword"},
    ["Gravity Gun"]     = {fill = Color3RGB(180, 100, 255),outline = Color3RGB(140, 60, 220), label = "Gravity Gun"},
    ["Green Key"]       = {fill = Color3RGB(0, 255, 100),  outline = Color3RGB(0, 200, 80),   label = "Green Key"},
}

local ITEM_LOOKUP = {}
for name, info in pairs(ITEM_NAMES) do
    ITEM_LOOKUP[name:lower()] = info
end

local itemESPCache = {}
local cachedItems = {}

local function getItemInfo(toolName) return ITEM_LOOKUP[toolName:lower()] end

local function isItemOnMap(tool)
    if not tool or not tool.Parent then return false end
    if not tool:IsA("Tool") then return false end
    if tool:IsDescendantOf(Players) then return false end
    local p = tool.Parent
    if p:IsA("Backpack") or p:FindFirstChildOfClass("Humanoid") then return false end
    return tool:IsDescendantOf(workspace)
end

local function getToolPart(tool)
    if not tool then return nil end
    local handle = tool:FindFirstChild("Handle")
    if handle and handle:IsA("BasePart") then return handle end
    for _, c in pairs(tool:GetDescendants()) do
        if c:IsA("BasePart") and c.Transparency < 1 then return c end
    end
    return nil
end

local function addItemESP(tool, info)
    if itemESPCache[tool] then return end
    local part = getToolPart(tool)
    if not part then return end
    local hl = Instance.new("Highlight")
    hl.Name = "_IH"
    hl.FillColor = info.fill
    hl.FillTransparency = 0.5
    hl.OutlineColor = info.outline
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = tool
    local bb = Instance.new("BillboardGui")
    bb.Name = "_IB"
    bb.Adornee = part
    bb.Size = UDim2.fromOffset(180, 35)
    bb.StudsOffset = Vector3new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    bb.Parent = tool
    local tl = Instance.new("TextLabel")
    tl.Parent = bb
    tl.BackgroundTransparency = 1
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.Font = Enum.Font.GothamBold
    tl.TextColor3 = info.outline
    tl.TextSize = 13
    tl.TextScaled = true
    tl.TextStrokeTransparency = 0.4
    tl.TextStrokeColor3 = Color3RGB(0, 0, 0)
    tl.ZIndex = 10
    tl.Text = info.label
    itemESPCache[tool] = {highlight = hl, billboard = bb, textLabel = tl, part = part, info = info}
end

local function removeItemESP(tool)
    local data = itemESPCache[tool]
    if data then
        pcall(function() data.highlight:Destroy() end)
        pcall(function() data.billboard:Destroy() end)
        itemESPCache[tool] = nil
    end
end

local function clearAllItemESP()
    for tool, data in pairs(itemESPCache) do
        pcall(function() data.highlight:Destroy() end)
        pcall(function() data.billboard:Destroy() end)
    end
    itemESPCache = {}
end

task.spawn(function()
    while true do
        local newList = {}
        pcall(function()
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("Tool") and getItemInfo(obj.Name) and isItemOnMap(obj) then
                    table_insert(newList, obj)
                end
            end
        end)
        cachedItems = newList
        task.wait(2)
    end
end)

local function updateItemESP()
    if not S.ItemESP then
        clearAllItemESP()
        return
    end
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local alive = {}
    for _, tool in pairs(cachedItems) do
        if tool and tool.Parent and isItemOnMap(tool) then
            alive[tool] = true
            local info = getItemInfo(tool.Name)
            if info then
                if not itemESPCache[tool] then addItemESP(tool, info) end
                local data = itemESPCache[tool]
                if data and data.textLabel then
                    local part = data.part
                    if part and part.Parent and myHRP then
                        local dist = mathfloor((myHRP.Position - part.Position).Magnitude)
                        data.textLabel.Text = info.label .. " [" .. dist .. "m]"
                    else
                        data.textLabel.Text = info.label
                    end
                end
            end
        end
    end
    for tool, _ in pairs(itemESPCache) do
        if not alive[tool] then removeItemESP(tool) end
    end
end

local hitboxOriginals = {}

local function updateHitboxes()
    if not S.HitboxEnabled then
        for char, origSize in pairs(hitboxOriginals) do
            pcall(function()
                local head = char:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    head.Size = origSize
                    head.Transparency = 0
                    head.CanCollide = true
                end
            end)
        end
        hitboxOriginals = {}
        return
    end
    local targets = getTargets()
    for i = 1, #targets do
        local char = targets[i]
        local head = char:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            if not hitboxOriginals[char] then hitboxOriginals[char] = head.Size end
            local sz = S.HitboxSize
            head.Size = Vector3new(sz, sz, sz)
            head.Transparency = 0.7
            head.CanCollide = false
            head.Material = Enum.Material.Neon
            head.Color = Color3RGB(255, 0, 0)
        end
    end
end

local function teleportBehind(targetName)
    local myChar = LP.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local targetPlayer = nil
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name == targetName and p ~= LP then targetPlayer = p break end
    end
    if not targetPlayer then return end
    local targetChar = targetPlayer.Character
    if not targetChar then return end
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
    if not targetHum or targetHum.Health <= 0 then return end
    local behindPos = targetRoot.Position - (targetRoot.CFrame.LookVector * 4)
    myRoot.CFrame = CFramenew(behindPos, targetRoot.Position)
end

local function pressF()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    end)
end

local function fireAllProximity(obj)
    pcall(function()
        for _, d in pairs(obj:GetDescendants()) do if d:IsA("ProximityPrompt") then fireproximityprompt(d) end end
    end)
end

local function fireAllClicks(obj)
    pcall(function()
        for _, d in pairs(obj:GetDescendants()) do if d:IsA("ClickDetector") then fireclickdetector(d) end end
    end)
end

local function collectItem(obj, savedCFrame)
    local c = LP.Character
    if not c then return false end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local part = getToolPart(obj)
    if not part then return false end
    for attempt = 1, 2 do
        if not obj or not obj.Parent then return true end
        if not isItemOnMap(obj) then return true end
        hrp.CFrame = CFramenew(part.Position + Vector3new(0, 1, 0))
        task.wait(0.1)
        fireAllProximity(obj)
        pressF()
        fireAllClicks(obj)
        if obj:IsA("Tool") then pcall(function() obj.Parent = c end) end
        task.wait(0.1)
    end
    return false
end

local function tpBloxyCola()
    local c = LP.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local sv = hrp.CFrame
    task.spawn(function()
        local items = {}
        for _, tool in pairs(cachedItems) do
            if tool.Name:lower():find("cola") or tool.Name:lower():find("bloxiade") then table_insert(items, tool) end
        end
        if #items == 0 then return end
        collectItem(items[1], sv)
        task.wait(0.1)
        hrp.CFrame = sv
    end)
end

local function tpMedkit()
    local c = LP.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local sv = hrp.CFrame
    task.spawn(function()
        local items = {}
        for _, tool in pairs(cachedItems) do if tool.Name:lower():find("medkit") then table_insert(items, tool) end end
        if #items == 0 then return end
        collectItem(items[1], sv)
        task.wait(0.1)
        hrp.CFrame = sv
    end)
end

local function tpNearestItem()
    local c = LP.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local sv = hrp.CFrame
    task.spawn(function()
        local best, bd = nil, mathhuge
        for _, tool in pairs(cachedItems) do
            local p = getToolPart(tool)
            if p then
                local d = (p.Position - hrp.Position).Magnitude
                if d < bd then bd = d best = tool end
            end
        end
        if best then collectItem(best, sv) end
        task.wait(0.1)
        hrp.CFrame = sv
    end)
end

local genCache = {}

task.spawn(function()
    while true do
        pcall(function()
            local newCache = {}
            for _, v in pairs(workspace:GetDescendants()) do
                if v.Name:lower():find("generator") and (v:IsA("Model") or v:IsA("BasePart")) then
                    table_insert(newCache, v)
                end
            end
            genCache = newCache
        end)
        task.wait(5)
    end
end)

local staminaHooked = {}

local function hookStaminaOnChar(char)
    local function tryHook(obj)
        local n = obj.Name:lower()
        if (n:find("stamina") or n:find("energy") or n:find("sprint")) and (obj:IsA("NumberValue") or obj:IsA("IntValue") or obj:IsA("DoubleConstrainedValue")) then
            if staminaHooked[obj] then return end
            staminaHooked[obj] = true
            obj:GetPropertyChangedSignal("Value"):Connect(function()
                if S.InfStamina then
                    pcall(function() obj.Value = 100 end)
                end
            end)
        end
    end
    pcall(function()
        for _, v in pairs(char:GetDescendants()) do tryHook(v) end
        char.DescendantAdded:Connect(tryHook)
        local ps = LP:FindFirstChild("PlayerScripts")
        if ps then
            for _, v in pairs(ps:GetDescendants()) do tryHook(v) end
        end
    end)
end

local infStaminaConn

local function startInfStamina()
    if infStaminaConn then infStaminaConn:Disconnect() infStaminaConn = nil end
    infStaminaConn = RS.Heartbeat:Connect(function()
        if not S.InfStamina then
            infStaminaConn:Disconnect()
            infStaminaConn = nil
            return
        end
        pcall(function()
            local char = LP.Character
            if not char then return end
            for _, v in pairs(char:GetDescendants()) do
                local n = v.Name:lower()
                if (n:find("stamina") or n:find("energy") or n:find("sprint")) and (v:IsA("NumberValue") or v:IsA("IntValue") or v:IsA("DoubleConstrainedValue")) then
                    v.Value = 100
                end
            end
            local ps = LP:FindFirstChild("PlayerScripts")
            if ps then
                for _, v in pairs(ps:GetDescendants()) do
                    local n = v.Name:lower()
                    if (n:find("stamina") or n:find("energy") or n:find("sprint")) and (v:IsA("NumberValue") or v:IsA("IntValue") or v:IsA("DoubleConstrainedValue")) then
                        v.Value = 100
                    end
                end
            end
        end)
    end)
end

pcall(function()
    local c = LP.Character
    if c then hookStaminaOnChar(c) end
    LP.CharacterAdded:Connect(function(char)
        staminaHooked = {}
        hookStaminaOnChar(char)
    end)
end)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if S.InfStamina and not infStaminaConn then
                startInfStamina()
            end

            local mc = LP.Character
            local mh = mc and mc:FindFirstChild("HumanoidRootPart")
            local wp = workspace:FindFirstChild("Players")
            local killersF = wp and wp:FindFirstChild("Killers")
            local survF = wp and wp:FindFirstChild("Survivors")

            if killersF then
                for _, child in pairs(killersF:GetChildren()) do
                    if not child:FindFirstChild("HumanoidRootPart") then continue end
                    local dist = mh and mathfloor((mh.Position - child.HumanoidRootPart.Position).Magnitude) or 0
                    if S.KillerESP then aHL(child, "_KH", Color3RGB(255, 0, 0), Color3RGB(255, 0, 0)) aBB(child, "_KB", "[Killer] "..child.Name.." ["..dist.."m]", Color3RGB(255, 40, 40), child.PrimaryPart)
                    else rm(child, "_KH", "_KB") end
                end
            end

            if survF then
                for _, child in pairs(survF:GetChildren()) do
                    if not child:FindFirstChild("HumanoidRootPart") then continue end
                    local dist = mh and mathfloor((mh.Position - child.HumanoidRootPart.Position).Magnitude) or 0
                    if S.SurvESP then aHL(child, "_SH", Color3RGB(0,200,60), Color3RGB(90,255,130)) aBB(child, "_SB", "[Surv] "..child.Name.." ["..dist.."m]", Color3RGB(90,255,120), child.PrimaryPart)
                    else rm(child, "_SH", "_SB") end
                end
            end

            if S.GenESP then
                for _, o in pairs(genCache) do aHL(o, "_GH", Color3RGB(255,200,0), Color3RGB(255,160,0)) end
            end

            updateItemESP()
        end)
    end
end)

return {
    updateHitboxes = updateHitboxes,
    teleportBehind = teleportBehind,
    tpBloxyCola = tpBloxyCola,
    tpMedkit = tpMedkit,
    tpNearestItem = tpNearestItem,
    startInfStamina = startInfStamina,
    getPlayerListForDropdown = function()
        local list = {}
        for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table_insert(list, p.Name) end end
        return list
    end,
    clearHitboxes = function() end,
    clearAllItemESP = clearAllItemESP,
}
end
