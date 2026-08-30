-- // init.lua
if getgenv and getgenv().AntiloseLoadedInstance then
    pcall(function() getgenv().AntiloseLoadedInstance() end)
end

-- Твой репозиторий на GitHub
local BASE_URL = "https://raw.githubusercontent.com/Gay111/allaxANT1LOSE/main/src/"

local function import(modulePath)
    local fullUrl = BASE_URL .. modulePath
    local source = game:HttpGet(fullUrl)
    return loadstring(source)()
end

-- Загрузка модулей
local UI = import("ui.lua")
local Visual = import("visual.lua")
local World = import("world.lua")

local uiInstance = UI.Init()
local visualInstance = Visual.Init(uiInstance.ScreenGui)
local worldInstance = World.Init()

-- ============================================================================
-- // ВКЛАДКА: VISUALS (3D In-World Awall Checker)
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

-- ============================================================================
-- // ВКЛАДКА: WORLD (Свет, Карта, Self Chams Рук и Оружия)
-- ============================================================================

-- Левая колонка: Свет и Self Arms Material
local WorldLight = uiInstance.CreateGroupbox(uiInstance.Pages["World"].Left, "Lighting & Time")

WorldLight:AddSlider("Time of Day", 0, 24, math.floor(game:GetService("Lighting").ClockTime), 0.5, "h", function(v)
    worldInstance.State.targetTime = v
    game:GetService("Lighting").ClockTime = v
end)

WorldLight:AddToggle("Lock Time of Day", false, function(v)
    worldInstance.State.lockTimeEnabled = v
    if v then game:GetService("Lighting").ClockTime = worldInstance.State.targetTime end
end)

WorldLight:AddSlider("Map Brightness", 0, 10, math.floor(game:GetService("Lighting").Brightness), 0.2, "", function(v)
    game:GetService("Lighting").Brightness = v
end)

WorldLight:AddSlider("Exposure Compensation", -3, 3, 0, 0.1, "", function(v)
    game:GetService("Lighting").ExposureCompensation = v
end)

local ArmsGroup = uiInstance.CreateGroupbox(uiInstance.Pages["World"].Left, "Self Arms Material")

ArmsGroup:AddToggle("Enable Arms Chams", false, function(v)
    worldInstance.State.armsEnabled = v
end)

ArmsGroup:AddSegmented("Material", { "NEON", "FORCEFIELD", "GLASS", "FOIL", "PLASTIC" }, 1, function(opt)
    worldInstance.State.armsMaterial = opt
end)

ArmsGroup:AddSlider("Color - Red", 0, 255, 255, 1, "", function(v)
    worldInstance.State.armsColorR = v
end)

ArmsGroup:AddSlider("Color - Green", 0, 255, 255, 1, "", function(v)
    worldInstance.State.armsColorG = v
end)

ArmsGroup:AddSlider("Color - Blue", 0, 255, 255, 1, "", function(v)
    worldInstance.State.armsColorB = v
end)

ArmsGroup:AddSlider("Transparency", 0, 1, 0, 0.05, "", function(v)
    worldInstance.State.armsTransparency = v
end)

-- Правая колонка: Оружие / Предметы и Атмосфера
local WeaponGroup = uiInstance.CreateGroupbox(uiInstance.Pages["World"].Right, "Held Item / Weapon Material")

WeaponGroup:AddToggle("Enable Weapon Chams", false, function(v)
    worldInstance.State.weaponEnabled = v
end)

WeaponGroup:AddSegmented("Material", { "NEON", "FORCEFIELD", "GLASS", "FOIL", "PLASTIC" }, 2, function(opt)
    worldInstance.State.weaponMaterial = opt
end)

WeaponGroup:AddSlider("Color - Red", 0, 255, 0, 1, "", function(v)
    worldInstance.State.weaponColorR = v
end)

WeaponGroup:AddSlider("Color - Green", 0, 255, 255, 1, "", function(v)
    worldInstance.State.weaponColorG = v
end)

WeaponGroup:AddSlider("Color - Blue", 0, 255, 255, 1, "", function(v)
    worldInstance.State.weaponColorB = v
end)

WeaponGroup:AddSlider("Transparency", 0, 1, 0, 0.05, "", function(v)
    worldInstance.State.weaponTransparency = v
end)

local WorldAtm = uiInstance.CreateGroupbox(uiInstance.Pages["World"].Right, "World Tint & Atmosphere")

WorldAtm:AddSlider("Tint - Red", 0, 255, 255, 1, "", function(v)
    worldInstance.State.worldTintR = v
    worldInstance.UpdateWorldColor()
end)

WorldAtm:AddSlider("Tint - Green", 0, 255, 255, 1, "", function(v)
    worldInstance.State.worldTintG = v
    worldInstance.UpdateWorldColor()
end)

WorldAtm:AddSlider("Tint - Blue", 0, 255, 255, 1, "", function(v)
    worldInstance.State.worldTintB = v
    worldInstance.UpdateWorldColor()
end)

WorldAtm:AddButton("Reset World Color", function()
    worldInstance.State.worldTintR, worldInstance.State.worldTintG, worldInstance.State.worldTintB = 255, 255, 255
    worldInstance.UpdateWorldColor()
end)

WorldAtm:AddSlider("Fog Density", 0, 100, 30, 2, "%", function(v)
    worldInstance.Atmosphere.Density = v / 100
    worldInstance.Atmosphere.Haze = (v / 100) * 2
    game:GetService("Lighting").FogEnd = math.clamp(5000 - (v * 45), 100, 10000)
end)

WorldAtm:AddButton("Clear All Fog", function()
    worldInstance.Atmosphere.Density = 0
    worldInstance.Atmosphere.Haze = 0
    game:GetService("Lighting").FogStart = 0
    game:GetService("Lighting").FogEnd = 10000000
end)

WorldAtm:AddToggle("Map Transparency", false, function(v)
    worldInstance.State.mapTransparencyEnabled = v
    worldInstance.UpdateAllMapParts()
end)

WorldAtm:AddSlider("Transparency Level", 0, 1, 0.5, 0.05, "", function(v)
    worldInstance.State.mapTransparencyValue = v
    if worldInstance.State.mapTransparencyEnabled then
        worldInstance.UpdateAllMapParts()
    end
end)

-- ============================================================================
-- // ВКЛАДКА: SETTINGS (Выгрузка)
-- ============================================================================
local SetGroup = uiInstance.CreateGroupbox(uiInstance.Pages["Settings"].Left, "Client Core")

local function unloadAll()
    for _, c in ipairs(uiInstance.Connections) do pcall(function() c:Disconnect() end) end
    visualInstance.Cleanup()
    worldInstance.Cleanup()
    uiInstance.ScreenGui:Destroy()
    if getgenv then getgenv().AntiloseLoadedInstance = nil end
end

SetGroup:AddButton("Unload Interface", unloadAll)
if getgenv then getgenv().AntiloseLoadedInstance = unloadAll end

-- ============================================================================
-- // ВКЛАДКА: AIM
-- ============================================================================
local AimGroup = uiInstance.CreateGroupbox(uiInstance.Pages["Aim"].Left, "Aim Modules")
AimGroup:AddToggle("Feature In Development", false, function() end)

-- Открываем вкладку World по умолчанию
uiInstance.SwitchTab("World", 3)
