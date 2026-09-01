--!strict
-- [ allaxANT1LOSE ] Visual Module with Animated Player Chams & Awall Indicator
local Visual = {}

-- // Сервисы
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")

-- // Таблица состояния
Visual.State = {
    -- Awall Indicator
    awallEnabled = false,
    awallSize = 1.2,
    markerTransparency = 0.25,
    penetrationDepth = 8,
    awallMode = "MOUSE", -- "MOUSE", "CENTER"

    -- 3D Player Chams (CS2)
    chamsEnabled = false,
    chamHideOriginal = true,
    chamTeamCheck = false,
    chamMaterial = "PLASTIC",
    chamColorMode = "STATIC", -- "STATIC", "PULSE", "RAINBOW", "GRADIENT"
    chamSpeed = 1.0,
    chamColorR = 0,
    chamColorG = 210,
    chamColorB = 160,
    chamColor2R = 255,
    chamColor2G = 0,
    chamColor2B = 120,
    chamTransparency = 0.3,
}

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
    return Enum.Material.Plastic
end

-- // Калькулятор динамического цвета
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

-- // Внутреннее хранилище
local connections = {}
local originalPartsData = {}
local hiddenElements = {}
local awallMarker = nil

-- // Инициализация маркера Awall
local function createAwallMarker()
    local marker = Instance.new("Part")
    marker.Name = "_allax_AwallMarker"
    marker.Shape = Enum.PartType.Ball
    marker.Material = Enum.Material.Neon
    marker.Color = Color3.fromRGB(255, 50, 50)
    marker.Transparency = 0.25
    marker.CanCollide = false
    marker.CanTouch = false
    marker.CanQuery = false
    marker.CastShadow = false
    marker.Anchored = true
    marker.Size = Vector3.new(1.2, 1.2, 1.2)
    marker.Parent = Workspace
    awallMarker = marker
end

-- // Восстановление оригинального вида персонажей при выключении
local function restoreCharacters()
    for part, data in pairs(originalPartsData) do
        if part and part.Parent then
            pcall(function()
                part.Material = data.Material
                part.Color = data.Color
                part.Transparency = data.Transparency
            end)
        end
    end
    table.clear(originalPartsData)

    for item, propData in pairs(hiddenElements) do
        if item and item.Parent then
            pcall(function()
                for prop, val in pairs(propData) do
                    (item :: any)[prop] = val
                end
            end)
        end
    end
    table.clear(hiddenElements)
end

-- // Инициализация модуля
function Visual.Init(screenGui: ScreenGui?)
    createAwallMarker()

    -- ========================================================================
    -- // RenderStepped: Awall Indicator & Player 3D Chams
    -- ========================================================================
    table.insert(connections, RunService.RenderStepped:Connect(function()
        local curCam = Workspace.CurrentCamera or Camera
        if not curCam then return end

        -- 1. Логика Awall Indicator
        if awallMarker then
            if not Visual.State.awallEnabled then
                awallMarker.Transparency = 1
            else
                local origin = curCam.CFrame.Position
                local direction = curCam.CFrame.LookVector * 500

                if Visual.State.awallMode == "MOUSE" then
                    local mousePos = UserInputService:GetMouseLocation()
                    local ray = curCam:ViewportPointToRay(mousePos.X, mousePos.Y)
                    origin = ray.Origin
                    direction = ray.Direction * 500
                end

                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                rayParams.FilterDescendantsInstances = { LocalPlayer.Character, awallMarker, curCam }

                local rayResult = Workspace:Raycast(origin, direction, rayParams)
                if rayResult then
                    local penParams = RaycastParams.new()
                    penParams.FilterType = Enum.RaycastFilterType.Exclude
                    penParams.FilterDescendantsInstances = { LocalPlayer.Character, awallMarker, curCam }

                    local deepOrigin = rayResult.Position + (direction.Unit * Visual.State.penetrationDepth)
                    local penResult = Workspace:Raycast(deepOrigin, -direction.Unit * Visual.State.penetrationDepth, penParams)

                    awallMarker.CFrame = CFrame.new(rayResult.Position)
                    local size = tonumber(Visual.State.awallSize) or 1.2
                    awallMarker.Size = Vector3.new(size, size, size)
                    awallMarker.Transparency = tonumber(Visual.State.markerTransparency) or 0.25

                    if penResult and (penResult.Position - rayResult.Position).Magnitude <= Visual.State.penetrationDepth then
                        awallMarker.Color = Color3.fromRGB(50, 255, 50) -- Пробиваемо
                    else
                        awallMarker.Color = Color3.fromRGB(255, 50, 50) -- Не пробиваемо
                    end
                else
                    awallMarker.Transparency = 1
                end
            end
        end

        -- 2. Логика 3D Player Chams
        if not Visual.State.chamsEnabled then
            if next(originalPartsData) ~= nil or next(hiddenElements) ~= nil then
                restoreCharacters()
            end
            return
        end

        local mat = parseMaterial(Visual.State.chamMaterial)
        local col1 = Color3.fromRGB(Visual.State.chamColorR, Visual.State.chamColorG, Visual.State.chamColorB)
        local col2 = Color3.fromRGB(Visual.State.chamColor2R or 0, Visual.State.chamColor2G or 0, Visual.State.chamColor2B or 0)
        local mode = tostring(Visual.State.chamColorMode or "STATIC"):upper()
        local speed = tonumber(Visual.State.chamSpeed) or 1.0
        local trans = tonumber(Visual.State.chamTransparency) or 0.3

        local partIndex = 0

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local char = player.Character
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                local isAlive = humanoid and humanoid.Health > 0

                -- Team Check
                local isTeammate = false
                if Visual.State.chamTeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                    isTeammate = true
                end

                if isAlive and not isTeammate then
                    -- Скрытие одежды и наклеек при необходимости
                    if Visual.State.chamHideOriginal then
                        for _, item in ipairs(char:GetChildren()) do
                            if item:IsA("Clothing") or item:IsA("ShirtGraphic") then
                                if not hiddenElements[item] then
                                    hiddenElements[item] = { Parent = item.Parent }
                                    item.Parent = nil
                                end
                            elseif item:IsA("Accessory") then
                                local handle = item:FindFirstChild("Handle")
                                if handle and handle:IsA("BasePart") then
                                    if not hiddenElements[handle] then
                                        hiddenElements[handle] = { Transparency = handle.Transparency }
                                    end
                                    handle.Transparency = 1
                                end
                            end
                        end
                    end

                    -- Покраска всех частей тела игрока
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            partIndex = partIndex + 1

                            if not originalPartsData[part] then
                                originalPartsData[part] = {
                                    Material = part.Material,
                                    Color = part.Color,
                                    Transparency = part.Transparency
                                }
                            end

                            local dynamicChamColor = getDynamicColor(mode, col1, col2, speed, partIndex)

                            pcall(function()
                                part.Material = mat
                                part.Color = dynamicChamColor
                                part.Transparency = trans
                            end)
                        end
                    end
                end
            end
        end
    end))

    return Visual
end

-- // Очистка модуля
function Visual.Cleanup()
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)

    restoreCharacters()

    if awallMarker and awallMarker.Parent then
        pcall(function() awallMarker:Destroy() end)
    end
end

Visual.Destroy = Visual.Cleanup

return Visual
