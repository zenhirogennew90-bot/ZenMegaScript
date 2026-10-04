-- =================================================================
-- APEX CORE EXECUTIVE HUB (SCROLLABLE & MODULAR BACKEND)
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
    SpeedHack = false,
    SpeedVal = 16,
    JumpHack = false,
    JumpVal = 50,
    FlyHack = false,
    FlySpeed = 50,
    ESP = false,
    Noclip = false,
    AutoFarm = false
}

-- =================================================================
-- UI SECTION: COMPACT SCROLLABLE TABS & CONTROLS
-- =================================================================

-- TAB 1: PLAYER MODS
local TabPlayer = Window:CreateTab("🏃 Player", 4483345998)

TabPlayer:CreateToggle({
   Name = "Speed Hack",
   CurrentValue = false,
   Callback = function(Value)
      getgenv().ApexFlags.SpeedHack = Value
   end,
})

TabPlayer:CreateSlider({
   Name = "WalkSpeed Value",
   Range = {16, 500},
   Increment = 1,
   CurrentValue = 16,
   Callback = function(Value)
      getgenv().ApexFlags.SpeedVal = Value
   end,
})

TabPlayer:CreateToggle({
   Name = "Jump Power",
   CurrentValue = false,
   Callback = function(Value)
      getgenv().ApexFlags.JumpHack = Value
   end,
})

TabPlayer:CreateSlider({
   Name = "Jump Value",
   Range = {50, 500},
   Increment = 1,
   CurrentValue = 50,
   Callback = function(Value)
      getgenv().ApexFlags.JumpVal = Value
   end,
})

-- TAB 2: VISUALS / ESP
local TabVisuals = Window:CreateTab("👁️ Visuals", 4483345998)

TabVisuals:CreateToggle({
   Name = "Player ESP (Highlight)",
   CurrentValue = false,
   Callback = function(Value)
      getgenv().ApexFlags.ESP = Value
   end,
})

-- TAB 3: AUTOMATION / GAMEPLAY
local TabAuto = Window:CreateTab("🤖 Automation", 4483345998)

TabAuto:CreateToggle({
   Name = "Master Auto Farm",
   CurrentValue = false,
   Callback = function(Value)
      getgenv().ApexFlags.AutoFarm = Value
   end,
})

-- TAB 4: UTILITIES
local TabUtil = Window:CreateTab("⚙️ Utilities", 4483345998)

TabUtil:CreateToggle({
   Name = "Noclip (Pass Wall)",
   CurrentValue = false,
   Callback = function(Value)
      getgenv().ApexFlags.Noclip = Value
   end,
})

TabUtil:CreateButton({
   Name = "Rejoin Server",
   Callback = function()
      game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
   end,
})

-- =================================================================
-- BACKEND ENGINE & LOGICAL LOOPS (TEMPATTKAN KODE FITUR DI SINI)
-- =================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- 1. Loop Player Stat Modifiers
RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local Hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        
        if getgenv().ApexFlags.SpeedHack then
            Hum.WalkSpeed = getgenv().ApexFlags.SpeedVal
        end
        
        if getgenv().ApexFlags.JumpHack then
            Hum.UseJumpPower = true
            Hum.JumpPower = getgenv().ApexFlags.JumpVal
        end
    end
end)

-- 2. Loop Noclip Logic
RunService.Stepped:Connect(function()
    if getgenv().ApexFlags.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- 3. Loop Auto Farm (Template Logika Fitur Berat)
task.spawn(function()
    while task.wait(0.1) do
        if getgenv().ApexFlags.AutoFarm then
            -- [TEMPATKAN KODE LOGIKA AUTO FARM ATAU FITUR PANJANG DI SINI]
        end
    end
end)

Rayfield:Notify({
   Title = "Apex Hub Ready!",
   Content = "Script berhasil dimuat. Siap digunakan!",
   Duration = 4,
   Image = 4483345998,
})
