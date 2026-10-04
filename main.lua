-- =================================================================
-- APEX EXECUTIVE HUB v2.3 (ESP COLOR CUSTOMIZER)
-- =================================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "⚡ Apex Executive Hub",
   LoadingTitle = "Apex Engine Initializing...",
   LoadingSubtitle = "by Zen Core",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

-- Global State & Flag Management
getgenv().ApexFlags = {
    MasterESP = false,
    ESPBox = false,
    ESPName = false,
    ESPLine = false,
    BoxColor = Color3.fromRGB(0, 255, 150),
    NameColor = Color3.fromRGB(255, 255, 255),
    LineColor = Color3.fromRGB(255, 50, 50)
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- =================================================================
-- UI SECTION: VISUALS / ESP TAB
-- =================================================================

local TabVisuals = Window:CreateTab("👁️ Visuals", 4483345998)

TabVisuals:CreateToggle({
   Name = "MASTER ESP",
   CurrentValue = false,
   Callback = function(Value)
      getgenv().ApexFlags.MasterESP = Value
   end,
})

TabVisuals:CreateToggle({
   Name = "ESP BOX",
   CurrentValue = false,
   Callback = function(Value)
      getgenv().ApexFlags.ESPBox = Value
   end,
})

TabVisuals:CreateColorPicker({
    Name = "Warna ESP Box",
    Color = Color3.fromRGB(0, 255, 150),
    Callback = function(Value)
        getgenv().ApexFlags.BoxColor = Value
    end,
})

TabVisuals:CreateToggle({
   Name = "ESP NAME",
   CurrentValue = false,
   Callback = function(Value)
      getgenv().ApexFlags.ESPName = Value
   end,
})

TabVisuals:CreateColorPicker({
    Name = "Warna ESP Name",
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        getgenv().ApexFlags.NameColor = Value
    end,
})

TabVisuals:CreateToggle({
   Name = "ESP LINE",
   CurrentValue = false,
   Callback = function(Value)
      getgenv().ApexFlags.ESPLine = Value
   end,
})

TabVisuals:CreateColorPicker({
    Name = "Warna ESP Line",
    Color = Color3.fromRGB(255, 50, 50),
    Callback = function(Value)
        getgenv().ApexFlags.LineColor = Value
    end,
})

-- =================================================================
-- BACKEND ENGINE: DRAWING ESP SYSTEM
-- =================================================================

local function createESP(player)
    -- Main Box
    local drawBox = Drawing.new("Square")
    drawBox.Visible = false
    drawBox.Thickness = 3.5
    drawBox.Filled = false

    -- Box Outline
    local drawBoxOutline = Drawing.new("Square")
    drawBoxOutline.Visible = false
    drawBoxOutline.Color = Color3.fromRGB(0, 0, 0)
    drawBoxOutline.Thickness = 5.5
    drawBoxOutline.Filled = false

    -- Name
    local drawName = Drawing.new("Text")
    drawName.Visible = false
    drawName.Size = 14
    drawName.Center = true
    drawName.Outline = true

    -- Line
    local drawLine = Drawing.new("Line")
    drawLine.Visible = false
    drawLine.Thickness = 2.0

    local camera = workspace.CurrentCamera

    local updater = RunService.RenderStepped:Connect(function()
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player ~= LocalPlayer then
            local hrp = player.Character.HumanoidRootPart
            local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)

            if onScreen and getgenv().ApexFlags.MasterESP then
                -- ESP Box Logic
                if getgenv().ApexFlags.ESPBox then
                    local sizeX = 2000 / pos.Z
                    local sizeY = 3000 / pos.Z
                    local boxPos = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                    local boxSize = Vector2.new(sizeX, sizeY)

                    drawBoxOutline.Size = boxSize
                    drawBoxOutline.Position = boxPos
                    drawBoxOutline.Visible = true

                    drawBox.Color = getgenv().ApexFlags.BoxColor
                    drawBox.Size = boxSize
                    drawBox.Position = boxPos
                    drawBox.Visible = true
                else
                    drawBox.Visible = false
                    drawBoxOutline.Visible = false
                end

                -- ESP Name Logic
                if getgenv().ApexFlags.ESPName then
                    drawName.Text = player.Name
                    drawName.Color = getgenv().ApexFlags.NameColor
                    drawName.Position = Vector2.new(pos.X, pos.Y - (3000 / pos.Z) / 2 - 15)
                    drawName.Visible = true
                else
                    drawName.Visible = false
                end

                -- ESP Line Logic
                if getgenv().ApexFlags.ESPLine then
                    drawLine.Color = getgenv().ApexFlags.LineColor
                    drawLine.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                    drawLine.To = Vector2.new(pos.X, pos.Y)
                    drawLine.Visible = true
                else
                    drawLine.Visible = false
                end
            else
                drawBox.Visible = false
                drawBoxOutline.Visible = false
                drawName.Visible = false
                drawLine.Visible = false
            end
        else
            drawBox.Visible = false
            drawBoxOutline.Visible = false
            drawName.Visible = false
            drawLine.Visible = false
        end
    end)

    Players.PlayerRemoving:Connect(function(leaver)
        if leaver == player then
            updater:Disconnect()
            drawBox:Remove()
            drawBoxOutline:Remove()
            drawName:Remove()
            drawLine:Remove()
        end
    end)
end

-- Initialize ESP for existing and new players
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then createESP(p) end
end
Players.PlayerAdded:Connect(createESP)

Rayfield:Notify({
   Title = "Apex Hub Updated!",
   Content = "Fitur ganti warna ESP siap digunakan!",
   Duration = 4,
   Image = 4483345998,
})
