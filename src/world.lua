-- // src/world.lua
local World = {}

local function getService(name)
    local service = game:GetService(name)
    return (cloneref and cloneref(service)) or service
end

local Players = getService("Players")
local Lighting = getService("Lighting")
local Workspace = getService("Workspace")
local RunService = getService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local MaterialMap = {
    ["NEON"] = Enum.Material.Neon,
    ["FORCEFIELD"] = Enum.Material.ForceField,
    ["GLASS"] = Enum.Material.Glass,
    ["FOIL"] = Enum.Material.Foil,
    ["PLASTIC"] = Enum.Material.SmoothPlastic
}

local ArmLimbNames = {
    ["Left Arm"] = true, ["Right Arm"] = true,
    ["LeftHand"] = true, ["RightHand"] = true,
    ["LeftLowerArm"] = true, ["RightLowerArm"] = true,
    ["LeftUpperArm"] = true, ["RightUpperArm"] = true
}

function World.Init()
    local OriginalLighting = {
        ClockTime = Lighting.ClockTime,
        Brightness = Lighting.Brightness,
        ExposureCompensation = Lighting.ExposureCompensation,
        FogStart = Lighting.FogStart,
        FogEnd = Lighting.FogEnd,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
    }
    local OriginalTransparencies = {}
    local OrigArmProps = {}
    local OrigWeaponProps = {}

    local CustomAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if not CustomAtmosphere then
        CustomAtmosphere = Instance.new("Atmosphere")
        CustomAtmosphere.Name = "AntiloseAtmosphere"
        CustomAtmosphere.Density = 0.3
        CustomAtmosphere.Parent = Lighting
    end

    local CustomColorCorrection = Lighting:FindFirstChild("AntiloseColorCorrection")
    if not CustomColorCorrection then
        CustomColorCorrection = Instance.new("ColorCorrectionEffect")
        CustomColorCorrection.Name = "AntiloseColorCorrection"
        CustomColorCorrection.Enabled = true
        CustomColorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
        CustomColorCorrection.Parent = Lighting
    end

    local state = {
        -- Освещение и карта
        mapTransparencyEnabled = false,
        mapTransparencyValue = 0.5,
        lockTimeEnabled = false,
        targetTime = Lighting.ClockTime,
        worldTintR = 255,
        worldTintG = 255,
        worldTintB = 255,

        -- Self Chams (Руки)
        armsEnabled = false,
        armsMaterial = "NEON",
        armsColorR = 255,
        armsColorG = 255,
        armsColorB = 255,
        armsTransparency = 0,

        -- Self Chams (Оружие / Предметы)
        weaponEnabled = false,
        weaponMaterial = "FORCEFIELD",
        weaponColorR = 0,
        weaponColorG = 255,
        weaponColorB = 255,
        weaponTransparency = 0
    }

    -- 1. Логика карты
    local function isPlayerDescendant(instance)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character and instance:IsDescendantOf(plr.Character) then
                return true
            end
        end
        return false
    end

    local function applyTransparency(part)
        if part:IsA("BasePart") and not part:IsA("Terrain") and not isPlayerDescendant(part) then
            if OriginalTransparencies[part] == nil then
                OriginalTransparencies[part] = part.Transparency
            end
            if state.mapTransparencyEnabled then
                part.Transparency = math.clamp(math.max(OriginalTransparencies[part], state.mapTransparencyValue), 0, 1)
            else
                part.Transparency = OriginalTransparencies[part]
            end
        end
    end

    local function updateAllMapParts()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            applyTransparency(obj)
        end
    end

    local descConn = Workspace.DescendantAdded:Connect(function(obj)
        if state.mapTransparencyEnabled then
            task.defer(function() applyTransparency(obj) end)
        end
    end)

    local timeConn = Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
        if state.lockTimeEnabled then
            Lighting.ClockTime = state.targetTime
        end
    end)

    local function updateWorldColor()
        local color = Color3.fromRGB(state.worldTintR, state.worldTintG, state.worldTintB)
        CustomColorCorrection.TintColor = color
        Lighting.Ambient = color
        Lighting.OutdoorAmbient = color
    end

    -- 2. Логика Self Chams (Arms & Weapons)
    local function isArmPart(part)
        if not part:IsA("BasePart") then return false end
        -- Персонаж игрока
        if LocalPlayer.Character and part:IsDescendantOf(LocalPlayer.Character) then
            if not part:FindFirstAncestorOfClass("Tool") and (ArmLimbNames[part.Name] or part.Name:lower():find("arm") or part.Name:lower():find("hand")) then
                return true
            end
        end
        -- Viewmodel в камере
        if part:IsDescendantOf(Camera) and part.Name ~= "Antilose_3DAwallMarker" then
            local pName = part.Name:lower()
            local parentName = part.Parent and part.Parent.Name:lower() or ""
            if pName:find("arm") or pName:find("hand") or pName:find("sleeve") or pName:find("glove") or parentName:find("arm") then
                return true
            end
        end
        return false
    end

    local function isWeaponPart(part)
        if not part:IsA("BasePart") then return false end
        -- Тулза в персонаже
        if LocalPlayer.Character and part:IsDescendantOf(LocalPlayer.Character) and part:FindFirstAncestorOfClass("Tool") then
            return true
        end
        -- Оружие во viewmodel (все части кроме рук)
        if part:IsDescendantOf(Camera) and part.Name ~= "Antilose_3DAwallMarker" and not isArmPart(part) then
            return true
        end
        return false
    end

    local chamsConn = RunService.RenderStepped:Connect(function()
        -- Руки
        if state.armsEnabled then
            local targetMat = MaterialMap[state.armsMaterial] or Enum.Material.Neon
            local targetCol = Color3.fromRGB(state.armsColorR, state.armsColorG, state.armsColorB)

            local targets = {}
            if LocalPlayer.Character then
                for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if isArmPart(p) then table.insert(targets, p) end
                end
            end
            for _, p in ipairs(Camera:GetDescendants()) do
                if isArmPart(p) then table.insert(targets, p) end
            end

            for _, part in ipairs(targets) do
                if not OrigArmProps[part] then
                    OrigArmProps[part] = {
                        Material = part.Material,
                        Color = part.Color,
                        Transparency = part.Transparency
                    }
                end
                part.Material = targetMat
                part.Color = targetCol
                part.Transparency = state.armsTransparency
            end
        else
            if next(OrigArmProps) then
                for part, props in pairs(OrigArmProps) do
                    if part and part.Parent then
                        part.Material = props.Material
                        part.Color = props.Color
                        part.Transparency = props.Transparency
                    end
                end
                table.clear(OrigArmProps)
            end
        end

        -- Оружие / Предметы
        if state.weaponEnabled then
            local targetMat = MaterialMap[state.weaponMaterial] or Enum.Material.ForceField
            local targetCol = Color3.fromRGB(state.weaponColorR, state.weaponColorG, state.weaponColorB)

            local targets = {}
            if LocalPlayer.Character then
                for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if isWeaponPart(p) then table.insert(targets, p) end
                end
            end
            for _, p in ipairs(Camera:GetDescendants()) do
                if isWeaponPart(p) then table.insert(targets, p) end
            end

            for _, part in ipairs(targets) do
                if not OrigWeaponProps[part] then
                    OrigWeaponProps[part] = {
                        Material = part.Material,
                        Color = part.Color,
                        Transparency = part.Transparency
                    }
                end
                part.Material = targetMat
                part.Color = targetCol
                part.Transparency = state.weaponTransparency
            end
        else
            if next(OrigWeaponProps) then
                for part, props in pairs(OrigWeaponProps) do
                    if part and part.Parent then
                        part.Material = props.Material
                        part.Color = props.Color
                        part.Transparency = props.Transparency
                    end
                end
                table.clear(OrigWeaponProps)
            end
        end
    end)

    local function cleanup()
        pcall(function() descConn:Disconnect() end)
        pcall(function() timeConn:Disconnect() end)
        pcall(function() chamsConn:Disconnect() end)

        if CustomAtmosphere and CustomAtmosphere.Name == "AntiloseAtmosphere" then
            CustomAtmosphere:Destroy()
        end
        if CustomColorCorrection then
            CustomColorCorrection:Destroy()
        end

        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ExposureCompensation = OriginalLighting.ExposureCompensation
        Lighting.FogStart = OriginalLighting.FogStart
        Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient

        state.mapTransparencyEnabled = false
        for part, alpha in pairs(OriginalTransparencies) do
            if part and part.Parent then part.Transparency = alpha end
        end

        for part, props in pairs(OrigArmProps) do
            if part and part.Parent then
                part.Material = props.Material
                part.Color = props.Color
                part.Transparency = props.Transparency
            end
        end

        for part, props in pairs(OrigWeaponProps) do
            if part and part.Parent then
                part.Material = props.Material
                part.Color = props.Color
                part.Transparency = props.Transparency
            end
        end
    end

    return {
        State = state,
        Atmosphere = CustomAtmosphere,
        UpdateAllMapParts = updateAllMapParts,
        UpdateWorldColor = updateWorldColor,
        Cleanup = cleanup
    }
end

return World
