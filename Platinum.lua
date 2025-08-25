local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local settings = {
    AimbotEnabled = false,
    FOV = 100,
    RainbowFOV = false,
    FOVColor = Color3.fromRGB(255, 255, 255),
    AimAt = "Head",
    ChamsEnabled = false,
    TeamCheck = true,
    Tracers = false,
    RefreshRate = 20,
    ShowFOV = false,
    TeamColor = Color3.fromRGB(0, 255, 0),  -- Default team color
    EnemyColor = Color3.fromRGB(255, 0, 0), -- Default enemy color
    ChamsTransparency = 0.5,
    AimSensitivity = 0.1,
    AimSmoothness = 1.0
}

local aimKey = Enum.KeyCode.E
local holdingKey = false
local awaitingKeybind = false

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.Transparency = 1
fovCircle.Filled = false

RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Radius = settings.FOV
    fovCircle.Color = settings.RainbowFOV and Color3.fromHSV(tick() % 5 / 5, 1, 1) or settings.FOVColor
    fovCircle.Visible = settings.ShowFOV
end)

local highlights = {}
local function removeHighlight(player)
    local h = highlights[player]
    if h then
        h:Destroy()
        highlights[player] = nil
    end
end

local function refreshAllChams()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
            removeHighlight(player)
            local highlight = Instance.new("Highlight")
            highlight.Name = "ESPHighlight"
            if settings.TeamCheck then
                if player.Team == LocalPlayer.Team then
                    highlight.FillColor = settings.TeamColor
                else
                    highlight.FillColor = settings.EnemyColor
                end
            else
                if player.Team == LocalPlayer.Team then
                    highlight.FillColor = settings.TeamColor
                else
                    highlight.FillColor = settings.EnemyColor
                end
            end
            highlight.FillTransparency = settings.ChamsTransparency
            highlight.OutlineTransparency = 0
            highlight.Adornee = player.Character
            highlight.Parent = player.Character
            highlights[player] = highlight
        end
    end
end

local function recheckAll()
    for _, player in ipairs(Players:GetPlayers()) do
        removeHighlight(player)
    end
    if settings.ChamsEnabled then refreshAllChams() end
end

Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player)
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if settings.ChamsEnabled then
            task.wait(0.5)
            refreshAllChams()
        end
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function()
        if settings.ChamsEnabled then
            task.wait(0.5)
            refreshAllChams()
        end
    end)
end

local function getClosestPlayer()
    local closest, closestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(settings.AimAt) then
            if settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
            local part = player.Character:FindFirstChild(settings.AimAt)
            if part then
                local targetPosition = part.Position
                if settings.AimAt == "Torso" then
                    targetPosition = targetPosition - Vector3.new(0, 1, 0) 
                end

                local pos, onScreen = Camera:WorldToViewportPoint(targetPosition)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - Camera.ViewportSize / 2).Magnitude
                    if dist < settings.FOV and dist < closestDist then
                        closest, closestDist = player, dist
                    end
                end
            end
        end
    end
    return closest
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if awaitingKeybind and input.UserInputType == Enum.UserInputType.Keyboard then
        aimKey = input.KeyCode
        awaitingKeybind = false
        Rayfield:Notify({Title = "Keybind Set", Content = "Aimbot key is now " .. tostring(aimKey.Name)})
    elseif input.KeyCode == aimKey then
        holdingKey = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == aimKey then
        holdingKey = false
    end
end)

RunService.RenderStepped:Connect(function()
    if settings.AimbotEnabled and holdingKey then
        local target = getClosestPlayer()
        if target and target.Character then
            local part = target.Character:FindFirstChild(settings.AimAt)
            if part then
                local targetPosition = part.Position
                if settings.AimAt == "Torso" then
                    targetPosition = targetPosition - Vector3.new(0, 1, 0) 
                end

                local direction = (targetPosition - Camera.CFrame.Position).Unit
                local newDirection = Camera.CFrame.LookVector:Lerp(direction, settings.AimSensitivity * settings.AimSmoothness)
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + newDirection)
            end
        end
    end
end)

local tracers = {}
local lastTracerUpdate = 0

-- Function to clear all tracers
local function clearAllTracers()
    for _, line in pairs(tracers) do
        line:Remove()
    end
    tracers = {} -- Clear the tracers table
end

RunService.RenderStepped:Connect(function()
    if settings.Tracers then
        if tick() - lastTracerUpdate >= settings.RefreshRate / 1000 then
            lastTracerUpdate = tick()

            -- First, hide the current tracers before updating them
            for _, line in pairs(tracers) do
                line.Visible = false
            end

            -- Now, create new tracers for players
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    if settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
                    local hrp = player.Character.HumanoidRootPart
                    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local tracer = tracers[player] or Drawing.new("Line")
                        tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                        tracer.Color = Color3.new(1, 1, 1)
                        tracer.Thickness = 1
                        tracer.Transparency = 1
                        tracer.Visible = true
                        tracers[player] = tracer
                    end
                end
            end
        end
    else
        -- Clear all tracers if the tracers setting is off
        clearAllTracers()
    end
end)

-- UI Setup
local Window = Rayfield:CreateWindow({
    Name = "Aimbot + Visuals Hub",
    Icon = 0,
    LoadingTitle = "Rayfield UI",
    LoadingSubtitle = "Aimbot + ESP",
    Theme = "Default",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "TC2Cheats",
        FileName = "UserConfig"
    }
})

local AimbotTab = Window:CreateTab("Aimbot", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)

AimbotTab:CreateSection("Aimbot")
AimbotTab:CreateToggle({ Name = "Enable Aimbot", CurrentValue = false, Callback = function(v) settings.AimbotEnabled = v end })
AimbotTab:CreateButton({ Name = "Set Aimbot Key", Callback = function() awaitingKeybind = true Rayfield:Notify({Title = "Keybind", Content = "Press any key..."}) end })
AimbotTab:CreateParagraph({ Title = "Note", Content = "Aimbot targets the head by default. Aimbot Hold Key" })
AimbotTab:CreateSlider({ Name = "Sensitivity", Range = {0.01, 1}, Increment = 0.01, CurrentValue = settings.AimSensitivity, Callback = function(v) settings.AimSensitivity = v end })
AimbotTab:CreateSlider({ Name = "Smoothness", Range = {0.1, 5}, Increment = 0.1, CurrentValue = settings.AimSmoothness, Callback = function(v) settings.AimSmoothness = v end })
AimbotTab:CreateParagraph({ Title = "Note", Content = "⚠️ Do not set smoothness above 1.5 or the aimbot might break." })

AimbotTab:CreateSection("FOV")
AimbotTab:CreateToggle({ Name = "Show FOV", CurrentValue = false, Callback = function(v) settings.ShowFOV = v end })
AimbotTab:CreateToggle({ Name = "Rainbow", CurrentValue = false, Callback = function(v) settings.RainbowFOV = v end })
AimbotTab:CreateColorPicker({ Name = "FOV Color", Color = settings.FOVColor, Callback = function(c) settings.FOVColor = c end })
AimbotTab:CreateSlider({ Name = "FOV Size", Range = {1, 250}, Increment = 1, CurrentValue = settings.FOV, Callback = function(v) settings.FOV = v end })

VisualsTab:CreateSection("ESP")
VisualsTab:CreateToggle({ Name = "Enable ESP", CurrentValue = false, Callback = function(v) settings.ChamsEnabled = v if v then refreshAllChams() else recheckAll() end end })
VisualsTab:CreateToggle({ Name = "Team Check", CurrentValue = settings.TeamCheck, Callback = function(v) settings.TeamCheck = v recheckAll() end })
VisualsTab:CreateColorPicker({ Name = "Team Color", Color = settings.TeamColor, Callback = function(c) settings.TeamColor = c end })
VisualsTab:CreateColorPicker({ Name = "Enemy Color", Color = settings.EnemyColor, Callback = function(c) settings.EnemyColor = c end })
VisualsTab:CreateSlider({ Name = "Chams Transparency", Range = {0, 1}, Increment = 0.05, CurrentValue = settings.ChamsTransparency, Callback = function(v) settings.ChamsTransparency = v recheckAll() end })

VisualsTab:CreateSection("Tracers")
VisualsTab:CreateToggle({ Name = "Tracers", CurrentValue = false, Callback = function(v) settings.Tracers = v end })
VisualsTab:CreateSlider({ Name = "Refresh Rate", Range = {1, 100}, Increment = 1, CurrentValue = settings.RefreshRate, Callback = function(v) settings.RefreshRate = v end })
VisualsTab:CreateButton({ Name = "Fix Visuals", Callback = recheckAll })