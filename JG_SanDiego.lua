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
    if statusLabel then pcall(function() statusLabel.Text = "Статус: " .. text end) end
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
    if not hrp then return end

    speed = speed or (S.AutoFarmSpeed or 60)

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = V3new(mathhuge, mathhuge, mathhuge)
    bv.Velocity = V3new(0, 0, 0)
    bv.Parent = hrp

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = V3new(mathhuge, mathhuge, mathhuge)
    bg.P = 9e4
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp

    local alive = true
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
        pcall(function() bv:Destroy() end)
        pcall(function() bg:Destroy() end)
    end

    while alive and SD.AutoFarmActive do
        if not ch or not ch.Parent or not hrp or not hrp.Parent then break end
        local dist = (hrp.Position - targetPos).Magnitude
        if dist < 10 then break end
        local dir = (targetPos - hrp.Position).Unit
        bv.Velocity = dir * speed
        bg.CFrame = CFnew(hrp.Position, targetPos)
        task.wait()
    end

    if alive then
        pcall(function() bv.Velocity = V3new(0, 0, 0) end)
        task.wait(0.3)
    end
    stopCurrentFly()
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

local function findInWorkspace(name)
    local nameLow = name:lower()
    for _, child in ipairs(ws:GetDescendants()) do
        if child.Name == name or string_find(child.Name:lower(), nameLow) then
            return child
        end
    end
    return nil
end

local function findAllInWorkspace(name)
    local nameLow = name:lower()
    local results = {}
    for _, child in ipairs(ws:GetDescendants()) do
        if child.Name == name or string_find(child.Name:lower(), nameLow) then
            table_insert(results, child)
        end
    end
    return results
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

local function findAllButtonsInGUI(buttonName)
    local pg = LP.PlayerGui
    if not pg then return {} end
    local bLow = buttonName:lower()
    local results = {}
    for _, gui in ipairs(pg:GetDescendants()) do
        if (gui:IsA("TextButton") or gui:IsA("ImageButton")) then
            local vis = true
            pcall(function() vis = gui.Visible end)
            if vis then
                local match = false
                if gui.Name and string_find(gui.Name:lower(), bLow) then match = true end
                if gui:IsA("TextButton") and gui.Text and string_find(gui.Text:lower(), bLow) then match = true end
                if match then table_insert(results, gui) end
            end
        end
    end
    return results
end

local function findTextLabelInGUI(text)
    local pg = LP.PlayerGui
    if not pg then return nil end
    local tLow = text:lower()
    for _, gui in ipairs(pg:GetDescendants()) do
        if gui:IsA("TextLabel") or gui:IsA("TextButton") then
            local vis = true
            pcall(function() vis = gui.Visible end)
            if vis and gui.Text and string_find(gui.Text:lower(), tLow) then
                return gui
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
    pcall(function()
        if fireclickdetector then
            local cd = btn:FindFirstChildOfClass("ClickDetector")
            if cd then fireclickdetector(cd) end
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

local function tryFireRemote(name, ...)
    local args = table.pack(...)
    local rs = game:GetService("ReplicatedStorage")
    for _, child in ipairs(rs:GetDescendants()) do
        if child:IsA("RemoteEvent") and (child.Name == name or string_find(child.Name:lower(), name:lower())) then
            pcall(function() child:FireServer(table.unpack(args, 1, args.n)) end)
            return true
        end
    end
    for _, child in ipairs(rs:GetDescendants()) do
        if child:IsA("RemoteFunction") and (child.Name == name or string_find(child.Name:lower(), name:lower())) then
            pcall(function() child:InvokeServer(table.unpack(args, 1, args.n)) end)
            return true
        end
    end
    return false
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

local function findNearestFromList(names)
    local ch = LP.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") then return nil, nil end
    local myPos = ch.HumanoidRootPart.Position
    local nearestObj = nil
    local nearestPos = nil
    local nearestDist = mathhuge
    for _, name in ipairs(names) do
        local all = findAllInWorkspace(name)
        for _, child in ipairs(all) do
            local pos = getPartPosition(child)
            if pos then
                local d = (myPos - pos).Magnitude
                if d < nearestDist then
                    nearestDist = d
                    nearestObj = child
                    nearestPos = pos
                end
            end
        end
    end
    return nearestObj, nearestPos
end

local function findNearestNPC(names)
    local ch = LP.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") then return nil, nil end
    local myPos = ch.HumanoidRootPart.Position
    local nearestObj = nil
    local nearestPos = nil
    local nearestDist = mathhuge
    for _, name in ipairs(names) do
        local nameLow = name:lower()
        for _, child in ipairs(ws:GetDescendants()) do
            if child:IsA("Model") and (child.Name == name or string_find(child.Name:lower(), nameLow)) then
                if child:FindFirstChildOfClass("Humanoid") then
                    local pos = getPartPosition(child)
                    if pos then
                        local d = (myPos - pos).Magnitude
                        if d < nearestDist then
                            nearestDist = d
                            nearestObj = child
                            nearestPos = pos
                        end
                    end
                end
            end
        end
    end
    return nearestObj, nearestPos
end

local function flyToObj(obj, extraY)
    extraY = extraY or 3
    local pos = getPartPosition(obj)
    if pos then
        flyTo(pos + V3new(0, extraY, 0), S.AutoFarmSpeed or 120)
        task.wait(0.3)
    end
end

local function flyToPos(pos, extraY)
    if not pos then return end
    extraY = extraY or 3
    flyTo(pos + V3new(0, extraY, 0), S.AutoFarmSpeed or 120)
    task.wait(0.3)
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
                flyTo(pos + V3new(0, 3, 3), S.AutoFarmSpeed or 120)
                task.wait(0.5)
            end
            fireProximityPrompt(pp)
            return true
        end
    end
    return false
end

local function waitForGUIButton(buttonName, timeout)
    timeout = timeout or 8
    local start = tick()
    while tick() - start < timeout and SD.AutoFarmActive do
        local btn = findButtonInGUI(buttonName)
        if btn then return btn end
        task.wait(0.3)
    end
    return nil
end

local function waitForGUIText(text, timeout)
    timeout = timeout or 8
    local start = tick()
    while tick() - start < timeout and SD.AutoFarmActive do
        local lbl = findTextLabelInGUI(text)
        if lbl then return lbl end
        task.wait(0.3)
    end
    return nil
end

-- === ПОКУПКА КОЛЕЦ В BLACK MARKET ===
local function buyRings()
    if not SD.AutoFarmActive then return false end
    setStatus("Лечу к Black Market...")

    local marketObj, marketPos = findNearestFromList({
        "BlackMarket","Black Market","GoodsMarket","Goods Market",
        "Black Market Goods","BlackMarketGoods","Market","Goods",
        "Shop","Jewelry","JewelryShop"
    })
    if marketPos then
        flyToPos(marketPos, 3)
    end

    local bought = false
    for attempt = 1, 8 do
        if not SD.AutoFarmActive then return false end
        setStatus("Покупка колец... (" .. attempt .. ")")

        local promptDone = false
        local buyTargets = {
            {"Fake Diamond Ring","Buy"},{"Ring","Buy"},{"Diamond","Buy"},
            {"Black Market Goods","Buy"},{"BlackMarket","Buy"},
            {"Black Market","Buy"},{"Goods","Buy"},{"Market","Buy"}
        }
        for _, pair in ipairs(buyTargets) do
            if promptDone then break end
            promptDone = interactPromptNear(pair[1], pair[2])
        end

        task.wait(0.5)

        local ringBtn = findButtonInGUI("Fake Diamond Ring")
            or findButtonInGUI("Diamond Ring")
            or findButtonInGUI("Ring")
        if ringBtn then
            clickButton(ringBtn)
            task.wait(0.3)
            bought = true
        end

        local buyBtn = findButtonInGUI("Buy")
            or findButtonInGUI("Purchase")
        if buyBtn then
            clickButton(buyBtn)
            task.wait(0.3)
            bought = true
        end

        if not bought then
            local remotes = {"BuyRing","PurchaseRing","BuyItem","Purchase","BuyGoods","Buy"}
            for _, rn in ipairs(remotes) do
                if tryFireRemote(rn, "Fake Diamond Ring") then bought = true break end
                if tryFireRemote(rn, "FakeDiamondRing") then bought = true break end
            end
        end

        if bought then break end
        task.wait(0.5)
    end

    return bought
end

-- === СПАВН МАШИНЫ Tayora Cambria ===
local function spawnVehicle()
    if not SD.AutoFarmActive then return false end
    setStatus("Лечу к Vehicle Spawner...")

    local spawnerObj, spawnerPos = findNearestFromList({
        "VehicleSpawner","Vehicle Spawner","SpawnVehicle","Spawn Vehicle",
        "VehicleSpawn","CarSpawner","Car Spawner","Tablet",
        "VehiclePad","SpawnPad","Garage","CivilianGarage"
    })

    if not spawnerPos then
        for _, desc in ipairs(ws:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                local at = desc.ActionText or ""
                local ot = desc.ObjectText or ""
                local atL = at:lower()
                local otL = ot:lower()
                if string_find(atL, "spawn") or string_find(atL, "vehicle")
                    or string_find(otL, "spawn") or string_find(otL, "vehicle") then
                    local par = desc.Parent
                    if par then
                        spawnerPos = getPartPosition(par)
                        spawnerObj = par
                        break
                    end
                end
            end
        end
    end

    if spawnerPos then
        flyToPos(spawnerPos, 3)
    end

    task.wait(0.5)

    local promptFired = false
    if spawnerObj then
        local pp = findProximityPrompt(spawnerObj, "spawn")
            or findProximityPrompt(spawnerObj, "vehicle")
            or findProximityPrompt(spawnerObj, nil)
        if pp then
            fireProximityPrompt(pp)
            promptFired = true
        end
        if not promptFired and spawnerObj.Parent then
            pp = findProximityPrompt(spawnerObj.Parent, "spawn")
                or findProximityPrompt(spawnerObj.Parent, "vehicle")
                or findProximityPrompt(spawnerObj.Parent, nil)
            if pp then
                fireProximityPrompt(pp)
                promptFired = true
            end
        end
    end

    if not promptFired then
        local spawnNames = {
            {"VehicleSpawner","Spawn"},{"Vehicle Spawner","Spawn"},
            {"SpawnVehicle",nil},{"Spawn Vehicle",nil},
            {"Tablet","Spawn"},{"Garage","Spawn"}
        }
        for _, pair in ipairs(spawnNames) do
            if promptFired then break end
            promptFired = interactPromptNear(pair[1], pair[2])
        end
    end

    task.wait(1)
    setStatus("Выбираю Tayora Cambria...")

    local carSelected = false
    for attempt = 1, 15 do
        if not SD.AutoFarmActive then return false end
        if carSelected then break end

        local carNames = {
            "Tayora Cambria","TayoraCambria","Tayora","Cambria",
            "tayora cambria","tayoracambria"
        }
        for _, cName in ipairs(carNames) do
            local btn = findButtonInGUI(cName)
            if btn then
                clickButton(btn)
                task.wait(0.3)
                clickButton(btn)
                carSelected = true
                setStatus("Выбрано: " .. cName)
                break
            end
        end

        if not carSelected then
            local lbl = findTextLabelInGUI("Tayora")
                or findTextLabelInGUI("Cambria")
            if lbl then
                local parent = lbl.Parent
                if parent then
                    if parent:IsA("TextButton") or parent:IsA("ImageButton") then
                        clickButton(parent)
                        carSelected = true
                    else
                        for _, child in ipairs(parent:GetChildren()) do
                            if child:IsA("TextButton") or child:IsA("ImageButton") then
                                clickButton(child)
                                carSelected = true
                                break
                            end
                        end
                        if not carSelected then
                            for _, child in ipairs(parent:GetDescendants()) do
                                if child:IsA("TextButton") or child:IsA("ImageButton") then
                                    clickButton(child)
                                    carSelected = true
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end

        if not carSelected then
            task.wait(0.5)
        end
    end

    task.wait(0.5)
    setStatus("Нажимаю Spawn...")

    local spawned = false
    for attempt = 1, 10 do
        if not SD.AutoFarmActive then return false end
        if spawned then break end

        local spawnBtnNames = {"Spawn","spawn","SpawnVehicle","Spawn Vehicle","Confirm","Select","OK"}
        for _, sName in ipairs(spawnBtnNames) do
            local btn = findButtonInGUI(sName)
            if btn then
                clickButton(btn)
                task.wait(0.2)
                clickButton(btn)
                spawned = true
                setStatus("Машина заспавнена!")
                break
            end
        end

        if not spawned then
            tryFireRemote("SpawnVehicle", "Tayora Cambria")
            tryFireRemote("SpawnVehicle", "TayoraCambria")
            tryFireRemote("Spawn", "Tayora Cambria")
            task.wait(0.5)
        end
    end

    task.wait(1)
    return spawned or carSelected
end

-- === ПРОДАЖА У БЛИЖАЙШЕГО ПРОДАВЦА ===
local function sellGoods()
    if not SD.AutoFarmActive then return false end
    setStatus("Лечу к продавцу...")

    local sellerObj, sellerPos = findNearestNPC({
        "Smuggled Goods Seller","Smuggler","GoodsSeller","Goods Seller",
        "Garage Smuggler","GarageSmuggler","Seller"
    })

    if not sellerPos then
        local _, altPos = findNearestFromList({
            "Smuggled Goods Seller","SmugGoodsSeller","GoodsSeller",
            "Garage Smuggler","GarageSmuggler","Seller","Sell",
            "Autoshop","AutoShop","ParkingGarage"
        })
        sellerPos = altPos
    end

    if sellerPos then
        flyToPos(sellerPos, 3)
    end

    task.wait(0.5)

    local sold = false
    local sellTargets = {
        {"Smuggled Goods Seller","Sell"},{"Garage Smuggler","Sell"},
        {"GoodsSeller","Sell"},{"Seller","Sell"},{"Smuggler","Sell"},
        {"Sell",nil},{"Goods","Sell"}
    }
    for _, pair in ipairs(sellTargets) do
        if sold then break end
        sold = interactPromptNear(pair[1], pair[2])
    end

    if not sold then
        for _, desc in ipairs(ws:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                local at = (desc.ActionText or ""):lower()
                local ot = (desc.ObjectText or ""):lower()
                if string_find(at, "sell") or string_find(ot, "sell")
                    or string_find(ot, "smuggl") or string_find(ot, "goods") then
                    local par = desc.Parent
                    if par then
                        local pos = getPartPosition(par)
                        if pos then
                            flyToPos(pos, 3)
                            task.wait(0.3)
                        end
                    end
                    fireProximityPrompt(desc)
                    sold = true
                    break
                end
            end
        end
    end

    if not sold then
        local remotes = {"SellGoods","Sell","SellItem","SellAll","SellSmuggled"}
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

-- === ОТМЫВКА В LAUNDROMAT ===
local function launderMoney()
    if not SD.AutoFarmActive then return false end
    setStatus("Лечу к Laundromat...")

    local launderObj, launderPos = findNearestFromList({
        "Laundromat","LAUNDROMAT","Launder","MoneyWash","Money Wash",
        "Wash","Laundering","LaunderCash","WashingMachine"
    })

    if launderPos then
        flyToPos(launderPos, 3)
    end

    task.wait(0.5)

    local done = false
    local targets = {
        {"Laundromat","Launder"},{"LAUNDROMAT","Launder"},
        {"Launder","Launder Cash"},{"Launder",nil},
        {"Money Wash",nil},{"Wash","Launder"},
        {"WashingMachine","Launder"},{"Washing Machine","Launder"}
    }
    for _, pair in ipairs(targets) do
        if done then break end
        done = interactPromptNear(pair[1], pair[2])
    end

    if not done then
        for _, desc in ipairs(ws:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                local at = (desc.ActionText or ""):lower()
                local ot = (desc.ObjectText or ""):lower()
                if string_find(at, "launder") or string_find(at, "wash")
                    or string_find(ot, "launder") or string_find(ot, "laundromat") then
                    local par = desc.Parent
                    if par then
                        local pos = getPartPosition(par)
                        if pos then
                            flyToPos(pos, 3)
                            task.wait(0.3)
                        end
                    end
                    fireProximityPrompt(desc)
                    done = true
                    break
                end
            end
        end
    end

    if not done then
        local remotes = {"Launder","LaunderMoney","LaunderCash","WashMoney","MoneyWash"}
        for _, rn in ipairs(remotes) do
            if tryFireRemote(rn) then done = true break end
        end
    end

    return done
end

-- === ОСНОВНОЙ ЦИКЛ ФАРМА ===
local function doRingFarmCycle()
    if not SD.AutoFarmActive then return end

    -- 1. Купить кольца
    setStatus("Этап 1: Покупка колец...")
    buyRings()
    task.wait(0.5)

    if not SD.AutoFarmActive then return end

    -- 2. Заспавнить машину
    setStatus("Этап 2: Спавн машины...")
    spawnVehicle()
    task.wait(1)

    if not SD.AutoFarmActive then return end

    -- 3. Лететь к ближайшему продавцу и продать
    setStatus("Этап 3: Продажа...")
    sellGoods()
    task.wait(0.8)

    if not SD.AutoFarmActive then return end

    -- 4. Лететь к Laundromat и отмыть
    setStatus("Этап 4: Отмывка...")
    launderMoney()
    task.wait(0.8)

    SD.AutoFarmLaps = SD.AutoFarmLaps + 1
    setStatus("Круг #" .. SD.AutoFarmLaps .. " завершён!")
end

function SD.startAutoFarm()
    if SD.AutoFarmActive then return end
    SD.AutoFarmActive = true
    SD.AutoFarmLaps = 0
    setStatus("Запуск...")
    task.spawn(function()
        while SD.AutoFarmActive do
            pcall(function() doRingFarmCycle() end)
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
