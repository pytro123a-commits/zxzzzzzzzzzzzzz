--[[ 
    Custom ESP Library
    Drawing-based
    Stable | No Thickness crash
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

esp.team_boxes   = {true, Color3.fromRGB(255,255,255), Color3.fromRGB(1,1,1), 0}
esp.team_chams   = {true, Color3.fromRGB(138,139,194), Color3.fromRGB(138,139,194), .25, .75, true}
esp.team_names   = {true, Color3.fromRGB(255,255,255)}
esp.team_weapon  = {true, Color3.fromRGB(255,255,255)}
esp.team_distance = true
esp.team_health   = true
-- ==========================================

local cache = {}

-- ================= UTILS =================
local function safe(obj)
    return typeof(obj) == "userdata" and obj.Remove
end

local function removeAll(t)
    for _,v in pairs(t) do
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

local function getColor(plr, default)
    if esp.teamcheck and plr.Team and plr.Team.TeamColor then
        return plr.Team.TeamColor.Color
    end
    return default
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
    d.box.Visible = false

    d.boxOutline = Drawing.new("Square")
    d.boxOutline.Filled = false
    d.boxOutline.Thickness = 3
    d.boxOutline.Visible = false

    d.name = Drawing.new("Text")
    d.name.Center = true
    d.name.Size = 13
    d.name.Outline = true
    d.name.Visible = false

    d.distance = Drawing.new("Text")
    d.distance.Center = true
    d.distance.Size = 12
    d.distance.Outline = true
    d.distance.Visible = false

    d.weapon = Drawing.new("Text")
    d.weapon.Size = 12
    d.weapon.Outline = true
    d.weapon.Visible = false

    d.health = Drawing.new("Line")
    d.health.Thickness = 2
    d.health.Visible = false

    cache[plr] = d
end

local function clear(plr)
    if cache[plr] then
        removeAll(cache[plr])
        cache[plr] = nil
    end
end
-- ============================================

RunService.RenderStepped:Connect(function()
    if not esp.enabled then
        for _,v in pairs(cache) do
            for _,d in pairs(v) do
                if safe(d) then d.Visible = false end
            end
        end
        return
    end

    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and valid(plr) then
            if not cache[plr] then
                create(plr)
            end

            local d = cache[plr]
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if not char or not hrp or not hum or hum.Health <= 0 then
                for _,x in pairs(d) do if safe(x) then x.Visible = false end end
                continue
            end

            local pos, on = Camera:WorldToViewportPoint(hrp.Position)
            if not on then
                for _,x in pairs(d) do if safe(x) then x.Visible = false end end
                continue
            end

            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            local scale = math.clamp(2000 / dist, 3, 300)
            local size = Vector2.new(scale/2, scale)

            local mainColor = getColor(plr, esp.team_boxes[2])

            -- BOX
            if esp.team_boxes[1] then
                d.box.Size = size
                d.box.Position = Vector2.new(pos.X - size.X/2, pos.Y - size.Y/2)
                d.box.Color = mainColor
                d.box.Visible = true

                if esp.outlines then
                    d.boxOutline.Size = size + Vector2.new(2,2)
                    d.boxOutline.Position = d.box.Position - Vector2.new(1,1)
                    d.boxOutline.Color = esp.team_boxes[3]
                    d.boxOutline.Visible = true
                else
                    d.boxOutline.Visible = false
                end
            else
                d.box.Visible = false
                d.boxOutline.Visible = false
            end

            -- NAME
            if esp.team_names[1] then
                d.name.Text = esp.shortnames and plr.Name:sub(1,12) or plr.Name
                d.name.Position = Vector2.new(pos.X, d.box.Position.Y - 14)
                d.name.Color = getColor(plr, esp.team_names[2])
                d.name.Visible = true
            else
                d.name.Visible = false
            end

            -- DISTANCE
            if esp.team_distance then
                d.distance.Text = ("[%dm]"):format(dist)
                d.distance.Position = Vector2.new(pos.X, d.box.Position.Y + size.Y + 2)
                d.distance.Color = mainColor
                d.distance.Visible = true
            else
                d.distance.Visible = false
            end

            -- WEAPON (lado da vida)
            if esp.team_weapon[1] then
                local tool = getTool(char)
                d.weapon.Text = tool
                d.weapon.Position = Vector2.new(d.box.Position.X + size.X + 6, pos.Y)
                d.weapon.Color = esp.team_weapon[2]
                d.weapon.Visible = tool ~= ""
            else
                d.weapon.Visible = false
            end

            -- HEALTH
            if esp.team_health then
                local hp = hum.Health / hum.MaxHealth
                local y1 = d.box.Position.Y + size.Y
                local y2 = y1 - (size.Y * hp)

                d.health.From = Vector2.new(d.box.Position.X - 4, y1)
                d.health.To   = Vector2.new(d.box.Position.X - 4, y2)
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
