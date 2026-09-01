--!strict
-- [ allaxANT1LOSE ] World Module with Animated Dynamic Chams (Pulse, Rainbow, Gradient)
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
World.State = {
    -- Освещение
    targetTime = 14,
    lockTimeEnabled = false,
    mapBrightness = Lighting.Brightness,
    exposureCompensation = Lighting.ExposureCompensation,

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
    armsColorMode = "STATIC", -- "STATIC", "PULSE", "RAINBOW", "GRADIENT"
    armsSpeed = 1.0,
    armsColorR = 255,
    armsColorG = 255,
    armsColorB = 255,
    armsColor2R = 0,
    armsColor2G = 0,
    armsColor2B = 0,
    armsTransparency = 0,

    -- Чамсы на Оружие (Held Weapon)
    weaponEnabled = false,
    weaponMaterial = "FORCEFIELD",
    weaponColorMode = "STATIC", -- "STATIC", "PULSE", "RAINBOW", "GRADIENT"
    weaponSpeed = 1.0,
    weaponColorR = 0,
    weaponColorG = 255,
    weaponColorB = 255,
    weaponColor2R = 255,
    weaponColor2G = 0,
    weaponColor2B = 255,
    weaponTransparency = 0,

    -- Тинт мира и прозрачность карты
    worldTintR = 255,
    worldTintG = 255,
    worldTintB = 255,
    mapTransparencyEnabled = false,
    mapTransparencyValue = 0.5,

    -- Bloom
    bloomEnabled = false,
    bloomIntensity = 1.5,
    bloomSize = 28,
    bloomThreshold = 0.3,

    -- Motion Blur
    motionBlurEnabled = false,
    motionBlurMultiplier = 1.0,
    motionBlurMax = 40,

    -- SunRays & DoF
    sunRaysEnabled = false,
    sunRaysIntensity = 0.3,
    sunRaysSpread = 0.8,
    dofEnabled = false,
    dofFarIntensity = 0.8,
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

-- // Маппинг материалов
local MaterialMap = {
    ["NEON"] = Enum.Material.Neon,
    ["FORCEFIELD"] = Enum.Material.ForceField,
    ["GLASS"] = Enum.Material.Glass,
    ["FOIL"] = Enum.Material.Foil,
    ["PLASTIC"] = Enum.Material.Plastic,
    ["SMOOTHPLASTIC"] = Enum.Material.SmoothPlastic,
    ["Neon"] = Enum.Material.Neon,
    ["ForceField"] = Enum.Material.ForceField,
    ["Glass"] = Enum.Material.Glass,
    ["Foil"] = Enum.Material.Foil,
    ["Plastic"] = Enum.Material.Plastic,
}

local function parseMaterial(matName: any): Enum.Material
    if typeof(matName) == "EnumItem" then return matName end
    local str = tostring(matName or "")
    if MaterialMap[str] then return MaterialMap[str] end
    if MaterialMap[str:upper()] then return MaterialMap[str:upper()] end
    return Enum.Material.Neon
end

-- // Калькулятор динамического цвета (Pulse, Rainbow, Gradient)
local function getDynamicColor(mode: string, col1: Color3, col2: Color3, speed: number, offset: number): Color3
    local t = tick() * (speed or 1.0)
    local off = offset or 0

    if mode == "RAINBOW" then
        local hue = (t * 0.2 + off * 0.05) % 1
        return Color3.fromHSV(hue, 1, 1)
    elseif mode == "PULSE" then
        local alpha = (math.sin(t * 3.5) + 1) / 2
        return col1:Lerp(col2, alpha)
    elseif mode == "GRADIENT" then
        local alpha = (math.sin(t * 2.5 + off * 0.4) + 1) / 2
        return col1:Lerp(col2, alpha)
    else
        return col1
    end
end

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
local isUpdatingMap = false

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
    Instances.Bloom.Threshold = tonumber(World.State.bloomThreshold) or 0.3
end

-- // Обновление ColorCorrection & Тинта
function World.UpdateColorCorrection()
    if not Instances.ColorCorrection then return end

    local r = (tonumber(World.State.worldTintR) or 255) / 255
    local g = (tonumber(World.State.worldTintG) or 255) / 255
    local b = (tonumber(World.State.worldTintB) or 255) / 255
    local isCustomTint = (r ~= 1 or g ~= 1 or b ~= 1)

    Instances.ColorCorrection.Enabled = World.State.colorCorrectionEnabled or isCustomTint
    Instances.ColorCorrection.Saturation = tonumber(World.State.saturation) or 0.35
    Instances.ColorCorrection.Contrast = tonumber(World.State.contrast) or 0.15
    Instances.ColorCorrection.Brightness = tonumber(World.State.brightness) or 0
    Instances.ColorCorrection.TintColor = Color3.new(r, g, b)
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
        Instances.DoF.FarIntensity = tonumber(World.State.dofFarIntensity) or 0.8
        Instances.DoF.NearIntensity = tonumber(World.State.dofNearIntensity) or 0.5
        Instances.DoF.FocusDistance = tonumber(World.State.dofFocusDistance) or 15
        Instances.DoF.InFocusRadius = tonumber(World.State.dofInFocusRadius) or 15
    end
end

-- // Обновление Облаков
function World.UpdateClouds()
    local terrain = Workspace:FindFirstChildOfClass("Terrain") or Workspace.Terrain
    if not terrain then return end

    local clouds = terrain:FindFirstChildOfClass("Clouds")
    if not clouds then
        clouds = Instance.new("Clouds")
        clouds.Name = "_allax_Clouds"
        clouds.Parent = terrain
    end
    Instances.Clouds = clouds

    if World.State.cloudsEnabled then
        clouds.Enabled = true
        clouds.Cover = math.clamp(tonumber(World.State.cloudsCover) or 0.6, 0.05, 1)
        clouds.Density = math.clamp(tonumber(World.State.cloudsDensity) or 0.7, 0.05, 1)
        clouds.Color = Color3.fromRGB(
            tonumber(World.State.cloudsColorR) or 255,
            tonumber(World.State.cloudsColorG) or 255,
            tonumber(World.State.cloudsColorB) or 255
        )
    else
        clouds.Enabled = false
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

-- // Тинт мира
function World.UpdateWorldColor()
    World.UpdateColorCorrection()
end

-- // Туман
function World.SetFog(densityPercent: number)
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        atmosphere.Density = math.clamp((densityPercent / 100) * 0.75, 0, 1)
        atmosphere.Haze = math.clamp((densityPercent / 100) * 2.5, 0, 10)
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

-- // Прозрачность карты
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

-- // Инициализация
function World.Init()
    Instances.Bloom = getOrCreateEffect(Lighting, "BloomEffect", "_allax_Bloom")
    Instances.MotionBlur = getOrCreateEffect(Lighting, "BlurEffect", "_allax_MotionBlur")
    Instances.SunRays = getOrCreateEffect(Lighting, "SunRaysEffect", "_allax_SunRays")
    Instances.DoF = getOrCreateEffect(Lighting, "DepthOfFieldEffect", "_allax_DoF")
    Instances.ColorCorrection = getOrCreateEffect(Lighting, "ColorCorrectionEffect", "_allax_ColorCorrection")

    local terrain = Workspace:FindFirstChildOfClass("Terrain") or Workspace.Terrain
    if terrain then
        Instances.Clouds = terrain:FindFirstChildOfClass("Clouds") or getOrCreateEffect(terrain, "Clouds", "_allax_Clouds")
    end

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

        -- Заморозка времени
        if World.State.lockTimeEnabled then
            Lighting.ClockTime = tonumber(World.State.targetTime) or 14
        end

        -- Motion Blur
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

        -- ====================================================================
        -- // ДИНАМИЧЕСКИЕ ЧАМСЫ НА РУКИ И ОРУЖИЕ (Pulse, Rainbow, Gradient, Static)
        -- ====================================================================
        if World.State.armsEnabled or World.State.weaponEnabled then
            local armMat = parseMaterial(World.State.armsMaterial)
            local armCol1 = Color3.fromRGB(World.State.armsColorR, World.State.armsColorG, World.State.armsColorB)
            local armCol2 = Color3.fromRGB(World.State.armsColor2R or 0, World.State.armsColor2G or 0, World.State.armsColor2B or 0)
            local armMode = tostring(World.State.armsColorMode or "STATIC"):upper()
            local armSpeed = tonumber(World.State.armsSpeed) or 1.0
            local armTrans = tonumber(World.State.armsTransparency) or 0

            local wepMat = parseMaterial(World.State.weaponMaterial)
            local wepCol1 = Color3.fromRGB(World.State.weaponColorR, World.State.weaponColorG, World.State.weaponColorB)
            local wepCol2 = Color3.fromRGB(World.State.weaponColor2R or 0, World.State.weaponColor2G or 0, World.State.weaponColor2B or 0)
            local wepMode = tostring(World.State.weaponColorMode or "STATIC"):upper()
            local wepSpeed = tonumber(World.State.weaponSpeed) or 1.0
            local wepTrans = tonumber(World.State.weaponTransparency) or 0

            local partIndex = 0

            -- 1. Сканирование вьюмоделей внутри Камеры
            for _, obj in ipairs(curCam:GetDescendants()) do
                if obj:IsA("BasePart") then
                    partIndex = partIndex + 1
                    local name = obj.Name:lower()
                    local pName = obj.Parent and obj.Parent.Name:lower() or ""

                    local isArm = name:find("arm") or name:find("hand") or name:find("glove") or name:find("sleeve")
                               or pName:find("arm") or pName:find("hand") or pName:find("glove") or pName:find("sleeve")

                    if isArm and World.State.armsEnabled then
                        local dynamicArmColor = getDynamicColor(armMode, armCol1, armCol2, armSpeed, partIndex)
                        pcall(function()
                            obj.Material = armMat
                            obj.Color = dynamicArmColor
                            obj.Transparency = armTrans
                        end)
                    elseif not isArm and World.State.weaponEnabled then
                        local dynamicWepColor = getDynamicColor(wepMode, wepCol1, wepCol2, wepSpeed, partIndex)
                        pcall(function()
                            obj.Material = wepMat
                            obj.Color = dynamicWepColor
                            obj.Transparency = wepTrans
                        end)
                    end
                end
            end

            -- 2. Сканирование вьюмоделей в Workspace
            for _, vmName in ipairs({"Viewmodel", "ViewModel", "Arms", "FPS_Arms", "Ignore"}) do
                local vm = Workspace:FindFirstChild(vmName)
                if vm then
                    for _, obj in ipairs(vm:GetDescendants()) do
                        if obj:IsA("BasePart") then
                            partIndex = partIndex + 1
                            local name = obj.Name:lower()
                            local pName = obj.Parent and obj.Parent.Name:lower() or ""

                            local isArm = name:find("arm") or name:find("hand") or name:find("glove") or name:find("sleeve")
                                       or pName:find("arm") or pName:find("hand") or pName:find("glove") or pName:find("sleeve")

                            if isArm and World.State.armsEnabled then
                                local dynamicArmColor = getDynamicColor(armMode, armCol1, armCol2, armSpeed, partIndex)
                                pcall(function()
                                    obj.Material = armMat
                                    obj.Color = dynamicArmColor
                                    obj.Transparency = armTrans
                                end)
                            elseif not isArm and World.State.weaponEnabled then
                                local dynamicWepColor = getDynamicColor(wepMode, wepCol1, wepCol2, wepSpeed, partIndex)
                                pcall(function()
                                    obj.Material = wepMat
                                    obj.Color = dynamicWepColor
                                    obj.Transparency = wepTrans
                                end)
                            end
                        end
                    end
                end
            end

            -- 3. Сканирование предметов в персонаже (Tool)
            if LocalPlayer and LocalPlayer.Character and World.State.weaponEnabled then
                for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
                    if tool:IsA("Tool") then
                        for _, p in ipairs(tool:GetDescendants()) do
                            if p:IsA("BasePart") then
                                partIndex = partIndex + 1
                                local dynamicWepColor = getDynamicColor(wepMode, wepCol1, wepCol2, wepSpeed, partIndex)
                                pcall(function()
                                    p.Material = wepMat
                                    p.Color = dynamicWepColor
                                    p.Transparency = wepTrans
                                end)
                            end
                        end
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
