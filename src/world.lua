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

-- Имена частей тела персонажа (R6 / R15)
local ArmLimbNames = {
    ["Left Arm"] = true, ["Right Arm"] = true,
    ["LeftHand"] = true, ["RightHand"] = true,
    ["LeftLowerArm"] = true, ["RightLowerArm"] = true,
    ["LeftUpperArm"] = true, ["RightUpperArm"] = true,
}

-- Ключевые слова для распознавания элементов рук / перчаток / рукавов
local ArmKeywords = {
    "arm", "hand", "glove", "sleeve", "finger", "thumb", "index",
    "middle", "ring", "pinky", "wrist", "palm", "forearm", "shoulder", "elbow"
}

-- Ключевые слова для распознавания оружия
local WeaponKeywords = {
    "gun", "weapon", "knife", "sword", "rifle", "pistol", "shotgun", "sniper",
    "smg", "blade", "barrel", "receiver", "mag", "magazine", "scope", "sight",
    "silencer", "suppressor", "grip", "stock", "bullet", "handle", "trigger"
}

-- Черный список вспомогательных и технических деталей
local IgnoreKeywords = {
    "root", "hitbox", "bounding", "origin", "camera", "aim", "offset",
    "spring", "node", "point", "flash", "muzzle", "particle", "emitter",
    "sound", "collider", "attachment", "marker", "light"
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

        -- Self Chams (Оружие)
        weaponEnabled = false,
        weaponMaterial = "FORCEFIELD",
        weaponColorR = 0,
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

    -- Проверка на техническую или игнорируемую деталь
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

    -- Распознавание деталей рук
    local function isArmPart(part)
        if isIgnoredPart(part) then return false end

        -- 1. Руки персонажа от 3-го лица
        if LocalPlayer.Character and part:IsDescendantOf(LocalPlayer.Character) then
            if part:FindFirstAncestorOfClass("Tool") then return false end
            if ArmLimbNames[part.Name] then return true end

            local pName = part.Name:lower()
            for _, kw in ipairs(ArmKeywords) do
                if pName:find(kw) then return true end
            end
        end

        -- 2. Вьюмодель в Camera (1-е лицо)
        if part:IsDescendantOf(Camera) then
            -- Если деталь находится внутри Tool или модели оружия — это НЕ рука
            if part:FindFirstAncestorOfClass("Tool") then return false end

            local pName = part.Name:lower()
            for _, kw in ipairs(ArmKeywords) do
                if pName:find(kw) then return true end
            end

            -- Проверяем непосредственного родителя (если это конкретная подмодель руки)
            local pModel = part.Parent
            if pModel and pModel:IsA("Model") and pModel ~= Camera then
                local mName = pModel.Name:lower()
                for _, kw in ipairs(ArmKeywords) do
                    if mName:find(kw) and not mName:find("weapon") and not mName:find("gun") then
                        return true
                    end
                end
            end
        end

        return false
    end

    -- Распознавание деталей оружия
    local function isWeaponPart(part)
        if isIgnoredPart(part) then return false end
        if isArmPart(part) then return false end

        -- 1. Оружие в персонаже
        if LocalPlayer.Character and part:IsDescendantOf(LocalPlayer.Character) then
            if part:FindFirstAncestorOfClass("Tool") then
                return true
            end
        end

        -- 2. Оружие во вьюмодели Camera
        if part:IsDescendantOf(Camera) then
            if part:FindFirstAncestorOfClass("Tool") then
                return true
            end

            local pName = part.Name:lower()
            for _, kw in ipairs(WeaponKeywords) do
                if pName:find(kw) then return true end
            end

            local pModel = part.Parent
            if pModel and pModel:IsA("Model") and pModel ~= Camera then
                local mName = pModel.Name:lower()
                for _, kw in ipairs(WeaponKeywords) do
                    if mName:find(kw) then return true end
                end
            end

            -- Fallback: любая видимая деталь в камере, не являющаяся рукой
            return true
        end

        return false
    end

    -- Безопасное применение материала
    local function applyChamsToPart(part, storeTable, otherStoreTable, targetMat, targetCol, targetAlpha)
        if not part or not part.Parent then return end
        
        -- Если деталь уже обрабатывается другой категорией чамсов — пропускаем коллизию
        if otherStoreTable and otherStoreTable[part] then return end

        if not storeTable[part] then
            -- Игнорируем невидимые коллизии
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
                SpecialMesh = sMesh,
                SpecialMeshTexture = sMesh and sMesh.TextureId or nil,
                SurfaceAppearance = sApp,
                Decals = decals
            }
        end

        -- Прячем SurfaceAppearance и текстуры декалей
        local stored = storeTable[part]
        if stored.SurfaceAppearance and stored.SurfaceAppearance.Parent then
            stored.SurfaceAppearance.Parent = nil
        end
        if stored.SpecialMesh and stored.SpecialMeshTexture and stored.SpecialMesh.TextureId ~= "" then
            pcall(function() stored.SpecialMesh.TextureId = "" end)
        end
        for _, dData in ipairs(stored.Decals) do
            if dData.Instance and dData.Instance.Parent then
                dData.Instance.Transparency = 1
            end
        end

        -- Применяем цвет и материал
        part.Material = targetMat
        part.Color = targetCol
        part.Transparency = targetAlpha
    end

    -- Восстановление оригинального вида
    local function restoreChamsTable(storeTable)
        for part, props in pairs(storeTable) do
            if part and part.Parent then
                pcall(function()
                    part.Material = props.Material
                    part.Color = props.Color
                    part.Transparency = props.Transparency
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
                end)
            end
        end
        table.clear(storeTable)
    end

    -- Главный цикл обновления Chams
    local chamsConn = RunService.RenderStepped:Connect(function()
        -- 1. РУКИ (Arms)
        if state.armsEnabled then
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
                        applyChamsToPart(p, OrigArmProps, OrigWeaponProps, targetMat, targetCol, state.armsTransparency)
                    end
                end
            end
            for _, p in ipairs(Camera:GetDescendants()) do
                if isArmPart(p) then
                    applyChamsToPart(p, OrigArmProps, OrigWeaponProps, targetMat, targetCol, state.armsTransparency)
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

        -- 2. ОРУЖИЕ (Weapons)
        if state.weaponEnabled then
            local targetMat = MaterialMap[state.weaponMaterial] or Enum.Material.ForceField
            local targetCol = Color3.fromRGB(state.weaponColorR, state.weaponColorG, state.weaponColorB)

            if LocalPlayer.Character then
                for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if isWeaponPart(p) then
                        applyChamsToPart(p, OrigWeaponProps, OrigArmProps, targetMat, targetCol, state.weaponTransparency)
                    end
                end
            end
            for _, p in ipairs(Camera:GetDescendants()) do
                if isWeaponPart(p) then
                    applyChamsToPart(p, OrigWeaponProps, OrigArmProps, targetMat, targetCol, state.weaponTransparency)
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
