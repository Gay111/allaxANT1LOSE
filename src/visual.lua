-- // src/visual.lua
local Visual = {}

local function getService(name)
    local service = game:GetService(name)
    return (cloneref and cloneref(service)) or service
end

local UserInputService = getService("UserInputService")
local Players = getService("Players")
local RunService = getService("RunService")
local Workspace = getService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

function Visual.Init(ScreenGui)
    local state = {
        awallEnabled = false,
        awallSize = 10,
        awallMode = "MOUSE"
    }

    local Box, Stroke

    if Drawing and Drawing.new then
        Box = Drawing.new("Square")
        Box.Visible = false
        Box.Filled = true
        Box.Thickness = 1
        Box.Size = Vector2.new(state.awallSize, state.awallSize)
        Box.Color = Color3.fromRGB(255, 50, 60)

        Stroke = Drawing.new("Square")
        Stroke.Visible = false
        Stroke.Filled = false
        Stroke.Thickness = 1
        Stroke.Size = Vector2.new(state.awallSize + 2, state.awallSize + 2)
        Stroke.Color = Color3.fromRGB(0, 0, 0)
    else
        local Frame = Instance.new("Frame")
        Frame.Name = "AwallIndicator"
        Frame.Size = UDim2.new(0, state.awallSize, 0, state.awallSize)
        Frame.BackgroundColor3 = Color3.fromRGB(255, 50, 60)
        Frame.BorderSizePixel = 1
        Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Frame.Visible = false
        Frame.ZIndex = 999
        Frame.Parent = ScreenGui

        Box = {
            SetVisible = function(v) Frame.Visible = v end,
            SetPos = function(x, y) Frame.Position = UDim2.new(0, x, 0, y) end,
            SetColor = function(c) Frame.BackgroundColor3 = c end,
            SetSize = function(s) Frame.Size = UDim2.new(0, s, 0, s) end
        }
    end

    local function isEnemy(part)
        if not part then return false end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and part:IsDescendantOf(plr.Character) then
                return true
            end
        end
        return false
    end

    local conn = RunService.RenderStepped:Connect(function()
        if not state.awallEnabled then
            if Stroke then Stroke.Visible = false end
            if Box.SetVisible then Box.SetVisible(false) else Box.Visible = false end
            return
        end

        local screenPos, rayOrigin, rayDirection
        if state.awallMode == "MOUSE" then
            local mouseLoc = UserInputService:GetMouseLocation()
            screenPos = Vector2.new(mouseLoc.X + 12, mouseLoc.Y + 12)
            local unitRay = Camera:ViewportPointToRay(mouseLoc.X, mouseLoc.Y)
            rayOrigin, rayDirection = unitRay.Origin, unitRay.Direction * 1500
        else
            local center = Camera.ViewportSize / 2
            screenPos = Vector2.new(center.X - (state.awallSize / 2), center.Y + 16)
            local unitRay = Camera:ViewportPointToRay(center.X, center.Y)
            rayOrigin, rayDirection = unitRay.Origin, unitRay.Direction * 1500
        end

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local filter = {}
        if LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
        params.FilterDescendantsInstances = filter

        local result = Workspace:Raycast(rayOrigin, rayDirection, params)
        local hasTarget = result and result.Instance and isEnemy(result.Instance)
        local targetCol = hasTarget and Color3.fromRGB(50, 255, 100) or Color3.fromRGB(255, 50, 60)

        if Box.SetVisible then
            Box.SetVisible(true)
            Box.SetPos(screenPos.X, screenPos.Y)
            Box.SetColor(targetCol)
            Box.SetSize(state.awallSize)
        else
            Box.Size = Vector2.new(state.awallSize, state.awallSize)
            Box.Position = screenPos
            Box.Color = targetCol
            Box.Visible = true

            if Stroke then
                Stroke.Size = Vector2.new(state.awallSize + 2, state.awallSize + 2)
                Stroke.Position = Vector2.new(screenPos.X - 1, screenPos.Y - 1)
                Stroke.Visible = true
            end
        end
    end)

    local function cleanup()
        pcall(function() conn:Disconnect() end)
        if Box and not Box.SetVisible then pcall(function() Box:Remove() end) end
        if Stroke then pcall(function() Stroke:Remove() end) end
    end

    return { State = state, Cleanup = cleanup }
end

return Visual
