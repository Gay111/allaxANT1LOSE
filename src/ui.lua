-- // src/ui.lua
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

function UI.Init()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AntiloseClient"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = getContainer()

    local Window = Instance.new("Frame")
    Window.Name = "AntiloseWindow"
    Window.Size = UDim2.new(0, 680, 0, 480)
    Window.Position = UDim2.new(0.5, -340, 0.5, -240)
    Window.BackgroundTransparency = 1
    Window.Parent = ScreenGui

    -- Процедурные тени
    local ShadowHolder = Instance.new("Frame")
    ShadowHolder.Name = "ShadowLayers"
    ShadowHolder.Size = UDim2.new(1, 0, 1, 0)
    ShadowHolder.BackgroundTransparency = 1
    ShadowHolder.ZIndex = 1
    ShadowHolder.Parent = Window

    for i = 1, 6 do
        local progress = i / 6
        local sizeOffset = 24 * progress
        local alpha = 0.6 * ((1 - progress) ^ 1.6)

        local layer = Instance.new("Frame")
        layer.AnchorPoint = Vector2.new(0.5, 0.5)
        layer.Position = UDim2.new(0.5, 0, 0.5, 5)
        layer.Size = UDim2.new(1, sizeOffset * 2, 1, sizeOffset * 2)
        layer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        layer.BackgroundTransparency = 1 - alpha
        layer.BorderSizePixel = 0
        layer.ZIndex = 1
        layer.Parent = ShadowHolder

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8 + (sizeOffset * 0.4))
        corner.Parent = layer
    end

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(1, 0, 1, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    MainFrame.BorderSizePixel = 0
    MainFrame.ZIndex = 2
    MainFrame.Parent = Window

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Thickness = 1
    MainStroke.Color = Color3.fromRGB(255, 255, 255)
    MainStroke.Parent = MainFrame

    local MainStrokeGrad = Instance.new("UIGradient")
    MainStrokeGrad.Rotation = 90
    MainStrokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(180, 180, 190)),
        ColorSequenceKeypoint.new(0.2, Color3.fromRGB(50, 50, 58)),
        ColorSequenceKeypoint.new(0.8, Color3.fromRGB(16, 16, 20)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(35, 35, 42))
    })
    MainStrokeGrad.Parent = MainStroke

    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 42)
    Header.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
    Header.BorderSizePixel = 0
    Header.ZIndex = 3
    Header.Parent = MainFrame

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 8)
    HeaderCorner.Parent = Header

    local HeaderBottomCover = Instance.new("Frame")
    HeaderBottomCover.Size = UDim2.new(1, 0, 0, 8)
    HeaderBottomCover.Position = UDim2.new(0, 0, 1, -8)
    HeaderBottomCover.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
    HeaderBottomCover.BorderSizePixel = 0
    HeaderBottomCover.ZIndex = 3
    HeaderBottomCover.Parent = Header

    local HeaderLine = Instance.new("Frame")
    HeaderLine.Size = UDim2.new(1, 0, 0, 1)
    HeaderLine.Position = UDim2.new(0, 0, 1, 0)
    HeaderLine.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    HeaderLine.BorderSizePixel = 0
    HeaderLine.ZIndex = 4
    HeaderLine.Parent = Header

    local LogoText = Instance.new("TextLabel")
    LogoText.Size = UDim2.new(0, 150, 1, 0)
    LogoText.Position = UDim2.new(0, 16, 0, 0)
    LogoText.BackgroundTransparency = 1
    LogoText.Text = "ANTILOSE"
    LogoText.TextColor3 = Color3.fromRGB(255, 255, 255)
    LogoText.TextSize = 13
    LogoText.Font = Enum.Font.GothamBold
    LogoText.TextXAlignment = Enum.TextXAlignment.Left
    LogoText.ZIndex = 4
    LogoText.Parent = Header

    local LogoSub = Instance.new("TextLabel")
    LogoSub.Size = UDim2.new(0, 100, 1, 0)
    LogoSub.Position = UDim2.new(0, 92, 0, 0)
    LogoSub.BackgroundTransparency = 1
    LogoSub.Text = "// CLIENT"
    LogoSub.TextColor3 = Color3.fromRGB(90, 90, 100)
    LogoSub.TextSize = 10
    LogoSub.Font = Enum.Font.GothamMedium
    LogoSub.TextXAlignment = Enum.TextXAlignment.Left
    LogoSub.ZIndex = 4
    LogoSub.Parent = Header

    local Telemetry = Instance.new("TextLabel")
    Telemetry.Size = UDim2.new(0, 200, 1, 0)
    Telemetry.Position = UDim2.new(1, -216, 0, 0)
    Telemetry.BackgroundTransparency = 1
    Telemetry.Text = "FPS: 60  |  PING: 0ms"
    Telemetry.TextColor3 = Color3.fromRGB(110, 110, 120)
    Telemetry.TextSize = 10
    Telemetry.Font = Enum.Font.GothamBold
    Telemetry.TextXAlignment = Enum.TextXAlignment.Right
    Telemetry.ZIndex = 4
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

    -- Контент и Док
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -24, 1, -120)
    Content.Position = UDim2.new(0, 12, 0, 52)
    Content.BackgroundTransparency = 1
    Content.ZIndex = 3
    Content.Parent = MainFrame

    local Dock = Instance.new("Frame")
    Dock.Name = "BottomDock"
    Dock.Size = UDim2.new(1, -24, 0, 48)
    Dock.Position = UDim2.new(0, 12, 1, -58)
    Dock.BackgroundColor3 = Color3.fromRGB(11, 11, 14)
    Dock.BorderSizePixel = 0
    Dock.ZIndex = 3
    Dock.Parent = MainFrame

    local DockCorner = Instance.new("UICorner")
    DockCorner.CornerRadius = UDim.new(0, 6)
    DockCorner.Parent = Dock

    local DockStroke = Instance.new("UIStroke")
    DockStroke.Thickness = 1
    DockStroke.Color = Color3.fromRGB(24, 24, 28)
    DockStroke.Parent = Dock

    local ActiveIndicator = Instance.new("Frame")
    ActiveIndicator.Name = "ActiveIndicator"
    ActiveIndicator.Size = UDim2.new(0, 158, 0, 36)
    ActiveIndicator.Position = UDim2.new(0, 6, 0.5, -18)
    ActiveIndicator.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    ActiveIndicator.BorderSizePixel = 0
    ActiveIndicator.ZIndex = 4
    ActiveIndicator.Parent = Dock

    local IndCorner = Instance.new("UICorner")
    IndCorner.CornerRadius = UDim.new(0, 5)
    IndCorner.Parent = ActiveIndicator

    local IndStroke = Instance.new("UIStroke")
    IndStroke.Thickness = 1
    IndStroke.Color = Color3.fromRGB(255, 255, 255)
    IndStroke.Parent = ActiveIndicator

    local IndStrokeGrad = Instance.new("UIGradient")
    IndStrokeGrad.Rotation = 90
    IndStrokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 220, 230)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 35, 42))
    })
    IndStrokeGrad.Parent = IndStroke

    local TabDefinitions = {
        { Name = "Aim",      Icon = "100486500105972" },
        { Name = "Visuals",  Icon = "6523858422" },
        { Name = "World",    Icon = "11887653913" },
        { Name = "Settings", Icon = "7059346386" },
    }

    local Pages = {}
    local TabButtons = {}
    local CurrentTab = nil

    local function SwitchTab(tabName, targetIndex)
        if CurrentTab == tabName then return end
        CurrentTab = tabName

        local targetX = 6 + ((targetIndex - 1) * (158 + 6))
        TweenService:Create(ActiveIndicator, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, targetX, 0.5, -18)
        }):Play()

        for name, pageData in pairs(Pages) do
            local isTarget = (name == tabName)
            pageData.Root.Visible = isTarget
            if isTarget then
                pageData.Root.Position = UDim2.new(0, 0, 0, 4)
                TweenService:Create(pageData.Root, TweenInfo.new(0.2, Enum.EasingStyle.Quart), { Position = UDim2.new(0, 0, 0, 0) }):Play()
            end
        end

        for name, tab in pairs(TabButtons) do
            local active = (name == tabName)
            local iconColor = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(90, 90, 100)
            local textColor = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 110)
            TweenService:Create(tab.Icon, TweenInfo.new(0.2), { ImageColor3 = iconColor }):Play()
            TweenService:Create(tab.Label, TweenInfo.new(0.2), { TextColor3 = textColor }):Play()
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
        LeftCol.ScrollBarImageColor3 = Color3.fromRGB(45, 45, 52)
        LeftCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
        LeftCol.CanvasSize = UDim2.new(0, 0, 0, 0)
        LeftCol.Parent = Page

        local LeftLayout = Instance.new("UIListLayout")
        LeftLayout.Padding = UDim.new(0, 10)
        LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
        LeftLayout.Parent = LeftCol

        local RightCol = Instance.new("ScrollingFrame")
        RightCol.Name = "RightColumn"
        RightCol.Size = UDim2.new(0.5, -6, 1, 0)
        RightCol.Position = UDim2.new(0.5, 6, 0, 0)
        RightCol.BackgroundTransparency = 1
        RightCol.BorderSizePixel = 0
        RightCol.ScrollBarThickness = 2
        RightCol.ScrollBarImageColor3 = Color3.fromRGB(45, 45, 52)
        RightCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
        RightCol.CanvasSize = UDim2.new(0, 0, 0, 0)
        RightCol.Parent = Page

        local RightLayout = Instance.new("UIListLayout")
        RightLayout.Padding = UDim.new(0, 10)
        RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
        RightLayout.Parent = RightCol

        Pages[def.Name] = { Root = Page, Left = LeftCol, Right = RightCol }

        local TabBtn = Instance.new("Frame")
        TabBtn.Name = def.Name .. "Tab"
        TabBtn.Size = UDim2.new(0, 158, 0, 36)
        TabBtn.Position = UDim2.new(0, 6 + ((index - 1) * (158 + 6)), 0.5, -18)
        TabBtn.BackgroundTransparency = 1
        TabBtn.ZIndex = 5
        TabBtn.Parent = Dock

        local Icon = Instance.new("ImageLabel")
        Icon.Name = "Icon"
        Icon.Size = UDim2.new(0, 16, 0, 16)
        Icon.Position = UDim2.new(0, 18, 0.5, -8)
        Icon.BackgroundTransparency = 1
        Icon.Image = string.format("rbxthumb://type=Asset&id=%s&w=420&h=420", def.Icon)
        Icon.ImageColor3 = Color3.fromRGB(90, 90, 100)
        Icon.ZIndex = 6
        Icon.Parent = TabBtn

        local Label = Instance.new("TextLabel")
        Label.Name = "Label"
        Label.Size = UDim2.new(1, -44, 1, 0)
        Label.Position = UDim2.new(0, 42, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = string.upper(def.Name)
        Label.TextColor3 = Color3.fromRGB(100, 100, 110)
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

    local function CreateGroupbox(parent, title)
        local Box = Instance.new("Frame")
        Box.Name = title .. "Groupbox"
        Box.Size = UDim2.new(1, 0, 0, 0)
        Box.AutomaticSize = Enum.AutomaticSize.Y
        Box.BackgroundColor3 = Color3.fromRGB(11, 11, 14)
        Box.BorderSizePixel = 0
        Box.ZIndex = 3
        Box.Parent = parent

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 6)
        Corner.Parent = Box

        local Stroke = Instance.new("UIStroke")
        Stroke.Thickness = 1
        Stroke.Color = Color3.fromRGB(22, 22, 26)
        Stroke.Parent = Box

        local BoxHeader = Instance.new("Frame")
        BoxHeader.Size = UDim2.new(1, 0, 0, 26)
        BoxHeader.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
        BoxHeader.BorderSizePixel = 0
        BoxHeader.ZIndex = 4
        BoxHeader.Parent = Box

        local BoxHeaderCorner = Instance.new("UICorner")
        BoxHeaderCorner.CornerRadius = UDim.new(0, 6)
        BoxHeaderCorner.Parent = BoxHeader

        local BoxHeaderCut = Instance.new("Frame")
        BoxHeaderCut.Size = UDim2.new(1, 0, 0, 6)
        BoxHeaderCut.Position = UDim2.new(0, 0, 1, -6)
        BoxHeaderCut.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
        BoxHeaderCut.BorderSizePixel = 0
        BoxHeaderCut.ZIndex = 4
        BoxHeaderCut.Parent = BoxHeader

        local HeaderTitle = Instance.new("TextLabel")
        HeaderTitle.Size = UDim2.new(1, -20, 1, 0)
        HeaderTitle.Position = UDim2.new(0, 10, 0, 0)
        HeaderTitle.BackgroundTransparency = 1
        HeaderTitle.Text = string.upper(title)
        HeaderTitle.TextColor3 = Color3.fromRGB(170, 170, 180)
        HeaderTitle.TextSize = 9
        HeaderTitle.Font = Enum.Font.GothamBold
        HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
        HeaderTitle.ZIndex = 5
        HeaderTitle.Parent = BoxHeader

        local Elements = Instance.new("Frame")
        Elements.Name = "Elements"
        Elements.Size = UDim2.new(1, -20, 0, 0)
        Elements.Position = UDim2.new(0, 10, 0, 32)
        Elements.AutomaticSize = Enum.AutomaticSize.Y
        Elements.BackgroundTransparency = 1
        Elements.ZIndex = 4
        Elements.Parent = Box

        local ElemLayout = Instance.new("UIListLayout")
        ElemLayout.Padding = UDim.new(0, 8)
        ElemLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ElemLayout.Parent = Elements

        local Pad = Instance.new("Frame")
        Pad.Size = UDim2.new(1, 0, 0, 4)
        Pad.BackgroundTransparency = 1
        Pad.LayoutOrder = 999
        Pad.Parent = Elements

        local Methods = {}

        function Methods:AddToggle(toggleTitle, default, callback)
            local state = default or false
            local Item = Instance.new("Frame")
            Item.Size = UDim2.new(1, 0, 0, 24)
            Item.BackgroundTransparency = 1
            Item.ZIndex = 4
            Item.Parent = Elements

            local CheckBox = Instance.new("Frame")
            CheckBox.Size = UDim2.new(0, 14, 0, 14)
            CheckBox.Position = UDim2.new(0, 0, 0.5, -7)
            CheckBox.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
            CheckBox.BorderSizePixel = 0
            CheckBox.ZIndex = 5
            CheckBox.Parent = Item

            local CheckCorner = Instance.new("UICorner")
            CheckCorner.CornerRadius = UDim.new(0, 3)
            CheckCorner.Parent = CheckBox

            local CheckStroke = Instance.new("UIStroke")
            CheckStroke.Thickness = 1
            CheckStroke.Color = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(40, 40, 48)
            CheckStroke.Parent = CheckBox

            local Core = Instance.new("Frame")
            Core.Size = UDim2.new(0, 6, 0, 6)
            Core.Position = UDim2.new(0.5, -3, 0.5, -3)
            Core.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Core.BackgroundTransparency = state and 0 or 1
            Core.BorderSizePixel = 0
            Core.ZIndex = 6
            Core.Parent = CheckBox

            local CoreCorner = Instance.new("UICorner")
            CoreCorner.CornerRadius = UDim.new(0, 1)
            CoreCorner.Parent = Core

            local Text = Instance.new("TextLabel")
            Text.Size = UDim2.new(1, -24, 1, 0)
            Text.Position = UDim2.new(0, 24, 0, 0)
            Text.BackgroundTransparency = 1
            Text.Text = toggleTitle
            Text.TextColor3 = state and Color3.fromRGB(235, 235, 240) or Color3.fromRGB(140, 140, 150)
            Text.TextSize = 11
            Text.Font = Enum.Font.GothamMedium
            Text.TextXAlignment = Enum.TextXAlignment.Left
            Text.ZIndex = 5
            Text.Parent = Item

            local Trigger = Instance.new("TextButton")
            Trigger.Size = UDim2.new(1, 0, 1, 0)
            Trigger.BackgroundTransparency = 1
            Trigger.Text = ""
            Trigger.ZIndex = 7
            Trigger.Parent = Item

            Trigger.MouseButton1Click:Connect(function()
                state = not state
                TweenService:Create(CheckStroke, TweenInfo.new(0.15), { Color = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(40, 40, 48) }):Play()
                TweenService:Create(Text, TweenInfo.new(0.15), { TextColor3 = state and Color3.fromRGB(235, 235, 240) or Color3.fromRGB(140, 140, 150) }):Play()
                TweenService:Create(Core, TweenInfo.new(0.15), { BackgroundTransparency = state and 0 or 1 }):Play()
                if callback then task.spawn(callback, state) end
            end)
        end

        function Methods:AddSlider(sliderTitle, min, max, default, step, suffix, callback)
            local value = default or min
            step = step or 1
            suffix = suffix or ""

            local Item = Instance.new("Frame")
            Item.Size = UDim2.new(1, 0, 0, 36)
            Item.BackgroundTransparency = 1
            Item.ZIndex = 4
            Item.Parent = Elements

            local Text = Instance.new("TextLabel")
            Text.Size = UDim2.new(1, -60, 0, 16)
            Text.BackgroundTransparency = 1
            Text.Text = sliderTitle
            Text.TextColor3 = Color3.fromRGB(180, 180, 190)
            Text.TextSize = 11
            Text.Font = Enum.Font.GothamMedium
            Text.TextXAlignment = Enum.TextXAlignment.Left
            Text.ZIndex = 5
            Text.Parent = Item

            local Val = Instance.new("TextLabel")
            Val.Size = UDim2.new(0, 60, 0, 16)
            Val.Position = UDim2.new(1, -60, 0, 0)
            Val.BackgroundTransparency = 1
            Val.Text = tostring(value) .. suffix
            Val.TextColor3 = Color3.fromRGB(130, 130, 140)
            Val.TextSize = 10
            Val.Font = Enum.Font.GothamBold
            Val.TextXAlignment = Enum.TextXAlignment.Right
            Val.ZIndex = 5
            Val.Parent = Item

            local Track = Instance.new("Frame")
            Track.Size = UDim2.new(1, 0, 0, 4)
            Track.Position = UDim2.new(0, 0, 0, 24)
            Track.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
            Track.BorderSizePixel = 0
            Track.ZIndex = 5
            Track.Parent = Item

            local TrackCorner = Instance.new("UICorner")
            TrackCorner.CornerRadius = UDim.new(1, 0)
            TrackCorner.Parent = Track

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new(math.clamp((value - min) / (max - min), 0, 1), 0, 1, 0)
            Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Fill.BorderSizePixel = 0
            Fill.ZIndex = 6
            Fill.Parent = Track

            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(1, 0)
            FillCorner.Parent = Fill

            local Trigger = Instance.new("TextButton")
            Trigger.Size = UDim2.new(1, 0, 1, 0)
            Trigger.BackgroundTransparency = 1
            Trigger.Text = ""
            Trigger.ZIndex = 7
            Trigger.Parent = Track

            local sliding = false
            local function update(input)
                local pos = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                local rawVal = min + ((max - min) * pos)
                value = math.floor(rawVal / step + 0.5) * step
                value = math.clamp(value, min, max)

                Val.Text = string.format("%s%s", tostring(value), suffix)
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
                if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end
            end)
        end

        function Methods:AddSegmented(segTitle, options, defaultIndex, callback)
            local selectedIndex = defaultIndex or 1
            local Item = Instance.new("Frame")
            Item.Size = UDim2.new(1, 0, 0, 42)
            Item.BackgroundTransparency = 1
            Item.ZIndex = 4
            Item.Parent = Elements

            local Text = Instance.new("TextLabel")
            Text.Size = UDim2.new(1, 0, 0, 14)
            Text.BackgroundTransparency = 1
            Text.Text = segTitle
            Text.TextColor3 = Color3.fromRGB(180, 180, 190)
            Text.TextSize = 10
            Text.Font = Enum.Font.GothamMedium
            Text.TextXAlignment = Enum.TextXAlignment.Left
            Text.ZIndex = 5
            Text.Parent = Item

            local Bar = Instance.new("Frame")
            Bar.Size = UDim2.new(1, 0, 0, 22)
            Bar.Position = UDim2.new(0, 0, 0, 18)
            Bar.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
            Bar.BorderSizePixel = 0
            Bar.ZIndex = 5
            Bar.Parent = Item

            local BarCorner = Instance.new("UICorner")
            BarCorner.CornerRadius = UDim.new(0, 4)
            BarCorner.Parent = Bar

            local BarLayout = Instance.new("UIListLayout")
            BarLayout.FillDirection = Enum.FillDirection.Horizontal
            BarLayout.Parent = Bar

            local buttons = {}
            local btnWidth = 1 / #options

            for i, optName in ipairs(options) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Size = UDim2.new(btnWidth, 0, 1, 0)
                OptBtn.BackgroundColor3 = (i == selectedIndex) and Color3.fromRGB(28, 28, 34) or Color3.fromRGB(16, 16, 20)
                OptBtn.BorderSizePixel = 0
                OptBtn.Text = optName
                OptBtn.TextColor3 = (i == selectedIndex) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 110)
                OptBtn.TextSize = 9
                OptBtn.Font = Enum.Font.GothamBold
                OptBtn.ZIndex = 6
                OptBtn.Parent = Bar

                local BtnCorner = Instance.new("UICorner")
                BtnCorner.CornerRadius = UDim.new(0, 4)
                BtnCorner.Parent = OptBtn

                buttons[i] = OptBtn

                OptBtn.MouseButton1Click:Connect(function()
                    selectedIndex = i
                    for btnIdx, b in ipairs(buttons) do
                        local isCur = (btnIdx == selectedIndex)
                        TweenService:Create(b, TweenInfo.new(0.15), {
                            BackgroundColor3 = isCur and Color3.fromRGB(28, 28, 34) or Color3.fromRGB(16, 16, 20),
                            TextColor3 = isCur and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 110)
                        }):Play()
                    end
                    if callback then task.spawn(callback, optName, i) end
                end)
            end
        end

        function Methods:AddButton(btnText, callback)
            local Btn = Instance.new("Frame")
            Btn.Size = UDim2.new(1, 0, 0, 26)
            Btn.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
            Btn.BorderSizePixel = 0
            Btn.ZIndex = 4
            Btn.Parent = Elements

            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 4)
            BtnCorner.Parent = Btn

            local BtnStroke = Instance.new("UIStroke")
            BtnStroke.Thickness = 1
            BtnStroke.Color = Color3.fromRGB(30, 30, 38)
            BtnStroke.Parent = Btn

            local Text = Instance.new("TextLabel")
            Text.Size = UDim2.new(1, 0, 1, 0)
            Text.BackgroundTransparency = 1
            Text.Text = string.upper(btnText)
            Text.TextColor3 = Color3.fromRGB(200, 200, 210)
            Text.TextSize = 10
            Text.Font = Enum.Font.GothamBold
            Text.ZIndex = 5
            Text.Parent = Btn

            local Trigger = Instance.new("TextButton")
            Trigger.Size = UDim2.new(1, 0, 1, 0)
            Trigger.BackgroundTransparency = 1
            Trigger.Text = ""
            Trigger.ZIndex = 6
            Trigger.Parent = Btn

            Trigger.MouseButton1Click:Connect(function()
                TweenService:Create(Btn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(30, 30, 38) }):Play()
                task.wait(0.1)
                TweenService:Create(Btn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(16, 16, 20) }):Play()
                if callback then task.spawn(callback) end
            end)
        end

        return Methods
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
