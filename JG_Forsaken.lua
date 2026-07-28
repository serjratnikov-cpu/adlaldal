return function(S, getTargets, isValid, Players, LP, mathhuge, mathfloor, Vector3new, CFramenew, Color3RGB, task, pcall, workspace, table_insert)

local VirtualInputManager = game:GetService("VirtualInputManager")

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
            if d.Name == "_GH" or d.Name == "_GB" then
                d:Destroy()
            end
        end
        local a = obj:FindFirstChild("_GH") if a then a:Destroy() end
        local b = obj:FindFirstChild("_GB") if b then b:Destroy() end
    end)
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
            if not hitboxOriginals[char] then
                hitboxOriginals[char] = head.Size
            end
            local sz = S.HitboxSize
            head.Size = Vector3new(sz, sz, sz)
            head.Transparency = 0.7
            head.CanCollide = false
            head.Material = Enum.Material.Neon
            head.Color = Color3RGB(255, 0, 0)
        end
    end
    local alive = {}
    for i = 1, #targets do alive[targets[i]] = true end
    for char, origSize in pairs(hitboxOriginals) do
        if not alive[char] then
            pcall(function()
                local head = char:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    head.Size = origSize
                    head.Transparency = 0
                    head.CanCollide = true
                end
            end)
            hitboxOriginals[char] = nil
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
        if p.Name == targetName and p ~= LP then
            targetPlayer = p
            break
        end
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

local function findItemPart(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChild("Handle") or obj:FindFirstChild("Main") or obj:FindFirstChildWhichIsA("BasePart", true)
    end
    if obj:IsA("Tool") then
        return obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function isItemAvailable(obj)
    if not obj or not obj.Parent then return false end
    if obj:IsDescendantOf(Players) then return false end
    local ancestor = obj.Parent
    while ancestor and ancestor ~= workspace do
        if ancestor:IsA("Player") or ancestor:FindFirstChildOfClass("Humanoid") then return false end
        if ancestor.Name == "Backpack" then return false end
        ancestor = ancestor.Parent
    end
    return true
end

local function pressF()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        task.wait(0.08)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    end)
end

local function fireAllProximity(obj)
    pcall(function()
        for _, d in pairs(obj:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                pcall(function()
                    if fireproximityprompt then
                        fireproximityprompt(d)
                    end
                end)
            end
        end
        if obj:IsA("ProximityPrompt") then
            pcall(function()
                if fireproximityprompt then fireproximityprompt(obj) end
            end)
        end
        local parent = obj.Parent
        if parent then
            for _, d in pairs(parent:GetDescendants()) do
                if d:IsA("ProximityPrompt") then
                    pcall(function()
                        if fireproximityprompt then fireproximityprompt(d) end
                    end)
                end
            end
        end
    end)
end

local function fireAllClicks(obj)
    pcall(function()
        for _, d in pairs(obj:GetDescendants()) do
            if d:IsA("ClickDetector") then
                pcall(function()
                    if fireclickdetector then fireclickdetector(d) end
                end)
            end
        end
        if obj:IsA("ClickDetector") then
            pcall(function()
                if fireclickdetector then fireclickdetector(obj) end
            end)
        end
    end)
end

local function collectItem(obj, savedCFrame)
    local c = LP.Character
    if not c then return false end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local part = findItemPart(obj)
    if not part then return false end
    
    for attempt = 1, 4 do
        if not obj or not obj.Parent then break end
        if not isItemAvailable(obj) then break end
        part = findItemPart(obj)
        if not part then break end
        
        hrp.CFrame = CFramenew(part.Position + Vector3new(0, 2, 0))
        task.wait(0.2)
        
        fireAllProximity(obj)
        task.wait(0.15)
        pressF()
        task.wait(0.15)
        pressF()
        task.wait(0.15)
        
        fireAllClicks(obj)
        task.wait(0.1)
        
        if obj:IsA("Tool") then
            pcall(function() obj.Parent = c end)
            task.wait(0.15)
            if obj.Parent == c then return true end
            pcall(function() obj.Parent = LP.Backpack end)
            task.wait(0.15)
            if obj.Parent == LP.Backpack then return true end
        end
        
        if part and obj.Parent then
            hrp.CFrame = CFramenew(part.Position)
            task.wait(0.15)
            pressF()
            task.wait(0.2)
        end
        
        for _, tool in pairs(LP.Backpack:GetChildren()) do
            if tool == obj then return true end
        end
        for _, tool in pairs(c:GetChildren()) do
            if tool == obj then return true end
        end
        
        if not obj.Parent then return true end
    end
    
    return obj and (obj.Parent == c or obj.Parent == LP.Backpack) or (obj and not obj.Parent)
end

local function findItemsByKeywords(keywords)
    local found = {}
    for _, o in pairs(workspace:GetDescendants()) do
        pcall(function()
            if isItemAvailable(o) then
                local nl = o.Name:lower()
                for _, kw in pairs(keywords) do
                    if nl:find(kw) then
                        table_insert(found, o)
                        break
                    end
                end
            end
        end)
    end
    return found
end

local function tpBloxyCola()
    local c = LP.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local sv = hrp.CFrame
    task.spawn(function()
        local keywords = {"bloxy", "cola", "bloxiade", "soda"}
        local items = findItemsByKeywords(keywords)
        if #items == 0 then
            return
        end
        table.sort(items, function(a, b)
            local pa = findItemPart(a)
            local pb = findItemPart(b)
            if not pa or not pb then return false end
            return (pa.Position - hrp.Position).Magnitude < (pb.Position - hrp.Position).Magnitude
        end)
        for _, item in pairs(items) do
            if item and item.Parent and isItemAvailable(item) then
                collectItem(item, sv)
                break
            end
        end
        task.wait(0.15)
        if c and c.Parent then
            local h2 = c:FindFirstChild("HumanoidRootPart")
            if h2 then h2.CFrame = sv end
        end
    end)
end

local function tpMedkit()
    local c = LP.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local sv = hrp.CFrame
    task.spawn(function()
        local keywords = {"medkit", "med_kit", "med kit", "firstaid", "first_aid", "first aid", "bandage", "healthkit", "health_kit", "medical"}
        local items = findItemsByKeywords(keywords)
        if #items == 0 then
            return
        end
        table.sort(items, function(a, b)
            local pa = findItemPart(a)
            local pb = findItemPart(b)
            if not pa or not pb then return false end
            return (pa.Position - hrp.Position).Magnitude < (pb.Position - hrp.Position).Magnitude
        end)
        for _, item in pairs(items) do
            if item and item.Parent and isItemAvailable(item) then
                collectItem(item, sv)
                break
            end
        end
        task.wait(0.15)
        if c and c.Parent then
            local h2 = c:FindFirstChild("HumanoidRootPart")
            if h2 then h2.CFrame = sv end
        end
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
        local itemKeywords = {"bloxy", "cola", "bloxiade", "soda", "medkit", "med_kit", "med kit", "firstaid", "first_aid", "first aid", "bandage", "healthkit", "health_kit", "medical", "battery", "key", "pickup"}
        for _, o in pairs(workspace:GetDescendants()) do
            pcall(function()
                if isItemAvailable(o) then
                    local isItem = false
                    if o:IsA("Tool") then isItem = true end
                    local nl = o.Name:lower()
                    for _, kw in pairs(itemKeywords) do
                        if nl:find(kw) then isItem = true break end
                    end
                    if isItem then
                        local part = findItemPart(o)
                        if part then
                            local d = (part.Position - hrp.Position).Magnitude
                            if d < bd then bd = d best = o end
                        end
                    end
                end
            end)
        end
        if best then
            collectItem(best, sv)
        end
        task.wait(0.15)
        if c and c.Parent then
            local h2 = c:FindFirstChild("HumanoidRootPart")
            if h2 then h2.CFrame = sv end
        end
    end)
end

local genCache = {}
local allGenObjects = {}

task.spawn(function()
    while true do
        pcall(function()
            local newCache = {}
            local allObjects = {}
            local seenPositions = {}
            
            for _, v in pairs(workspace:GetDescendants()) do
                if v.Name:lower():find("generator") then
                    allObjects[v] = true
                    if v:IsA("Model") then
                        local part = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
                        if part then
                            local posKey = mathfloor(part.Position.X) .. "_" .. mathfloor(part.Position.Y) .. "_" .. mathfloor(part.Position.Z)
                            if not seenPositions[posKey] then
                                seenPositions[posKey] = true
                                table_insert(newCache, v)
                            end
                        end
                    end
                end
            end
            
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") and v.Name:lower():find("generator") then
                    local pm = v:FindFirstAncestorWhichIsA("Model")
                    local isInsideGenModel = false
                    if pm and pm.Name:lower():find("generator") then
                        isInsideGenModel = true
                    end
                    if not isInsideGenModel then
                        local posKey = mathfloor(v.Position.X) .. "_" .. mathfloor(v.Position.Y) .. "_" .. mathfloor(v.Position.Z)
                        if not seenPositions[posKey] then
                            seenPositions[posKey] = true
                            table_insert(newCache, v)
                        end
                    end
                end
            end
            
            for obj, _ in pairs(allGenObjects) do
                if obj and obj.Parent then
                    local isMain = false
                    for _, m in pairs(newCache) do
                        if m == obj then isMain = true break end
                    end
                    if not isMain then
                        rmAllGenESP(obj)
                    end
                end
            end
            
            allGenObjects = allObjects
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
                    pcall(function()
                        if not child:FindFirstChild("HumanoidRootPart") then return end
                        local dist = mh and mathfloor((mh.Position - child.HumanoidRootPart.Position).Magnitude) or 0
                        local hd = child:FindFirstChild("Head") or child.HumanoidRootPart
                        if S.KillerESP then
                            aHL(child, "_KH", Color3RGB(255, 0, 0), Color3RGB(255, 0, 0))
                            aBB(child, "_KB", "[Killer] " .. child.Name .. " [" .. dist .. "m]", Color3RGB(255, 40, 40), hd)
                        else
                            rm(child, "_KH", "_KB")
                        end
                    end)
                end
            end

            if survF then
                for _, child in pairs(survF:GetChildren()) do
                    pcall(function()
                        if not child:FindFirstChild("HumanoidRootPart") then return end
                        local dist = mh and mathfloor((mh.Position - child.HumanoidRootPart.Position).Magnitude) or 0
                        local hd = child:FindFirstChild("Head") or child.HumanoidRootPart
                        if S.SurvESP then
                            aHL(child, "_SH", Color3RGB(0,200,60), Color3RGB(90,255,130))
                            aBB(child, "_SB", "[Surv] "..child.Name.." ["..dist.."m]", Color3RGB(90,255,120), hd)
                        else
                            rm(child, "_SH", "_SB")
                        end
                    end)
                end
            end

            if not S.GenESP then
                for obj, _ in pairs(allGenObjects) do
                    if obj and obj.Parent then
                        rmAllGenESP(obj)
                    end
                end
            else
                for obj, _ in pairs(allGenObjects) do
                    if obj and obj.Parent then
                        local isMain = false
                        for _, m in pairs(genCache) do
                            if m == obj then isMain = true break end
                        end
                        if not isMain then
                            rmAllGenESP(obj)
                        else
                            local gb = obj:FindFirstChild("_GB") if gb then gb:Destroy() end
                        end
                    end
                end
                
                for _, o in pairs(genCache) do
                    if o and o.Parent then
                        aHL(o, "_GH", Color3RGB(255,200,0), Color3RGB(255,160,0))
                        local gb = o:FindFirstChild("_GB") if gb then gb:Destroy() end
                    end
                end
            end
        end)
    end
end)

local function getPlayerListForDropdown()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local ch = p.Character
            if ch and ch:FindFirstChildOfClass("Humanoid") and ch:FindFirstChildOfClass("Humanoid").Health > 0 then
                table_insert(list, p.Name)
            end
        end
    end
    return list
end

local function clearHitboxes()
    for char, origSize in pairs(hitboxOriginals) do
        pcall(function()
            local head = char:FindFirstChild("Head")
            if head and head:IsA("BasePart") then head.Size = origSize head.Transparency = 0 end
        end)
    end
    hitboxOriginals = {}
end

return {
    updateHitboxes = updateHitboxes,
    teleportBehind = teleportBehind,
    tpBloxyCola = tpBloxyCola,
    tpMedkit = tpMedkit,
    tpNearestItem = tpNearestItem,
    getPlayerListForDropdown = getPlayerListForDropdown,
    clearHitboxes = clearHitboxes,
}

end
