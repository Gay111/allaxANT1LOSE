--!strict
-- [ allaxANT1LOSE ] Full World & Visuals Module
local World = {}

-- // Сервисы
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")

-- // Сохранение оригинальных настроек игры для восстановления
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

-- // Главное состояние модуля (State / Config)
World.State = {
    -- Время и Освещение
    targetTime = 14,
    lockTimeEnabled = false,

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
    mapTransparencyEnabled = false,
    mapTransparencyValue = 0.5,

    -- Bloom
    bloomEnabled = false,
    bloomIntensity = 1.25,
    bloomSize = 24,
    bloomThreshold = 0.8,

    -- Motion Blur
    motionBlurEnabled = false,
    motionBlurMultiplier = 0.6,
    motionBlurMax = 35,

    -- SunRays & DoF
    sunRaysEnabled = false,
    sunRaysIntensity = 0.25,
    sunRaysSpread = 0.7,
    dofEnabled = false,
    dofFarIntensity = 0.5,
    dofFocusDistance = 15,
    dofInFocusRadius = 20,

    -- Color Correction
    colorCorrectionEnabled = false,
    saturation = 0.3,
    contrast = 0.15,
    brightness = 0,

    -- Погода / Осадки (Weather)
    weather = "None", -- "Snow", "Rain", "Embers", "Sakura", "Stars", "None"
    weatherDensity = 100,
}

-- Псевдоним для совместимости
World.Config = World.State

-- // Инстансы эффектов
local Instances = {
    Bloom = nil :: BloomEffect?,
    MotionBlur = nil :: BlurEffect?,
    SunRays = nil :: SunRaysEffect?,
    DoF = nil :: DepthOfFieldEffect?,
    ColorCorrection = nil :: ColorCorrectionEffect?,
    WeatherPart = nil :: Part?,
    WeatherEmitter = nil :: ParticleEmitter?,
}

-- Атмосфера
local AtmosphereInstance = Lighting:FindFirstChildOfClass("Atmosphere")
if not AtmosphereInstance then
    AtmosphereInstance = Instance.new("Atmosphere")
    AtmosphereInstance.Name = "_allax_Atmosphere"
    AtmosphereInstance.Parent = Lighting
end
World.Atmosphere = AtmosphereInstance

-- Соединения (Connections)
local connections = {}
local lastCameraCFrame = Camera.CFrame
local currentBlurSize = 0
local originalMapMaterials = {}

-- // Функция поиска/создания эффекта
local function getOrCreateEffect<T>(className: string, name: string): T
    local found = Lighting:FindFirstChild(name)
    if not found or not found:IsA(className) then
        found = Instance.new(className)
        found.Name = name
        found.Parent = Lighting
    end
    return found :: any
end

-- // Пресеты погоды
local WeatherPresets = {
    ["Snow"] = {
        Texture = "rbxassetid://109524434",
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.45),
            NumberSequenceKeypoint.new(1, 0.25)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.8, 0.2),
            NumberSequenceKeypoint.new(1, 1)
        }),
        Speed = NumberRange.new(10, 20),
        Lifetime = NumberRange.new(4, 6),
        SpreadAngle = Vector2.new(15, 15),
        Acceleration = Vector3.new(0, -14, 0),
        Rotation = NumberRange.new(-180, 180),
        RotSpeed = NumberRange.new(-50, 50),
        LightEmission = 0.3,
        Color = ColorSequence.new(Color3.fromRGB(240, 245, 255))
    },
    ["Rain"] = {
        Texture = "rbxassetid://7047683935",
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(1, 0.8)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
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
            NumberSequenceKeypoint.new(0, 0.35),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1)
        }),
        Speed = NumberRange.new(6, 14),
        Lifetime = NumberRange.new(3, 5),
        SpreadAngle = Vector2.new(45, 45),
        Acceleration = Vector3.new(0, 4, 0),
        Rotation = NumberRange.new(-180, 180),
        RotSpeed = NumberRange.new(-100, 100),
        LightEmission = 1,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 40, 0))
        })
    },
    ["Sakura"] = {
        Texture = "rbxassetid://258128463",
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.65),
            NumberSequenceKeypoint.new(1, 0.4)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(1, 0.8)
        }),
        Speed = NumberRange.new(6, 12),
        Lifetime = NumberRange.new(4, 7),
        SpreadAngle = Vector2.new(30, 30),
        Acceleration = Vector3.new(5, -8, 3),
        Rotation = NumberRange.new(-180, 180),
        RotSpeed = NumberRange.new(-80, 80),
        LightEmission = 0.2,
        Color = ColorSequence.new(Color3.fromRGB(255, 180, 210))
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
            ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 210, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
        })
    }
}

-- // Обновление Bloom
function World.UpdateBloom()
    if not Instances.Bloom then return end
    Instances.Bloom.Enabled = World.State.bloomEnabled
    Instances.Bloom.Intensity = World.State.bloomIntensity
    Instances.Bloom.Size = World.State.bloomSize
    Instances.Bloom.Threshold = World.State.bloomThreshold
end

-- // Обновление ColorCorrection
function World.UpdateColorCorrection()
    if not Instances.ColorCorrection then return end
    Instances.ColorCorrection.Enabled = World.State.colorCorrectionEnabled
    Instances.ColorCorrection.Saturation = World.State.saturation
    Instances.ColorCorrection.Contrast = World.State.contrast
    Instances.ColorCorrection.Brightness = World.State.brightness
end

-- // Обновление SunRays & DoF
function World.UpdateCinematics()
    if Instances.SunRays then
        Instances.SunRays.Enabled = World.State.sunRaysEnabled
        Instances.SunRays.Intensity = World.State.sunRaysIntensity
        Instances.SunRays.Spread = World.State.sunRaysSpread
    end
    if Instances.DoF then
        Instances.DoF.Enabled = World.State.dofEnabled
        Instances.DoF.FarIntensity = World.State.dofFarIntensity
        Instances.DoF.FocusDistance = World.State.dofFocusDistance
        Instances.DoF.InFocusRadius = World.State.dofInFocusRadius
    end
end

-- // Обновление погоды
function World.UpdateWeather()
    local emitter = Instances.WeatherEmitter
    if not emitter then return end

    local preset = WeatherPresets[World.State.weather]
    if not preset or World.State.weather == "None" then
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
    emitter.Rate = World.State.weatherDensity
    emitter.Enabled = true
end

-- // Цвет мира (World Tint)
function World.UpdateWorldColor()
    local r = World.State.worldTintR / 255
    local g = World.State.worldTintG / 255
    local b = World.State.worldTintB / 255
    local col = Color3.new(r, g, b)
    Lighting.Ambient = col
    Lighting.OutdoorAmbient = col
end

-- // Прозрачность карты
function World.UpdateAllMapParts()
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part:IsDescendantOf(Camera) and not Players:GetPlayerFromCharacter(part.Parent) then
            if World.State.mapTransparencyEnabled then
                if not originalMapMaterials[part] then
                    originalMapMaterials[part] = {
                        Transparency = part.Transparency,
                        Material = part.Material
                    }
                end
                part.Transparency = World.State.mapTransparencyValue
            elseif originalMapMaterials[part] then
                part.Transparency = originalMapMaterials[part].Transparency
                part.Material = originalMapMaterials[part].Material
            end
        end
    end
end

-- // Инициализация модуля
function World.Init()
    Instances.Bloom = getOrCreateEffect("BloomEffect", "_allax_Bloom")
    Instances.MotionBlur = getOrCreateEffect("BlurEffect", "_allax_MotionBlur")
    Instances.SunRays = getOrCreateEffect("SunRaysEffect", "_allax_SunRays")
    Instances.DoF = getOrCreateEffect("DepthOfFieldEffect", "_allax_DoF")
    Instances.ColorCorrection = getOrCreateEffect("ColorCorrectionEffect", "_allax_ColorCorrection")

    -- Партиклы погоды над камерой
    local weatherPart = Instance.new("Part")
    weatherPart.Name = "_allax_WeatherPart"
    weatherPart.Transparency = 1
    weatherPart.CanCollide = false
    weatherPart.CanTouch = false
    weatherPart.CanQuery = false
    weatherPart.CastShadow = false
    weatherPart.Anchored = true
    weatherPart.Size = Vector3.new(120, 1, 120)
    weatherPart.Parent = Workspace

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "WeatherEmitter"
    emitter.Enabled = false
    emitter.Parent = weatherPart

    Instances.WeatherPart = weatherPart
    Instances.WeatherEmitter = emitter

    -- Постоянный цикл погоды и размытия
    table.insert(connections, RunService.RenderStepped:Connect(function(dt: number)
        -- 1. Следование партиклов за камерой
        local curCam = Workspace.CurrentCamera or Camera
        if curCam and Instances.WeatherPart then
            Instances.WeatherPart.CFrame = CFrame.new(curCam.CFrame.Position + Vector3.new(0, 35, 0))
        end

        -- 2. Заморозка времени
        if World.State.lockTimeEnabled then
            Lighting.ClockTime = World.State.targetTime
        end

        -- 3. Динамический Motion Blur
        if Instances.MotionBlur and curCam then
            if not World.State.motionBlurEnabled then
                Instances.MotionBlur.Size = 0
                Instances.MotionBlur.Enabled = false
            else
                Instances.MotionBlur.Enabled = true
                local currentCFrame = curCam.CFrame
                local lookDelta = (currentCFrame.LookVector - lastCameraCFrame.LookVector).Magnitude
                local rotDelta = math.deg(lookDelta)

                local targetBlur = math.clamp(rotDelta * (World.State.motionBlurMultiplier * 10), 0, World.State.motionBlurMax)
                currentBlurSize = currentBlurSize + (targetBlur - currentBlurSize) * math.clamp(dt * 15, 0, 1)

                Instances.MotionBlur.Size = math.floor(currentBlurSize + 0.5)
                lastCameraCFrame = currentCFrame
            end
        end
    end))

    -- Логика Чамсов на Руки и Оружие в камере
    table.insert(connections, RunService.Heartbeat:Connect(function()
        local curCam = Workspace.CurrentCamera or Camera
        if not curCam then return end

        for _, obj in ipairs(curCam:GetDescendants()) do
            if obj:IsA("BasePart") then
                local isArm = obj.Name:lower():find("arm") or obj.Name:lower():find("hand")
                local isWeapon = not isArm and not obj.Name:lower():find("humanoid")

                if isArm and World.State.armsEnabled then
                    pcall(function()
                        obj.Material = Enum.Material[World.State.armsMaterial] or Enum.Material.Neon
                        obj.Color = Color3.fromRGB(World.State.armsColorR, World.State.armsColorG, World.State.armsColorB)
                        obj.Transparency = World.State.armsTransparency
                    end)
                elseif isWeapon and World.State.weaponEnabled then
                    pcall(function()
                        obj.Material = Enum.Material[World.State.weaponMaterial] or Enum.Material.ForceField
                        obj.Color = Color3.fromRGB(World.State.weaponColorR, World.State.weaponColorG, World.State.weaponColorB)
                        obj.Transparency = World.State.weaponTransparency
                    end)
                end
            end
        end
    end))

    World.UpdateBloom()
    World.UpdateColorCorrection()
    World.UpdateCinematics()
    World.UpdateWeather()

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
