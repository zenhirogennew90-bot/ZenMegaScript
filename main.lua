-- ===================================================================
-- ZENITH & ZEN HUB - ALL-IN-ONE HYBRID SCRIPT (LUAU)
-- Safe, Optimized, Mobile Friendly UI & Smooth Performance
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
    AirWalkHeight = 0,
    HoldingUp = false,
    HoldingDown = false,
    Noclip = false,
    BypassCamera = false,
    WalkspeedToggle = false,
    WalkspeedValue = 16,
    AttachFront = false,
    
    -- Target State
    TargetPlayer = nil,
    
    -- Lighting Backup
    OriginalAmbient = Lighting.Ambient,
    OriginalOutdoorAmbient = Lighting.OutdoorAmbient,
    OriginalBrightness = Lighting.Brightness,
    OriginalClockTime = Lighting.ClockTime,
    OriginalFogEnd = Lighting.FogEnd
}

-- Target Storage for Visual Elements
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

-- ESP Box, Name & Line Manager
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
    box.Thickness = 1.5
    box.Filled = false
    box.Color = Color3.fromRGB(0, 255, 150)
    box.Visible = false

    local name = Drawing.new("Text")
    name.Text = player.DisplayName or player.Name
    name.Size = 14
    name.Center = true
    name.Outline = true
    name.Color = Color3.fromRGB(255, 255, 255)
    name.Visible = false

    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Color = Color3.fromRGB(0, 255, 150)
    line.Visible = false

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

                -- Box ESP
                if State.ESPBox then
                    drawings.Box.Size = Vector2.new(width, height)
                    drawings.Box.Position = Vector2.new(pos.X - width / 2, pos.Y - height / 2)
                    drawings.Box.Visible = true
                else
                    drawings.Box.Visible = false
                end

                -- Name ESP
                if State.ESPName then
                    drawings.Name.Position = Vector2.new(pos.X, pos.Y - height / 2 - 16)
                    drawings.Name.Text = string.format("%s [%dM]", player.DisplayName, math.floor((root.Position - GetRoot(LocalPlayer).Position).Magnitude))
                    drawings.Name.Visible = true
                else
                    drawings.Name.Visible = false
                end

                -- Line ESP
                if State.ESPLine then
                    drawings.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    drawings.Line.To = Vector2.new(pos.X, pos.Y)
                    drawings.Line.Visible = true
                else
                    drawings.Line.Visible = false
                end
            else
                drawings.Box.Visible = false
                drawings.Name.Visible = false
                drawings.Line.Visible = false
            end
        else
            drawings.Box.Visible = false
            drawings.Name.Visible = false
            drawings.Line.Visible = false
        end
    end
end

-- ESP Chams
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
            highlight.FillTransparency = 0.4
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = ChamsFolder
        end
    end
end

-- Fullbright
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

-- Camera X-Ray & Bypass Lock
local function UpdateCameraSystem()
    if State.CameraXRay or State.BypassCamera then
        LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
        LocalPlayer.CameraMinZoomDistance = 0.5
        LocalPlayer.CameraMaxZoomDistance = 400
    else
        LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
    end
end

-- Spectate Target
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
-- ACTION FEATURES IMPLEMENTATION
-- -------------------------------------------------------------------

-- Air Walk Engine
local AirWalkPlatform = Instance.new("Part")
AirWalkPlatform.Size = Vector3.new(8, 1, 8)
AirWalkPlatform.Anchored = true
AirWalkPlatform.Transparency = 1
AirWalkPlatform.CanCollide = false
AirWalkPlatform.Name = "ZenAirWalkPlatform"
AirWalkPlatform.Parent = workspace

local function UpdateAirWalk()
    local root = GetRoot(LocalPlayer)
    if State.AirWalk and root then
        if State.AirWalkHeight == 0 then
            State.AirWalkHeight = root.Position.Y - 3.2
        end

        if State.HoldingUp then
            State.AirWalkHeight = State.AirWalkHeight + 0.5
        elseif State.HoldingDown then
            State.AirWalkHeight = State.AirWalkHeight - 0.5
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

-- Attach Front Engine
local function UpdateAttachFront()
    if State.AttachFront and State.TargetPlayer then
        local targetRoot = GetRoot(State.TargetPlayer)
        local myRoot = GetRoot(LocalPlayer)
        if targetRoot and myRoot then
            myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -3)
        end
    end
end

-- Teleport Options
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
        TeleportToPlayer(randomPlayer)
    end
end

-- Auto Select Player
local function AutoSelectNearestPlayer()
    local myRoot = GetRoot(LocalPlayer)
    if not myRoot then return end
    
    local nearest = nil
    local shortestDist = math.huge
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and GetRoot(p) then
            local dist = (GetRoot(p).Position - myRoot.Position).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                nearest = p
            end
        end
    end
    
    State.TargetPlayer = nearest
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
    
    -- Walkspeed Enforcer
    local hum = GetHumanoid(LocalPlayer)
    if hum then
        if State.WalkspeedToggle then
            hum.WalkSpeed = State.WalkspeedValue
        end
    end
end)

-- Setup Player Listeners for ESP
for _, p in pairs(Players:GetPlayers()) do
    CreateESP(p)
end
Players.PlayerAdded:Connect(function(p)
    CreateESP(p)
    if State.ESPChams then UpdateChams() end
end)
Players.PlayerRemoving:Connect(function(p)
    ClearESP(p)
    if State.TargetPlayer == p then State.TargetPlayer = nil end
end)

-- -------------------------------------------------------------------
-- MOBILE FLOATING UI GUI IMPLEMENTATION
-- -------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZenithHybridGui"
ScreenGui.ResetOnSpawn = false

-- Fallback Safe Parenting for Delta & Mobile Executors
if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = CoreGui
end

-- Main Floating Panel Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainPanel"
MainFrame.Size = UDim2.new(0, 310, 0, 420)
MainFrame.Position = UDim2.new(0.5, -155, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(90, 80, 220)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- Title Bar
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 40)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Text = "ZENITH • HYBRID v3.7"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = MainFrame

-- Minimize / Close Button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 26, 0, 26)
ToggleBtn.Position = UDim2.new(1, -33, 0, 7)
ToggleBtn.Text = "X"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = ToggleBtn

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Container ScrollFrame
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -50)
Scroll.Position = UDim2.new(0, 10, 0, 45)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(90, 80, 220)
Scroll.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.Parent = Scroll

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 15)
end)

-- Helper Functions UI Generator
local function CreateSectionHeader(title)
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -10, 0, 24)
    header.Text = "  --- " .. string.upper(title) .. " ---"
    header.TextColor3 = Color3.fromRGB(150, 150, 200)
    header.TextSize = 11
    header.Font = Enum.Font.GothamBold
    header.BackgroundTransparency = 1
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = Scroll
end

local function CreateToggle(text, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.Parent = Scroll
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local currentState = defaultState
    local function updateText()
        btn.Text = text .. ": " .. (currentState and "ON 🟢" or "OFF 🔴")
        btn.TextColor3 = currentState and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(200, 200, 200)
    end
    updateText()

    btn.MouseButton1Click:Connect(function()
        currentState = not currentState
        updateText()
        pcall(callback, currentState)
    end)
end

local function CreateButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(38, 38, 52)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(240, 240, 240)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.Parent = Scroll

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        pcall(callback)
    end)
end

-- -------------------------------------------------------------------
-- UI MENU BUILDER
-- -------------------------------------------------------------------

-- VISUAL SECTION
CreateSectionHeader("Fitur Visual")

CreateToggle("ESP Box", State.ESPBox, function(v) State.ESPBox = v end)
CreateToggle("ESP Name", State.ESPName, function(v) State.ESPName = v end)
CreateToggle("ESP Line", State.ESPLine, function(v) State.ESPLine = v end)
CreateToggle("ESP Chams", State.ESPChams, function(v) State.ESPChams = v; UpdateChams() end)
CreateToggle("Fullbright (Cerahkan)", State.Fullbright, function(v) ToggleFullbright(v) end)
CreateToggle("Camera X-Ray", State.CameraXRay, function(v) State.CameraXRay = v end)
CreateToggle("Spectate Target", State.Spectate, function(v) State.Spectate = v end)

-- ACTION SECTION
CreateSectionHeader("Fitur Aksi")

CreateToggle("Air Walk", State.AirWalk, function(v) State.AirWalk = v end)

local holdUpBtn = Instance.new("TextButton")
holdUpBtn.Size = UDim2.new(1, -10, 0, 34)
holdUpBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
holdUpBtn.Text = "Naik (Tahan) ⬆️"
holdUpBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
holdUpBtn.Font = Enum.Font.GothamSemibold
holdUpBtn.TextSize = 12
holdUpBtn.Parent = Scroll
local c1 = Instance.new("UICorner") c1.CornerRadius = UDim.new(0, 6) c1.Parent = holdUpBtn

holdUpBtn.MouseButton1Down:Connect(function() State.HoldingUp = true end)
holdUpBtn.MouseButton1Up:Connect(function() State.HoldingUp = false end)

local holdDownBtn = Instance.new("TextButton")
holdDownBtn.Size = UDim2.new(1, -10, 0, 34)
holdDownBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
holdDownBtn.Text = "Turun (Tahan) ⬇️"
holdDownBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
holdDownBtn.Font = Enum.Font.GothamSemibold
holdDownBtn.TextSize = 12
holdDownBtn.Parent = Scroll
local c2 = Instance.new("UICorner") c2.CornerRadius = UDim.new(0, 6) c2.Parent = holdDownBtn

holdDownBtn.MouseButton1Down:Connect(function() State.HoldingDown = true end)
holdDownBtn.MouseButton1Up:Connect(function() State.HoldingDown = false end)

CreateToggle("Noclip (Tembus Dinding)", State.Noclip, function(v) State.Noclip = v end)
CreateToggle("Bebas Kamera (Bypass)", State.BypassCamera, function(v) State.BypassCamera = v end)

CreateToggle("Walkspeed (100 Speed)", State.WalkspeedToggle, function(v)
    State.WalkspeedToggle = v
    State.WalkspeedValue = v and 100 or 16
    local hum = GetHumanoid(LocalPlayer)
    if hum then hum.WalkSpeed = State.WalkspeedValue end
end)

CreateButton("Target: Auto Select Player 🔄", function()
    AutoSelectNearestPlayer()
    if State.TargetPlayer then
        print("Target dipilih: " .. State.TargetPlayer.Name)
    end
end)

CreateButton("Teleport to Target 🚀", function()
    if State.TargetPlayer then
        TeleportToPlayer(State.TargetPlayer)
    end
end)

CreateButton("Teleport Random Player 🎲", function()
    TeleportRandom()
end)

CreateToggle("Attach Front 🔗", State.AttachFront, function(v) State.AttachFront = v end)

CreateButton("Rejoin Server 🔄", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

CreateButton("Hop Full Server 🚀", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

print("ZENITH Hybrid Script loaded successfully!")
