-- Highlight ESP Library (STABLE)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ESP = {}
ESP.Enabled = true
ESP.Color = Color3.fromRGB(255, 0, 0)
ESP.Transparency = 0.6

-- ================= UTILS =================

local function clear(player)
    if player.Character then
        local hl = player.Character:FindFirstChild("ESPHighlight")
        if hl then hl:Destroy() end

        local head = player.Character:FindFirstChild("Head")
        if head then
            local tag = head:FindFirstChild("NameTag")
            if tag then tag:Destroy() end
        end
    end
end

local function create(player)
    if not ESP.Enabled then return end
    if not player.Character then return end
    if player == LocalPlayer then return end
    if player.Character:FindFirstChild("ESPHighlight") then return end

    local hl = Instance.new("Highlight")
    hl.Name = "ESPHighlight"
    hl.Adornee = player.Character
    hl.FillColor = ESP.Color
    hl.FillTransparency = ESP.Transparency
    hl.OutlineColor = Color3.new(1,1,1)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = player.Character

    local head = player.Character:FindFirstChild("Head")
    if head and not head:FindFirstChild("NameTag") then
        local gui = Instance.new("BillboardGui")
        gui.Name = "NameTag"
        gui.Adornee = head
        gui.Size = UDim2.fromOffset(160, 28)
        gui.StudsOffset = Vector3.new(0, 2.3, 0)
        gui.AlwaysOnTop = true
        gui.Parent = head

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1,1)
        label.BackgroundTransparency = 1
        label.TextScaled = true
        label.Font = Enum.Font.Cartoon
        label.TextStrokeTransparency = 0.5
        label.TextColor3 = Color3.new(1,1,1)
        label.Text = player.Name
        label.Parent = gui
    end
end

-- ================= PLAYER HOOK =================

local function setup(player)
    if player == LocalPlayer then return end

    player.CharacterAdded:Connect(function()
        task.wait(0.1)
        create(player)
    end)

    if player.Character then
        create(player)
    end
end

for _,p in ipairs(Players:GetPlayers()) do
    setup(p)
end

Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(clear)

-- ================= API =================

function ESP.SetEnabled(v)
    ESP.Enabled = v
    for _,p in ipairs(Players:GetPlayers()) do
        if v then
            create(p)
        else
            clear(p)
        end
    end
end

function ESP.SetColor(c)
    ESP.Color = c
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("ESPHighlight") then
            p.Character.ESPHighlight.FillColor = c
        end
    end
end

function ESP.SetTransparency(v)
    ESP.Transparency = v
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("ESPHighlight") then
            p.Character.ESPHighlight.FillTransparency = v
        end
    end
end

return ESP
