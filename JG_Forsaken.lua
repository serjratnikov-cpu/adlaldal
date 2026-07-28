return function(S, getTargets, isValid, Players, LP, mathhuge, mathfloor, Vector3new, CFramenew, Color3RGB, task, pcall, workspace, table_insert)

local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

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

local ITEM_NAMES = {
    ["Medkit"]          = {fill = Color3RGB(0, 255, 100),  outline = Color3RGB(0, 200, 80),   label = "Medkit"},
    ["Bloxy Cola"]      = {fill = Color3RGB(0, 170, 255),  outline = Color3RGB(0, 130, 220),  label = "Bloxy Cola"},
    ["BloxyCola"]       = {fill = Color3RGB(0, 170, 255),  outline = Color3RGB(0, 130, 220),  label = "Bloxy Cola"},
    ["Bloxiade"]        = {fill = Color3RGB(0, 170, 255),  outline = Color3RGB(0, 130, 220),  label = "Bloxiade"},
    ["Bloxy Cola Test"] = {fill = Color3RGB(0, 170, 255),  outline = Color3RGB(0, 130, 220),  label = "Bloxy Cola Test"},
    ["BloxyColaTest"]   = {fill = Color3RGB(0, 170, 255),  outline = Color3RGB(0, 130, 220),  label = "Bloxy Cola Test"},
    ["Fake Bloxy Cola"] = {fill = Color3RGB(180, 80, 80),  outline = Color3RGB(150, 50, 50),  label = "Fake Bloxy Cola"},
    ["Fake Medkit"]     = {fill = Color3RGB(180, 80, 80),  outline = Color3RGB(150, 50, 50),  label = "Fake Medkit"},
    ["Flashlight"]      = {fill = Color3RGB(255, 255, 150),outline = Color3RGB(220, 220, 100),label = "Flashlight"},
    ["Epicsauce"]       = {fill = Color3RGB(255, 120, 0),  outline = Color3RGB(220, 100, 0),  label = "Epicsauce"},
    ["Glock"]           = {fill = Color3RGB(200, 200, 200),outline = Color3RGB(160, 160, 160),label = "Glock"},
    ["Glock 19"]        = {fill = Color3RGB(200, 200, 200),outline = Color3RGB(160, 160, 160),label = "Glock"},
    ["Assault Rifle"]   = {fill = Color3RGB(200, 200, 200),outline = Color3RGB(160, 160, 160),label = "Assault Rifle"},
    ["Broadsword"]      = {fill = Color3RGB(200, 200, 200),outline = Color3RGB(160, 160, 160),label = "Broadsword"},
    ["Gravity Gun"]     = {fill = Color3RGB(180, 100, 255),outline = Color3RGB(140, 60, 220), label = "Gravity Gun"},
    ["GravityGun"]      = {fill = Color3RGB(180, 100, 255),outline = Color3RGB(140, 60, 220), label = "Gravity Gun"},
    ["Green Key"]       = {fill = Color3RGB(0, 255, 100),  outline = Color3RGB(0, 200, 80),   label = "Green Key"},
    ["GreenKey"]        = {fill = Color3RGB(0, 255, 100),  outline = Color3RGB(0, 200, 80),   label = "Green Key"},
}

local ITEM_LOOKUP = {}
for name, info in pairs(ITEM_NAMES) do
    ITEM_LOOKUP[name:lower()] = info
end

local function getItemInfo(rawName)
    if not rawName then return nil end
    local n = rawName:lower()
    if ITEM_LOOKUP[n] then return ITEM_LOOKUP[n] end
    if n:find("bloxy") and n:find("cola") then return ITEM_LOOKUP["bloxy cola"] end
    if n:find("medkit") then return ITEM_LOOKUP["medkit"] end
    if n:find("bloxiade") then return ITEM_LOOKUP["bloxiade"] end
    if n:find("flashlight") then return ITEM_LOOKUP["flashlight"] end
    if n:find("epicsauce") then return ITEM_LOOKUP["epicsauce"] end
    if n:find("glock") then return ITEM_LOOKUP["glock"] end
    if n:find("assault") and n:find("rifle") then return ITEM_LOOKUP["assault rifle"] end
    if n:find("broadsword") then return ITEM_LOOKUP["broadsword"] end
    if n:find("gravity") then return ITEM_LOOKUP["gravity gun"] end
    if n:find("green") and n:find("key") then return ITEM_LOOKUP["green key"] end
    return nil
end

local itemESPCache = {}
local cachedItems = {}

local function isInPlayer(obj)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character and obj:IsDescendantOf(plr.Character) then return true end
        if obj:IsDescendantOf(plr) then return true end
    end
    return false
end

local function isItemOnMap(obj)
    if not obj or not obj.Parent then return false end
    if isInPlayer(obj) then return false end
    if obj:IsA("Tool") then
        local p = obj.Parent
        if p:IsA("Backpack") or p:FindFirstChildOfClass("Humanoid") then return false end
        return obj:IsDescendantOf(workspace)
    end
    if obj:IsA("Model") then
        return obj:IsDescendantOf(workspace) and (obj.PrimaryPart ~= nil or obj:FindFirstChildWhichIsA("BasePart") ~= nil)
    end
    if obj:IsA("BasePart") then
        return obj:IsDescendantOf(workspace)
    end
    return false
end

local function getToolPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    local handle = obj:FindFirstChild("Handle")
    if handle and handle:IsA("BasePart") then return handle end
    if obj:IsA("Model") and obj.PrimaryPart then return obj.PrimaryPart end
    for _, c in pairs(obj:GetDescendants()) do
        if c:IsA("BasePart") and c.Transparency < 1 then return c end
    end
    if obj:IsA("Model") then
        return obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function addItemESP(obj, info)
    if itemESPCache[obj] then return end
    local part = getToolPart(obj)
    if not part then return end

    local hl = Instance.new("Highlight")
    hl.Name = "_IH"
    hl.FillColor = info.fill
    hl.FillTransparency = 0.5
    hl.OutlineColor = info.outline
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = obj

    local bb = Instance.new("BillboardGui")
    bb.Name = "_IB"
    bb.Adornee = part
    bb.Size = UDim2.fromOffset(180, 35)
    bb.StudsOffset = Vector3new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    bb.Parent = part

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

    itemESPCache[obj] = {highlight = hl, billboard = bb, textLabel = tl, part = part, info = info}
end

local function removeItemESP(obj)
    local data = itemESPCache[obj]
    if data then
        pcall(function() data.highlight:Destroy() end)
        pcall(function() data.billboard:Destroy() end)
        itemESPCache[obj] = nil
    end
end

local function clearAllItemESP()
    for obj, data in pairs(itemESPCache) do
        pcall(function() data.highlight:Destroy() end)
        pcall(function() data.billboard:Destroy() end)
    end
    itemESPCache = {}
end

local function scanItems()
    local newList = {}
    local seen = {}
    pcall(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if not seen[obj] and getItemInfo(obj.Name) and isItemOnMap(obj) then
                if obj:IsA("Tool") or obj:IsA("Model") or (obj:IsA("BasePart") and obj.Parent == workspace) then
                    seen[obj] = true
                    table_insert(newList, obj)
                end
            end
        end
    end)
    cachedItems = newList
end

task.spawn(function()
    while true do
        scanItems()
        task.wait(1.5)
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
    for _, obj in pairs(cachedItems) do
        if obj and obj.Parent and isItemOnMap(obj) then
            alive[obj] = true
            local info = getItemInfo(obj.Name)
            if info then
                if not itemESPCache[obj] then addItemESP(obj, info) end
                local data = itemESPCache[obj]
                if data and data.textLabel then
                    local part = data.part
                    if not part or not part.Parent then
                        part = getToolPart(obj)
                        if part then data.part = part; data.billboard.Adornee = part; data.billboard.Parent = part end
                    end
                    if part and myHRP then
                        local dist = mathfloor((myHRP.Position - part.Position).Magnitude)
                        data.textLabel.Text = info.label .. " [" .. dist .. "m]"
                    else
                        data.textLabel.Text = info.label
                    end
                end
            end
        end
    end

    for obj, _ in pairs(itemESPCache) do
        if not alive[obj] then removeItemESP(obj) end
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

local function pressKey(key)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end)
end

local function fireAllProximity(obj)
    pcall(function()
        for _, d in pairs(obj:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                pcall(function()
                    local origDist = d.MaxActivationDistance
                    local origTime = d.HoldDuration
                    d.MaxActivationDistance = 1000
                    d.HoldDuration = 0
                    fireproximityprompt(d)
                    task.wait(0.05)
                    d.MaxActivationDistance = origDist
                    d.HoldDuration = origTime
                end)
            end
        end
        if obj:IsA("ProximityPrompt") then
            pcall(function() fireproximityprompt(obj) end)
        end
    end)
end

local function fireAllClicks(obj)
    pcall(function()
        for _, d in pairs(obj:GetDescendants()) do
            if d:IsA("ClickDetector") then pcall(function() fireclickdetector(d) end) end
        end
    end)
end

local function isPickedUp(obj)
    if not obj or not obj.Parent then return true end
    if obj:IsA("Tool") then
        local p = obj.Parent
        if p:IsA("Backpack") or p:FindFirstChildOfClass("Humanoid") then return true end
    end
    return isInPlayer(obj)
end

local function collectItem(obj, savedCFrame)
    local c = LP.Character
    if not c then return false end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local part = getToolPart(obj)
    if not part then return false end

    for attempt = 1, 4 do
        if isPickedUp(obj) then return true end
        if not obj or not obj.Parent then return true end
        part = getToolPart(obj) or part
        if part and part.Parent then
            hrp.CFrame = CFramenew(part.Position + Vector3new(0, 2, 0))
        end
        task.wait(0.15)
        fireAllProximity(obj)
        fireAllClicks(obj)
        pressKey(Enum.KeyCode.E)
        pressKey(Enum.KeyCode.F)
        if obj:IsA("Tool") then pcall(function() obj.Parent = c end) end
        task.wait(0.2)
        if isPickedUp(obj) then return true end
    end
    return isPickedUp(obj)
end

local function tpToItemsByFilter(filterFn)
    local c = LP.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local sv = hrp.CFrame
    task.spawn(function()
        scanItems()
        local items = {}
        for _, obj in pairs(cachedItems) do
            if filterFn(obj) then table_insert(items, obj) end
        end
        if #items == 0 then return end
        table.sort(items, function(a, b)
            local pa, pb = getToolPart(a), getToolPart(b)
            if not pa then return false end
            if not pb then return true end
            return (pa.Position - sv.Position).Magnitude < (pb.Position - sv.Position).Magnitude
        end)
        collectItem(items[1], sv)
        task.wait(0.15)
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            LP.Character.HumanoidRootPart.CFrame = sv
        end
    end)
end

local function tpBloxyCola()
    tpToItemsByFilter(function(o)
        local n = o.Name:lower()
        return (n:find("bloxy") and n:find("cola")) or n:find("bloxiade")
    end)
end

local function tpMedkit()
    tpToItemsByFilter(function(o)
        local n = o.Name:lower()
        return n:find("medkit") and not n:find("fake")
    end)
end

local function tpNearestItem()
    local c = LP.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local sv = hrp.CFrame
    task.spawn(function()
        scanItems()
        local best, bd = nil, mathhuge
        for _, obj in pairs(cachedItems) do
            local info = getItemInfo(obj.Name)
            local n = obj.Name:lower()
            if info and not n:find("fake") then
                local p = getToolPart(obj)
                if p then
                    local d = (p.Position - hrp.Position).Magnitude
                    if d < bd then bd = d best = obj end
                end
            end
        end
        if best then
            collectItem(best, sv)
            task.wait(0.15)
            if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                LP.Character.HumanoidRootPart.CFrame = sv
            end
        end
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

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
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
                for _, o in pairs(genCache) do
                    if o and o.Parent then aHL(o, "_GH", Color3RGB(255,200,0), Color3RGB(255,160,0)) end
                end
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
    getPlayerListForDropdown = function()
        local list = {}
        for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table_insert(list, p.Name) end end
        return list
    end,
    clearHitboxes = function() end,
    clearAllItemESP = clearAllItemESP,
}
end
