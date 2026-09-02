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
    MainBg       = Color3.fromRGB(11, 12, 15),
    GroupBg      = Color3.fromRGB(15, 17, 22),
    DrawerBg     = Color3.fromRGB(12, 13, 17),
    Border       = Color3.fromRGB(26, 29, 38),
    BorderActive = Color3.fromRGB(45, 50, 65),
    Accent       = Color3.fromRGB(75, 115, 245),
    AccentDim    = Color3.fromRGB(35, 50, 95),
    TextActive   = Color3.fromRGB(235, 238, 245),
    TextDim      = Color3.fromRGB(120, 125, 140),
    TextDark     = Color3.fromRGB(80, 85, 95),
    CheckBg      = Color3.fromRGB(20, 22, 28)
}

local function tw(obj, props, t)
    local tween = TweenService:Create(obj, TweenInfo.new(t or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
    tween:Play()
    return tween
end

function UI.Init()
    local Lib = { Connections = {}, Pages = {} }

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AntiloseClient"
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
    Main.Size = UDim2.new(0, 560, 0, 390)
    Main.Position = UDim2.new(0.5, -280, 0.5, -195)
    Main.BackgroundColor3 = THEME.MainBg
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 6)
    MainCorner.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Thickness = 1
    MainStroke.Color = THEME.Border
    MainStroke.Parent = Main

    -- Шапка
    local Topbar = Instance.new("Frame")
    Topbar.Size = UDim2.new(1, 0, 0, 32)
    Topbar.BackgroundColor3 = THEME.GroupBg
    Topbar.BorderSizePixel = 0
    Topbar.Parent = Main

    local TopStroke = Instance.new("Frame")
    TopStroke.Size = UDim2.new(1, 0, 0, 1)
    TopStroke.Position = UDim2.new(0, 0, 1, -1)
    TopStroke.BackgroundColor3 = THEME.Border
    TopStroke.BorderSizePixel = 0
    TopStroke.Parent = Topbar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -24, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.RichText = true
    Title.Text = "<b>ANTILOSE</b>  <font color=\"rgb(75,115,245)\">/</font>  CLIENT"
    Title.Font = Enum.Font.GothamMedium
    Title.TextSize = 11
    Title.TextColor3 = THEME.TextActive
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Topbar

    -- Перемещение окна мышью
    local isDrag, startInp, startPos
    Topbar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            isDrag = true
            startInp = i.Position
            startPos = Main.Position
        end
    end)
    local moveConn = UserInputService.InputChanged:Connect(function(i)
        if isDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - startInp
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    local endConn = UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then isDrag = false end
    end)
    table.insert(Lib.Connections, moveConn)
    table.insert(Lib.Connections, endConn)

    -- Контейнер контента
    local PageContainer = Instance.new("Frame")
    PageContainer.Size = UDim2.new(1, 0, 1, -66)
    PageContainer.Position = UDim2.new(0, 0, 0, 33)
    PageContainer.BackgroundTransparency = 1
    PageContainer.Parent = Main

    -- Нижняя панель навигации
    local BottomNav = Instance.new("Frame")
    BottomNav.Size = UDim2.new(1, 0, 0, 33)
    BottomNav.Position = UDim2.new(0, 0, 1, -33)
    BottomNav.BackgroundColor3 = THEME.GroupBg
    BottomNav.BorderSizePixel = 0
    BottomNav.Parent = Main

    local NavSep = Instance.new("Frame")
    NavSep.Size = UDim2.new(1, 0, 0, 1)
    NavSep.BackgroundColor3 = THEME.Border
    NavSep.BorderSizePixel = 0
    NavSep.Parent = BottomNav

    local NavGrid = Instance.new("UIGridLayout")
    NavGrid.CellSize = UDim2.new(0.25, 0, 1, 0)
    NavGrid.CellPadding = UDim2.new(0, 0, 0, 0)
    NavGrid.Parent = BottomNav

    local Tabs = { "Aim", "Visuals", "World", "Settings" }
    local TabButtons = {}

    for _, tabName in ipairs(Tabs) do
        local Page = Instance.new("Frame")
        Page.Name = tabName .. "Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.Visible = false
        Page.Parent = PageContainer

        local LeftCol = Instance.new("ScrollingFrame")
        LeftCol.Size = UDim2.new(0.5, -12, 1, -12)
        LeftCol.Position = UDim2.new(0, 8, 0, 6)
        LeftCol.BackgroundTransparency = 1
        LeftCol.ScrollBarThickness = 2
        LeftCol.ScrollBarImageColor3 = THEME.BorderActive
        LeftCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
        LeftCol.CanvasSize = UDim2.new(0, 0, 0, 0)
        LeftCol.Parent = Page

        local RightCol = LeftCol:Clone()
        RightCol.Position = UDim2.new(0.5, 4, 0, 6)
        RightCol.Parent = Page

        local function formatList(parent)
            local l = Instance.new("UIListLayout")
            l.Padding = UDim.new(0, 8)
            l.SortOrder = Enum.SortOrder.LayoutOrder
            l.Parent = parent
            local pad = Instance.new("UIPadding")
            pad.PaddingRight = UDim.new(0, 4)
            pad.Parent = parent
        end
        formatList(LeftCol)
        formatList(RightCol)

        Lib.Pages[tabName] = { Page = Page, Left = LeftCol, Right = RightCol }

        -- Кнопка вкладки снизу
        local TabBtn = Instance.new("TextButton")
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = string.upper(tabName)
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextSize = 10
        TabBtn.TextColor3 = THEME.TextDark
        TabBtn.AutoButtonColor = false
        TabBtn.Parent = BottomNav

        local Indicator = Instance.new("Frame")
        Indicator.Size = UDim2.new(0.5, 0, 0, 2)
        Indicator.Position = UDim2.new(0.25, 0, 0, 0)
        Indicator.BackgroundColor3 = THEME.Accent
        Indicator.BorderSizePixel = 0
        Indicator.Visible = false
        Indicator.Parent = TabBtn

        TabButtons[tabName] = { Button = TabBtn, Indicator = Indicator }

        TabBtn.MouseButton1Click:Connect(function()
            Lib.SwitchTab(tabName)
        end)
    end

    function Lib.SwitchTab(name)
        for tName, data in pairs(Lib.Pages) do
            local isCur = (tName == name)
            data.Page.Visible = isCur
            local tabObj = TabButtons[tName]
            if isCur then
                tw(tabObj.Button, { TextColor3 = THEME.TextActive }, 0.15)
                tabObj.Indicator.Visible = true
            else
                tw(tabObj.Button, { TextColor3 = THEME.TextDark }, 0.15)
                tabObj.Indicator.Visible = false
            end
        end
    end

    -- ========================================================================
    -- // ГРУППЫ И ЭЛЕМЕНТЫ (CS2 / NEVERLOSE STYLE)
    -- ========================================================================
    function Lib.CreateGroupbox(parent, title)
        local Group = Instance.new("Frame")
        Group.AutomaticSize = Enum.AutomaticSize.Y
        Group.Size = UDim2.new(1, 0, 0, 0)
        Group.BackgroundColor3 = THEME.GroupBg
        Group.BorderSizePixel = 0
        Group.Parent = parent

        local GCorner = Instance.new("UICorner")
        GCorner.CornerRadius = UDim.new(0, 4)
        GCorner.Parent = Group

        local GStroke = Instance.new("UIStroke")
        GStroke.Thickness = 1
        GStroke.Color = THEME.Border
        GStroke.Parent = Group

        local GPad = Instance.new("UIPadding")
        GPad.PaddingTop = UDim.new(0, 8)
        GPad.PaddingBottom = UDim.new(0, 8)
        GPad.PaddingLeft = UDim.new(0, 8)
        GPad.PaddingRight = UDim.new(0, 8)
        GPad.Parent = Group

        local GList = Instance.new("UIListLayout")
        GList.Padding = UDim.new(0, 5)
        GList.SortOrder = Enum.SortOrder.LayoutOrder
        GList.Parent = Group

        local GHeader = Instance.new("TextLabel")
        GHeader.Size = UDim2.new(1, 0, 0, 14)
        GHeader.BackgroundTransparency = 1
        GHeader.Text = string.upper(title)
        GHeader.Font = Enum.Font.GothamBold
        GHeader.TextSize = 9
        GHeader.TextColor3 = THEME.TextDark
        GHeader.TextXAlignment = Enum.TextXAlignment.Left
        GHeader.Parent = Group

        local GSep = Instance.new("Frame")
        GSep.Size = UDim2.new(1, 0, 0, 1)
        GSep.BackgroundColor3 = THEME.Border
        GSep.BorderSizePixel = 0
        GSep.Parent = Group

        local Methods = {}

        -- Создание функции с выпадающими поднастройками
        function Methods:AddFeature(featTitle, defaultState, callback)
            local isToggled = defaultState or false
            local isExpanded = false

            local Container = Instance.new("Frame")
            Container.AutomaticSize = Enum.AutomaticSize.Y
            Container.Size = UDim2.new(1, 0, 0, 0)
            Container.BackgroundTransparency = 1
            Container.Parent = Group

            local CLayout = Instance.new("UIListLayout")
            CLayout.Padding = UDim.new(0, 4)
            CLayout.SortOrder = Enum.SortOrder.LayoutOrder
            CLayout.Parent = Container

            -- Главная строка (Чекбокс + Заголовок + Кнопка раскрытия [...])
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 20)
            Row.BackgroundTransparency = 1
            Row.Parent = Container

            local CheckBox = Instance.new("TextButton")
            CheckBox.Size = UDim2.new(0, 13, 0, 13)
            CheckBox.Position = UDim2.new(0, 0, 0.5, -6)
            CheckBox.BackgroundColor3 = isToggled and THEME.Accent or THEME.CheckBg
            CheckBox.Text = ""
            CheckBox.AutoButtonColor = false
            CheckBox.Parent = Row

            local CbCorner = Instance.new("UICorner")
            CbCorner.CornerRadius = UDim.new(0, 3)
            CbCorner.Parent = CheckBox

            local CbStroke = Instance.new("UIStroke")
            CbStroke.Thickness = 1
            CbStroke.Color = isToggled and THEME.Accent or THEME.Border
            CbStroke.Parent = CheckBox

            local CheckMark = Instance.new("Frame")
            CheckMark.Size = UDim2.new(0, 5, 0, 5)
            CheckMark.Position = UDim2.new(0.5, -2, 0.5, -2)
            CheckMark.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            CheckMark.BorderSizePixel = 0
            CheckMark.Visible = isToggled
            CheckMark.Parent = CheckBox

            local Label = Instance.new("TextButton")
            Label.Size = UDim2.new(1, -45, 1, 0)
            Label.Position = UDim2.new(0, 20, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = featTitle
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 10
            Label.TextColor3 = isToggled and THEME.TextActive or THEME.TextDim
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.AutoButtonColor = false
            Label.Parent = Row

            local function toggle()
                isToggled = not isToggled
                CheckMark.Visible = isToggled
                tw(CheckBox, { BackgroundColor3 = isToggled and THEME.Accent or THEME.CheckBg }, 0.15)
                tw(CbStroke, { Color = isToggled and THEME.Accent or THEME.Border }, 0.15)
                tw(Label, { TextColor3 = isToggled and THEME.TextActive or THEME.TextDim }, 0.15)
                if callback then callback(isToggled) end
            end

            CheckBox.MouseButton1Click:Connect(toggle)
            Label.MouseButton1Click:Connect(toggle)

            -- Кнопка поднастроек [...]
            local CfgBtn = Instance.new("TextButton")
            CfgBtn.Size = UDim2.new(0, 20, 0, 14)
            CfgBtn.Position = UDim2.new(1, -20, 0.5, -7)
            CfgBtn.BackgroundColor3 = THEME.MainBg
            CfgBtn.Text = "..."
            CfgBtn.Font = Enum.Font.GothamBold
            CfgBtn.TextSize = 8
            CfgBtn.TextColor3 = THEME.TextDark
            CfgBtn.AutoButtonColor = false
            CfgBtn.Parent = Row

            local CfgCorner = Instance.new("UICorner")
            CfgCorner.CornerRadius = UDim.new(0, 3)
            CfgCorner.Parent = CfgBtn

            local CfgStroke = Instance.new("UIStroke")
            CfgStroke.Thickness = 1
            CfgStroke.Color = THEME.Border
            CfgStroke.Parent = CfgBtn

            -- Выпадающий ящик поднастроек
            local Drawer = Instance.new("Frame")
            Drawer.AutomaticSize = Enum.AutomaticSize.Y
            Drawer.Size = UDim2.new(1, 0, 0, 0)
            Drawer.BackgroundColor3 = THEME.DrawerBg
            Drawer.BorderSizePixel = 0
            Drawer.Visible = false
            Drawer.Parent = Container

            local DrCorner = Instance.new("UICorner")
            DrCorner.CornerRadius = UDim.new(0, 3)
            DrCorner.Parent = Drawer

            local DrStroke = Instance.new("UIStroke")
            DrStroke.Thickness = 1
            DrStroke.Color = THEME.Border
            DrStroke.Parent = Drawer

            local DrPad = Instance.new("UIPadding")
            DrPad.PaddingTop = UDim.new(0, 6)
            DrPad.PaddingBottom = UDim.new(0, 6)
            DrPad.PaddingLeft = UDim.new(0, 8)
            DrPad.PaddingRight = UDim.new(0, 8)
            DrPad.Parent = Drawer

            local DrList = Instance.new("UIListLayout")
            DrList.Padding = UDim.new(0, 6)
            DrList.SortOrder = Enum.SortOrder.LayoutOrder
            DrList.Parent = Drawer

            CfgBtn.MouseButton1Click:Connect(function()
                isExpanded = not isExpanded
                Drawer.Visible = isExpanded
                tw(CfgBtn, { TextColor3 = isExpanded and THEME.Accent or THEME.TextDark }, 0.15)
                tw(CfgStroke, { Color = isExpanded and THEME.Accent or THEME.Border }, 0.15)
            end)

            local Sub = {}

            -- Слайдер внутри поднастроек
            function Sub:AddSlider(sName, min, max, def, step, suffix, sCb)
                local curVal = def or min
                local SRow = Instance.new("Frame")
                SRow.Size = UDim2.new(1, 0, 0, 24)
                SRow.BackgroundTransparency = 1
                SRow.Parent = Drawer

                local sLbl = Instance.new("TextLabel")
                sLbl.Size = UDim2.new(0.65, 0, 0, 12)
                sLbl.BackgroundTransparency = 1
                sLbl.Text = sName
                sLbl.Font = Enum.Font.GothamMedium
                sLbl.TextSize = 9
                sLbl.TextColor3 = THEME.TextDim
                sLbl.TextXAlignment = Enum.TextXAlignment.Left
                sLbl.Parent = SRow

                local vLbl = Instance.new("TextLabel")
                vLbl.Size = UDim2.new(0.35, 0, 0, 12)
                vLbl.Position = UDim2.new(0.65, 0, 0, 0)
                vLbl.BackgroundTransparency = 1
                vLbl.Text = tostring(curVal) .. (suffix or "")
                vLbl.Font = Enum.Font.GothamMedium
                vLbl.TextSize = 9
                vLbl.TextColor3 = THEME.TextDark
                vLbl.TextXAlignment = Enum.TextXAlignment.Right
                vLbl.Parent = SRow

                local Bar = Instance.new("Frame")
                Bar.Size = UDim2.new(1, 0, 0, 3)
                Bar.Position = UDim2.new(0, 0, 1, -4)
                Bar.BackgroundColor3 = THEME.BorderActive
                Bar.BorderSizePixel = 0
                Bar.Parent = SRow

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
                    vLbl.Text = string.format(step and (step < 1 and "%.2f" or "%d") or "%.1f", val) .. (suffix or "")
                    if sCb then sCb(val) end
                end

                SRow.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true update(i.Position.X) end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then update(i.Position.X) end
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
                end)
            end

            -- Выбор режимов
            function Sub:AddSegmented(segTitle, options, defIdx, segCb)
                local SRow = Instance.new("Frame")
                SRow.Size = UDim2.new(1, 0, 0, 22)
                SRow.BackgroundTransparency = 1
                SRow.Parent = Drawer

                local sLbl = Instance.new("TextLabel")
                sLbl.Size = UDim2.new(0.35, 0, 1, 0)
                sLbl.BackgroundTransparency = 1
                sLbl.Text = segTitle
                sLbl.Font = Enum.Font.GothamMedium
                sLbl.TextSize = 9
                sLbl.TextColor3 = THEME.TextDim
                sLbl.TextXAlignment = Enum.TextXAlignment.Left
                sLbl.Parent = SRow

                local SegBar = Instance.new("Frame")
                SegBar.Size = UDim2.new(0.65, 0, 1, 0)
                SegBar.Position = UDim2.new(0.35, 0, 0, 0)
                SegBar.BackgroundColor3 = THEME.MainBg
                SegBar.Parent = SRow

                local SCorner = Instance.new("UICorner")
                SCorner.CornerRadius = UDim.new(0, 3)
                SCorner.Parent = SegBar

                local SStroke = Instance.new("UIStroke")
                SStroke.Thickness = 1
                SStroke.Color = THEME.Border
                SStroke.Parent = SegBar

                local SLayout = Instance.new("UIListLayout")
                SLayout.FillDirection = Enum.FillDirection.Horizontal
                SLayout.Parent = SegBar

                local curIdx = defIdx or 1
                local btns = {}

                for idx, opt in ipairs(options) do
                    local b = Instance.new("TextButton")
                    b.Size = UDim2.new(1 / #options, 0, 1, 0)
                    b.BackgroundTransparency = (idx == curIdx) and 0 or 1
                    b.BackgroundColor3 = THEME.AccentDim
                    b.Text = opt
                    b.Font = Enum.Font.GothamBold
                    b.TextSize = 8
                    b.TextColor3 = (idx == curIdx) and THEME.TextActive or THEME.TextDark
                    b.AutoButtonColor = false
                    b.Parent = SegBar

                    local bCorn = Instance.new("UICorner")
                    bCorn.CornerRadius = UDim.new(0, 3)
                    bCorn.Parent = b

                    b.MouseButton1Click:Connect(function()
                        for i, btn in ipairs(btns) do
                            btn.BackgroundTransparency = (i == idx) and 0 or 1
                            btn.TextColor3 = (i == idx) and THEME.TextActive or THEME.TextDark
                        end
                        if segCb then segCb(opt) end
                    end)
                    table.insert(btns, b)
                end
            end

            -- Обычный чекбокс внутри поднастроек
            function Sub:AddToggle(subTitle, subDef, subCb)
                local subTog = subDef or false
                local SRow = Instance.new("Frame")
                SRow.Size = UDim2.new(1, 0, 0, 16)
                SRow.BackgroundTransparency = 1
                SRow.Parent = Drawer

                local CBox = Instance.new("TextButton")
                CBox.Size = UDim2.new(0, 11, 0, 11)
                CBox.Position = UDim2.new(0, 0, 0.5, -5)
                CBox.BackgroundColor3 = subTog and THEME.Accent or THEME.MainBg
                CBox.Text = ""
                CBox.AutoButtonColor = false
                CBox.Parent = SRow

                local CCorn = Instance.new("UICorner")
                CCorn.CornerRadius = UDim.new(0, 2)
                CCorn.Parent = CBox

                local CStrk = Instance.new("UIStroke")
                CStrk.Thickness = 1
                CStrk.Color = subTog and THEME.Accent or THEME.Border
                CStrk.Parent = CBox

                local CMk = Instance.new("Frame")
                CMk.Size = UDim2.new(0, 5, 0, 5)
                CMk.Position = UDim2.new(0.5, -2, 0.5, -2)
                CMk.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                CMk.BorderSizePixel = 0
                CMk.Visible = subTog
                CMk.Parent = CBox

                local sLbl = Instance.new("TextButton")
                sLbl.Size = UDim2.new(1, -18, 1, 0)
                sLbl.Position = UDim2.new(0, 18, 0, 0)
                sLbl.BackgroundTransparency = 1
                sLbl.Text = subTitle
                sLbl.Font = Enum.Font.GothamMedium
                sLbl.TextSize = 9
                sLbl.TextColor3 = subTog and THEME.TextActive or THEME.TextDim
                sLbl.TextXAlignment = Enum.TextXAlignment.Left
                sLbl.AutoButtonColor = false
                sLbl.Parent = SRow

                local function togSub()
                    subTog = not subTog
                    CMk.Visible = subTog
                    tw(CBox, { BackgroundColor3 = subTog and THEME.Accent or THEME.MainBg }, 0.15)
                    tw(CStrk, { Color = subTog and THEME.Accent or THEME.Border }, 0.15)
                    tw(sLbl, { TextColor3 = subTog and THEME.TextActive or THEME.TextDim }, 0.15)
                    if subCb then subCb(subTog) end
                end

                CBox.MouseButton1Click:Connect(togSub)
                sLbl.MouseButton1Click:Connect(togSub)
            end

            return Sub
        end

        -- Обычный слайдер на уровне группы
        function Methods:AddSlider(sName, min, max, def, step, suffix, sCb)
            local curVal = def or min
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 26)
            Row.BackgroundTransparency = 1
            Row.Parent = Group

            local sLbl = Instance.new("TextLabel")
            sLbl.Size = UDim2.new(0.65, 0, 0, 12)
            sLbl.BackgroundTransparency = 1
            sLbl.Text = sName
            sLbl.Font = Enum.Font.GothamMedium
            sLbl.TextSize = 9
            sLbl.TextColor3 = THEME.TextDim
            sLbl.TextXAlignment = Enum.TextXAlignment.Left
            sLbl.Parent = Row

            local vLbl = Instance.new("TextLabel")
            vLbl.Size = UDim2.new(0.35, 0, 0, 12)
            vLbl.Position = UDim2.new(0.65, 0, 0, 0)
            vLbl.BackgroundTransparency = 1
            vLbl.Text = tostring(curVal) .. (suffix or "")
            vLbl.Font = Enum.Font.GothamMedium
            vLbl.TextSize = 9
            vLbl.TextColor3 = THEME.TextDark
            vLbl.TextXAlignment = Enum.TextXAlignment.Right
            vLbl.Parent = Row

            local Bar = Instance.new("Frame")
            Bar.Size = UDim2.new(1, 0, 0, 3)
            Bar.Position = UDim2.new(0, 0, 1, -4)
            Bar.BackgroundColor3 = THEME.BorderActive
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
                vLbl.Text = string.format(step and (step < 1 and "%.2f" or "%d") or "%.1f", val) .. (suffix or "")
                if sCb then sCb(val) end
            end

            Row.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true update(i.Position.X) end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then update(i.Position.X) end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
            end)
        end

        -- Кнопка действия
        function Methods:AddButton(btnText, bCb)
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 22)
            Btn.BackgroundColor3 = THEME.MainBg
            Btn.Text = btnText
            Btn.Font = Enum.Font.GothamMedium
            Btn.TextSize = 10
            Btn.TextColor3 = THEME.TextActive
            Btn.AutoButtonColor = false
            Btn.Parent = Group

            local bCorn = Instance.new("UICorner")
            bCorn.CornerRadius = UDim.new(0, 3)
            bCorn.Parent = Btn

            local bStrk = Instance.new("UIStroke")
            bStrk.Thickness = 1
            bStrk.Color = THEME.Border
            bStrk.Parent = Btn

            Btn.MouseButton1Click:Connect(function()
                tw(Btn, { BackgroundColor3 = THEME.BorderActive }, 0.08).Completed:Connect(function()
                    tw(Btn, { BackgroundColor3 = THEME.MainBg }, 0.12)
                end)
                if bCb then bCb() end
            end)
        end

        function Methods:AddToggle(title, def, cb)
            return Methods:AddFeature(title, def, cb)
        end

        return Methods
    end

    Lib.SwitchTab("Aim")
    return Lib
end

return UI
