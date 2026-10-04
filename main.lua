-- =================================================================
-- CORE ESP ENGINE (UNIVERSAL SLAP BATTLES & OBBY COMPATIBLE)
-- =================================================================

local Storage = {}

local function removeESP(player)
    if Storage[player] then
        if Storage[player].Connection then Storage[player].Connection:Disconnect() end
        if Storage[player].Highlight then pcall(function() Storage[player].Highlight:Destroy() end) end
        if Storage[player].Billboard then pcall(function() Storage[player].Billboard:Destroy() end) end
        Storage[player] = nil
    end
end

local function applyESP(player)
    removeESP(player)
    if player == LocalPlayer then return end

    local function setupCharacter(char)
        if not char then return end
        
        -- Fallback Part Detection untuk Game Custom
        local rootPart = char:WaitForChild("HumanoidRootPart", 4) 
            or char:WaitForChild("Head", 2) 
            or char:WaitForChild("Torso", 2) 
            or char:FindFirstChildWhichIsA("BasePart")
            
        if not rootPart then return end

        -- 1. Chams Instance (Menggunakan CoreGui / Char Parent)
        local highlight = Instance.new("Highlight")
        highlight.Name = "ApexChams_" .. player.Name
        highlight.Adornee = char
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.3
        highlight.OutlineTransparency = 0
        highlight.Enabled = false
        
        -- Jalankan pcall untuk menghindari proteksi game
        pcall(function()
            highlight.Parent = char
        end)

        -- 2. BillboardGui Instance (Box & Name)
        local bb = Instance.new("BillboardGui")
        bb.Name = "ApexBB_" .. player.Name
        bb.Adornee = rootPart
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(4.5, 0, 6, 0)
        bb.StudsOffset = Vector3.new(0, 0, 0)
        
        pcall(function()
            bb.Parent = rootPart
        end)

        -- Box Frame
        local box = Instance.new("Frame")
        box.Name = "Box"
        box.Size = UDim2.new(1, 0, 1, 0)
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 2
        box.Visible = false
        box.Parent = bb

        -- Name TextLabel
        local name = Instance.new("TextLabel")
        name.Name = "Name"
        name.Size = UDim2.new(1, 0, 0.25, 0)
        name.Position = UDim2.new(0, 0, -0.3, 0)
        name.BackgroundTransparency = 1
        name.Text = player.DisplayName .. " (@" .. player.Name .. ")"
        name.TextSize = 13
        name.Font = Enum.Font.SourceSansBold
        name.TextStrokeTransparency = 0
        name.Visible = false
        name.Parent = bb

        -- Update Loop Real-time Sync
        local conn
        conn = RunService.Heartbeat:Connect(function()
            if not char or not char.Parent or not rootPart or not rootPart.Parent then
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

    if player.Character then 
        task.spawn(setupCharacter, player.Character) 
    end
    
    player.CharacterAdded:Connect(function(char)
        task.spawn(setupCharacter, char)
    end)
end

-- Initialize Engine untuk Semua Player
for _, p in ipairs(Players:GetPlayers()) do
    applyESP(p)
end

Players.PlayerAdded:Connect(applyESP)
Players.PlayerRemoving:Connect(removeESP)
