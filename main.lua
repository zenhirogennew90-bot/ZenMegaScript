-- ===================================================================
-- ZENITH COMPACT ELEGANT PANEL (LUAU)
-- Compact 1:1 Ratio, Smooth UI, Quiet Sound, Mobile Optimized
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
-- QUIET BUTTON SOUND EFFECT
-- -------------------------------------------------------------------
local ClickSound = Instance.new("Sound")
ClickSound.SoundId = "rbxassetid://6899131464" -- Soft quiet click sound
ClickSound.Volume = 0.25
ClickSound.Parent = CoreGui

local function PlayQuietClick()
    pcall(function()
        ClickSound:Play()
    end)
end

-- -------------------------------------------------------------------
-- STATE MANAGEMENT
-- -------------------------------------------------------------------
local State = {
    -- Visual Features
    ESPBox = false,
    ESPLine = false,
    Fullbright = false,
    CameraXRay = false,
    Spectate = false,
    
    -- Action Features
    AirWalk = false,
    AirWalkHeight = 0,
    Noclip = false,
    BypassCamera = false,
    WalkspeedToggle = false,
    WalkspeedValue = 16,
    AttachFront = false,
    
    -- Target System
    TargetPlayer = nil,
    
    -- Lighting Backup
    OriginalAmbient = Lighting.Ambient,
    OriginalOutdoorAmbient = Lighting.OutdoorAmbient,
    OriginalBrightness = Lighting.Brightness,
    OriginalClockTime = Lighting.ClockTime,
    OriginalFogEnd = Lighting.FogEnd
}

local ESPStorage = {}

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
-- VISUAL LOGIC IMPLEMENTATION
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
    box.Thickness = 1
    box.Filled = false
    box.Color = Color3.fromRGB(120, 110, 255)
    box.Visible = false

    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Color = Color3.fromRGB(120, 110, 255)
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
        LocalPlayer.CameraMaxZoomDistance = 500
    else
        LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
    end
end

local function UpdateSpectate()
    if State.Spectate and State.TargetPlayer and GetHumanoid(State.TargetPlayer) then
        Camera.CameraSubject = GetHumanoid(State.TargetPlayer)
    else
        if GetHumanoid(LocalPlayer) then
            Camera.CameraSubject = GetHumanoid(LocalPlayer)
        end
    end
end

-- -------------------------------------------------------------------
-- ACTION LOGIC IMPLEMENTATION
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
        if root then
            State.AirWalkHeight = root.Position.Y - 3.2
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

local function UpdateAttachFront()
    if State.AttachFront and State.TargetPlayer then
        local targetRoot = GetRoot(State.TargetPlayer)
        local myRoot = GetRoot(LocalPlayer)
        if targetRoot and myRoot then
            myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -2.5)
        end
    end
end

local function TeleportToPlayer(target)
    local targetRoot = GetRoot(target)
    local myRoot = GetRoot(LocalPlayer)
    if targetRoot and myRoot then
        myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 2, 0)
    end
end

local function TeleportRandom()
    local allPlayers = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and GetRoot(p) then
            table.insert(allPlayers, p)
        end
    end
    if #allPlayers > 0 then
        local randomPlayer = allPlayers[math.random(1, #allPlayers)]
        State.TargetPlayer = randomPlayer
        TeleportToPlayer(randomPlayer)
    end
end

-- -------------------------------------------------------------------
-- MAIN LOOP UPDATE
-- -------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    UpdateESP()
    UpdateAirWalk()
    UpdateAttachFront()
    UpdateSpectate()
    UpdateCameraSystem()
    
    local hum = GetHumanoid(LocalPlayer)
    if hum and State.WalkspeedToggle then
        hum.WalkSpeed = State.WalkspeedValue
    end
end)

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(function(p) CreateESP(p) end)
Players.PlayerRemoving:Connect(function(p) 
    ClearESP(p) 
    if State.TargetPlayer == p then State.TargetPlayer = nil end
end)

-- -------------------------------------------------------------------
-- ELEGANT COMPACT 1:1 UI PANEL IMPLEMENTATION
-- -------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZenithCompactGui"
ScreenGui.ResetOnSpawn = false

if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = CoreGui
end

-- Compact Main Frame (Efficient & Small)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainPanel"
MainFrame.Size = UDim2.new(0, 280, 0, 280) -- Balanced 1:1 Compact Aspect
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(60, 60, 90)
UIStroke.Thickness = 1
UIStroke.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 32)
Header.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -35, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Text = "ZENITH COMPACT"
Title.TextColor3 = Color3.fromRGB(210, 210, 240)
Title.TextSize = 11
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -28, 0, 4)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(200, 100, 100)
CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 10
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    PlayQuietClick()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Scrolling Container
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -12, 1, -40)
Scroll.Position = UDim2.new(0, 6, 0, 36)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 140)
Scroll.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.Parent = Scroll

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
end)

local function CreateHeaderLabel(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -4, 0, 20)
    lbl.Text = "--- " .. text .. " ---"
    lbl.TextColor3 = Color3.fromRGB(120, 120, 160)
    lbl.TextSize = 10
    lbl.Font = Enum.Font.GothamBold
    lbl.BackgroundTransparency = 1
    lbl.Parent = Scroll
end

local function CreateToggleBtn(name, getState, setStateFunc)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 10
    btn.Parent = Scroll
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn

    local function refresh()
        local active = getState()
        btn.Text = name .. " -> " .. (active and "ON" or "OFF")
        btn.TextColor3 = active and Color3.fromRGB(130, 255, 170) or Color3.fromRGB(180, 180, 180)
        btn.BackgroundColor3 = active and Color3.fromRGB(28, 42, 34) or Color3.fromRGB(24, 24, 34)
    end
    refresh()

    btn.MouseButton1Click:Connect(function()
        PlayQuietClick()
        local current = getState()
        setStateFunc(not current)
        refresh()
    end)
end

local function CreateActionBtn(name, actionCallback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(220, 220, 230)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 10
    btn.Parent = Scroll

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        PlayQuietClick()
        pcall(actionCallback)
    end)
end

-- BUILD UI ELEMENTS
CreateHeaderLabel("VISUAL")
CreateToggleBtn("ESP Box", function() return State.ESPBox end, function(v) State.ESPBox = v end)
CreateToggleBtn("ESP Line", function() return State.ESPLine end, function(v) State.ESPLine = v end)
CreateToggleBtn("Fullbright", function() return State.Fullbright end, function(v) ToggleFullbright(v) end)
CreateToggleBtn("Camera X-Ray", function() return State.CameraXRay end, function(v) State.CameraXRay = v end)
CreateToggleBtn("Spectate", function() return State.Spectate end, function(v) State.Spectate = v end)

CreateHeaderLabel("AKSI")
CreateToggleBtn("Air Walk", function() return State.AirWalk end, function(v) State.AirWalk = v end)
CreateToggleBtn("Noclip", function() return State.Noclip end, function(v) State.Noclip = v end)
CreateToggleBtn("Bebas Kamera", function() return State.BypassCamera end, function(v) State.BypassCamera = v end)
CreateToggleBtn("Walkspeed (100)", function() return State.WalkspeedToggle end, function(v) 
    State.WalkspeedToggle = v
    State.WalkspeedValue = v and 100 or 16
end)
CreateActionBtn("Teleport To Target", function()
    if State.TargetPlayer then TeleportToPlayer(State.TargetPlayer) end
end)
CreateActionBtn("Teleport Random", function()
    TeleportRandom()
end)
CreateToggleBtn("Attach Front", function() return State.AttachFront end, function(v) State.AttachFront = v end)
CreateActionBtn("Rejoin Server", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)
CreateActionBtn("Hop Server", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

print("Zenith Compact Elegant Panel loaded successfully.")

