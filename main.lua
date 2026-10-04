-- =================================================================
-- APEX EXECUTIVE HUB v3.1 (CLEAN NATIVE ESP - NO MASTER TOGGLE)
-- =================================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "⚡ Apex Executive Hub",
   LoadingTitle = "Apex Engine Initializing...",
   LoadingSubtitle = "by Zen Core",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

getgenv().ApexFlags = {
    ESPBox = false,
    ESPName = false,
    ESPChams = false,
    BoxColor = Color3.fromRGB(0, 255, 150),
    NameColor = Color3.fromRGB(255, 255, 255),
    ChamsColor = Color3.fromRGB(255, 0, 128)
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- =================================================================
-- UI SECTION: VISUALS / ESP TAB
-- =================================================================

local TabVisuals = Window:CreateTab("👁️ Visuals", 4483345998)

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
   Name = "ESP CHAMS",
   CurrentValue = false,
   Callback = function(Value)
      getgenv().ApexFlags.ESPChams = Value
   end,
})

TabVisuals:CreateColorPicker({
    Name = "Warna ESP Chams",
    Color = Color3.fromRGB(255, 0, 128),
    Callback = function(Value)
        getgenv().ApexFlags.ChamsColor = Value
    end,
})

-- =================================================================
-- BACKEND ENGINE (ROBLOX NATIVE ESP)
-- =================================================================

local function createESP(player)
    local function applyToChar(char)
        if not char then return end
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then return end

        -- Chams Setup (Highlight)
        local highlight = char:FindFirstChild("ApexChams") or Instance.new("Highlight")
        highlight.Name = "ApexChams"
        highlight.Adornee = char
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.4
        highlight.OutlineTransparency = 0
        highlight.Parent = char

        -- Billboard Gui Setup (Box & Name)
        local bb = char:FindFirstChild("ApexBB") or Instance.new("BillboardGui")
        bb.Name = "ApexBB"
        bb.Adornee = hrp
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(4.5, 0, 6, 0)
        bb.StudsOffset = Vector3.new(0, 0, 0)
        bb.Parent = hrp

        -- ESP Box Frame
        local boxFrame = bb:FindFirstChild("BoxFrame") or Instance.new("Frame")
        boxFrame.Name = "BoxFrame"
        boxFrame.Size = UDim2.new(1, 0, 1, 0)
        boxFrame.BackgroundTransparency = 1
        boxFrame.BorderSizePixel = 3
        boxFrame.Parent = bb

        -- ESP Name Label
        local nameLabel = bb:FindFirstChild("NameLabel") or Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, 0, 0.25, 0)
        nameLabel.Position = UDim2.new(0, 0, -0.3, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.TextStrokeTransparency = 0
        nameLabel.Parent = bb

        -- Render Loop Update Real-Time
        local updater
        updater = RunService.RenderStepped:Connect(function()
            if char and char:Parent() and player ~= LocalPlayer then
                -- Update Chams
                if getgenv().ApexFlags.ESPChams then
                    highlight.Enabled = true
                    highlight.FillColor = getgenv().ApexFlags.ChamsColor
                    highlight.OutlineColor = getgenv().ApexFlags.ChamsColor
                else
                    highlight.Enabled = false
                end

                -- Update Box
                if getgenv().ApexFlags.ESPBox then
                    boxFrame.Visible = true
                    boxFrame.BorderColor3 = getgenv().ApexFlags.BoxColor
                else
                    boxFrame.Visible = false
                end

                -- Update Name
                if getgenv().ApexFlags.ESPName then
                    nameLabel.Visible = true
                    nameLabel.TextColor3 = getgenv().ApexFlags.NameColor
                else
                    nameLabel.Visible = false
                end
            else
                highlight:Destroy()
                bb:Destroy()
                if updater then updater:Disconnect() end
            end
        end)
    end

    if player.Character then applyToChar(player.Character) end
    player.CharacterAdded:Connect(applyToChar)
end

-- Initialize Semua Player
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then createESP(p) end
end
Players.PlayerAdded:Connect(createESP)

Rayfield:Notify({
   Title = "Apex Engine Updated!",
   Content = "Master ESP Dihapus. Sistem Lebih Ringan & Responsif!",
   Duration = 4,
   Image = 4483345998,
})
