-- ===================================================================
-- ZENITH ELEGANT 1:1 - NEW CLEAN HYBRID MINI SCRIPT
-- Features: Visual, Air Walk + Noclip Combo, Simple Speed Controller
-- ===================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- -------------------------------------------------------------------
-- 1. STATE MANAGEMENT
-- -------------------------------------------------------------------
local State = {
    -- Visual Features
    ESPBox = false,
    ESPLine = false,
    Fullbright = false,
    CameraXRay = false,
    
    -- Action Features
    AirWalkNoclip = false,
    WalkspeedToggle = false,
    WalkspeedValue = 16,
    
    -- Environment Backup
    OriginalAmbient = Lighting.Ambient,
    OriginalOutdoorAmbient = Lighting.OutdoorAmbient,
    OriginalBrightness = Lighting.Brightness,
    OriginalClockTime = Lighting.ClockTime,
    OriginalFogEnd = Lighting.FogEnd
}

local ESPStorage = {}

-- -------------------------------------------------------------------
-- 2. HELPER & UTILITY FUNCTIONS
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
-- 3. CORE LOGIC IMPLEMENTATIONS
-- -------------------------------------------------------------------

-- ESP System
local function ClearESP(player)
    if ESPStorage[player] then
        for _, obj in pairs(ESPStorage[player]) do
            if obj and obj.Destroy then obj:Destroy() end
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

-- Fullbright System
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

-- Camera X-Ray System
local function UpdateCameraSystem()
    if State.CameraXRay then
        LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
        LocalPlayer.CameraMinZoomDistance = 0.5
        LocalPlayer.CameraMaxZoomDistance = 400
    else
        LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
    end
end

-- Air Walk + Noclip Platform
local AirWalkPlatform = Instance.new("Part")
AirWalkPlatform.Size = Vector3.new(8, 0.4, 8)
AirWalkPlatform.Anchored = true
AirWalkPlatform.Transparency = 1
AirWalkPlatform.Color = Color3.fromRGB(150, 80, 255)
AirWalkPlatform.Material = Enum.Material.SmoothPlastic
AirWalkPlatform.CanCollide = false
AirWalkPlatform.Name = "ZenAirWalkPlatform"
AirWalkPlatform.Parent = workspace

local lockedY = nil

local function UpdateAirWalkNoclip()
    local char = GetCharacter(LocalPlayer)
    local root = GetRoot(LocalPlayer)
    
    if State.AirWalkNoclip and char and root then
        if not lockedY then
            lockedY = root.Position.Y - 3.15
        end

        AirWalkPlatform.CFrame = CFrame.new(root.Position.X, lockedY, root.Position.Z)
        AirWalkPlatform.CanCollide = true
        AirWalkPlatform.Transparency = 0.5

        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part ~= AirWalkPlatform and part.CanCollide then
                part.CanCollide = false
            end
        end
    else
        lockedY = nil
        AirWalkPlatform.CanCollide = false
        AirWalkPlatform.Transparency = 1
    end
end

-- Teleport Farthest Player
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

-- Main RenderLoop Connection
RunService.RenderStepped:Connect(function()
    UpdateESP()
    UpdateAirWalkNoclip()
    UpdateCameraSystem()
    
    local hum = GetHumanoid(LocalPlayer)
    if hum and State.WalkspeedToggle then
        hum.WalkSpeed = State.WalkspeedValue
    end
end)

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(function(p) CreateESP(p) end)
Players.PlayerRemoving:Connect(function(p) ClearESP(p) end)

-- -------------------------------------------------------------------
-- 4. USER INTERFACE (CLEAN 1:1 MINI UI)
-- -------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZenithCleanMiniUI"
ScreenGui.ResetOnSpawn = false

if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = CoreGui
end

-- Main Frame (260x260 px)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 260, 0, 260)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -130)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(60, 75, 110)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

local MainGrad = Instance.new("UIGradient")
MainGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 34, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 20, 28))
})
MainGrad.Rotation = 45
MainGrad.Parent = MainFrame

-- Floating Toggle Button (Z Button)
local FloatBtn = Instance.new("TextButton")
FloatBtn.Name = "FloatButton"
FloatBtn.Size = UDim2.new(0, 54, 0, 54)
FloatBtn.Position = UDim2.new(0, 15, 0.4, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(20, 25, 38)
FloatBtn.Text = "Z"
FloatBtn.TextColor3 = Color3.fromRGB(90, 210, 255)
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.TextSize = 22
FloatBtn.Visible = false
FloatBtn.Active = true
FloatBtn.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(1, 0)
FloatCorner.Parent = FloatBtn

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color = Color3.fromRGB(40, 160, 255)
FloatStroke.Thickness = 2.5
FloatStroke.Parent = FloatBtn

local FloatGrad = Instance.new("UIGradient")
FloatGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(32, 45, 75)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(18, 24, 38)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 14, 22))
})
FloatGrad.Rotation = 135
FloatGrad.Parent = FloatBtn

-- Red Accent Badge on Floating Button
local RedDot = Instance.new("Frame")
RedDot.Name = "RedDotAccent"
RedDot.Size = UDim2.new(0, 15, 0, 15)
RedDot.Position = UDim2.new(1, -16, 0, 3)
RedDot.BackgroundColor3 = Color3.fromRGB(255, 35, 50)
RedDot.BorderSizePixel = 0
RedDot.Parent = FloatBtn

local RedDotCorner = Instance.new("UICorner")
RedDotCorner.CornerRadius = UDim.new(1, 0)
RedDotCorner.Parent = RedDot

local RedDotStroke = Instance.new("UIStroke")
RedDotStroke.Color = Color3.fromRGB(255, 130, 140)
RedDotStroke.Thickness = 1.5
RedDotStroke.Parent = RedDot

-- Smooth Dragging Logic
local dragging, dragStart, startPos
FloatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = FloatBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        local targetPos = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        TweenService:Create(FloatBtn, TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = targetPos}):Play()
    end
end)

-- Header Bar
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 36)
Header.BackgroundTransparency = 1
Header.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Text = "ZENITH • MINI"
Title.TextColor3 = Color3.fromRGB(230, 235, 250)
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -30, 0, 6)
CloseBtn.Text = "-"
CloseBtn.TextColor3 = Color3.fromRGB(200, 205, 220)
CloseBtn.BackgroundColor3 = Color3.fromRGB(32, 38, 52)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

-- Smooth Minimize / Maximize Animations
CloseBtn.MouseButton1Click:Connect(function()
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    TweenService:Create(MainFrame, tweenInfo, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}):Play()
    task.delay(0.2, function()
        MainFrame.Visible = false
        MainFrame.Size = UDim2.new(0, 260, 0, 260)
        MainFrame.BackgroundTransparency = 0
        
        FloatBtn.Size = UDim2.new(0, 0, 0, 0)
        FloatBtn.Visible = true
        TweenService:Create(FloatBtn, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 54, 0, 54)}):Play()
    end)
end)

FloatBtn.MouseButton1Click:Connect(function()
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    TweenService:Create(FloatBtn, tweenInfo, {Size = UDim2.new(0, 0, 0, 0)}):Play()
    task.delay(0.2, function()
        FloatBtn.Visible = false
        FloatBtn.Size = UDim2.new(0, 54, 0, 54)
        
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        MainFrame.BackgroundTransparency = 1
        MainFrame.Visible = true
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 260, 0, 260), BackgroundTransparency = 0}):Play()
    end)
end)

-- Scrolling Container
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -42)
Scroll.Position = UDim2.new(0, 8, 0, 38)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 100, 140)
Scroll.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 5)
Layout.Parent = Scroll

Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 10)
end)

-- -------------------------------------------------------------------
-- 5. UI COMPONENT BUILDERS (CLEAN & MODULAR)
-- -------------------------------------------------------------------
local function AddCategory(name)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -6, 0, 20)
    label.Text = name
    label.TextColor3 = Color3.fromRGB(120, 140, 180)
    label.TextSize = 10
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = Scroll
end

local function AddToggle(text, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(28, 34, 48)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.Parent = Scroll

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(48, 58, 82)
    stroke.Thickness = 1
    stroke.Parent = btn

    local currentState = defaultState
    local function Render()
        btn.Text = text .. " -> " .. (currentState and "ON" or "OFF")
        btn.TextColor3 = currentState and Color3.fromRGB(110, 240, 180) or Color3.fromRGB(180, 185, 200)
    end
    Render()

    btn.MouseButton1Click:Connect(function()
        currentState = not currentState
        Render()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = currentState and Color3.fromRGB(36, 48, 72) or Color3.fromRGB(28, 34, 48)}):Play()
        pcall(callback, currentState)
    end)
end

local function AddButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(32, 38, 55)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(210, 215, 235)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.Parent = Scroll

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(55, 68, 98)
    stroke.Thickness = 1
    stroke.Parent = btn

    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(48, 62, 92)}):Play()
        task.delay(0.1, function()
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(32, 38, 55)}):Play()
        end)
        pcall(callback)
    end)
end

local function AddWalkspeedControl()
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -6, 0, 32)
    container.BackgroundColor3 = Color3.fromRGB(28, 34, 48)
    container.Parent = Scroll

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(48, 58, 82)
    stroke.Thickness = 1
    stroke.Parent = container

    local label = Instance.new("TextButton")
    label.Size = UDim2.new(0.55, 0, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "Speed: 16"
    label.TextColor3 = Color3.fromRGB(180, 185, 200)
    label.TextSize = 11
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local minusBtn = Instance.new("TextButton")
    minusBtn.Size = UDim2.new(0, 26, 0, 22)
    minusBtn.Position = UDim2.new(0.58, 0, 0.15, 0)
    minusBtn.BackgroundColor3 = Color3.fromRGB(36, 44, 64)
    minusBtn.Text = "-"
    minusBtn.TextColor3 = Color3.fromRGB(210, 215, 235)
    minusBtn.Font = Enum.Font.GothamBold
    minusBtn.TextSize = 12
    minusBtn.Parent = container

    local mCorner = Instance.new("UICorner")
    mCorner.CornerRadius = UDim.new(0, 4)
    mCorner.Parent = minusBtn

    local plusBtn = Instance.new("TextButton")
    plusBtn.Size = UDim2.new(0, 26, 0, 22)
    plusBtn.Position = UDim2.new(0.78, 0, 0.15, 0)
    plusBtn.BackgroundColor3 = Color3.fromRGB(36, 44, 64)
    plusBtn.Text = "+"
    plusBtn.TextColor3 = Color3.fromRGB(210, 215, 235)
    plusBtn.Font = Enum.Font.GothamBold
    plusBtn.TextSize = 12
    plusBtn.Parent = container

    local pCorner = Instance.new("UICorner")
    pCorner.CornerRadius = UDim.new(0, 4)
    pCorner.Parent = plusBtn

    local function UpdateDisplay()
        label.Text = "Speed: " .. State.WalkspeedValue .. " (" .. (State.WalkspeedToggle and "ON" or "OFF") .. ")"
        label.TextColor3 = State.WalkspeedToggle and Color3.fromRGB(110, 240, 180) or Color3.fromRGB(180, 185, 200)
    end

    label.MouseButton1Click:Connect(function()
        State.WalkspeedToggle = not State.WalkspeedToggle
        UpdateDisplay()
    end)

    minusBtn.MouseButton1Click:Connect(function()
        State.WalkspeedValue = math.max(16, State.WalkspeedValue - 8)
        State.WalkspeedTog
