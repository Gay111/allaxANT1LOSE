-- // src/ui.lua
local UI = {}

local function getService(name)
    local s = game:GetService(name)
    return (cloneref and cloneref(s)) or s
end

local TweenService = getService("TweenService")
local UserInputService = getService("UserInputService")
local CoreGui = getService("CoreGui")

local THEME = {
    Background = Color3.fromRGB(13, 14, 17),
    Card = Color3.fromRGB(18, 20, 24),
    CardHover = Color3.fromRGB(22, 24, 30),
    CardExpanded = Color3.fromRGB(15, 16, 20),
    Border = Color3.fromRGB(28, 30, 38),
    BorderFocus = Color3.fromRGB(45, 49, 62),
    Accent = Color3.fromRGB(100, 135, 245),
    AccentDim = Color3.fromRGB(45, 55, 90),
    Text = Color3.fromRGB(230, 232, 240),
    TextDark = Color3.fromRGB(100, 105, 120),
    Green = Color3.fromRGB(75, 210, 140)
}

local function tween(obj, props, t, style, dir)
    local tw = TweenService:Create(obj, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

function UI.Init()
    local Lib = { Connections = {}, Pages = {} }

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AntiloseStealth"
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

    -- Основное окно (компактное)
    local Main = Instance.new("Frame")
    Main.Name = "MainWindow"
    Main.Size = UDim2.new(0, 560, 0, 420)
    Main.Position = UDim2.new(0.5, -280, 0.5, -210)
    Main.BackgroundColor3 = THEME.Background
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Thickness = 1
    MainStroke.Color = THEME.Border
    MainStroke.Parent = Main

    -- Шапка
    local Topbar = Instance.new("Frame")
    Topbar.Size = UDim2.new(1, 0, 0, 34)
    Topbar.BackgroundTransparency = 1
    Topbar.Parent = Main

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -30, 1, 0)
    Title.Position = UDim2.new(0, 16, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "ANTILOSE <font color=\"rgb(100,135,245)\">//</font> STEALTH"
    Title.RichText = true
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 11
    Title.TextColor3 = THEME.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Topbar

    local SepTop = Instance.new("Frame")
    SepTop.Size = UDim2.new(1, 0, 0, 1)
    SepTop.Position = UDim2.new(0, 0, 0, 34)
    SepTop.BackgroundColor3 = THEME.Border
    SepTop.BorderSizePixel = 0
    SepTop.Parent = Main

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
    local PagesFolder = Instance.new("Frame")
    PagesFolder.Size = UDim2.new(1, 0, 1, -74)
    PagesFolder.Position = UDim2.new(0, 0, 0, 35)
    PagesFolder.BackgroundTransparency = 1
    PagesFolder.Parent = Main

    -- Нижняя панель вкладок
    local BottomNav = Instance.new("Frame")
    BottomNav.Size = UDim2.new(1, 0, 0, 38)
    BottomNav.Position = UDim2.new(0, 0, 1, -38)
    BottomNav.BackgroundColor3 = THEME.Card
    BottomNav.BorderSizePixel = 0
    BottomNav.Parent = Main

    local SepBottom = Instance.new("Frame")
    SepBottom.Size = UDim2.new(1, 0, 0, 1)
    SepBottom.BackgroundColor3 = THEME.Border
    SepBottom.BorderSizePixel = 0
    SepBottom.Parent = BottomNav

    local NavLayout = Instance.new("UIListLayout")
    NavLayout.FillDirection = Enum.FillDirection.Horizontal
    NavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    NavLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    NavLayout.Padding = UDim.new(0, 6)
    NavLayout.Parent = BottomNav

    local Tabs = { "Aim", "Visuals", "World", "Settings" }
    local TabButtons = {}

    for _, tabName in ipairs(Tabs) do
        local Page = Instance.new("Frame")
        Page.Name = tabName .. "Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.Visible = false
        Page.Parent = PagesFolder

        local LeftCol = Instance.new("ScrollingFrame")
        LeftCol.Size = UDim2.new(0.5, -12, 1, -12)
        LeftCol.Position = UDim2.new(0, 8, 0, 6)
        LeftCol.BackgroundTransparency = 1
        LeftCol.ScrollBarThickness = 2
        LeftCol.ScrollBarImageColor3 = THEME.BorderFocus
        LeftCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
        LeftCol.CanvasSize = UDim2.new(0, 0, 0, 0)
        LeftCol.Parent = Page

        local RightCol = LeftCol:Clone()
        RightCol.Position = UDim2.new(0.5, 4, 0, 6)
        RightCol.Parent = Page

        local function setupList(parent)
            local l = Instance.new("UIListLayout")
            l.Padding = UDim.new(0, 6)
            l.SortOrder = Enum.SortOrder.LayoutOrder
            l.Parent = parent
            local pad = Instance.new("UIPadding")
            pad.PaddingRight = UDim.new(0, 4)
            pad.Parent = parent
        end
        setupList(LeftCol)
        setupList(RightCol)

        Lib.Pages[tabName] = { Page = Page, Left = LeftCol, Right = RightCol }

        -- Кнопка вкладки снизу
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(0, 110, 0, 26)
        TabBtn.BackgroundColor3 = THEME.Background
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = string.upper(tabName)
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextSize = 10
        TabBtn.TextColor3 = THEME.TextDark
        TabBtn.AutoButtonColor = false
        TabBtn.Parent = BottomNav

        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 5)
        BtnCorner.Parent = TabBtn

        TabButtons[tabName] = TabBtn

        TabBtn.MouseButton1Click:Connect(function()
            Lib.SwitchTab(tabName)
        end)
    end

    function Lib.SwitchTab(name)
        for tName, data in pairs(Lib.Pages) do
            local isCur = (tName == name)
            data.Page.Visible = isCur
            local btn = TabButtons[tName]
            if isCur then
                tween(btn, { BackgroundTransparency = 0, TextColor3 = THEME.Text }, 0.25)
            else
                tween(btn, { BackgroundTransparency = 1, TextColor3 = THEME.TextDark }, 0.25)
            end
        end
    end

    -- ========================================================================
    -- // АККОРДЕОНЫ И ЭКОНОМИЯ МЕСТА
    -- ========================================================================
    function Lib.CreateGroupbox(parent, title)
        local Group = Instance.new("Frame")
        Group.AutomaticSize = Enum.AutomaticSize.Y
        Group.Size = UDim2.new(1, 0, 0, 0)
        Group.BackgroundTransparency = 1
        Group.Parent = parent

        local GList = Instance.new("UIListLayout")
        GList.Padding = UDim.new(0, 5)
        GList.SortOrder = Enum.SortOrder.LayoutOrder
        GList.Parent = Group

        local GHeader = Instance.new("TextLabel")
        GHeader.Size = UDim2.new(1, 0, 0, 18)
        GHeader.BackgroundTransparency = 1
        GHeader.Text = string.upper(title)
        GHeader.Font = Enum.Font.GothamBold
        GHeader.TextSize = 9
        GHeader.TextColor3 = THEME.TextDark
        GHeader.TextXAlignment = Enum.TextXAlignment.Left
        GHeader.Parent = Group

        local BoxMethods = {}

        -- Создание раскрывающейся функции (Master-Toggle + Drawer)
        function BoxMethods:AddFeature(featTitle, defaultState, callback)
            local isToggled = defaultState or false
            local isExpanded = false

            local Card = Instance.new("Frame")
            Card.Size = UDim2.new(1, 0, 0, 30)
            Card.BackgroundColor3 = THEME.Card
            Card.BorderSizePixel = 0
            Card.ClipsDescendants = true
            Card.Parent = Group

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 6)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Thickness = 1
            CardStroke.Color = THEME.Border
            CardStroke.Parent = Card

            -- Шапка карточки
            local HeaderBar = Instance.new("Frame")
            HeaderBar.Size = UDim2.new(1, 0, 0, 30)
            HeaderBar.BackgroundTransparency = 1
            HeaderBar.Parent = Card

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -75, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = featTitle
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 11
            Label.TextColor3 = THEME.Text
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = HeaderBar

            -- Тумблер Вкл / Выкл
            local ToggleSwitch = Instance.new("TextButton")
            ToggleSwitch.Size = UDim2.new(0, 30, 0, 16)
            ToggleSwitch.Position = UDim2.new(1, -62, 0.5, -8)
            ToggleSwitch.BackgroundColor3 = isToggled and THEME.Accent or THEME.BorderFocus
            ToggleSwitch.AutoButtonColor = false
            ToggleSwitch.Text = ""
            ToggleSwitch.Parent = HeaderBar

            local SwCorner = Instance.new("UICorner")
            SwCorner.CornerRadius = UDim.new(1, 0)
            SwCorner.Parent = ToggleSwitch

            local SwDot = Instance.new("Frame")
            SwDot.Size = UDim2.new(0, 12, 0, 12)
            SwDot.Position = isToggled and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
            SwDot.BackgroundColor3 = THEME.Text
            SwDot.BorderSizePixel = 0
            SwDot.Parent = ToggleSwitch

            local DotCorner = Instance.new("UICorner")
            DotCorner.CornerRadius = UDim.new(1, 0)
            DotCorner.Parent = SwDot

            ToggleSwitch.MouseButton1Click:Connect(function()
                isToggled = not isToggled
                tween(ToggleSwitch, { BackgroundColor3 = isToggled and THEME.Accent or THEME.BorderFocus }, 0.2)
                tween(SwDot, { Position = isToggled and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6) }, 0.2)
                if callback then callback(isToggled) end
            end)

            -- Кнопка раскрытия настроек
            local ExpandBtn = Instance.new("TextButton")
            ExpandBtn.Size = UDim2.new(0, 22, 0, 22)
            ExpandBtn.Position = UDim2.new(1, -26, 0.5, -11)
            ExpandBtn.BackgroundTransparency = 1
            ExpandBtn.Text = "▾"
            ExpandBtn.Font = Enum.Font.GothamBold
            ExpandBtn.TextSize = 13
            ExpandBtn.TextColor3 = THEME.TextDark
            ExpandBtn.AutoButtonColor = false
            ExpandBtn.Parent = HeaderBar

            -- Контейнер поднастроек
            local Drawer = Instance.new("Frame")
            Drawer.Position = UDim2.new(0, 0, 0, 30)
            Drawer.Size = UDim2.new(1, 0, 0, 0)
            Drawer.AutomaticSize = Enum.AutomaticSize.Y
            Drawer.BackgroundColor3 = THEME.CardExpanded
            Drawer.BorderSizePixel = 0
            Drawer.Visible = false
            Drawer.Parent = Card

            local DPad = Instance.new("UIPadding")
            DPad.PaddingTop = UDim.new(0, 6)
            DPad.PaddingBottom = UDim.new(0, 8)
            DPad.PaddingLeft = UDim.new(0, 10)
            DPad.PaddingRight = UDim.new(0, 10)
            DPad.Parent = Drawer

            local DList = Instance.new("UIListLayout")
            DList.Padding = UDim.new(0, 6)
            DList.SortOrder = Enum.SortOrder.LayoutOrder
            DList.Parent = Drawer

            local function toggleDrawer()
                isExpanded = not isExpanded
                if isExpanded then
                    Drawer.Visible = true
                    tween(ExpandBtn, { Rotation = 180, TextColor3 = THEME.Accent }, 0.25)
                    Card.AutomaticSize = Enum.AutomaticSize.Y
                else
                    tween(ExpandBtn, { Rotation = 0, TextColor3 = THEME.TextDark }, 0.25)
                    Card.AutomaticSize = Enum.AutomaticSize.None
                    tween(Card, { Size = UDim2.new(1, 0, 0, 30) }, 0.25).Completed:Connect(function()
                        if not isExpanded then Drawer.Visible = false end
                    end)
                end
            end

            ExpandBtn.MouseButton1Click:Connect(toggleDrawer)

            local SubMethods = {}

            -- Слайдер внутри карточки
            function SubMethods:AddSlider(sName, min, max, default, step, suffix, sCallback)
                local curVal = default or min
                local Row = Instance.new("Frame")
                Row.Size = UDim2.new(1, 0, 0, 26)
                Row.BackgroundTransparency = 1
                Row.Parent = Drawer

                local sLabel = Instance.new("TextLabel")
                sLabel.Size = UDim2.new(0.6, 0, 0, 14)
                sLabel.BackgroundTransparency = 1
                sLabel.Text = sName
                sLabel.Font = Enum.Font.GothamMedium
                sLabel.TextSize = 10
                sLabel.TextColor3 = THEME.Text
                sLabel.TextXAlignment = Enum.TextXAlignment.Left
                sLabel.Parent = Row

                local ValLabel = Instance.new("TextLabel")
                ValLabel.Size = UDim2.new(0.4, 0, 0, 14)
                ValLabel.Position = UDim2.new(0.6, 0, 0, 0)
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
                Bar.BackgroundColor3 = THEME.Border
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
                local function updateSlider(xPos)
                    local perc = math.clamp((xPos - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                    local val = min + (max - min) * perc
                    if step then val = math.floor(val / step + 0.5) * step end
                    val = math.clamp(val, min, max)
                    Fill.Size = UDim2.new(perc, 0, 1, 0)
                    ValLabel.Text = string.format(step and (step < 1 and "%.2f" or "%d") or "%.1f", val) .. (suffix or "")
                    if sCallback then sCallback(val) end
                end

                Row.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = true
                        updateSlider(inp.Position.X)
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        updateSlider(inp.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
                end)
            end

            -- Выбор режимов
            function SubMethods:AddSegmented(segTitle, options, defIdx, segCallback)
                local Row = Instance.new("Frame")
                Row.Size = UDim2.new(1, 0, 0, 24)
                Row.BackgroundTransparency = 1
                Row.Parent = Drawer

                local sLabel = Instance.new("TextLabel")
                sLabel.Size = UDim2.new(0.35, 0, 1, 0)
                sLabel.BackgroundTransparency = 1
                sLabel.Text = segTitle
                sLabel.Font = Enum.Font.GothamMedium
                sLabel.TextSize = 10
                sLabel.TextColor3 = THEME.Text
                sLabel.TextXAlignment = Enum.TextXAlignment.Left
                sLabel.Parent = Row

                local SegBar = Instance.new("Frame")
                SegBar.Size = UDim2.new(0.65, 0, 1, 0)
                SegBar.Position = UDim2.new(0.35, 0, 0, 0)
                SegBar.BackgroundColor3 = THEME.Border
                SegBar.Parent = Row

                local SCorner = Instance.new("UICorner")
                SCorner.CornerRadius = UDim.new(0, 4)
                SCorner.Parent = SegBar

                local SLayout = Instance.new("UIListLayout")
                SLayout.FillDirection = Enum.FillDirection.Horizontal
                SLayout.Parent = SegBar

                local activeIndex = defIdx or 1
                local btns = {}

                for i, opt in ipairs(options) do
                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(1 / #options, 0, 1, 0)
                    btn.BackgroundTransparency = (i == activeIndex) and 0 or 1
                    btn.BackgroundColor3 = THEME.AccentDim
                    btn.Text = opt
                    btn.Font = Enum.Font.GothamBold
                    btn.TextSize = 8
                    btn.TextColor3 = (i == activeIndex) and THEME.Text or THEME.TextDark
                    btn.AutoButtonColor = false
                    btn.Parent = SegBar

                    local bCorn = Instance.new("UICorner")
                    bCorn.CornerRadius = UDim.new(0, 4)
                    bCorn.Parent = btn

                    btn.MouseButton1Click:Connect(function()
                        for idx, b in ipairs(btns) do
                            b.BackgroundTransparency = (idx == i) and 0 or 1
                            b.TextColor3 = (idx == i) and THEME.Text or THEME.TextDark
                        end
                        if segCallback then segCallback(opt) end
                    end)
                    table.insert(btns, btn)
                end
            end

            -- Обычный тумблер внутри поднастроек
            function SubMethods:AddToggle(subTitle, subDef, subCb)
                local subTog = subDef or false
                local Row = Instance.new("Frame")
                Row.Size = UDim2.new(1, 0, 0, 20)
                Row.BackgroundTransparency = 1
                Row.Parent = Drawer

                local sLabel = Instance.new("TextLabel")
                sLabel.Size = UDim2.new(0.7, 0, 1, 0)
                sLabel.BackgroundTransparency = 1
                sLabel.Text = subTitle
                sLabel.Font = Enum.Font.GothamMedium
                sLabel.TextSize = 10
                sLabel.TextColor3 = THEME.Text
                sLabel.TextXAlignment = Enum.TextXAlignment.Left
                sLabel.Parent = Row

                local tBtn = Instance.new("TextButton")
                tBtn.Size = UDim2.new(0, 24, 0, 12)
                tBtn.Position = UDim2.new(1, -24, 0.5, -6)
                tBtn.BackgroundColor3 = subTog and THEME.Accent or THEME.BorderFocus
                tBtn.Text = ""
                tBtn.AutoButtonColor = false
                tBtn.Parent = Row

                local tCorn = Instance.new("UICorner")
                tCorn.CornerRadius = UDim.new(1, 0)
                tCorn.Parent = tBtn

                tBtn.MouseButton1Click:Connect(function()
                    subTog = not subTog
                    tween(tBtn, { BackgroundColor3 = subTog and THEME.Accent or THEME.BorderFocus }, 0.2)
                    if subCb then subCb(subTog) end
                end)
            end

            return SubMethods
        end

        -- Стандартные элементы для настроек верхнего уровня (без раскрытия)
        function BoxMethods:AddButton(btnText, bCallback)
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 26)
            Btn.BackgroundColor3 = THEME.Card
            Btn.Text = btnText
            Btn.Font = Enum.Font.GothamMedium
            Btn.TextSize = 10
            Btn.TextColor3 = THEME.Text
            Btn.AutoButtonColor = false
            Btn.Parent = Group

            local bCorn = Instance.new("UICorner")
            bCorn.CornerRadius = UDim.new(0, 5)
            bCorn.Parent = Btn

            local bStroke = Instance.new("UIStroke")
            bStroke.Thickness = 1
            bStroke.Color = THEME.Border
            bStroke.Parent = Btn

            Btn.MouseButton1Click:Connect(function()
                tween(Btn, { BackgroundColor3 = THEME.BorderFocus }, 0.1).Completed:Connect(function()
                    tween(Btn, { BackgroundColor3 = THEME.Card }, 0.15)
                end)
                if bCallback then bCallback() end
            end)
        end

        function BoxMethods:AddToggle(tTitle, def, cb)
            local f = BoxMethods:AddFeature(tTitle, def, cb)
            return f
        end

        function BoxMethods:AddSlider(sTitle, min, max, def, step, suf, cb)
            -- Обычный слайдер вне аккордеона
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 32)
            Row.BackgroundColor3 = THEME.Card
            Row.Parent = Group

            local rCorn = Instance.new("UICorner")
            rCorn.CornerRadius = UDim.new(0, 5)
            rCorn.Parent = Row

            local rStroke = Instance.new("UIStroke")
            rStroke.Thickness = 1
            rStroke.Color = THEME.Border
            rStroke.Parent = Row

            local sLabel = Instance.new("TextLabel")
            sLabel.Size = UDim2.new(0.6, 0, 0, 16)
            sLabel.Position = UDim2.new(0, 8, 0, 3)
            sLabel.BackgroundTransparency = 1
            sLabel.Text = sTitle
            sLabel.Font = Enum.Font.GothamMedium
            sLabel.TextSize = 10
            sLabel.TextColor3 = THEME.Text
            sLabel.TextXAlignment = Enum.TextXAlignment.Left
            sLabel.Parent = Row

            local vLabel = Instance.new("TextLabel")
            vLabel.Size = UDim2.new(0.35, 0, 0, 16)
            vLabel.Position = UDim2.new(0.65, -8, 0, 3)
            vLabel.BackgroundTransparency = 1
            vLabel.Text = tostring(def) .. (suf or "")
            vLabel.Font = Enum.Font.GothamMedium
            vLabel.TextSize = 10
            vLabel.TextColor3 = THEME.TextDark
            vLabel.TextXAlignment = Enum.TextXAlignment.Right
            vLabel.Parent = Row

            local Bar = Instance.new("Frame")
            Bar.Size = UDim2.new(1, -16, 0, 3)
            Bar.Position = UDim2.new(0, 8, 1, -7)
            Bar.BackgroundColor3 = THEME.Border
            Bar.BorderSizePixel = 0
            Bar.Parent = Row

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new(math.clamp((def - min)/(max - min), 0, 1), 0, 1, 0)
            Fill.BackgroundColor3 = THEME.Accent
            Fill.BorderSizePixel = 0
            Fill.Parent = Bar

            local sliding = false
            local function upd(xPos)
                local perc = math.clamp((xPos - Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X, 0, 1)
                local val = min + (max - min)*perc
                if step then val = math.floor(val/step + 0.5)*step end
                val = math.clamp(val, min, max)
                Fill.Size = UDim2.new(perc, 0, 1, 0)
                vLabel.Text = string.format(step and (step < 1 and "%.2f" or "%d") or "%.1f", val) .. (suf or "")
                if cb then cb(val) end
            end

            Row.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true upd(i.Position.X) end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then upd(i.Position.X) end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
            end)
        end

        return BoxMethods
    end

    Lib.SwitchTab("Aim")
    return Lib
end

return UI
