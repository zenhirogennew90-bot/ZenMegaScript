-- ===================================================================
-- ZENITH & ZEN HUB - UPDATED HYBRID SCRIPT (LUAU)
-- With RGB Rainbow Panel & Soft Button Click Sounds
-- ===================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- -------------------------------------------------------------------
-- SOUND EFFECTS (SOFT CLICK)
-- -------------------------------------------------------------------
local ClickSound = Instance.new("Sound")
ClickSound.Name = "ZenClickSound"
ClickSound.SoundId = "rbxassetid://6895079853" -- Soft Bubble / UI Click Sound
ClickSound.Volume = 0.5
ClickSound.Parent = SoundService

local function PlayClickSound()
    pcall(function()
        if ClickSound.IsPlaying then
            ClickSound:Stop()
        end
        ClickSound:Play()
    end)
end

-- -------------------------------------------------------------------
-- STATE MANAGEMENT
-- -------------------------------------------------------------------
local State = {
    -- Visual State
    ESPBox = false,
    ESPName = false,
    ESPLine = false,
    ESPChams = false,
    Fullbright = false,
    CameraXRay = false,
    Spectate = false,
    
    -- Action State
    AirWalk = false,
    Noclip = false,
    BypassCamera = false,
    WalkspeedToggle = false,
    WalkspeedValue = 32,
    
    -- Target & Search State
    SpectateTarget = nil,
    SearchQuery = ""
}

local ESPStorage = {}
local ChamsFolder = Instance.new("Folder")
ChamsFolder.Name = "ZenChamsFolder"
ChamsFolder.Parent = CoreGui

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
            if obj and obj.Destroy then obj:Destroy() end
        end
        ESPStorage[player] = nil
    end
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    ClearESP(player)

    local box = Drawing.new("Square")
    box.Thickness = 1.5; box.Filled = false; box.Color = Color3.fromRGB(0, 255, 150); box.Visible = false

    local name = Drawing.new("Text")
    name.Size = 14; name.Center = true; name.Outline = true; name.Color = Color3.fromRGB(255, 255, 255); name.Visible = false

    local line = Drawing.new("Line")
    line.Thickness = 1; line.Color = Color3.fromRGB(0, 255, 150); line.Visible = false

    ESPStorage[player] = {Box = box, Name = name, Line = line}
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
                else drawings.Box.Visible = false end

                if State.ESPName then
                    drawings.Name.Position = Vector2.new(pos.X, pos.Y - height / 2 - 16)
                    drawings.Name.Text = string.format("%s [%dM]", player.DisplayName, math.floor((root.Position - GetRoot(LocalPlayer).Position).Magnitude))
                    drawings.Name.Visible = true
                else drawings.Name.Visible = false end

                if State.ESPLine then
                    drawings.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    drawings.Line.To = Vector2.new(pos.X, pos.Y)
                    drawings.Line.Visible = true
                else drawings.Line.Visible = false end
            else
                drawings.Box.Visible = false; drawings.Name.Visible = false; drawings.Line.Visible = false
            end
        else
            drawings.Box.Visible = false; drawings.Name.Visible = false; drawings.Line.Visible = false
        end
    end
end

local function UpdateChams()
    ChamsFolder:ClearAllChildren()
    if not State.ESPChams then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and GetCharacter(player) then
            local highlight = Instance.new("Highlight")
            highlight.Name = player.Name .. "_Chams"
            highlight.Adornee = GetCharacter(player)
            highlight.FillColor = Color3.fromRGB(255, 0, 100)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.4; highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = ChamsFolder
        end
    end
end

local function ToggleFullbright(value)
    State.Fullbright = value
    if value then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 100000
    else
        Lighting.Ambient = Lighting.Ambient
        Lighting.Brightness = 1
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
-- ACTION FEATURES (AIRWALK WITH ANIMATION & SPECTATE TP)
-- -------------------------------------------------------------------
local AirWalkPlatform = Instance.new("Part")
AirWalkPlatform.Size = Vector3.new(6, 1, 6)
AirWalkPlatform.Anchored = true
AirWalkPlatform.Transparency = 1
AirWalkPlatform.CanCollide = false
AirWalkPlatform.Parent = workspace

local function UpdateAirWalk()
    local root = GetRoot(LocalPlayer)
    local hum = GetHumanoid(LocalPlayer)
    if State.AirWalk and root and hum then
        AirWalkPlatform.CFrame = CFrame.new(root.Position.X, root.Position.Y - 3.2, root.Position.Z)
        AirWalkPlatform.CanCollide = true
        
        if hum.MoveDirection.Magnitude > 0 then
            AirWalkPlatform.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
    else
        AirWalkPlatform.CanCollide = false
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

-- -------------------------------------------------------------------
-- GUI & INTERFACE CREATION
-- -------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZenithHybridGui"
ScreenGui.ResetOnSpawn = false

if gethui then ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then syn.protect_gui(ScreenGui); ScreenGui.Parent = CoreGui
else ScreenGui.Parent = CoreGui end

-- Center Floating Teleport Button
local CenterTPBtn = Instance.new("TextButton")
CenterTPBtn.Size = UDim2.new(0, 180, 0, 40)
CenterTPBtn.Position = UDim2.new(0.5, -90, 0.85, 0)
CenterTPBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CenterTPBtn.Text = "⚡ TELEPORT KE TARGET"
CenterTPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CenterTPBtn.Font = Enum.Font.GothamBold
CenterTPBtn.TextSize = 13
CenterTPBtn.Visible = false
CenterTPBtn.Parent = ScreenGui

local ctpCorner = Instance.new("UICorner") ctpCorner.CornerRadius = UDim.new(0, 8) ctpCorner.Parent = CenterTPBtn
local ctpStroke = Instance.new("UIStroke") ctpStroke.Thickness = 2; ctpStroke.Parent = CenterTPBtn

CenterTPBtn.MouseButton1Click:Connect(function()
    PlayClickSound()
    if State.SpectateTarget and GetRoot(State.SpectateTarget) and GetRoot(LocalPlayer) then
        GetRoot(LocalPlayer).CFrame = GetRoot(State.SpectateTarget).CFrame * CFrame.new(0, 3, 0)
    end
end)

-- Main Floating Panel
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 310, 0, 440)
MainFrame.Position = UDim2.new(0.5, -155, 0.5, -220)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.Active = true; MainFrame.Draggable = true; MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner") UICorner.CornerRadius = UDim.new(0, 10) UICorner.Parent = MainFrame

-- RGB Border Stroke
local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2
UIStroke.Parent = MainFrame

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 40); Title.Position = UDim2.new(0, 15, 0, 0)
Title.Text = "ZENITH • MEGASHCRIPT v3.8"
Title.TextColor3 = Color3.fromRGB(255, 255, 255); Title.TextSize = 15; Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left; Title.BackgroundTransparency = 1; Title.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 26, 0, 26); ToggleBtn.Position = UDim2.new(1, -33, 0, 7)
ToggleBtn.Text = "X"; ToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40); ToggleBtn.Font = Enum.Font.GothamBold; ToggleBtn.TextSize = 12
ToggleBtn.Parent = MainFrame
local BtnCorner = Instance.new("UICorner") BtnCorner.CornerRadius = UDim.new(0, 6) BtnCorner.Parent = ToggleBtn

ToggleBtn.MouseButton1Click:Connect(function()
    PlayClickSound()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Scroll Area
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -50); Scroll.Position = UDim2.new(0, 10, 0, 45)
Scroll.BackgroundTransparency = 1; Scroll.ScrollBarThickness = 3; Scroll.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder; UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.Parent = Scroll

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 15)
end)

local function CreateSectionHeader(text)
    local h = Instance.new("TextLabel")
    h.Size = UDim2.new(1, -10, 0, 24); h.Text = "  --- " .. string.upper(text) .. " ---"
    h.TextColor3 = Color3.fromRGB(150, 150, 200); h.TextSize = 11; h.Font = Enum.Font.GothamBold
    h.BackgroundTransparency = 1; h.TextXAlignment = Enum.TextXAlignment.Left; h.Parent = Scroll
end

local function CreateToggle(text, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 34); btn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 12; btn.Parent = Scroll
    local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 6); corner.Parent = btn

    local currentState = defaultState
    local function update()
        btn.Text = text .. ": " .. (currentState and "ON 🟢" or "OFF 🔴")
        btn.TextColor3 = currentState and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(200, 200, 200)
    end
    update()
    btn.MouseButton1Click:Connect(function()
        PlayClickSound()
        currentState = not currentState; update(); pcall(callback, currentState)
    end)
end

local function CreateButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 34); btn.BackgroundColor3 = Color3.fromRGB(38, 38, 52)
    btn.Text = text; btn.TextColor3 = Color3.fromRGB(240, 240, 240); btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 12; btn.Parent = Scroll
    local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 6); corner.Parent = btn
    btn.MouseButton1Click:Connect(function()
        PlayClickSound()
        pcall(callback)
    end)
end

-- -------------------------------------------------------------------
-- BUILD MENU INTERFACE
-- -------------------------------------------------------------------
CreateSectionHeader("Fitur Visual")
CreateToggle("ESP Box", State.ESPBox, function(v) State.ESPBox = v end)
CreateToggle("ESP Name", State.ESPName, function(v) State.ESPName = v end)
CreateToggle("ESP Line", State.ESPLine, function(v) State.ESPLine = v end)
CreateToggle("ESP Chams", State.ESPChams, function(v) State.ESPChams = v; UpdateChams() end)
CreateToggle("Fullbright", State.Fullbright, function(v) ToggleFullbright(v) end)
CreateToggle("Camera X-Ray", State.CameraXRay, function(v) State.CameraXRay = v end)

CreateSectionHeader("Fitur Aksi")
CreateToggle("Air Walk (Animasi Aktif)", State.AirWalk, function(v) State.AirWalk = v end)
CreateToggle("Noclip (Tembus Dinding)", State.Noclip, function(v) State.Noclip = v end)
CreateToggle("Bebas Kamera", State.BypassCamera, function(v) State.BypassCamera = v end)

CreateToggle("Walkspeed Custom", State.WalkspeedToggle, function(v)
    State.WalkspeedToggle = v
end)

-- TextBox Kecepatan Walkspeed
local SpeedBox = Instance.new("TextBox")
SpeedBox.Size = UDim2.new(1, -10, 0, 34); SpeedBox.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
SpeedBox.Text = "Atur Kecepatan (Default: 32)"; SpeedBox.TextColor3 = Color3.fromRGB(200, 200, 200)
SpeedBox.Font = Enum.Font.GothamSemibold; SpeedBox.TextSize = 12; SpeedBox.Parent = Scroll
local sc = Instance.new("UICorner") sc.CornerRadius = UDim.new(0, 6); sc.Parent = SpeedBox

SpeedBox.FocusLost:Connect(function()
    PlayClickSound()
    local num = tonumber(SpeedBox.Text)
    if num then State.WalkspeedValue = num; SpeedBox.Text = "Speed diset ke: " .. num
    else SpeedBox.Text = "Masukkan angka valid!" end
end)

CreateSectionHeader("Spectate & Teleport Player")

-- Input Search Player untuk Spectate
local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -10, 0, 34); SearchBox.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
SearchBox.Text = "Ketik Nama Player untuk Spectate"; SearchBox.TextColor3 = Color3.fromRGB(200, 200, 200)
SearchBox.Font = Enum.Font.GothamSemibold; SearchBox.TextSize = 12; SearchBox.Parent = Scroll
local sbc = Instance.new("UICorner") sbc.CornerRadius = UDim.new(0, 6); sbc.Parent = SearchBox

SearchBox.FocusLost:Connect(function()
    PlayClickSound()
    local query = string.lower(SearchBox.Text)
    local found = nil
    for _, p in pairs(Players:GetPlayers()) do
        if string.find(string.lower(p.Name), query) or string.find(string.lower(p.DisplayName), query) then
            found = p
            break
        end
    end
    if found then
        State.SpectateTarget = found
        SearchBox.Text = "Target: " .. found.Name
    else
        SearchBox.Text = "Player Tidak Ditemukan!"
    end
end)

CreateToggle("Aktifkan Spectate Target", State.Spectate, function(v)
    State.Spectate = v
    CenterTPBtn.Visible = v
    if not v then
        State.SpectateTarget = nil
        Camera.CameraSubject = GetHumanoid(LocalPlayer)
    end
end)

CreateButton("Rejoin Server", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

CreateButton("Hop Server Lain", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

-- -------------------------------------------------------------------
-- MAIN LOOP & RGB ANIMATION ENGINE
-- -------------------------------------------------------------------
local hue = 0
RunService.RenderStepped:Connect(function(deltaTime)
    -- RGB Rainbow Color Animation
    hue = (hue + deltaTime * 0.2) % 1
    local rgbColor = Color3.fromHSV(hue, 0.8, 1)
    
    UIStroke.Color = rgbColor
    Title.TextColor3 = rgbColor
    ctpStroke.Color = rgbColor
    Scroll.ScrollBarImageColor3 = rgbColor

    -- Updates
    UpdateESP()
    UpdateAirWalk()
    UpdateCameraSystem()
    
    -- Update Spectate Logic
    if State.Spectate and State.SpectateTarget and GetHumanoid(State.SpectateTarget) then
        Camera.CameraSubject = GetHumanoid(State.SpectateTarget)
    end
    
    -- Walkspeed Enforcer
    local hum = GetHumanoid(LocalPlayer)
    if hum and State.WalkspeedToggle then
        hum.WalkSpeed = State.WalkspeedValue
    end
end)

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(function(p) CreateESP(p) end)
Players.PlayerRemoving:Connect(function(p) 
    ClearESP(p) 
    if State.SpectateTarget == p then State.SpectateTarget = nil end 
end)

print("ZENITH MegaScript Updated with RGB & Audio Feedback!")
