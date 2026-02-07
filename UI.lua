-- Clean Highlight ESP (Advanced Legit + Outline Control)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ESP = {}

-- ================= SETTINGS =================

ESP.Enabled = true

ESP.TeamCheck = true

ESP.ChamsEnabled = true
ESP.OutlineEnabled = true

ESP.ToolESPEnabled = true
ESP.HealthESPEnabled = true
ESP.DistanceESPEnabled = true

ESP.DefaultColor = Color3.fromRGB(255,255,255)
ESP.OutlineColor = Color3.fromRGB(255,255,255)
ESP.Transparency = 0.9

-- ================= UTILS =================

local function getTeamColor(player)
    if ESP.TeamCheck and player.Team and player.Team.TeamColor then
        return player.Team.TeamColor.Color
    end
    return ESP.DefaultColor
end

local function getOutlineColor(player)
    if ESP.TeamCheck then
        return getTeamColor(player)
    end
    return ESP.OutlineColor
end

local function getEquippedTool(char)
    for _,v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") then
            return v.Name
        end
    end
    return nil
end

local function clear(player)
    if not player.Character then return end
    local char = player.Character

    local hl = char:FindFirstChild("ESP_HL")
    if hl then hl:Destroy() end

    local head = char:FindFirstChild("Head")
    if head then
        local tag = head:FindFirstChild("ESP_Tag")
        if tag then tag:Destroy() end
    end
end

-- ================= CREATE =================

local function create(player)
    if not ESP.Enabled then return end
    if player == LocalPlayer then return end
    if not player.Character then return end
    if player.Character:FindFirstChild("ESP_HL") then return end

    local color = getTeamColor(player)
    local outlineColor = getOutlineColor(player)

    local hl = Instance.new("Highlight")
    hl.Name = "ESP_HL"
    hl.Adornee = player.Character

    hl.FillColor = color
    hl.OutlineColor = outlineColor

    hl.FillTransparency = ESP.ChamsEnabled and ESP.Transparency or 1
    hl.OutlineTransparency = ESP.OutlineEnabled and 0 or 1

    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = player.Character

    local head = player.Character:FindFirstChild("Head")
    if head then
        local gui = Instance.new("BillboardGui")
        gui.Name = "ESP_Tag"
        gui.Adornee = head
        gui.Size = UDim2.fromOffset(160, 22)
        gui.StudsOffset = Vector3.new(0, 2.5, 0)
        gui.AlwaysOnTop = true
        gui.Parent = head

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1,1)
        label.BackgroundTransparency = 1
        label.TextScaled = true
        label.Font = Enum.Font.Gotham
        label.TextStrokeTransparency = 0.85
        label.TextColor3 = color
        label.Text = ""
        label.Parent = gui
    end
end

-- ================= UPDATE =================

local function update(player)
    if not ESP.Enabled then return end
    if player == LocalPlayer then return end
    if not player.Character then return end

    local char = player.Character
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not hum or not root or not head then return end

    local color = getTeamColor(player)
    local outlineColor = getOutlineColor(player)

    local hl = char:FindFirstChild("ESP_HL")
    if hl then
        hl.FillColor = color
        hl.OutlineColor = outlineColor
        hl.FillTransparency = ESP.ChamsEnabled and ESP.Transparency or 1
        hl.OutlineTransparency = ESP.OutlineEnabled and 0 or 1
        hl.Enabled = hum.Health > 0
    end

    local tag = head:FindFirstChild("ESP_Tag")
    if tag then
        local label = tag:FindFirstChildOfClass("TextLabel")
        if label then
            local parts = {}

            table.insert(parts, player.Name)

            if ESP.HealthESPEnabled then
                table.insert(parts, string.format("%d%%", (hum.Health / hum.MaxHealth) * 100))
            end

            if ESP.DistanceESPEnabled and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
                local dist = (LocalPlayer.Character.PrimaryPart.Position - root.Position).Magnitude
                table.insert(parts, string.format("%dm", dist))
            end

            if ESP.ToolESPEnabled then
                local tool = getEquippedTool(char)
                if tool then
                    table.insert(parts, "[" .. tool .. "]")
                end
            end

            label.Text = table.concat(parts, " | ")
            label.TextColor3 = color
        end
    end
end

-- ================= PLAYER HOOK =================

local function setup(player)
    if player == LocalPlayer then return end

    player.CharacterAdded:Connect(function()
        task.wait(0.15)
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

-- ================= LOOP =================

task.spawn(function()
    while true do
        for _,p in ipairs(Players:GetPlayers()) do
            update(p)
        end
        task.wait(0.35)
    end
end)

-- ================= API =================

function ESP.SetEnabled(v) ESP.Enabled = v end
function ESP.SetTeamCheck(v) ESP.TeamCheck = v end
function ESP.SetChams(v) ESP.ChamsEnabled = v end
function ESP.SetOutline(v) ESP.OutlineEnabled = v end
function ESP.SetToolESP(v) ESP.ToolESPEnabled = v end
function ESP.SetHealthESP(v) ESP.HealthESPEnabled = v end
function ESP.SetDistanceESP(v) ESP.DistanceESPEnabled = v end
function ESP.SetTransparency(v) ESP.Transparency = v end
function ESP.SetOutlineColor(c) ESP.OutlineColor = c end

return ESP
