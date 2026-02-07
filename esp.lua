--[[ 
    PATCHED ESP v3
    based on seere_v3
    fixes:
    - Thickness crash
    - team check bug
    - tool detection bug
    - R6/R15 safe
    - outline safety
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local esp = {}
esp.enabled = true
esp.teamcheck = false
esp.outlines = false -- OFF por segurança
esp.shortnames = true

esp.team_boxes   = {true, Color3.fromRGB(255,255,255)}
esp.team_names   = {true, Color3.fromRGB(255,255,255)}
esp.team_health  = true
esp.team_distance = true
esp.team_weapon  = {true, Color3.fromRGB(255,255,255)}

local drawings = {}

-- =========================
-- helpers
-- =========================
local function safe(d)
    return typeof(d) == "userdata" and d.Remove ~= nil
end

local function remove(tbl)
    for _,v in pairs(tbl) do
        if safe(v) then pcall(function() v:Remove() end) end
    end
end

local function getTool(char)
    for _,v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") then
            return v.Name
        end
    end
    return ""
end

local function teamColor(plr, default)
    if esp.teamcheck and plr.Team and plr.Team.TeamColor then
        return plr.Team.TeamColor.Color
    end
    return default
end

function esp.checkteam(plr)
    if not plr or not LocalPlayer.Team then return true end
    return plr.Team ~= LocalPlayer.Team
end

-- =========================
-- create drawings
-- =========================
local function newESP(plr)
    local t = {}

    t.box = Drawing.new("Square")
    t.box.Filled = false
    t.box.Thickness = 1
    t.box.Visible = false

    t.name = Drawing.new("Text")
    t.name.Size = 13
    t.name.Center = true
    t.name.Outline = true
    t.name.Visible = false

    t.distance = Drawing.new("Text")
    t.distance.Size = 12
    t.distance.Center = true
    t.distance.Outline = true
    t.distance.Visible = false

    t.weapon = Drawing.new("Text")
    t.weapon.Size = 12
    t.weapon.Center = false
    t.weapon.Outline = true
    t.weapon.Visible = false

    t.health = Drawing.new("Line")
    t.health.Thickness = 2
    t.health.Visible = false

    drawings[plr] = t
end

local function clear(plr)
    if drawings[plr] then
        remove(drawings[plr])
        drawings[plr] = nil
    end
end

-- =========================
-- update loop
-- =========================
RunService.RenderStepped:Connect(function()
    if not esp.enabled then
        for _,v in pairs(drawings) do
            for _,d in pairs(v) do
                if safe(d) then d.Visible = false end
            end
        end
        return
    end

    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if not drawings[plr] then
                newESP(plr)
            end

            local d = drawings[plr]
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local head = char and char:FindFirstChild("Head")

            if not char or not hrp or not hum or hum.Health <= 0 then
                for _,x in pairs(d) do
                    if safe(x) then x.Visible = false end
                end
                continue
            end

            local pos, onscreen = Camera:WorldToViewportPoint(hrp.Position)
            if not onscreen then
                for _,x in pairs(d) do
                    if safe(x) then x.Visible = false end
                end
                continue
            end

            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            local scale = math.clamp(2000 / dist, 2, 300)
            local size = Vector2.new(scale / 2, scale)

            local color = teamColor(plr, Color3.fromRGB(255,255,255))

            -- BOX
            if esp.team_boxes[1] then
                d.box.Size = size
                d.box.Position = Vector2.new(pos.X - size.X/2, pos.Y - size.Y/2)
                d.box.Color = color
                d.box.Visible = true
            else
                d.box.Visible = false
            end

            -- NAME
            if esp.team_names[1] then
                d.name.Text = esp.shortnames and plr.Name:sub(1,12) or plr.Name
                d.name.Position = Vector2.new(pos.X, d.box.Position.Y - 14)
                d.name.Color = color
                d.name.Visible = true
            else
                d.name.Visible = false
            end

            -- DIST
            if esp.team_distance then
                d.distance.Text = ("[%dm]"):format(dist)
                d.distance.Position = Vector2.new(pos.X, d.box.Position.Y + size.Y + 2)
                d.distance.Color = color
                d.distance.Visible = true
            else
                d.distance.Visible = false
            end

            -- WEAPON (lado da vida)
            if esp.team_weapon[1] then
                d.weapon.Text = getTool(char)
                d.weapon.Position = Vector2.new(d.box.Position.X + size.X + 4, pos.Y)
                d.weapon.Color = esp.team_weapon[2]
                d.weapon.Visible = d.weapon.Text ~= ""
            else
                d.weapon.Visible = false
            end

            -- HEALTH BAR
            if esp.team_health then
                local hp = hum.Health / hum.MaxHealth
                local y1 = d.box.Position.Y + size.Y
                local y2 = y1 - (size.Y * hp)

                d.health.From = Vector2.new(d.box.Position.X - 4, y1)
                d.health.To = Vector2.new(d.box.Position.X - 4, y2)
                d.health.Color = Color3.fromRGB(255 - 255*hp, 255*hp, 0)
                d.health.Visible = true
            else
                d.health.Visible = false
            end
        end
    end
end)

Players.PlayerRemoving:Connect(clear)

return esp
