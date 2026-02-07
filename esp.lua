--[[ 
    Custom ESP Library (FINAL)
    Drawing-based
    Offscreen fixed
    Death / Leave safe
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local esp = {}

-- ================= CONFIG =================
esp.enabled = true
esp.teamcheck = false
esp.outlines = true
esp.shortnames = true
esp.fade_speed = 0.18

esp.team_boxes   = {true, Color3.fromRGB(255,255,255), Color3.fromRGB(0,0,0)}
esp.team_names   = {true, Color3.fromRGB(255,255,255)}
esp.team_weapon  = {true, Color3.fromRGB(255,255,255)}
esp.team_distance = true
esp.team_health   = true
-- ==========================================

local cache = {}

-- ================= UTILS =================
local function safe(o)
    return typeof(o) == "userdata" and o.Remove
end

local function hide(d)
    for _,v in pairs(d) do
        if safe(v) then
            v.Visible = false
            if v.Transparency then
                v.Transparency = 1
            end
        end
    end
end

local function fade(d, target)
    for _,v in pairs(d) do
        if safe(v) and v.Transparency then
            v.Transparency += (target - v.Transparency) * esp.fade_speed
            v.Visible = v.Transparency < 0.97
        end
    end
end

local function isOnScreen(pos)
    local vp = Camera.ViewportSize
    return pos.Z > 0
       and pos.X >= 0 and pos.X <= vp.X
       and pos.Y >= 0 and pos.Y <= vp.Y
end

local function getTool(char)
    for _,v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") then
            return v.Name
        end
    end
    return ""
end

local function valid(plr)
    if not esp.teamcheck then return true end
    if not LocalPlayer.Team then return true end
    return plr.Team ~= LocalPlayer.Team
end
-- ==========================================

-- ================= DRAWINGS =================
local function create(plr)
    local d = {}

    d.box = Drawing.new("Square")
    d.box.Filled = false
    d.box.Thickness = 1
    d.box.Transparency = 1

    d.outline = Drawing.new("Square")
    d.outline.Filled = false
    d.outline.Thickness = 3
    d.outline.Transparency = 1

    d.name = Drawing.new("Text")
    d.name.Center = true
    d.name.Size = 13
    d.name.Outline = true
    d.name.Transparency = 1

    d.distance = Drawing.new("Text")
    d.distance.Center = true
    d.distance.Size = 12
    d.distance.Outline = true
    d.distance.Transparency = 1

    d.weapon = Drawing.new("Text")
    d.weapon.Size = 12
    d.weapon.Outline = true
    d.weapon.Transparency = 1

    d.health = Drawing.new("Line")
    d.health.Thickness = 2
    d.health.Transparency = 1

    cache[plr] = d
end

local function clear(plr)
    local d = cache[plr]
    if not d then return end

    for _,v in pairs(d) do
        if safe(v) then
            v.Visible = false
            v:Remove()
        end
    end

    cache[plr] = nil
end
-- ============================================

-- ================= MAIN LOOP =================
RunService.RenderStepped:Connect(function()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if not valid(plr) then continue end

        if not cache[plr] then
            create(plr)
        end

        local d = cache[plr]
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if not esp.enabled or not char or not hrp or not hum then
            fade(d, 1)
            continue
        end

        -- MORTE = SOME NA HORA
        if hum.Health <= 0 then
            hide(d)
            continue
        end

        local pos, on = Camera:WorldToViewportPoint(hrp.Position)
        if not on or not isOnScreen(pos) then
            fade(d, 1)
            continue
        end

        fade(d, 0)

        local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
        local scale = math.clamp(1800 / dist, 6, 300)
        local size = Vector2.new(scale / 2, scale)

        -- BOX
        if esp.team_boxes[1] then
            d.box.Size = size
            d.box.Position = Vector2.new(pos.X - size.X/2, pos.Y - size.Y/2)
            d.box.Color = esp.team_boxes[2]
        end

        if esp.outlines then
            d.outline.Size = size + Vector2.new(2,2)
            d.outline.Position = d.box.Position - Vector2.new(1,1)
            d.outline.Color = esp.team_boxes[3]
        else
            d.outline.Visible = false
        end

        -- NAME
        if esp.team_names[1] then
            d.name.Text = esp.shortnames and plr.Name:sub(1,12) or plr.Name
            d.name.Position = Vector2.new(pos.X, d.box.Position.Y - 14)
            d.name.Color = esp.team_names[2]
        end

        -- DISTANCE
        if esp.team_distance then
            d.distance.Text = ("[%dm]"):format(dist)
            d.distance.Position = Vector2.new(pos.X, d.box.Position.Y + size.Y + 2)
            d.distance.Color = esp.team_boxes[2]
        end

        -- WEAPON
        if esp.team_weapon[1] then
            d.weapon.Text = getTool(char)
            d.weapon.Position = Vector2.new(d.box.Position.X + size.X + 6, pos.Y)
            d.weapon.Color = esp.team_weapon[2]
        end

        -- HEALTH
        if esp.team_health then
            local hp = hum.Health / hum.MaxHealth
            local y1 = d.box.Position.Y + size.Y
            local y2 = y1 - (size.Y * hp)
            d.health.From = Vector2.new(d.box.Position.X - 4, y1)
            d.health.To   = Vector2.new(d.box.Position.X - 4, y2)
            d.health.Color = Color3.fromRGB(255 - 255*hp, 255*hp, 0)
        end
    end
end)
-- ============================================

-- REMOVE AO SAIR
Players.PlayerRemoving:Connect(clear)

-- LIMPA NO RESPAWN
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        if cache[plr] then
            hide(cache[plr])
        end
    end)
end)

return esp
