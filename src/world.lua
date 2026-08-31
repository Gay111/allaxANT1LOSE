--!strict
-- [ allaxANT1LOSE ] Aggressive World & Visuals Engine
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
}

-- // Главное состояние модуля
local StateData = {
    -- Освещение
    targettime = 14,
    locktimeenabled = false,
    forcemapbrightness = false,
    mapbrightness = 2,
    exposurecompensation = 0,

    -- Облака (Clouds)
    cloudsenabled = false,
    cloudscover = 0.6,
    cloudsdensity = 0.7,
    cloudscolorr = 255,
    cloudscolorg = 255,
    cloudscolorb = 255,

    -- Чамсы на Руки и Оружие
    armsenabled = false,
    armsmaterial = "NEON",
    armscolorr = 255,
    armscolorg = 255,
    armscolorb = 255,
    armstransparency = 0,

    weaponenabled = false,
    weaponmaterial = "FORCEFIELD",
    weaponcolorr = 0,
    weaponcolorg = 255,
    weaponcolorb = 255,
    weapontransparency = 0,

    -- Тинт мира и прозрачность
    worldtintr = 255,
    worldtintg = 255,
    worldtintb = 255,
    lockworldtint = false,
    maptransparencyenabled = false,
    maptransparencyvalue = 0.5,

    -- Bloom
    bloomenabled = false,
    bloomintensity = 1.8,
    bloomsize = 32,
    bloomthreshold = 0.2,

    -- Motion Blur
    motionblurenabled = false,
    motionblurmultiplier = 1.2,
    motionblurmax = 40,

    -- SunRays & DoF
    sunraysenabled = false,
    sunraysintensity = 0.35,
    sunraysspread = 0.8,
    dofenabled = false,
    doffarintensity = 0.75,
    doffocusdistance = 20,
    dofinfocusradius = 25,

    -- Color Correction
    colorcorrectionenabled = false,
    saturation = 0.4,
    contrast = 0.2,
    brightness = 0,

    -- Погода
    weather = "None",
    weatherdensity = 120,
}

-- Универсальный регистронезависимый прокси
local StateProxy = setmetatable({}, {
    __index = function(_, key)
        return StateData[string.lower(tostring(key))]
    end,
    __newindex = function(_, key, val)
        StateData[string.lower(tostring(key))] = val
    end
})

World.State = StateProxy
World.Config = StateProxy

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
local isEnforcing = false

-- // Агрессивное получение / создание эффекта
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
        Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0.35) }),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.8, 0.1), NumberSequenceKeypoint.new(1, 1) }),
        Speed = NumberRange.new(8, 16),
        Lifetime = NumberRange.new(4, 6),
        SpreadAngle = Vector2.new(20, 20),
        Acceleration = Vector3.new(0, -10, 0),
        Rotation = NumberRange.new(-180, 180),
        RotSpeed = NumberRange.new(-40, 40),
        LightEmission = 0.8,
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    },
    ["Rain"] = {
        Texture = "rbxassetid://243660364",
        Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0.6) }),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.7) }),
        Speed = NumberRange.new(50, 75),
        Lifetime = NumberRange.new(1.5, 2.5),
        SpreadAngle = Vector2.new(3, 3),
        Acceleration = Vector3.new(0, -90, 0),
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
        Lifetime = NumberRange.new(3, 5),
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
        Lifetime = NumberRange.new(3, 6),
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

-- // Подавление дефолтных эффектов игры, конфликтующих с нашими
local function suppressConflictingGameEffects()
    for _, child in ipairs(Lighting:GetChildren()) do
        if not child.Name:find("^_allax_") then
            if child:IsA("BloomEffect") and StateData.bloomenabled then
                child.Enabled = false
            elseif child:IsA("ColorCorrectionEffect") and StateData.colorcorrectionenabled then
                child.Enabled = false
            end
        end
    end
end

-- // Обновление Облаков
function World.UpdateClouds()
    if not Instances.Clouds then
        Instances.Clouds = getOrCreateEffect(Terrain, "Clouds", "_allax_Clouds")
    end
    local clouds = Instances.Clouds
    if not clouds then return end

    clouds.Enabled = StateData.cloudsenabled
    clouds.Cover = tonumber(StateData.cloudscover) or 0.6
    clouds.Density = tonumber(StateData.cloudsdensity) or 0.7
    clouds.Color = Color3.fromRGB(
        tonumber(StateData.cloudscolorr) or 255,
        tonumber(StateData.cloudscolorg) or 255,
        tonumber(StateData.cloudscolorb) or 255
    )
end

-- // Обновление Bloom
function World.UpdateBloom()
    if not Instances.Bloom then
        Instances.Bloom = getOrCreateEffect(Lighting, "BloomEffect", "_allax_Bloom")
    end
    Instances.Bloom.Enabled = StateData.bloomenabled
    Instances.Bloom.Intensity = tonumber(StateData.bloomintensity) or 1.8
    Instances.Bloom.Size = tonumber(StateData.bloomsize) or 32
    Instances.Bloom.Threshold = tonumber(StateData.bloomthreshold) or 0.2
    suppressConflictingGameEffects()
end

-- // Обновление ColorCorrection
function World.UpdateColorCorrection()
    if not Instances.ColorCorrection then
        Instances.ColorCorrection = getOrCreateEffect(Lighting, "ColorCorrectionEffect", "_allax_ColorCorrection")
    end
    Instances.ColorCorrection.Enabled = StateData.colorcorrectionenabled
    Instances.ColorCorrection.Saturation = tonumber(StateData.saturation) or 0.4
    Instances.ColorCorrection.Contrast = tonumber(StateData.contrast) or 0.2
    Instances.ColorCorrection.Brightness = tonumber(StateData.brightness) or 0
    suppressConflictingGameEffects()
end

-- // Обновление SunRays & DoF
function World.UpdateCinematics()
    if not Instances.SunRays then
        Instances.SunRays = getOrCreateEffect(Lighting, "SunRaysEffect", "_allax_SunRays")
    end
    if not Instances.DoF then
        Instances.DoF = getOrCreateEffect(Lighting, "DepthOfFieldEffect", "_allax_DoF")
    end

    Instances.SunRays.Enabled = StateData.sunraysenabled
    Instances.SunRays.Intensity = tonumber(StateData.sunraysintensity) or 0.35
    Instances.SunRays.Spread = tonumber(StateData.sunraysspread) or 0.8

    Instances.DoF.Enabled = StateData.dofenabled
    Instances.DoF.FarIntensity = tonumber(StateData.doffarintensity) or 0.75
    Instances.DoF.FocusDistance = tonumber(StateData.doffocusdistance) or 20
    Instances.DoF.InFocusRadius = tonumber(StateData.dofinfocusradius) or 25
end

-- // Обновление Погоды
function World.UpdateWeather()
    local emitter = Instances.WeatherEmitter
    if not emitter then return end

    local currentType = tostring(StateData.weather or "None"):lower()
    if currentType == "none" or currentType == "" then
        emitter.Enabled = false
        return
    end

    local preset = nil
    for name, p in pairs(WeatherPresets) do
        if name:lower() == currentType then
            preset = p
            break
        end
    end

    if not preset then
        emitter.Enabled = false
        return
    end

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
    emitter.Rate = tonumber(StateData.weatherdensity) or 120
    emitter.Enabled = true
end

-- // Цвет мира (World Tint)
function World.UpdateWorldColor()
    local r = (tonumber(StateData.worldtintr) or 255) / 255
    local g = (tonumber(StateData.worldtintg) or 255) / 255
    local b = (tonumber(StateData.worldtintb) or 255) / 255
    local col = Color3.new(r, g, b)

    isEnforcing = true
    Lighting.Ambient = col
    Lighting.OutdoorAmbient = col
    isEnforcing = false
end

-- // Прозрачность карты
function World.UpdateAllMapParts()
    local cam = Workspace.CurrentCamera
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and (not cam or not part:IsDescendantOf(cam)) and (not LocalPlayer.Character or not part:IsDescendantOf(LocalPlayer.Character)) and not Players:GetPlayerFromCharacter(part.Parent) then
            if StateData.maptransparencyenabled then
                if not originalMapMaterials[part] then
                    originalMapMaterials[part] = {
                        Transparency = part.Transparency,
                        Material = part.Material
                    }
                end
                part.Transparency = tonumber(StateData.maptransparencyvalue) or 0.5
            elseif originalMapMaterials[part] then
                part.Transparency = originalMapMaterials[part].Transparency
                part.Material = originalMapMaterials[part].Material
            end
        end
    end
end

-- // Инициализация модуля с агрессивной защитой
function World.Init()
    Instances.Bloom = getOrCreateEffect(Lighting, "BloomEffect", "_allax_Bloom")
    Instances.MotionBlur = getOrCreateEffect(Lighting, "BlurEffect", "_allax_MotionBlur")
    Instances.SunRays = getOrCreateEffect(Lighting, "SunRaysEffect", "_allax_SunRays")
    Instances.DoF = getOrCreateEffect(Lighting, "DepthOfFieldEffect", "_allax_DoF")
    Instances.ColorCorrection = getOrCreateEffect(Lighting, "ColorCorrectionEffect", "_allax_ColorCorrection")
    Instances.Clouds = getOrCreateEffect(Terrain, "Clouds", "_allax_Clouds")

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

    -- ========================================================================
    -- // АГРЕССИВНЫЙ WATCHDOG (Восстановление удалённых игрой эффектов)
    -- ========================================================================
    table.insert(connections, Lighting.ChildRemoved:Connect(function(child)
        if child.Name:find("^_allax_") then
            task.defer(function()
                World.UpdateBloom()
                World.UpdateColorCorrection()
                World.UpdateCinematics()
                if child.Name == "_allax_MotionBlur" then
                    Instances.MotionBlur = getOrCreateEffect(Lighting, "BlurEffect", "_allax_MotionBlur")
                end
            end)
        end
    end))

    table.insert(connections, Terrain.ChildRemoved:Connect(function(child)
        if child.Name == "_allax_Clouds" then
            task.defer(function()
                World.UpdateClouds()
            end)
        end
    end))

    -- ========================================================================
    -- // АГРЕССИВНЫЙ FORCE-LOCK НА СВОЙСТВА ОСВЕЩЕНИЯ (Мгновенный возврат)
    -- ========================================================================
    table.insert(connections, Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
        if StateData.locktimeenabled and not isEnforcing then
            isEnforcing = true
            Lighting.ClockTime = tonumber(StateData.targettime) or 14
            isEnforcing = false
        end
    end))

    table.insert(connections, Lighting:GetPropertyChangedSignal("Ambient"):Connect(function()
        if StateData.lockworldtint and not isEnforcing then
            World.UpdateWorldColor()
        end
    end))

    -- ========================================================================
    -- // RenderStepped & Heartbeat Enforcement
    -- ========================================================================
    table.insert(connections, RunService.RenderStepped:Connect(function(dt: number)
        local curCam = Workspace.CurrentCamera
        if not curCam then return end

        -- Позиция осадков строго над головой
        if Instances.WeatherPart then
            Instances.WeatherPart.CFrame = CFrame.new(curCam.CFrame.Position + Vector3.new(0, 28, 0))
        end

        -- Форсирование времени каждый кадр
        if StateData.locktimeenabled then
            isEnforcing = true
            Lighting.ClockTime = tonumber(StateData.targettime) or 14
            isEnforcing = false
        end

        -- Форсирование яркости
        if StateData.forcemapbrightness then
            Lighting.Brightness = tonumber(StateData.mapbrightness) or 2
            Lighting.ExposureCompensation = tonumber(StateData.exposurecompensation) or 0
        end

        -- Динамический Motion Blur
        if Instances.MotionBlur then
            if not StateData.motionblurenabled then
                Instances.MotionBlur.Size = 0
                Instances.MotionBlur.Enabled = false
            else
                Instances.MotionBlur.Enabled = true
                local currentCFrame = curCam.CFrame
                local lookDelta = (currentCFrame.LookVector - lastCameraCFrame.LookVector).Magnitude
                local rotDelta = math.deg(lookDelta)

                local mult = tonumber(StateData.motionblurmultiplier) or 1.2
                local maxBlur = tonumber(StateData.motionblurmax) or 40
                local targetBlur = math.clamp(rotDelta * (mult * 20), 0, maxBlur)

                currentBlurSize = currentBlurSize + (targetBlur - currentBlurSize) * math.clamp(dt * 20, 0, 1)
                Instances.MotionBlur.Size = math.clamp(math.round(currentBlurSize), 0, 56)
                lastCameraCFrame = currentCFrame
            end
        end
    end))

    -- Постоянное поддержание материалов Chams
    table.insert(connections, RunService.Heartbeat:Connect(function()
        local curCam = Workspace.CurrentCamera
        if not curCam then return end

        for _, obj in ipairs(curCam:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name = obj.Name:lower()
                local isArm = name:find("arm") or name:find("hand")
                local isWeapon = not isArm and not name:find("humanoid")

                if isArm and StateData.armsenabled then
                    pcall(function()
                        obj.Material = Enum.Material[StateData.armsmaterial] or Enum.Material.Neon
                        obj.Color = Color3.fromRGB(StateData.armscolorr, StateData.armscolorg, StateData.armscolorb)
                        obj.Transparency = tonumber(StateData.armstransparency) or 0
                    end)
                elseif isWeapon and StateData.weaponenabled then
                    pcall(function()
                        obj.Material = Enum.Material[StateData.weaponmaterial] or Enum.Material.ForceField
                        obj.Color = Color3.fromRGB(StateData.weaponcolorr, StateData.weaponcolorg, StateData.weaponcolorb)
                        obj.Transparency = tonumber(StateData.weapontransparency) or 0
                    end)
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

-- // Очистка
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

    for part, data in pairs(originalMapMaterials) do
        if part and part.Parent then
            pcall(function()
                part.Transparency = data.Transparency
                part.Material = data.Material
            end)
        end
    end

    for prop, val in pairs(OriginalSettings) do
        pcall(function()
            (Lighting :: any)[prop] = val
        end)
    end
end

World.Destroy = World.Cleanup

return World
