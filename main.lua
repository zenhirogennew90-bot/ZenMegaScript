-- =================================================================
-- APEX EXECUTIVE HUB v3.2 (INDEPENDENT TOGGLE ESP - MOBILE SAFE)
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
   CurrentValue = getgenv().ApexFlags.ESPBox,
   Callback = function(Value)
      getgenv().ApexFlags.ESPBox = Value
   end,
})

TabVisuals:CreateColorPicker({
    Name = "Warna ESP Box",
    Color = getgenv().ApexFlags.BoxColor,
    Callback = function(Value)
        getgenv().ApexFlags.BoxColor = Value
    end,
})

TabVisuals:CreateToggle({
   Name = "ESP NAME",
   CurrentValue = getgenv().ApexFlags.ESPName,
   Callback = function(Value)
      getgenv().ApexFlags.ESPName = Value
   end,
})

TabVisuals:CreateColorPicker({
    Name = "Warna ESP Name",
    Color = getgenv().ApexFlags.NameColor,
    Callback = function(Value)
        getgenv().ApexFlags.NameColor = Value
    end,
})

TabVisuals:CreateToggle({
   Name = "ESP CHAMS",
   CurrentValue = getgenv().ApexFlags.ESPChams,
   Callback = function(Value)
      getgenv().ApexFlags.ESPChams = Value
   end,
})

TabVisuals:CreateColorPicker({
    Name = "Warna ESP Chams",
    Color = getgenv().ApexFlags.ChamsColor,
    Callback = function(Value)
        getgenv().ApexFlags.ChamsColor = Value
    end,
})

-- =================================================================
-- BACKEND ENGINE (INDEPENDENT NATIVE ESP)
-- =================================================================

local function createESP(player)
    local function applyToChar(char)
        if not char then return end
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then return end

        -- 1. Chams Setup (Highlight)
        local highlight = char:FindFirstChild("ApexChams") or Instance.new("Highlight")
        highlight.Name = "ApexChams"
        highlight.Adornee = char
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.4
        highlight.OutlineTransparency = 0
        highlight.Enabled = false
        highlight.Parent = char

        -- 2. Billboard Gui Setup (Box & Name Container)
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
        boxFrame.Visible = false
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
        nameLabel.Visible = false
        nameLabel.Parent = bb

        -- Independent Render Loop
        local updater
        updater = RunService.RenderStepped:Connect(function()
            if char and char:Parent() and player ~= LocalPlayer then
                -- 1. Toggle & Warna Chams
                local isChams = getgenv().ApexFlags.ESPChams
                highlight.Enabled = isChams
                if isChams then
                    highlight.FillColor = getgenv().ApexFlags.ChamsColor
                    highlight.OutlineColor = getgenv().ApexFlags.ChamsColor
                end

                -- 2. Toggle & Warna Box
                local isBox = getgenv().ApexFlags.ESPBox
                boxFrame.Visible = isBox
                if isBox then
                    boxFrame.BorderColor3 = getgenv().ApexFlags.BoxColor
                end

                -- 3. Toggle & Warna Name
                local isName = getgenv().ApexFlags.ESPName
                nameLabel.Visible = isName
                if isName then
                    nameLabel.TextColor3 = getgenv().ApexFlags.NameColor
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
   Title = "Apex Engine Fixed!",
   Content = "Setiap Toggle ESP Sekarang Aktif Mandiri 100%!",
   Duration = 4,
   Image = 4483345998,
})
