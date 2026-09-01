-- // src/visual.lua
local Visual = {}

local function getService(name)
    local service = game:GetService(name)
    return (cloneref and cloneref(service)) or service
end

local UserInputService = getService("UserInputService")
local Players = getService("Players")
local RunService = getService("RunService")
local Workspace = getService("Workspace")
local CoreGui = getService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local MaterialMap = {
    ["NEON"] = Enum.Material.Neon,
    ["FORCEFIELD"] = Enum.Material.ForceField,
    ["GLASS"] = Enum.Material.Glass,
    ["FOIL"] = Enum.Material.Foil,
    ["PLASTIC"] = Enum.Material.SmoothPlastic
}

local ValidBodyParts = {
    ["Head"] = true, ["Torso"] = true, ["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true,
    ["UpperTorso"] = true, ["LowerTorso"] = true,
    ["LeftUpperArm"] = true, ["LeftLowerArm"] = true, ["LeftHand"] = true,
    ["RightUpperArm"] = true, ["RightLowerArm"] = true, ["RightHand"] = true,
    ["LeftUpperLeg"] = true, ["LeftLowerLeg"] = true, ["LeftFoot"] = true,
    ["RightUpperLeg"] = true, ["RightLowerLeg"] = true, ["RightFoot"] = true
}

-- // Калькулятор динамического цвета (Pulse, Rainbow, Gradient, Static)
local function getDynamicColor(mode: string, col1: Color3, col2: Color3, speed: number, offset: number): Color3
    local t = tick() * (speed or 1.0)
    local off = offset or 0

    if mode == "RAINBOW" then
        local hue = (t * 0.2 + off * 0.05) % 1
        return Color3.fromHSV(hue, 1, 1)
    elseif mode == "PULSE" then
        local alpha = (math.sin(t * 3.5) + 1) / 2
        return col1:Lerp(col2, alpha)
    elseif mode == "GRADIENT" then
        local alpha = (math.sin(t * 2.5 + off * 0.4) + 1) / 2
        return col1:Lerp(col2, alpha)
    else
        return col1
    end
end

function Visual.Init(ParentGui)
    local state = {
        -- 3D AutoWall Marker
        awallEnabled = false,
        awallSize = 1.2,
        markerTransparency = 0.25,
        penetrationDepth = 8,
        awallMode = "MOUSE",

        -- CS2 Precision 3D Chams (ViewportFrame)
        chamsEnabled = false,
        chamColorR = 0,
        chamColorG = 210,
        chamColorB = 160,
        chamColor2R = 255,
        chamColor2G = 0,
        chamColor2B = 120,
        chamColorMode = "STATIC", -- "STATIC", "PULSE", "RAINBOW", "GRADIENT"
        chamSpeed = 1.0,
        chamMaterial = "PLASTIC",
        chamTransparency = 0.3,
        chamHideOriginal = true,
        chamTeamCheck = false
    }

    local guiParent = ParentGui or (gethui and gethui()) or CoreGui

    local chamsGui = Instance.new("ScreenGui")
    chamsGui.Name = "CS2_Precision_3DChams"
    chamsGui.ResetOnSpawn = false
    chamsGui.IgnoreGuiInset = true
    chamsGui.DisplayOrder = 1
    chamsGui.Parent = guiParent

    local viewportCamera = Instance.new("Camera")
    viewportCamera.Parent = chamsGui
    
    local viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.new(1, 0, 1, 0)
    viewport.BackgroundTransparency = 1
    viewport.ImageTransparency = 0
    viewport.Ambient = Color3.fromRGB(240, 240, 240)
    viewport.LightColor = Color3.fromRGB(255, 255, 255)
    viewport.LightDirection = Vector3.new(0, 0, -1)
    viewport.CurrentCamera = viewportCamera
    viewport.Parent = chamsGui

    local clonedModels = {}

    local function isEnemy(model)
        if not state.chamTeamCheck then return true end
        local plr = Players:GetPlayerFromCharacter(model)
        if plr and plr ~= LocalPlayer then
            if LocalPlayer.Team and plr.Team then
                return LocalPlayer.Team ~= plr.Team
            end
        end
        return true
    end

    local function isValidTarget(model)
        if not model or not model.Parent then return false end
        if model == LocalPlayer.Character then return false end
        if model:IsDescendantOf(Camera) then return false end
        
        local mName = model.Name:lower()
        if mName:find("viewmodel") or mName:find("arms") or mName:find("weapon") then return false end
        if not model:FindFirstChild("Head") then return false end

        return isEnemy(model)
    end

    local function create3DCham(targetModel)
        if not isValidTarget(targetModel) or clonedModels[targetModel] then return end

        local chamModel = Instance.new("Model")
        chamModel.Name = targetModel.Name

        local targetMat = MaterialMap[state.chamMaterial] or Enum.Material.SmoothPlastic
        local col1 = Color3.fromRGB(state.chamColorR, state.chamColorG, state.chamColorB)
        local col2 = Color3.fromRGB(state.chamColor2R, state.chamColor2G, state.chamColor2B)
        local mode = tostring(state.chamColorMode or "STATIC"):upper()
        local speed = tonumber(state.chamSpeed) or 1.0

        local partIndex = 0

        for _, part in ipairs(targetModel:GetChildren()) do
            if part:IsA("BasePart") and ValidBodyParts[part.Name] then
                partIndex = partIndex + 1
                local p
                
                -- Унифицированная дефолтная голова для всех персонажей
                if part.Name == "Head" then
                    p = Instance.new("Part")
                    p.Name = "Head"
                    p.Size = Vector3.new(2, 1, 1)
                    
                    local mesh = Instance.new("SpecialMesh")
                    mesh.MeshType = Enum.MeshType.Head
                    mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
                    mesh.Parent = p
                else
                    part.Archivable = true
                    p = part:Clone()
                    
                    if not p then
                        p = Instance.new("Part")
                        p.Name = part.Name
                        p.Size = part.Size
                    end

                    -- Очистка от текстур, декалей и эффектов
                    for _, child in ipairs(p:GetChildren()) do
                        if child:IsA("Decal") or child:IsA("Texture") or child:IsA("ParticleEmitter") or child:IsA("Light") or child:IsA("SurfaceAppearance") or child:IsA("BillboardGui") then
                            child:Destroy()
                        end
                    end
                end

                p.Material = targetMat
                p.Color = getDynamicColor(mode, col1, col2, speed, partIndex)
                p.Transparency = state.chamTransparency
                p.CanCollide = false
                p.CanTouch = false
                p.CanQuery = false
                p.CastShadow = false
                p.Anchored = true
                p.Parent = chamModel
            end
        end

        chamModel.Parent = viewport
        clonedModels[targetModel] = chamModel
    end

    local function hideOriginal(realModel)
        for _, obj in ipairs(realModel:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.LocalTransparencyModifier = 1
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            end
        end
    end

    local function restoreOriginal(realModel)
        for _, obj in ipairs(realModel:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.LocalTransparencyModifier = 0
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 0
            end
        end
    end

    -- 2. 3D AutoWall Marker
    local MarkerPart = Instance.new("Part")
    MarkerPart.Name = "Antilose_3DAwallMarker"
    MarkerPart.Material = Enum.Material.Neon
    MarkerPart.Transparency = 1
    MarkerPart.Color = Color3.fromRGB(255, 35, 60)
    MarkerPart.Anchored = true
    MarkerPart.CanCollide = false
    MarkerPart.CanTouch = false
    MarkerPart.CanQuery = false
    MarkerPart.CastShadow = false
    MarkerPart.Size = Vector3.new(state.awallSize, state.awallSize, 0.015)
    MarkerPart.Parent = Camera

    local MarkerOutline = Instance.new("SelectionBox")
    MarkerOutline.Name = "NeonOutline"
    MarkerOutline.Adornee = MarkerPart
    MarkerOutline.Color3 = Color3.fromRGB(255, 35, 60)
    MarkerOutline.LineThickness = 0.035
    MarkerOutline.Transparency = 0
    MarkerOutline.SurfaceTransparency = 1
    MarkerOutline.Visible = false
    MarkerOutline.Parent = MarkerPart

    local function isEnemyCharacter(instance)
        if not instance then return false end
        local current = instance.Parent
        while current and current ~= Workspace and current ~= game do
            if current:FindFirstChildOfClass("Humanoid") then
                local plr = Players:GetPlayerFromCharacter(current)
                if plr and plr ~= LocalPlayer then
                    return true
                end
            end
            current = current.Parent
        end
        return false
    end

    -- Главный цикл рендера
    local renderConn = RunService.RenderStepped:Connect(function()
        if state.chamsEnabled then
            viewport.Visible = true
            viewportCamera.CFrame = Camera.CFrame
            viewportCamera.FieldOfView = Camera.FieldOfView

            local targetMat = MaterialMap[state.chamMaterial] or Enum.Material.SmoothPlastic
            local col1 = Color3.fromRGB(state.chamColorR, state.chamColorG, state.chamColorB)
            local col2 = Color3.fromRGB(state.chamColor2R, state.chamColor2G, state.chamColor2B)
            local mode = tostring(state.chamColorMode or "STATIC"):upper()
            local speed = tonumber(state.chamSpeed) or 1.0

            for realModel, chamModel in pairs(clonedModels) do
                if realModel and realModel.Parent and realModel:FindFirstChild("Head") and isEnemy(realModel) then
                    if state.chamHideOriginal then
                        hideOriginal(realModel)
                    else
                        restoreOriginal(realModel)
                    end

                    local partIndex = 0
                    for _, realPart in ipairs(realModel:GetChildren()) do
                        if realPart:IsA("BasePart") and ValidBodyParts[realPart.Name] then
                            local chamPart = chamModel:FindFirstChild(realPart.Name)
                            if chamPart then
                                partIndex = partIndex + 1
                                local rCF = (realPart.GetRenderCFrame and realPart:GetRenderCFrame()) or realPart.CFrame
                                chamPart.CFrame = rCF
                                chamPart.Material = targetMat
                                chamPart.Color = getDynamicColor(mode, col1, col2, speed, partIndex)
                                chamPart.Transparency = state.chamTransparency
                            end
                        end
                    end
                else
                    if chamModel then chamModel:Destroy() end
                    if realModel and realModel.Parent then
                        restoreOriginal(realModel)
                    end
                    clonedModels[realModel] = nil
                end
            end
        else
            viewport.Visible = false
            if next(clonedModels) then
                for realModel, chamModel in pairs(clonedModels) do
                    if chamModel then chamModel:Destroy() end
                    if realModel and realModel.Parent then
                        restoreOriginal(realModel)
                    end
                end
                table.clear(clonedModels)
            end
        end

        -- Обработка AutoWall маркера
        if not state.awallEnabled then
            MarkerPart.Transparency = 1
            MarkerOutline.Visible = false
            return
        end

        local rayOrigin, rayDirection
        if state.awallMode == "MOUSE" then
            local mouseLoc = UserInputService:GetMouseLocation()
            local unitRay = Camera:ViewportPointToRay(mouseLoc.X, mouseLoc.Y)
            rayOrigin = unitRay.Origin
            rayDirection = unitRay.Direction * 2000
        else
            local center = Camera.ViewportSize / 2
            local unitRay = Camera:ViewportPointToRay(center.X, center.Y)
            rayOrigin = unitRay.Origin
            rayDirection = unitRay.Direction * 2000
        end

        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local filter = { MarkerPart }
        if LocalPlayer.Character then
            table.insert(filter, LocalPlayer.Character)
        end
        rayParams.FilterDescendantsInstances = filter

        local hitResult = Workspace:Raycast(rayOrigin, rayDirection, rayParams)

        if hitResult and hitResult.Instance then
            local hitPos = hitResult.Position
            local hitNormal = hitResult.Normal
            local hitInstance = hitResult.Instance

            if hitNormal.Magnitude < 0.001 then
                hitNormal = Vector3.new(0, 1, 0)
            else
                hitNormal = hitNormal.Unit
            end

            local isPenetrableOrDirectHit = false

            if isEnemyCharacter(hitInstance) then
                isPenetrableOrDirectHit = true
            else
                local dir = rayDirection.Unit
                local penOrigin = hitPos + (dir * 0.1)
                local penDirection = dir * state.penetrationDepth

                local penParams = RaycastParams.new()
                penParams.FilterType = Enum.RaycastFilterType.Exclude
                local penFilter = { MarkerPart, hitInstance }
                if LocalPlayer.Character then
                    table.insert(penFilter, LocalPlayer.Character)
                end
                penParams.FilterDescendantsInstances = penFilter

                local penResult = Workspace:Raycast(penOrigin, penDirection, penParams)
                if penResult and penResult.Instance and isEnemyCharacter(penResult.Instance) then
                    isPenetrableOrDirectHit = true
                end
            end

            local activeColor = isPenetrableOrDirectHit and Color3.fromRGB(30, 255, 120) or Color3.fromRGB(255, 35, 60)

            MarkerPart.Size = Vector3.new(state.awallSize, state.awallSize, 0.015)
            
            local targetPos = hitPos + (hitNormal * 0.015)
            local lookTarget = targetPos + hitNormal
            if (lookTarget - targetPos).Magnitude > 0.001 then
                MarkerPart.CFrame = CFrame.lookAt(targetPos, lookTarget)
            end
            
            MarkerPart.Color = activeColor
            MarkerPart.Transparency = state.markerTransparency

            MarkerOutline.Color3 = activeColor
            MarkerOutline.Visible = true
        else
            MarkerPart.Transparency = 1
            MarkerOutline.Visible = false
        end
    end)

    -- Фоновый сканер сущностей (Игроки + Боты/NPC с Humanoid в Workspace)
    local isScanning = true
    task.spawn(function()
        while isScanning do
            if state.chamsEnabled then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        create3DCham(plr.Character)
                    end
                end
                for _, model in ipairs(Workspace:GetChildren()) do
                    if model:IsA("Model") and model ~= LocalPlayer.Character and model:FindFirstChild("Head") and model:FindFirstChildOfClass("Humanoid") then
                        create3DCham(model)
                    end
                end
            end
            task.wait(0.2)
        end
    end)

    local function cleanup()
        isScanning = false
        pcall(function() renderConn:Disconnect() end)

        for realModel, chamModel in pairs(clonedModels) do
            if chamModel then chamModel:Destroy() end
            if realModel and realModel.Parent then
                restoreOriginal(realModel)
            end
        end
        table.clear(clonedModels)

        if chamsGui then chamsGui:Destroy() end
        if MarkerPart then MarkerPart:Destroy() end
    end

    return { State = state, Cleanup = cleanup }
end

return Visual
