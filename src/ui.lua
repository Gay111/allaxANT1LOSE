-- // src/ui.lua
-- Minimalist Executive UI Engine with Nested Feature Drawers

local UI = {}

local function getService(name)
    local service = game:GetService(name)
    return (cloneref and cloneref(service)) or service
end

local TweenService = getService("TweenService")
local UserInputService = getService("UserInputService")
local Players = getService("Players")
local CoreGui = getService("CoreGui")
local RunService = getService("RunService")
local LocalPlayer = Players.LocalPlayer

local function getContainer()
    if gethui then return gethui() end
    if CoreGui and pcall(function() return CoreGui:GetChildren() end) then return CoreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- // Цветовая палитра (Minimal Dark Slate)
local Theme = {
    WindowBg       = Color3.fromRGB(13, 14, 17),
    WindowBorder   = Color3.fromRGB(25, 27, 34),
    HeaderBg       = Color3.fromRGB(16, 17, 21),
    HeaderBorder   = Color3.fromRGB(24, 26, 32),
    DockBg         = Color3.fromRGB(15, 16, 20),
    DockBorder     = Color3.fromRGB(24, 26, 33),
    DockActive     = Color3.fromRGB(24, 26, 33),
    CardBg         = Color3.fromRGB(18, 19, 24),
    CardBorder     = Color3.fromRGB(28, 30, 38),
    CardHover      = Color3.fromRGB(22, 23, 29),
    DrawerBg       = Color3.fromRGB(12, 13, 16),
    DrawerBorder   = Color3.fromRGB(22, 24, 30),
    TextPrimary    = Color3.fromRGB(240, 240, 245),
    TextMuted      = Color3.fromRGB(120, 122, 135),
    TextDark       = Color3.fromRGB(75, 78, 90),
    AccentWhite    = Color3.fromRGB(255, 255, 255),
    ToggleOff      = Color3.fromRGB(30, 32, 40),
    ToggleOffThumb = Color3.fromRGB(80, 83, 98),
    SliderTrack    = Color3.fromRGB(25, 27, 34),
    ButtonBg       = Color3.fromRGB(22, 24, 30),
    ButtonBorder   = Color3.fromRGB(32, 35, 45),
}

function UI.Init()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AntiloseClient"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = getContainer()

    local Window = Instance.new("Frame")
    Window.Name = "MainWindow"
    Window.Size = UDim2.new(0, 680, 0, 490)
    Window.Position = UDim2.new(0.5, -340, 0.5, -245)
    Window.BackgroundColor3 = Theme.WindowBg
    Window.BorderSizePixel = 0
    Window.ClipsDescendants = false
    Window.Parent = ScreenGui

    local WindowCorner = Instance.new("UICorner")
    WindowCorner.CornerRadius = UDim.new(0, 7)
    WindowCorner.Parent = Window

    local WindowStroke = Instance.new("UIStroke")
    WindowStroke.Thickness = 1
    WindowStroke.Color = Theme.WindowBorder
    WindowStroke.Parent = Window

    -- Элегантная 9-slice тень без спама 6 прозрачными фреймами
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 3)
    Shadow.Size = UDim2.new(1, 40, 1, 40)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://6014261993"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.4
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    Shadow.ZIndex = 0
    Shadow.Parent = Window

    -- ========================================================================
    -- // HEADER
    -- ========================================================================
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 38)
    Header.BackgroundColor3 = Theme.HeaderBg
    Header.BorderSizePixel = 0
    Header.ZIndex = 3
    Header.Parent = Window

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 7)
    HeaderCorner.Parent = Header

    local HeaderCover = Instance.new("Frame")
    HeaderCover.Size = UDim2.new(1, 0, 0, 8)
    HeaderCover.Position = UDim2.new(0, 0, 1, -8)
    HeaderCover.BackgroundColor3 = Theme.HeaderBg
    HeaderCover.BorderSizePixel = 0
    HeaderCover.ZIndex = 3
    HeaderCover.Parent = Header

    local HeaderLine = Instance.new("Frame")
    HeaderLine.Size = UDim2.new(1, 0, 0, 1)
    HeaderLine.Position = UDim2.new(0, 0, 1, 0)
    HeaderLine.BackgroundColor3 = Theme.HeaderBorder
    HeaderLine.BorderSizePixel = 0
    HeaderLine.ZIndex = 4
    HeaderLine.Parent = Header

    local Brand = Instance.new("TextLabel")
    Brand.Size = UDim2.new(0, 200, 1, 0)
    Brand.Position = UDim2.new(0, 14, 0, 0)
    Brand.BackgroundTransparency = 1
    Brand.Text = "ANTILOSE"
    Brand.TextColor3 = Theme.TextPrimary
    Brand.TextSize = 12
    Brand.Font = Enum.Font.GothamBold
    Brand.TextXAlignment = Enum.TextXAlignment.Left
    Brand.ZIndex = 5
    Brand.Parent = Header

    local BrandBadge = Instance.new("TextLabel")
    BrandBadge.Size = UDim2.new(0, 80, 1, 0)
    BrandBadge.Position = UDim2.new(0, 82, 0, 0)
    BrandBadge.BackgroundTransparency = 1
    BrandBadge.Text = "// CLIENT"
    BrandBadge.TextColor3 = Theme.TextMuted
    BrandBadge.TextSize = 10
    BrandBadge.Font = Enum.Font.GothamMedium
    BrandBadge.TextXAlignment = Enum.TextXAlignment.Left
    BrandBadge.ZIndex = 5
    BrandBadge.Parent = Header

    local Telemetry = Instance.new("TextLabel")
    Telemetry.Size = UDim2.new(0, 200, 1, 0)
    Telemetry.Position = UDim2.new(1, -214, 0, 0)
    Telemetry.BackgroundTransparency = 1
    Telemetry.Text = "FPS: 60  |  PING: 0ms"
    Telemetry.TextColor3 = Theme.TextMuted
    Telemetry.TextSize = 10
    Telemetry.Font = Enum.Font.GothamMedium
    Telemetry.TextXAlignment = Enum.TextXAlignment.Right
    Telemetry.ZIndex = 5
    Telemetry.Parent = Header

    local lastTime = tick()
    local frameCount = 0
    local fpsConn = RunService.RenderStepped:Connect(function()
        if not ScreenGui.Parent then return end
        frameCount = frameCount + 1
        local now = tick()
        if now - lastTime >= 0.5 then
            local fps = math.floor(frameCount / (now - lastTime))
            local ping = 0
            pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
            Telemetry.Text = string.format("FPS: %d  |  PING: %dms", fps, ping)
            frameCount = 0
            lastTime = now
        end
    end)

    -- Перетаскивание
    local isDragging, dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            dragStart = input.Position
            startPos = Window.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)

    -- ========================================================================
    -- // CONTENT AREA & BOTTOM DOCK
    -- ========================================================================
    local Content = Instance.new("Frame")
    Content.Name = "ContentArea"
    Content.Size = UDim2.new(1, -24, 1, -104)
    Content.Position = UDim2.new(0, 12, 0, 48)
    Content.BackgroundTransparency = 1
    Content.ZIndex = 3
    Content.Parent = Window

    local Dock = Instance.new("Frame")
    Dock.Name = "BottomDock"
    Dock.Size = UDim2.new(1, -24, 0, 42)
    Dock.Position = UDim2.new(0, 12, 1, -50)
    Dock.BackgroundColor3 = Theme.DockBg
    Dock.BorderSizePixel = 0
    Dock.ZIndex = 3
    Dock.Parent = Window

    local DockCorner = Instance.new("UICorner")
    DockCorner.CornerRadius = UDim.new(0, 6)
    DockCorner.Parent = Dock

    local DockStroke = Instance.new("UIStroke")
    DockStroke.Thickness = 1
    DockStroke.Color = Theme.DockBorder
    DockStroke.Parent = Dock

    -- Индикатор активной вкладки
    local ActiveIndicator = Instance.new("Frame")
    ActiveIndicator.Name = "ActiveIndicator"
    ActiveIndicator.Size = UDim2.new(0, 158, 0, 32)
    ActiveIndicator.Position = UDim2.new(0, 5, 0.5, -16)
    ActiveIndicator.BackgroundColor3 = Theme.DockActive
    ActiveIndicator.BorderSizePixel = 0
    ActiveIndicator.ZIndex = 4
    ActiveIndicator.Parent = Dock

    local IndCorner = Instance.new("UICorner")
    IndCorner.CornerRadius = UDim.new(0, 5)
    IndCorner.Parent = ActiveIndicator

    local IndStroke = Instance.new("UIStroke")
    IndStroke.Thickness = 1
    IndStroke.Color = Color3.fromRGB(38, 41, 52)
    IndStroke.Parent = ActiveIndicator

    local TabDefinitions = {
        { Name = "Aim", Icon = "100486500105972" },
        { Name = "Visuals", Icon = "6523858422" },
        { Name = "World", Icon = "11887653913" },
        { Name = "Settings", Icon = "7059346386" },
    }

    local Pages = {}
    local TabButtons = {}
    local CurrentTab = nil

    local function SwitchTab(tabName, targetIndex)
        if CurrentTab == tabName then return end
        CurrentTab = tabName

        local targetX = 5 + ((targetIndex - 1) * (158 + 6))
        TweenService:Create(ActiveIndicator, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, targetX, 0.5, -16)
        }):Play()

        for name, pageData in pairs(Pages) do
            local isTarget = (name == tabName)
            pageData.Root.Visible = isTarget
            if isTarget then
                pageData.Root.Position = UDim2.new(0, 0, 0, 3)
                TweenService:Create(pageData.Root, TweenInfo.new(0.18, Enum.EasingStyle.Quart), { Position = UDim2.new(0, 0, 0, 0) }):Play()
            end
        end

        for name, tab in pairs(TabButtons) do
            local active = (name == tabName)
            local iconColor = active and Theme.AccentWhite or Theme.TextMuted
            local textColor = active and Theme.TextPrimary or Theme.TextDark
            TweenService:Create(tab.Icon, TweenInfo.new(0.18), { ImageColor3 = iconColor }):Play()
            TweenService:Create(tab.Label, TweenInfo.new(0.18), { TextColor3 = textColor }):Play()
        end
    end

    for index, def in ipairs(TabDefinitions) do
        local Page = Instance.new("Frame")
        Page.Name = def.Name .. "Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.Visible = false
        Page.ZIndex = 3
        Page.Parent = Content

        local LeftCol = Instance.new("ScrollingFrame")
        LeftCol.Name = "LeftColumn"
        LeftCol.Size = UDim2.new(0.5, -6, 1, 0)
        LeftCol.BackgroundTransparency = 1
        LeftCol.BorderSizePixel = 0
        LeftCol.ScrollBarThickness = 2
        LeftCol.ScrollBarImageColor3 = Theme.WindowBorder
        LeftCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
        LeftCol.CanvasSize = UDim2.new(0, 0, 0, 0)
        LeftCol.Parent = Page

        local LeftLayout = Instance.new("UIListLayout")
        LeftLayout.Padding = UDim.new(0, 8)
        LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
        LeftLayout.Parent = LeftCol

        local RightCol = Instance.new("ScrollingFrame")
        RightCol.Name = "RightColumn"
        RightCol.Size = UDim2.new(0.5, -6, 1, 0)
        RightCol.Position = UDim2.new(0.5, 6, 0, 0)
        RightCol.BackgroundTransparency = 1
        RightCol.BorderSizePixel = 0
        RightCol.ScrollBarThickness = 2
        RightCol.ScrollBarImageColor3 = Theme.WindowBorder
        RightCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
        RightCol.CanvasSize = UDim2.new(0, 0, 0, 0)
        RightCol.Parent = Page

        local RightLayout = Instance.new("UIListLayout")
        RightLayout.Padding = UDim.new(0, 8)
        RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
        RightLayout.Parent = RightCol

        Pages[def.Name] = { Root = Page, Left = LeftCol, Right = RightCol }

        local TabBtn = Instance.new("Frame")
        TabBtn.Name = def.Name .. "Tab"
        TabBtn.Size = UDim2.new(0, 158, 0, 32)
        TabBtn.Position = UDim2.new(0, 5 + ((index - 1) * (158 + 6)), 0.5, -16)
        TabBtn.BackgroundTransparency = 1
        TabBtn.ZIndex = 5
        TabBtn.Parent = Dock

        local Icon = Instance.new("ImageLabel")
        Icon.Name = "Icon"
        Icon.Size = UDim2.new(0, 15, 0, 15)
        Icon.Position = UDim2.new(0, 14, 0.5, -7)
        Icon.BackgroundTransparency = 1
        Icon.Image = string.format("rbxthumb://type=Asset&id=%s&w=420&h=420", def.Icon)
        Icon.ImageColor3 = Theme.TextMuted
        Icon.ZIndex = 6
        Icon.Parent = TabBtn

        local Label = Instance.new("TextLabel")
        Label.Name = "Label"
        Label.Size = UDim2.new(1, -40, 1, 0)
        Label.Position = UDim2.new(0, 38, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = string.upper(def.Name)
        Label.TextColor3 = Theme.TextDark
        Label.TextSize = 10
        Label.Font = Enum.Font.GothamBold
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.ZIndex = 6
        Label.Parent = TabBtn

        local Trigger = Instance.new("TextButton")
        Trigger.Size = UDim2.new(1, 0, 1, 0)
        Trigger.BackgroundTransparency = 1
        Trigger.Text = ""
        Trigger.ZIndex = 7
        Trigger.Parent = TabBtn

        TabButtons[def.Name] = { Frame = TabBtn, Icon = Icon, Label = Label }

        Trigger.MouseButton1Click:Connect(function()
            SwitchTab(def.Name, index)
        end)
    end

    -- ========================================================================
    -- // HELPER: Генератор вложенных элементов настроек
    -- ========================================================================
    local function populateSettingsContainer(container)
        local methods = {}

        -- Sub-Toggle
        function methods:AddToggle(toggleTitle, default, callback)
            local state = default or false

            local Item = Instance.new("Frame")
            Item.Size = UDim2.new(1, 0, 0, 24)
            Item.BackgroundTransparency = 1
            Item.ZIndex = 6
            Item.Parent = container

            local CheckBox = Instance.new("Frame")
            CheckBox.Size = UDim2.new(0, 14, 0, 14)
            CheckBox.Position = UDim2.new(0, 2, 0.5, -7)
            CheckBox.BackgroundColor3 = state and Theme.AccentWhite or Color3.fromRGB(20, 21, 27)
            CheckBox.BorderSizePixel = 0
            CheckBox.ZIndex = 7
            CheckBox.Parent = Item

            local Corner = Instance.new("UICorner")
            Corner.CornerRadius = UDim.new(0, 3)
            Corner.Parent = CheckBox

            local Stroke = Instance.new("UIStroke")
            Stroke.Thickness = 1
            Stroke.Color = state and Theme.AccentWhite or Theme.CardBorder
            Stroke.Parent = CheckBox

            local Dot = Instance.new("Frame")
            Dot.Size = UDim2.new(0, 6, 0, 6)
            Dot.Position = UDim2.new(0.5, -3, 0.5, -3)
            Dot.BackgroundColor3 = Color3.fromRGB(15, 16, 20)
            Dot.BackgroundTransparency = state and 0 or 1
            Dot.BorderSizePixel = 0
            Dot.ZIndex = 8
            Dot.Parent = CheckBox

            local DotCorner = Instance.new("UICorner")
            DotCorner.CornerRadius = UDim.new(0, 1)
            DotCorner.Parent = Dot

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -26, 1, 0)
            Label.Position = UDim2.new(0, 26, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = toggleTitle
            Label.TextColor3 = state and Theme.TextPrimary or Theme.TextMuted
            Label.TextSize = 10.5
            Label.Font = Enum.Font.GothamMedium
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.ZIndex = 7
            Label.Parent = Item

            local Trigger = Instance.new("TextButton")
            Trigger.Size = UDim2.new(1, 0, 1, 0)
            Trigger.BackgroundTransparency = 1
            Trigger.Text = ""
            Trigger.ZIndex = 9
            Trigger.Parent = Item

            Trigger.MouseButton1Click:Connect(function()
                state = not state
                TweenService:Create(CheckBox, TweenInfo.new(0.15), {
                    BackgroundColor3 = state and Theme.AccentWhite or Color3.fromRGB(20, 21, 27)
                }):Play()
                TweenService:Create(Stroke, TweenInfo.new(0.15), {
                    Color = state and Theme.AccentWhite or Theme.CardBorder
                }):Play()
                TweenService:Create(Dot, TweenInfo.new(0.15), {
                    BackgroundTransparency = state and 0 or 1
                }):Play()
                TweenService:Create(Label, TweenInfo.new(0.15), {
                    TextColor3 = state and Theme.TextPrimary or Theme.TextMuted
                }):Play()

                if callback then task.spawn(callback, state) end
            end)
        end

        -- Sub-Slider
        function methods:AddSlider(sliderTitle, min, max, default, step, suffix, callback)
            local value = default or min
            step = step or 1
            suffix = suffix or ""

            local Item = Instance.new("Frame")
            Item.Size = UDim2.new(1, 0, 0, 30)
            Item.BackgroundTransparency = 1
            Item.ZIndex = 6
            Item.Parent = container

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Size = UDim2.new(1, -60, 0, 14)
            TitleLabel.Position = UDim2.new(0, 2, 0, 0)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Text = sliderTitle
            TitleLabel.TextColor3 = Theme.TextMuted
            TitleLabel.TextSize = 10
            TitleLabel.Font = Enum.Font.GothamMedium
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.ZIndex = 7
            TitleLabel.Parent = Item

            local ValLabel = Instance.new("TextLabel")
            ValLabel.Size = UDim2.new(0, 60, 0, 14)
            ValLabel.Position = UDim2.new(1, -62, 0, 0)
            ValLabel.BackgroundTransparency = 1
            ValLabel.Text = tostring(value) .. suffix
            ValLabel.TextColor3 = Theme.TextPrimary
            ValLabel.TextSize = 10
            ValLabel.Font = Enum.Font.GothamBold
            ValLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValLabel.ZIndex = 7
            ValLabel.Parent = Item

            local Track = Instance.new("Frame")
            Track.Size = UDim2.new(1, -4, 0, 4)
            Track.Position = UDim2.new(0, 2, 0, 19)
            Track.BackgroundColor3 = Theme.SliderTrack
            Track.BorderSizePixel = 0
            Track.ZIndex = 7
            Track.Parent = Item

            local TrackCorner = Instance.new("UICorner")
            TrackCorner.CornerRadius = UDim.new(1, 0)
            TrackCorner.Parent = Track

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new(math.clamp((value - min) / (max - min), 0, 1), 0, 1, 0)
            Fill.BackgroundColor3 = Theme.AccentWhite
            Fill.BorderSizePixel = 0
            Fill.ZIndex = 8
            Fill.Parent = Track

            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(1, 0)
            FillCorner.Parent = Fill

            local Trigger = Instance.new("TextButton")
            Trigger.Size = UDim2.new(1, 0, 0, 14)
            Trigger.Position = UDim2.new(0, 0, 0, 14)
            Trigger.BackgroundTransparency = 1
            Trigger.Text = ""
            Trigger.ZIndex = 9
            Trigger.Parent = Item

            local sliding = false
            local function update(input)
                local trackWidth = Track.AbsoluteSize.X
                if trackWidth <= 0 then return end
                local pos = math.clamp((input.Position.X - Track.AbsolutePosition.X) / trackWidth, 0, 1)
                local rawVal = min + ((max - min) * pos)
                value = math.floor(rawVal / step + 0.5) * step
                value = math.clamp(value, min, max)

                local formatted = (step < 1) and string.format("%.2f", value) or tostring(value)
                ValLabel.Text = formatted .. suffix
                Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                if callback then task.spawn(callback, value) end
            end

            Trigger.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliding = true
                    update(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliding = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                    update(input)
                end
            end)
        end

        -- Sub-Segmented
        function methods:AddSegmented(segTitle, options, defaultIndex, callback)
            local selectedIndex = defaultIndex or 1

            local Item = Instance.new("Frame")
            Item.Size = UDim2.new(1, 0, 0, 38)
            Item.BackgroundTransparency = 1
            Item.ZIndex = 6
            Item.Parent = container

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 0, 13)
            Label.Position = UDim2.new(0, 2, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = segTitle
            Label.TextColor3 = Theme.TextMuted
            Label.TextSize = 9.5
            Label.Font = Enum.Font.GothamMedium
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.ZIndex = 7
            Label.Parent = Item

            local Bar = Instance.new("Frame")
            Bar.Size = UDim2.new(1, -4, 0, 20)
            Bar.Position = UDim2.new(0, 2, 0, 16)
            Bar.BackgroundColor3 = Color3.fromRGB(16, 17, 22)
            Bar.BorderSizePixel = 0
            Bar.ZIndex = 7
            Bar.Parent = Item

            local BarCorner = Instance.new("UICorner")
            BarCorner.CornerRadius = UDim.new(0, 4)
            BarCorner.Parent = Bar

            local BarStroke = Instance.new("UIStroke")
            BarStroke.Thickness = 1
            BarStroke.Color = Theme.CardBorder
            BarStroke.Parent = Bar

            local BarLayout = Instance.new("UIListLayout")
            BarLayout.FillDirection = Enum.FillDirection.Horizontal
            BarLayout.Parent = Bar

            local btnWidth = 1 / #options
            local buttons = {}

            for i, optName in ipairs(options) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Size = UDim2.new(btnWidth, 0, 1, 0)
                OptBtn.BackgroundColor3 = (i == selectedIndex) and Color3.fromRGB(30, 32, 42) or Color3.fromRGB(16, 17, 22)
                OptBtn.BorderSizePixel = 0
                OptBtn.Text = optName
                OptBtn.TextColor3 = (i == selectedIndex) and Theme.AccentWhite or Theme.TextMuted
                OptBtn.TextSize = 8.5
                OptBtn.Font = Enum.Font.GothamBold
                OptBtn.ZIndex = 8
                OptBtn.Parent = Bar

                local BtnCorner = Instance.new("UICorner")
                BtnCorner.CornerRadius = UDim.new(0, 3)
                BtnCorner.Parent = OptBtn

                buttons[i] = OptBtn

                OptBtn.MouseButton1Click:Connect(function()
                    selectedIndex = i
                    for btnIdx, b in ipairs(buttons) do
                        local isCur = (btnIdx == selectedIndex)
                        TweenService:Create(b, TweenInfo.new(0.12), {
                            BackgroundColor3 = isCur and Color3.fromRGB(30, 32, 42) or Color3.fromRGB(16, 17, 22),
                            TextColor3 = isCur and Theme.AccentWhite or Theme.TextMuted
                        }):Play()
                    end
                    if callback then task.spawn(callback, optName, i) end
                end)
            end
        end

        -- Sub-Button
        function methods:AddButton(btnText, callback)
            local Btn = Instance.new("Frame")
            Btn.Size = UDim2.new(1, -4, 0, 24)
            Btn.Position = UDim2.new(0, 2, 0, 0)
            Btn.BackgroundColor3 = Theme.ButtonBg
            Btn.BorderSizePixel = 0
            Btn.ZIndex = 6
            Btn.Parent = container

            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 4)
            BtnCorner.Parent = Btn

            local BtnStroke = Instance.new("UIStroke")
            BtnStroke.Thickness = 1
            BtnStroke.Color = Theme.ButtonBorder
            BtnStroke.Parent = Btn

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 1, 0)
            Label.BackgroundTransparency = 1
            Label.Text = string.upper(btnText)
            Label.TextColor3 = Theme.TextPrimary
            Label.TextSize = 9.5
            Label.Font = Enum.Font.GothamBold
            Label.ZIndex = 7
            Label.Parent = Btn

            local Trigger = Instance.new("TextButton")
            Trigger.Size = UDim2.new(1, 0, 1, 0)
            Trigger.BackgroundTransparency = 1
            Trigger.Text = ""
            Trigger.ZIndex = 8
            Trigger.Parent = Btn

            Trigger.MouseButton1Click:Connect(function()
                TweenService:Create(Btn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(34, 38, 50) }):Play()
                task.wait(0.1)
                TweenService:Create(Btn, TweenInfo.new(0.1), { BackgroundColor3 = Theme.ButtonBg }):Play()
                if callback then task.spawn(callback) end
            end)
        end

        return methods
    end

    -- ========================================================================
    -- // GROUPBOX / SECTION CREATION
    -- ========================================================================
    local function CreateGroupbox(parent, title)
        local Section = Instance.new("Frame")
        Section.Name = title .. "Section"
        Section.Size = UDim2.new(1, 0, 0, 0)
        Section.AutomaticSize = Enum.AutomaticSize.Y
        Section.BackgroundTransparency = 1
        Section.BorderSizePixel = 0
        Section.ZIndex = 4
        Section.Parent = parent

        local SectionLayout = Instance.new("UIListLayout")
        SectionLayout.Padding = UDim.new(0, 6)
        SectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
        SectionLayout.Parent = Section

        -- Аккуратный минималистичный заголовок категории
        local HeaderLabel = Instance.new("TextLabel")
        HeaderLabel.Size = UDim2.new(1, 0, 0, 14)
        HeaderLabel.BackgroundTransparency = 1
        HeaderLabel.Text = string.upper(title)
        HeaderLabel.TextColor3 = Theme.TextDark
        HeaderLabel.TextSize = 9
        HeaderLabel.Font = Enum.Font.GothamBold
        HeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
        HeaderLabel.ZIndex = 4
        HeaderLabel.LayoutOrder = 0
        HeaderLabel.Parent = Section

        local Pad = Instance.new("UIPadding")
        Pad.PaddingLeft = UDim.new(0, 2)
        Pad.PaddingRight = UDim.new(0, 2)
        Pad.Parent = HeaderLabel

        local GroupMethods = {}

        -- // FEATURE CARD С ВЛОЖЕННЫМИ НАСТРОЙКАМИ (Главная фича редизайна)
        function GroupMethods:AddFeature(featureTitle, defaultState, callback)
            local isEnabled = defaultState or false
            local isExpanded = false

            local Card = Instance.new("Frame")
            Card.Name = featureTitle .. "Feature"
            Card.Size = UDim2.new(1, 0, 0, 36)
            Card.AutomaticSize = Enum.AutomaticSize.Y
            Card.BackgroundColor3 = Theme.CardBg
            Card.BorderSizePixel = 0
            Card.ClipsDescendants = true
            Card.ZIndex = 5
            Card.Parent = Section

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 5)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Thickness = 1
            CardStroke.Color = Theme.CardBorder
            CardStroke.Parent = Card

            -- Верхняя полоса функции (всегда 36px)
            local TopBar = Instance.new("Frame")
            TopBar.Name = "TopBar"
            TopBar.Size = UDim2.new(1, 0, 0, 36)
            TopBar.BackgroundTransparency = 1
            TopBar.ZIndex = 6
            TopBar.Parent = Card

            -- Минималистичный Toggle Switch (Pill)
            local Switch = Instance.new("Frame")
            Switch.Name = "Switch"
            Switch.Size = UDim2.new(0, 26, 0, 14)
            Switch.Position = UDim2.new(0, 10, 0.5, -7)
            Switch.BackgroundColor3 = isEnabled and Theme.AccentWhite or Theme.ToggleOff
            Switch.BorderSizePixel = 0
            Switch.ZIndex = 7
            Switch.Parent = TopBar

            local SwitchCorner = Instance.new("UICorner")
            SwitchCorner.CornerRadius = UDim.new(1, 0)
            SwitchCorner.Parent = Switch

            local Thumb = Instance.new("Frame")
            Thumb.Name = "Thumb"
            Thumb.Size = UDim2.new(0, 10, 0, 10)
            Thumb.Position = isEnabled and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
            Thumb.BackgroundColor3 = isEnabled and Color3.fromRGB(15, 16, 20) or Theme.ToggleOffThumb
            Thumb.BorderSizePixel = 0
            Thumb.ZIndex = 8
            Thumb.Parent = Switch

            local ThumbCorner = Instance.new("UICorner")
            ThumbCorner.CornerRadius = UDim.new(1, 0)
            ThumbCorner.Parent = Thumb

            -- Название функции
            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(1, -84, 1, 0)
            Title.Position = UDim2.new(0, 44, 0, 0)
            Title.BackgroundTransparency = 1
            Title.Text = featureTitle
            Title.TextColor3 = isEnabled and Theme.TextPrimary or Theme.TextMuted
            Title.TextSize = 11
            Title.Font = Enum.Font.GothamMedium
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.ZIndex = 7
            Title.Parent = TopBar

            -- Кнопка шестеренки [ ⚙ ] для раскрытия скрытых параметров
            local GearBtn = Instance.new("ImageButton")
            GearBtn.Name = "GearSettings"
            GearBtn.Size = UDim2.new(0, 18, 0, 18)
            GearBtn.Position = UDim2.new(1, -28, 0.5, -9)
            GearBtn.BackgroundTransparency = 1
            GearBtn.Image = "rbxthumb://type=Asset&id=7059346386&w=420&h=420"
            GearBtn.ImageColor3 = Theme.TextDark
            GearBtn.ZIndex = 8
            GearBtn.Parent = TopBar

            -- Клик по функции (переключение главного тоггла)
            local MainTrigger = Instance.new("TextButton")
            MainTrigger.Size = UDim2.new(1, -36, 1, 0)
            MainTrigger.BackgroundTransparency = 1
            MainTrigger.Text = ""
            MainTrigger.ZIndex = 7
            MainTrigger.Parent = TopBar

            local function updateToggleVisual()
                local targetPos = isEnabled and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
                local switchBg = isEnabled and Theme.AccentWhite or Theme.ToggleOff
                local thumbBg = isEnabled and Color3.fromRGB(15, 16, 20) or Theme.ToggleOffThumb
                local textColor = isEnabled and Theme.TextPrimary or Theme.TextMuted

                TweenService:Create(Switch, TweenInfo.new(0.18, Enum.EasingStyle.Quart), { BackgroundColor3 = switchBg }):Play()
                TweenService:Create(Thumb, TweenInfo.new(0.18, Enum.EasingStyle.Quart), { Position = targetPos, BackgroundColor3 = thumbBg }):Play()
                TweenService:Create(Title, TweenInfo.new(0.18), { TextColor3 = textColor }):Play()
            end

            MainTrigger.MouseButton1Click:Connect(function()
                isEnabled = not isEnabled
                updateToggleVisual()
                if callback then task.spawn(callback, isEnabled) end
            end)

            -- Контейнер скрытых настроек (отсек аккордеона)
            local SettingsDrawer = Instance.new("Frame")
            SettingsDrawer.Name = "SettingsDrawer"
            SettingsDrawer.Size = UDim2.new(1, 0, 0, 0)
            SettingsDrawer.Position = UDim2.new(0, 0, 0, 36)
            SettingsDrawer.AutomaticSize = Enum.AutomaticSize.Y
            SettingsDrawer.BackgroundColor3 = Theme.DrawerBg
            SettingsDrawer.BorderSizePixel = 0
            SettingsDrawer.Visible = false
            SettingsDrawer.ZIndex = 5
            SettingsDrawer.Parent = Card

            local DrawerDivider = Instance.new("Frame")
            DrawerDivider.Size = UDim2.new(1, 0, 0, 1)
            DrawerDivider.BackgroundColor3 = Theme.DrawerBorder
            DrawerDivider.BorderSizePixel = 0
            DrawerDivider.ZIndex = 6
            DrawerDivider.Parent = SettingsDrawer

            local DrawerElements = Instance.new("Frame")
            DrawerElements.Name = "Elements"
            DrawerElements.Size = UDim2.new(1, -16, 0, 0)
            DrawerElements.Position = UDim2.new(0, 8, 0, 8)
            DrawerElements.AutomaticSize = Enum.AutomaticSize.Y
            DrawerElements.BackgroundTransparency = 1
            DrawerElements.ZIndex = 6
            DrawerElements.Parent = SettingsDrawer

            local DrawerLayout = Instance.new("UIListLayout")
            DrawerLayout.Padding = UDim.new(0, 6)
            DrawerLayout.SortOrder = Enum.SortOrder.LayoutOrder
            DrawerLayout.Parent = DrawerElements

            local DrawerBottomPad = Instance.new("Frame")
            DrawerBottomPad.Size = UDim2.new(1, 0, 0, 4)
            DrawerBottomPad.BackgroundTransparency = 1
            DrawerBottomPad.LayoutOrder = 9999
            DrawerBottomPad.Parent = DrawerElements

            -- Открытие / Закрытие отсека параметров
            GearBtn.MouseButton1Click:Connect(function()
                isExpanded = not isExpanded
                SettingsDrawer.Visible = isExpanded

                TweenService:Create(GearBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
                    Rotation = isExpanded and 90 or 0,
                    ImageColor3 = isExpanded and Theme.AccentWhite or Theme.TextDark
                }):Play()
            end)

            local featureSubMethods = populateSettingsContainer(DrawerElements)
            function featureSubMethods:SetState(state)
                isEnabled = state
                updateToggleVisual()
            end

            return featureSubMethods
        end

        -- // СЕКЦИЯ БЕЗ МАСТЕР-ТОГГЛА (для погоды, освещения, кинематики и т.д.)
        function GroupMethods:AddConfigSection(sectionTitle)
            local isExpanded = false

            local Card = Instance.new("Frame")
            Card.Name = sectionTitle .. "ConfigCard"
            Card.Size = UDim2.new(1, 0, 0, 36)
            Card.AutomaticSize = Enum.AutomaticSize.Y
            Card.BackgroundColor3 = Theme.CardBg
            Card.BorderSizePixel = 0
            Card.ClipsDescendants = true
            Card.ZIndex = 5
            Card.Parent = Section

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 5)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Thickness = 1
            CardStroke.Color = Theme.CardBorder
            CardStroke.Parent = Card

            local TopBar = Instance.new("Frame")
            TopBar.Name = "TopBar"
            TopBar.Size = UDim2.new(1, 0, 0, 36)
            TopBar.BackgroundTransparency = 1
            TopBar.ZIndex = 6
            TopBar.Parent = Card

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(1, -44, 1, 0)
            Title.Position = UDim2.new(0, 12, 0, 0)
            Title.BackgroundTransparency = 1
            Title.Text = sectionTitle
            Title.TextColor3 = Theme.TextPrimary
            Title.TextSize = 11
            Title.Font = Enum.Font.GothamMedium
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.ZIndex = 7
            Title.Parent = TopBar

            local GearBtn = Instance.new("ImageButton")
            GearBtn.Name = "GearSettings"
            GearBtn.Size = UDim2.new(0, 18, 0, 18)
            GearBtn.Position = UDim2.new(1, -28, 0.5, -9)
            GearBtn.BackgroundTransparency = 1
            GearBtn.Image = "rbxthumb://type=Asset&id=7059346386&w=420&h=420"
            GearBtn.ImageColor3 = Theme.TextDark
            GearBtn.ZIndex = 8
            GearBtn.Parent = TopBar

            local TopTrigger = Instance.new("TextButton")
            TopTrigger.Size = UDim2.new(1, 0, 1, 0)
            TopTrigger.BackgroundTransparency = 1
            TopTrigger.Text = ""
            TopTrigger.ZIndex = 7
            TopTrigger.Parent = TopBar

            local SettingsDrawer = Instance.new("Frame")
            SettingsDrawer.Name = "SettingsDrawer"
            SettingsDrawer.Size = UDim2.new(1, 0, 0, 0)
            SettingsDrawer.Position = UDim2.new(0, 0, 0, 36)
            SettingsDrawer.AutomaticSize = Enum.AutomaticSize.Y
            SettingsDrawer.BackgroundColor3 = Theme.DrawerBg
            SettingsDrawer.BorderSizePixel = 0
            SettingsDrawer.Visible = false
            SettingsDrawer.ZIndex = 5
            SettingsDrawer.Parent = Card

            local DrawerDivider = Instance.new("Frame")
            DrawerDivider.Size = UDim2.new(1, 0, 0, 1)
            DrawerDivider.BackgroundColor3 = Theme.DrawerBorder
            DrawerDivider.BorderSizePixel = 0
            DrawerDivider.ZIndex = 6
            DrawerDivider.Parent = SettingsDrawer

            local DrawerElements = Instance.new("Frame")
            DrawerElements.Name = "Elements"
            DrawerElements.Size = UDim2.new(1, -16, 0, 0)
            DrawerElements.Position = UDim2.new(0, 8, 0, 8)
            DrawerElements.AutomaticSize = Enum.AutomaticSize.Y
            DrawerElements.BackgroundTransparency = 1
            DrawerElements.ZIndex = 6
            DrawerElements.Parent = SettingsDrawer

            local DrawerLayout = Instance.new("UIListLayout")
            DrawerLayout.Padding = UDim.new(0, 6)
            DrawerLayout.SortOrder = Enum.SortOrder.LayoutOrder
            DrawerLayout.Parent = DrawerElements

            local DrawerBottomPad = Instance.new("Frame")
            DrawerBottomPad.Size = UDim2.new(1, 0, 0, 4)
            DrawerBottomPad.BackgroundTransparency = 1
            DrawerBottomPad.LayoutOrder = 9999
            DrawerBottomPad.Parent = DrawerElements

            local function toggleDrawer()
                isExpanded = not isExpanded
                SettingsDrawer.Visible = isExpanded

                TweenService:Create(GearBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
                    Rotation = isExpanded and 90 or 0,
                    ImageColor3 = isExpanded and Theme.AccentWhite or Theme.TextDark
                }):Play()
            end

            GearBtn.MouseButton1Click:Connect(toggleDrawer)
            TopTrigger.MouseButton1Click:Connect(toggleDrawer)

            return populateSettingsContainer(DrawerElements)
        end

        -- Одиночная кнопка (для выгрузки и утилит)
        function GroupMethods:AddButton(btnText, callback)
            local Btn = Instance.new("Frame")
            Btn.Size = UDim2.new(1, 0, 0, 28)
            Btn.BackgroundColor3 = Theme.ButtonBg
            Btn.BorderSizePixel = 0
            Btn.ZIndex = 5
            Btn.Parent = Section

            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 5)
            BtnCorner.Parent = Btn

            local BtnStroke = Instance.new("UIStroke")
            BtnStroke.Thickness = 1
            BtnStroke.Color = Theme.ButtonBorder
            BtnStroke.Parent = Btn

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 1, 0)
            Label.BackgroundTransparency = 1
            Label.Text = string.upper(btnText)
            Label.TextColor3 = Theme.TextPrimary
            Label.TextSize = 10
            Label.Font = Enum.Font.GothamBold
            Label.ZIndex = 6
            Label.Parent = Btn

            local Trigger = Instance.new("TextButton")
            Trigger.Size = UDim2.new(1, 0, 1, 0)
            Trigger.BackgroundTransparency = 1
            Trigger.Text = ""
            Trigger.ZIndex = 7
            Trigger.Parent = Btn

            Trigger.MouseButton1Click:Connect(function()
                TweenService:Create(Btn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(36, 40, 52) }):Play()
                task.wait(0.1)
                TweenService:Create(Btn, TweenInfo.new(0.1), { BackgroundColor3 = Theme.ButtonBg }):Play()
                if callback then task.spawn(callback) end
            end)
        end

        return GroupMethods
    end

    -- Toggle Menu Keybind
    local keyConn = UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and (input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightShift) then
            Window.Visible = not Window.Visible
        end
    end)

    return {
        ScreenGui = ScreenGui,
        Window = Window,
        Pages = Pages,
        SwitchTab = SwitchTab,
        CreateGroupbox = CreateGroupbox,
        Connections = { fpsConn, keyConn }
    }
end

return UI
