-- // src/ui.lua
local UI = {}

local function getService(name)
    local s = game:GetService(name)
    return (cloneref and cloneref(s)) or s
end

local TweenService = getService("TweenService")
local UserInputService = getService("UserInputService")
local CoreGui = getService("CoreGui")
local Players = getService("Players")
local LocalPlayer = Players.LocalPlayer

local THEME = {
    MainBg       = Color3.fromRGB(10, 10, 13),
    TopbarBg     = Color3.fromRGB(13, 13, 17),
    GroupBg      = Color3.fromRGB(15, 15, 20),
    InputBg      = Color3.fromRGB(20, 20, 27),
    Border       = Color3.fromRGB(28, 28, 36),
    Accent       = Color3.fromRGB(75, 115, 245),
    AccentDim    = Color3.fromRGB(35, 45, 75),
    TextLight    = Color3.fromRGB(235, 235, 242),
    TextDim      = Color3.fromRGB(140, 145, 160),
    TextDark     = Color3.fromRGB(80, 85, 95)
}

local function tween(obj, props, t)
    local tw = TweenService:Create(obj, TweenInfo.new(t or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

function UI.Init()
    local Lib = { Connections = {}, Pages = {} }

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AntiloseClientUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    pcall(function()
        if gethui then
            ScreenGui.Parent = gethui()
        elseif syn and syn.protect_gui then
            syn.protect_gui(ScreenGui)
            ScreenGui.Parent = CoreGui
        else
            ScreenGui.Parent = CoreGui
        end
    end)
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    Lib.ScreenGui = ScreenGui

    -- Главное окно
    local Main = Instance.new("Frame")
    Main.Name = "MainWindow"
    Main.Size = UDim2.new(0, 580, 0, 440)
    Main.Position = UDim2.new(0.5, -290, 0.5, -220)
    Main.BackgroundColor3 = THEME.MainBg
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Thickness = 1
    MainStroke.Color = Color3.fromRGB(255, 255, 255)
    MainStroke.Parent = Main

    local MainStrokeGrad = Instance.new("UIGradient")
    MainStrokeGrad.Rotation = 90
    MainStrokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(180, 180, 190)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 50, 58)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(24, 24, 28))
    })
    MainStrokeGrad.Parent = MainStroke

    -- Верхняя панель (Topbar)
    local Topbar = Instance.new("Frame")
    Topbar.Size = UDim2.new(1, 0, 0, 36)
    Topbar.BackgroundColor3 = THEME.TopbarBg
    Topbar.BorderSizePixel = 0
    Topbar.Parent = Main

    local TopbarSep = Instance.new("Frame")
    TopbarSep.Size = UDim2.new(1, 0, 0, 1)
    TopbarSep.Position = UDim2.new(0, 0, 1, -1)
    TopbarSep.BackgroundColor3 = THEME.Border
    TopbarSep.BorderSizePixel = 0
    TopbarSep.Parent = Topbar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -24, 1, 0)
    Title.Position = UDim2.new(0, 14, 0, 0)
    Title.BackgroundTransparency = 1
    Title.RichText = true
    Title.Text = "<b>ANTILOSE</b>  <font color=\"rgb(75,115,245)\">//</font>  CLIENT"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 12
    Title.TextColor3 = THEME.TextLight
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Topbar

    -- Dragging
    local isDragging, dragStart, startPos
    Topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end)
    local dragInput = UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    local dragEnd = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false end
    end)
    table.insert(Lib.Connections, dragInput)
    table.insert(Lib.Connections, dragEnd)

    -- Контейнер страниц
    local PagesContainer = Instance.new("Frame")
    PagesContainer.Size = UDim2.new(1, 0, 1, -74)
    PagesContainer.Position = UDim2.new(0, 0, 0, 36)
    PagesContainer.BackgroundTransparency = 1
    PagesContainer.Parent = Main

    -- Нижняя панель вкладок
    local BottomNav = Instance.new("Frame")
    BottomNav.Size = UDim2.new(1, 0, 0, 38)
    BottomNav.Position = UDim2.new(0, 0, 1, -38)
    BottomNav.BackgroundColor3 = THEME.TopbarBg
    BottomNav.BorderSizePixel = 0
    BottomNav.Parent = Main

    local BottomSep = Instance.new("Frame")
    BottomSep.Size = UDim2.new(1, 0, 0, 1)
    BottomSep.BackgroundColor3 = THEME.Border
    BottomSep.BorderSizePixel = 0
    BottomSep.Parent = BottomNav

    local NavLayout = Instance.new("UIListLayout")
    NavLayout.FillDirection = Enum.FillDirection.Horizontal
    NavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    NavLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    NavLayout.Padding = UDim.new(0, 10)
    NavLayout.Parent = BottomNav

    local Tabs = { "Aim", "Visuals", "World", "Settings" }
    local TabButtons = {}

    for idx, tabName in ipairs(Tabs) do
        local Page = Instance.new("Frame")
        Page.Name = tabName .. "Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.Visible = false
        Page.Parent = PagesContainer

        local LeftCol = Instance.new("ScrollingFrame")
        LeftCol.Size = UDim2.new(0.5, -12, 1, -12)
        LeftCol.Position = UDim2.new(0, 8, 0, 6)
        LeftCol.BackgroundTransparency = 1
        LeftCol.ScrollBarThickness = 2
        LeftCol.ScrollBarImageColor3 = THEME.Border
        LeftCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
        LeftCol.CanvasSize = UDim2.new(0, 0, 0, 0)
        LeftCol.Parent = Page

        local RightCol = LeftCol:Clone()
        RightCol.Position = UDim2.new(0.5, 4, 0, 6)
        RightCol.Parent = Page

        local function setupColumn(col)
            local layout = Instance.new("UIListLayout")
            layout.Padding = UDim.new(0, 8)
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Parent = col
            local pad = Instance.new("UIPadding")
            pad.PaddingRight = UDim.new(0, 4)
            pad.Parent = col
        end
        setupColumn(LeftCol)
        setupColumn(RightCol)

        Lib.Pages[tabName] = { Page = Page, Left = LeftCol, Right = RightCol }

        -- Кнопка вкладки снизу
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(0, 115, 0, 26)
        TabBtn.BackgroundColor3 = THEME.MainBg
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = string.upper(tabName)
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextSize = 10
        TabBtn.TextColor3 = THEME.TextDark
        TabBtn.AutoButtonColor = false
        TabBtn.Parent = BottomNav

        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 4)
        BtnCorner.Parent = TabBtn

        local Indicator = Instance.new("Frame")
        Indicator.Size = UDim2.new(0.6, 0, 0, 2)
        Indicator.Position = UDim2.new(0.2, 0, 1, -2)
        Indicator.BackgroundColor3 = THEME.Accent
        Indicator.BorderSizePixel = 0
        Indicator.Visible = false
        Indicator.Parent = TabBtn

        TabButtons[tabName] = { Button = TabBtn, Indicator = Indicator }

        TabBtn.MouseButton1Click:Connect(function()
            Lib.SwitchTab(tabName, idx)
        end)
    end

    function Lib.SwitchTab(name, index)
        for tName, data in pairs(Lib.Pages) do
            local isCur = (tName == name)
            data.Page.Visible = isCur
            local tabObj = TabButtons[tName]
            if tabObj then
                if isCur then
                    tween(tabObj.Button, { TextColor3 = THEME.TextLight, BackgroundTransparency = 0.5 }, 0.2)
                    tabObj.Indicator.Visible = true
                else
                    tween(tabObj.Button, { TextColor3 = THEME.TextDark, BackgroundTransparency = 1 }, 0.2)
                    tabObj.Indicator.Visible = false
                end
            end
        end
    end

    -- ========================================================================
    -- // СОЗДАНИЕ ГРУПП (GROUPBOXES)
    -- ========================================================================
    function Lib.CreateGroupbox(parent, title)
        local Group = Instance.new("Frame")
        Group.AutomaticSize = Enum.AutomaticSize.Y
        Group.Size = UDim2.new(1, 0, 0, 0)
        Group.BackgroundColor3 = THEME.GroupBg
        Group.BorderSizePixel = 0
        Group.Parent = parent

        local GCorner = Instance.new("UICorner")
        GCorner.CornerRadius = UDim.new(0, 6)
        GCorner.Parent = Group

        local GStroke = Instance.new("UIStroke")
        GStroke.Thickness = 1
        GStroke.Color = Color3.fromRGB(255, 255, 255)
        GStroke.Parent = Group

        local GStrokeGrad = Instance.new("UIGradient")
        GStrokeGrad.Rotation = 90
        GStrokeGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.0, Color3.fromRGB(180, 180, 190)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 50, 58)),
            ColorSequenceKeypoint.new(1.0, Color3.fromRGB(24, 24, 28))
        })
        GStrokeGrad.Parent = GStroke

        local GPad = Instance.new("UIPadding")
        GPad.PaddingTop = UDim.new(0, 8)
        GPad.PaddingBottom = UDim.new(0, 8)
        GPad.PaddingLeft = UDim.new(0, 10)
        GPad.PaddingRight = UDim.new(0, 10)
        GPad.Parent = Group

        local GList = Instance.new("UIListLayout")
        GList.Padding = UDim.new(0, 6)
        GList.SortOrder = Enum.SortOrder.LayoutOrder
        GList.Parent = Group

        local GHeader = Instance.new("TextLabel")
        GHeader.Size = UDim2.new(1, 0, 0, 16)
        GHeader.BackgroundTransparency = 1
        GHeader.Text = string.upper(title)
        GHeader.Font = Enum.Font.GothamBold
        GHeader.TextSize = 10
        GHeader.TextColor3 = THEME.TextDim
        GHeader.TextXAlignment = Enum.TextXAlignment.Left
        GHeader.Parent = Group

        local GSep = Instance.new("Frame")
        GSep.Size = UDim2.new(1, 0, 0, 1)
        GSep.BackgroundColor3 = THEME.Border
        GSep.BorderSizePixel = 0
        GSep.Parent = Group

        local Methods = {}

        -- Toggle
        function Methods:AddToggle(toggleTitle, default, callback)
            local isToggled = default or false
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 20)
            Row.BackgroundTransparency = 1
            Row.Parent = Group

            local Checkbox = Instance.new("TextButton")
            Checkbox.Size = UDim2.new(0, 14, 0, 14)
            Checkbox.Position = UDim2.new(0, 0, 0.5, -7)
            Checkbox.BackgroundColor3 = isToggled and THEME.Accent or THEME.InputBg
            Checkbox.Text = ""
            Checkbox.AutoButtonColor = false
            Checkbox.Parent = Row

            local CCorner = Instance.new("UICorner")
            CCorner.CornerRadius = UDim.new(0, 3)
            CCorner.Parent = Checkbox

            local CStroke = Instance.new("UIStroke")
            CStroke.Thickness = 1
            CStroke.Color = isToggled and THEME.Accent or THEME.Border
            CStroke.Parent = Checkbox

            local Checkmark = Instance.new("Frame")
            Checkmark.Size = UDim2.new(0, 6, 0, 6)
            Checkmark.Position = UDim2.new(0.5, -3, 0.5, -3)
            Checkmark.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Checkmark.BorderSizePixel = 0
            Checkmark.Visible = isToggled
            Checkmark.Parent = Checkbox

            local Label = Instance.new("TextButton")
            Label.Size = UDim2.new(1, -22, 1, 0)
            Label.Position = UDim2.new(0, 22, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = toggleTitle
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 11
            Label.TextColor3 = isToggled and THEME.TextLight or THEME.TextDim
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.AutoButtonColor = false
            Label.Parent = Row

            local function toggle()
                isToggled = not isToggled
                Checkmark.Visible = isToggled
                tween(Checkbox, { BackgroundColor3 = isToggled and THEME.Accent or THEME.InputBg }, 0.15)
                tween(CStroke, { Color = isToggled and THEME.Accent or THEME.Border }, 0.15)
                tween(Label, { TextColor3 = isToggled and THEME.TextLight or THEME.TextDim }, 0.15)
                if callback then callback(isToggled) end
            end

            Checkbox.MouseButton1Click:Connect(toggle)
            Label.MouseButton1Click:Connect(toggle)
        end

        -- Slider
        function Methods:AddSlider(sliderTitle, min, max, default, step, suffix, callback)
            local curVal = default or min
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 28)
            Row.BackgroundTransparency = 1
            Row.Parent = Group

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(0.65, 0, 0, 14)
            Label.BackgroundTransparency = 1
            Label.Text = sliderTitle
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 10
            Label.TextColor3 = THEME.TextDim
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Row

            local ValLabel = Instance.new("TextLabel")
            ValLabel.Size = UDim2.new(0.35, 0, 0, 14)
            ValLabel.Position = UDim2.new(0.65, 0, 0, 0)
            ValLabel.BackgroundTransparency = 1
            ValLabel.Text = tostring(curVal) .. (suffix or "")
            ValLabel.Font = Enum.Font.GothamMedium
            ValLabel.TextSize = 10
            ValLabel.TextColor3 = THEME.TextDark
            ValLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValLabel.Parent = Row

            local Bar = Instance.new("Frame")
            Bar.Size = UDim2.new(1, 0, 0, 4)
            Bar.Position = UDim2.new(0, 0, 1, -5)
            Bar.BackgroundColor3 = THEME.InputBg
            Bar.BorderSizePixel = 0
            Bar.Parent = Row

            local BarCorner = Instance.new("UICorner")
            BarCorner.CornerRadius = UDim.new(1, 0)
            BarCorner.Parent = Bar

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new(math.clamp((curVal - min) / (max - min), 0, 1), 0, 1, 0)
            Fill.BackgroundColor3 = THEME.Accent
            Fill.BorderSizePixel = 0
            Fill.Parent = Bar

            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(1, 0)
            FillCorner.Parent = Fill

            local sliding = false
            local function update(xPos)
                local perc = math.clamp((xPos - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                local val = min + (max - min) * perc
                if step then val = math.floor(val / step + 0.5) * step end
                val = math.clamp(val, min, max)
                Fill.Size = UDim2.new(perc, 0, 1, 0)
                ValLabel.Text = string.format(step and (step < 1 and "%.2f" or "%d") or "%.1f", val) .. (suffix or "")
                if callback then callback(val) end
            end

            Row.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliding = true
                    update(input.Position.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                    update(input.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliding = false
                end
            end)
        end

        -- Segmented
        function Methods:AddSegmented(segTitle, options, defaultIndex, callback)
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 24)
            Row.BackgroundTransparency = 1
            Row.Parent = Group

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(0.35, 0, 1, 0)
            Label.BackgroundTransparency = 1
            Label.Text = segTitle
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 10
            Label.TextColor3 = THEME.TextDim
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Row

            local SegBar = Instance.new("Frame")
            SegBar.Size = UDim2.new(0.65, 0, 1, 0)
            SegBar.Position = UDim2.new(0.35, 0, 0, 0)
            SegBar.BackgroundColor3 = THEME.InputBg
            SegBar.BorderSizePixel = 0
            SegBar.Parent = Row

            local SCorner = Instance.new("UICorner")
            SCorner.CornerRadius = UDim.new(0, 4)
            SCorner.Parent = SegBar

            local SStroke = Instance.new("UIStroke")
            SStroke.Thickness = 1
            SStroke.Color = THEME.Border
            SStroke.Parent = SegBar

            local SLayout = Instance.new("UIListLayout")
            SLayout.FillDirection = Enum.FillDirection.Horizontal
            SLayout.Parent = SegBar

            local activeIndex = defaultIndex or 1
            local buttons = {}

            for idx, opt in ipairs(options) do
                local Btn = Instance.new("TextButton")
                Btn.Size = UDim2.new(1 / #options, 0, 1, 0)
                Btn.BackgroundTransparency = (idx == activeIndex) and 0 or 1
                Btn.BackgroundColor3 = THEME.AccentDim
                Btn.Text = opt
                Btn.Font = Enum.Font.GothamBold
                Btn.TextSize = 8
                Btn.TextColor3 = (idx == activeIndex) and THEME.TextLight or THEME.TextDark
                Btn.AutoButtonColor = false
                Btn.Parent = SegBar

                local bCorner = Instance.new("UICorner")
                bCorner.CornerRadius = UDim.new(0, 4)
                bCorner.Parent = Btn

                Btn.MouseButton1Click:Connect(function()
                    for i, b in ipairs(buttons) do
                        b.BackgroundTransparency = (i == idx) and 0 or 1
                        b.TextColor3 = (i == idx) and THEME.TextLight or THEME.TextDark
                    end
                    if callback then callback(opt) end
                end)
                table.insert(buttons, Btn)
            end
        end

        -- Button
        function Methods:AddButton(btnText, callback)
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 24)
            Btn.BackgroundColor3 = THEME.InputBg
            Btn.Text = btnText
            Btn.Font = Enum.Font.GothamMedium
            Btn.TextSize = 10
            Btn.TextColor3 = THEME.TextLight
            Btn.AutoButtonColor = false
            Btn.Parent = Group

            local bCorner = Instance.new("UICorner")
            bCorner.CornerRadius = UDim.new(0, 4)
            bCorner.Parent = Btn

            local bStroke = Instance.new("UIStroke")
            bStroke.Thickness = 1
            bStroke.Color = THEME.Border
            bStroke.Parent = Btn

            Btn.MouseButton1Click:Connect(function()
                tween(Btn, { BackgroundColor3 = THEME.Border }, 0.1).Completed:Connect(function()
                    tween(Btn, { BackgroundColor3 = THEME.InputBg }, 0.15)
                end)
                if callback then callback() end
            end)
        end

        return Methods
    end

    return Lib
end

return UI
