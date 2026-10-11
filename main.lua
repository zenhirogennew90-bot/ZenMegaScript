-- ===================================================================
-- ZENITH • ULTRALIGHT v4.3 - GUARANTEED UI EDITION (LUAU)
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

-- State
local State = {
    ESPBox = false, ESPLine = false, Fullbright = false, CameraXRay = false,
    AirWalk = false, AirWalkHeight = 0, Fly = false, FlySpeed = 50,
    Noclip = false, BypassCamera = false, WalkspeedToggle = false, WalkspeedValue = 16,
    OrigAmbient = Lighting.Ambient, OrigOutAmbient = Lighting.OutdoorAmbient,
    OrigBright = Lighting.Brightness, OrigClock = Lighting.ClockTime, OrigFog = Lighting.FogEnd
}

local ESPStorage = {}

local function PlayClickSound()
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://9114220405"
        s.Volume = 0.3
        s.Parent = SoundService
        s:Play()
        s.Ended:Connect(function() s:Destroy() end)
    end)
end

local function GetRoot(p)
    local char = p and p.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid(p)
    local char = p and p.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- Reset State on Spawn
LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    task.wait(0.5)
    State.AirWalkHeight = 0
    State.Fly = false
    local hum = GetHumanoid(LocalPlayer)
    if hum and not State.WalkspeedToggle then hum.WalkSpeed = 16 end
end)

-- ESP & Visuals
local function ClearESP(p)
    if ESPStorage[p] then
        for _, obj in pairs(ESPStorage[p]) do if obj and obj.Destroy then obj:Destroy() end end
        ESPStorage[p] = nil
    end
end

local function CreateESP(p)
    if p == LocalPlayer then return end
    ClearESP(p)
    local box = Drawing.new("Square")
    box.Thickness = 1.2; box.Filled = false; box.Color = Color3.fromRGB(120, 100, 255); box.Visible = false
    local line = Drawing.new("Line")
    line.Thickness = 1; line.Color = Color3.fromRGB(120, 100, 255); line.Visible = false
    ESPStorage[p] = {Box = box, Line = line}
end

for _, p in ipairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(ClearESP)

RunService.RenderStepped:Connect(function()
    for p, d in pairs(ESPStorage) do
        local root = GetRoot(p)
        local hum = GetHumanoid(p)
        if root and hum and hum.Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local leg = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                local head = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3.5, 0))
                local h = math.abs(head.Y - leg.Y)
                local w = h / 2.2
                if State.ESPBox then
                    d.Box.Size = Vector2.new(w, h)
                    d.Box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2)
                    d.Box.Visible = true
                else d.Box.Visible = false end
                if State.ESPLine then
                    d.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    d.Line.To = Vector2.new(pos.X, pos.Y)
                    d.Line.Visible = true
                else d.Line.Visible = false end
            else d.Box.Visible = false; d.Line.Visible = false end
        else d.Box.Visible = false; d.Line.Visible = false end
    end

    if State.Fullbright then
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 100000
    else
        Lighting.Ambient = State.OrigAmbient
        Lighting.OutdoorAmbient = State.OrigOutAmbient
        Lighting.Brightness = State.OrigBright
        Lighting.ClockTime = State.OrigClock
        Lighting.FogEnd = State.OrigFog
    end

    if State.CameraXRay or State.BypassCamera then
        LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
        LocalPlayer.CameraMaxZoomDistance = 500
    else
        LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
        LocalPlayer.CameraMaxZoomDistance = 128
    end

    local hum = GetHumanoid(LocalPlayer)
    if hum and State.WalkspeedToggle then hum.WalkSpeed = State.WalkspeedValue end
end)

-- Air Walk
local AirPlatform = Instance.new("Part")
AirPlatform.Size = Vector3.new(6, 0.8, 6)
AirPlatform.Anchored = true
AirPlatform.Transparency = 1
AirPlatform.Parent = workspace

RunService.RenderStepped:Connect(function()
    local root = GetRoot(LocalPlayer)
    if State.AirWalk and root then
        if State.AirWalkHeight == 0 then State.AirWalkHeight = root.Position.Y - 3.2 end
        AirPlatform.CFrame = CFrame.new(root.Position.X, State.AirWalkHeight, root.Position.Z)
        AirPlatform.CanCollide = true
    else
        AirPlatform.CanCollide = false
        if root then State.AirWalkHeight = 0 end
    end
end)

-- Fly Engine
local flyBV, flyBG = nil, nil
local function ToggleFly(enabled)
    local root = GetRoot(LocalPlayer)
    local hum = GetHumanoid(LocalPlayer)
    if enabled and root and hum then
        hum.PlatformStand = true
        if flyBV then flyBV:Destroy() end
        if flyBG then flyBG:Destroy() end
        flyBV = Instance.new("BodyVelocity", root)
        flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flyBV.Velocity = Vector3.zero
        flyBG = Instance.new("BodyGyro", root)
        flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        flyBG.CFrame = root.CFrame
    else
        if flyBV then flyBV:Destroy(); flyBV = nil end
        if flyBG then flyBG:Destroy(); flyBG = nil end
        if hum then hum.PlatformStand = false end
    end
end

RunService.RenderStepped:Connect(function()
    local root = GetRoot(LocalPlayer)
    local hum = GetHumanoid(LocalPlayer)
    if State.Fly and root and hum and flyBV and flyBG then
        flyBG.CFrame = Camera.CFrame
        local moveDir = hum.MoveDirection
        local vel = Vector3.zero
        if moveDir.Magnitude > 0.05 then
            local look, right = Camera.CFrame.LookVector, Camera.CFrame.RightVector
            vel = ((look * -moveDir.Z) + (right * moveDir.X)).Unit * State.FlySpeed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or hum.Jump then
            vel = vel + Vector3.new(0, State.FlySpeed * 0.8, 0)
        end
        flyBV.Velocity = vel
    end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if State.Noclip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

-- Teleport Helpers
local function TPToPlayer(target)
    local root = GetRoot(LocalPlayer)
    local tRoot = GetRoot(target)
    if root and tRoot then root.CFrame = tRoot.CFrame * CFrame.new(0, 3, 0) end
end

local function TPFurthest()
    local root = GetRoot(LocalPlayer)
    if not root then return end
    local furthest, maxDist = nil, 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local tRoot = GetRoot(p)
            if tRoot then
                local dist = (tRoot.Position - root.Position).Magnitude
                if dist > maxDist then maxDist = dist; furthest = p end
            end
        end
    end
    if furthest then TPToPlayer(furthest) end
end

-- ===================================================================
-- UI IMPLEMENTATION (SAFE & GUARANTEED VISIBLE)
-- ===================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZenithUI"
ScreenGui.ResetOnSpawn = false

-- Safe Parent Method for Mobile Executors
local success = pcall(function()
    if gethui then
        ScreenGui.Parent = gethui()
    else
        ScreenGui.Parent = CoreGui
    end
end)

if not success or not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 260, 0, 360)
Main.Position = UDim2.new(0.5, -130, 0.5, -180)
Main.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
Main.Active = true; Main.Draggable = true

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(75, 65, 180); stroke.Thickness = 1.2

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, -35, 0, 35); Title.Position = UDim2.new(0, 12, 0, 0)
Title.Text = "ZENITH • ULTRALIGHT"; Title.TextColor3 = Color3.fromRGB(230, 230, 255)
Title.TextSize = 12; Title.Font = Enum.Font.GothamBold; Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left

local Close = Instance.new("TextButton", Main)
Close.Size = UDim2.new(0, 22, 0, 22); Close.Position = UDim2.new(1, -28, 0, 6)
Close.Text = "-"; Close.TextColor3 = Color3.fromRGB(180, 180, 220); Close.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Close.Font = Enum.Font.GothamBold; Close.TextSize = 12
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 4)
Close.MouseButton1Click:Connect(function() PlayClickSound(); Main.Visible = not Main.Visible end)

local Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size = UDim2.new(1, -12, 1, -42); Scroll.Position = UDim2.new(0, 6, 0, 38)
Scroll.BackgroundTransparency = 1; Scroll.ScrollBarThickness = 2

local Layout = Instance.new("UIListLayout", Scroll)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.SortOrder = Enum.SortOrder.LayoutOrder; Layout.Padding = UDim.new(0, 5)

Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 10)
end)

local function AddHeader(txt)
    local l = Instance.new("TextLabel", Scroll)
    l.Size = UDim2.new(1, -6, 0, 20); l.Text = " " .. txt
    l.TextColor3 = Color3.fromRGB(130, 130, 170); l.TextSize = 10; l.Font = Enum.Font.GothamBold
    l.BackgroundTransparency = 1; l.TextXAlignment = Enum.TextXAlignment.Left
end

local function AddToggle(txt, cb)
    local b = Instance.new("TextButton", Scroll)
    b.Size = UDim2.new(1, -6, 0, 28); b.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    b.Font = Enum.Font.GothamSemibold; b.TextSize = 11
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    local val = false
    local function upd()
        b.Text = txt .. " : " .. (val and "ON" or "OFF")
        b.TextColor3 = val and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(180, 180, 180)
    end
    upd()
    b.MouseButton1Click:Connect(function()
        PlayClickSound(); val = not val; upd(); pcall(cb, val)
    end)
end

local function AddButton(txt, cb)
    local b = Instance.new("TextButton", Scroll)
    b.Size = UDim2.new(1, -6, 0, 28); b.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
    b.Text = txt; b.TextColor3 = Color3.fromRGB(220, 220, 240); b.Font = Enum.Font.GothamSemibold; b.TextSize = 11
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    b.MouseButton1Click:Connect(function() PlayClickSound(); pcall(cb) end)
end

local function AddTextBox(ph, cb)
    local bx = Instance.new("TextBox", Scroll)
    bx.Size = UDim2.new(1, -6, 0, 28); bx.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    bx.PlaceholderText = ph; bx.Text = ""; bx.TextColor3 = Color3.fromRGB(240, 240, 240)
    bx.PlaceholderColor3 = Color3.fromRGB(120, 120, 150); bx.Font = Enum.Font.GothamSemibold; bx.TextSize = 11
    Instance.new("UICorner", bx).CornerRadius = UDim.new(0, 5)
    bx.FocusLost:Connect(function(enter)
        if enter then PlayClickSound(); pcall(cb, bx.Text) end
    end)
end

-- Selector Widget (< Name >)
local function AddSelector()
    local f = Instance.new("Frame", Scroll)
    f.Size = UDim2.new(1, -6, 0, 30); f.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)

    local lb = Instance.new("TextButton", f)
    lb.Size = UDim2.new(0, 30, 1, 0); lb.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    lb.Text = "<"; lb.TextColor3 = Color3.fromRGB(255, 255, 255)
    lb.Font = Enum.Font.GothamBold; lb.TextSize = 12
    Instance.new("UICorner", lb).CornerRadius = UDim.new(0, 5)

    local nb = Instance.new("TextButton", f)
    nb.Size = UDim2.new(1, -64, 1, 0); nb.Position = UDim2.new(0, 32, 0, 0)
    nb.BackgroundColor3 = Color3.fromRGB(25, 25, 38); nb.Text = "Pilih Player (TP)"
    nb.TextColor3 = Color3.fromRGB(100, 220, 255); nb.Font = Enum.Font.GothamSemibold; nb.TextSize = 11
    Instance.new("UICorner", nb).CornerRadius = UDim.new(0, 5)

    local rb = Instance.new("TextButton", f)
    rb.Size = UDim2.new(0, 30, 1, 0); rb.Position = UDim2.new(1, -30, 0, 0)
    rb.BackgroundColor3 = Color3.fromRGB(35, 35, 50); rb.Text = ">"
    rb.TextColor3 = Color3.fromRGB(255, 255, 255); rb.Font = Enum.Font.GothamBold; rb.TextSize = 12
    Instance.new("UICorner", rb).CornerRadius = UDim.new(0, 5)

    local idx = 1
    local function getList()
        local t = {}
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(t, p) end end
        return t
    end

    local function update()
        local list = getList()
        if #list == 0 then nb.Text = "Tidak ada player"; return end
        if idx > #list then idx = 1 end
        if idx < 1 then idx = #list end
        nb.Text = list[idx].DisplayName or list[idx].Name
    end

    lb.MouseButton1Click:Connect(function() PlayClickSound(); idx -= 1; update() end)
    rb.MouseButton1Click:Connect(function() PlayClickSound(); idx += 1; update() end)
    nb.MouseButton1Click:Connect(function()
        PlayClickSound()
        local list = getList()
        if #list > 0 then
            if idx > #list then idx = 1 end
            TPToPlayer(list[idx])
        end
    end)

    task.spawn(function()
        while task.wait(1) do pcall(update) end
    end)
end

-- Build Menu UI Elements
AddHeader("FITUR VISUAL")
AddToggle("ESP Box", function(v) State.ESPBox = v end)
AddToggle("ESP Line", function(v) State.ESPLine = v end)
AddToggle("Fullbright", function(v) State.Fullbright = v end)
AddToggle("Camera X-Ray", function(v) State.CameraXRay = v end)

AddHeader("FITUR AKSI")
AddToggle("Air Walk", function(v) State.AirWalk = v end)
AddToggle("Fly Simple", function(v) State.Fly = v; ToggleFly(v) end)
AddToggle("Noclip", function(v) State.Noclip = v end)
AddToggle("Bebas Kamera", function(v) State.BypassCamera = v end)

AddToggle("Walkspeed Toggle", function(v)
    State.WalkspeedToggle = v
    if not v then
        local h = GetHumanoid(LocalPlayer)
        if h then h.WalkSpeed = 16 end
    end
end)

AddTextBox("Input Speed Manual (Contoh: 50)", function(val)
    local n = tonumber(val)
    if n then State.WalkspeedValue = n end
end)

AddHeader("PLAYER SELECTOR (TP)")
AddSelector()

AddButton("TP Player Terjauh", TPFurthest)
AddButton("Rejoin Server", function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
AddButton("Hop Full Server", function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)

print("Zenith Ultralight v4.3 loaded successfully!")
