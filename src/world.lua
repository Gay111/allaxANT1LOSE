--!strict
-- [ allaxANT1LOSE ] World & Visual Effects Module (Fully Working Particles & Post-Processing)
local World = {}

-- // Сервисы
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

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

-- // Главная таблица состояния
local StateData = {
    targettime = 14,
    locktimeenabled = false,

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

    worldtintr = 255,
    worldtintg = 255,
    worldtintb = 255,
    maptransparencyenabled = false,
    maptransparencyvalue = 0.5,

    bloomenabled = false,
    bloomintensity = 1.8,
    bloomsize = 32,
    bloomthreshold = 0.2, -- Понижен порог, чтобы блум был сразу виден

    motionblurenabled = false,
    motionblurmultiplier = 1.2,
    motionblurmax = 40,

    sunraysenabled = false,
    sunraysintensity = 0.35,
    sunraysspread = 0.8,

    dofenabled = false,
    doffarintensity = 0.75,
    doffocusdistance = 20,
    dofinfocusradius = 25,

    colorcorrectionenabled = false,
    saturation = 0.4,
    contrast = 0.2,
    brightness = 0,

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

local connections = {}
local lastCameraCFrame = CFrame.new()
local currentBlurSize = 0
local originalMapMaterials = {}

local function getOrCreateEffect<T>(className: string, name: string): T
    local found = Lighting:FindFirstChild(name)
    if not found or not found:IsA(className) then
        found = Instance.new(className)
        found.Name = name
        found.Parent = Lighting
    end
    return found :: any
end

-- // 100% РАБОЧИЕ ПРЕСЕТЫ ПОГОДЫ (Проверенные Asset ID Roblox)
local WeatherPresets = {
    ["Snow"] = {
        Texture = "rbxassetid://304777684", -- Реальная текстура снежинки
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.7),
            NumberSequenceKeypoint.new(1, 0.35)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(0.8, 0.1),
            NumberSequenceKeypoint.new(1, 1)
        }),
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
        Texture = "rbxassetid://243660364", -- Реальная текстура капли дождя
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.6),
            NumberSequenceKeypoint.new(1, 0.6)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 0.7)
        }),
        Speed = NumberRange.new(45, 70),
        Lifetime = NumberRange.new(1.5, 2.5),
        SpreadAngle = Vector2.new(3, 3),
        Acceleration = Vector3.new(0, -80, 0),
        Rotation = NumberRange.new(0, 0),
        RotSpeed = NumberRange.new(0, 0),
        LightEmission = 0.4,
        Color = ColorSequence.new(Color3.fromRGB(200, 225, 255))
    },
    ["Embers"] = {
        Texture = "rbxassetid://5857851618", -- Искры / Огненный пепел
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(1, 0.1)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1)
        }),
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
        Texture = "rbxassetid://258128463", -- Лепестки сакуры
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.7),
            NumberSequenceKeypoint.new(1, 0.4)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(1, 0.8)
        }),
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
        Texture = "rbxassetid://5857892330", -- Звездная пыль / Свечение
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(0.5, 0.7),
            NumberSequenceKeypoint.new(1, 0.1)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1)
        }),
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

-- // Обновление Bloom
function World.UpdateBloom()
    if not Instances.Bloom then return end
    Instances.Bloom.Enabled = StateData.bloomenabled
    Instances.Bloom.Intensity = tonumber(StateData.bloomintensity) or 1.8
    Instances.Bloom.Size = tonumber(StateData.bloomsize) or 32
    Instances.Bloom.Threshold = tonumber(StateData.bloomthreshold) or 0.2
end

-- // Обновление ColorCorrection
function World.UpdateColorCorrection()
    if not Instances.ColorCorrection then return end
    Instances.ColorCorrection.Enabled = StateData.colorcorrectionenabled
    Instances.ColorCorrection.Saturation = tonumber(StateData.saturation) or 0.4
    Instances.ColorCorrection.Contrast = tonumber(StateData.contrast) or 0.2
    Instances.ColorCorrection.Brightness = tonumber(StateData.brightness) or 0
end

-- // Обновление SunRays & DoF
function World.UpdateCinematics()
    if Instances.SunRays then
        Instances.SunRays.Enabled = StateData.sunraysenabled
        Instances.SunRays.Intensity = tonumber(StateData.sunraysintensity) or 0.35
        Instances.SunRays.Spread = tonumber(StateData.sunraysspread) or 0.8
    end
    if Instances.DoF then
        Instances.DoF.Enabled = StateData.dofenabled
        Instances.DoF.FarIntensity = tonumber(StateData.doffarintensity) or 0.75
        Instances.DoF.FocusDistance = tonumber(StateData.doffocusdistance) or 20
        Instances.DoF.InFocusRadius = tonumber(StateData.dofinfocusradius) or 25
    end
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
    Lighting.Ambient = col
    Lighting.OutdoorAmbient = col
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

-- // Инициализация
function World.Init()
    Instances.Bloom = getOrCreateEffect("BloomEffect", "_allax_Bloom")
    Instances.MotionBlur = getOrCreateEffect("BlurEffect", "_allax_MotionBlur")
    Instances.SunRays = getOrCreateEffect("SunRaysEffect", "_allax_SunRays")
    Instances.DoF = getOrCreateEffect("DepthOfFieldEffect", "_allax_DoF")
    Instances.ColorCorrection = getOrCreateEffect("ColorCorrectionEffect", "_allax_ColorCorrection")

    local cam = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")
    lastCameraCFrame = cam and cam.CFrame or CFrame.new()

    -- Контейнер осадков
    local weatherPart = Instance.new("Part")
    weatherPart.Name = "_allax_WeatherPart"
    weatherPart.Transparency = 1
    weatherPart.CanCollide = false
    weatherPart.CanTouch = false
    weatherPart.CanQuery = false
    weatherPart.CastShadow = false
    weatherPart.Anchored = true
    weatherPart.Size = Vector3.new(160, 2, 160)
    weatherPart.Parent = Workspace

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "WeatherEmitter"
    emitter.EmissionDirection = Enum.NormalId.Bottom
    emitter.Enabled = false
    emitter.Parent = weatherPart

    Instances.WeatherPart = weatherPart
    Instances.WeatherEmitter = emitter

    -- RenderStepped Цикл
    table.insert(connections, RunService.RenderStepped:Connect(function(dt: number)
        local curCam = Workspace.CurrentCamera
        if not curCam then return end

        -- Следование осадков за игроком
        if Instances.WeatherPart then
            Instances.WeatherPart.CFrame = CFrame.new(curCam.CFrame.Position + Vector3.new(0, 28, 0))
        end

        -- Заморозка времени
        if StateData.locktimeenabled then
            Lighting.ClockTime = tonumber(StateData.targettime) or 14
        end

        -- Динамический Motion Blur с плавной интерполяцией
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

    -- Heartbeat Цикл для Chams
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
