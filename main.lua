-- ===================================================================
-- ZENITH • ULTRALIGHT v3.8 - COMPACT HYBRID SCRIPT (LUAU)
-- Optimized for Delta Executor & Mobile Gaming (Clean, Smooth, 1:1 UI)
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
    -- Visual
    ESPBox = false,
    ESPLine = false,
    Fullbright = false,
    CameraXRay = false,
    
    -- Action
    AirWalk = false,
    AirWalkHeight = 0,
    Fly = false,
    FlySpeed = 50,
    Noclip = false,
    BypassCamera = false,
    Walkspeed = false,
    
    -- Backup Lighting
    OriginalAmbient = Lighting.Ambient,
    OriginalOutdoorAmbient = Lighting.OutdoorAmbient,
    OriginalBrightness = Lighting.Brightness,
    OriginalClockTime = Lighting.ClockTime,
    OriginalFogEnd = Lighting.FogEnd
}

-- Storage for ESP Drawings & Chams
local ESPStorage = {}

-- Sound Effect Generator (Tenang & Lembut)
local function PlayClickSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://9114220405" -- Clean subtle UI click sound
    sound.Volume = 0.3
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
-- VISUAL FEATURES
-- -------------------------------------------------------------------
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
    box.Color = Color3.fromRGB(120, 100, 255)
    box.Visible = false

    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Color = Color3.fromRGB(120, 100, 255)
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
                local width = height / 2.2

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

local function ToggleFullbright(val)
    State.Fullbright = val
    if val then
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
        LocalPlayer.CameraMaxZoomDistance = 500
    else
        LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
    end
end

-- -------------------------------------------------------------------
-- ACTION FEATURES
-- -------------------------------------------------------------------
local AirWalkPlatform = Instance.new("Part")
AirWalkPlatform.Size = Vector3.new(6, 0.8, 6)
AirWalkPlatform.Anchored = true
AirWalkPlatform.Transparency = 1
AirWalkPlatform.CanCollide = false
AirWalkPlatform.Parent = workspace

local function UpdateAirWalk()
    local root = GetRoot(LocalPlayer)
    if State.AirWalk and root then
        if State.AirWalkHeight == 0 then
            State.AirWalkHeight = root.Position.Y - 3.2
        end
        AirWalkPlatform.CFrame = CFrame.new(root.Position.X, State.AirWalkHeight, root.Position.Z)
        AirWalkPlatform.CanCollide = true
    else
        AirWalkPlatform.CanCollide = false
        if root then State.AirWalkHeight = root.Position.Y - 3.2 end
    end
end

-- Fly Simple Engine
RunService.RenderStepped:Connect(function()
    local root = GetRoot(LocalPlayer)
    local hum = GetHumanoid(LocalPlayer)
    
    if State.Fly and root and hum then
        hum.PlatformStand = true
        local camCFrame = Camera.CFrame
        local moveDir = Vector3.new()
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
            moveDir = moveDir + camCFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
            moveDir = moveDir - camCFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
            moveDir = moveDir - camCFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
            moveDir = moveDir + camCFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        
        root.Velocity = moveDir * State.FlySpeed
        root.CFrame = CFrame.new(root.Position, root.Position + camCFrame.LookVector)
    elseif hum then
        hum.PlatformStand = false
    end
end)

-- Noclip Engine
RunService.Stepped:Connect(function()
    if State.Noclip and GetCharacter(LocalPlayer) then
        for _, part in pairs(GetCharacter(LocalPlayer):GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

local function TeleportFurthestPlayer()
    local myRoot = GetRoot(LocalPlayer)
    if not myRoot then return end
    
    local furthestPlayer = nil
    local maxDist = 0
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and GetRoot(p) then
            local dist = (GetRoot(p).Position - myRoot.Position).Magnitude
            if dist > maxDist then
                maxDist = dist
                furthestPlayer = p
            end
        end
    end
    
    if furthestPlayer and GetRoot(furthestPlayer) then
        myRoot.CFrame = GetRoot(furthestPlayer).CFrame * CFrame.new(0, 3, 0)
    end
end

-- Main Render Loop
RunService.RenderStepped:Connect(function()
    UpdateESP()
    UpdateAirWalk()
    UpdateCameraSystem()
    
    local hum = GetHumanoid(LocalPlayer)
    if hum and State.Walkspeed then
        hum.WalkSpeed = 80
    end
end)

-- Initialize Players
for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(function(p) CreateESP(p) end)
Players.PlayerRemoving:Connect(function(p) ClearESP(p) end)

-- -------------------------------------------------------------------
-- COMPACT 1:1 UI PANEL IMPLEMENTATION (VISUAL GAMING ELEGANT)
-- -------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZenithUltralightGui"
ScreenGui.ResetOnSpawn = false
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = CoreGui end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainPanel"
MainFrame.Size = UDim2.new(0, 260, 0, 340)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -170)
MainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(75, 65, 180)
UIStroke.Thickness = 1.2
UIStroke.Parent = MainFrame

-- Header
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -35, 0, 35)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Text = "ZENITH • ULTRALIGHT"
Title.TextColor3 = Color3.fromRGB(230, 230, 255)
Title.TextSize = 12
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = MainFrame

-- Close / Hide Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -28, 0, 6)
CloseBtn.Text = "-"
CloseBtn.TextColor3 = Color3.fromRGB(180, 180, 220)
CloseBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    PlayClickSound()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Container Scroll
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -12, 1, -42)
Scroll.Position = UDim2.new(0, 6, 0, 38)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 90, 220)
Scroll.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = Scroll

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
end)

local function CreateHeader(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -6, 0, 20)
    lbl.Text = " " .. text
    lbl.TextColor3 = Color3.fromRGB(130, 130, 170)
    lbl.TextSize = 10
    lbl.Font = Enum.Font.GothamBold
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = Scroll
end

local function CreateToggle(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 11
    btn.Parent = Scroll
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = btn

    local state = false
    local function update()
        btn.Text = text .. " : " .. (state and "ON" or "OFF")
        btn.TextColor3 = state and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(180, 180, 180)
    end
    update()

    btn.MouseButton1Click:Connect(function()
        PlayClickSound()
        state = not state
        update()
        pcall(callback, state)
    end)
end

local function CreateButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(220, 220, 240)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 11
    btn.Parent = Scroll

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        PlayClickSound()
        pcall(callback)
    end)
end

-- Build Menu UI Elements
CreateHeader("FITUR VISUAL")
CreateToggle("ESP Box", function(v) State.ESPBox = v end)
CreateToggle("ESP Line", function(v) State.ESPLine = v end)
CreateToggle("Fullbright", function(v) ToggleFullbright(v) end)
CreateToggle("Camera X-Ray", function(v) State.CameraXRay = v end)

CreateHeader("FITUR AKSI")
CreateToggle("Air Walk", function(v) State.AirWalk = v end)
CreateToggle("Fly Simple", function(v) State.Fly = v end)
CreateToggle("Noclip", function(v) State.Noclip = v end)
CreateToggle("Bebas Kamera", function(v) State.BypassCamera = v end)
CreateToggle("Walkspeed (80)", function(v) State.Walkspeed = v end)
CreateButton("TP Player Terjauh", function() TeleportFurthestPlayer() end)
CreateButton("Rejoin Server", function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
CreateButton("Hop Full Server", function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)

print("Zenith Ultralight v3.8 successfully loaded!")
