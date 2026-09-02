-- // src/ui.lua — Flat Minimalist UI
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

-- Строгая палитра без лишних оттенков
local Colors = {
    Bg          = Color3.fromRGB(18, 18, 20),
    Border      = Color3.fromRGB(36, 36, 42),
    Card        = Color3.fromRGB(24, 24, 28),
    CardBorder  = Color3.fromRGB(34, 34, 40),
    Drawer      = Color3.fromRGB(14, 14, 16),
    Text        = Color3.fromRGB(225, 225, 230),
    Muted       = Color3.fromRGB(115, 115, 125),
    Dark        = Color3.fromRGB(70, 70, 80),
    White       = Color3.fromRGB(255, 255, 255),
    Track       = Color3.fromRGB(32, 32, 38),
}

function UI.Init()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AntiloseMinimal"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = getContainer()

    local Window = Instance.new("Frame")
    Window.Name = "Window"
    Window.Size = UDim2.new(0, 600, 0, 440)
    Window.Position = UDim2.new(0.5, -300, 0.5, -220)
    Window.BackgroundColor3 = Colors.Bg
    Window.BorderSizePixel = 0
    Window.Parent = ScreenGui

    local WinCorner = Instance.new("UICorner")
    WinCorner.CornerRadius = UDim.new(0, 4)
    WinCorner.Parent = Window

    local WinStroke = Instance.new("UIStroke")
    WinStroke.Thickness = 1
    WinStroke.Color = Colors.Border
    WinStroke.Parent = Window

    -- Шапка (простая 32px полоса)
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 32)
    Header.BackgroundTransparency = 1
    Header.Parent = Window

    local HeaderLine = Instance.new("Frame")
    HeaderLine.Size = UDim2.new(1, 0, 0, 1)
    HeaderLine.Position = UDim2.new(0, 0, 1, -1)
    HeaderLine.BackgroundColor3 = Colors.Border
    HeaderLine.BorderSizePixel = 0
    HeaderLine.Parent = Header

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0, 120, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "ANTILOSE"
    Title.TextColor3 = Colors.White
    Title.TextSize = 11
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header

    local FpsLabel = Instance.new("TextLabel")
    FpsLabel.Size = UDim2.new(0, 100, 1, 0)
    FpsLabel.Position = UDim2.new(1, -112, 0, 0)
    FpsLabel.BackgroundTransparency = 1
    FpsLabel.Text = "60 fps"
    FpsLabel.TextColor3 = Colors.Dark
    FpsLabel.TextSize = 10
    FpsLabel.Font = Enum.Font.GothamMedium
    FpsLabel.TextXAlignment = Enum.TextXAlignment.Right
    FpsLabel.Parent = Header

    local lastTime, frames = tick(), 0
    local fpsConn = RunService.RenderStepped:Connect(function()
        if not ScreenGui.Parent then return end
        frames = frames + 1
        local now = tick()
        if now - lastTime >= 0.5 then
            FpsLabel.Text = string.format("%d fps", math.floor(frames / (now - lastTime)))
            frames, lastTime = 0, now
        end
    end)

    -- Перемещение окна
    local isDrag, dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDrag = true
            dragStart = input.Position
            startPos = Window.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDrag and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDrag = false
        end
    end)

    -- Рабочая область страниц
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -20, 1, -76)
    Content.Position = UDim2.new(0, 10, 0, 38)
    Content.BackgroundTransparency = 1
    Content.Parent = Window

    -- Нижний док с вкладками (ровная полоса 36px)
    local Dock = Instance.new("Frame")
    Dock.Name = "Dock"
    Dock.Size = UDim2.new(1, 0, 0, 36)
    Dock.Position = UDim2.new(0, 0, 1, -36)
    Dock.BackgroundColor3 = Colors.Bg
    Dock.BorderSizePixel = 0
    Dock.Parent = Window

    local DockLine = Instance.new("Frame")
    DockLine.Size = UDim2.new(1, 0, 0, 1)
    DockLine.Position = UDim2.new(0, 0, 0, 0)
    DockLine.BackgroundColor3 = Colors.Border
    DockLine.BorderSizePixel = 0
    DockLine.Parent = Dock

    local DockLayout = Instance.new("UIListLayout")
    DockLayout.FillDirection = Enum.FillDirection.Horizontal
    DockLayout.Parent = Dock

    local TabDefinitions = {
        { Name = "Aim", Icon = "100486500105972" },
        { Name = "Visuals", Icon = "6523858422" },
        { Name = "World", Icon = "11887653913" },
        { Name = "Settings", Icon = "7059346386" },
    }

    local Pages = {}
    local TabButtons = {}
    local CurrentTab = nil

    local function SwitchTab(tabName)
        if CurrentTab == tabName then return end
        CurrentTab = tabName

        for name, pageData in pairs(Pages) do
            pageData.Root.Visible = (name == tabName)
        end
        for name, tab in pairs(TabButtons) do
            local active = (name == tabName)
            tab.Icon.ImageColor3 = active and Colors.White or Colors.Dark
            tab.Label.TextColor3 = active and Colors.White or Colors.Dark
        end
    end

    for _, def in ipairs(TabDefinitions) do
        local Page = Instance.new("Frame")
        Page.Name = def.Name .. "Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.Visible = false
        Page.Parent = Content

        local LeftCol = Instance.new("ScrollingFrame")
        LeftCol.Name = "Left"
        LeftCol.Size = UDim2.new(0.5, -5, 1, 0)
        LeftCol.BackgroundTransparency = 1
        LeftCol.BorderSizePixel = 0
        LeftCol.ScrollBarThickness = 1.5
        LeftCol.ScrollBarImageColor3 = Colors.Border
        LeftCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
        LeftCol.CanvasSize = UDim2.new(0, 0, 0, 0)
        LeftCol.Parent = Page

        local LeftLayout = Instance.new("UIListLayout")
        LeftLayout.Padding = UDim.new(0, 6)
        LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
        LeftLayout.Parent = LeftCol

        local RightCol = Instance.new("ScrollingFrame")
        RightCol.Name = "Right"
        RightCol.Size = UDim2.new(0.5, -5, 1, 0)
        RightCol.Position = UDim2.new(0.5, 5, 0, 0)
        RightCol.BackgroundTransparency = 1
        RightCol.BorderSizePixel = 0
        RightCol.ScrollBarThickness = 1.5
        RightCol.ScrollBarImageColor3 = Colors.Border
        RightCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
        RightCol.CanvasSize = UDim2.new(0, 0, 0, 0)
        RightCol.Parent = Page

        local RightLayout = Instance.new("UIListLayout")
        RightLayout.Padding = UDim.new(0, 6)
        RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
        RightLayout.Parent = RightCol

        Pages[def.Name] = { Root = Page, Left = LeftCol, Right = RightCol }

        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = def.Name
        TabBtn.Size = UDim2.new(0.25, 0, 1, 0)
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = ""
        TabBtn.Parent = Dock

        local CenterBox = Instance.new("Frame")
        CenterBox.Size = UDim2.new(0, 75, 1, 0)
        CenterBox.AnchorPoint = Vector2.new(0.5, 0.5)
        CenterBox.Position = UDim2.new(0.5, 0, 0.5, 0)
        CenterBox.BackgroundTransparency = 1
        CenterBox.Parent = TabBtn

        local Icon = Instance.new("ImageLabel")
        Icon.Size = UDim2.new(0, 13, 0, 13)
        Icon.Position = UDim2.new(0, 0, 0.5, -6.5)
        Icon.BackgroundTransparency = 1
        Icon.Image = string.format("rbxthumb://type=Asset&id=%s&w=420&h=420", def.Icon)
        Icon.ImageColor3 = Colors.Dark
        Icon.Parent = CenterBox

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -20, 1, 0)
        Label.Position = UDim2.new(0, 20, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = def.Name
        Label.TextColor3 = Colors.Dark
        Label.TextSize = 10
        Label.Font = Enum.Font.GothamMedium
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = CenterBox

        TabButtons[def.Name] = { Icon = Icon, Label = Label }

        TabBtn.MouseButton1Click:Connect(function()
            SwitchTab(def.Name)
        end)
    end

    -- ========================================================================
    -- // HELPER: Вложенные контролы (скрыты внутри функции)
    -- ========================================================================
    local function populateDrawer(drawer)
        local sub = {}

        -- Sub-Toggle
        function sub:AddToggle(title, default, callback)
            local state = default or false

            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 20)
            Row.BackgroundTransparency = 1
            Row.Parent = drawer

            local Box = Instance.new("Frame")
            Box.Size = UDim2.new(0, 12, 0, 12)
            Box.Position = UDim2.new(0, 0, 0.5, -6)
            Box.BackgroundColor3 = state and Colors.White or Colors.Bg
            Box.BorderSizePixel = 0
            Box.Parent = Row

            local BoxCorner = Instance.new("UICorner")
            BoxCorner.CornerRadius = UDim.new(0, 2)
            BoxCorner.Parent = Box

            local BoxStroke = Instance.new("UIStroke")
            BoxStroke.Thickness = 1
            BoxStroke.Color = state and Colors.White or Colors.Border
            BoxStroke.Parent = Box

            local Lbl = Instance.new("TextLabel")
            Lbl.Size = UDim2.new(1, -20, 1, 0)
            Lbl.Position = UDim2.new(0, 20, 0, 0)
            Lbl.BackgroundTransparency = 1
            Lbl.Text = title
            Lbl.TextColor3 = state and Colors.Text or Colors.Muted
            Lbl.TextSize = 9.5
            Lbl.Font = Enum.Font.Gotham
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.Parent = Row

            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 1, 0)
            Btn.BackgroundTransparency = 1
            Btn.Text = ""
            Btn.Parent = Row

            Btn.MouseButton1Click:Connect(function()
                state = not state
                Box.BackgroundColor3 = state and Colors.White or Colors.Bg
                BoxStroke.Color = state and Colors.White or Colors.Border
                Lbl.TextColor3 = state and Colors.Text or Colors.Muted
                if callback then task.spawn(callback, state) end
            end)
        end

        -- Sub-Slider
        function sub:AddSlider(title, min, max, default, step, suffix, callback)
            local val = default or min
            step = step or 1
            suffix = suffix or ""

            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 26)
            Row.BackgroundTransparency = 1
            Row.Parent = drawer

            local Lbl = Instance.new("TextLabel")
            Lbl.Size = UDim2.new(1, -50, 0, 12)
            Lbl.BackgroundTransparency = 1
            Lbl.Text = title
            Lbl.TextColor3 = Colors.Muted
            Lbl.TextSize = 9
            Lbl.Font = Enum.Font.Gotham
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.Parent = Row

            local ValLbl = Instance.new("TextLabel")
            ValLbl.Size = UDim2.new(0, 50, 0, 12)
            ValLbl.Position = UDim2.new(1, -50, 0, 0)
            ValLbl.BackgroundTransparency = 1
            ValLbl.Text = tostring(val) .. suffix
            ValLbl.TextColor3 = Colors.Text
            ValLbl.TextSize = 9
            ValLbl.Font = Enum.Font.GothamMedium
            ValLbl.TextXAlignment = Enum.TextXAlignment.Right
            ValLbl.Parent = Row

            local Track = Instance.new("Frame")
            Track.Size = UDim2.new(1, 0, 0, 2)
            Track.Position = UDim2.new(0, 0, 0, 18)
            Track.BackgroundColor3 = Colors.Track
            Track.BorderSizePixel = 0
            Track.Parent = Row

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new(math.clamp((val - min) / (max - min), 0, 1), 0, 1, 0)
            Fill.BackgroundColor3 = Colors.White
            Fill.BorderSizePixel = 0
            Fill.Parent = Track

            local Trigger = Instance.new("TextButton")
            Trigger.Size = UDim2.new(1, 0, 0, 12)
            Trigger.Position = UDim2.new(0, 0, 0, 13)
            Trigger.BackgroundTransparency = 1
            Trigger.Text = ""
            Trigger.Parent = Row

            local isSliding = false
            local function update(input)
                local w = Track.AbsoluteSize.X
                if w <= 0 then return end
                local pos = math.clamp((input.Position.X - Track.AbsolutePosition.X) / w, 0, 1)
                val = math.floor((min + (max - min) * pos) / step + 0.5) * step
                val = math.clamp(val, min, max)
                ValLbl.Text = ((step < 1) and string.format("%.2f", val) or tostring(val)) .. suffix
                Fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
                if callback then task.spawn(callback, val) end
            end

            Trigger.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    isSliding = true
                    update(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    isSliding = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if isSliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                    update(input)
                end
            end)
        end

        -- Sub-Segmented
        function sub:AddSegmented(title, options, defaultIdx, callback)
            local current = defaultIdx or 1

            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 32)
            Row.BackgroundTransparency = 1
            Row.Parent = drawer

            local Lbl = Instance.new("TextLabel")
            Lbl.Size = UDim2.new(1, 0, 0, 12)
            Lbl.BackgroundTransparency = 1
            Lbl.Text = title
            Lbl.TextColor3 = Colors.Muted
            Lbl.TextSize = 9
            Lbl.Font = Enum.Font.Gotham
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.Parent = Row

            local Bar = Instance.new("Frame")
            Bar.Size = UDim2.new(1, 0, 0, 18)
            Bar.Position = UDim2.new(0, 0, 0, 14)
            Bar.BackgroundColor3 = Colors.Bg
            Bar.BorderSizePixel = 0
            Bar.Parent = Row

            local BarStroke = Instance.new("UIStroke")
            BarStroke.Thickness = 1
            BarStroke.Color = Colors.Border
            BarStroke.Parent = Bar

            local BarLayout = Instance.new("UIListLayout")
            BarLayout.FillDirection = Enum.FillDirection.Horizontal
            BarLayout.Parent = Bar

            local w = 1 / #options
            local btns = {}
            for i, opt in ipairs(options) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Size = UDim2.new(w, 0, 1, 0)
                OptBtn.BackgroundColor3 = (i == current) and Colors.Card or Colors.Bg
                OptBtn.BorderSizePixel = 0
                OptBtn.Text = opt
                OptBtn.TextColor3 = (i == current) and Colors.White or Colors.Muted
                OptBtn.TextSize = 8.5
                OptBtn.Font = Enum.Font.GothamMedium
                OptBtn.Parent = Bar
                btns[i] = OptBtn

                OptBtn.MouseButton1Click:Connect(function()
                    current = i
                    for bIdx, b in ipairs(btns) do
                        b.BackgroundColor3 = (bIdx == current) and Colors.Card or Colors.Bg
                        b.TextColor3 = (bIdx == current) and Colors.White or Colors.Muted
                    end
                    if callback then task.spawn(callback, opt, i) end
                end)
            end
        end

        -- Sub-Button
        function sub:AddButton(btnText, callback)
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 20)
            Btn.BackgroundColor3 = Colors.Card
            Btn.BorderSizePixel = 0
            Btn.Text = btnText
            Btn.TextColor3 = Colors.Text
            Btn.TextSize = 9.5
            Btn.Font = Enum.Font.GothamMedium
            Btn.Parent = drawer

            local BtnStroke = Instance.new("UIStroke")
            BtnStroke.Thickness = 1
            BtnStroke.Color = Colors.Border
            BtnStroke.Parent = Btn

            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 3)
            BtnCorner.Parent = Btn

            Btn.MouseButton1Click:Connect(function()
                if callback then task.spawn(callback) end
            end)
        end

        return sub
    end

    -- ========================================================================
    -- // GROUPBOX & COMPACT FEATURE CARDS
    -- ========================================================================
    local function CreateGroupbox(parent, title)
        local Section = Instance.new("Frame")
        Section.Name = title
        Section.Size = UDim2.new(1, 0, 0, 0)
        Section.AutomaticSize = Enum.AutomaticSize.Y
        Section.BackgroundTransparency = 1
        Section.Parent = parent

        local SectionLayout = Instance.new("UIListLayout")
        SectionLayout.Padding = UDim.new(0, 4)
        SectionLayout.Parent = Section

        local Group = {}

        -- Строка функции (высота всего 30px!)
        function Group:AddFeature(featureTitle, default, callback)
            local isEnabled = default or false
            local isOpen = false

            local Card = Instance.new("Frame")
            Card.Name = featureTitle
            Card.Size = UDim2.new(1, 0, 0, 30)
            Card.AutomaticSize = Enum.AutomaticSize.Y
            Card.BackgroundColor3 = Colors.Card
            Card.BorderSizePixel = 0
            Card.ClipsDescendants = true
            Card.Parent = Section

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 3)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Thickness = 1
            CardStroke.Color = Colors.CardBorder
            CardStroke.Parent = Card

            -- Шапка строки функции (30px)
            local Bar = Instance.new("Frame")
            Bar.Size = UDim2.new(1, 0, 0, 30)
            Bar.BackgroundTransparency = 1
            Bar.Parent = Card

            -- Квадратный чекбокс (13x13)
            local Check = Instance.new("Frame")
            Check.Size = UDim2.new(0, 13, 0, 13)
            Check.Position = UDim2.new(0, 9, 0.5, -6.5)
            Check.BackgroundColor3 = isEnabled and Colors.White or Colors.Bg
            Check.BorderSizePixel = 0
            Check.Parent = Bar

            local CheckCorner = Instance.new("UICorner")
            CheckCorner.CornerRadius = UDim.new(0, 2)
            CheckCorner.Parent = Check

            local CheckStroke = Instance.new("UIStroke")
            CheckStroke.Thickness = 1
            CheckStroke.Color = isEnabled and Colors.White or Colors.Border
            CheckStroke.Parent = Check

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Size = UDim2.new(1, -65, 1, 0)
            TitleLbl.Position = UDim2.new(0, 28, 0, 0)
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.Text = featureTitle
            TitleLbl.TextColor3 = isEnabled and Colors.White or Colors.Muted
            TitleLbl.TextSize = 10.5
            TitleLbl.Font = Enum.Font.GothamMedium
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.Parent = Bar

            -- Шестеренка настроек ⚙
            local Gear = Instance.new("TextButton")
            Gear.Size = UDim2.new(0, 24, 0, 24)
            Gear.Position = UDim2.new(1, -26, 0.5, -12)
            Gear.BackgroundTransparency = 1
            Gear.Text = "⚙"
            Gear.TextColor3 = Colors.Dark
            Gear.TextSize = 13
            Gear.Font = Enum.Font.Gotham
            Gear.Parent = Bar

            local MainClick = Instance.new("TextButton")
            MainClick.Size = UDim2.new(1, -32, 1, 0)
            MainClick.BackgroundTransparency = 1
            MainClick.Text = ""
            MainClick.Parent = Bar

            -- Внутренний контейнер скрытых настроек
            local Drawer = Instance.new("Frame")
            Drawer.Name = "Drawer"
            Drawer.Size = UDim2.new(1, 0, 0, 0)
            Drawer.Position = UDim2.new(0, 0, 0, 30)
            Drawer.AutomaticSize = Enum.AutomaticSize.Y
            Drawer.BackgroundColor3 = Colors.Drawer
            Drawer.BorderSizePixel = 0
            Drawer.Visible = false
            Drawer.Parent = Card

            local DrawerLine = Instance.new("Frame")
            DrawerLine.Size = UDim2.new(1, 0, 0, 1)
            DrawerLine.BackgroundColor3 = Colors.CardBorder
            DrawerLine.BorderSizePixel = 0
            DrawerLine.Parent = Drawer

            local Elements = Instance.new("Frame")
            Elements.Size = UDim2.new(1, -16, 0, 0)
            Elements.Position = UDim2.new(0, 8, 0, 6)
            Elements.AutomaticSize = Enum.AutomaticSize.Y
            Elements.BackgroundTransparency = 1
            Elements.Parent = Drawer

            local ElLayout = Instance.new("UIListLayout")
            ElLayout.Padding = UDim.new(0, 4)
            ElLayout.Parent = Elements

            local Pad = Instance.new("Frame")
            Pad.Size = UDim2.new(1, 0, 0, 4)
            Pad.BackgroundTransparency = 1
            Pad.LayoutOrder = 9999
            Pad.Parent = Elements

            MainClick.MouseButton1Click:Connect(function()
                isEnabled = not isEnabled
                Check.BackgroundColor3 = isEnabled and Colors.White or Colors.Bg
                CheckStroke.Color = isEnabled and Colors.White or Colors.Border
                TitleLbl.TextColor3 = isEnabled and Colors.White or Colors.Muted
                if callback then task.spawn(callback, isEnabled) end
            end)

            Gear.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                Drawer.Visible = isOpen
                Gear.TextColor3 = isOpen and Colors.White or Colors.Dark
            end)

            local subMethods = populateDrawer(Elements)
            function subMethods:SetState(st)
                isEnabled = st
                Check.BackgroundColor3 = isEnabled and Colors.White or Colors.Bg
                CheckStroke.Color = isEnabled and Colors.White or Colors.Border
                TitleLbl.TextColor3 = isEnabled and Colors.White or Colors.Muted
            end
            return subMethods
        end

        -- Секция без мастер-тоггла (для освещения, погоды и т.д.)
        function Group:AddConfigSection(sectionTitle)
            local isOpen = false

            local Card = Instance.new("Frame")
            Card.Name = sectionTitle
            Card.Size = UDim2.new(1, 0, 0, 30)
            Card.AutomaticSize = Enum.AutomaticSize.Y
            Card.BackgroundColor3 = Colors.Card
            Card.BorderSizePixel = 0
            Card.ClipsDescendants = true
            Card.Parent = Section

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 3)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Thickness = 1
            CardStroke.Color = Colors.CardBorder
            CardStroke.Parent = Card

            local Bar = Instance.new("Frame")
            Bar.Size = UDim2.new(1, 0, 0, 30)
            Bar.BackgroundTransparency = 1
            Bar.Parent = Card

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Size = UDim2.new(1, -36, 1, 0)
            TitleLbl.Position = UDim2.new(0, 10, 0, 0)
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.Text = sectionTitle
            TitleLbl.TextColor3 = Colors.Text
            TitleLbl.TextSize = 10.5
            TitleLbl.Font = Enum.Font.GothamMedium
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.Parent = Bar

            local Gear = Instance.new("TextButton")
            Gear.Size = UDim2.new(0, 24, 0, 24)
            Gear.Position = UDim2.new(1, -26, 0.5, -12)
            Gear.BackgroundTransparency = 1
            Gear.Text = "⚙"
            Gear.TextColor3 = Colors.Dark
            Gear.TextSize = 13
            Gear.Font = Enum.Font.Gotham
            Gear.Parent = Bar

            local Trigger = Instance.new("TextButton")
            Trigger.Size = UDim2.new(1, 0, 1, 0)
            Trigger.BackgroundTransparency = 1
            Trigger.Text = ""
            Trigger.Parent = Bar

            local Drawer = Instance.new("Frame")
            Drawer.Size = UDim2.new(1, 0, 0, 0)
            Drawer.Position = UDim2.new(0, 0, 0, 30)
            Drawer.AutomaticSize = Enum.AutomaticSize.Y
            Drawer.BackgroundColor3 = Colors.Drawer
            Drawer.BorderSizePixel = 0
            Drawer.Visible = false
            Drawer.Parent = Card

            local DrawerLine = Instance.new("Frame")
            DrawerLine.Size = UDim2.new(1, 0, 0, 1)
            DrawerLine.BackgroundColor3 = Colors.CardBorder
            DrawerLine.BorderSizePixel = 0
            DrawerLine.Parent = Drawer

            local Elements = Instance.new("Frame")
            Elements.Size = UDim2.new(1, -16, 0, 0)
            Elements.Position = UDim2.new(0, 8, 0, 6)
            Elements.AutomaticSize = Enum.AutomaticSize.Y
            Elements.BackgroundTransparency = 1
            Elements.Parent = Drawer

            local ElLayout = Instance.new("UIListLayout")
            ElLayout.Padding = UDim.new(0, 4)
            ElLayout.Parent = Elements

            local Pad = Instance.new("Frame")
            Pad.Size = UDim2.new(1, 0, 0, 4)
            Pad.BackgroundTransparency = 1
            Pad.LayoutOrder = 9999
            Pad.Parent = Elements

            local function toggle()
                isOpen = not isOpen
                Drawer.Visible = isOpen
                Gear.TextColor3 = isOpen and Colors.White or Colors.Dark
            end

            Gear.MouseButton1Click:Connect(toggle)
            Trigger.MouseButton1Click:Connect(toggle)

            return populateDrawer(Elements)
        end

        function Group:AddButton(btnText, callback)
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 26)
            Btn.BackgroundColor3 = Colors.Card
            Btn.BorderSizePixel = 0
            Btn.Text = btnText
            Btn.TextColor3 = Colors.Text
            Btn.TextSize = 10
            Btn.Font = Enum.Font.GothamMedium
            Btn.Parent = Section

            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 3)
            BtnCorner.Parent = Btn

            local BtnStroke = Instance.new("UIStroke")
            BtnStroke.Thickness = 1
            BtnStroke.Color = Colors.CardBorder
            BtnStroke.Parent = Btn

            Btn.MouseButton1Click:Connect(function()
                if callback then task.spawn(callback) end
            end)
        end

        return Group
    end

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
