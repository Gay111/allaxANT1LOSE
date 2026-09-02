-- // init.lua
if getgenv and getgenv().AntiloseLoadedInstance then
    pcall(function() getgenv().AntiloseLoadedInstance() end)
end

local BASE_URL = "https://raw.githubusercontent.com/Gay111/allaxANT1LOSE/main/src/"

local function import(modulePath)
    local source
    if readfile and isfile and isfile("src/" .. modulePath) then
        source = readfile("src/" .. modulePath)
    elseif readfile and isfile and isfile(modulePath) then
        source = readfile(modulePath)
    end
    
    if not source then
        local fullUrl = BASE_URL .. modulePath .. "?t=" .. tostring(os.time())
        local success, result = pcall(function()
            return game:HttpGet(fullUrl)
        end)
        if not success or not result or result:match("404") or result == "404: Not Found" then
            error("\n[Antilose Loader] ОШИБКА 404: Не удалось загрузить '" .. modulePath .. "' с GitHub.")
        end
        source = result
    end
    
    local func, err = loadstring(source)
    if not func then
        error("\n[Antilose Loader] СИНТАКСИЧЕСКАЯ ОШИБКА в '" .. modulePath .. "':\n" .. tostring(err))
    end
    
    local runSuccess, runResult = pcall(func)
    if not runSuccess then
        error("\n[Antilose Loader] ОШИБКА ВЫПОЛНЕНИЯ в '" .. modulePath .. "':\n" .. tostring(runResult))
    end
    
    return runResult
end

-- // Инициализация
local UI = import("ui.lua")
local Visual = import("visual.lua")
local World = import("world.lua")
local Combat = import("combat.lua")
local SettingsMod = import("settings.lua")

local uiInstance = UI.Init()
local visualInstance = Visual.Init(uiInstance.ScreenGui)
local worldInstance = World.Init()
local combatInstance = Combat.Init()
local settingsInstance = SettingsMod.Init(uiInstance.ScreenGui)

-- Синхронизация статусов с HUD
settingsInstance.SetFeature("aimbot", "Aimbot", true, "HOLD")
settingsInstance.SetFeature("triggerbot", "Triggerbot", false, "HOLD")
settingsInstance.SetFeature("awall", "Awall Checker", false, "ALWAYS")

-- ============================================================================
-- // 1. AIM
-- ============================================================================
local AimLeft = uiInstance.CreateGroupbox(uiInstance.Pages["Aim"].Left, "Aim Settings")
local AimRight = uiInstance.CreateGroupbox(uiInstance.Pages["Aim"].Right, "FOV & Automation")

local AimFeat = AimLeft:AddFeature("Aimbot Assistance", true, function(v)
    getgenv().AimbotSettings.Enabled = v
    local bindMode = getgenv().AimbotSettings.BindType or "HOLD"
    settingsInstance.SetFeature("aimbot", "Aimbot", v, string.upper(bindMode))
end)
AimFeat:AddToggle("Wall Check", true, function(v) getgenv().AimbotSettings.WallCheck = v end)
AimFeat:AddToggle("Alive Check", true, function(v) getgenv().AimbotSettings.AliveCheck = v end)
AimFeat:AddSlider("Smoothness", 0.01, 1, 0.15, 0.01, "", function(v) getgenv().AimbotSettings.Sensitivity = v end)
AimFeat:AddToggle("180 Snap Back", true, function(v) getgenv().AimbotSettings.ReturnToOriginal = v end)
AimFeat:AddSegmented("Target Bone", { "SMART", "HEAD", "BODY" }, 1, function(opt)
    if opt == "SMART" then getgenv().AimbotSettings.AimPart = "Smart"
    elseif opt == "HEAD" then getgenv().AimbotSettings.AimPart = "Head"
    else getgenv().AimbotSettings.AimPart = "HumanoidRootPart" end
end)
AimFeat:AddSegmented("Bind Mode", { "HOLD", "TOGGLE", "ALWAYS" }, 1, function(opt)
    if opt == "HOLD" then getgenv().AimbotSettings.BindType = "Hold"
    elseif opt == "TOGGLE" then getgenv().AimbotSettings.BindType = "Toggle"
    else getgenv().AimbotSettings.BindType = "Always On" end
    if getgenv().AimbotSettings.Enabled then settingsInstance.SetFeature("aimbot", "Aimbot", true, opt) end
end)
AimFeat:AddSegmented("Trigger Key", { "R-MOUSE", "E", "F", "Q" }, 1, function(opt)
    local keys = { ["R-MOUSE"] = Enum.UserInputType.MouseButton2, ["E"] = Enum.KeyCode.E, ["F"] = Enum.KeyCode.F, ["Q"] = Enum.KeyCode.Q }
    getgenv().AimbotSettings.TriggerKey = keys[opt]
end)

local FovFeat = AimRight:AddFeature("FOV Circle", true, function(v)
    getgenv().AimbotSettings.FOV.Visible = v
end)
FovFeat:AddSlider("Radius", 10, 800, 150, 5, "px", function(v) getgenv().AimbotSettings.FOV.BaseRadius = v end)
FovFeat:AddSegmented("Anchor", { "MOUSE", "CENTER" }, 1, function(opt) getgenv().AimbotSettings.FOV.Type = opt end)
FovFeat:AddSlider("Color - Red", 0, 255, 255, 1, "", function(v)
    local c = getgenv().AimbotSettings.FOV.Color
    getgenv().AimbotSettings.FOV.Color = Color3.fromRGB(v, c.G * 255, c.B * 255)
end)
FovFeat:AddSlider("Color - Green", 0, 255, 85, 1, "", function(v)
    local c = getgenv().AimbotSettings.FOV.Color
    getgenv().AimbotSettings.FOV.Color = Color3.fromRGB(c.R * 255, v, c.B * 255)
end)
FovFeat:AddSlider("Color - Blue", 0, 255, 85, 1, "", function(v)
    local c = getgenv().AimbotSettings.FOV.Color
    getgenv().AimbotSettings.FOV.Color = Color3.fromRGB(c.R * 255, c.G * 255, v)
end)

local TrigFeat = AimRight:AddFeature("Auto Triggerbot", false, function(v)
    getgenv().TriggerbotSettings.Enabled = v
    local bindMode = getgenv().TriggerbotSettings.BindType or "HOLD"
    settingsInstance.SetFeature("triggerbot", "Triggerbot", v, string.upper(bindMode))
end)
TrigFeat:AddToggle("Wall Check", true, function(v) getgenv().TriggerbotSettings.WallCheck = v end)
TrigFeat:AddToggle("Alive Check", true, function(v) getgenv().TriggerbotSettings.AliveCheck = v end)
TrigFeat:AddSlider("Delay", 0, 1000, 50, 10, "ms", function(v) getgenv().TriggerbotSettings.Delay = v / 1000 end)
TrigFeat:AddSegmented("Bind Mode", { "HOLD", "TOGGLE", "ALWAYS" }, 1, function(opt)
    if opt == "HOLD" then getgenv().TriggerbotSettings.BindType = "Hold"
    elseif opt == "TOGGLE" then getgenv().TriggerbotSettings.BindType = "Toggle"
    else getgenv().TriggerbotSettings.BindType = "Always On" end
    if getgenv().TriggerbotSettings.Enabled then settingsInstance.SetFeature("triggerbot", "Triggerbot", true, opt) end
end)
TrigFeat:AddSegmented("Trigger Key", { "X", "C", "Z", "L-ALT" }, 1, function(opt)
    local keys = { ["X"] = Enum.KeyCode.X, ["C"] = Enum.KeyCode.C, ["Z"] = Enum.KeyCode.Z, ["L-ALT"] = Enum.KeyCode.LeftAlt }
    getgenv().TriggerbotSettings.TriggerKey = keys[opt]
end)

-- ============================================================================
-- // 2. VISUALS
-- ============================================================================
local VisLeft = uiInstance.CreateGroupbox(uiInstance.Pages["Visuals"].Left, "In-World Indicators")
local VisRight = uiInstance.CreateGroupbox(uiInstance.Pages["Visuals"].Right, "3D Player Chams")

local AwallFeat = VisLeft:AddFeature("Awall Checker", false, function(v)
    visualInstance.State.awallEnabled = v
    settingsInstance.SetFeature("awall", "Awall Checker", v, "ALWAYS")
end)
AwallFeat:AddSlider("Marker Size", 0.5, 4, 1.2, 0.1, "m", function(v) visualInstance.State.awallSize = v end)
AwallFeat:AddSlider("Marker Transparency", 0, 1, 0.25, 0.05, "", function(v) visualInstance.State.markerTransparency = v end)
AwallFeat:AddSlider("Penetration Depth", 1, 20, 8, 1, "m", function(v) visualInstance.State.penetrationDepth = v end)
AwallFeat:AddSegmented("Anchor Mode", { "MOUSE", "CENTER" }, 1, function(opt) visualInstance.State.awallMode = opt end)

local ChamsFeat = VisRight:AddFeature("3D Player Chams", false, function(v)
    visualInstance.State.chamsEnabled = v
end)
ChamsFeat:AddToggle("Hide Original Skin", true, function(v) visualInstance.State.chamHideOriginal = v end)
ChamsFeat:AddToggle("Team Check", false, function(v) visualInstance.State.chamTeamCheck = v end)
ChamsFeat:AddSegmented("Material", { "PLASTIC", "NEON", "FORCEFIELD", "GLASS", "FOIL" }, 1, function(opt) visualInstance.State.chamMaterial = opt end)
ChamsFeat:AddSegmented("Color Mode", { "STATIC", "PULSE", "RAINBOW", "GRADIENT" }, 1, function(opt) visualInstance.State.chamColorMode = opt end)
ChamsFeat:AddSlider("Speed", 0.1, 5, 1.0, 0.1, "x", function(v) visualInstance.State.chamSpeed = v end)
ChamsFeat:AddSlider("Color 1 - Red", 0, 255, 0, 1, "", function(v) visualInstance.State.chamColorR = v end)
ChamsFeat:AddSlider("Color 1 - Green", 0, 255, 210, 1, "", function(v) visualInstance.State.chamColorG = v end)
ChamsFeat:AddSlider("Color 1 - Blue", 0, 255, 160, 1, "", function(v) visualInstance.State.chamColorB = v end)
ChamsFeat:AddSlider("Color 2 - Red", 0, 255, 255, 1, "", function(v) visualInstance.State.chamColor2R = v end)
ChamsFeat:AddSlider("Color 2 - Green", 0, 255, 0, 1, "", function(v) visualInstance.State.chamColor2G = v end)
ChamsFeat:AddSlider("Color 2 - Blue", 0, 255, 120, 1, "", function(v) visualInstance.State.chamColor2B = v end)
ChamsFeat:AddSlider("Transparency", 0, 1, 0.3, 0.05, "", function(v) visualInstance.State.chamTransparency = v end)

-- ============================================================================
-- // 3. WORLD
-- ============================================================================
local WorldLeft = uiInstance.CreateGroupbox(uiInstance.Pages["World"].Left, "Lighting & Viewmodel")
local WorldRight = uiInstance.CreateGroupbox(uiInstance.Pages["World"].Right, "Atmosphere & Weather")

local LightFeat = WorldLeft:AddFeature("Lighting & Time", false, function(v)
    worldInstance.State.lockTimeEnabled = v
    if v then game:GetService("Lighting").ClockTime = worldInstance.State.targetTime end
end)
LightFeat:AddSlider("Time of Day", 0, 24, math.floor(game:GetService("Lighting").ClockTime), 0.5, "h", function(v)
    worldInstance.State.targetTime = v
    game:GetService("Lighting").ClockTime = v
end)
LightFeat:AddSlider("Map Brightness", 0, 10, math.floor(game:GetService("Lighting").Brightness), 0.2, "", function(v)
    worldInstance.State.mapBrightness = v
    game:GetService("Lighting").Brightness = v
end)
LightFeat:AddSlider("Exposure", -3, 3, 0, 0.1, "", function(v)
    worldInstance.State.exposureCompensation = v
    game:GetService("Lighting").ExposureCompensation = v
end)

local CloudsFeat = WorldLeft:AddFeature("Realistic Clouds", false, function(v)
    worldInstance.State.cloudsEnabled = v
    worldInstance.UpdateClouds()
end)
CloudsFeat:AddSlider("Cover", 0, 1, 0.6, 0.05, "", function(v) worldInstance.State.cloudsCover = v worldInstance.UpdateClouds() end)
CloudsFeat:AddSlider("Density", 0, 1, 0.7, 0.05, "", function(v) worldInstance.State.cloudsDensity = v worldInstance.UpdateClouds() end)
CloudsFeat:AddSlider("Red", 0, 255, 255, 1, "", function(v) worldInstance.State.cloudsColorR = v worldInstance.UpdateClouds() end)
CloudsFeat:AddSlider("Green", 0, 255, 255, 1, "", function(v) worldInstance.State.cloudsColorG = v worldInstance.UpdateClouds() end)
CloudsFeat:AddSlider("Blue", 0, 255, 255, 1, "", function(v) worldInstance.State.cloudsColorB = v worldInstance.UpdateClouds() end)

local PostFeat = WorldLeft:AddFeature("Bloom & Blur", false, function(v)
    worldInstance.State.bloomEnabled = v
    worldInstance.UpdateBloom()
end)
PostFeat:AddSlider("Bloom Intensity", 0, 5, 1.5, 0.05, "", function(v) worldInstance.State.bloomIntensity = v worldInstance.UpdateBloom() end)
PostFeat:AddSlider("Bloom Size", 0, 56, 28, 1, "", function(v) worldInstance.State.bloomSize = v worldInstance.UpdateBloom() end)
PostFeat:AddSlider("Bloom Threshold", 0, 2, 0.3, 0.05, "", function(v) worldInstance.State.bloomThreshold = v worldInstance.UpdateBloom() end)
PostFeat:AddToggle("Motion Blur", false, function(v) worldInstance.State.motionBlurEnabled = v end)
PostFeat:AddSlider("Blur Multiplier", 0.1, 3, 1.0, 0.05, "", function(v) worldInstance.State.motionBlurMultiplier = v end)

local ArmsFeat = WorldLeft:AddFeature("Arms Material", false, function(v) worldInstance.State.armsEnabled = v end)
ArmsFeat:AddSegmented("Material", { "NEON", "FORCEFIELD", "GLASS", "FOIL", "PLASTIC" }, 1, function(opt) worldInstance.State.armsMaterial = opt end)
ArmsFeat:AddSegmented("Color Mode", { "STATIC", "PULSE", "RAINBOW", "GRADIENT" }, 1, function(opt) worldInstance.State.armsColorMode = opt end)
ArmsFeat:AddSlider("Speed", 0.1, 5, 1.0, 0.1, "x", function(v) worldInstance.State.armsSpeed = v end)
ArmsFeat:AddSlider("Color 1 - Red", 0, 255, 255, 1, "", function(v) worldInstance.State.armsColorR = v end)
ArmsFeat:AddSlider("Color 1 - Green", 0, 255, 255, 1, "", function(v) worldInstance.State.armsColorG = v end)
ArmsFeat:AddSlider("Color 1 - Blue", 0, 255, 255, 1, "", function(v) worldInstance.State.armsColorB = v end)
ArmsFeat:AddSlider("Color 2 - Red", 0, 255, 0, 1, "", function(v) worldInstance.State.armsColor2R = v end)
ArmsFeat:AddSlider("Color 2 - Green", 0, 255, 0, 1, "", function(v) worldInstance.State.armsColor2G = v end)
ArmsFeat:AddSlider("Color 2 - Blue", 0, 255, 0, 1, "", function(v) worldInstance.State.armsColor2B = v end)
ArmsFeat:AddSlider("Transparency", 0, 1, 0, 0.05, "", function(v) worldInstance.State.armsTransparency = v end)

local weatherMap = { ["NONE"] = "None", ["SNOW"] = "Snow", ["RAIN"] = "Rain", ["EMBERS"] = "Embers", ["SAKURA"] = "Sakura", ["STARS"] = "Stars" }
local WeatherFeat = WorldRight:AddFeature("Weather Particles", false, function(v)
    if not v then worldInstance.State.weather = "None" worldInstance.UpdateWeather() end
end)
WeatherFeat:AddSegmented("Type", { "NONE", "SNOW", "RAIN", "EMBERS", "SAKURA", "STARS" }, 1, function(opt)
    worldInstance.State.weather = weatherMap[opt] or "None"
    worldInstance.UpdateWeather()
end)
WeatherFeat:AddSlider("Density", 10, 300, 100, 10, "p/s", function(v) worldInstance.State.weatherDensity = v worldInstance.UpdateWeather() end)

local CinemaFeat = WorldRight:AddFeature("Cinematics (Sun & DoF)", false, function(v)
    worldInstance.State.sunRaysEnabled = v
    worldInstance.UpdateCinematics()
end)
CinemaFeat:AddSlider("Sun Rays Intensity", 0, 1, 0.3, 0.01, "", function(v) worldInstance.State.sunRaysIntensity = v worldInstance.UpdateCinematics() end)
CinemaFeat:AddToggle("Depth of Field", false, function(v) worldInstance.State.dofEnabled = v worldInstance.UpdateCinematics() end)
CinemaFeat:AddSlider("Focus Distance", 5, 100, 15, 1, "m", function(v) worldInstance.State.dofFocusDistance = v worldInstance.UpdateCinematics() end)

local WeapFeat = WorldRight:AddFeature("Weapon Material", false, function(v) worldInstance.State.weaponEnabled = v end)
WeapFeat:AddSegmented("Material", { "NEON", "FORCEFIELD", "GLASS", "FOIL", "PLASTIC" }, 2, function(opt) worldInstance.State.weaponMaterial = opt end)
WeapFeat:AddSegmented("Color Mode", { "STATIC", "PULSE", "RAINBOW", "GRADIENT" }, 1, function(opt) worldInstance.State.weaponColorMode = opt end)
WeapFeat:AddSlider("Speed", 0.1, 5, 1.0, 0.1, "x", function(v) worldInstance.State.weaponSpeed = v end)
WeapFeat:AddSlider("Color 1 - Red", 0, 255, 0, 1, "", function(v) worldInstance.State.weaponColorR = v end)
WeapFeat:AddSlider("Color 1 - Green", 0, 255, 255, 1, "", function(v) worldInstance.State.weaponColorG = v end)
WeapFeat:AddSlider("Color 1 - Blue", 0, 255, 255, 1, "", function(v) worldInstance.State.weaponColorB = v end)
WeapFeat:AddSlider("Color 2 - Red", 0, 255, 255, 1, "", function(v) worldInstance.State.weaponColor2R = v end)
WeapFeat:AddSlider("Color 2 - Green", 0, 255, 0, 1, "", function(v) worldInstance.State.weaponColor2G = v end)
WeapFeat:AddSlider("Color 2 - Blue", 0, 255, 255, 1, "", function(v) worldInstance.State.weaponColor2B = v end)
WeapFeat:AddSlider("Transparency", 0, 1, 0, 0.05, "", function(v) worldInstance.State.weaponTransparency = v end)

local AtmFeat = WorldRight:AddFeature("Color Correction & Tint", false, function(v)
    worldInstance.State.colorCorrectionEnabled = v
    worldInstance.UpdateColorCorrection()
end)
AtmFeat:AddSlider("Saturation", -1, 2, 0.35, 0.05, "", function(v) worldInstance.State.saturation = v worldInstance.UpdateColorCorrection() end)
AtmFeat:AddSlider("Contrast", -1, 2, 0.15, 0.05, "", function(v) worldInstance.State.contrast = v worldInstance.UpdateColorCorrection() end)
AtmFeat:AddSlider("Tint - Red", 0, 255, 255, 1, "", function(v) worldInstance.State.worldTintR = v worldInstance.UpdateWorldColor() end)
AtmFeat:AddSlider("Tint - Green", 0, 255, 255, 1, "", function(v) worldInstance.State.worldTintG = v worldInstance.UpdateWorldColor() end)
AtmFeat:AddSlider("Tint - Blue", 0, 255, 255, 1, "", function(v) worldInstance.State.worldTintB = v worldInstance.UpdateWorldColor() end)

local MapTransFeat = WorldRight:AddFeature("Map Transparency", false, function(v)
    worldInstance.State.mapTransparencyEnabled = v
    worldInstance.UpdateAllMapParts()
end)
MapTransFeat:AddSlider("Level", 0, 1, 0.5, 0.05, "", function(v)
    worldInstance.State.mapTransparencyValue = v
    if worldInstance.State.mapTransparencyEnabled then worldInstance.UpdateAllMapParts() end
end)

WorldRight:AddSlider("Fog Density", 0, 100, 30, 2, "%", function(v) worldInstance.SetFog(v) end)
WorldRight:AddButton("Clear All Fog", function() worldInstance.ClearFog() end)
WorldRight:AddButton("Reset World Color", function()
    worldInstance.State.worldTintR = 255
    worldInstance.State.worldTintG = 255
    worldInstance.State.worldTintB = 255
    worldInstance.UpdateWorldColor()
end)

-- ============================================================================
-- // 4. SETTINGS
-- ============================================================================
local SetLeft = uiInstance.CreateGroupbox(uiInstance.Pages["Settings"].Left, "HUD Elements")
local SetRight = uiInstance.CreateGroupbox(uiInstance.Pages["Settings"].Right, "Client Core")

local WmSettings = SetLeft:AddFeature("Watermark HUD", true, function(v)
    settingsInstance.State.watermarkEnabled = v
end)
WmSettings:AddToggle("Show FPS", true, function(v) settingsInstance.State.showFps = v end)
WmSettings:AddToggle("Show Ping", true, function(v) settingsInstance.State.showPing = v end)
WmSettings:AddToggle("Show Server Time", true, function(v) settingsInstance.State.showTime = v end)
WmSettings:AddToggle("Show Username", true, function(v) settingsInstance.State.showUser = v end)

local ListSettings = SetLeft:AddFeature("Active Modules HUD", true, function(v)
    settingsInstance.State.featureListEnabled = v
    settingsInstance.UpdateFeatureListUI()
end)
ListSettings:AddToggle("Active Only", true, function(v)
    settingsInstance.State.showOnlyActive = v
    settingsInstance.UpdateFeatureListUI()
end)

local function unloadAll()
    for _, c in ipairs(uiInstance.Connections or {}) do pcall(function() c:Disconnect() end) end
    if visualInstance and visualInstance.Cleanup then pcall(function() visualInstance.Cleanup() end) end
    if worldInstance and (worldInstance.Cleanup or worldInstance.Destroy) then pcall(function() (worldInstance.Cleanup or worldInstance.Destroy)() end) end
    if combatInstance and combatInstance.Cleanup then pcall(function() combatInstance.Cleanup() end) end
    if settingsInstance and settingsInstance.Cleanup then pcall(function() settingsInstance.Cleanup() end) end
    if uiInstance and uiInstance.ScreenGui then pcall(function() uiInstance.ScreenGui:Destroy() end) end
    if getgenv then getgenv().AntiloseLoadedInstance = nil end
end

SetRight:AddButton("Unload Interface", unloadAll)
if getgenv then getgenv().AntiloseLoadedInstance = unloadAll end

uiInstance.SwitchTab("Aim")
