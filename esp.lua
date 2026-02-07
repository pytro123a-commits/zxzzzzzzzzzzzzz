--[[
    ESP V3
    Highlight + BillboardGui
    Ultra stable / No drag possible
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local esp = {}

-- ===== CONFIG =====
esp.enabled = true
esp.showHighlight = true
esp.showName = true
esp.showDistance = true
esp.teamcheck = false

esp.fillColor = Color3.fromRGB(255, 0, 0)
esp.outlineColor = Color3.fromRGB(255, 255, 255)
esp.fillTransparency = 0.5
esp.outlineTransparency = 0
-- ==================

local objects = {}

-- ===== UTILS =====
local function valid(plr)
    if not esp.teamcheck then return true end
    if not LocalPlayer.Team then return true end
    return plr.Team ~= LocalPlayer.Team
end

local function cleanup(plr)
    local obj = objects[plr]
    if not obj then return end

    if obj.highlight then obj.highlight:Destroy() end
    if obj.gui then obj.gui:Destroy() end

    objects[plr] = nil
end
-- ==================

-- ===== CREATE =====
local function create(plr, char)
    cleanup(plr)

    local highlight
    if esp.showHighlight then
        highlight = Instance.new("Highlight")
        highlight.Adornee = char
        highlight.FillColor = esp.fillColor
        highlight.OutlineColor = esp.outlineColor
        highlight.FillTransparency = esp.fillTransparency
        highlight.OutlineTransparency = esp.outlineTransparency
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = char
    end

    local gui
    if esp.showName or esp.showDistance then
        gui = Instance.new("BillboardGui")
        gui.Size = UDim2.fromOffset(200, 50)
        gui.StudsOffset = Vector3.new(0, 3, 0)
        gui.AlwaysOnTop = true
        gui.Adornee = char:WaitForChild("Head", 2)
        gui.Parent = char

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.TextScaled = true
        label.Font = Enum.Font.SourceSansBold
        label.TextColor3 = Color3.new(1,1,1)
        label.TextStrokeTransparency = 0
        label.Parent = gui

        gui._label = label
    end

    objects[plr] = {
        highlight = highlight,
        gui = gui
    }
end
-- ==================

-- ===== UPDATE =====
RunService.RenderStepped:Connect(function()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if not valid(plr) then
            cleanup(plr)
            continue
        end

        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if not esp.enabled or not char or not hum or hum.Health <= 0 then
            cleanup(plr)
            continue
        end

        if not objects[plr] then
            create(plr, char)
        end

        local obj = objects[plr]

        -- UPDATE TEXTO
        if obj.gui and obj.gui:FindFirstChild("_label") then
            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            local txt = ""

            if esp.showName then
                txt = plr.Name
            end
            if esp.showDistance then
                txt = txt .. string.format(" [%dm]", dist)
            end

            obj.gui._label.Text = txt
        end
    end
end)

Players.PlayerRemoving:Connect(cleanup)

return esp
