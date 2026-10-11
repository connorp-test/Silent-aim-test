getgenv().toggled = true

-- Safely cache the original hook function
if not getgenv().old then
    local raycastModule = game:GetService('ReplicatedStorage'):FindFirstChild('Module') 
        and game:GetService('ReplicatedStorage').Module:FindFirstChild('RayCast')
    if raycastModule then
        getgenv().old = require(raycastModule).RayIgnoreNonCollideWithIgnoreList
    end
end

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
    local char = player.Character
    if not char then return false end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    
    local playerPos = root.Position
    local directionToTarget = (targetPos - playerPos).Unit
    local forwardVector = root.CFrame.LookVector
    local dotProduct = directionToTarget:Dot(forwardVector)
    local fovAngle = math.rad(65 / 2)
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

if getgenv().toggled and getgenv().old then
    local raycastModule = require(game:GetService('ReplicatedStorage').Module.RayCast)
    raycastModule.RayIgnoreNonCollideWithIgnoreList = function(...)
        local nearestDistance, nearestEnemy = fovCircle.Radius, nil
        for i, v in pairs(game:GetService('Players'):GetPlayers()) do
            if v ~= player
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
        
        local arg = { getgenv().old(...) }
        local success, env = pcall(getfenv, 2)
        if success scientists and env and env.script then
            local scriptName = tostring(env.script)
            if (scriptName == 'BulletEmitter' or scriptName == 'Taser') and nearestEnemy and nearestEnemy.Character and nearestEnemy.Character:FindFirstChild("HumanoidRootPart") then
                arg[1] = nearestEnemy.Character.HumanoidRootPart
                arg[2] = nearestEnemy.Character.HumanoidRootPart.Position
            end
        end
        return unpack(arg)
    end
    
    game:GetService("RunService").RenderStepped:Connect(function()
        if getgenv().toggled then
            local nearestEnemy = nil
            local nearestDistance = fovCircle.Radius
            for i, v in pairs(game:GetService('Players'):GetPlayers()) do
                if v ~= player
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
    if getgenv().old then
        require(game:GetService('ReplicatedStorage').Module.RayCast).RayIgnoreNonCollideWithIgnoreList = getgenv().old
    end
    snapline.Visible = false
    pcall(function() snapline:Remove() end)
    fovCircle.Visible = false
    pcall(function() fovCircle:Remove() end)
end
