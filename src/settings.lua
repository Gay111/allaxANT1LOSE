-- // src/settings.lua
local SettingsModule = {}

local function getService(name)
    local s = game:GetService(name)
    return (cloneref and cloneref(s)) or s
end

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
    -- // 1. SLEEK WATERMARK
    -- ========================================================================
    local WmFrame = Instance.new("Frame")
    WmFrame.Name = "WatermarkHUD"
    WmFrame.AutomaticSize = Enum.AutomaticSize.X
    WmFrame.Size = UDim2.new(0, 0, 0, 22)
    WmFrame.Position = UDim2.new(0, 16, 0, 16)
    WmFrame.BackgroundColor3 = Color3.fromRGB(11, 12, 15)
    WmFrame.BackgroundTransparency = 0.15
    WmFrame.BorderSizePixel = 0
    WmFrame.ZIndex = 50
    WmFrame.Parent = screenGui

    local WmCorner = Instance.new("UICorner")
    WmCorner.CornerRadius = UDim.new(0, 4)
    WmCorner.Parent = WmFrame

    local WmStroke = Instance.new("UIStroke")
    WmStroke.Thickness = 1
    WmStroke.Color = Color3.fromRGB(26, 29, 38)
    WmStroke.Parent = WmFrame

    local WmPad = Instance.new("UIPadding")
    WmPad.PaddingLeft = UDim.new(0, 8)
    WmPad.PaddingRight = UDim.new(0, 8)
    WmPad.Parent = WmFrame

    local WmLayout = Instance.new("UIListLayout")
    WmLayout.FillDirection = Enum.FillDirection.Horizontal
    WmLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    WmLayout.Padding = UDim.new(0, 6)
    WmLayout.Parent = WmFrame

    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.new(0, 4, 0, 4)
    Dot.BackgroundColor3 = Color3.fromRGB(75, 115, 245)
    Dot.BorderSizePixel = 0
    Dot.Parent = WmFrame

    local DotCorner = Instance.new("UICorner")
    DotCorner.CornerRadius = UDim.new(1, 0)
    DotCorner.Parent = Dot

    local WmText = Instance.new("TextLabel")
    WmText.AutomaticSize = Enum.AutomaticSize.X
    WmText.Size = UDim2.new(0, 0, 1, 0)
    WmText.BackgroundTransparency = 1
    WmText.Font = Enum.Font.GothamMedium
    WmText.TextSize = 10
    WmText.TextColor3 = Color3.fromRGB(220, 225, 235)
    WmText.Text = "ANTILOSE"
    WmText.Parent = WmFrame

    -- Драг Watermark
    local isDragWm, startInpWm, startPosWm
    WmFrame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragWm = true
            startInpWm = i.Position
            startPosWm = WmFrame.Position
        end
    end)

    -- ========================================================================
    -- // 2. ACTIVE BINDS HUD
    -- ========================================================================
    local Hud = Instance.new("Frame")
    Hud.Name = "BindsHUD"
    Hud.AutomaticSize = Enum.AutomaticSize.Y
    Hud.Size = UDim2.new(0, 145, 0, 0)
    Hud.Position = UDim2.new(0, 16, 0, 46)
    Hud.BackgroundColor3 = Color3.fromRGB(11, 12, 15)
    Hud.BackgroundTransparency = 0.2
    Hud.BorderSizePixel = 0
    Hud.ZIndex = 50
    Hud.Parent = screenGui

    local HudCorner = Instance.new("UICorner")
    HudCorner.CornerRadius = UDim.new(0, 4)
    HudCorner.Parent = Hud

    local HudStroke = Instance.new("UIStroke")
    HudStroke.Thickness = 1
    HudStroke.Color = Color3.fromRGB(26, 29, 38)
    HudStroke.Parent = Hud

    local HudHead = Instance.new("TextLabel")
    HudHead.Size = UDim2.new(1, -12, 0, 20)
    HudHead.Position = UDim2.new(0, 6, 0, 0)
    HudHead.BackgroundTransparency = 1
    HudHead.Font = Enum.Font.GothamBold
    HudHead.Text = "ACTIVE MODULES"
    HudHead.TextSize = 8
    HudHead.TextColor3 = Color3.fromRGB(90, 95, 110)
    HudHead.TextXAlignment = Enum.TextXAlignment.Left
    HudHead.Parent = Hud

    local Container = Instance.new("Frame")
    Container.AutomaticSize = Enum.AutomaticSize.Y
    Container.Size = UDim2.new(1, -12, 0, 0)
    Container.Position = UDim2.new(0, 6, 0, 20)
    Container.BackgroundTransparency = 1
    Container.Parent = Hud

    local CList = Instance.new("UIListLayout")
    CList.Padding = UDim.new(0, 3)
    CList.Parent = Container

    local BPad = Instance.new("Frame")
    BPad.Size = UDim2.new(1, 0, 0, 4)
    BPad.BackgroundTransparency = 1
    BPad.LayoutOrder = 9999
    BPad.Parent = Container

    -- Драг Binds
    local isDragHud, startInpHud, startPosHud
    HudHead.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragHud = true
            startInpHud = i.Position
            startPosHud = Hud.Position
        end
    end)

    local moveConn = UserInputService.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement then
            if isDragWm then
                local d = inp.Position - startInpWm
                WmFrame.Position = UDim2.new(startPosWm.X.Scale, startPosWm.X.Offset + d.X, startPosWm.Y.Scale, startPosWm.Y.Offset + d.Y)
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

    -- Обновление списка
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
                Row.Size = UDim2.new(1, 0, 0, 15)
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
                Badge.TextColor3 = feat.Active and Color3.fromRGB(75, 115, 245) or Color3.fromRGB(80, 85, 95)
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

    -- Телеметрия
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
                WmFrame.Visible = true
                local parts = { "<b>" .. Settings.State.watermarkTitle .. "</b>" }
                if Settings.State.showUser then table.insert(parts, LocalPlayer.Name) end
                if Settings.State.showFps then table.insert(parts, curFps .. " fps") end
                if Settings.State.showPing then table.insert(parts, curPing .. " ms") end
                if Settings.State.showTime then table.insert(parts, os.date("%X")) end

                WmText.RichText = true
                WmText.Text = table.concat(parts, "  <font color=\"rgb(50,55,68)\">|</font>  ")
            else
                WmFrame.Visible = false
            end
        end
    end)
    table.insert(Settings.Connections, teleConn)

    function Settings.Cleanup()
        for _, c in ipairs(Settings.Connections) do pcall(function() c:Disconnect() end) end
        if WmFrame then pcall(function() WmFrame:Destroy() end) end
        if Hud then pcall(function() Hud:Destroy() end) end
    end

    return Settings
end

return SettingsModule
