getgenv().toggled = true

getgenv().old = getgenv().old
    or require(game:GetService('ReplicatedStorage').Module.RayCast).RayIgnoreNonCollideWithIgnoreList

local fovCircle = Drawing.new("Circle")
fovCircle.Visible = true
fovCircle.Radius = 500
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 1
fovCircle.Position = Vector2.new(game:GetService("Workspace").CurrentCamera.ViewportSize.X / 2, game:GetService("Workspace").CurrentCamera.ViewportSize.Y / 2)

local snapline = Drawing.new("Line")
snapline.Visible = false
snapline.Color = Color3.fromRGB(255, 255, 255)
snapline.Thickness = 1.2

local camera = game:GetService("Workspace").CurrentCamera
local player = game:GetService("Players").LocalPlayer

local function isInFOV(targetPos)
    local playerPos = player.Character and player.Character.HumanoidRootPart.Position
    if not playerPos then return false end
    
    local directionToTarget = (targetPos - playerPos).Unit
    local forwardVector = player.Character.HumanoidRootPart.CFrame.LookVector
    local dotProduct = directionToTarget:Dot(forwardVector)
    local fovAngle = math.rad(65 / 2)
    local distance = (targetPos - playerPos).Magnitude
    local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)
    local screenDistance = (Vector2.new(screenPos.X, screenPos.Y) - fovCircle.Position).Magnitude
    return dotProduct > math.cos(fovAngle) and screenDistance <= fovCircle.Radius and onScreen
end

local function updateSnapline(target)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local rootPos = target.Character.HumanoidRootPart.Position
        local screenPos, onScreen = camera:WorldToViewportPoint(rootPos)
        
        if onScreen then
            snapline.Visible = true
            snapline.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
            snapline.To = Vector2.new(screenPos.X, screenPos.Y)
        else
            snapline.Visible = false
        end
    else
        snapline.Visible = false
    end
end

if getgenv().toggled then
    require(game:GetService('ReplicatedStorage').Module.RayCast).RayIgnoreNonCollideWithIgnoreList =
        function(...)
            local nearestDistance, nearestEnemy = fovCircle.Radius, nil
            for i, v in pairs(game:GetService('Players'):GetPlayers()) do
                if
                    v ~= player
                    and v.Team ~= player.Team
                    and v.Character
                    and v.Character:FindFirstChild('HumanoidRootPart')
                    and v.Character:FindFirstChild('Humanoid')
                    and v.Character.Humanoid.Health > 0
                    and isInFOV(v.Character.HumanoidRootPart.Position)
                then
                    local screenPos = camera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position)
                    local screenDistance = (Vector2.new(screenPos.X, screenPos.Y) - fovCircle.Position).Magnitude
                    if screenDistance < nearestDistance then
                        nearestDistance, nearestEnemy = screenDistance, v
                    end
                end
            end
            
            updateSnapline(nearestEnemy)
            
            local arg = { old(...) }
            if
                (
                    tostring(getfenv(2).script) == 'BulletEmitter'
                    or tostring(getfenv(2).script) == 'Taser'
                ) and nearestEnemy
            then
                arg[1] = nearestEnemy.Character.HumanoidRootPart
                arg[2] = nearestEnemy.Character.HumanoidRootPart.Position
            end
            return unpack(arg)
        end
    
    game:GetService("RunService").RenderStepped:Connect(function()
        if toggled then
            local nearestEnemy = nil
            local nearestDistance = fovCircle.Radius
            for i, v in pairs(game:GetService('Players'):GetPlayers()) do
                if
                    v ~= player
                    and v.Team ~= player.Team
                    and v.Character
                    and v.Character:FindFirstChild('HumanoidRootPart')
                    and v.Character:FindFirstChild('Humanoid')
                    and v.Character.Humanoid.Health > 0
                    and isInFOV(v.Character.HumanoidRootPart.Position)
                then
                    local screenPos = camera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position)
                    local screenDistance = (Vector2.new(screenPos.X, screenPos.Y) - fovCircle.Position).Magnitude
                    if screenDistance < nearestDistance then
                        nearestDistance, nearestEnemy = screenDistance, v
                    end
                end
            end
            updateSnapline(nearestEnemy)
            fovCircle.Visible = true
        else
            snapline.Visible = false
            fovCircle.Visible = false
        end
    end)
else
    require(game:GetService('ReplicatedStorage').Module.RayCast).RayIgnoreNonCollideWithIgnoreList = getgenv().old
    snapline.Visible = false
    snapline:Remove()
    fovCircle.Visible = false
    fovCircle:Remove()
end
