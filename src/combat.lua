-- src/combat.lua
local Combat = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Глобальные настройки
getgenv().AimbotSettings = getgenv().AimbotSettings or {
    Enabled = true,
    AliveCheck = true,
    AimPart = "Smart", -- "Smart", "Head", "HumanoidRootPart"
    Sensitivity = 0.15,
    TriggerKey = Enum.UserInputType.MouseButton2,
    BindType = "Hold", -- "Hold", "Toggle", "Always On"
    WallCheck = true,
    ReturnToOriginal = true,
    
    PartsList = {
        "Head", "UpperTorso", "LowerTorso", 
        "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
        "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", 
        "HumanoidRootPart"
    },
    
    FOV = {
        Visible = true,
        Type = "MOUSE", -- "MOUSE", "CENTER"
        BaseRadius = 150,
        Color = Color3.fromRGB(255, 85, 85),
        Thickness = 1,
        Filled = false,
        Sides = 64
    }
}

local Settings = getgenv().AimbotSettings
local TargetEntities = {}
local FOVCircle = nil
local connectionRender = nil
local connectionBegan = nil
local connectionEnded = nil
local cacheThread = nil
local isAiming = false
local preLockCFrame = nil
local wasLocked = false

local function GetFOVPosition()
    if Settings.FOV.Type == "CENTER" then
        return Camera.ViewportSize / 2
    else
        return UserInputService:GetMouseLocation()
    end
end

local function GetDynamicRadius()
    local defaultFOV = 70
    local currentFOV = Camera.FieldOfView
    return Settings.FOV.BaseRadius * (defaultFOV / currentFOV)
end

local function UpdateFOV()
    if not FOVCircle then return end
    FOVCircle.Visible = Settings.FOV.Visible and Settings.Enabled
    FOVCircle.Radius = GetDynamicRadius()
    FOVCircle.Color = Settings.FOV.Color
    FOVCircle.Position = GetFOVPosition()
end

-- Проверка препятствий (Умный цикличный Wall Check)
local function IsPartVisible(part, character)
    if not Settings.WallCheck then return true end
    
    local origin = Camera.CFrame.Position
    local destination = part.Position
    local direction = destination - origin
    
    local ignoreList = {LocalPlayer.Character, character, Camera}
    for _, obj in ipairs(Camera:GetChildren()) do
        table.insert(ignoreList, obj)
    end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    
    local attempts = 0
    local maxAttempts = 15
    
    while attempts < maxAttempts do
        raycastParams.FilterInstances = ignoreList
        local result = workspace:Raycast(origin, direction, raycastParams)
        
        if not result then
            return true
        end
        
        local hitPart = result.Instance
        
        local isFakeObstacle = (hitPart.CanCollide == false)
            or (hitPart.Transparency > 0.75)
            or (hitPart.Name == "Handle")
            or hitPart:IsA("ForceField")
            or hitPart:IsA("Decal")
            or hitPart:IsA("Texture")
            or hitPart:IsDescendantOf(Camera)
            or hitPart.Parent:FindFirstChildOfClass("Tool")
        
        if isFakeObstacle then
            table.insert(ignoreList, hitPart)
            attempts = attempts + 1
        else
            return false
        end
    end
    
    return false
end

local function IsTargetValid(character)
    if not character or not character:IsDescendantOf(workspace) then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    if Settings.AliveCheck and humanoid.Health <= 0 then return false end
    return true
end

local function GetClosestTarget()
    local bestTarget = nil
    local bestPart = nil
    local maxDistance = GetDynamicRadius()
    local fovOrigin = GetFOVPosition()

    for _, character in ipairs(TargetEntities) do
        if IsTargetValid(character) then
            if Settings.AimPart ~= "Smart" then
                local part = character:FindFirstChild(Settings.AimPart)
                if part and IsPartVisible(part, character) then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - fovOrigin).Magnitude
                        if distance < maxDistance then
                            bestTarget = character
                            bestPart = part
                            maxDistance = distance
                        end
                    end
                end
            else
                for _, partName in ipairs(Settings.PartsList) do
                    local part = character:FindFirstChild(partName)
                    if part and IsPartVisible(part, character) then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local distance = (Vector2.new(screenPos.X, screenPos.Y) - fovOrigin).Magnitude
                            if distance < maxDistance then
                                bestTarget = character
                                bestPart = part
                                maxDistance = distance
                            end
                        end
                    end
                end
            end
        end
    end
    return bestTarget, bestPart
end

local function HandleInput(input, isBegan)
    local isKey = (input.KeyCode == Settings.TriggerKey) or (input.UserInputType == Settings.TriggerKey)
    if not isKey then return end

    if Settings.BindType == "Hold" then
        isAiming = isBegan
    elseif Settings.BindType == "Toggle" and isBegan then
        isAiming = not isAiming
    end
end

function Combat.Init()
    if FOVCircle then return Combat end
    
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = Settings.FOV.Visible
    FOVCircle.Color = Settings.FOV.Color
    FOVCircle.Thickness = Settings.FOV.Thickness
    FOVCircle.Filled = Settings.FOV.Filled
    FOVCircle.NumSides = Settings.FOV.Sides

    cacheThread = task.spawn(function()
        while true do
            local tempTargets = {}
            for _, desc in ipairs(workspace:GetDescendants()) do
                if desc:IsA("Humanoid") then
                    local character = desc.Parent
                    if character and character:IsA("Model") and character ~= LocalPlayer.Character then
                        table.insert(tempTargets, character)
                    end
                end
            end
            TargetEntities = tempTargets
            task.wait(0.5)
        end
    end)

    connectionBegan = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        HandleInput(input, true)
    end)

    connectionEnded = UserInputService.InputEnded:Connect(function(input, processed)
        HandleInput(input, false)
    end)

    connectionRender = RunService.RenderStepped:Connect(function()
        UpdateFOV()
        
        local activeAim = isAiming
        if Settings.BindType == "Always On" then
            activeAim = true
        end
        
        if Settings.Enabled and activeAim then
            local targetCharacter, targetPart = GetClosestTarget()
            
            if targetCharacter and targetPart then
                if not wasLocked then
                    preLockCFrame = Camera.CFrame
                    wasLocked = true
                end
                
                local currentCFrame = Camera.CFrame
                local targetCFrame = CFrame.new(currentCFrame.Position, targetPart.Position)
                Camera.CFrame = currentCFrame:Lerp(targetCFrame, Settings.Sensitivity)
            else
                if wasLocked then
                    wasLocked = false
                    if Settings.ReturnToOriginal and preLockCFrame then
                        Camera.CFrame = preLockCFrame
                        preLockCFrame = nil
                    end
                end
            end
        else
            if wasLocked then
                wasLocked = false
                if Settings.ReturnToOriginal and preLockCFrame then
                    Camera.CFrame = preLockCFrame
                    preLockCFrame = nil
                end
            end
        end
    end)
    
    return Combat
end

function Combat.Cleanup()
    if FOVCircle then FOVCircle:Destroy() FOVCircle = nil end
    if connectionRender then connectionRender:Disconnect() connectionRender = nil end
    if connectionBegan then connectionBegan:Disconnect() connectionBegan = nil end
    if connectionEnded then connectionEnded:Disconnect() connectionEnded = nil end
    if cacheThread then task.cancel(cacheThread) cacheThread = nil end
end

return Combat
