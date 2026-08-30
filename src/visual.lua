--!strict
-- [ ALLAX / VISUAL MODULE ]
-- Wall Indicator with Neon Outline & Custom Transparency

local cloneref = (cloneref or function(o) return o end)
local Workspace = cloneref(game:GetService("Workspace"))
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Visual = {}
Visual.__index = Visual

-- Глобальное/локальное состояние модуля
local state = {
    enabled = true,
    mode = "CENTER", -- "CENTER" или "MOUSE"
    penetrationDepth = 8, -- глубина рейкаста
    
    -- Настройки прозрачности
    fillTransparency = 0.45,   -- Прозрачность основного маркера (0 = сплошной, 1 = невидимый)
    outlineTransparency = 0.1, -- Прозрачность неоновой обводки
    
    -- Цветовая палитра (RGB)
    colorPenetrable = Color3.fromRGB(0, 255, 170),   -- Яркий неоновый мятно-зеленый
    colorSolid      = Color3.fromRGB(255, 45, 85),    -- Яркий неоновый рубиновый/красный
    
    -- Размеры индикатора
    markerSize = Vector3.new(0.55, 0.55, 0.05)
}

-- Хранилище объектов маркера
local Indicator = {
    Container = nil :: Folder?,
    Part = nil :: Part?,
    SelectionGlow = nil :: SelectionBox?,
    RenderConnection = nil :: RBXScriptConnection?
}

-- Инициализация и создание геометрии маркера
local function createMarker()
    if Indicator.Part then
        Indicator.Part:Destroy()
    end

    -- Папка-контейнер для защиты от рейкастов
    local folder = Instance.new("Folder")
    folder.Name = "VisualIndicator_Container"
    folder.Parent = Workspace
    Indicator.Container = folder

    -- Основной 3D-парт (заливка)
    local part = Instance.new("Part")
    part.Name = "IndicatorPart"
    part.Material = Enum.Material.Neon
    part.Size = state.markerSize
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Transparency = state.fillTransparency
    part.Parent = folder
    Indicator.Part = part

    -- Неоновый контур (SelectionBox создает эффект четкой светящейся рамки)
    local glowOutline = Instance.new("SelectionBox")
    glowOutline.Name = "NeonOutline"
    glowOutline.Adornee = part
    glowOutline.LineThickness = 0.035 -- Толщина неонового канта
    glowOutline.Transparency = state.outlineTransparency
    glowOutline.Color3 = state.colorPenetrable
    glowOutline.Visible = false
    glowOutline.Parent = part
    Indicator.SelectionGlow = glowOutline
end

-- Проверка на принадлежность персонажу врага
local function isEnemyCharacter(hitInstance: Instance?): boolean
    if not hitInstance then return false end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if hitInstance:IsDescendantOf(player.Character) then
                -- Проверка на команду (если актуально)
                if player.Team == nil or player.Team ~= LocalPlayer.Team then
                    return true
                end
            end
        end
    end
    return false
end

-- Основной цикл обновления
local function onRenderStep()
    if not state.enabled or not Camera or not Indicator.Part or not Indicator.SelectionGlow then
        if Indicator.Part then
            Indicator.Part.Transparency = 1
            Indicator.SelectionGlow.Visible = false
        end
        return
    end

    -- Выбор направления луча
    local unitRay: Ray
    if state.mode == "MOUSE" then
        local mousePos = UserInputService:GetMouseLocation()
        unitRay = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    else
        local viewportCenter = Camera.ViewportSize / 2
        unitRay = Camera:ViewportPointToRay(viewportCenter.X, viewportCenter.Y)
    end

    -- Параметры первого рейкаста
    local filterList = { Indicator.Container, LocalPlayer.Character }
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = filterList
    rayParams.IgnoreWater = true

    local hit = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, rayParams)

    if hit and hit.Instance then
        local hitPos = hit.Position
        local hitNormal = hit.Normal
        local isPenetrable = false

        -- Проверяем прямое попадание во врага
        if isEnemyCharacter(hit.Instance) then
            isPenetrable = true
        else
            -- Второй рейкаст за стену (Penetration Check)
            local wallOffset = hitPos + (unitRay.Direction * 0.1)
            local penRay = Workspace:Raycast(wallOffset, unitRay.Direction * state.penetrationDepth, rayParams)

            if penRay and penRay.Instance and isEnemyCharacter(penRay.Instance) then
                isPenetrable = true
            end
        end

        -- Определение активного неонового цвета
        local targetColor = isPenetrable and state.colorPenetrable or state.colorSolid

        -- Позиционирование маркера по нормали стены со смещением (предотвращает мерцание)
        local markerCFrame = CFrame.lookAt(hitPos + (hitNormal * 0.02), hitPos + hitNormal)

        -- Обновление свойств отображения
        Indicator.Part.CFrame = markerCFrame
        Indicator.Part.Color = targetColor
        Indicator.Part.Transparency = state.fillTransparency
        
        Indicator.SelectionGlow.Color3 = targetColor
        Indicator.SelectionGlow.Transparency = state.outlineTransparency
        Indicator.SelectionGlow.Visible = true
    else
        Indicator.Part.Transparency = 1
        Indicator.SelectionGlow.Visible = false
    end
end

-- Публичные методы API
function Visual.Init()
    createMarker()
    
    if Indicator.RenderConnection then
        Indicator.RenderConnection:Disconnect()
    end
    Indicator.RenderConnection = RunService.RenderStepped:Connect(onRenderStep)
end

-- Сеттеры для привязки к интерфейсу (UI Sliders / Toggles)
function Visual.SetEnabled(val: boolean)
    state.enabled = val
end

function Visual.SetMode(val: string)
    state.mode = val
end

function Visual.SetFillTransparency(val: number)
    state.fillTransparency = math.clamp(val, 0, 1)
end

function Visual.SetOutlineTransparency(val: number)
    state.outlineTransparency = math.clamp(val, 0, 1)
end

function Visual.SetPenetrationDepth(val: number)
    state.penetrationDepth = val
end

function Visual.Destroy()
    if Indicator.RenderConnection then
        Indicator.RenderConnection:Disconnect()
        Indicator.RenderConnection = nil
    end
    if Indicator.Container then
        Indicator.Container:Destroy()
        Indicator.Container = nil
    end
end

return Visual
