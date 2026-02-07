-- ESP Highlight + NameTag + Backpack Tool
-- Estável / Anti-duplicação / Sem drag

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ESP_ENABLED = true
local UPDATE_RATE = 0.25

-- ================= INTERNAL =================
local connections = {}

-- ================= UTILS =================

local function getRoot(char)
    return char:FindFirstChild("HumanoidRootPart")
end

local function clearESP(player)
    if player.Character then
        if player.Character:FindFirstChild("ESPHighlight") then
            player.Character.ESPHighlight:Destroy()
        end
        local head = player.Character:FindFirstChild("Head")
        if head and head:FindFirstChild("NameTag") then
            head.NameTag:Destroy()
        end
    end
end

-- ================= CREATE =================

local function createHighlight(player)
    if not ESP_ENABLED then return end
    if not player.Character then return end
    if player.Character:FindFirstChild("ESPHighlight") then return end

    local hl = Instance.new("Highlight")
    hl.Name = "ESPHighlight"
    hl.Adornee = player.Character
    hl.FillColor = Color3.fromRGB(255, 0, 0)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.6
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = player.Character
end

local function createNameTag(player)
    if not ESP_ENABLED then return end
    if not player.Character then return end

    local head = player.Character:FindFirstChild("Head")
    if not head or head:FindFirstChild("NameTag") then return end

    local gui = Instance.new("BillboardGui")
    gui.Name = "NameTag"
    gui.Adornee = head
    gui.Size = UDim2.fromOffset(160, 28)
    gui.StudsOffset = Vector3.new(0, 2.3, 0)
    gui.AlwaysOnTop = true
    gui.Parent = head

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextScaled = true
    label.Font = Enum.Font.Cartoon
    label.TextStrokeTransparency = 0.5
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Text = ""
    label.Parent = gui
end

-- ================= UPDATE =================

local function getEquippedTool(player)
    if not player.Character then return "None" end
    for _, v in ipairs(player.Character:GetChildren()) do
        if v:IsA("Tool") then
            return v.Name
        end
    end
    return "None"
end

local function updateESP(player)
    if not ESP_ENABLED then return end
    if not player.Character then return end

    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    local root = getRoot(player.Character)
    local head = player.Character:FindFirstChild("Head")

    if not hum or not root or not head then return end

    -- Update Highlight
    local hl = player.Character:FindFirstChild("ESPHighlight")
    if hl then
        if hum.Health <= 0 then
            hl.FillColor = Color3.fromRGB(120, 0, 0)
        else
            hl.FillColor = Color3.fromRGB(255, 0, 0)
        end
    end

    -- Update Text
    local tag = head:FindFirstChild("NameTag")
    if tag then
        local label = tag:FindFirstChildOfClass("TextLabel")
        if label and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
            local dist = (LocalPlayer.Character.PrimaryPart.Position - root.Position).Magnitude
            local tool = getEquippedTool(player)

            label.Text =
                player.Name ..
                " | " .. math.floor(dist) .. "m" ..
                " | ❤️" .. math.floor(hum.Health) ..
                " | 🔫 " .. tool
        end
    end
end

-- ================= PLAYER SETUP =================

local function setupPlayer(player)
    if player == LocalPlayer then return end

    player.CharacterAdded:Connect(function(char)
        task.wait(0.15)
        createHighlight(player)
        createNameTag(player)

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Died:Connect(function()
                clearESP(player)
            end)
        end
    end)

    if player.Character then
        createHighlight(player)
        createNameTag(player)
    end
end

-- ================= INIT =================

for _, plr in ipairs(Players:GetPlayers()) do
    setupPlayer(plr)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(clearESP)

-- ================= UPDATE LOOP =================

task.spawn(function()
    while true do
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                updateESP(plr)
            end
        end
        task.wait(UPDATE_RATE)
    end
end)

-- ================= API =================

return {
    SetEnabled = function(v)
        ESP_ENABLED = v
        if not v then
            for _, plr in ipairs(Players:GetPlayers()) do
                clearESP(plr)
            end
        else
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    createHighlight(plr)
                    createNameTag(plr)
                end
            end
        end
    end
}
+
