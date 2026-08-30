--!strict
-- [ ALLAX / UI MODULE ]
-- Оригинальная синяя тема (Neverlose Style)

local cloneref = (cloneref or function(o) return o end)
local CoreGui = cloneref(game:GetService("CoreGui"))
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))

local LocalPlayer = Players.LocalPlayer

-- Основной акцентный цвет темы (Neverlose Blue)
local ACCENT_COLOR = Color3.fromRGB(0, 140, 255)

local function getContainer(): Instance
    if gethui then
        return gethui()
    end
    local success, _ = pcall(function()
        return CoreGui:GetChildren()
    end)
    if success then
        return CoreGui
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local UI = {}
UI.__index = UI

function UI.Init(modules)
    local Visual = modules and modules.Visual
    local World = modules and modules.World
    local Aim = modules and modules.Aim

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AllaxAntilose_UI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = getContainer()

    -- Главное окно
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 600, 0, 480)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -240)
    MainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = false
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(30, 30, 40)
    MainStroke.Thickness = 1
    MainStroke.Parent = MainFrame

    -- Тень / Синее свечение
    local GlowShadow = Instance.new("ImageLabel")
    GlowShadow.Name = "GlowShadow"
    GlowShadow.AnchorPoint = Vector2.new(0.5, 0.5)
    GlowShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    GlowShadow.Size = UDim2.new(1, 46, 1, 46)
    GlowShadow.BackgroundTransparency = 1
    GlowShadow.Image = "rbxassetid://1316045217"
    GlowShadow.ImageColor3 = ACCENT_COLOR
    GlowShadow.ImageTransparency = 0.88
    GlowShadow.ScaleType = Enum.ScaleType.Slice
    GlowShadow.SliceCenter = Rect.new(10, 10, 118, 118)
    GlowShadow.ZIndex = 0
    GlowShadow.Parent = MainFrame

    -- Шапка окна
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 42)
    TopBar.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame

    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 8)
    TopCorner.Parent = TopBar

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Text = "ALLAX <font color=\"#008CFF\">ANTILOSE</font>"
    Title.RichText = true
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.TextColor3 = Color3.fromRGB(245, 245, 250)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 16, 0, 0)
    Title.Size = UDim2.new(0, 200, 1, 0)
    Title.Parent = TopBar

    -- Счетчики FPS / PING
    local StatsLabel = Instance.new("TextLabel")
    StatsLabel.Name = "StatsLabel"
    StatsLabel.Text = "FPS: 60 | PING: 0ms"
    StatsLabel.Font = Enum.Font.GothamMedium
    StatsLabel.TextSize = 12
    StatsLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
    StatsLabel.TextXAlignment = Enum.TextXAlignment.Right
    StatsLabel.BackgroundTransparency = 1
    StatsLabel.Position = UDim2.new(1, -216, 0, 0)
    StatsLabel.Size = UDim2.new(0, 200, 1, 0)
    StatsLabel.Parent = TopBar

    local frameCount = 0
    local lastFpsTime = os.clock()
    local currentFps = 60

    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = os.clock()
        if now - lastFpsTime >= 0.5 then
            currentFps = math.floor(frameCount / (now - lastFpsTime))
            frameCount = 0
            lastFpsTime = now
            local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
            StatsLabel.Text = string.format("FPS: %d | PING: %dms", currentFps, ping)
        end
    end)

    -- Перемещение окна
    local dragging, dragStart, startPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Нижний док табов
    local DockBar = Instance.new("Frame")
    DockBar.Name = "DockBar"
    DockBar.Size = UDim2.new(1, -24, 0, 38)
    DockBar.Position = UDim2.new(0, 12, 1, -48)
    DockBar.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    DockBar.BorderSizePixel = 0
    DockBar.Parent = MainFrame

    local DockCorner = Instance.new("UICorner")
    DockCorner.CornerRadius = UDim.new(0, 6)
    DockCorner.Parent = DockBar

    local DockLayout = Instance.new("UIListLayout")
    DockLayout.FillDirection = Enum.FillDirection.Horizontal
    DockLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    DockLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    DockLayout.Padding = UDim.new(0, 8)
    DockLayout.Parent = DockBar

    -- Контейнер контента
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -24, 1, -102)
    ContentContainer.Position = UDim2.new(0, 12, 0, 48)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame

    local tabs = {}
    local tabButtons = {}

    local function createTab(name: string)
        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "_Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.ScrollBarThickness = 2
        Page.ScrollBarImageColor3 = ACCENT_COLOR
        Page.Visible = false
        Page.Parent = ContentContainer

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Parent = Page

        local PagePadding = Instance.new("UIPadding")
        PagePadding.PaddingTop = UDim.new(0, 4)
        PagePadding.PaddingBottom = UDim.new(0, 4)
        PagePadding.PaddingLeft = UDim.new(0, 2)
        PagePadding.PaddingRight = UDim.new(0, 6)
        PagePadding.Parent = Page

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 12)
        end)

        local Btn = Instance.new("TextButton")
        Btn.Name = name .. "_DockBtn"
        Btn.Size = UDim2.new(0, 110, 0, 28)
        Btn.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
        Btn.BorderSizePixel = 0
        Btn.Font = Enum.Font.GothamMedium
        Btn.Text = name
        Btn.TextSize = 12
        Btn.TextColor3 = Color3.fromRGB(150, 150, 165)
        Btn.AutoButtonColor = false
        Btn.Parent = DockBar

        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 4)
        BtnCorner.Parent = Btn

        Btn.MouseButton1Click:Connect(function()
            for tName, page in pairs(tabs) do
                page.Visible = (tName == name)
            end
            for bName, b in pairs(tabButtons) do
                if bName == name then
                    TweenService:Create(b, TweenInfo.new(0.2), {
                        BackgroundColor3 = ACCENT_COLOR,
                        TextColor3 = Color3.fromRGB(255, 255, 255)
                    }):Play()
                else
                    TweenService:Create(b, TweenInfo.new(0.2), {
                        BackgroundColor3 = Color3.fromRGB(24, 24, 32),
                        TextColor3 = Color3.fromRGB(150, 150, 165)
                    }):Play()
                end
            end
        end)

        tabs[name] = Page
        tabButtons[name] = Btn

        local TabFunctions = {}

        function TabFunctions:AddToggle(title: string, default: boolean, callback: (boolean) -> ())
            local state = default or false

            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 36)
            ToggleFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
            ToggleFrame.BorderSizePixel = 0
            ToggleFrame.Parent = Page

            local C = Instance.new("UICorner")
            C.CornerRadius = UDim.new(0, 6)
            C.Parent = ToggleFrame

            local S = Instance.new("UIStroke")
            S.Color = Color3.fromRGB(28, 28, 36)
            S.Thickness = 1
            S.Parent = ToggleFrame

            local Lbl = Instance.new("TextLabel")
            Lbl.Text = title
            Lbl.Font = Enum.Font.GothamMedium
            Lbl.TextSize = 13
            Lbl.TextColor3 = Color3.fromRGB(225, 225, 235)
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.BackgroundTransparency = 1
            Lbl.Position = UDim2.new(0, 12, 0, 0)
            Lbl.Size = UDim2.new(1, -60, 1, 0)
            Lbl.Parent = ToggleFrame

            local Switch = Instance.new("TextButton")
            Switch.Text = ""
            Switch.Size = UDim2.new(0, 36, 0, 20)
            Switch.Position = UDim2.new(1, -48, 0.5, -10)
            Switch.BackgroundColor3 = state and ACCENT_COLOR or Color3.fromRGB(32, 32, 42)
            Switch.AutoButtonColor = false
            Switch.Parent = ToggleFrame

            local SC = Instance.new("UICorner")
            SC.CornerRadius = UDim.new(1, 0)
            SC.Parent = Switch

            local Dot = Instance.new("Frame")
            Dot.Size = UDim2.new(0, 14, 0, 14)
            Dot.Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
            Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Dot.BorderSizePixel = 0
            Dot.Parent = Switch

            local DC = Instance.new("UICorner")
            DC.CornerRadius = UDim.new(1, 0)
            DC.Parent = Dot

            Switch.MouseButton1Click:Connect(function()
                state = not state
                TweenService:Create(Switch, TweenInfo.new(0.2), {
                    BackgroundColor3 = state and ACCENT_COLOR or Color3.fromRGB(32, 32, 42)
                }):Play()
                TweenService:Create(Dot, TweenInfo.new(0.2), {
                    Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                }):Play()
                pcall(callback, state)
            end)
            
            pcall(callback, state)
        end

        function TabFunctions:AddSlider(title: string, min: number, max: number, default: number, step: number, callback: (number) -> ())
            local val = default or min

            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, 0, 0, 50)
            SliderFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
            SliderFrame.BorderSizePixel = 0
            SliderFrame.Parent = Page

            local C = Instance.new("UICorner")
            C.CornerRadius = UDim.new(0, 6)
            C.Parent = SliderFrame

            local S = Instance.new("UIStroke")
            S.Color = Color3.fromRGB(28, 28, 36)
            S.Thickness = 1
            S.Parent = SliderFrame

            local Lbl = Instance.new("TextLabel")
            Lbl.Text = title
            Lbl.Font = Enum.Font.GothamMedium
            Lbl.TextSize = 13
            Lbl.TextColor3 = Color3.fromRGB(225, 225, 235)
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.BackgroundTransparency = 1
            Lbl.Position = UDim2.new(0, 12, 0, 8)
            Lbl.Size = UDim2.new(1, -100, 0, 16)
            Lbl.Parent = SliderFrame

            local ValLbl = Instance.new("TextLabel")
            ValLbl.Text = tostring(val)
            ValLbl.Font = Enum.Font.GothamBold
            ValLbl.TextSize = 12
            ValLbl.TextColor3 = ACCENT_COLOR
            ValLbl.TextXAlignment = Enum.TextXAlignment.Right
            ValLbl.BackgroundTransparency = 1
            ValLbl.Position = UDim2.new(1, -80, 0, 8)
            ValLbl.Size = UDim2.new(0, 68, 0, 16)
            ValLbl.Parent = SliderFrame

            local Bar = Instance.new("TextButton")
            Bar.Text = ""
            Bar.AutoButtonColor = false
            Bar.Size = UDim2.new(1, -24, 0, 6)
            Bar.Position = UDim2.new(0, 12, 0, 32)
            Bar.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
            Bar.BorderSizePixel = 0
            Bar.Parent = SliderFrame

            local BC = Instance.new("UICorner")
            BC.CornerRadius = UDim.new(1, 0)
            BC.Parent = Bar

            local Fill = Instance.new("Frame")
            local progress = math.clamp((val - min) / (max - min), 0, 1)
            Fill.Size = UDim2.new(progress, 0, 1, 0)
            Fill.BackgroundColor3 = ACCENT_COLOR
            Fill.BorderSizePixel = 0
            Fill.Parent = Bar

            local FC = Instance.new("UICorner")
            FC.CornerRadius = UDim.new(1, 0)
            FC.Parent = Fill

            local sliding = false
            local function update(input)
                local relativeX = math.clamp(input.Position.X - Bar.AbsolutePosition.X, 0, Bar.AbsoluteSize.X)
                local pct = relativeX / Bar.AbsoluteSize.X
                local rawVal = min + (max - min) * pct
                local steppedVal = math.floor(rawVal / step + 0.5) * step
                steppedVal = math.clamp(steppedVal, min, max)

                Fill.Size = UDim2.new((steppedVal - min) / (max - min), 0, 1, 0)
                ValLbl.Text = string.format("%.2f", steppedVal):gsub("%.00$", "")
                pcall(callback, steppedVal)
            end

            Bar.InputBegan:Connect(function(input)
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

            pcall(callback, val)
        end

        function TabFunctions:AddSegmented(title: string, options: {string}, default: string, callback: (string) -> ())
            local current = default or options[1]

            local SegFrame = Instance.new("Frame")
            SegFrame.Size = UDim2.new(1, 0, 0, 42)
            SegFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
            SegFrame.BorderSizePixel = 0
            SegFrame.Parent = Page

            local C = Instance.new("UICorner")
            C.CornerRadius = UDim.new(0, 6)
            C.Parent = SegFrame

            local S = Instance.new("UIStroke")
            S.Color = Color3.fromRGB(28, 28, 36)
            S.Thickness = 1
            S.Parent = SegFrame

            local Lbl = Instance.new("TextLabel")
            Lbl.Text = title
            Lbl.Font = Enum.Font.GothamMedium
            Lbl.TextSize = 13
            Lbl.TextColor3 = Color3.fromRGB(225, 225, 235)
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.BackgroundTransparency = 1
            Lbl.Position = UDim2.new(0, 12, 0, 0)
            Lbl.Size = UDim2.new(0, 180, 1, 0)
            Lbl.Parent = SegFrame

            local BtnContainer = Instance.new("Frame")
            BtnContainer.Size = UDim2.new(0, #options * 70, 0, 24)
            BtnContainer.Position = UDim2.new(1, -((#options * 70) + 12), 0.5, -12)
            BtnContainer.BackgroundTransparency = 1
            BtnContainer.Parent = SegFrame

            local HList = Instance.new("UIListLayout")
            HList.FillDirection = Enum.FillDirection.Horizontal
            HList.Padding = UDim.new(0, 4)
            HList.Parent = BtnContainer

            local btns = {}
            for _, opt in ipairs(options) do
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(0, 66, 1, 0)
                b.BackgroundColor3 = (opt == current) and ACCENT_COLOR or Color3.fromRGB(28, 28, 38)
                b.TextColor3 = (opt == current) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 170)
                b.Font = Enum.Font.GothamBold
                b.TextSize = 11
                b.Text = opt
                b.AutoButtonColor = false
                b.Parent = BtnContainer

                local BC = Instance.new("UICorner")
                BC.CornerRadius = UDim.new(0, 4)
                BC.Parent = b

                b.MouseButton1Click:Connect(function()
                    current = opt
                    for name, btnInstance in pairs(btns) do
                        local active = (name == opt)
                        TweenService:Create(btnInstance, TweenInfo.new(0.15), {
                            BackgroundColor3 = active and ACCENT_COLOR or Color3.fromRGB(28, 28, 38),
                            TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 170)
                        }):Play()
                    end
                    pcall(callback, opt)
                end)
                btns[opt] = b
            end

            pcall(callback, current)
        end

        function TabFunctions:AddButton(title: string, callback: () -> ())
            local BtnFrame = Instance.new("TextButton")
            BtnFrame.Size = UDim2.new(1, 0, 0, 36)
            BtnFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
            BtnFrame.BorderSizePixel = 0
            BtnFrame.Font = Enum.Font.GothamBold
            BtnFrame.Text = title
            BtnFrame.TextColor3 = Color3.fromRGB(230, 230, 240)
            BtnFrame.TextSize = 13
            BtnFrame.AutoButtonColor = false
            BtnFrame.Parent = Page

            local C = Instance.new("UICorner")
            C.CornerRadius = UDim.new(0, 6)
            C.Parent = BtnFrame

            local S = Instance.new("UIStroke")
            S.Color = Color3.fromRGB(30, 30, 40)
            S.Thickness = 1
            S.Parent = BtnFrame

            BtnFrame.MouseButton1Click:Connect(function()
                TweenService:Create(BtnFrame, TweenInfo.new(0.1), {BackgroundColor3 = ACCENT_COLOR, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                task.wait(0.1)
                TweenService:Create(BtnFrame, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22, 22, 30), TextColor3 = Color3.fromRGB(230, 230, 240)}):Play()
                pcall(callback)
            end)
        end

        return TabFunctions
    end

    -- Создаем вкладки
    local AimTab = createTab("Aim")
    local VisualTab = createTab("Visuals")
    local WorldTab = createTab("World")
    local SettingsTab = createTab("Settings")

    -- 1. Вкладка AIM
    AimTab:AddToggle("Aimbot Enabled", false, function(state)
        if Aim and Aim.SetEnabled then Aim.SetEnabled(state) end
    end)
    AimTab:AddSlider("FOV Radius", 30, 400, 120, 5, function(val)
        if Aim and Aim.SetFOV then Aim.SetFOV(val) end
    end)

    -- 2. Вкладка VISUALS (с добавленными слайдерами прозрачности)
    if Visual then
        VisualTab:AddToggle("Indicator Enabled", true, function(state)
            Visual.SetEnabled(state)
        end)

        VisualTab:AddSegmented("Target Mode", {"CENTER", "MOUSE"}, "CENTER", function(mode)
            Visual.SetMode(mode)
        end)

        -- Слайдеры для нового индикатора
        VisualTab:AddSlider("Fill Transparency", 0, 1, 0.40, 0.05, function(val)
            Visual.SetFillTransparency(val)
        end)

        VisualTab:AddSlider("Outline Transparency", 0, 1, 0.05, 0.05, function(val)
            Visual.SetOutlineTransparency(val)
        end)

        VisualTab:AddSlider("Penetration Depth", 1, 30, 8, 1, function(val)
            Visual.SetPenetrationDepth(val)
        end)
    end

    -- 3. Вкладка WORLD
    if World then
        WorldTab:AddToggle("Map Transparency", false, function(state)
            if World.State then
                World.State.mapTransparencyEnabled = state
                World.UpdateAllMapParts()
            end
        end)

        WorldTab:AddSlider("Map Opacity Value", 0, 1, 0.5, 0.05, function(val)
            if World.State then
                World.State.mapTransparencyValue = val
                if World.State.mapTransparencyEnabled then
                    World.UpdateAllMapParts()
                end
            end
        end)

        WorldTab:AddToggle("Lock Day/Night Time", false, function(state)
            if World.State then
                World.State.lockTimeEnabled = state
            end
        end)

        WorldTab:AddSlider("Time of Day", 0, 24, 14, 0.5, function(val)
            if World.State then
                World.State.targetTime = val
            end
        end)
    end

    -- 4. Вкладка SETTINGS
    SettingsTab:AddButton("Unload / Close Menu", function()
        ScreenGui:Destroy()
        if Visual and Visual.Destroy then Visual.Destroy() end
        if World and World.Cleanup then World.Cleanup() end
    end)

    -- Горячая клавиша Insert / RightShift
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and (input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightShift) then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    -- Первая активная вкладка
    if tabButtons["Visuals"] then
        tabs["Visuals"].Visible = true
        tabButtons["Visuals"].BackgroundColor3 = ACCENT_COLOR
        tabButtons["Visuals"].TextColor3 = Color3.fromRGB(255, 255, 255)
    end

    return ScreenGui
end

return UI
