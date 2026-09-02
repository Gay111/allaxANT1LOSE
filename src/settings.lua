-- // src/settings.lua
local SettingsModule = {}

local function getService(name)
    local s = game:GetService(name)
    return (cloneref and cloneref(s)) or s
end

local TweenService = getService("TweenService")
local UserInputService = getService("UserInputService")
local Players = getService("Players")
local RunService = getService("RunService")
local LocalPlayer = Players.LocalPlayer

function SettingsModule.Init(screenGui)
    local Settings = {
        State = {
            watermarkEnabled = true,
            showFps = true,
            showPing = true,
            showTime = true,
            showUser = true,
            watermarkTitle = "ANTILOSE",
            
            featureListEnabled = true,
            showOnlyActive = true
        },
        Features = {},
        Connections = {}
    }

    -- ========================================================================
    -- // 1. MICRO-PILL WATERMARK
    -- ========================================================================
    local WmPill = Instance.new("Frame")
    WmPill.Name = "WatermarkPill"
    WmPill.AutomaticSize = Enum.AutomaticSize.X
    WmPill.Size = UDim2.new(0, 0, 0, 24)
    WmPill.Position = UDim2.new(0, 16, 0, 16)
    WmPill.BackgroundColor3 = Color3.fromRGB(12, 13, 16)
    WmPill.BackgroundTransparency = 0.2
    WmPill.BorderSizePixel = 0
    WmPill.ZIndex = 50
    WmPill.Parent = screenGui

    local WmCorner = Instance.new("UICorner")
    WmCorner.CornerRadius = UDim.new(1, 0)
    WmCorner.Parent = WmPill

    local WmStroke = Instance.new("UIStroke")
    WmStroke.Thickness = 1
    WmStroke.Color = Color3.fromRGB(30, 32, 40)
    WmStroke.Parent = WmPill

    local WmPadding = Instance.new("UIPadding")
    WmPadding.PaddingLeft = UDim.new(0, 8)
    WmPadding.PaddingRight = UDim.new(0, 10)
    WmPadding.Parent = WmPill

    local WmLayout = Instance.new("UIListLayout")
    WmLayout.FillDirection = Enum.FillDirection.Horizontal
    WmLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    WmLayout.Padding = UDim.new(0, 6)
    WmLayout.Parent = WmPill

    -- Пульсирующий индикатор (Status Dot)
    local StatusDot = Instance.new("Frame")
    StatusDot.Size = UDim2.new(0, 6, 0, 6)
    StatusDot.BackgroundColor3 = Color3.fromRGB(80, 220, 130)
    StatusDot.BorderSizePixel = 0
    StatusDot.Parent = WmPill

    local DotCorner = Instance.new("UICorner")
    DotCorner.CornerRadius = UDim.new(1, 0)
    DotCorner.Parent = StatusDot

    -- Анимация пульса
    task.spawn(function()
        while WmPill.Parent do
            TweenService:Create(StatusDot, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.6
            }):Play()
            task.wait(0.9)
            TweenService:Create(StatusDot, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.0
            }):Play()
            task.wait(0.9)
        end
    end)

    local WmText = Instance.new("TextLabel")
    WmText.AutomaticSize = Enum.AutomaticSize.X
    WmText.Size = UDim2.new(0, 0, 1, 0)
    WmText.BackgroundTransparency = 1
    WmText.Font = Enum.Font.GothamMedium
    WmText.TextSize = 10
    WmText.TextColor3 = Color3.fromRGB(220, 225, 235)
    WmText.Text = "ANTILOSE"
    WmText.Parent = WmPill

    -- Драг для Watermark
    local isDragWm, startInpWm, startPosWm
    WmPill.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragWm = true
            startInpWm = i.Position
            startPosWm = WmPill.Position
        end
    end)

    -- ========================================================================
    -- // 2. STEALTH FEATURE / KEYBIND LIST HUD
    -- ========================================================================
    local Hud = Instance.new("Frame")
    Hud.Name = "FeatureHUD"
    Hud.AutomaticSize = Enum.AutomaticSize.Y
    Hud.Size = UDim2.new(0, 140, 0, 0)
    Hud.Position = UDim2.new(0, 16, 0, 50)
    Hud.BackgroundColor3 = Color3.fromRGB(12, 13, 16)
    Hud.BackgroundTransparency = 0.25
    Hud.BorderSizePixel = 0
    Hud.ZIndex = 50
    Hud.Parent = screenGui

    local HudCorner = Instance.new("UICorner")
    HudCorner.CornerRadius = UDim.new(0, 6)
    HudCorner.Parent = Hud

    local HudStroke = Instance.new("UIStroke")
    HudStroke.Thickness = 1
    HudStroke.Color = Color3.fromRGB(28, 30, 38)
    HudStroke.Parent = Hud

    local HudHeader = Instance.new("TextLabel")
    HudHeader.Size = UDim2.new(1, -12, 0, 20)
    HudHeader.Position = UDim2.new(0, 6, 0, 2)
    HudHeader.BackgroundTransparency = 1
    HudHeader.Font = Enum.Font.GothamBold
    HudHeader.Text = "ACTIVE BINDS"
    HudHeader.TextSize = 8
    HudHeader.TextColor3 = Color3.fromRGB(100, 105, 120)
    HudHeader.TextXAlignment = Enum.TextXAlignment.Left
    HudHeader.Parent = Hud

    local Container = Instance.new("Frame")
    Container.AutomaticSize = Enum.AutomaticSize.Y
    Container.Size = UDim2.new(1, -12, 0, 0)
    Container.Position = UDim2.new(0, 6, 0, 22)
    Container.BackgroundTransparency = 1
    Container.Parent = Hud

    local CList = Instance.new("UIListLayout")
    CList.Padding = UDim.new(0, 3)
    CList.Parent = Container

    local BottomPad = Instance.new("Frame")
    BottomPad.Size = UDim2.new(1, 0, 0, 4)
    BottomPad.BackgroundTransparency = 1
    BottomPad.LayoutOrder = 9999
    BottomPad.Parent = Container

    -- Драг для HUD
    local isDragHud, startInpHud, startPosHud
    HudHeader.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragHud = true
            startInpHud = i.Position
            startPosHud = Hud.Position
        end
    end)

    -- Общий обработчик перемещения
    local moveConn = UserInputService.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement then
            if isDragWm then
                local d = inp.Position - startInpWm
                WmPill.Position = UDim2.new(startPosWm.X.Scale, startPosWm.X.Offset + d.X, startPosWm.Y.Scale, startPosWm.Y.Offset + d.Y)
            elseif isDragHud then
                local d = inp.Position - startInpHud
                Hud.Position = UDim2.new(startPosHud.X.Scale, startPosHud.X.Offset + d.X, startPosHud.Y.Scale, startPosHud.Y.Offset + d.Y)
            end
        end
    end)
    local endConn = UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragWm = false
            isDragHud = false
        end
    end)
    table.insert(Settings.Connections, moveConn)
    table.insert(Settings.Connections, endConn)

    -- ========================================================================
    -- // ОБНОВЛЕНИЕ HUD
    -- ========================================================================
    local activeRows = {}

    function Settings.UpdateFeatureListUI()
        Hud.Visible = Settings.State.featureListEnabled
        if not Settings.State.featureListEnabled then return end

        for _, r in pairs(activeRows) do r:Destroy() end
        table.clear(activeRows)

        local count = 0
        for _, feat in pairs(Settings.Features) do
            if not Settings.State.showOnlyActive or feat.Active then
                count = count + 1
                local Row = Instance.new("Frame")
                Row.Size = UDim2.new(1, 0, 0, 16)
                Row.BackgroundTransparency = 1
                Row.Parent = Container

                local NameL = Instance.new("TextLabel")
                NameL.Size = UDim2.new(0.65, 0, 1, 0)
                NameL.BackgroundTransparency = 1
                NameL.Font = Enum.Font.GothamMedium
                NameL.Text = feat.Name
                NameL.TextSize = 9
                NameL.TextColor3 = Color3.fromRGB(220, 225, 235)
                NameL.TextXAlignment = Enum.TextXAlignment.Left
                NameL.Parent = Row

                local Badge = Instance.new("TextLabel")
                Badge.Size = UDim2.new(0.35, 0, 1, 0)
                Badge.Position = UDim2.new(0.65, 0, 0, 0)
                Badge.BackgroundTransparency = 1
                Badge.Font = Enum.Font.GothamBold
                Badge.Text = "[" .. (feat.Mode or (feat.Active and "ON" or "OFF")) .. "]"
                Badge.TextSize = 8
                Badge.TextColor3 = feat.Active and Color3.fromRGB(100, 135, 245) or Color3.fromRGB(90, 95, 110)
                Badge.TextXAlignment = Enum.TextXAlignment.Right
                Badge.Parent = Row

                table.insert(activeRows, Row)
            end
        end

        Hud.Visible = (count > 0 and Settings.State.featureListEnabled)
    end

    function Settings.SetFeature(id, name, active, mode)
        Settings.Features[id] = { Name = name, Active = active, Mode = mode }
        Settings.UpdateFeatureListUI()
    end

    -- Телеметрия для ватермарки
    local lastT = tick()
    local frames = 0
    local curFps = 60
    local curPing = 0

    local teleConn = RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = tick()
        if now - lastT >= 0.5 then
            curFps = math.floor(frames / (now - lastT))
            pcall(function() curPing = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
            frames = 0
            lastT = now

            if Settings.State.watermarkEnabled then
                WmPill.Visible = true
                local parts = { "<b>" .. Settings.State.watermarkTitle .. "</b>" }
                if Settings.State.showUser then table.insert(parts, LocalPlayer.Name) end
                if Settings.State.showFps then table.insert(parts, curFps .. " fps") end
                if Settings.State.showPing then table.insert(parts, curPing .. " ms") end
                if Settings.State.showTime then table.insert(parts, os.date("%X")) end

                WmText.RichText = true
                WmText.Text = table.concat(parts, "  <font color=\"rgb(60,65,75)\">|</font>  ")
            else
                WmPill.Visible = false
            end
        end
    end)
    table.insert(Settings.Connections, teleConn)

    function Settings.Cleanup()
        for _, c in ipairs(Settings.Connections) do pcall(function() c:Disconnect() end) end
        if WmPill then pcall(function() WmPill:Destroy() end) end
        if Hud then pcall(function() Hud:Destroy() end) end
    end

    return Settings
end

return SettingsModule
