-- // init.lua
if getgenv and getgenv().AntiloseLoadedInstance then
    pcall(function() getgenv().AntiloseLoadedInstance() end)
end

local BASE_URL = "https://raw.githubusercontent.com/Gay111/allaxANT1LOSE/main/src/"

-- Безопасная функция импорта модулей
local function import(modulePath)
    local source
    
    -- 1. Пробуем загрузить локальный файл из папки workspace эксплойта
    if readfile and isfile and isfile("src/" .. modulePath) then
        source = readfile("src/" .. modulePath)
    elseif readfile and isfile and isfile(modulePath) then
        source = readfile(modulePath)
    end
    
    -- 2. Если локального файла нет — качаем с GitHub
    if not source then
        local fullUrl = BASE_URL .. modulePath .. "?t=" .. tostring(os.time())
        local success, result = pcall(function()
            return game:HttpGet(fullUrl)
        end)
        
        -- Проверяем, скачался ли файл и не является ли он ошибкой 404
        if not success or not result or result:match("404") or result == "404: Not Found" then
            error("\n[Antilose Loader] ОШИБКА 404: Не удалось загрузить файл '" .. modulePath .. "' с GitHub.\nУбедитесь, что вы создали этот файл на гитхабе по пути: src/" .. modulePath)
        end
        source = result
    end
    
    -- 3. Безопасная компиляция кода
    local func, err = loadstring(source)
    if not func then
        error("\n[Antilose Loader] СИНТАКСИЧЕСКАЯ ОШИБКА в файле '" .. modulePath .. "':\n" .. tostring(err))
    end
    
    -- 4. Безопасное выполнение модуля
    local runSuccess, runResult = pcall(func)
    if not runSuccess then
        error("\n[Antilose Loader] ОШИБКА ВЫПОЛНЕНИЯ в файле '" .. modulePath .. "':\n" .. tostring(runResult))
    end
    
    return runResult
end

-- Загрузка модулей
local UI = import("ui.lua")
local Visual = import("visual.lua")
local World = import("world.lua")
local Combat = import("combat.lua")

local uiInstance = UI.Init()
local visualInstance = Visual.Init(uiInstance.ScreenGui)
local worldInstance = World.Init()
local combatInstance = Combat.Init()

-- ============================================================================
-- // ВКЛАДКА: VISUALS
-- ============================================================================
local VisGroup = uiInstance.CreateGroupbox(uiInstance.Pages["Visuals"].Left, "3D In-World Indicators")

VisGroup:AddToggle("Awall Checker", false, function(v)
    visualInstance.State.awallEnabled = v
end)

VisGroup:AddSlider("Marker Size", 0.5, 4, 1.2, 0.1, "m", function(v)
    visualInstance.State.awallSize = v
end)

VisGroup:AddSlider("Marker Transparency", 0, 1, 0.25, 0.05, "", function(v)
    visualInstance.State.markerTransparency = v
end)

VisGroup:AddSlider("Penetration Depth", 1, 20, 8, 1, "m", function(v)
    visualInstance.State.penetrationDepth = v
end)

VisGroup:AddSegmented("Anchor Mode", { "MOUSE", "CENTER" }, 1, function(opt)
    visualInstance.State.awallMode = opt
end)

-- Секция настроек CS2 3D Chams
local PlayerChamsGroup = uiInstance.CreateGroupbox(uiInstance.Pages["Visuals"].Right, "3D Player Chams (CS2)")

PlayerChamsGroup:AddToggle("Enable 3D Chams", false, function(v)
    visualInstance.State.chamsEnabled = v
end)

PlayerChamsGroup:AddToggle("Hide Original Skin", true, function(v)
    visualInstance.State.chamHideOriginal = v
end)

PlayerChamsGroup:AddToggle("Team Check", false, function(v)
    visualInstance.State.chamTeamCheck = v
end)

PlayerChamsGroup:AddSegmented("Material", { "PLASTIC", "NEON", "FORCEFIELD", "GLASS", "FOIL" }, 1, function(opt)
    visualInstance.State.chamMaterial = opt
end)

PlayerChamsGroup:AddSlider("Transparency", 0, 1, 0.3, 0.05, "", function(v)
    visualInstance.State.chamTransparency = v
end)

PlayerChamsGroup:AddSlider("Color - Red", 0, 255, 0, 1, "", function(v)
    visualInstance.State.chamColorR = v
end)

PlayerChamsGroup:AddSlider("Color - Green", 0, 255, 210, 1, "", function(v)
    visualInstance.State.chamColorG = v
end)

PlayerChamsGroup:AddSlider("Color - Blue", 0, 255, 160, 1, "", function(v)
    visualInstance.State.chamColorB = v
end)

-- ============================================================================
-- // ВКЛАДКА: WORLD
-- ============================================================================

-- [Левая колонка] Освещение и Время
local WorldLight = uiInstance.CreateGroupbox(uiInstance.Pages["World"].Left, "Lighting & Time")

WorldLight:AddSlider("Time of Day", 0, 24, math.floor(game:GetService("Lighting").ClockTime), 0.5, "h", function(v)
    if worldInstance.State then worldInstance.State.targetTime = v end
    game:GetService("Lighting").ClockTime = v
end)

WorldLight:AddToggle("Lock Time of Day", false, function(v)
    if worldInstance.State then worldInstance.State.lockTimeEnabled = v end
    if v and worldInstance.State then game:GetService("Lighting").ClockTime = worldInstance.State.targetTime end
end)

WorldLight:AddSlider("Map Brightness", 0, 10, math.floor(game:GetService("Lighting").Brightness), 0.2, "", function(v)
    game:GetService("Lighting").Brightness = v
end)

WorldLight:AddSlider("Exposure Compensation", -3, 3, 0, 0.1, "", function(v)
    game:GetService("Lighting").ExposureCompensation = v
end)

-- [Левая колонка] Bloom & Motion Blur
local PostEffectsGroup = uiInstance.CreateGroupbox(uiInstance.Pages["World"].Left, "Bloom & Motion Blur")

PostEffectsGroup:AddToggle("Enable Bloom", false, function(v)
    World.Config.BloomEnabled = v
    World.UpdateBloom()
end)

PostEffectsGroup:AddSlider("Bloom Intensity", 0, 5, 1.25, 0.05, "", function(v)
    World.Config.BloomIntensity = v
    World.UpdateBloom()
end)

PostEffectsGroup:AddSlider("Bloom Size", 0, 56, 24, 1, "", function(v)
    World.Config.BloomSize = v
    World.UpdateBloom()
end)

PostEffectsGroup:AddSlider("Bloom Threshold", 0, 2, 0.8, 0.05, "", function(v)
    World.Config.BloomThreshold = v
    World.UpdateBloom()
end)

PostEffectsGroup:AddToggle("Motion Blur", false, function(v)
    World.Config.MotionBlurEnabled = v
end)

PostEffectsGroup:AddSlider("Blur Intensity", 0.1, 2, 0.6, 0.05, "", function(v)
    World.Config.MotionBlurMultiplier = v
end)

-- [Левая колонка] Чамсы Рук
local ArmsGroup = uiInstance.CreateGroupbox(uiInstance.Pages["World"].Left, "Self Arms Material")

ArmsGroup:AddToggle("Enable Arms Chams", false, function(v)
    if worldInstance.State then worldInstance.State.armsEnabled = v end
end)

ArmsGroup:AddSegmented("Material", { "NEON", "FORCEFIELD", "GLASS", "FOIL", "PLASTIC" }, 1, function(opt)
    if worldInstance.State then worldInstance.State.armsMaterial = opt end
end)

ArmsGroup:AddSlider("Color - Red", 0, 255, 255, 1, "", function(v)
    if worldInstance.State then worldInstance.State.armsColorR = v end
end)

ArmsGroup:AddSlider("Color - Green", 0, 255, 255, 1, "", function(v)
    if worldInstance.State then worldInstance.State.armsColorG = v end
end)

ArmsGroup:AddSlider("Color - Blue", 0, 255, 255, 1, "", function(v)
    if worldInstance.State then worldInstance.State.armsColorB = v end
end)

ArmsGroup:AddSlider("Transparency", 0, 1, 0, 0.05, "", function(v)
    if worldInstance.State then worldInstance.State.armsTransparency = v end
end)

-- [Правая колонка] Погодные эффекты / Частицы с неба
local WeatherGroup = uiInstance.CreateGroupbox(uiInstance.Pages["World"].Right, "Sky Weather & Particles")

local weatherNames = {
    ["NONE"] = "None",
    ["SNOW"] = "Snow",
    ["RAIN"] = "Rain",
    ["EMBERS"] = "Embers",
    ["SAKURA"] = "Sakura",
    ["STARS"] = "Stars"
}

WeatherGroup:AddSegmented("Weather Type", { "NONE", "SNOW", "RAIN", "EMBERS", "SAKURA", "STARS" }, 1, function(opt)
    World.Config.Weather = weatherNames[opt] or "None"
    World.UpdateWeather()
end)

WeatherGroup:AddSlider("Particle Density", 10, 300, 100, 10, "p/s", function(v)
    World.Config.WeatherDensity = v
    World.UpdateWeather()
end)

-- [Правая колонка] Кинематографичность (SunRays & DoF)
local CinemaGroup = uiInstance.CreateGroupbox(uiInstance.Pages["World"].Right, "Cinematics (SunRays & DoF)")

CinemaGroup:AddToggle("Sun Rays", false, function(v)
    World.Config.SunRaysEnabled = v
    World.UpdateCinematics()
end)

CinemaGroup:AddSlider("Sun Rays Intensity", 0, 1, 0.25, 0.01, "", function(v)
    World.Config.SunRaysIntensity = v
    World.UpdateCinematics()
end)

CinemaGroup:AddToggle("Depth of Field", false, function(v)
    World.Config.DoFEnabled = v
    World.UpdateCinematics()
end)

CinemaGroup:AddSlider("Focus Distance", 5, 100, 15, 1, "m", function(v)
    World.Config.DoFFocusDistance = v
    World.UpdateCinematics()
end)

-- [Правая колонка] Чамсы Оружия
local WeaponGroup = uiInstance.CreateGroupbox(uiInstance.Pages["World"].Right, "Held Item / Weapon Material")

WeaponGroup:AddToggle("Enable Weapon Chams", false, function(v)
    if worldInstance.State then worldInstance.State.weaponEnabled = v end
end)

WeaponGroup:AddSegmented("Material", { "NEON", "FORCEFIELD", "GLASS", "FOIL", "PLASTIC" }, 2, function(opt)
    if worldInstance.State then worldInstance.State.weaponMaterial = opt end
end)

WeaponGroup:AddSlider("Color - Red", 0, 255, 0, 1, "", function(v)
    if worldInstance.State then worldInstance.State.weaponColorR = v end
end)

WeaponGroup:AddSlider("Color - Green", 0, 255, 255, 1, "", function(v)
    if worldInstance.State then worldInstance.State.weaponColorG = v end
end)

WeaponGroup:AddSlider("Color - Blue", 0, 255, 255, 1, "", function(v)
    if worldInstance.State then worldInstance.State.weaponColorB = v end
end)

WeaponGroup:AddSlider("Transparency", 0, 1, 0, 0.05, "", function(v)
    if worldInstance.State then worldInstance.State.weaponTransparency = v end
end)

-- [Правая колонка] Атмосфера, ColorCorrection & Туман
local WorldAtm = uiInstance.CreateGroupbox(uiInstance.Pages["World"].Right, "World Tint & Atmosphere")

WorldAtm:AddToggle("Color Correction", false, function(v)
    World.Config.ColorCorrectionEnabled = v
    World.UpdateColorCorrection()
end)

WorldAtm:AddSlider("Saturation", -1, 2, 0.3, 0.05, "", function(v)
    World.Config.Saturation = v
    World.UpdateColorCorrection()
end)

WorldAtm:AddSlider("Contrast", -1, 2, 0.15, 0.05, "", function(v)
    World.Config.Contrast = v
    World.UpdateColorCorrection()
end)

WorldAtm:AddSlider("Tint - Red", 0, 255, 255, 1, "", function(v)
    if worldInstance.State then
        worldInstance.State.worldTintR = v
        if worldInstance.UpdateWorldColor then worldInstance.UpdateWorldColor() end
    end
end)

WorldAtm:AddSlider("Tint - Green", 0, 255, 255, 1, "", function(v)
    if worldInstance.State then
        worldInstance.State.worldTintG = v
        if worldInstance.UpdateWorldColor then worldInstance.UpdateWorldColor() end
    end
end)

WorldAtm:AddSlider("Tint - Blue", 0, 255, 255, 1, "", function(v)
    if worldInstance.State then
        worldInstance.State.worldTintB = v
        if worldInstance.UpdateWorldColor then worldInstance.UpdateWorldColor() end
    end
end)

WorldAtm:AddButton("Reset World Color", function()
    if worldInstance.State then
        worldInstance.State.worldTintR, worldInstance.State.worldTintG, worldInstance.State.worldTintB = 255, 255, 255
        if worldInstance.UpdateWorldColor then worldInstance.UpdateWorldColor() end
    end
end)

WorldAtm:AddSlider("Fog Density", 0, 100, 30, 2, "%", function(v)
    if worldInstance.Atmosphere then
        worldInstance.Atmosphere.Density = v / 100
        worldInstance.Atmosphere.Haze = (v / 100) * 2
    end
    game:GetService("Lighting").FogEnd = math.clamp(5000 - (v * 45), 100, 10000)
end)

WorldAtm:AddButton("Clear All Fog", function()
    if worldInstance.Atmosphere then
        worldInstance.Atmosphere.Density = 0
        worldInstance.Atmosphere.Haze = 0
    end
    game:GetService("Lighting").FogStart = 0
    game:GetService("Lighting").FogEnd = 10000000
end)

WorldAtm:AddToggle("Map Transparency", false, function(v)
    if worldInstance.State then
        worldInstance.State.mapTransparencyEnabled = v
        if worldInstance.UpdateAllMapParts then worldInstance.UpdateAllMapParts() end
    end
end)

WorldAtm:AddSlider("Transparency Level", 0, 1, 0.5, 0.05, "", function(v)
    if worldInstance.State then
        worldInstance.State.mapTransparencyValue = v
        if worldInstance.State.mapTransparencyEnabled and worldInstance.UpdateAllMapParts then
            worldInstance.UpdateAllMapParts()
        end
    end
end)

-- ============================================================================
-- // ВКЛАДКА: SETTINGS
-- ============================================================================
local SetGroup = uiInstance.CreateGroupbox(uiInstance.Pages["Settings"].Left, "Client Core")

local function unloadAll()
    for _, c in ipairs(uiInstance.Connections or {}) do
        pcall(function() c:Disconnect() end)
    end
    if visualInstance and visualInstance.Cleanup then
        pcall(function() visualInstance.Cleanup() end)
    end
    if World and World.Destroy then
        pcall(function() World.Destroy() end)
    elseif worldInstance and worldInstance.Cleanup then
        pcall(function() worldInstance.Cleanup() end)
    end
    if combatInstance and combatInstance.Cleanup then
        pcall(function() combatInstance.Cleanup() end)
    end
    if uiInstance and uiInstance.ScreenGui then
        pcall(function() uiInstance.ScreenGui:Destroy() end)
    end
    if getgenv then
        getgenv().AntiloseLoadedInstance = nil
    end
end

SetGroup:AddButton("Unload Interface", unloadAll)
if getgenv then
    getgenv().AntiloseLoadedInstance = unloadAll
end

-- ============================================================================
-- // ВКЛАДКА: AIM
-- ============================================================================
local AimGroup = uiInstance.CreateGroupbox(uiInstance.Pages["Aim"].Left, "Aim Settings")
local FovGroup = uiInstance.CreateGroupbox(uiInstance.Pages["Aim"].Right, "FOV Settings")
local TriggerGroup = uiInstance.CreateGroupbox(uiInstance.Pages["Aim"].Left, "Triggerbot Settings")

-- Группа: Базовый аим
AimGroup:AddToggle("Enable Aimbot", true, function(v)
    getgenv().AimbotSettings.Enabled = v
end)

AimGroup:AddToggle("Wall Check", true, function(v)
    getgenv().AimbotSettings.WallCheck = v
end)

AimGroup:AddToggle("Alive Check", true, function(v)
    getgenv().AimbotSettings.AliveCheck = v
end)

AimGroup:AddSlider("Smoothness", 0.01, 1, 0.15, 0.01, "", function(v)
    getgenv().AimbotSettings.Sensitivity = v
end)

AimGroup:AddToggle("180 Snap Back", true, function(v)
    getgenv().AimbotSettings.ReturnToOriginal = v
end)

AimGroup:AddSegmented("Aim Mode", { "SMART", "HEAD", "BODY" }, 1, function(opt)
    if opt == "SMART" then
        getgenv().AimbotSettings.AimPart = "Smart"
    elseif opt == "HEAD" then
        getgenv().AimbotSettings.AimPart = "Head"
    else
        getgenv().AimbotSettings.AimPart = "HumanoidRootPart"
    end
end)

AimGroup:AddSegmented("Bind Mode", { "HOLD", "TOGGLE", "ALWAYS" }, 1, function(opt)
    if opt == "HOLD" then
        getgenv().AimbotSettings.BindType = "Hold"
    elseif opt == "TOGGLE" then
        getgenv().AimbotSettings.BindType = "Toggle"
    else
        getgenv().AimbotSettings.BindType = "Always On"
    end
end)

AimGroup:AddSegmented("Trigger Key", { "R-MOUSE", "E", "F", "Q" }, 1, function(opt)
    local keys = {
        ["R-MOUSE"] = Enum.UserInputType.MouseButton2,
        ["E"] = Enum.KeyCode.E,
        ["F"] = Enum.KeyCode.F,
        ["Q"] = Enum.KeyCode.Q
    }
    getgenv().AimbotSettings.TriggerKey = keys[opt]
end)

-- Группа: FOV
FovGroup:AddToggle("Show FOV", true, function(v)
    getgenv().AimbotSettings.FOV.Visible = v
end)

FovGroup:AddSlider("FOV Radius", 10, 800, 150, 5, "px", function(v)
    getgenv().AimbotSettings.FOV.BaseRadius = v
end)

FovGroup:AddSegmented("FOV Position", { "MOUSE", "CENTER" }, 1, function(opt)
    getgenv().AimbotSettings.FOV.Type = opt
end)

FovGroup:AddSlider("Color - Red", 0, 255, 255, 1, "", function(v)
    local c = getgenv().AimbotSettings.FOV.Color
    getgenv().AimbotSettings.FOV.Color = Color3.fromRGB(v, c.G * 255, c.B * 255)
end)

FovGroup:AddSlider("Color - Green", 0, 255, 85, 1, "", function(v)
    local c = getgenv().AimbotSettings.FOV.Color
    getgenv().AimbotSettings.FOV.Color = Color3.fromRGB(c.R * 255, v, c.B * 255)
end)

FovGroup:AddSlider("Color - Blue", 0, 255, 85, 1, "", function(v)
    local c = getgenv().AimbotSettings.FOV.Color
    getgenv().AimbotSettings.FOV.Color = Color3.fromRGB(c.R * 255, c.G * 255, v)
end)

-- Группа: Triggerbot
TriggerGroup:AddToggle("Enable Triggerbot", false, function(v)
    getgenv().TriggerbotSettings.Enabled = v
end)

TriggerGroup:AddToggle("Wall Check", true, function(v)
    getgenv().TriggerbotSettings.WallCheck = v
end)

TriggerGroup:AddToggle("Alive Check", true, function(v)
    getgenv().TriggerbotSettings.AliveCheck = v
end)

TriggerGroup:AddSlider("Delay", 0, 1000, 50, 10, "ms", function(v)
    getgenv().TriggerbotSettings.Delay = v / 1000
end)

TriggerGroup:AddSegmented("Bind Mode", { "HOLD", "TOGGLE", "ALWAYS" }, 1, function(opt)
    if opt == "HOLD" then
        getgenv().TriggerbotSettings.BindType = "Hold"
    elseif opt == "TOGGLE" then
        getgenv().TriggerbotSettings.BindType = "Toggle"
    else
        getgenv().TriggerbotSettings.BindType = "Always On"
    end
end)

TriggerGroup:AddSegmented("Trigger Key", { "X", "C", "Z", "L-ALT" }, 1, function(opt)
    local keys = {
        ["X"] = Enum.KeyCode.X,
        ["C"] = Enum.KeyCode.C,
        ["Z"] = Enum.KeyCode.Z,
        ["L-ALT"] = Enum.KeyCode.LeftAlt
    }
    getgenv().TriggerbotSettings.TriggerKey = keys[opt]
end)

uiInstance.SwitchTab("Visuals", 2)
