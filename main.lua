--[[
    Project: ZenMegaScript - Advanced Mobile UI & Features
    Environment: Roblox Luau (Delta Executor Compatible)
    Features: Advanced ESP, Camera X-Ray, AirWalk + Noclip, Speed Controller (up to 250),
              TP Farthest, TP Manual Name, Server Hop, Clean 260x260 Navy UI, Smooth "Z" Button, Elastic Animations.
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Hapus UI lama jika ada untuk mencegah duplikasi
if CoreGui:FindFirstChild("ZenMegaScriptUI") then
    CoreGui.ZenMegaScriptUI:Destroy()
end

-- ==========================================
-- 1. UTILITY & STATE VARIABLES
-- ==========================================
local Config = {
    ESP_Enabled = false,
    Skeleton_Enabled = false,
    Distance_Enabled = false,
    Chams_Enabled = false,
    CameraXRay_Enabled = false,
    AirWalk_Enabled = false,
    Noclip_Enabled = false,
    WalkSpeed = 16,
}

local activeHighlights = {}
local activeBillboards = {}
local airWalkPlatform = nil

-- ==========================================
-- 2. GUI CREATION (CLEAN MINI UI & FLOATING BUTTON)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZenMegaScriptUI"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Floating Button ("Z")
local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Name = "FloatingButtonZ"
FloatingBtn.Parent = ScreenGui
FloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
FloatingBtn.Position = UDim2.new(0, 30, 0.5, -30)
FloatingBtn.Size = UDim2.new(0, 50, 0, 50)
FloatingBtn.Font = Enum.Font.GothamBold
FloatingBtn.Text = "Z"
FloatingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingBtn.TextSize = 22

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(1, 0)
BtnCorner.Parent = FloatingBtn

local BtnStroke = Instance.new("UIStroke")
BtnStroke.Color = Color3.fromRGB(56, 189, 248) -- Bright blue border
BtnStroke.Thickness = 2
BtnStroke.Parent = FloatingBtn

local BtnGradient = Instance.new("UIGradient")
BtnGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 41, 59)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 23, 42))
})
BtnGradient.Rotation = 45
BtnGradient.Parent = FloatingBtn

-- Red dot accent on Floating Button
local RedDot = Instance.new("Frame")
RedDot.Name = "RedDotAccent"
RedDot.Parent = FloatingBtn
RedDot.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
RedDot.Position = UDim2.new(0.7, 0, 0.1, 0)
RedDot.Size = UDim2.new(0, 10, 0, 10)
local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1, 0)
DotCorner.Parent = RedDot

-- Main Menu Frame (Clean Mini UI - 260x260)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -130)
MainFrame.Size = UDim2.new(0, 260, 0, 260)
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(51, 65, 85)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 41, 59)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 23, 42))
})
MainGradient.Rotation = 90
MainGradient.Parent = MainFrame

-- Top Bar / Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Parent = MainFrame
Header.BackgroundTransparency = 1
Header.Size = UDim2.new(1, 0, 0, 35)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = Header
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.Size = UDim2.new(0, 180, 1, 0)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "ZenMegaScript UI"
TitleLabel.TextColor3 = Color3.fromRGB(248, 250, 252)
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize / Close Button (-)
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeButton"
MinimizeBtn.Parent = Header
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
MinimizeBtn.Position = UDim2.new(1, -30, 0.5, -10)
MinimizeBtn.Size = UDim2.new(0, 20, 0, 20)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 14

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinimizeBtn

-- Content Scroll Area inside 260x260 UI
local ScrollContainer = Instance.new("ScrollingFrame")
ScrollContainer.Parent = MainFrame
ScrollContainer.BackgroundTransparency = 1
ScrollContainer.Position = UDim2.new(0, 10, 0, 40)
ScrollContainer.Size = UDim2.new(1, -20, 1, -50)
ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, 450)
ScrollContainer.ScrollBarThickness = 4

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollContainer
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)

-- ==========================================
-- 3. UI BUILDER HELPER FUNCTIONS
-- ==========================================
local function createButton(name, text, callback)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Parent = ScrollContainer
    btn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(226, 232, 240)
    btn.TextSize = 12
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(71, 85, 105)
    stroke.Thickness = 1
    stroke.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createToggle(name, text, initialState, callback)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Parent = ScrollContainer
    frame.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    frame.Size = UDim2.new(1, 0, 0, 32)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Size = UDim2.new(0, 160, 1, 0)
    label.Font = Enum.Font.GothamMedium
    label.Text = text
    label.TextColor3 = Color3.fromRGB(226, 232, 240)
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local tglBtn = Instance.new("TextButton")
    tglBtn.Parent = frame
    tglBtn.BackgroundColor3 = initialState and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(100, 116, 139)
    tglBtn.Position = UDim2.new(1, -45, 0.5, -10)
    tglBtn.Size = UDim2.new(0, 36, 0, 20)
    tglBtn.Text = initialState and "ON" or "OFF"
    tglBtn.Font = Enum.Font.GothamBold
    tglBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tglBtn.TextSize = 9
    
    local tglCorner = Instance.new("UICorner")
    tglCorner.CornerRadius = UDim.new(1, 0)
    tglCorner.Parent = tglBtn
    
    local state = initialState
    tglBtn.MouseButton1Click:Connect(function()
        state = not state
        tglBtn.BackgroundColor3 = state and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(100, 116, 139)
        tglBtn.Text = state and "ON" or "OFF"
        callback(state)
    end)
    return frame
end

-- Section headers
local function createSectionLabel(text)
    local lbl = Instance.new("TextLabel")
    lbl.Parent = ScrollContainer
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(56, 189, 248)
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
end

-- ==========================================
-- 4. IMPLEMENTING FEATURES & CONTROLS
-- ==========================================

createSectionLabel("--- VISUALS ---")
createToggle("ToggleChams", "ESP Chams Ringan", false, function(state)
    Config.Chams_Enabled = state
end)
createToggle("ToggleDistance", "ESP Jarak (Meter)", false, function(state)
    Config.Distance_Enabled = state
end)
createToggle("ToggleCameraXRay", "Camera X-Ray (No Occlusion)", false, function(state)
    Config.CameraXRay_Enabled = state
    if state then
        LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
    else
        LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
    end
end)

createSectionLabel("--- ACTIONS & MOVEMENT ---")
createToggle("ToggleAirWalkNoclip", "Air Walk + Noclip", false, function(state)
    Config.AirWalk_Enabled = state
    Config.Noclip_Enabled = state
    if not state and airWalkPlatform then
        airWalkPlatform:Destroy()
        airWalkPlatform = nil
    end
end)

-- Speed Controller with [+] and [-] buttons up to 250
local speedFrame = Instance.new("Frame")
speedFrame.Parent = ScrollContainer
speedFrame.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
speedFrame.Size = UDim2.new(1, 0, 0, 32)
local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 6)
speedCorner.Parent = speedFrame

local speedLabel = Instance.new("TextLabel")
speedLabel.Parent = speedFrame
speedLabel.BackgroundTransparency = 1
speedLabel.Position = UDim2.new(0, 10, 0, 0)
speedLabel.Size = UDim2.new(0, 130, 1, 0)
speedLabel.Font = Enum.Font.GothamMedium
speedLabel.Text = "Speed: 16"
speedLabel.TextColor3 = Color3.fromRGB(226, 232, 240)
speedLabel.TextSize = 11
speedLabel.TextXAlignment = Enum.TextXAlignment.Left

local minusBtn = Instance.new("TextButton")
minusBtn.Parent = speedFrame
minusBtn.BackgroundColor3 = Color3.fromRGB(71, 85, 105)
minusBtn.Position = UDim2.new(1, -65, 0.5, -10)
minusBtn.Size = UDim2.new(0, 26, 0, 20)
minusBtn.Text = "-"
minusBtn.Font = Enum.Font.GothamBold
minusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minusBtn.TextSize = 12
Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 4)

local plusBtn = Instance.new("TextButton")
plusBtn.Parent = speedFrame
plusBtn.BackgroundColor3 = Color3.fromRGB(71, 85, 105)
plusBtn.Position = UDim2.new(1, -35, 0.5, -10)
plusBtn.Size = UDim2.new(0, 26, 0, 20)
plusBtn.Text = "+"
plusBtn.Font = Enum.Font.GothamBold
plusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
plusBtn.TextSize = 12
Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 4)

minusBtn.MouseButton1Click:Connect(function()
    Config.WalkSpeed = math.clamp(Config.WalkSpeed - 5, 16, 250)
    speedLabel.Text = "Speed: " .. Config.WalkSpeed
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = Config.WalkSpeed
    end
end)

plusBtn.MouseButton1Click:Connect(function()
    Config.WalkSpeed = math.clamp(Config.WalkSpeed + 5, 16, 250)
    speedLabel.Text = "Speed: " .. Config.WalkSpeed
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = Config.WalkSpeed
    end
end)

createButton("TPFarthest", "TP Player Terjauh", function()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local myPos = char.HumanoidRootPart.Position
    local farthestPlayer = nil
    local maxDist = 0
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (myPos - plr.Character.HumanoidRootPart.Position).Magnitude
            if dist > maxDist then
                maxDist = dist
                farthestPlayer = plr
            end
        end
    end
    
    if farthestPlayer and farthestPlayer.Character and farthestPlayer.Character:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = farthestPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
    end
end)

-- TP Manual Name (TextBox + Button)
local tpManualFrame = Instance.new("Frame")
tpManualFrame.Parent = ScrollContainer
tpManualFrame.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
tpManualFrame.Size = UDim2.new(1, 0, 0, 32)
Instance.new("UICorner", tpManualFrame).CornerRadius = UDim.new(0, 6)

local tpTextBox = Instance.new("TextBox")
tpTextBox.Parent = tpManualFrame
tpTextBox.BackgroundTransparency = 1
tpTextBox.Position = UDim2.new(0, 8, 0, 0)
tpTextBox.Size = UDim2.new(0, 160, 1, 0)
tpTextBox.Font = Enum.Font.GothamMedium
tpTextBox.PlaceholderText = "Ketik Nama Player..."
tpTextBox.Text = ""
tpTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
tpTextBox.TextSize = 11
tpTextBox.TextXAlignment = Enum.TextXAlignment.Left

local tpGoBtn = Instance.new("TextButton")
tpGoBtn.Parent = tpManualFrame
tpGoBtn.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
tpGoBtn.Position = UDim2.new(1, -65, 0.5, -11)
tpGoBtn.Size = UDim2.new(0, 58, 0, 22)
tpGoBtn.Font = Enum.Font.GothamBold
tpGoBtn.Text = "TP"
tpGoBtn.TextColor3 = Color3.fromRGB(15, 23, 42)
tpGoBtn.TextSize = 11
Instance.new("UICorner", tpGoBtn).CornerRadius = UDim.new(0, 4)

tpGoBtn.MouseButton1Click:Connect(function()
    local query = string.lower(tpTextBox.Text)
    if query == "" then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if string.sub(string.lower(plr.Name), 1, #query) == query or string.sub(string.lower(plr.DisplayName), 1, #query) == query then
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                break
            end
        end
    end
end)

createButton("HopServer", "Hop Full Server", function()
    local servers = {}
    local success, err = pcall(function()
        servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")).data
    end)
    if success and servers then
        for _, srv in ipairs(servers) do
            if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                break
            end
        end
    end
end)

-- ==========================================
-- 5. RUNTIME LOOPS (ESP, Noclip, AirWalk)
-- ==========================================
RunService.RenderStepped:Connect(function()
    -- Noclip logic
    if Config.Noclip_Enabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    
    -- AirWalk logic
    if Config.AirWalk_Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        if not airWalkPlatform then
            airWalkPlatform = Instance.new("Part")
            airWalkPlatform.Name = "AirWalkPlatform"
            airWalkPlatform.Size = Vector3.new(3, 0.2, 3)
            airWalkPlatform.Transparency = 0.5
            airWalkPlatform.Anchored = true
            airWalkPlatform.CanCollide = true
            airWalkPlatform.Parent = workspace
        end
        airWalkPlatform.CFrame = hrp.CFrame - Vector3.new(0, 3.5, 0)
    elseif airWalkPlatform then
        airWalkPlatform:Destroy()
        airWalkPlatform = nil
    end
    
    -- Chams & Distance ESP logic
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local char = plr.Character
            -- Chams
            if Config.Chams_Enabled then
                if not activeHighlights[plr] then
                    local hl = Instance.new("Highlight")
                    hl.Name = "ZenChams"
                    hl.Adornee = char
                    hl.FillColor = Color3.fromRGB(239, 68, 68)
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.Parent = char
                    activeHighlights[plr] = hl
                end
            else
                if activeHighlights[plr] then
                    activeHighlights[plr]:Destroy()
                    activeHighlights[plr] = nil
                end
            end
        end
    end
end)

-- ==========================================
-- 6. ANIMASI & TRANSISI ELASTIC/BACK
-- ==========================================
local isOpen = false

local function toggleUI()
    isOpen = not isOpen
    if isOpen then
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        MainFrame.Position = FloatingBtn.Position
        
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        local tween = TweenService:Create(MainFrame, tweenInfo, {
            Size = UDim2.new(0, 260, 0, 260),
            Position = UDim2.new(0.5, -130, 0.5, -130)
        })
        tween:Play()
    else
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        local tween = TweenService:Create(MainFrame, tweenInfo, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = FloatingBtn.Position
        })
        tween:Play()
        tween.Completed:Connect(function()
            if not isOpen then
                MainFrame.Visible = false
            end
        end)
    end
end

FloatingBtn.MouseButton1Click:Connect(toggleUI)
MinimizeBtn.MouseButton1Click:Connect(toggleUI)

-- Smooth Draggable Floating Button ("Z") logic for mobile/PC
local dragging, dragInput, dragStart, startPos
FloatingBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = FloatingBtn.Position
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
        FloatingBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

print("ZenMegaScript successfully loaded!")

