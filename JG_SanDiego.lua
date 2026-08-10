local function flyTo(targetPos, speed)
    stopCurrentFly()
    local ch = LP.Character
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    speed = speed or (S.AutoFarmSpeed or 120)

    local alive = true
    local stepCount = 0
    local flyTime = 0
    local isGrounded = false
    local wasFlying = false
    
    local noclipConn = RS.Stepped:Connect(function()
        if not alive then return end
        pcall(function()
            if ch and hrp then
                for _, part in ipairs(ch:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
                hrp.Velocity = V3new(0, 0, 0)
                hrp.RotVelocity = V3new(0, 0, 0)
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
    end)

    currentFlyCleanup = function()
        alive = false
        pcall(function() noclipConn:Disconnect() end)
        pcall(function()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Landed)
            end
        end)
    end

    while alive and SD.AutoFarmActive do
        if not ch or not ch.Parent or not hrp or not hrp.Parent then break end
        local currentPos = hrp.Position
        local dist = (currentPos - targetPos).Magnitude
        if dist < 4 then break end
        
        local dir = (targetPos - currentPos).Unit
        local nextPos = currentPos + (dir * (speed * 0.04))
        
        stepCount = stepCount + 1
        flyTime = flyTime + 0.04
        
        local ray = RaycastParams.new()
        ray.FilterType = Enum.RaycastFilterType.Blacklist
        ray.FilterDescendantsInstances = {ch}
        local hit = ws:Raycast(nextPos + V3new(0, 3, 0), V3new(0, -6, 0), ray)
        
        if hit then
            isGrounded = true
            nextPos = V3new(nextPos.X, hit.Position.Y + 2.5, nextPos.Z)
        else
            isGrounded = false
        end
        
        if flyTime >= 3.8 and not isGrounded then
            hum:ChangeState(Enum.HumanoidStateType.Landed)
            task.wait(0.15)
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            flyTime = 0
            wasFlying = true
        end
        
        if wasFlying and flyTime < 0.5 then
            nextPos = V3new(nextPos.X, nextPos.Y - 0.5, nextPos.Z)
        end
        
        if stepCount % 3 == 0 then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        
        if stepCount % 5 == 0 and not hit then
            local checkRay = ws:Raycast(nextPos + V3new(0, 8, 0), V3new(0, -12, 0), ray)
            if checkRay then
                nextPos = V3new(nextPos.X, checkRay.Position.Y + 2.5, nextPos.Z)
                isGrounded = true
            end
        end
        
        hrp.CFrame = CFnew(nextPos, targetPos)
        task.wait(0.04)
    end

    stopCurrentFly()
end
