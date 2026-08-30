-- // src/world.lua
local World = {}

local function getService(name)
    local service = game:GetService(name)
    return (cloneref and cloneref(service)) or service
end

local Players = getService("Players")
local Lighting = getService("Lighting")
local Workspace = getService("Workspace")
local LocalPlayer = Players.LocalPlayer

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
        mapTransparencyEnabled = false,
        mapTransparencyValue = 0.5,
        lockTimeEnabled = false,
        targetTime = Lighting.ClockTime,
        worldTintR = 255,
        worldTintG = 255,
        worldTintB = 255
    }

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

    local function cleanup()
        pcall(function() descConn:Disconnect() end)
        pcall(function() timeConn:Disconnect() end)

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
