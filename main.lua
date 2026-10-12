-- ===================================================================
-- ZENITH ELEGANT 1:1 - MINI HYBRID SCRIPT (FULL CODE)
-- Features: Visual, Action, Manual Walkspeed, Soft Sound & Aligned Air Walk
-- ===================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- -------------------------------------------------------------------
-- STATE MANAGEMENT
-- -------------------------------------------------------------------
local State = {
    -- Visual Features
    ESPBox = false,
    ESPLine = false,
    Fullbright = false,
    CameraXRay = false,
    
    -- Action Features
    AirWalk = false,
    AirWalkHeight = 0,
    Noclip = false,
    BypassCamera = false,
    WalkspeedToggle = false,
    WalkspeedValue = 16,
    
    -- Lighting Backup
    OriginalAmbient = Lighting.Ambient,
    OriginalOutdoorAmbient = Lighting.OutdoorAmbient,
    OriginalBrightness = Lighting.Brightness,
    OriginalClockTime = Lighting.ClockTime,
    OriginalFogEnd = Lighting.FogEnd
}

local ESPStorage = {}

-- -------------------------------------------------------------------
-- AUDIO SYSTEM (Calm & Soft Feedback)
-- -------------------------------------------------------------------
local function PlaySoftSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://6895079853"
    sound.Volume = 0.3
    sound.Pitch = 1.2
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- -------------------------------------------------------------------
-- HELPER FUNCTIONS
-- -------------------------------------------------------------------
local function GetCharacter(player)
    return player and player.Character or nil
end

local function GetRoot(player)
    local char = GetCharacter(player)
    return char and char:FindFirstChild("HumanoidRootPart") or nil
end

local function GetHumanoid(player)
    local char = GetCharacter(player)
    return char and char:FindFirstChildOfClass("Humanoid") or nil
end

-- -------------------------------------------------------------------
-- VISUAL FEATURES IMPLEMENTATION
-- -------------------------------------------------------------------
local function ClearESP(player)
    if ESPStorage[player] then
        for _, obj in pairs(ESPStorage[player]) do
            if obj and obj.Destroy then
                obj:Destroy()
            end
        end
        ESPStorage[player] = nil
    end
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    ClearESP(player)

    local box = Drawing.new("Square")
    box.Thickness = 1.2
    box.Filled = false
    box.Color = Color3.fromRGB(120, 140, 255)
    box.Visible = false

    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Color = Color3.fromRGB(120, 140, 255)
    line.Visible = false

    ESPStorage[player] = {Box = box, Line = line}
end

local function UpdateESP()
    for player, drawings in pairs(ESPStorage) do
        local root = GetRoot(player)
        local hum = GetHumanoid(player)
        
        if root and hum and hum.Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            
            if onScreen then
                local head = GetCharacter(player):FindFirstChild("Head")
                local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or pos
                local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                
                local height = math.abs(headPos.Y - legPos.Y)
                local width = height / 2

                if State.ESPBox then
                    drawings.Box.Size = Vector2.new(width, height)
                    drawings.Box.Position = Vector2.new(pos.X - width / 2, pos.Y - height / 2)
                    drawings.Box.Visible = true
                else
                    drawings.Box.Visible = false
                end

                if State.ESPLine then
                    drawings.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    drawings.Line.To = Vector2.new(pos.X, pos.Y)
                    drawings.Line.Visible = true
                else
                    drawings.Line.Visible = false
                end
            else
                drawings.Box.Visible = false
                drawings.Line.Visible = false
            end
        else
            drawings.Box.Visible = false
            drawings.Line.Visible = false
        end
    end
end

local function ToggleFullbright(value)
    State.Fullbright = value
    if value then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
    else
        Lighting.Ambient = State.OriginalAmbient
        Lighting.OutdoorAmbient = State.OriginalOutdoorAmbient
        Lighting.Brightness = State.OriginalBrightness
        Lighting.ClockTime = State.OriginalClockTime
        Lighting.FogEnd = State.OriginalFogEnd
    end
end

local function UpdateCameraSystem()
    if State.CameraXRay or State.BypassCamera then
        LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
        LocalPlayer.CameraMinZoomDistance = 0.5
        LocalPlayer.CameraMaxZoomDistance = 400
    else
        LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
    end
end

-- -------------------------------------------------------------------
-- ACTION FEATURES IMPLEMENTATION
-- -------------------------------------------------------------------

-- Air Walk Engine (Turun sejajar dengan tanah / pemain lain)
local AirWalkPlatform = Instance.new("Part")
AirWalkPlatform.Size = Vector3.new(10, 2.5, 10)
AirWalkPlatform.Anchored = true
AirWalkPlatform.Transparency = 0.65
AirWalkPlatform.Color = Color3.fromRGB(150, 80, 255)
AirWalkPlatform.Material = Enum.Material.SmoothPlastic
AirWalkPlatform.CanCollide = false
AirWalkPlatform.Name = "ZenPurpleAirWalkPlatform"
AirWalkPlatform.Parent = workspace

local PlatformSelection = Instance.new("SelectionBox")
PlatformSelection.Color3 = Color3.fromRGB(180, 100, 255)
PlatformSelection.LineThickness = 0.03
PlatformSelection.Adornee = AirWalkPlatform
PlatformSelection.Parent = AirWalkPlatform

local function UpdateAirWalk()
    local root = GetRoot(LocalPlayer)
    if State.AirWalk and root then
        if State.AirWalkHeight == 0 then
            -- Diubah dari -3.8 menjadi -4.6 agar posisi blok turun sejajar tanah
            State.AirWalkHeight = root.Position.Y - 4.6
        end
        AirWalkPlatform.CFrame = CFrame.new(root.Position.X, State.AirWalkHeight, root.Position.Z)
        AirWalkPlatform.CanCollide = true
    else
        AirWalkPlatform.CanCollide = false
        if root then
            State.AirWalkHeight = root.Position.Y - 4.6
        end
    end
end

RunService.Stepped:Connect(function()
    if State.Noclip and GetCharacter(LocalPlayer) then
        for _, part in pairs(GetCharacter(LocalPlayer):GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

local function TeleportFarthestPlayer()
    local myRoot = GetRoot(LocalPlayer)
    if not myRoot then return end

    local farthestPlayer = nil
    local maxDistance = 0

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local targetRoot = GetRoot(player)
            if targetRoot then
                local dist = (targetRoot.Position - myRoot.Position).Magnitude
                if dist > maxDistance then
                    maxDistance = dist
                    farthestPlayer = player
                end
            end
        end
    end

    if farthestPlayer and GetRoot(farthestPlayer) then
        myRoot.CFrame = GetRoot(farthestPlayer).CFrame * CFrame.new(0, 2, 0)
    end
end

-- -------------------------------------------------------------------
-- MAIN LOOP
-- -------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    UpdateESP()
    UpdateAirWalk()
    UpdateCameraSystem()
    
    local hum = GetHumanoid(LocalPlayer)
    if hum then
        if State.WalkspeedToggle then
            hum.WalkSpeed = State.WalkspeedValue
        end
    end
end)

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(function(p) CreateESP(p) end)
Players.PlayerRemoving:Connect(function(p) ClearESP(p) end)

-- -------------------------------------------------------------------
-- ELEGANT MINI UI (1:1 RATIO COMPACT FRAME)
-- -------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZenithMiniUI"
ScreenGui.ResetOnSpawn = false

if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = CoreGui
end

-- Main Box 1:1 Aspect Ratio (260x260 pixel)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 260, 0, 260)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -130)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 52, 70)
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

-- Floating Toggle Button
local FloatBtn = Instance.new("TextButton")
FloatBtn.Name = "FloatButton"
FloatBtn.Size = UDim2.new(0, 42, 0, 42)
FloatBtn.Position = UDim2.new(0, 15, 0.4, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 33)
FloatBtn.Text = "Z"
FloatBtn.TextColor3 = Color3.fromRGB(120, 140, 255)
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.TextSize = 16
FloatBtn.Visible = false
FloatBtn.Active = true
FloatBtn.Draggable = true
FloatBtn.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(1, 0)
FloatCorner.Parent = FloatBtn

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color = Color3.fromRGB(60, 70, 95)
FloatStroke.Thickness = 1.5
FloatStroke.Parent = FloatBtn

-- Header Bar
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 36)
Header.BackgroundTransparency = 1
Header.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Text = "ZENITH • MINI"
Title.TextColor3 = Color3.fromRGB(220, 225, 240)
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -30, 0, 6)
CloseBtn.Text = "-"
CloseBtn.TextColor3 = Color3.fromRGB(160, 165, 180)
CloseBtn.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    PlaySoftSound()
    MainFrame.Visible = false
    FloatBtn.Visible = true
end)

FloatBtn.MouseButton1Click:Connect(function()
    PlaySoftSound()
    FloatBtn.Visible = false
    MainFrame.Visible = true
end)

-- Scrolling Container
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -42)
Scroll.Position = UDim2.new(0, 8, 0, 38)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = Color3.fromRGB(60, 70, 95)
Scroll.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 5)
Layout.Parent = Scroll

Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 10)
end)

-- UI Helpers
local function AddCategory(name)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -6, 0, 20)
    label.Text = name
    label.TextColor3 = Color3.fromRGB(90, 105, 140)
    label.TextSize = 10
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = Scroll
end

local function AddToggle(text, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.Parent = Scroll

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local currentState = defaultState
    local function Render()
        btn.Text = text .. " -> " .. (currentState and "ON" or "OFF")
        btn.TextColor3 = currentState and Color3.fromRGB(120, 220, 160) or Color3.fromRGB(160, 165, 180)
    end
    Render()

    btn.MouseButton1Click:Connect(function()
        PlaySoftSound()
        currentState = not currentState
        Render()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = currentState and Color3.fromRGB(28, 35, 48) or Color3.fromRGB(22, 25, 34)}):Play()
        pcall(callback, currentState)
    end)
end

local function AddButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 205, 220)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.Parent = Scroll

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        PlaySoftSound()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40, 48, 65)}):Play()
        task.delay(0.1, function()
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(28, 32, 44)}):Play()
        end)
        pcall(callback)
    end)
end

local function AddWalkspeedBox()
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -6, 0, 32)
    container.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
    container.Parent = Scroll

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.55, 0, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.Text = "Walkspeed ->"
    label.TextColor3 = Color3.fromRGB(160, 165, 180)
    label.TextSize = 11
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = container

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0.38, -6, 0.7, 0)
    input.Position = UDim2.new(0.6, 0, 0.15, 0)
    input.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
    input.Text = tostring(State.WalkspeedValue)
    input.TextColor3 = Color3.fromRGB(120, 140, 255)
    input.Font = Enum.Font.GothamBold
    input.TextSize = 11
    input.ClearTextOnFocus = false
    input.Parent = container

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = input

    input.FocusLost:Connect(function(enterPressed)
        local num = tonumber(input.Text)
        if num then
            State.WalkspeedValue = num
            State.WalkspeedToggle = true
            PlaySoftSound()
        else
            input.Text = tostring(State.WalkspeedValue)
        end
    end)
end

-- -------------------------------------------------------------------
-- BUILD UI ITEMS
-- -------------------------------------------------------------------

AddCategory("FITUR VISUAL")
AddToggle("ESP Box", State.ESPBox, function(v) State.ESPBox = v end)
AddToggle("ESP Line", State.ESPLine, function(v) State.ESPLine = v end)
AddToggle("Fullbright (Cerahkan)", State.Fullbright, function(v) ToggleFullbright(v) end)
AddToggle("Camera X-Ray", State.CameraXRay, function(v) State.CameraXRay = v end)

AddCategory("FITUR AKSI")
AddToggle("Air Walk", State.AirWalk, function(v) State.AirWalk = v end)
AddToggle("Noclip (Tembus Wall)", State.Noclip, function(v) State.Noclip = v end)
AddToggle("Bebas Kamera (Bypass)", State.BypassCamera, function(v) State.BypassCamera = v end)
AddWalkspeedBox()
AddButton("TP Player Terjauh", function() TeleportFarthestPlayer() end)
AddButton("Rejoin Server", function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
AddButton("Hop Full Server", function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)

print("Zenith Mini UI Loaded Successfully!")
