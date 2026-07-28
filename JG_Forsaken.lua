return function(S, getTargets, isValid, Players, LP, mathhuge, mathfloor, Vector3new, CFramenew, Color3RGB, task, pcall, workspace, table_insert)

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
    
local function tpBloxyCola()
    local c = LP.Character
    if not c then return end
    local h = c:FindFirstChild("HumanoidRootPart")
    if not h then return end
    local sv = h.CFrame
    task.spawn(function()
        for _, o in pairs(workspace:GetDescendants()) do
            pcall(function()
                if o:IsA("Tool") and o.Parent ~= c and o.Parent ~= LP.Backpack then
                    local nl = o.Name:lower()
                    if nl:find("bloxy") or nl:find("cola") or nl:find("bloxiade") then
                        local ha = o:FindFirstChild("Handle")
                        if ha then
                            h.CFrame = ha.CFrame
                            task.wait(0.3)
                            o.Parent = LP.Backpack
                            task.wait(0.1)
                        end
                    end
                end
            end)
        end
        task.wait(0.2)
        h.CFrame = sv
    end)
end

local function tpMedkit()
    local c = LP.Character
    if not c then return end
    local h = c:FindFirstChild("HumanoidRootPart")
    if not h then return end
    local sv = h.CFrame
    local kw = {"medkit", "med_kit", "firstaid", "first_aid", "bandage", "healthkit", "health_kit"}
    task.spawn(function()
        for _, o in pairs(workspace:GetDescendants()) do
            pcall(function()
                if o:IsA("Tool") and o.Parent ~= c and o.Parent ~= LP.Backpack then
                    local nl = o.Name:lower()
                    for _, k in pairs(kw) do
                        if nl:find(k) then
                            local ha = o:FindFirstChild("Handle")
                            if ha then
                                h.CFrame = ha.CFrame
                                task.wait(0.3)
                                o.Parent = LP.Backpack
                                task.wait(0.1)
                            end
                            break
                        end
                    end
                end
            end)
        end
        task.wait(0.2)
        h.CFrame = sv
    end)
end

local function tpNearestItem()
    local c = LP.Character
    if not c then return end
    local h = c:FindFirstChild("HumanoidRootPart")
    if not h then return end
    local sv = h.CFrame
    local best, bd = nil, mathhuge
    for _, o in pairs(workspace:GetDescendants()) do
        pcall(function()
            if o:IsA("Tool") and o.Parent ~= c and o.Parent ~= LP.Backpack then
                local ha = o:FindFirstChild("Handle")
                if ha then
                    local d = (ha.Position - h.Position).Magnitude
                    if d < bd then bd = d best = o end
                end
            end
        end)
    end
    if best then
        local ha = best:FindFirstChild("Handle")
        if ha then
            h.CFrame = ha.CFrame
            task.wait(0.35)
            pcall(function() best.Parent = LP.Backpack end)
            task.wait(0.2)
            h.CFrame = sv
        end
    end
end

local genCache = {}
task.spawn(function()
    while true do
        pcall(function()
            local newCache = {}
            local models = {}
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") and v.Name:lower():find("generator") then
                    table_insert(newCache, v)
                    models[v] = true
                end
            end
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") and v.Name:lower():find("generator") then
                    local pm = v:FindFirstAncestorWhichIsA("Model")
                    if not pm or not models[pm] then table_insert(newCache, v) end
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

            -- === Обработка Killers ===
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

            -- === Обработка Survivors ===
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

            -- === Обработка генераторов ===
            for _, o in pairs(genCache) do
                if o and o.Parent then
                    if S.GenESP then
                        local pos = o:IsA("Model") and (o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart")) and (o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart")).Position or (o:IsA("BasePart") and o.Position)
                        if pos then
                            local dist = mh and mathfloor((mh.Position - pos).Magnitude) or 0
                            aHL(o, "_GH", Color3RGB(255,200,0), Color3RGB(255,160,0))
                            local ad = o:IsA("Model") and (o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart")) or o
                            aBB(o, "_GB", "[Gen] "..dist.."m", Color3RGB(255,240,60), ad)
                        end
                    else
                        rm(o, "_GH", "_GB")
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
