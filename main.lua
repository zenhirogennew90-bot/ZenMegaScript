
--==================================================
-- JALAN SANTAI + FLY + AIRWALK
-- Delta Executor | Roblox | Mobile + PC
--==================================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

if not player then return end

-- CONFIG
local WALK_SPEED = 8
local FLY_SPEED = 40
local FLY_VERTICAL_SPEED = 30
-- Status animasi/state sebelum Fly
local savedFlyState = {}

-- CLEANUP SCRIPT LAMA
if _G.JalanSantaiCleanup then
    pcall(_G.JalanSantaiCleanup)
end

local destroyed = false
local walkEnabled = false
local flyEnabled = false
local airWalkEnabled = false
local verticalInput = 0

local connections = {}
local movers = {}
local flyConnection
local airWalkConnection
local airWalkAttachment
local airWalkForce

local originalSpeed = setmetatable({}, {__mode = "k"})
local originalRotate = setmetatable({}, {__mode = "k"})

local gui

--==================================================
-- CONNECTION MANAGER
--==================================================

local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(connections, c)
    return c
end

local function getCharacter()
    local character = player.Character
    if not character then return nil end

    return character,
        character:FindFirstChildOfClass("Humanoid"),
        character:FindFirstChild("HumanoidRootPart")
end

local function rememberSpeed(humanoid)
    if originalSpeed[humanoid] == nil then
        originalSpeed[humanoid] = humanoid.WalkSpeed
    end
end

local function restoreSpeed(humanoid)
    if humanoid and originalSpeed[humanoid] ~= nil then
        humanoid.WalkSpeed = originalSpeed[humanoid]
        originalSpeed[humanoid] = nil
    end
end

--==================================================
-- GUI HELPERS
--==================================================

local function round(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = object
end

local function makeButton(parent, name, text, position, size, color)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Text = text
    b.Position = position
    b.Size = size
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = true
    b.Active = true
    b.Parent = parent
    round(b, 9)
    return b
end

--==================================================
-- CREATE SCREEN GUI
--==================================================

gui = Instance.new("ScreenGui")
gui.Name = "WalkFlyAirWalk"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local ok = pcall(function()
    gui.Parent = game:GetService("CoreGui")
end)

if not ok or not gui.Parent then
    gui.Parent = player:WaitForChild("PlayerGui")
end

-- MAIN PANEL
local main = Instance.new("Frame")
main.Name = "MainPanel"
main.Size = UDim2.fromOffset(260, 225)
main.Position = UDim2.new(0.5, -130, 0.3, 0)
main.BackgroundColor3 = Color3.fromRGB(22, 25, 35)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
round(main, 13)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(65, 145, 255)
mainStroke.Thickness = 1.5
mainStroke.Parent = main

local header = Instance.new("TextLabel")
header.Name = "DragHeader"
header.Size = UDim2.new(1, -50, 0, 40)
header.Position = UDim2.fromOffset(12, 0)
header.BackgroundTransparency = 1
header.Text = "WALK  /  FLY  /  AIRWALK"
header.TextColor3 = Color3.new(1, 1, 1)
header.TextSize = 13
header.Font = Enum.Font.GothamBold
header.TextXAlignment = Enum.TextXAlignment.Left
header.Active = true
header.Parent = main

local closeButton = makeButton(
    main, "Close", "X",
    UDim2.new(1, -40, 0, 5),
    UDim2.fromOffset(32, 30),
    Color3.fromRGB(190, 55, 65)
)

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Size = UDim2.new(1, -20, 0, 25)
status.Position = UDim2.fromOffset(10, 39)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(205, 215, 230)
status.TextSize = 11
status.Font = Enum.Font.Gotham
status.Parent = main

local walkButton = makeButton(
    main, "WalkToggle", "JALAN SANTAI: OFF",
    UDim2.fromOffset(10, 70),
    UDim2.new(1, -20, 0, 42),
    Color3.fromRGB(35, 105, 75)
)

local flyButton = makeButton(
    main, "FlyToggle", "FLY: OFF",
    UDim2.fromOffset(10, 120),
    UDim2.new(1, -20, 0, 42),
    Color3.fromRGB(45, 85, 155)
)

local airWalkButton = makeButton(
    main, "AirWalkToggle", "AIRWALK: OFF",
    UDim2.fromOffset(10, 170),
    UDim2.new(1, -20, 0, 42),
    Color3.fromRGB(90, 65, 130)
)

--==================================================
-- SEPARATE FLY CONTROL PANEL
--==================================================

local flyPanel = Instance.new("Frame")
flyPanel.Name = "FlyControlPanel"
flyPanel.Size = UDim2.fromOffset(150, 150)
flyPanel.Position = UDim2.new(1, -165, 0.45, 0)
flyPanel.BackgroundColor3 = Color3.fromRGB(22, 25, 35)
flyPanel.BorderSizePixel = 0
flyPanel.Visible = false
flyPanel.Active = true
flyPanel.Parent = gui
round(flyPanel, 13)

local flyStroke = Instance.new("UIStroke")
flyStroke.Color = Color3.fromRGB(65, 145, 255)
flyStroke.Thickness = 1.5
flyStroke.Parent = flyPanel

local flyHeader = Instance.new("TextLabel")
flyHeader.Name = "DragHeader"
flyHeader.Size = UDim2.new(1, -10, 0, 32)
flyHeader.Position = UDim2.fromOffset(5, 0)
flyHeader.BackgroundTransparency = 1
flyHeader.Text = "FLY CONTROL"
flyHeader.TextColor3 = Color3.new(1, 1, 1)
flyHeader.TextSize = 12
flyHeader.Font = Enum.Font.GothamBold
flyHeader.Active = true
flyHeader.Parent = flyPanel

local upButton = makeButton(
    flyPanel, "FlyUp", "▲  NAIK",
    UDim2.fromOffset(10, 40),
    UDim2.new(1, -20, 0, 42),
    Color3.fromRGB(40, 145, 190)
)

local downButton = makeButton(
    flyPanel, "FlyDown", "▼  TURUN",
    UDim2.fromOffset(10, 90),
    UDim2.new(1, -20, 0, 42),
    Color3.fromRGB(125, 85, 180)
)

--==================================================
-- UPDATE UI
--==================================================

local function updateUI()
    if destroyed then return end

    walkButton.Text = walkEnabled
        and "JALAN SANTAI: ON"
        or "JALAN SANTAI: OFF"

    flyButton.Text = flyEnabled and "FLY: ON" or "FLY: OFF"

    airWalkButton.Text = airWalkEnabled
        and "AIRWALK: ON"
        or "AIRWALK: OFF"

    walkButton.BackgroundColor3 = walkEnabled
        and Color3.fromRGB(30, 165, 95)
        or Color3.fromRGB(35, 105, 75)

    flyButton.BackgroundColor3 = flyEnabled
        and Color3.fromRGB(40, 135, 225)
        or Color3.fromRGB(45, 85, 155)

    airWalkButton.BackgroundColor3 = airWalkEnabled
        and Color3.fromRGB(140, 95, 205)
        or Color3.fromRGB(90, 65, 130)

    status.Text = "Walk " .. (walkEnabled and "ON" or "OFF")
        .. " | Fly " .. (flyEnabled and "ON" or "OFF")
        .. " | AirWalk " .. (airWalkEnabled and "ON" or "OFF")

    flyPanel.Visible = flyEnabled
end

--==================================================
-- WALK SYSTEM
--==================================================

local function setWalk(enabled)
    walkEnabled = enabled

    local _, humanoid = getCharacter()
    if not humanoid then return end

    if enabled then
        rememberSpeed(humanoid)
        humanoid.WalkSpeed = WALK_SPEED
    else
        restoreSpeed(humanoid)
    end
end

--==================================================
-- FLY SYSTEM
--==================================================

local function removeFlyObjects()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    for _, object in ipairs(movers) do
        pcall(function()
            object:Destroy()
        end)
    end
    table.clear(movers)

    local _, humanoid = getCharacter()
    if humanoid and originalRotate[humanoid] ~= nil then
        humanoid.AutoRotate = originalRotate[humanoid]
        originalRotate[humanoid] = nil
    end

    verticalInput = 0
end

local function stopFly()
    flyEnabled = false
    removeFlyObjects()
end

local function startFly()
    local _, humanoid, root = getCharacter()

    if not humanoid or not root or humanoid.Health <= 0 then
        flyEnabled = false
        return
    end

    removeFlyObjects()

    originalRotate[humanoid] = humanoid.AutoRotate
    humanoid.AutoRotate = false

    local velocity = Instance.new("BodyVelocity")
    velocity.Name = "LocalFlyVelocity"
    velocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    velocity.P = 1e4
    velocity.Velocity = Vector3.zero
    velocity.Parent = root
    table.insert(movers, velocity)

    local gyro = Instance.new("BodyGyro")
    gyro.Name = "LocalFlyGyro"
    gyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    gyro.P = 1e4
    gyro.D = 500
    gyro.CFrame = root.CFrame
    gyro.Parent = root
    table.insert(movers, gyro)

    flyConnection = RunService.Heartbeat:Connect(function()
        if destroyed or not flyEnabled then return end

        if not root.Parent or humanoid.Health <= 0 then
            stopFly()
            updateUI()
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then return end

        local move = humanoid.MoveDirection
        local horizontal = Vector3.new(move.X, 0, move.Z)

        velocity.Velocity =
            horizontal * FLY_SPEED
            + Vector3.new(0, verticalInput * FLY_VERTICAL_SPEED, 0)

        local look = camera.CFrame.LookVector
        gyro.CFrame = CFrame.lookAt(
            root.Position,
            root.Position + look
        )
    end)
end

--==================================================
-- AIRWALK SYSTEM
-- Menahan jatuh, bukan terbang naik-turun
--==================================================

local function removeAirWalkObjects()
    if airWalkConnection then
        airWalkConnection:Disconnect()
        airWalkConnection = nil
    end

    if airWalkForce then
        airWalkForce:Destroy()
        airWalkForce = nil
    end

    if airWalkAttachment then
        airWalkAttachment:Destroy()
        airWalkAttachment = nil
    end
end

local function stopAirWalk()
    airWalkEnabled = false
    removeAirWalkObjects()
end

local function startAirWalk()
    removeAirWalkObjects()

    local _, humanoid, root = getCharacter()

    if not humanoid or not root or humanoid.Health <= 0 then
        airWalkEnabled = false
        return
    end

    airWalkAttachment = Instance.new("Attachment")
    airWalkAttachment.Name = "LocalAirWalkAttachment"
    airWalkAttachment.Parent = root

    airWalkForce = Instance.new("VectorForce")
    airWalkForce.Name = "LocalAirWalkForce"
    airWalkForce.Attachment0 = airWalkAttachment
    airWalkForce.RelativeTo = Enum.ActuatorRelativeTo.World
    airWalkForce.ApplyAtCenterOfMass = true
    airWalkForce.Force = Vector3.zero
    airWalkForce.Parent = root

    airWalkConnection = RunService.Heartbeat:Connect(function()
        if destroyed or not airWalkEnabled then return end

        if not root.Parent or humanoid.Health <= 0 then
            stopAirWalk()
            updateUI()
            return
        end

        -- Jangan aktifkan gaya AirWalk bersamaan dengan Fly
        if flyEnabled then
            airWalkForce.Force = Vector3.zero
            return
        end

        if humanoid.FloorMaterial == Enum.Material.Air then
            airWalkForce.Force = Vector3.new(
                0,
                root.AssemblyMass * workspace.Gravity,
                0
            )

            local velocity = root.AssemblyLinearVelocity

            if velocity.Y < 0 then
                root.AssemblyLinearVelocity = Vector3.new(
                    velocity.X,
                    0,
                    velocity.Z
                )
            end
        else
            airWalkForce.Force = Vector3.zero
        end
    end)
end

--==================================================
-- BUTTON EVENTS
--==================================================

connect(walkButton.Activated, function()
    if destroyed then return end

    setWalk(not walkEnabled)
    updateUI()
end)

connect(flyButton.Activated, function()
    if destroyed then return end

    if flyEnabled then
        stopFly()
    else
        -- Hindari konflik fisika Fly dengan AirWalk
        if airWalkEnabled then
            stopAirWalk()
        end

        flyEnabled = true
        startFly()
    end

    updateUI()
end)

connect(airWalkButton.Activated, function()
    if destroyed then return end

    if airWalkEnabled then
        stopAirWalk()
    else
        -- AirWalk tidak berjalan bersamaan dengan Fly
        if flyEnabled then
            stopFly()
        end

        airWalkEnabled = true
        startAirWalk()
    end

    updateUI()
end)

--==================================================
-- FLY HOLD CONTROLS
--==================================================

local function bindVertical(button, direction)
    connect(button.InputBegan, function(input)
        if destroyed or not flyEnabled then return end

        local kind = input.UserInputType
        if kind == Enum.UserInputType.Touch
            or kind == Enum.UserInputType.MouseButton1 then
            verticalInput = direction
        end
    end)

    connect(button.InputEnded, function(input)
        local kind = input.UserInputType
        if kind == Enum.UserInputType.Touch
            or kind == Enum.UserInputType.MouseButton1 then
            if verticalInput == direction then
                verticalInput = 0
            end
        end
    end)
end

bindVertical(upButton, 1)
bindVertical(downButton, -1)

connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        verticalInput = 0
    end
end)

--==================================================
-- DRAG PANELS
--==================================================

local function makeDraggable(panel, dragHandle)
    local dragging = false
    local dragStart
    local startPosition
    local activeInput

    connect(dragHandle.InputBegan, function(input)
        local kind = input.UserInputType

        if kind == Enum.UserInputType.Touch
            or kind == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPosition = panel.Position
            activeInput = input
        end
    end)

    connect(UIS.InputChanged, function(input)
        if not dragging then return end

        local mouseMove =
            input.UserInputType == Enum.UserInputType.MouseMovement
        local touchMove = activeInput and input == activeInput

        if mouseMove or touchMove then
            local delta = input.Position - dragStart

            panel.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    connect(UIS.InputEnded, function(input)
        local kind = input.UserInputType

        if kind == Enum.UserInputType.Touch
            or kind == Enum.UserInputType.MouseButton1 then
            dragging = false
            activeInput = nil
        end
    end)
end

makeDraggable(main, header)
makeDraggable(flyPanel, flyHeader)

--==================================================
-- RESPAWN SUPPORT
--==================================================

connect(player.CharacterAdded, function()
    stopFly()
    stopAirWalk()

    walkEnabled = false
    airWalkEnabled = false

    task.spawn(function()
        local character = player.Character
        local humanoid = character
            and character:WaitForChild("Humanoid", 10)

        if destroyed or not humanoid then return end

        updateUI()
    end)
end)

--==================================================
-- COMPLETE CLEANUP
--==================================================

local function cleanup()
    if destroyed then return end

    stopFly()
    stopAirWalk()
    setWalk(false)

    destroyed = true

    for _, c in ipairs(connections) do
        pcall(function()
            c:Disconnect()
        end)
    end
    table.clear(connections)

    -- Pulihkan properti humanoid yang masih tersimpan
    local _, humanoid = getCharacter()
    if humanoid then
        restoreSpeed(humanoid)

        if originalRotate[humanoid] ~= nil then
            humanoid.AutoRotate = originalRotate[humanoid]
            originalRotate[humanoid] = nil
        end
    end

    pcall(function()
        gui:Destroy()
    end)

    if _G.JalanSantaiCleanup == cleanup then
        _G.JalanSantaiCleanup = nil
    end
end

connect(closeButton.Activated, cleanup)
_G.JalanSantaiCleanup = cleanup

updateUI()
