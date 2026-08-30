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

-- Строгие имена частей рук (для исключения деталей оружия вроде Grip/Handle)
local ExactArmNames = {
    ["left arm"] = true,
    ["right arm"] = true,
    ["leftarm"] = true,
    ["rightarm"] = true,
    ["lefthand"] = true,
    ["righthand"] = true,
    ["leftlowerarm"] = true,
    ["rightlowerarm"] = true,
    ["leftupperarm"] = true,
    ["rightupperarm"] = true,
    ["leftshoulder"] = true,
    ["rightshoulder"] = true,
    ["leftglove"] = true,
    ["rightglove"] = true,
    ["glove"] = true,
    ["gloves"] = true,
    ["left_arm"] = true,
    ["right_arm"] = true,
    ["l_arm"] = true,
    ["r_arm"] = true,
    ["l_hand"] = true,
    ["r_hand"] = true,
    ["l_glove"] = true,
    ["r_glove"] = true,
    ["sleeve"] = true,
    ["sleeves"] = true,
    ["leftsleeve"] = true,
    ["rightsleeve"] = true
}

local WeaponContainers = {
    "gun", "weapon", "knife", "sword", "c4", "grenade", "flashbang", "smoke", "tool", "arms_weapon"
}

local IgnoreKeywords = {
    "root", "hitbox", "bounding", "origin", "camera", "aim", "offset",
    "spring", "node", "point", "flash", "muzzle", "particle", "sound", "collider", "attachment"
}

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

    -- Изолированный HDR Bloom (Threshold = 2.0 исключает карту и небо)
    local CustomBloom = Lighting:FindFirstChild("AntiloseNeonBloom")
    if not CustomBloom then
        CustomBloom = Instance.new("BloomEffect")
        CustomBloom.Name = "AntiloseNeonBloom"
        CustomBloom.Intensity = 1.2
        CustomBloom.Size = 18
        CustomBloom.Threshold = 2.0 -- Срабатывает ТОЛЬКО на наш HDR VertexColor (> 2.0)
        CustomBloom.Enabled = false
        CustomBloom.Parent = Lighting
    end

    local CustomAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
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

        -- Arms
        armsEnabled = false,
        armsMaterial = "NEON",
        armsColorR = 0,
        armsColorG = 255,
        armsColorB = 255,
        armsTransparency = 0,

        -- Weapon
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

    local function isIgnoredPart(part)
        if not part:IsA("BasePart") then return true end
        if part.Name == "Antilose_3DAwallMarker" then return true end
        
        local pName = part.Name:lower()
        for _, ignore in ipairs(IgnoreKeywords) do
            if pName:find(ignore) then
                return true
            end
        end
        return false
    end

    -- Проверка, лежит ли деталь внутри модели оружия
    local function isInsideWeaponModel(part)
        if part:FindFirstAncestorOfClass("Tool") then return true end
        local parent = part.Parent
        while parent and parent ~= Workspace and parent ~= Camera do
            local parentName = parent.Name:lower()
            for _, wName in ipairs(WeaponContainers) do
                if parentName:find(wName) then
                    return true
                end
            end
            parent = parent.Parent
        end
        return false
    end

    -- 100% точное распознавание рук
    local function isArmPart(part)
        if isIgnoredPart(part) then return false end
        if isInsideWeaponModel(part) then return false end

        local pName = part.Name:lower()
        if ExactArmNames[pName] then
            return true
        end

        -- Если это часть руки в персонаже (3-е лицо)
        if LocalPlayer.Character and part:IsDescendantOf(LocalPlayer.Character) then
            if ExactArmNames[part.Name] or pName:find("arm") or pName:find("hand") then
                return true
            end
        end

        -- Вьюмодель: проверяем имя прямого родителя (например, модель "Left Arm")
        local pModel = part.Parent
        if pModel and pModel:IsA("Model") and pModel ~= Camera and pModel.Name ~= "Arms" then
            local mName = pModel.Name:lower()
            if ExactArmNames[mName] then
                return true
            end
        end

        return false
    end

    -- 100% точное распознавание оружия
    local function isWeaponPart(part)
        if isIgnoredPart(part) then return false end
        if isArmPart(part) then return false end

        -- В персонаже
        if LocalPlayer.Character and part:IsDescendantOf(LocalPlayer.Character) then
            if part:FindFirstAncestorOfClass("Tool") then return true end
        end

        -- Во вьюмодели в Camera
        if part:IsDescendantOf(Camera) or part:FindFirstAncestor("Arms") or part:FindFirstAncestor("ViewModel") then
            return true
        end

        return false
    end

    -- Применение стиля материала
    local function applyChamsToPart(part, storeTable, otherStoreTable, matName, targetMat, targetCol, targetAlpha)
        if not part or not part.Parent then return end
        if otherStoreTable and otherStoreTable[part] then return end

        if not storeTable[part] then
            if part.Transparency >= 0.99 then return end

            local sMesh = part:FindFirstChildOfClass("SpecialMesh")
            local sApp = part:FindFirstChildOfClass("SurfaceAppearance")
            local decals = {}
            for _, d in ipairs(part:GetChildren()) do
                if d:IsA("Decal") or d:IsA("Texture") then
                    table.insert(decals, { Instance = d, Transparency = d.Transparency })
                end
            end

            storeTable[part] = {
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

        local stored = storeTable[part]
        
        -- Скрываем мешающие текстуры
        if stored.SurfaceAppearance and stored.SurfaceAppearance.Parent then
            stored.SurfaceAppearance.Parent = nil
        end
        for _, dData in ipairs(stored.Decals) do
            if dData.Instance and dData.Instance.Parent then
                dData.Instance.Transparency = 1
            end
        end

        -- Обработка SpecialMesh для каждого конкретного материала
        if stored.SpecialMesh and stored.SpecialMesh.Parent then
            if stored.SpecialMesh.TextureId ~= "" then
                pcall(function() stored.SpecialMesh.TextureId = "" end)
            end
            
            if matName == "NEON" then
                -- HDR-свечение выше порога 2.0 (только для Неона)
                stored.SpecialMesh.VertexColor = Vector3.new(targetCol.R * 3.5, targetCol.G * 3.5, targetCol.B * 3.5)
            elseif matName == "FOIL" then
                stored.SpecialMesh.VertexColor = Vector3.new(targetCol.R * 1.5, targetCol.G * 1.5, targetCol.B * 1.5)
            else
                -- Чистый 1:1 цвет для PLASTIC, GLASS, FORCEFIELD (без ослепления)
                stored.SpecialMesh.VertexColor = Vector3.new(targetCol.R, targetCol.G, targetCol.B)
            end
        end

        -- Свойства детали
        part.Material = targetMat
        part.Color = targetCol
        
        if matName == "FORCEFIELD" then
            part.Transparency = math.clamp(targetAlpha > 0 and targetAlpha or 0.1, 0.05, 0.95)
        else
            part.Transparency = targetAlpha
        end
    end

    local function restoreChamsTable(storeTable)
        for part, props in pairs(storeTable) do
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
        table.clear(storeTable)
    end

    local renderStepName = "Antilose_Chams_RenderStep"
    RunService:BindToRenderStep(renderStepName, Enum.RenderPriority.Last.Value, function()
        local needBloom = false

        -- 1. Руки (Arms)
        if state.armsEnabled then
            if LocalPlayer.Character then
                local shirt = LocalPlayer.Character:FindFirstChildOfClass("Shirt")
                if shirt and shirt.Parent then
                    CachedShirt = shirt
                    shirt.Parent = nil
                end
            end

            local matName = state.armsMaterial
            local targetMat = MaterialMap[matName] or Enum.Material.Neon
            local targetCol = Color3.fromRGB(state.armsColorR, state.armsColorG, state.armsColorB)

            if matName == "NEON" then needBloom = true end

            if LocalPlayer.Character then
                for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if isArmPart(p) then
                        applyChamsToPart(p, OrigArmProps, OrigWeaponProps, matName, targetMat, targetCol, state.armsTransparency)
                    end
                end
            end
            for _, p in ipairs(Camera:GetDescendants()) do
                if isArmPart(p) then
                    applyChamsToPart(p, OrigArmProps, OrigWeaponProps, matName, targetMat, targetCol, state.armsTransparency)
                end
            end
        else
            if CachedShirt and CachedShirt.Parent == nil and LocalPlayer.Character then
                CachedShirt.Parent = LocalPlayer.Character
                CachedShirt = nil
            end
            if next(OrigArmProps) then
                restoreChamsTable(OrigArmProps)
            end
        end

        -- 2. Оружие (Weapon)
        if state.weaponEnabled then
            local matName = state.weaponMaterial
            local targetMat = MaterialMap[matName] or Enum.Material.ForceField
            local targetCol = Color3.fromRGB(state.weaponColorR, state.weaponColorG, state.weaponColorB)

            if matName == "NEON" then needBloom = true end

            if LocalPlayer.Character then
                for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if isWeaponPart(p) then
                        applyChamsToPart(p, OrigWeaponProps, OrigArmProps, matName, targetMat, targetCol, state.weaponTransparency)
                    end
                end
            end
            for _, p in ipairs(Camera:GetDescendants()) do
                if isWeaponPart(p) then
                    applyChamsToPart(p, OrigWeaponProps, OrigArmProps, matName, targetMat, targetCol, state.weaponTransparency)
                end
            end
        else
            if next(OrigWeaponProps) then
                restoreChamsTable(OrigWeaponProps)
            end
        end

        -- Включаем Bloom ТОЛЬКО если активен материал NEON
        CustomBloom.Enabled = needBloom
    end)

    local function cleanup()
        pcall(function() descConn:Disconnect() end)
        pcall(function() timeConn:Disconnect() end)
        pcall(function() RunService:UnbindFromRenderStep(renderStepName) end)

        if CachedShirt and LocalPlayer.Character then
            CachedShirt.Parent = LocalPlayer.Character
        end

        if CustomBloom and CustomBloom.Name == "AntiloseNeonBloom" then
            CustomBloom:Destroy()
        end
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

        restoreChamsTable(OrigArmProps)
        restoreChamsTable(OrigWeaponProps)
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
