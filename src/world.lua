--!strict
-- [ allaxANT1LOSE ] World & Visual Effects Module
local World = {}

-- // Сервисы
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")

-- // Таблица состояния и оригинальных параметров игры
local OriginalLighting = {
    ClockTime = Lighting.ClockTime,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    FogColor = Lighting.FogColor,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
}

World.Config = {
    -- Bloom
    BloomEnabled = false,
    BloomIntensity = 1.25,
    BloomSize = 24,
    BloomThreshold = 0.8,

    -- Motion Blur
    MotionBlurEnabled = false,
    MotionBlurMultiplier = 0.6,
    MotionBlurMax = 35,

    -- SunRays & DoF
    SunRaysEnabled = false,
    SunRaysIntensity = 0.25,
    SunRaysSpread = 0.7,
    
    DoFEnabled = false,
    DoFFarIntensity = 0.5,
    DoFFocusDistance = 15,
    DoFInFocusRadius = 20,

    -- Color Correction
    ColorCorrectionEnabled = false,
    Saturation = 0.3,
    Contrast = 0.15,
    Brightness = 0,
    TintColor = Color3.fromRGB(255, 255, 255),

    -- Weather Particles
    Weather = "None", -- "Snow", "Rain", "Embers", "Sakura", "Stars", "None"
    WeatherDensity = 100, -- Rate партиклов
}

-- // Инстансы эффектов (создаются в Lighting)
local Instances = {
    Bloom = nil :: BloomEffect?,
    MotionBlur = nil :: BlurEffect?,
    SunRays = nil :: SunRaysEffect?,
    DoF = nil :: DepthOfFieldEffect?,
    ColorCorrection = nil :: ColorCorrectionEffect?,
    WeatherPart = nil :: Part?,
    WeatherEmitter = nil :: ParticleEmitter?,
}

-- // Внутренние переменные Motion Blur
local lastCameraCFrame = Camera.CFrame
local currentBlurSize = 0
local motionBlurConnection = nil
local weatherConnection = nil

-- // Создание / Получение эффектов в Lighting
local function getOrCreateEffect<T>(className: string, name: string): T
    local found = Lighting:FindFirstChild(name)
    if not found or not found:IsA(className) then
        found = Instance.new(className)
        found.Name = name
        found.Parent = Lighting
    end
    return found :: any
end

-- // Инициализация эффектов
function World.Init()
    Instances.Bloom = getOrCreateEffect("BloomEffect", "_allax_Bloom")
    Instances.MotionBlur = getOrCreateEffect("BlurEffect", "_allax_MotionBlur")
    Instances.SunRays = getOrCreateEffect("SunRaysEffect", "_allax_SunRays")
    Instances.DoF = getOrCreateEffect("DepthOfFieldEffect", "_allax_DoF")
    Instances.ColorCorrection = getOrCreateEffect("ColorCorrectionEffect", "_allax_ColorCorrection")

    -- Создание контейнера под партиклы
    local weatherPart = Instance.new("Part")
    weatherPart.Name = "_allax_WeatherEmitter"
    weatherPart.Transparency = 1
    weatherPart.CanCollide = false
    weatherPart.CanTouch = false
    weatherPart.CanQuery = false
    weatherPart.CastShadow = false
    weatherPart.Anchored = true
    weatherPart.Size = Vector3.new(120, 1, 120)
    weatherPart.Parent = Workspace

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "WeatherParticle"
    emitter.Enabled = false
    emitter.Parent = weatherPart

    Instances.WeatherPart = weatherPart
    Instances.WeatherEmitter = emitter

    -- Loop для следования за камерой
    weatherConnection = RunService.RenderStepped:Connect(function()
        if Instances.WeatherPart and Camera then
            Instances.WeatherPart.CFrame = CFrame.new(Camera.CFrame.Position + Vector3.new(0, 35, 0))
        end
    end)

    World.ApplyAll()
    World.StartMotionBlurLoop()
end

-- // Обновление Bloom
function World.UpdateBloom()
    if not Instances.Bloom then return end
    Instances.Bloom.Enabled = World.Config.BloomEnabled
    Instances.Bloom.Intensity = World.Config.BloomIntensity
    Instances.Bloom.Size = World.Config.BloomSize
    Instances.Bloom.Threshold = World.Config.BloomThreshold
end

-- // Обновление ColorCorrection
function World.UpdateColorCorrection()
    if not Instances.ColorCorrection then return end
    Instances.ColorCorrection.Enabled = World.Config.ColorCorrectionEnabled
    Instances.ColorCorrection.Saturation = World.Config.Saturation
    Instances.ColorCorrection.Contrast = World.Config.Contrast
    Instances.ColorCorrection.Brightness = World.Config.Brightness
    Instances.ColorCorrection.TintColor = World.Config.TintColor
end

-- // Обновление SunRays & DoF
function World.UpdateCinematics()
    if Instances.SunRays then
        Instances.SunRays.Enabled = World.Config.SunRaysEnabled
        Instances.SunRays.Intensity = World.Config.SunRaysIntensity
        Instances.SunRays.Spread = World.Config.SunRaysSpread
    end
    if Instances.DoF then
        Instances.DoF.Enabled = World.Config.DoFEnabled
        Instances.DoF.FarIntensity = World.Config.DoFFarIntensity
        Instances.DoF.FocusDistance = World.Config.DoFFocusDistance
        Instances.DoF.InFocusRadius = World.Config.DoFInFocusRadius
    end
end

-- // Логика Motion Blur
function World.StartMotionBlurLoop()
    if motionBlurConnection then
        motionBlurConnection:Disconnect()
    end

    motionBlurConnection = RunService.RenderStepped:Connect(function(dt: number)
        if not Instances.MotionBlur then return end

        if not World.Config.MotionBlurEnabled then
            Instances.MotionBlur.Size = 0
            Instances.MotionBlur.Enabled = false
            return
        end

        Instances.MotionBlur.Enabled = true

        local currentCam = Workspace.CurrentCamera or Camera
        if not currentCam then return end

        local currentCFrame = currentCam.CFrame
        local lookDelta = (currentCFrame.LookVector - lastCameraCFrame.LookVector).Magnitude
        local rotDelta = math.deg(lookDelta)

        local targetBlur = math.clamp(rotDelta * (World.Config.MotionBlurMultiplier * 10), 0, World.Config.MotionBlurMax)
        currentBlurSize = currentBlurSize + (targetBlur - currentBlurSize) * math.clamp(dt * 15, 0, 1)

        Instances.MotionBlur.Size = math.floor(currentBlurSize + 0.5)
        lastCameraCFrame = currentCFrame
    end)
end

-- // Конфигурации пресетов погоды / падающих частиц
local WeatherPresets = {
    ["Snow"] = {
        Texture = "rbxassetid://109524434",
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.4),
            NumberSequenceKeypoint.new(1, 0.2)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.8, 0.2),
            NumberSequenceKeypoint.new(1, 1)
        }),
        Speed = NumberRange.new(10, 20),
        Lifetime = NumberRange.new(4, 6),
        SpreadAngle = Vector2.new(15, 15),
        Acceleration = Vector3.new(0, -12, 0),
        Rotation = NumberRange.new(-180, 180),
        RotSpeed = NumberRange.new(-50, 50),
        LightEmission = 0.2,
        Color = ColorSequence.new(Color3.fromRGB(240, 245, 255))
    },
    ["Rain"] = {
        Texture = "rbxassetid://7047683935",
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(1, 0.8)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.4),
            NumberSequenceKeypoint.new(1, 0.8)
        }),
        Speed = NumberRange.new(80, 120),
        Lifetime = NumberRange.new(0.8, 1.2),
        SpreadAngle = Vector2.new(2, 2),
        Acceleration = Vector3.new(0, -250, 0),
        Rotation = NumberRange.new(0, 0),
        RotSpeed = NumberRange.new(0, 0),
        LightEmission = 0,
        Color = ColorSequence.new(Color3.fromRGB(180, 200, 220))
    },
    ["Embers"] = {
        Texture = "rbxassetid://258127006",
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1)
        }),
        Speed = NumberRange.new(5, 12),
        Lifetime = NumberRange.new(3, 5),
        SpreadAngle = Vector2.new(45, 45),
        Acceleration = Vector3.new(0, 2, 0),
        Rotation = NumberRange.new(-180, 180),
        RotSpeed = NumberRange.new(-100, 100),
        LightEmission = 1,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 0))
        })
    },
    ["Sakura"] = {
        Texture = "rbxassetid://258128463",
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.6),
            NumberSequenceKeypoint.new(1, 0.4)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(1, 0.8)
        }),
        Speed = NumberRange.new(6, 12),
        Lifetime = NumberRange.new(4, 7),
        SpreadAngle = Vector2.new(30, 30),
        Acceleration = Vector3.new(4, -8, 2),
        Rotation = NumberRange.new(-180, 180),
        RotSpeed = NumberRange.new(-80, 80),
        LightEmission = 0.1,
        Color = ColorSequence.new(Color3.fromRGB(255, 180, 205))
    },
    ["Stars"] = {
        Texture = "rbxassetid://258127006",
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.5, 0.5),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1)
        }),
        Speed = NumberRange.new(2, 6),
        Lifetime = NumberRange.new(3, 5),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, -1, 0),
        Rotation = NumberRange.new(-180, 180),
        RotSpeed = NumberRange.new(-40, 40),
        LightEmission = 1,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 200, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
        })
    }
}

-- // Обновление партиклов
function World.UpdateWeather()
    local emitter = Instances.WeatherEmitter
    if not emitter then return end

    local preset = WeatherPresets[World.Config.Weather]
    if not preset or World.Config.Weather == "None" then
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
    emitter.Rate = World.Config.WeatherDensity
    emitter.Enabled = true
end

-- // Быстрые функции изменения окружения (Красота мира)
function World.SetTime(clockTime: number)
    Lighting.ClockTime = clockTime
end

function World.SetWorldColor(ambient: Color3, outdoor: Color3)
    Lighting.Ambient = ambient
    Lighting.OutdoorAmbient = outdoor
end

-- // Применение всех настроек
function World.ApplyAll()
    World.UpdateBloom()
    World.UpdateColorCorrection()
    World.UpdateCinematics()
    World.UpdateWeather()
end

-- // Полная очистка модуля при отгрузке чита
function World.Destroy()
    if motionBlurConnection then motionBlurConnection:Disconnect() end
    if weatherConnection then weatherConnection:Disconnect() end

    for _, inst in pairs(Instances) do
        if inst and inst.Parent then
            inst:Destroy()
        end
    end

    -- Восстановление дефолтных настроек игры
    for prop, val in pairs(OriginalLighting) do
        pcall(function()
            (Lighting :: any)[prop] = val
        end)
    end
end

return World
