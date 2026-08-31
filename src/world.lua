--!strict
-- [ allaxANT1LOSE ] World Module (Fixed & Synced)
local World = {}

-- // Сервисы
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- // Оригинальные настройки Lighting
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

-- // Внутреннее хранилище состояния
local RawState = {
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
    bloomintensity = 1.25,
    bloomsize = 24,
    bloomthreshold = 0.8,

    motionblurenabled = false,
    motionblurmultiplier = 0.6,
    motionblurmax = 35,

    sunraysenabled = false,
    sunraysintensity = 0.25,
    sunraysspread = 0.7,

    dofenabled = false,
    doffarintensity = 0.5,
    doffocusdistance = 15,
    dofinfocusradius = 20,

    colorcorrectionenabled = false,
    saturation = 0.3,
    contrast = 0.15,
    brightness = 0,

    weather = "None",
    weatherdensity = 100,
}

-- Прокси, который делает State/Config нечувствительным к регистру
local StateProxy = setmetatable({}, {
    __index = function(_, key)
        return RawState[string.lower(tostring(key))]
    end,
    __newindex = function(_, key, val)
        RawState[string.lower(tostring(key))] = val
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

-- // Пресеты осадков
local WeatherPresets = {
    ["Snow"] = {
        Texture = "rbxassetid://109524434",
        Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0.25) }),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.8, 0.1), NumberSequenceKeypoint.new(1, 1) }),
        Speed = NumberRange.new(12, 22),
        Lifetime = NumberRange.new(3, 5),
        SpreadAngle = Vector2.new(15, 15),
        Acceleration = Vector3.new(0, -15, 0),
        Rotation = NumberRange.new(-180, 180),
        RotSpeed = NumberRange.new(-50, 50),
        LightEmission = 0.4,
        Color = ColorSequence.new(Color3.fromRGB(240, 245, 255))
    },
    ["Rain"] = {
        Texture = "rbxassetid://7047683935",
        Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0.8) }),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.8) }),
        Speed = NumberRange.new(80, 120),
        Lifetime = NumberRange.new(0.6, 1.0),
        SpreadAngle = Vector2.new(2, 2),
        Acceleration = Vector3.new(0, -250, 0),
        Rotation = NumberRange.new(0, 0),
        RotSpeed = NumberRange.new(0, 0),
        LightEmission = 0,
        Color = ColorSequence.new(Color3.fromRGB(180, 200, 220))
    },
    ["Embers"] = {
        Texture = "rbxassetid://258127006",
        Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) }),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
        Speed = NumberRange.new(5, 12),
        Lifetime = NumberRange.new(2, 4),
        SpreadAngle = Vector2.new(45, 45),
        Acceleration = Vector3.new(0, 5, 0),
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
        Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.65), NumberSequenceKeypoint.new(1, 0.4) }),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.8) }),
        Speed = NumberRange.new(6, 12),
        Lifetime = NumberRange.new(3, 6),
        SpreadAngle = Vector2.new(30, 30),
        Acceleration = Vector3.new(4, -8, 2),
        Rotation = NumberRange.new(-180, 180),
        RotSpeed = NumberRange.new(-80, 80),
        LightEmission = 0.2,
        Color = ColorSequence.new(Color3.fromRGB(255, 180, 210))
    },
    ["Stars"] = {
        Texture = "rbxassetid://258127006",
        Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 0) }),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }),
        Speed = NumberRange.new(2, 6),
        Lifetime = NumberRange.new(2, 4),
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

-- // Методы обновления
function World.UpdateBloom()
    if not Instances.Bloom then return end
    Instances.Bloom.Enabled = RawState.bloomenabled
    Instances.Bloom.Intensity = tonumber(RawState.bloomintensity) or 1.25
    Instances.Bloom.Size = tonumber(RawState.bloomsize) or 24
    Instances.Bloom.Threshold = tonumber(RawState.bloomthreshold) or 0.8
end

function World.UpdateColorCorrection()
    if not Instances.ColorCorrection then return end
    Instances.ColorCorrection.Enabled = RawState.colorcorrectionenabled
    Instances.ColorCorrection.Saturation = tonumber(RawState.saturation) or 0.3
    Instances.ColorCorrection.Contrast = tonumber(RawState.contrast) or 0.15
    Instances.ColorCorrection.Brightness = tonumber(RawState.brightness) or 0
end

function World.UpdateCinematics()
    if Instances.SunRays then
        Instances.SunRays.Enabled = RawState.sunraysenabled
        Instances.SunRays.Intensity = tonumber(RawState.sunraysintensity) or 0.25
        Instances.SunRays.Spread = tonumber(RawState.sunraysspread) or 0.7
    end
    if Instances.DoF then
        Instances.DoF.Enabled = RawState.dofenabled
        Instances.DoF.FarIntensity = tonumber(RawState.doffarintensity) or 0.5
        Instances.DoF.FocusDistance = tonumber(RawState.doffocusdistance) or 15
        Instances.DoF.InFocusRadius = tonumber(RawState.dofinfocusradius) or 20
    end
end

function World.UpdateWeather()
    local emitter = Instances.WeatherEmitter
    if not emitter then return end

    local currentType = tostring(RawState.weather or "None"):lower()
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
    emitter.Rate = tonumber(RawState.weatherdensity) or 100
    emitter.Enabled = true
end

function World.UpdateWorldColor()
    local r = (tonumber(RawState.worldtintr) or 255) / 255
    local g = (tonumber(RawState.worldtintg) or 255) / 255
    local b = (tonumber(RawState.worldtintb) or 255) / 255
    local col = Color3.new(r, g, b)
    Lighting.Ambient = col
    Lighting.OutdoorAmbient = col
end

function World.UpdateAllMapParts()
    local cam = Workspace.CurrentCamera
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and (not cam or not part:IsDescendantOf(cam)) and (not LocalPlayer.Character or not part:IsDescendantOf(LocalPlayer.Character)) and not Players:GetPlayerFromCharacter(part.Parent) then
            if RawState.maptransparencyenabled then
                if not originalMapMaterials[part] then
                    originalMapMaterials[part] = {
                        Transparency = part.Transparency,
                        Material = part.Material
                    }
                end
                part.Transparency = tonumber(RawState.maptransparencyvalue) or 0.5
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

    -- Контейнер погоды
    local weatherPart = Instance.new("Part")
    weatherPart.Name = "_allax_WeatherPart"
    weatherPart.Transparency = 1
    weatherPart.CanCollide = false
    weatherPart.CanTouch = false
    weatherPart.CanQuery = false
    weatherPart.CastShadow = false
    weatherPart.Anchored = true
    weatherPart.Size = Vector3.new(140, 1, 140)
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

        -- Позиция осадков над игроком
        if Instances.WeatherPart then
            Instances.WeatherPart.CFrame = CFrame.new(curCam.CFrame.Position + Vector3.new(0, 30, 0))
        end

        -- Заморозка времени
        if RawState.locktimeenabled then
            Lighting.ClockTime = tonumber(RawState.targettime) or 14
        end

        -- Motion Blur
        if Instances.MotionBlur then
            if not RawState.motionblurenabled then
                Instances.MotionBlur.Size = 0
                Instances.MotionBlur.Enabled = false
            else
                Instances.MotionBlur.Enabled = true
                local currentCFrame = curCam.CFrame
                local lookDelta = (currentCFrame.LookVector - lastCameraCFrame.LookVector).Magnitude
                local rotDelta = math.deg(lookDelta)

                local mult = tonumber(RawState.motionblurmultiplier) or 0.6
                local maxBlur = tonumber(RawState.motionblurmax) or 35
                local targetBlur = math.clamp(rotDelta * (mult * 10), 0, maxBlur)
                
                currentBlurSize = currentBlurSize + (targetBlur - currentBlurSize) * math.clamp(dt * 15, 0, 1)
                Instances.MotionBlur.Size = math.floor(currentBlurSize + 0.5)
                lastCameraCFrame = currentCFrame
            end
        end
    end))

    -- Heartbeat цикл для Chams
    table.insert(connections, RunService.Heartbeat:Connect(function()
        local curCam = Workspace.CurrentCamera
        if not curCam then return end

        for _, obj in ipairs(curCam:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name = obj.Name:lower()
                local isArm = name:find("arm") or name:find("hand")
                local isWeapon = not isArm and not name:find("humanoid")

                if isArm and RawState.armsenabled then
                    pcall(function()
                        obj.Material = Enum.Material[RawState.armsmaterial] or Enum.Material.Neon
                        obj.Color = Color3.fromRGB(RawState.armscolorr, RawState.armscolorg, RawState.armscolorb)
                        obj.Transparency = tonumber(RawState.armstransparency) or 0
                    end)
                elseif isWeapon and RawState.weaponenabled then
                    pcall(function()
                        obj.Material = Enum.Material[RawState.weaponmaterial] or Enum.Material.ForceField
                        obj.Color = Color3.fromRGB(RawState.weaponcolorr, RawState.weaponcolorg, RawState.weaponcolorb)
                        obj.Transparency = tonumber(RawState.weapontransparency) or 0
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
