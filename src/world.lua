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

local ArmLimbNames = {
    ["Left Arm"] = true, ["Right Arm"] = true,
    ["LeftHand"] = true, ["RightHand"] = true,
    ["LeftLowerArm"] = true, ["RightLowerArm"] = true,
    ["LeftUpperArm"] = true, ["RightUpperArm"] = true
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

        -- Self Chams (Руки)
        armsEnabled = false,
        armsMaterial = "NEON",
        armsColorR = 255,
        armsColorG = 255,
        armsColorB = 255,
        armsTransparency = 0,

        -- Self Chams (Оружие / Предметы)
        weaponEnabled = false,
        weaponMaterial = "FORCEFIELD",
        weaponColorR = 0,
        weaponColorG = 255,
        weaponColorB = 255,
        weaponTransparency = 0
    }

    -- Проверка на игрока
    local function isPlayerDescendant(instance)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character and instance:IsDescendantOf(plr.Character) then
                return true
            end
        end
        return false
    end

    -- Прозрачность карты
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

    -- Распознавание рук
    local function isArmPart(part)
        if not part:IsA("BasePart") then return false end
        if part.Name == "HumanoidRootPart" or part.Name:lower():find("root") then return false end

        -- Руки персонажа
        if LocalPlayer.Character and part:IsDescendantOf(LocalPlayer.Character) then
            if not part:FindFirstAncestorOfClass("Tool") and (ArmLimbNames[part.Name] or part.Name:lower():find("arm") or part.Name:lower():find("hand")) then
                return true
            end
        end

        -- Вьюмодель в камере
        if part:IsDescendantOf(Camera) and part.Name ~= "Antilose_3DAwallMarker" then
            local pName = part.Name:lower()
            local parentName = part.Parent and part.Parent.Name:lower() or ""
            if pName:find("arm") or pName:find("hand") or pName:find("sleeve") or pName:find("glove") or parentName:find("arm") then
                return true
            end
        end
        return false
    end

    -- Распознавание оружия
    local function isWeaponPart(part)
        if not part:IsA("BasePart") then return false end
        if part.Name == "HumanoidRootPart" or part.Name:lower():find("root") or part.Name:lower():find("hitbox") or part.Name:lower():find("bounding") then
            return false
        end

        if LocalPlayer.Character and part:IsDescendantOf(LocalPlayer.Character) and part:FindFirstAncestorOfClass("Tool") then
            return true
        end

        if part:IsDescendantOf(Camera) and part.Name ~= "Antilose_3DAwallMarker" and not isArmPart(part) then
            return true
        end
        return false
    end

    -- Применение материала к детали со снятием текстур
    local function applyChamsToPart(part, storeTable, targetMat, targetCol, targetAlpha)
        if not storeTable[part] then
            -- Если деталь изначально была полностью невидимым боксом — пропускаем ее!
            if part.Transparency >= 0.95 then
                return
            end

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
                TextureID = part:IsA("MeshPart") and part.TextureID or nil,
                SpecialMesh = sMesh,
                SpecialMeshTexture = sMesh and sMesh.TextureId or nil,
                SurfaceAppearance = sApp,
                Decals = decals
            }
        end

        -- Снимаем текстуры, мешающие неону/форсфилду
        if part:IsA("MeshPart") and part.TextureID ~= "" then
            part.TextureID = ""
        end
        if storeTable[part].SpecialMesh and storeTable[part].SpecialMesh.TextureId ~= "" then
            storeTable[part].SpecialMesh.TextureId = ""
        end
        if storeTable[part].SurfaceAppearance then
            storeTable[part].SurfaceAppearance.Parent = nil
        end
        for _, dData in ipairs(storeTable[part].Decals) do
            if dData.Instance and dData.Instance.Parent then
                dData.Instance.Transparency = 1
            end
        end

        part.Material = targetMat
        part.Color = targetCol
        part.Transparency = targetAlpha
    end

    -- Восстановление оригинального вида
    local function restoreChamsTable(storeTable)
        for part, props in pairs(storeTable) do
            if part and part.Parent then
                part.Material = props.Material
                part.Color = props.Color
                part.Transparency = props.Transparency
                if props.TextureID and part:IsA("MeshPart") then
                    part.TextureID = props.TextureID
                end
                if props.SpecialMesh and props.SpecialMesh.Parent and props.SpecialMeshTexture then
                    props.SpecialMesh.TextureId = props.SpecialMeshTexture
                end
                if props.SurfaceAppearance then
                    props.SurfaceAppearance.Parent = part
                end
                for _, dData in ipairs(props.Decals) do
                    if dData.Instance and dData.Instance.Parent then
                        dData.Instance.Transparency = dData.Transparency
                    end
                end
            end
        end
        table.clear(storeTable)
    end

    -- Главный цикл обновления Chams
    local chamsConn = RunService.RenderStepped:Connect(function()
        -- 1. РУКИ (Arms)
        if state.armsEnabled then
            -- Скрываем 2D одежду персонажа, если она блокирует неон
            if LocalPlayer.Character then
                local shirt = LocalPlayer.Character:FindFirstChildOfClass("Shirt")
                if shirt and shirt.Parent then
                    CachedShirt = shirt
                    shirt.Parent = nil
                end
            end

            local targetMat = MaterialMap[state.armsMaterial] or Enum.Material.Neon
            local targetCol = Color3.fromRGB(state.armsColorR, state.armsColorG, state.armsColorB)

            if LocalPlayer.Character then
                for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if isArmPart(p) then
                        applyChamsToPart(p, OrigArmProps, targetMat, targetCol, state.armsTransparency)
                    end
                end
            end
            for _, p in ipairs(Camera:GetDescendants()) do
                if isArmPart(p) then
                    applyChamsToPart(p, OrigArmProps, targetMat, targetCol, state.armsTransparency)
                end
            end
        else
            if CachedShirt and LocalPlayer.Character and CachedShirt.Parent == nil then
                CachedShirt.Parent = LocalPlayer.Character
                CachedShirt = nil
            end
            if next(OrigArmProps) then
                restoreChamsTable(OrigArmProps)
            end
        end

        -- 2. ОРУЖИЕ / ПРЕДМЕТЫ (Weapons)
        if state.weaponEnabled then
            local targetMat = MaterialMap[state.weaponMaterial] or Enum.Material.ForceField
            local targetCol = Color3.fromRGB(state.weaponColorR, state.weaponColorG, state.weaponColorB)

            if LocalPlayer.Character then
                for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if isWeaponPart(p) then
                        applyChamsToPart(p, OrigWeaponProps, targetMat, targetCol, state.weaponTransparency)
                    end
                end
            end
            for _, p in ipairs(Camera:GetDescendants()) do
                if isWeaponPart(p) then
                    applyChamsToPart(p, OrigWeaponProps, targetMat, targetCol, state.weaponTransparency)
                end
            end
        else
            if next(OrigWeaponProps) then
                restoreChamsTable(OrigWeaponProps)
            end
        end
    end)

    local function cleanup()
        pcall(function() descConn:Disconnect() end)
        pcall(function() timeConn:Disconnect() end)
        pcall(function() chamsConn:Disconnect() end)

        if CachedShirt and LocalPlayer.Character then
            CachedShirt.Parent = LocalPlayer.Character
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
