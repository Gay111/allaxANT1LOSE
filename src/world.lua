--!strict
-- [ allaxANT1LOSE ] Master World & Visuals Engine (Fixed Chams, Shaders & Post-Processing)
local World = {}

-- // Сервисы
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Terrain = Workspace:FindFirstChildOfClass("Terrain") or Workspace.Terrain

-- // Оригинальные настройки игры
local OriginalSettings = {
    ClockTime = Lighting.ClockTime,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    ExposureCompensation = Lighting.ExposureCompensation,
    FogColor = Lighting.FogColor,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    Technology = Lighting.Technology,
}

-- // Главная таблица состояния
World.State = {
    -- Освещение
    targetTime = 14,
    lockTimeEnabled = false,
    mapBrightness = Lighting.Brightness,
    exposureCompensation = Lighting.ExposureCompensation,
    forceBrightness = false,

    -- Облака (Clouds)
    cloudsEnabled = false,
    cloudsCover = 0.6,
    cloudsDensity = 0.7,
    cloudsColorR = 255,
    cloudsColorG = 255,
    cloudsColorB = 255,

    -- Чамсы на Руки (Self Arms)
    armsEnabled = false,
    armsMaterial = "NEON",
    armsColorR = 255,
    armsColorG = 255,
    armsColorB = 255,
    armsTransparency = 0,

    -- Чамсы на Оружие (Held Weapon)
    weaponEnabled = false,
    weaponMaterial = "FORCEFIELD",
    weaponColorR = 0,
    weaponColorG = 255,
    weaponColorB = 255,
    weaponTransparency = 0,

    -- Тинт мира и Карта
    worldTintR = 255,
    worldTintG = 255,
    worldTintB = 255,
    lockWorldTint = false,
    mapTransparencyEnabled = false,
    mapTransparencyValue = 0.5,

    -- Bloom
    bloomEnabled = false,
    bloomIntensity = 1.5,
    bloomSize = 28,
    bloomThreshold = 0.4,

    -- Motion Blur
    motionBlurEnabled = false,
    motionBlurMultiplier = 1.0,
    motionBlurMax = 40,

    -- SunRays & DoF
    sunRaysEnabled = false,
    sunRaysIntensity = 0.3,
    sunRaysSpread = 0.8,
    dofEnabled = false,
    dofFarIntensity = 0.85,
    dofNearIntensity = 0.5,
    dofFocusDistance = 15,
    dofInFocusRadius = 15,

    -- Color Correction
    colorCorrectionEnabled = false,
    saturation = 0.35,
    contrast = 0.15,
    brightness = 0,

    -- Погода
    weather = "None",
    weatherDensity = 100,
}

World.Config = World.State

-- // Инстансы эффектов
local Instances = {
    Bloom = nil :: BloomEffect?,
    MotionBlur = nil :: BlurEffect?,
    SunRays = nil :: SunRaysEffect?,
    DoF = nil :: DepthOfFieldEffect?,
    ColorCorrection = nil :: ColorCorrectionEffect?,
    Clouds = nil :: Clouds?,
    WeatherPart = nil :: Part?,
    WeatherEmitter = nil :: ParticleEmitter?,
}

local connections = {}
local lastCameraCFrame = CFrame.new()
local currentBlurSize = 0
local originalMapMaterials = {}
local originalTextures = {} -- Кэш текстур для Chams
local hiddenAppearances = {} -- Скрытые SurfaceAppearance
local isUpdatingMap = false

-- // Безопасное получение/создание эффекта
local function getOrCreateEffect<T>(parent: Instance, className: string, name: string): T
    local found = parent:FindFirstChild(name)
    if not found or not found:IsA(className) then
        found = Instance.new(className)
        found.Name = name
        found.Parent = parent
    end
    return found :: any
end

-- // Пресеты погоды
local WeatherPresets = {
    ["Snow"] = {
        Texture = "rbxassetid://304777684",
        Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0.3) }),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.8, 0.1), NumberSequenceKeypoint.new(1, 1) }),
        Speed = NumberRange.new(10, 18),
        Lifetime = NumberRange.new(3.5, 5.5),
        SpreadAngle = Vector2.new(20, 20),
        Acceleration = Vector3.new(0, -12, 0),
        Rotation = NumberRange.new(-180, 180),
        RotSpeed = NumberRange.new(-40, 40),
        LightEmission = 0.8,
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    },
    ["Rain"] = {
        Texture = "rbxassetid://243660364",
        Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0.6) }),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.7) }),
        Speed = NumberRange.new(55, 80),
        Lifetime = NumberRange.new(1.2, 2.0),
        SpreadAngle = Vector2.new(3, 3),
        Acceleration = Vector3.new(0, -100, 0),
        Rotation = NumberRange.new(0, 0),
        RotSpeed = NumberRange.new(0, 0),
        LightEmission = 0.4,
        Color = ColorSequence.new(Color3.fromRGB(200, 225, 255))
    },
    ["Embers"] = {
        Texture = "rbxassetid://5857851618",
        Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.1) }),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
        Speed = NumberRange.new(6, 14),
        Lifetime = NumberRange.new(2.5, 4.5),
        SpreadAngle = Vector2.new(45, 45),
        Acceleration = Vector3.new(0, 6, 0),
        Rotation = NumberRange.new(-180, 180),
        RotSpeed = NumberRange.new(-100, 100),
        LightEmission = 1,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 180, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 40, 0))
        })
    },
    ["Sakura"] = {
        Texture = "rbxassetid://258128463",
        Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0.4) }),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 0.8) }),
        Speed = NumberRange.new(6, 12),
        Lifetime = NumberRange.new(4, 7),
        SpreadAngle = Vector2.new(30, 30),
        Acceleration = Vector3.new(4, -8, 2),
        Rotation = NumberRange.new(-180, 180),
        RotSpeed = NumberRange.new(-80, 80),
        LightEmission = 0.2,
        Color = ColorSequence.new(Color3.fromRGB(255, 180, 210))
    },
    ["Stars"] = {
        Texture = "rbxassetid://5857892330",
        Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(0.5, 0.7), NumberSequenceKeypoint.new(1, 0.1) }),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }),
        Speed = NumberRange.new(4, 10),
        Lifetime = NumberRange.new(3, 5),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, -2, 0),
        Rotation = NumberRange.new(-180, 180),
        RotSpeed = NumberRange.new(-40, 40),
        LightEmission = 1,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 210, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
        })
    }
}

-- // Обновление Bloom
function World.UpdateBloom()
    if not Instances.Bloom then return end
    Instances.Bloom.Enabled = World.State.bloomEnabled
    Instances.Bloom.Intensity = tonumber(World.State.bloomIntensity) or 1.5
    Instances.Bloom.Size = tonumber(World.State.bloomSize) or 28
    Instances.Bloom.Threshold = tonumber(World.State.bloomThreshold) or 0.4
end

-- // Обновление ColorCorrection & Правильного Тинта (без убийства теней!)
function World.UpdateColorCorrection()
    if not Instances.ColorCorrection then return end
    
    local r = (tonumber(World.State.worldTintR) or 255) / 255
    local g = (tonumber(World.State.worldTintG) or 255) / 255
    local b = (tonumber(World.State.worldTintB) or 255) / 255
    local tintColor = Color3.new(r, g, b)

    Instances.ColorCorrection.Enabled = World.State.colorCorrectionEnabled or (r ~= 1 or g ~= 1 or b ~= 1)
    Instances.ColorCorrection.Saturation = tonumber(World.State.saturation) or 0.35
    Instances.ColorCorrection.Contrast = tonumber(World.State.contrast) or 0.15
    Instances.ColorCorrection.Brightness = tonumber(World.State.brightness) or 0
    Instances.ColorCorrection.TintColor = tintColor
end

-- // Обновление SunRays & DoF
function World.UpdateCinematics()
    if Instances.SunRays then
        Instances.SunRays.Enabled = World.State.sunRaysEnabled
        Instances.SunRays.Intensity = tonumber(World.State.sunRaysIntensity) or 0.3
        Instances.SunRays.Spread = tonumber(World.State.sunRaysSpread) or 0.8
    end
    if Instances.DoF then
        Instances.DoF.Enabled = World.State.dofEnabled
        Instances.DoF.FarIntensity = tonumber(World.State.dofFarIntensity) or 0.85
        Instances.DoF.NearIntensity = tonumber(World.State.dofNearIntensity) or 0.5
        Instances.DoF.FocusDistance = tonumber(World.State.dofFocusDistance) or 15
        Instances.DoF.InFocusRadius = tonumber(World.State.dofInFocusRadius) or 15
    end
end

-- // Обновление Облаков (Terrain Clouds)
function World.UpdateClouds()
    local terrain = Workspace:FindFirstChildOfClass("Terrain") or Workspace.Terrain
    if not terrain then return end

    if not Instances.Clouds or Instances.Clouds.Parent ~= terrain then
        Instances.Clouds = terrain:FindFirstChildOfClass("Clouds") or getOrCreateEffect(terrain, "Clouds", "_allax_Clouds")
    end
    
    local clouds = Instances.Clouds
    if not clouds then return end

    clouds.Enabled = World.State.cloudsEnabled
    clouds.Cover = math.clamp(tonumber(World.State.cloudsCover) or 0.6, 0, 1)
    clouds.Density = math.clamp(tonumber(World.State.cloudsDensity) or 0.7, 0, 1)
    clouds.Color = Color3.fromRGB(
        tonumber(World.State.cloudsColorR) or 255,
        tonumber(World.State.cloudsColorG) or 255,
        tonumber(World.State.cloudsColorB) or 255
    )

    -- Если режим освещения старый, обновляем до совместимого с облаками
    if World.State.cloudsEnabled and (Lighting.Technology == Enum.Technology.Compatibility or Lighting.Technology == Enum.Technology.Voxel) then
        pcall(function()
            Lighting.Technology = Enum.Technology.ShadowMap
        end)
    end
end

-- // Обновление Погоды
function World.UpdateWeather()
    local emitter = Instances.WeatherEmitter
    if not emitter then return end

    local currentType = tostring(World.State.weather or "None")
    if currentType == "None" or currentType == "" then
        emitter.Enabled = false
        emitter:Clear()
        return
    end

    local preset = WeatherPresets[currentType]
    if not preset then
        emitter.Enabled = false
        emitter:Clear()
        return
    end

    emitter:Clear()
    emitter.Texture = preset.Texture
    emitter.Size = preset.Size
    emitter.Transparency = preset.Transparency
    emitter.Speed = preset.Speed
    emitter.Lifetime = preset.Lifetime
    emitter.SpreadAngle = preset.SpreadAngle
    emitter.Acceleration = preset.Acceleration
    emitter.Rotation = preset.Rotation
    emitter.RotSpeed = preset.RotSpeed
    emitter.LightEmission = preset.LightEmission
    emitter.Color = preset.Color
    emitter.EmissionDirection = Enum.NormalId.Bottom
    emitter.Rate = tonumber(World.State.weatherDensity) or 100
    emitter.Enabled = true
end

-- // Функция мягкого изменения цвета мира (без выбеливания теней)
function World.UpdateWorldColor()
    World.UpdateColorCorrection()
end

-- // Универсальный Fog Controller (Atmosphere + Legacy)
function World.SetFog(densityPercent: number)
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        atmosphere.Density = math.clamp((densityPercent / 100) * 0.8, 0, 1)
        atmosphere.Haze = math.clamp((densityPercent / 100) * 3.0, 0, 10)
    end
    Lighting.FogStart = 0
    Lighting.FogEnd = math.clamp(5000 - (densityPercent * 48), 20, 10000)
end

function World.ClearFog()
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        atmosphere.Density = 0
        atmosphere.Haze = 0
    end
    Lighting.FogStart = 0
    Lighting.FogEnd = 10000000
end

-- // Оптимизированная прозрачность карты
function World.UpdateAllMapParts()
    if isUpdatingMap then return end
    isUpdatingMap = true

    task.spawn(function()
        local cam = Workspace.CurrentCamera
        local targetTransparency = tonumber(World.State.mapTransparencyValue) or 0.5
        local isEnabled = World.State.mapTransparencyEnabled

        for _, part in ipairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") 
               and (not cam or not part:IsDescendantOf(cam)) 
               and (not LocalPlayer.Character or not part:IsDescendantOf(LocalPlayer.Character)) 
               and not Players:GetPlayerFromCharacter(part.Parent) then
               
                if isEnabled then
                    if not originalMapMaterials[part] then
                        originalMapMaterials[part] = {
                            Transparency = part.Transparency,
                            Material = part.Material
                        }
                    end
                    part.Transparency = targetTransparency
                elseif originalMapMaterials[part] then
                    part.Transparency = originalMapMaterials[part].Transparency
                    part.Material = originalMapMaterials[part].Material
                end
            end
        end
        isUpdatingMap = false
    end)
end

-- // ВСЕЯДНЫЙ ДЕТЕКТОР И ЧАМСЫ ДЛЯ РУК И ОРУЖИЯ (С подавлением текстур)
local function applyChamsToObject(part: BasePart, isArm: boolean)
    local isEnabled = isArm and World.State.armsEnabled or (not isArm and World.State.weaponEnabled)
    local targetMatName = isArm and World.State.armsMaterial or World.State.weaponMaterial
    local targetMat = Enum.Material[targetMatName] or Enum.Material.Neon
    local targetColor = isArm 
        and Color3.fromRGB(World.State.armsColorR, World.State.armsColorG, World.State.armsColorB)
        or Color3.fromRGB(World.State.weaponColorR, World.State.weaponColorG, World.State.weaponColorB)
    local targetTrans = tonumber(isArm and World.State.armsTransparency or World.State.weaponTransparency) or 0

    -- 1. Скрываем SurfaceAppearance, которые перебивают цвет
    for _, sa in ipairs(part:GetChildren()) do
        if sa:IsA("SurfaceAppearance") then
            if isEnabled then
                if not hiddenAppearances[sa] then
                    hiddenAppearances[sa] = sa.Parent
                    sa.Parent = nil
                end
            end
        end
    end

    -- 2. Скрываем текстуру у MeshPart / SpecialMesh для чистого свечения
    if part:IsA("MeshPart") then
        if isEnabled then
            if part.TextureID ~= "" then
                originalTextures[part] = part.TextureID
                part.TextureID = ""
            end
        elseif originalTextures[part] then
            part.TextureID = originalTextures[part]
            originalTextures[part] = nil
        end
    end

    local specialMesh = part:FindFirstChildOfClass("SpecialMesh")
    if specialMesh then
        if isEnabled then
            if specialMesh.TextureId ~= "" then
                originalTextures[specialMesh] = specialMesh.TextureId
                specialMesh.TextureId = ""
            end
        elseif originalTextures[specialMesh] then
            specialMesh.TextureId = originalTextures[specialMesh]
            originalTextures[specialMesh] = nil
        end
    end

    -- 3. Применяем материал и цвет
    if isEnabled then
        part.Material = targetMat
        part.Color = targetColor
        part.Transparency = targetTrans
    end
end

-- // Инициализация
function World.Init()
    Instances.Bloom = getOrCreateEffect(Lighting, "BloomEffect", "_allax_Bloom")
    Instances.MotionBlur = getOrCreateEffect(Lighting, "BlurEffect", "_allax_MotionBlur")
    Instances.SunRays = getOrCreateEffect(Lighting, "SunRaysEffect", "_allax_SunRays")
    Instances.DoF = getOrCreateEffect(Lighting, "DepthOfFieldEffect", "_allax_DoF")
    Instances.ColorCorrection = getOrCreateEffect(Lighting, "ColorCorrectionEffect", "_allax_ColorCorrection")
    
    local terrain = Workspace:FindFirstChildOfClass("Terrain") or Workspace.Terrain
    Instances.Clouds = getOrCreateEffect(terrain, "Clouds", "_allax_Clouds")

    local cam = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")
    lastCameraCFrame = cam and cam.CFrame or CFrame.new()

    -- Контейнер погоды над камерой
    local weatherPart = Instance.new("Part")
    weatherPart.Name = "_allax_WeatherPart"
    weatherPart.Transparency = 1
    weatherPart.CanCollide = false
    weatherPart.CanTouch = false
    weatherPart.CanQuery = false
    weatherPart.CastShadow = false
    weatherPart.Anchored = true
    weatherPart.Size = Vector3.new(180, 2, 180)
    weatherPart.Parent = Workspace

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "WeatherEmitter"
    emitter.EmissionDirection = Enum.NormalId.Bottom
    emitter.Enabled = false
    emitter.Parent = weatherPart

    Instances.WeatherPart = weatherPart
    Instances.WeatherEmitter = emitter

    -- Главный RenderStepped цикл
    table.insert(connections, RunService.RenderStepped:Connect(function(dt: number)
        local curCam = Workspace.CurrentCamera
        if not curCam then return end

        -- Позиция осадков
        if Instances.WeatherPart then
            Instances.WeatherPart.CFrame = CFrame.new(curCam.CFrame.Position + Vector3.new(0, 28, 0))
        end

        -- Удержание времени
        if World.State.lockTimeEnabled then
            Lighting.ClockTime = tonumber(World.State.targetTime) or 14
        end

        -- Универсальная яркость (Future + ShadowMap support)
        if World.State.forceBrightness then
            local bright = tonumber(World.State.mapBrightness) or 2
            Lighting.Brightness = bright
            Lighting.ExposureCompensation = tonumber(World.State.exposureCompensation) or 0
        end

        -- Динамический Motion Blur
        if Instances.MotionBlur then
            if not World.State.motionBlurEnabled then
                Instances.MotionBlur.Size = 0
                Instances.MotionBlur.Enabled = false
            else
                Instances.MotionBlur.Enabled = true
                local currentCFrame = curCam.CFrame
                local lookDelta = (currentCFrame.LookVector - lastCameraCFrame.LookVector).Magnitude
                local rotDelta = math.deg(lookDelta)

                local mult = tonumber(World.State.motionBlurMultiplier) or 1.0
                local maxBlur = tonumber(World.State.motionBlurMax) or 40
                local targetBlur = math.clamp(rotDelta * (mult * 18), 0, maxBlur)

                currentBlurSize = currentBlurSize + (targetBlur - currentBlurSize) * math.clamp(dt * 20, 0, 1)
                Instances.MotionBlur.Size = math.clamp(math.round(currentBlurSize), 0, 56)
                lastCameraCFrame = currentCFrame
            end
        end
    end))

    -- Умный Heartbeat цикл для поиска и покраски Viewmodel / Рук / Оружия
    table.insert(connections, RunService.Heartbeat:Connect(function()
        if not World.State.armsEnabled and not World.State.weaponEnabled then return end

        local curCam = Workspace.CurrentCamera
        local targets = {}

        -- 1. Сканируем всё, что находится внутри камеры (Viewmodels)
        if curCam then
            for _, child in ipairs(curCam:GetChildren()) do
                if child:IsA("Model") or child:IsA("BasePart") or child:IsA("Folder") then
                    table.insert(targets, child)
                end
            end
        end

        -- 2. Сканируем персонажа игрока
        if LocalPlayer and LocalPlayer.Character then
            table.insert(targets, LocalPlayer.Character)
        end

        -- 3. Сканируем папки Viewmodels в Workspace
        for _, name in ipairs({"Viewmodel", "ViewModel", "Arms", "Weapons", "Ignore", "CameraModel"}) do
            local found = Workspace:FindFirstChild(name)
            if found then table.insert(targets, found) end
        end

        -- Обрабатываем части
        for _, root in ipairs(targets) do
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("BasePart") and not obj:IsDescendantOf(curCam == root and nil or Workspace:FindFirstChild("Terrain")) then
                    local name = obj.Name:lower()
                    local parentName = (obj.Parent and obj.Parent.Name or ""):lower()
                    
                    local isArm = name:find("arm") or name:find("hand") or name:find("glove") or name:find("sleeve") 
                               or parentName:find("arm") or parentName:find("hand") or parentName:find("glove")
                    
                    local isWeapon = not isArm and (
                        name:find("gun") or name:find("weapon") or name:find("knife") or name:find("mag") 
                        or name:find("barrel") or name:find("handle") or name:find("sight") or name:find("scope")
                        or parentName:find("weapon") or parentName:find("gun") or obj.Parent:IsA("Tool")
                    )

                    -- Если это вьюмодель в камере, а имя неопределенное:
                    if not isArm and not isWeapon and curCam and obj:IsDescendantOf(curCam) then
                        isWeapon = true
                    end

                    if isArm and World.State.armsEnabled then
                        pcall(applyChamsToObject, obj, true)
                    elseif isWeapon and World.State.weaponEnabled then
                        pcall(applyChamsToObject, obj, false)
                    end
                end
            end
        end
    end))

    World.UpdateBloom()
    World.UpdateColorCorrection()
    World.UpdateCinematics()
    World.UpdateWeather()
    World.UpdateClouds()

    return World
end

-- // Полная очистка
function World.Cleanup()
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)

    for _, inst in pairs(Instances) do
        if inst and inst.Parent then
            pcall(function() inst:Destroy() end)
        end
    end

    -- Восстановление текстур
    for obj, tex in pairs(originalTextures) do
        pcall(function()
            if obj:IsA("MeshPart") then
                obj.TextureID = tex
            elseif obj:IsA("SpecialMesh") then
                obj.TextureId = tex
            end
        end)
    end
    table.clear(originalTextures)

    -- Восстановление SurfaceAppearance
    for sa, parent in pairs(hiddenAppearances) do
        pcall(function() sa.Parent = parent end)
    end
    table.clear(hiddenAppearances)

    -- Восстановление карты
    for part, data in pairs(originalMapMaterials) do
        if part and part.Parent then
            pcall(function()
                part.Transparency = data.Transparency
                part.Material = data.Material
            end)
        end
    end

    -- Восстановление Lighting
    for prop, val in pairs(OriginalSettings) do
        pcall(function()
            (Lighting :: any)[prop] = val
        end)
    end
end

World.Destroy = World.Cleanup

return World
