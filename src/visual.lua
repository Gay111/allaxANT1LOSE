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
        awallSize = 1.2, -- Размер в стадах (3D studs)
        penetrationDepth = 8, -- Глубина сквозной проверки за стеной
        awallMode = "MOUSE" -- "MOUSE" или "CENTER"
    }

    -- 3D Неоновый маркер на поверхности стены (Memesense Style)
    local MarkerPart = Instance.new("Part")
    MarkerPart.Name = "Antilose_3DAwallMarker"
    MarkerPart.Material = Enum.Material.Neon
    MarkerPart.Transparency = 0.25
    MarkerPart.Color = Color3.fromRGB(255, 30, 40)
    MarkerPart.Anchored = true
    MarkerPart.CanCollide = false
    MarkerPart.CanTouch = false
    MarkerPart.CanQuery = false
    MarkerPart.CastShadow = false
    MarkerPart.Size = Vector3.new(state.awallSize, state.awallSize, 0.02)
    MarkerPart.Parent = Camera

    -- Тонкий контур вокруг 3D квадрата
    local MarkerOutline = Instance.new("SelectionBox")
    MarkerOutline.Name = "Outline"
    MarkerOutline.Adornee = MarkerPart
    MarkerOutline.Color3 = Color3.fromRGB(0, 0, 0)
    MarkerOutline.LineThickness = 0.02
    MarkerOutline.SurfaceTransparency = 1
    MarkerOutline.Parent = MarkerPart

    local function isEnemyCharacter(instance)
        if not instance then return false end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and instance:IsDescendantOf(plr.Character) then
                return true
            end
        end
        return false
    end

    local conn = RunService.RenderStepped:Connect(function()
        if not state.awallEnabled then
            MarkerPart.Transparency = 1
            MarkerOutline.Visible = false
            return
        end

        local rayOrigin, rayDirection

        if state.awallMode == "MOUSE" then
            local mouseLoc = UserInputService:GetMouseLocation()
            local unitRay = Camera:ViewportPointToRay(mouseLoc.X, mouseLoc.Y)
            rayOrigin = unitRay.Origin
            rayDirection = unitRay.Direction * 2000
        else
            local center = Camera.ViewportSize / 2
            local unitRay = Camera:ViewportPointToRay(center.X, center.Y)
            rayOrigin = unitRay.Origin
            rayDirection = unitRay.Direction * 2000
        end

        -- Фильтр игнорирования своего персонажа и маркера
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local filter = { MarkerPart }
        if LocalPlayer.Character then
            table.insert(filter, LocalPlayer.Character)
        end
        rayParams.FilterDescendantsInstances = filter

        -- 1-й рейкаст: поиск поверхности стены
        local hitResult = Workspace:Raycast(rayOrigin, rayDirection, rayParams)

        if hitResult and hitResult.Instance then
            local hitPos = hitResult.Position
            local hitNormal = hitResult.Normal
            local hitInstance = hitResult.Instance

            local isPenetrableOrDirectHit = false

            -- Проверка прямого попадания во врага
            if isEnemyCharacter(hitInstance) then
                isPenetrableOrDirectHit = true
            else
                -- 2-й сквозной рейкаст за стену (Penetration Check)
                local dir = rayDirection.Unit
                local penOrigin = hitPos + (dir * 0.1)
                local penDirection = dir * state.penetrationDepth

                local penParams = RaycastParams.new()
                penParams.FilterType = Enum.RaycastFilterType.Exclude
                local penFilter = { MarkerPart, hitInstance }
                if LocalPlayer.Character then
                    table.insert(penFilter, LocalPlayer.Character)
                end
                penParams.FilterDescendantsInstances = penFilter

                local penResult = Workspace:Raycast(penOrigin, penDirection, penParams)
                if penResult and penResult.Instance and isEnemyCharacter(penResult.Instance) then
                    isPenetrableOrDirectHit = true
                end
            end

            -- Выравнивание 3D-квадрата по нормали стены + микро-смещение (0.01 studs) против мерцания
            MarkerPart.Size = Vector3.new(state.awallSize, state.awallSize, 0.02)
            MarkerPart.CFrame = CFrame.lookAt(hitPos + (hitNormal * 0.015), hitPos + hitNormal)
            MarkerPart.Color = isPenetrableOrDirectHit and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 30, 40)
            MarkerPart.Transparency = 0.25
            MarkerOutline.Visible = true
        else
            -- Если луч уходит в небо/пустоту
            MarkerPart.Transparency = 1
            MarkerOutline.Visible = false
        end
    end)

    local function cleanup()
        pcall(function() conn:Disconnect() end)
        if MarkerPart then
            MarkerPart:Destroy()
        end
    end

    return { State = state, Cleanup = cleanup }
end

return Visual
