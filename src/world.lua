-- // src/world.lua
local World = {}

local function getService(name)
    local service = game:GetService(name)
    return (cloneref and cloneref(service)) or service
end

local Players = getService("Players")
local Lighting = getService("Lighting")
local Workspace = getService("Workspace")
local RunService = getService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local MaterialMap = {
    ["NEON"] = Enum.Material.Neon,
    ["FORCEFIELD"] = Enum.Material.ForceField,
    ["GLASS"] = Enum.Material.Glass,
    ["FOIL"] = Enum.Material.Foil,
    ["PLASTIC"] = Enum.Material.SmoothPlastic
}

-- Имена частей рук персонажа от 3-го лица
local CharacterArmLimbs = {
    ["Left Arm"] = true, ["Right Arm"] = true,
    ["LeftHand"] = true, ["RightHand"] = true,
    ["LeftLowerArm"] = true, ["RightLowerArm"] = true,
    ["LeftUpperArm"] = true, ["RightUpperArm"] = true,
}

local ForcefieldTexture = "rbxassetid://497042571"

function World.Init()
    local OriginalLighting = {
        ClockTime = Lighting.ClockTime,
        Brightness = Lighting.Brightness,
        ExposureCompensation = Lighting.ExposureCompensation,
        FogStart = Lighting.FogStart,
        FogEnd = Lighting.FogEnd,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
    }
    
    local OriginalTransparencies = {}
    local OrigArmProps = {}
    local OrigWeaponProps = {}
    local CachedShirt = nil

    local CustomAtmosphere = Lighting:FindFirstChild("AntiloseAtmosphere")
    if not CustomAtmosphere then
        CustomAtmosphere = Instance.new("Atmosphere")
        CustomAtmosphere.Name = "AntiloseAtmosphere"
        CustomAtmosphere.Density = 0.3
        CustomAtmosphere.Parent = Lighting
    end

    local CustomColorCorrection = Lighting:FindFirstChild("AntiloseColorCorrection")
    if not CustomColorCorrection then
        CustomColorCorrection = Instance.new("ColorCorrectionEffect")
        CustomColorCorrection.Name = "AntiloseColorCorrection"
        CustomColorCorrection.Enabled = true
        CustomColorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
        CustomColorCorrection.Parent = Lighting
    end

    local state = {
        mapTransparencyEnabled = false,
        mapTransparencyValue = 0.5,
        lockTimeEnabled = false,
        targetTime = Lighting.ClockTime,
        worldTintR = 255,
        worldTintG = 255,
        worldTintB = 255,

        -- Arms Chams
        armsEnabled = false,
        armsMaterial = "NEON",
        armsColorR = 0,
        armsColorG = 255,
        armsColorB = 255,
        armsTransparency = 0,

        -- Weapon Chams
        weaponEnabled = false,
        weaponMaterial = "FORCEFIELD",
        weaponColorR = 255,
        weaponColorG = 255,
        weaponColorB = 255,
        weaponTransparency = 0
    }

    local function isPlayerDescendant(instance)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character and instance:IsDescendantOf(plr.Character) then
                return true
            end
        end
        return false
    end

    local function applyTransparency(part)
        if part:IsA("BasePart") and not part:IsA("Terrain") and not isPlayerDescendant(part) then
            if OriginalTransparencies[part] == nil then
                OriginalTransparencies[part] = part.Transparency
            end
            if state.mapTransparencyEnabled then
                part.Transparency = math.clamp(math.max(OriginalTransparencies[part], state.mapTransparencyValue), 0, 1)
            else
                part.Transparency = OriginalTransparencies[part]
            end
        end
    end

    local function updateAllMapParts()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            applyTransparency(obj)
        end
    end

    local descConn = Workspace.DescendantAdded:Connect(function(obj)
        if state.mapTransparencyEnabled then
            task.defer(function() applyTransparency(obj) end)
        end
    end)

    local timeConn = Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
        if state.lockTimeEnabled then
            Lighting.ClockTime = state.targetTime
        end
    end)

    local function updateWorldColor()
        local color = Color3.fromRGB(state.worldTintR, state.worldTintG, state.worldTintB)
        CustomColorCorrection.TintColor = color
        Lighting.Ambient = color
        Lighting.OutdoorAmbient = color
    end

    -- Сохранение и применение Chams к отдельной детали
    local function applyChams(part, store, matName, matEnum, color, alpha)
        if not part or not part:IsA("BasePart") or part.Name == "Antilose_3DAwallMarker" then return end

        if not store[part] then
            local sMesh = part:FindFirstChildOfClass("SpecialMesh")
            local sApp = part:FindFirstChildOfClass("SurfaceAppearance")
            local decals = {}
            for _, d in ipairs(part:GetChildren()) do
                if d:IsA("Decal") or d:IsA("Texture") then
                    table.insert(decals, { Instance = d, Transparency = d.Transparency })
                end
            end

            store[part] = {
                Material = part.Material,
                Color = part.Color,
                Transparency = part.Transparency,
                SpecialMesh = sMesh,
                SpecialMeshTexture = sMesh and sMesh.TextureId or nil,
                SpecialMeshVertexColor = sMesh and sMesh.VertexColor or nil,
                SurfaceAppearance = sApp,
                Decals = decals
            }
        end

        local stored = store[part]

        -- Скрываем мешающие текстуры и декали
        if stored.SurfaceAppearance and stored.SurfaceAppearance.Parent then
            stored.SurfaceAppearance.Parent = nil
        end
        for _, dData in ipairs(stored.Decals) do
            if dData.Instance and dData.Instance.Parent then
                dData.Instance.Transparency = 1
            end
        end

        -- Настройка SpecialMesh
        if stored.SpecialMesh and stored.SpecialMesh.Parent then
            if matName == "FORCEFIELD" then
                if stored.SpecialMesh.TextureId ~= ForcefieldTexture then
                    stored.SpecialMesh.TextureId = ForcefieldTexture
                end
            else
                if stored.SpecialMesh.TextureId ~= "" then
                    stored.SpecialMesh.TextureId = ""
                end
            end
            stored.SpecialMesh.VertexColor = Vector3.new(color.R, color.G, color.B)
        end

        part.Material = matEnum
        part.Color = color
        part.Transparency = alpha
    end

    -- Восстановление оригинального вида
    local function restoreChams(store)
        for part, props in pairs(store) do
            if part and part.Parent then
                pcall(function()
                    part.Material = props.Material
                    part.Color = props.Color
                    part.Transparency = props.Transparency
                    if props.SpecialMesh and props.SpecialMesh.Parent then
                        if props.SpecialMeshTexture then
                            props.SpecialMesh.TextureId = props.SpecialMeshTexture
                        end
                        if props.SpecialMeshVertexColor then
                            props.SpecialMesh.VertexColor = props.SpecialMeshVertexColor
                        end
                    end
                    if props.SurfaceAppearance then
                        props.SurfaceAppearance.Parent = part
                    end
                    for _, dData in ipairs(props.Decals) do
                        if dData.Instance and dData.Instance.Parent then
                            dData.Instance.Transparency = dData.Transparency
                        end
                    end
                end)
            end
        end
        table.clear(store)
    end

    -- Главный цикл отрисовки
    local renderConn = RunService.RenderStepped:Connect(function()
        local armsMat = MaterialMap[state.armsMaterial] or Enum.Material.Neon
        local armsCol = Color3.fromRGB(state.armsColorR, state.armsColorG, state.armsColorB)
        local wepMat = MaterialMap[state.weaponMaterial] or Enum.Material.ForceField
        local wepCol = Color3.fromRGB(state.weaponColorR, state.weaponColorG, state.weaponColorB)

        -- 1. РУКИ (1-е лицо в Camera.Arms + 3-е лицо в Character)
        if state.armsEnabled then
            -- 3-е лицо
            if LocalPlayer.Character then
                local shirt = LocalPlayer.Character:FindFirstChildOfClass("Shirt")
                if shirt and shirt.Parent then
                    CachedShirt = shirt
                    shirt.Parent = nil
                end
                for _, part in ipairs(LocalPlayer.Character:GetChildren()) do
                    if part:IsA("BasePart") and CharacterArmLimbs[part.Name] then
                        applyChams(part, OrigArmProps, state.armsMaterial, armsMat, armsCol, state.armsTransparency)
                    end
                end
            end

            -- 1-е лицо (Camera.Arms)
            local vmArms = Camera:FindFirstChild("Arms") or Camera:FindFirstChild("ViewModel") or Camera:FindFirstChild("Viewmodel")
            if vmArms then
                local leftArm = vmArms:FindFirstChild("Left Arm") or vmArms:FindFirstChild("LeftArm")
                local rightArm = vmArms:FindFirstChild("Right Arm") or vmArms:FindFirstChild("RightArm")

                if leftArm then
                    for _, p in ipairs(leftArm:GetDescendants()) do
                        if p:IsA("BasePart") then
                            applyChams(p, OrigArmProps, state.armsMaterial, armsMat, armsCol, state.armsTransparency)
                        end
                    end
                    if leftArm:IsA("BasePart") then
                        applyChams(leftArm, OrigArmProps, state.armsMaterial, armsMat, armsCol, state.armsTransparency)
                    end
                end

                if rightArm then
                    for _, p in ipairs(rightArm:GetDescendants()) do
                        if p:IsA("BasePart") then
                            applyChams(p, OrigArmProps, state.armsMaterial, armsMat, armsCol, state.armsTransparency)
                        end
                    end
                    if rightArm:IsA("BasePart") then
                        applyChams(rightArm, OrigArmProps, state.armsMaterial, armsMat, armsCol, state.armsTransparency)
                    end
                end
            end
        else
            if CachedShirt and LocalPlayer.Character and CachedShirt.Parent == nil then
                CachedShirt.Parent = LocalPlayer.Character
                CachedShirt = nil
            end
            if next(OrigArmProps) then
                restoreChams(OrigArmProps)
            end
        end

        -- 2. ОРУЖИЕ (1-е лицо в Camera.Arms + 3-е лицо в Tool)
        if state.weaponEnabled then
            -- 3-е лицо
            if LocalPlayer.Character then
                local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool then
                    for _, p in ipairs(tool:GetDescendants()) do
                        if p:IsA("BasePart") then
                            applyChams(p, OrigWeaponProps, state.weaponMaterial, wepMat, wepCol, state.weaponTransparency)
                        end
                    end
                end
            end

            -- 1-е лицо (Все элементы в Camera.Arms кроме Left Arm и Right Arm)
            local vmArms = Camera:FindFirstChild("Arms") or Camera:FindFirstChild("ViewModel") or Camera:FindFirstChild("Viewmodel")
            if vmArms then
                for _, child in ipairs(vmArms:GetChildren()) do
                    local name = child.Name
                    -- Игнорируем руки и системные эффекты
                    if name ~= "Left Arm" and name ~= "Right Arm" and name ~= "LeftArm" and name ~= "RightArm" 
                       and name ~= "Flash" and name ~= "Bullet" and name ~= "AnimSaves" and name ~= "HumanoidRootPart" then
                        
                        if child:IsA("BasePart") then
                            applyChams(child, OrigWeaponProps, state.weaponMaterial, wepMat, wepCol, state.weaponTransparency)
                        end
                        for _, p in ipairs(child:GetDescendants()) do
                            if p:IsA("BasePart") then
                                applyChams(p, OrigWeaponProps, state.weaponMaterial, wepMat, wepCol, state.weaponTransparency)
                            end
                        end
                    end
                end
            end
        else
            if next(OrigWeaponProps) then
                restoreChams(OrigWeaponProps)
            end
        end
    end)

    local function cleanup()
        pcall(function() descConn:Disconnect() end)
        pcall(function() timeConn:Disconnect() end)
        pcall(function() renderConn:Disconnect() end)

        if CachedShirt and LocalPlayer.Character then
            CachedShirt.Parent = LocalPlayer.Character
        end

        local oldBloom = Lighting:FindFirstChild("AntiloseNeonBloom")
        if oldBloom then oldBloom:Destroy() end

        if CustomAtmosphere and CustomAtmosphere.Name == "AntiloseAtmosphere" then
            CustomAtmosphere:Destroy()
        end
        if CustomColorCorrection then
            CustomColorCorrection:Destroy()
        end

        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ExposureCompensation = OriginalLighting.ExposureCompensation
        Lighting.FogStart = OriginalLighting.FogStart
        Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient

        state.mapTransparencyEnabled = false
        for part, alpha in pairs(OriginalTransparencies) do
            if part and part.Parent then part.Transparency = alpha end
        end

        restoreChams(OrigArmProps)
        restoreChams(OrigWeaponProps)
    end

    return {
        State = state,
        Atmosphere = CustomAtmosphere,
        UpdateAllMapParts = updateAllMapParts,
        UpdateWorldColor = updateWorldColor,
        Cleanup = cleanup
    }
end

return World
