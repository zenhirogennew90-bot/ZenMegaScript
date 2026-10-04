-- =================================================================
-- APEX EXECUTIVE HUB v4.0 (STABLE NATIVE ESP - MOBILE OPTIMIZED)
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
-- UI TAB & CONTROLS
-- =================================================================

local TabVisuals = Window:CreateTab("👁️ Visuals", 4483345998)

TabVisuals:CreateToggle({
   Name = "ESP BOX",
   CurrentValue = getgenv().ApexFlags.ESPBox,
   Callback = function(v) getgenv().ApexFlags.ESPBox = v end,
})

TabVisuals:CreateColorPicker({
    Name = "Warna ESP Box",
    Color = getgenv().ApexFlags.BoxColor,
    Callback = function(v) getgenv().ApexFlags.BoxColor = v end,
})

TabVisuals:CreateToggle({
   Name = "ESP NAME",
   CurrentValue = getgenv().ApexFlags.ESPName,
   Callback = function(v) getgenv().ApexFlags.ESPName = v end,
})

TabVisuals:CreateColorPicker({
    Name = "Warna ESP Name",
    Color = getgenv().ApexFlags.NameColor,
    Callback = function(v) getgenv().ApexFlags.NameColor = v end,
})

TabVisuals:CreateToggle({
   Name = "ESP CHAMS",
   CurrentValue = getgenv().ApexFlags.ESPChams,
   Callback = function(v) getgenv().ApexFlags.ESPChams = v end,
})

TabVisuals:CreateColorPicker({
    Name = "Warna ESP Chams",
    Color = getgenv().ApexFlags.ChamsColor,
    Callback = function(v) getgenv().ApexFlags.ChamsColor = v end,
})

-- =================================================================
-- CORE ESP ENGINE
-- =================================================================

local Storage = {}

local function removeESP(player)
    if Storage[player] then
        if Storage[player].Connection then Storage[player].Connection:Disconnect() end
        if Storage[player].Highlight then Storage[player].Highlight:Destroy() end
        if Storage[player].Billboard then Storage[player].Billboard:Destroy() end
        Storage[player] = nil
    end
end

local function applyESP(player)
    removeESP(player)
    if player == LocalPlayer then return end

    local function setupCharacter(char)
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 3)
        if not hrp then return end

        -- 1. Chams Instance
        local highlight = Instance.new("Highlight")
        highlight.Name = "ApexChams"
        highlight.Adornee = char
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.4
        highlight.OutlineTransparency = 0
        highlight.Enabled = false
        highlight.Parent = char

        -- 2. BillboardGui Instance (Box & Name)
        local bb = Instance.new("BillboardGui")
        bb.Name = "ApexBB"
        bb.Adornee = hrp
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(4, 0, 5.5, 0)
        bb.StudsOffset = Vector3.new(0, 0, 0)
        bb.Parent = hrp

        -- Box UI
        local box = Instance.new("Frame")
        box.Name = "Box"
        box.Size = UDim2.new(1, 0, 1, 0)
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 2
        box.Visible = false
        box.Parent = bb

        -- Name UI
        local name = Instance.new("TextLabel")
        name.Name = "Name"
        name.Size = UDim2.new(1, 0, 0.2, 0)
        name.Position = UDim2.new(0, 0, -0.25, 0)
        name.BackgroundTransparency = 1
        name.Text = player.Name
        name.TextSize = 14
        name.Font = Enum.Font.SourceSansBold
        name.TextStrokeTransparency = 0
        name.Visible = false
        name.Parent = bb

        -- Loop Sync Properties
        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not char or not char:Parent() or not hrp or not hrp:Parent() then
                removeESP(player)
                return
            end

            -- Sync Chams
            local isChams = getgenv().ApexFlags.ESPChams
            highlight.Enabled = isChams
            if isChams then
                highlight.FillColor = getgenv().ApexFlags.ChamsColor
                highlight.OutlineColor = getgenv().ApexFlags.ChamsColor
            end

            -- Sync Box
            local isBox = getgenv().ApexFlags.ESPBox
            box.Visible = isBox
            if isBox then
                box.BorderColor3 = getgenv().ApexFlags.BoxColor
            end

            -- Sync Name
            local isName = getgenv().ApexFlags.ESPName
            name.Visible = isName
            if isName then
                name.TextColor3 = getgenv().ApexFlags.NameColor
            end
        end)

        Storage[player] = {
            Connection = conn,
            Highlight = highlight,
            Billboard = bb
        }
    end

    if player.Character then task.spawn(setupCharacter, player.Character) end
    player.CharacterAdded:Connect(function(char)
        task.spawn(setupCharacter, char)
    end)
end

-- Initialize Engine
for _, p in ipairs(Players:GetPlayers()) do
    applyESP(p)
end

Players.PlayerAdded:Connect(applyESP)
Players.PlayerRemoving:Connect(removeESP)

Rayfield:Notify({
   Title = "Apex Engine v4.0 Active",
   Content = "Seluruh modul ESP telah diperbarui!",
   Duration = 4,
   Image = 4483345998,
})
