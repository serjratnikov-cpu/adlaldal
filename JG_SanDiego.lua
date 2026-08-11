return function(S, LP, Players, ws, RS, Camera, Color3RGB, V3new, CFnew, mathhuge, pcall, task, table_insert, string_find, string_lower, tostring, mathfloor)

local SD = {}

-- Состояния
SD.AutoFarmActive = false
SD.AutoFarmStatus = "Idle"
SD.AutoFarmLaps = 0
SD.PoliceESP = false
SD.AimCivilian = false
SD.AimPolice = false

local policeHighlights = {}
local statusLabel = nil
local currentFlyCleanup = nil

-- Константы для поиска
local TEAM_NAMES_POLICE = {"police","border patrol","fbi","swat","bortac","army","sheriff","trooper","marshal","officer","cop","patrol"}
local TRUCK_NAMES = {"Semi", "Truck", "Heavy", "Cargo", "Mack", "Freightliner"}
local DEPOT_NAMES = {"Truck Depot", "Truck Spawn", "Job Center", "Delivery Start"}
local DELIVERY_POINTS = {"Delivery Point", "Warehouse", "Drop Off", "Cargo Sell", "Export"}

-- Утилиты (оставлены без изменений для совместимости)
local function isPolice(player)
    if not player then return false end
    local team = player.Team
    if team then
        local tLow = team.Name:lower()
        for _, n in ipairs(TEAM_NAMES_POLICE) do if string_find(tLow, n) then return true end end
    end
    return false
end

local function setStatus(text)
    SD.AutoFarmStatus = text
    if statusLabel then pcall(function() statusLabel.Text = "Статус: " .. text end) end
end

local function stopCurrentFly()
    if currentFlyCleanup then pcall(function() currentFlyCleanup() end) currentFlyCleanup = nil end
end

-- Улучшенная функция полета (теперь может перемещать и машину)
local function flyTo(targetPos, speed)
    stopCurrentFly()
    local ch = LP.Character
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    speed = speed or 300
    local alive = true
    
    local noclipConn = RS.Stepped:Connect(function()
        if not alive then return end
        pcall(function()
            local targetObj = (hum.SeatPart and hum.SeatPart.Parent) or ch
            for _, p in pairs(targetObj:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    end)

    currentFlyCleanup = function() alive = false noclipConn:Disconnect() end

    while alive and SD.AutoFarmActive do
        local currentObj = (hum.SeatPart and hum.SeatPart.Parent) or hrp
        local root = currentObj:IsA("Model") and (currentObj.PrimaryPart or currentObj:FindFirstChildWhichIsA("BasePart")) or currentObj
        
        if not root then break end
        local myPos = root.Position
        local dist = (myPos - targetPos).Magnitude
        if dist < 10 then break end

        local dir = (targetPos - myPos).Unit
        local dt = task.wait()
        local step = math.min(dist, speed * dt)
        
        local newCF = CFnew(myPos + dir * step, targetPos)
        if currentObj:IsA("Model") then
            currentObj:SetPrimaryPartCFrame(newCF)
        else
            currentObj.CFrame = newCF
        end
        
        pcall(function() root.AssemblyLinearVelocity = V3new(0,0,0) root.AssemblyAngularVelocity = V3new(0,0,0) end)
    end
    stopCurrentFly()
end

-- Функции для работы с грузовиками
local function getVehicle()
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart then return hum.SeatPart.Parent end
    return nil
end

local function spawnTruck()
    setStatus("Ищу спавнер грузовиков...")
    local spawner = nil
    for _, name in ipairs(DEPOT_NAMES) do
        spawner = SD.findInWorkspace(name)
        if spawner then break end
    end

    if spawner then
        flyTo(spawner.Position + V3new(0, 5, 0), 300)
        task.wait(0.5)
        -- Пытаемся нажать на кнопку спавна (обычно ProximityPrompt или GUI)
        local prompt = SD.findProximityPrompt(spawner, "Spawn") or SD.findProximityPrompt(spawner, "Truck")
        if prompt then
            SD.fireProximityPrompt(prompt)
            task.wait(1.5)
        end
    end
end

local function findDeliveryPoint()
    for _, name in ipairs(DELIVERY_POINTS) do
        local point = SD.findInWorkspace(name)
        if point then return point end
    end
    -- Если не нашли по имени, ищем ближайший яркий объект или папку Destinations
    local destFolder = ws:FindFirstChild("Destinations") or ws:FindFirstChild("DeliveryPoints")
    if destFolder then
        return destFolder:GetChildren()[1]
    end
    return nil
end

-- ГЛАВНЫЙ ЦИКЛ ФАРМА ГРУЗОВИКОВ
local function doTruckFarmCycle()
    if not SD.AutoFarmActive then return end

    -- 1. Проверяем, есть ли грузовик
    local truck = getVehicle()
    if not truck then
        setStatus("Лечу за грузовиком...")
        spawnTruck()
        
        -- Ждем, пока игрок окажется в сиденье (авто-сидение обычно работает в таких играх)
        local timeout = 0
        while not getVehicle() and timeout < 10 do
            setStatus("Сажусь в грузовик... " .. timeout)
            local nearestTruck = nil
            local minDist = 100
            for _, v in ipairs(ws:GetChildren()) do
                for _, tName in ipairs(TRUCK_NAMES) do
                    if string_find(v.Name, tName) and v:IsA("Model") then
                        local dist = (LP.Character.HumanoidRootPart.Position - v:GetModelCFrame().p).Magnitude
                        if dist < minDist then minDist = dist nearestTruck = v end
                    end
                end
            end
            
            if nearestTruck then
                local seat = nearestTruck:FindFirstChildOfClass("VehicleSeat")
                if seat then
                    LP.Character.HumanoidRootPart.CFrame = seat.CFrame
                end
            end
            task.wait(1)
            timeout = timeout + 1
        end
    end

    truck = getVehicle()
    if not truck then 
        setStatus("Грузовик не найден, повторяю...")
        return 
    end

    -- 2. Берем груз (если нужно)
    setStatus("Загрузка товара...")
    task.wait(1) 

    -- 3. Летим к точке сдачи
    local target = findDeliveryPoint()
    if target then
        setStatus("Доставка груза: " .. target.Name)
        local targetPos = target:IsA("BasePart") and target.Position or target:GetModelCFrame().p
        flyTo(targetPos, 300)
        task.wait(1)
        
        -- 4. Сдача груза
        setStatus("Разгрузка...")
        local sellPrompt = SD.findProximityPrompt(target, "Deliver") or SD.findProximityPrompt(target, "Unload")
        if sellPrompt then
            SD.fireProximityPrompt(sellPrompt)
        else
            -- Пытаемся через Remote если промпта нет
            SD.tryFireRemote("FinishJob")
            SD.tryFireRemote("CompleteDelivery")
        end
        
        task.wait(1)
        SD.AutoFarmLaps = SD.AutoFarmLaps + 1
        setStatus("Рейс #" .. SD.AutoFarmLaps .. " завершен!")
    else
        setStatus("Точка сдачи не найдена!")
        task.wait(2)
    end
end

-- Вспомогательные функции (интеграция из вашего кода)
function SD.findInWorkspace(name)
    local nameLow = name:lower()
    for _, child in ipairs(ws:GetDescendants()) do
        if string_find(child.Name:lower(), nameLow) then return child end
    end
    return nil
end

function SD.findProximityPrompt(parent, text)
    if not parent then return nil end
    for _, desc in ipairs(parent:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            if not text or string_find((desc.ActionText or ""):lower(), text:lower()) then return desc end
        end
    end
    return nil
end

function SD.fireProximityPrompt(prompt)
    if not prompt then return end
    pcall(function()
        fireproximityprompt(prompt)
    end)
end

function SD.tryFireRemote(name)
    for _, child in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if child:IsA("RemoteEvent") and string_find(child.Name:lower(), name:lower()) then
            child:FireServer()
            return true
        end
    end
    return false
end

-- Управление
function SD.startAutoFarm()
    if SD.AutoFarmActive then return end
    SD.AutoFarmActive = true
    SD.AutoFarmLaps = 0
    task.spawn(function()
        while SD.AutoFarmActive do
            pcall(function() doTruckFarmCycle() end)
            task.wait(1)
        end
        stopCurrentFly()
        setStatus("Остановлено")
    end)
end

function SD.stopAutoFarm()
    SD.AutoFarmActive = false
    stopCurrentFly()
end

function SD.setStatusLabel(label) statusLabel = label end

-- ESP и очистка (оставлено как было)
function SD.updatePoliceESP()
    SD.clearPoliceESP()
    if not S.PoliceESP then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isPolice(p) then
            local ch = p.Character
            if ch and ch:FindFirstChild("Humanoid") then
                local hl = Instance.new("Highlight", ch)
                hl.FillColor = Color3RGB(30, 100, 255)
                policeHighlights[p] = hl
            end
        end
    end
end

function SD.clearPoliceESP()
    for p, hl in pairs(policeHighlights) do pcall(function() hl:Destroy() end) end
    policeHighlights = {}
end

function SD.cleanup()
    SD.stopAutoFarm()
    SD.clearPoliceESP()
end

return SD
end
