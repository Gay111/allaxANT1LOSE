-- // src/settings.lua
local SettingsModule = {}

local function getService(name)
    local service = game:GetService(name)
    return (cloneref and cloneref(service)) or service
end

local TweenService = getService("TweenService")
local UserInputService = getService("UserInputService")
local Players = getService("Players")
local RunService = getService("RunService")
local LocalPlayer = Players.LocalPlayer

function SettingsModule.Init(screenGui)
    local Settings = {
        State = {
            -- Настройки Watermark
            watermarkEnabled = true,
            showFps = true,
            showPing = true,
            showTime = true,
            showUser = true,
            watermarkTextSize = 11,
            watermarkBgAlpha = 0.15,
            watermarkCustomTitle = "ANTILOSE",
            
            -- Настройки Feature List (Список функций / Кейбиндов)
            featureListEnabled = true,
            showOnlyActive = true,
            featureListAlpha = 0.15,
            featureListScale = 1.0,
        },
        Features = {}, -- { [id] = { Name = "Aimbot", Active = true, Mode = "HOLD [RMB]" } }
        Connections = {},
        UIElements = {}
    }

    -- ========================================================================
    -- // 1. WATERMARK HUD
    -- ========================================================================
    local WatermarkFrame = Instance.new("Frame")
    WatermarkFrame.Name = "WatermarkHUD"
    WatermarkFrame.AutomaticSize = Enum.AutomaticSize.XY
    WatermarkFrame.Position = UDim2.new(0, 20, 0, 20)
    WatermarkFrame.BackgroundColor3 = Color3.fromRGB(11, 11, 14)
    WatermarkFrame.BackgroundTransparency = Settings.State.watermarkBgAlpha
    WatermarkFrame.BorderSizePixel = 0
    WatermarkFrame.ZIndex = 10
    WatermarkFrame.Parent = screenGui

    local WmCorner = Instance.new("UICorner")
    WmCorner.CornerRadius = UDim.new(0, 6)
    WmCorner.Parent = WatermarkFrame

    local WmStroke = Instance.new("UIStroke")
    WmStroke.Thickness = 1
    WmStroke.Color = Color3.fromRGB(255, 255, 255)
    WmStroke.Parent = WatermarkFrame

    local WmStrokeGrad = Instance.new("UIGradient")
    WmStrokeGrad.Rotation = 90
    WmStrokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(180, 180, 190)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 50, 58)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(24, 24, 28))
    })
    WmStrokeGrad.Parent = WmStroke

    local WmPadding = Instance.new("UIPadding")
    WmPadding.PaddingTop = UDim.new(0, 6)
    WmPadding.PaddingBottom = UDim.new(0, 6)
    WmPadding.PaddingLeft = UDim.new(0, 12)
    WmPadding.PaddingRight = UDim.new(0, 12)
    WmPadding.Parent = WatermarkFrame

    local WmText = Instance.new("TextLabel")
    WmText.Name = "WmText"
    WmText.AutomaticSize = Enum.AutomaticSize.XY
    WmText.BackgroundTransparency = 1
    WmText.Font = Enum.Font.GothamBold
    WmText.TextSize = Settings.State.watermarkTextSize
    WmText.TextColor3 = Color3.fromRGB(235, 235, 240)
    WmText.Text = "ANTILOSE // CLIENT"
    WmText.ZIndex = 11
    WmText.Parent = WatermarkFrame

    -- Драг для Watermark
    local isDraggingWm, dragStartWm, startPosWm
    WatermarkFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingWm = true
            dragStartWm = input.Position
            startPosWm = WatermarkFrame.Position
        end
    end)

    -- ========================================================================
    -- // 2. ACTIVE / INACTIVE FEATURE LIST HUD
    -- ========================================================================
    local FeatureListFrame = Instance.new("Frame")
    FeatureListFrame.Name = "FeatureListHUD"
    FeatureListFrame.Size = UDim2.new(0, 190, 0, 30)
    FeatureListFrame.Position = UDim2.new(0, 20, 0, 70)
    FeatureListFrame.AutomaticSize = Enum.AutomaticSize.Y
    FeatureListFrame.BackgroundColor3 = Color3.fromRGB(11, 11, 14)
    FeatureListFrame.BackgroundTransparency = Settings.State.featureListAlpha
    FeatureListFrame.BorderSizePixel = 0
    FeatureListFrame.ZIndex = 10
    FeatureListFrame.Parent = screenGui

    local FlCorner = Instance.new("UICorner")
    FlCorner.CornerRadius = UDim.new(0, 6)
    FlCorner.Parent = FeatureListFrame

    local FlStroke = Instance.new("UIStroke")
    FlStroke.Thickness = 1
    FlStroke.Color = Color3.fromRGB(255, 255, 255)
    FlStroke.Parent = FeatureListFrame

    local FlStrokeGrad = Instance.new("UIGradient")
    FlStrokeGrad.Rotation = 90
    FlStrokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(180, 180, 190)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 50, 58)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(24, 24, 28))
    })
    FlStrokeGrad.Parent = FlStroke

    -- Шапка листа
    local FlHeader = Instance.new("Frame")
    FlHeader.Name = "Header"
    FlHeader.Size = UDim2.new(1, 0, 0, 26)
    FlHeader.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    FlHeader.BackgroundTransparency = 0.2
    FlHeader.BorderSizePixel = 0
    FlHeader.ZIndex = 11
    FlHeader.Parent = FeatureListFrame

    local FlHeaderCorner = Instance.new("UICorner")
    FlHeaderCorner.CornerRadius = UDim.new(0, 6)
    FlHeaderCorner.Parent = FlHeader

    local FlHeaderTitle = Instance.new("TextLabel")
    FlHeaderTitle.Size = UDim2.new(1, -16, 1, 0)
    FlHeaderTitle.Position = UDim2.new(0, 10, 0, 0)
    FlHeaderTitle.BackgroundTransparency = 1
    FlHeaderTitle.Text = "ACTIVE MODULES"
    FlHeaderTitle.TextColor3 = Color3.fromRGB(180, 180, 190)
    FlHeaderTitle.TextSize = 10
    FlHeaderTitle.Font = Enum.Font.GothamBold
    FlHeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
    FlHeaderTitle.ZIndex = 12
    FlHeaderTitle.Parent = FlHeader

    -- Контейнер элементов списка
    local FlContainer = Instance.new("Frame")
    FlContainer.Name = "Container"
    FlContainer.Size = UDim2.new(1, -16, 0, 0)
    FlContainer.Position = UDim2.new(0, 8, 0, 30)
    FlContainer.AutomaticSize = Enum.AutomaticSize.Y
    FlContainer.BackgroundTransparency = 1
    FlContainer.ZIndex = 11
    FlContainer.Parent = FeatureListFrame

    local FlLayout = Instance.new("UIListLayout")
    FlLayout.Padding = UDim.new(0, 4)
    FlLayout.SortOrder = Enum.SortOrder.LayoutOrder
    FlLayout.Parent = FlContainer

    local FlBottomPad = Instance.new("Frame")
    FlBottomPad.Size = UDim2.new(1, 0, 0, 4)
    FlBottomPad.BackgroundTransparency = 1
    FlBottomPad.LayoutOrder = 9999
    FlBottomPad.Parent = FlContainer

    -- Драг для Feature List
    local isDraggingFl, dragStartFl, startPosFl
    FlHeader.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingFl = true
            dragStartFl = input.Position
            startPosFl = FeatureListFrame.Position
        end
    end)

    -- Общий обработчик перемещения
    local moveConn = UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            if isDraggingWm then
                local delta = input.Position - dragStartWm
                WatermarkFrame.Position = UDim2.new(
                    startPosWm.X.Scale, startPosWm.X.Offset + delta.X,
                    startPosWm.Y.Scale, startPosWm.Y.Offset + delta.Y
                )
            elseif isDraggingFl then
                local delta = input.Position - dragStartFl
                FeatureListFrame.Position = UDim2.new(
                    startPosFl.X.Scale, startPosFl.X.Offset + delta.X,
                    startPosFl.Y.Scale, startPosFl.Y.Offset + delta.Y
                )
            end
        end
    end)

    local endConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingWm = false
            isDraggingFl = false
        end
    end)

    table.insert(Settings.Connections, moveConn)
    table.insert(Settings.Connections, endConn)

    -- ========================================================================
    -- // ФУНКЦИИ ОБНОВЛЕНИЯ HUD
    -- ========================================================================
    local featureRows = {}

    function Settings.UpdateFeatureListUI()
        FeatureListFrame.Visible = Settings.State.featureListEnabled
        if not Settings.State.featureListEnabled then return end

        for _, row in pairs(featureRows) do
            row:Destroy()
        end
        table.clear(featureRows)

        for id, feat in pairs(Settings.Features) do
            if not Settings.State.showOnlyActive or feat.Active then
                local Row = Instance.new("Frame")
                Row.Name = id .. "Row"
                Row.Size = UDim2.new(1, 0, 0, 18)
                Row.BackgroundTransparency = 1
                Row.ZIndex = 12
                Row.Parent = FlContainer

                local NameLabel = Instance.new("TextLabel")
                NameLabel.Size = UDim2.new(0.65, 0, 1, 0)
                NameLabel.BackgroundTransparency = 1
                NameLabel.Text = feat.Name
                NameLabel.TextColor3 = feat.Active and Color3.fromRGB(225, 225, 235) or Color3.fromRGB(110, 110, 120)
                NameLabel.TextSize = 10
                NameLabel.Font = Enum.Font.GothamMedium
                NameLabel.TextXAlignment = Enum.TextXAlignment.Left
                NameLabel.ZIndex = 13
                NameLabel.Parent = Row

                local StateBadge = Instance.new("TextLabel")
                StateBadge.Size = UDim2.new(0.35, 0, 1, 0)
                StateBadge.Position = UDim2.new(0.65, 0, 0, 0)
                StateBadge.BackgroundTransparency = 1
                StateBadge.Text = feat.Mode or (feat.Active and "ON" or "OFF")
                StateBadge.TextColor3 = feat.Active and Color3.fromRGB(130, 220, 130) or Color3.fromRGB(180, 80, 80)
                StateBadge.TextSize = 9
                StateBadge.Font = Enum.Font.GothamBold
                StateBadge.TextXAlignment = Enum.TextXAlignment.Right
                StateBadge.ZIndex = 13
                StateBadge.Parent = Row

                table.insert(featureRows, Row)
            end
        end
    end

    -- Метод обновления/добавления функции в лист
    function Settings.SetFeature(id, name, active, mode)
        Settings.Features[id] = {
            Name = name,
            Active = active,
            Mode = mode
        }
        Settings.UpdateFeatureListUI()
    end

    -- Цикл обновления телеметрии Watermark
    local lastTick = tick()
    local frames = 0
    local curFps = 60
    local curPing = 0

    local telemetryConn = RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = tick()
        if now - lastTick >= 0.5 then
            curFps = math.floor(frames / (now - lastTick))
            pcall(function()
                curPing = math.floor(LocalPlayer:GetNetworkPing() * 1000)
            end)
            frames = 0
            lastTick = now

            if Settings.State.watermarkEnabled then
                WatermarkFrame.Visible = true
                local parts = { Settings.State.watermarkCustomTitle }

                if Settings.State.showUser then
                    table.insert(parts, LocalPlayer.Name)
                end
                if Settings.State.showFps then
                    table.insert(parts, string.format("%d fps", curFps))
                end
                if Settings.State.showPing then
                    table.insert(parts, string.format("%d ms", curPing))
                end
                if Settings.State.showTime then
                    table.insert(parts, os.date("%X"))
                end

                WmText.Text = table.concat(parts, "  |  ")
            else
                WatermarkFrame.Visible = false
            end
        end
    end)

    table.insert(Settings.Connections, telemetryConn)

    -- Применение изменений прозрачности/размеров
    function Settings.ApplyStyle()
        WatermarkFrame.BackgroundTransparency = Settings.State.watermarkBgAlpha
        WmText.TextSize = Settings.State.watermarkTextSize
        FeatureListFrame.BackgroundTransparency = Settings.State.featureListAlpha
    end

    function Settings.Cleanup()
        for _, c in ipairs(Settings.Connections) do
            pcall(function() c:Disconnect() end)
        end
        if WatermarkFrame then pcall(function() WatermarkFrame:Destroy() end) end
        if FeatureListFrame then pcall(function() FeatureListFrame:Destroy() end) end
    end

    Settings.UIElements.Watermark = WatermarkFrame
    Settings.UIElements.FeatureList = FeatureListFrame

    return Settings
end

return SettingsModule
