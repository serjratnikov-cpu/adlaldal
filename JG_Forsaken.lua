return function(S, getTargets, isValid, Players, LP, mathhuge, mathfloor, Vector3new, CFramenew, Color3RGB, task, pcall, workspace, table_insert)

local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

-- ================= DEFAULT SETTINGS (если нет в S) =================
local function def(k, v) if S[k] == nil then S[k] = v end end
def("Invisibility", false)
def("FlyMod", false)
def("FlySpeedMod", 60)
def("NoclipMod", false)
def("JumpHack", false)
def("JumpHackPower", 120)
def("SpeedHack", false)
def("SpeedHackValue", 40)
def("InfStamina", false)
def("ChangeStamina", false)
def("StaminaValue", 100)
def("FakeGenESP", false)
def("DoneGenESP", false)
def("AutoGen", false)
def("RepairSpeed", 3)
def("RandomRepairSpeed", false)
def("CloseGenUI", false)
def("AutoBlock", false)
def("AutoBlockDistance", 12)
def("AntiBlindness", false)
def("AntiPopups", false)
def("AntiNolilaught", false)
def("AntiNoliClone", false)
def("KillerAutoFarmTP", false)
def("SurvivorAutoFarmTween", false)
def("SurvivorAutoFarmPath", false)
def("AutoFarmSpeed", 60)

-- ================= HELPERS =================
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
    if b then local y=p:FindFirstChild(b) if y then y:Destroy() end end
end

local function getHRP()
    local c = LP.Character
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = LP.Character
    if not c then return nil end
    return c:FindFirstChildOfClass("Humanoid")
end

-- ================= ITEM ESP DATA =================
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
for name, info in pairs(ITEM_NAMES) do ITEM_LOOKUP[name:lower()] = info end

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
    if obj:IsA("BasePart") then return obj:IsDescendantOf(workspace) end
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
    if obj:IsA("Model") then return obj:FindFirstChildWhichIsA("BasePart", true) end
    return nil
end

local function addItemESP(obj, info)
    if itemESPCache[obj] then return end
    local part = getToolPart(obj)
    if not part then return end
    local hl = Instance.new("Highlight")
    hl.Name = "_IH" hl.FillColor = info.fill hl.FillTransparency = 0.5
    hl.OutlineColor = info.outline hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop hl.Parent = obj
    local bb = Instance.new("BillboardGui")
    bb.Name = "_IB" bb.Adornee = part bb.Size = UDim2.fromOffset(180, 35)
    bb.StudsOffset = Vector3new(0, 2.5, 0) bb.AlwaysOnTop = true
    bb.ZIndexBehavior = Enum.ZIndexBehavior.Sibling bb.Parent = part
    local tl = Instance.new("TextLabel")
    tl.Parent = bb tl.BackgroundTransparency = 1 tl.Size = UDim2.new(1, 0, 1, 0)
    tl.Font = Enum.Font.GothamBold tl.TextColor3 = info.outline tl.TextSize = 13
    tl.TextScaled = true tl.TextStrokeTransparency = 0.4 tl.TextStrokeColor3 = Color3RGB(0, 0, 0)
    tl.ZIndex = 10 tl.Text = info.label
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
    while true do scanItems() task.wait(1.5) end
end)

local function updateItemESP()
    if not S.ItemESP then clearAllItemESP() return end
    local myHRP = getHRP()
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
                    else data.textLabel.Text = info.label end
                end
            end
        end
    end
    for obj, _ in pairs(itemESPCache) do
        if not alive[obj] then removeItemESP(obj) end
    end
end

-- ================= HITBOX =================
local hitboxOriginals = {}
local function updateHitboxes()
    if not S.HitboxEnabled then
        for char, origSize in pairs(hitboxOriginals) do
            pcall(function()
                local head = char:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    head.Size = origSize head.Transparency = 0 head.CanCollide = true
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
            head.Transparency = 0.7 head.CanCollide = false
            head.Material = Enum.Material.Neon head.Color = Color3RGB(255, 0, 0)
        end
    end
end

-- ================= TELEPORT BEHIND =================
local function teleportBehind(targetName)
    local myRoot = getHRP()
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

-- ================= ITEM COLLECT =================
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
                    d.MaxActivationDistance = 1000 d.HoldDuration = 0
                    fireproximityprompt(d)
                    task.wait(0.05)
                    d.MaxActivationDistance = origDist d.HoldDuration = origTime
                end)
            end
        end
        if obj:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(obj) end) end
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
    local hrp = getHRP()
    if not hrp then return false end
    local c = LP.Character
    local part = getToolPart(obj)
    if not part then return false end
    for attempt = 1, 4 do
        if isPickedUp(obj) then return true end
        if not obj or not obj.Parent then return true end
        part = getToolPart(obj) or part
        if part and part.Parent then hrp.CFrame = CFramenew(part.Position + Vector3new(0, 2, 0)) end
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
    local hrp = getHRP()
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
        local h = getHRP() if h then h.CFrame = sv end
    end)
end

local function tpBloxyCola()
    tpToItemsByFilter(function(o)
        local n = o.Name:lower()
        return (n:find("bloxy") and n:find("cola") and not n:find("fake")) or n:find("bloxiade")
    end)
end

local function tpMedkit()
    tpToItemsByFilter(function(o)
        local n = o.Name:lower()
        return n:find("medkit") and not n:find("fake")
    end)
end

local function tpNearestItem()
    local hrp = getHRP()
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
            local h = getHRP() if h then h.CFrame = sv end
        end
    end)
end

-- ================= BRING ALL ITEMS =================
local function bringAllItems()
    local hrp = getHRP()
    if not hrp then return end
    task.spawn(function()
        scanItems()
        local dropPos = hrp.Position + Vector3new(0, 0, 0)
        for i, obj in pairs(cachedItems) do
            pcall(function()
                if isItemOnMap(obj) then
                    local part = getToolPart(obj)
                    if part then
                        local offset = Vector3new((i % 5) * 3 - 6, 0, mathfloor(i / 5) * 3)
                        if obj:IsA("Model") and obj.PrimaryPart then
                            obj:SetPrimaryPartCFrame(CFramenew(dropPos + offset))
                        else
                            part.CFrame = CFramenew(dropPos + offset)
                        end
                    end
                end
            end)
        end
    end)
end

-- ================= DELETE ALL ITEMS =================
local function deleteAllItems()
    task.spawn(function()
        scanItems()
        for _, obj in pairs(cachedItems) do
            pcall(function()
                if isItemOnMap(obj) then obj:Destroy() end
            end)
        end
        clearAllItemESP()
        cachedItems = {}
    end)
end

-- ================= INVISIBILITY =================
local invisData = nil
local function toggleInvisibility()
    local c = LP.Character
    local hrp = getHRP()
    if not hrp then return end
    if S.Invisibility then
        pcall(function()
            local clone = hrp:Clone()
            for _, v in pairs(clone:GetChildren()) do v:Destroy() end
            clone.Transparency = 1
            local savedCF = hrp.CFrame
            c.Archivable = true
            hrp.CFrame = savedCF
            invisData = savedCF
            local hum = getHum()
            if hum then
                hrp:Destroy()
                hrp = c:FindFirstChild("HumanoidRootPart")
            end
        end)
    end
end

-- ================= FLY / NOCLIP / JUMP / SPEED (module versions) =================
local flyBody, flyGyro
local function stopFlyMod()
    pcall(function() if flyBody then flyBody:Destroy() flyBody=nil end end)
    pcall(function() if flyGyro then flyGyro:Destroy() flyGyro=nil end end)
end
local function startFlyMod()
    local hrp = getHRP() if not hrp then return end
    stopFlyMod()
    flyBody = Instance.new("BodyVelocity")
    flyBody.MaxForce = Vector3new(mathhuge, mathhuge, mathhuge)
    flyBody.Velocity = Vector3.zero flyBody.Parent = hrp
    flyGyro = Instance.new("BodyGyro")
    flyGyro.MaxTorque = Vector3new(mathhuge, mathhuge, mathhuge)
    flyGyro.P = 9e4 flyGyro.CFrame = hrp.CFrame flyGyro.Parent = hrp
end

local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
RunService.Heartbeat:Connect(function(dt)
    -- FLY
    if S.FlyMod then
        if not flyBody then startFlyMod() end
        if flyBody and flyGyro then
            local dir = Vector3.zero
            local cf = Camera.CFrame
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3new(0,1,0) end
            if dir.Magnitude > 0 then dir = dir.Unit end
            flyBody.Velocity = dir * S.FlySpeedMod
            flyGyro.CFrame = cf
        end
    else
        if flyBody then stopFlyMod() end
    end
    -- SPEED / JUMP
    local hum = getHum()
    local hrp = getHRP()
    if hum and hrp then
        if S.JumpHack then
            pcall(function() hum.JumpPower = S.JumpHackPower; hum.UseJumpPower = true end)
        end
        if S.SpeedHack and not S.FlyMod then
            local md = hum.MoveDirection
            if md.Magnitude > 0 then hrp.CFrame = hrp.CFrame + (md * S.SpeedHackValue * dt) end
        end
    end
end)

-- NOCLIP loop
local noclipTick = 0
RunService.Stepped:Connect(function()
    if not S.NoclipMod then return end
    noclipTick = noclipTick + 1
    if noclipTick < 3 then return end
    noclipTick = 0
    local c = LP.Character if not c then return end
    for _, p in pairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

-- ================= STAMINA (Inf / Change) =================
local function findStaminaObject()
    local c = LP.Character
    if not c then return nil end
    -- Пытаемся найти по разным путям
    local hum = c:FindFirstChildOfClass("Humanoid")
    -- attribute
    if hum then
        for _, attr in pairs({"Stamina", "stamina"}) do
            if hum:GetAttribute(attr) ~= nil then return {type="attr_hum", obj=hum, name=attr} end
        end
    end
    if c:GetAttribute("Stamina") ~= nil then return {type="attr_char", obj=c, name="Stamina"} end
    -- value objects
    for _, v in pairs(c:GetDescendants()) do
        if (v:IsA("NumberValue") or v:IsA("IntValue")) and v.Name:lower():find("stamina") then
            return {type="value", obj=v}
        end
    end
    -- в LP
    for _, v in pairs(LP:GetDescendants()) do
        if (v:IsA("NumberValue") or v:IsA("IntValue")) and v.Name:lower():find("stamina") then
            return {type="value", obj=v}
        end
    end
    return nil
end

task.spawn(function()
    while true do
        pcall(function()
            if S.InfStamina or S.ChangeStamina then
                local st = findStaminaObject()
                if st then
                    local val = S.InfStamina and 100 or (S.StaminaValue or 100)
                    if st.type == "value" then
                        st.obj.Value = val
                    elseif st.type == "attr_hum" or st.type == "attr_char" then
                        st.obj:SetAttribute(st.name, val)
                    end
                end
            end
        end)
        task.wait(0.1)
    end
end)

-- ================= GENERATORS =================
local genCache = {}
local function scanGenerators()
    local newCache = {}
    pcall(function()
        for _, v in pairs(workspace:GetDescendants()) do
            local ln = v.Name:lower()
            if (ln:find("generator") or ln:find("gen")) and (v:IsA("Model") or v:IsA("BasePart")) then
                -- фильтр чтобы не ловить "general" итд - проверяем что есть prompt или прогресс
                table_insert(newCache, v)
            end
        end
    end)
    genCache = newCache
end

task.spawn(function()
    while true do scanGenerators() task.wait(5) end
end)

local function isGenDone(gen)
    -- эвристика: ищем прогресс/атрибут завершения
    local prog = gen:GetAttribute("Progress") or gen:GetAttribute("Completed") or gen:GetAttribute("Done")
    if prog ~= nil then
        if typeof(prog) == "boolean" then return prog end
        if typeof(prog) == "number" then return prog >= 100 end
    end
    for _, v in pairs(gen:GetDescendants()) do
        if (v:IsA("NumberValue") or v:IsA("IntValue")) and v.Name:lower():find("progress") then
            return v.Value >= 100
        end
        if v:IsA("BoolValue") and (v.Name:lower():find("done") or v.Name:lower():find("complete")) then
            return v.Value
        end
    end
    return false
end

local function isGenFake(gen)
    local ln = gen.Name:lower()
    if ln:find("fake") then return true end
    if gen:GetAttribute("Fake") == true then return true end
    for _, v in pairs(gen:GetDescendants()) do
        if v:IsA("BoolValue") and v.Name:lower():find("fake") then return v.Value end
    end
    return false
end

-- ================= AUTO GENERATORS =================
local function fireGenRemotes(gen)
    -- Пытаемся найти remote для починки генератора и заспамить его
    pcall(function()
        for _, d in pairs(gen:GetDescendants()) do
            if d:IsA("RemoteEvent") then pcall(function() d:FireServer() end) end
            if d:IsA("RemoteFunction") then pcall(function() d:InvokeServer() end) end
        end
    end)
    -- глобальные remote в ReplicatedStorage
    pcall(function()
        for _, d in pairs(ReplicatedStorage:GetDescendants()) do
            local ln = d.Name:lower()
            if (d:IsA("RemoteEvent")) and (ln:find("gen") or ln:find("repair") or ln:find("fix")) then
                pcall(function() d:FireServer(gen) end)
            end
        end
    end)
    fireAllProximity(gen)
end

task.spawn(function()
    while true do
        if S.AutoGen then
            pcall(function()
                local hrp = getHRP()
                if hrp then
                    scanGenerators()
                    for _, gen in pairs(genCache) do
                        if not S.AutoGen then break end
                        if not isGenFake(gen) and not isGenDone(gen) then
                            local part = getToolPart(gen)
                            if part then
                                local sv = hrp.CFrame
                                hrp.CFrame = CFramenew(part.Position + Vector3new(0, 3, 0))
                                local wait = S.RandomRepairSpeed and (math.random(4,10)) or (S.RepairSpeed or 3)
                                local t0 = os.clock()
                                while (os.clock() - t0) < wait and S.AutoGen do
                                    fireGenRemotes(gen)
                                    if isGenDone(gen) then break end
                                    task.wait(0.3)
                                end
                                pcall(function()
                                    local h = getHRP() if h then h.CFrame = sv end
                                end)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- ================= CLOSE GENERATORS UI =================
local PlayerGui = LP:FindFirstChildOfClass("PlayerGui") or LP:WaitForChild("PlayerGui")
task.spawn(function()
    while true do
        if S.CloseGenUI then
            pcall(function()
                for _, gui in pairs(PlayerGui:GetChildren()) do
                    local ln = gui.Name:lower()
                    if gui:IsA("ScreenGui") and (ln:find("gen") or ln:find("repair") or ln:find("puzzle") or ln:find("numberlink") or ln:find("minigame")) then
                        gui.Enabled = false
                    end
                end
            end)
        end
        task.wait(0.3)
    end
end)

-- ================= AUTO BLOCK (Quest 1337) =================
local function fireBlockRemote()
    pcall(function()
        for _, d in pairs(ReplicatedStorage:GetDescendants()) do
            local ln = d.Name:lower()
            if d:IsA("RemoteEvent") and (ln:find("block") or ln:find("parry") or ln:find("counter")) then
                pcall(function() d:FireServer() end)
            end
        end
    end)
    -- нажатие клавиши блока (обычно F или ПКМ)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
    end)
end

task.spawn(function()
    while true do
        if S.AutoBlock then
            pcall(function()
                local hrp = getHRP()
                if hrp then
                    local dist = S.AutoBlockDistance or 12
                    -- Ищем киллера
                    local wp = workspace:FindFirstChild("Players")
                    local killersF = wp and wp:FindFirstChild("Killers")
                    if killersF then
                        for _, killer in pairs(killersF:GetChildren()) do
                            local kr = killer:FindFirstChild("HumanoidRootPart")
                            if kr and (kr.Position - hrp.Position).Magnitude <= dist then
                                fireBlockRemote()
                                break
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.15)
    end
end)

-- ================= ANTI BLINDNESS / POPUPS / NOLI =================
task.spawn(function()
    while true do
        pcall(function()
            -- Anti blindness (1x1x1x1) - убираем ослепляющие эффекты
            if S.AntiBlindness then
                for _, eff in pairs(Lighting:GetDescendants()) do
                    if eff:IsA("BlurEffect") or eff:IsA("ColorCorrectionEffect") then
                        pcall(function() eff.Enabled = false end)
                    end
                end
                for _, gui in pairs(PlayerGui:GetDescendants()) do
                    local ln = gui.Name:lower()
                    if (gui:IsA("Frame") or gui:IsA("ImageLabel")) and (ln:find("blind") or ln:find("flash") or ln:find("1x1")) then
                        gui.Visible = false
                    end
                end
            end
            -- Anti popups
            if S.AntiPopups then
                for _, gui in pairs(PlayerGui:GetChildren()) do
                    local ln = gui.Name:lower()
                    if gui:IsA("ScreenGui") and (ln:find("popup") or ln:find("jumpscare") or ln:find("ad") or ln:find("promo")) then
                        gui.Enabled = false
                    end
                end
            end
            -- Anti Nolilaugh (звук/эффект Noli)
            if S.AntiNolilaught then
                for _, s in pairs(workspace:GetDescendants()) do
                    if s:IsA("Sound") and s.Name:lower():find("noli") and s.Name:lower():find("laugh") then
                        s.Volume = 0 pcall(function() s:Stop() end)
                    end
                end
            end
            -- Anti Noli Clone
            if S.AntiNoliClone then
                for _, gui in pairs(PlayerGui:GetDescendants()) do
                    local ln = gui.Name:lower()
                    if ln:find("noli") and (ln:find("clone") or ln:find("mimic")) then
                        if gui:IsA("GuiObject") then gui.Visible = false
                        elseif gui:IsA("ScreenGui") then gui.Enabled = false end
                    end
                end
            end
        end)
        task.wait(0.2)
    end
end)

-- ================= EMOTES (FE) =================
local currentEmoteTrack = nil
local function playEmote(animId)
    local hum = getHum()
    if not hum then return end
    stopEmote()
    pcall(function()
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. tostring(animId)
        local animator = hum:FindFirstChildOfClass("Animator") or hum
        currentEmoteTrack = animator:LoadAnimation(anim)
        currentEmoteTrack:Play()
    end)
end
function stopEmote()
    pcall(function()
        if currentEmoteTrack then currentEmoteTrack:Stop() currentEmoteTrack = nil end
        local hum = getHum()
        if hum then
            local animator = hum:FindFirstChildOfClass("Animator")
            if animator then
                for _, tr in pairs(animator:GetPlayingAnimationTracks()) do
                    pcall(function() tr:Stop() end)
                end
            end
        end
    end)
end

-- ================= SOUNDS =================
local function playAllSounds()
    pcall(function()
        for _, s in pairs(workspace:GetDescendants()) do
            if s:IsA("Sound") then pcall(function() s:Play() end) end
        end
    end)
end
local function stopAllSounds()
    pcall(function()
        for _, s in pairs(workspace:GetDescendants()) do
            if s:IsA("Sound") then pcall(function() s:Stop() end) end
        end
        for _, s in pairs(game:GetService("SoundService"):GetDescendants()) do
            if s:IsA("Sound") then pcall(function() s:Stop() end) end
        end
    end)
end

-- ================= KILLER AUTOFARM (TELEPORT) =================
task.spawn(function()
    while true do
        if S.KillerAutoFarmTP then
            pcall(function()
                local hrp = getHRP()
                if hrp then
                    -- Телепорт к ближайшему выжившему
                    local wp = workspace:FindFirstChild("Players")
                    local survF = wp and wp:FindFirstChild("Survivors")
                    if survF then
                        local best, bd = nil, mathhuge
                        for _, surv in pairs(survF:GetChildren()) do
                            local sr = surv:FindFirstChild("HumanoidRootPart")
                            local sh = surv:FindFirstChildOfClass("Humanoid")
                            if sr and sh and sh.Health > 0 then
                                local d = (sr.Position - hrp.Position).Magnitude
                                if d < bd then bd = d best = sr end
                            end
                        end
                        if best then
                            hrp.CFrame = best.CFrame * CFramenew(0, 0, 3)
                            -- атака
                            pcall(function()
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                                task.wait(0.05)
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                            end)
                        end
                    end
                end
            end)
        end
        task.wait(0.4)
    end
end)

-- ================= SURVIVOR AUTOFARM (TWEENSERVICE) =================
local tweenFarmActive = false
task.spawn(function()
    while true do
        if S.SurvivorAutoFarmTween and not tweenFarmActive then
            tweenFarmActive = true
            pcall(function()
                local hrp = getHRP()
                if hrp then
                    scanGenerators()
                    for _, gen in pairs(genCache) do
                        if not S.SurvivorAutoFarmTween then break end
                        if not isGenFake(gen) and not isGenDone(gen) then
                            local part = getToolPart(gen)
                            if part then
                                local root = getHRP()
                                if root then
                                    local goal = CFramenew(part.Position + Vector3new(0, 3, 4))
                                    local dur = (root.Position - part.Position).Magnitude / (S.AutoFarmSpeed or 60)
                                    local tween = TweenService:Create(root, TweenInfo.new(dur, Enum.EasingStyle.Linear), {CFrame = goal})
                                    tween:Play()
                                    tween.Completed:Wait()
                                    local wait = S.RandomRepairSpeed and math.random(4,10) or (S.RepairSpeed or 3)
                                    local t0 = os.clock()
                                    while (os.clock() - t0) < wait and S.SurvivorAutoFarmTween do
                                        fireGenRemotes(gen)
                                        if isGenDone(gen) then break end
                                        task.wait(0.3)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            tweenFarmActive = false
        end
        task.wait(1)
    end
end)

-- ================= SURVIVOR AUTOFARM (PATHFINDER) =================
local pathFarmActive = false
local function walkToPath(destination)
    local hrp = getHRP()
    local hum = getHum()
    if not hrp or not hum then return end
    local path = PathfindingService:CreatePath({
        AgentRadius = 2, AgentHeight = 5, AgentCanJump = true,
    })
    local ok = pcall(function() path:ComputeAsync(hrp.Position, destination) end)
    if ok and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        for _, wp in pairs(waypoints) do
            if not S.SurvivorAutoFarmPath then break end
            if wp.Action == Enum.PathWaypointAction.Jump then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            hum:MoveTo(wp.Position)
            local reached = hum.MoveToFinished:Wait()
        end
    else
        -- fallback direct MoveTo
        hum:MoveTo(destination)
        hum.MoveToFinished:Wait()
    end
end

task.spawn(function()
    while true do
        if S.SurvivorAutoFarmPath and not pathFarmActive then
            pathFarmActive = true
            pcall(function()
                scanGenerators()
                for _, gen in pairs(genCache) do
                    if not S.SurvivorAutoFarmPath then break end
                    if not isGenFake(gen) and not isGenDone(gen) then
                        local part = getToolPart(gen)
                        if part then
                            walkToPath(part.Position)
                            local wait = S.RandomRepairSpeed and math.random(4,10) or (S.RepairSpeed or 3)
                            local t0 = os.clock()
                            while (os.clock() - t0) < wait and S.SurvivorAutoFarmPath do
                                fireGenRemotes(gen)
                                if isGenDone(gen) then break end
                                task.wait(0.3)
                            end
                        end
                    end
                end
            end)
            pathFarmActive = false
        end
        task.wait(1)
    end
end)

-- ================= ANTI STAFF =================
local STAFF_KEYWORDS = {"admin","staff","mod","moderator","developer","dev","owner","tester"}
local antiStaffWarned = {}
local function checkStaff(plr)
    local n = plr.Name:lower()
    local dn = (plr.DisplayName or ""):lower()
    for _, kw in pairs(STAFF_KEYWORDS) do
        if n:find(kw) or dn:find(kw) then return true end
    end
    -- проверка тегов/атрибутов
    if plr:GetAttribute("IsStaff") or plr:GetAttribute("Admin") then return true end
    return false
end

local antiStaffWarning = nil
task.spawn(function()
    while true do
        if S.AntiStaff then
            pcall(function()
                local detected = {}
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LP and checkStaff(plr) then
                        table_insert(detected, plr.Name)
                    end
                end
                if #detected > 0 then
                    if not antiStaffWarning then
                        antiStaffWarning = Instance.new("ScreenGui")
                        antiStaffWarning.Name = "_AntiStaffWarn"
                        antiStaffWarning.ResetOnSpawn = false
                        antiStaffWarning.Parent = PlayerGui
                        local lbl = Instance.new("TextLabel")
                        lbl.Size = UDim2.new(1, 0, 0, 40)
                        lbl.Position = UDim2.new(0, 0, 0, 0)
                        lbl.BackgroundColor3 = Color3RGB(200, 0, 0)
                        lbl.BackgroundTransparency = 0.2
                        lbl.Font = Enum.Font.GothamBold
                        lbl.TextColor3 = Color3RGB(255,255,255)
                        lbl.TextScaled = true
                        lbl.Name = "Label"
                        lbl.Parent = antiStaffWarning
                    end
                    antiStaffWarning.Label.Text = "⚠ STAFF В ИГРЕ: " .. table.concat(detected, ", ")
                    antiStaffWarning.Enabled = true
                else
                    if antiStaffWarning then antiStaffWarning.Enabled = false end
                end
            end)
        else
            if antiStaffWarning then antiStaffWarning.Enabled = false end
        end
        task.wait(2)
    end
end)

-- ================= MAIN ESP LOOP (Players / Gens / Items) =================
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local mh = getHRP()
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

            -- Generators ESP (обычные / фейк / готовые)
            for _, gen in pairs(genCache) do
                if not gen or not gen.Parent then continue end
                local fake = isGenFake(gen)
                local done = isGenDone(gen)
                local part = getToolPart(gen)
                local dist = (mh and part) and mathfloor((mh.Position - part.Position).Magnitude) or 0

                if done and S.DoneGenESP then
                    rm(gen, "_GH") rm(gen, "_FGH")
                    aHL(gen, "_DGH", Color3RGB(0,255,120), Color3RGB(0,200,80))
                    aBB(gen, "_GB", "[Done Gen] ["..dist.."m]", Color3RGB(0,255,120), part)
                elseif fake and S.FakeGenESP then
                    rm(gen, "_GH") rm(gen, "_DGH")
                    aHL(gen, "_FGH", Color3RGB(180,60,60), Color3RGB(150,40,40))
                    aBB(gen, "_GB", "[Fake Gen] ["..dist.."m]", Color3RGB(255,80,80), part)
                elseif not fake and not done and S.GenESP then
                    rm(gen, "_FGH") rm(gen, "_DGH")
                    aHL(gen, "_GH", Color3RGB(255,200,0), Color3RGB(255,160,0))
                    aBB(gen, "_GB", "[Gen] ["..dist.."m]", Color3RGB(255,210,0), part)
                else
                    rm(gen, "_GH") rm(gen, "_FGH") rm(gen, "_DGH") rm(gen, "_GB")
                end
            end

            updateItemESP()
        end)
    end
end)

-- ================= INVISIBILITY LOOP =================
local invisActive = false
task.spawn(function()
    while true do
        if S.Invisibility and not invisActive then
            invisActive = true
            pcall(function()
                local c = LP.Character
                local hum = getHum()
                local hrp = getHRP()
                if c and hrp then
                    local cf = hrp.CFrame
                    -- метод сервер-невидимость: реанкер
                    local anchor = Instance.new("Part")
                    anchor.Name = "_InvAnchor"
                    anchor.Anchored = true
                    anchor.CanCollide = false
                    anchor.Transparency = 1
                    anchor.Size = Vector3new(2,2,1)
                    anchor.CFrame = cf
                    anchor.Parent = workspace
                    local ok = pcall(function()
                        LP.Character = nil
                        hrp:Destroy()
                    end)
                end
            end)
        elseif not S.Invisibility then
            invisActive = false
            pcall(function()
                local a = workspace:FindFirstChild("_InvAnchor")
                if a then a:Destroy() end
            end)
        end
        task.wait(0.5)
    end
end)

-- ================= CLEANUP HITBOX =================
local function clearHitboxes()
    for char, origSize in pairs(hitboxOriginals) do
        pcall(function()
            local head = char:FindFirstChild("Head")
            if head and head:IsA("BasePart") then
                head.Size = origSize head.Transparency = 0 head.CanCollide = true
            end
        end)
    end
    hitboxOriginals = {}
end

-- ================= RETURN =================
return {
    updateHitboxes = updateHitboxes,
    teleportBehind = teleportBehind,
    tpBloxyCola = tpBloxyCola,
    tpMedkit = tpMedkit,
    tpNearestItem = tpNearestItem,
    bringAllItems = bringAllItems,
    deleteAllItems = deleteAllItems,
    playEmote = playEmote,
    stopEmote = stopEmote,
    playAllSounds = playAllSounds,
    stopAllSounds = stopAllSounds,
    getPlayerListForDropdown = function()
        local list = {}
        for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table_insert(list, p.Name) end end
        return list
    end,
    clearHitboxes = clearHitboxes,
    clearAllItemESP = clearAllItemESP,
}
end
