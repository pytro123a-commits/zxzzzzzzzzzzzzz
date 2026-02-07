--[[
    ESP V2
    Stateless / Anti-drag / UI-safe
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local esp = {}

-- ===== CONFIG =====
esp.enabled = true
esp.showBox = true
esp.showName = true
esp.showDistance = true
esp.showWeapon = true
esp.showHealth = true
esp.shortNames = true
esp.color = Color3.fromRGB(255,255,255)
-- ==================

-- cache só de objetos, NÃO de estado
local objects = {}

-- ===== UTILS =====
local function newSquare()
    local s = Drawing.new("Square")
    s.Filled = false
    s.Thickness = 1
    s.Visible = false
    return s
end

local function newText(size)
    local t = Drawing.new("Text")
    t.Center = true
    t.Outline = true
    t.Size = size
    t.Visible = false
    return t
end

local function newLine()
    local l = Drawing.new("Line")
    l.Thickness = 2
    l.Visible = false
    return l
end

local function destroySet(set)
    if not set then return end
    for _,v in pairs(set) do
        if typeof(v) == "userdata" and v.Remove then
            v:Remove()
        end
    end
end

local function onScreen(pos)
    local vp = Camera.ViewportSize
    return pos.Z > 0
       and pos.X >= 0 and pos.X <= vp.X
       and pos.Y >= 0 and pos.Y <= vp.Y
end

local function getTool(char)
    for _,v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") then return v.Name end
    end
    return ""
end
-- ==================

-- ===== MAIN LOOP =====
RunService.RenderStepped:Connect(function()
    if not esp.enabled then
        for _,set in pairs(objects) do
            for _,v in pairs(set) do v.Visible = false end
        end
        return
    end

    for _,plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end

        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        -- SEM CHAR = DESTROI
        if not char or not hrp or not hum or hum.Health <= 0 then
            destroySet(objects[plr])
            objects[plr] = nil
            continue
        end

        local pos, on = Camera:WorldToViewportPoint(hrp.Position)
        if not on or not onScreen(pos) then
            destroySet(objects[plr])
            objects[plr] = nil
            continue
        end

        -- CRIA SOMENTE QUANDO NECESSÁRIO
        if not objects[plr] then
            objects[plr] = {
                box = newSquare(),
                name = newText(13),
                distance = newText(12),
                weapon = newText(12),
                health = newLine()
            }
        end

        local d = objects[plr]

        local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
        local scale = math.clamp(1800 / dist, 8, 300)
        local w, h = scale/2, scale
        local topY = pos.Y - h/2
        local bottomY = pos.Y + h/2

        -- BOX
        if esp.showBox then
            d.box.Size = Vector2.new(w, h)
            d.box.Position = Vector2.new(pos.X - w/2, topY)
            d.box.Color = esp.color
            d.box.Visible = true
        else
            d.box.Visible = false
        end

        -- NAME
        if esp.showName then
            d.name.Text = esp.shortNames and plr.Name:sub(1,12) or plr.Name
            d.name.Position = Vector2.new(pos.X, topY - 14)
            d.name.Color = esp.color
            d.name.Visible = true
        else
            d.name.Visible = false
        end

        -- DISTANCE
        if esp.showDistance then
            d.distance.Text = ("[%dm]"):format(dist)
            d.distance.Position = Vector2.new(pos.X, bottomY + 2)
            d.distance.Color = esp.color
            d.distance.Visible = true
        else
            d.distance.Visible = false
        end

        -- WEAPON
        if esp.showWeapon then
            local tool = getTool(char)
            d.weapon.Text = tool
            d.weapon.Position = Vector2.new(pos.X + w/2 + 6, pos.Y)
            d.weapon.Color = esp.color
            d.weapon.Visible = tool ~= ""
        else
            d.weapon.Visible = false
        end

        -- HEALTH
        if esp.showHealth then
            local hp = hum.Health / hum.MaxHealth
            d.health.From = Vector2.new(pos.X - w/2 - 4, bottomY)
            d.health.To   = Vector2.new(pos.X - w/2 - 4, bottomY - h * hp)
            d.health.Color = Color3.fromRGB(255 - 255*hp, 255*hp, 0)
            d.health.Visible = true
        else
            d.health.Visible = false
        end
    end
end)
-- ======================

Players.PlayerRemoving:Connect(function(plr)
    destroySet(objects[plr])
    objects[plr] = nil
end)

return esp
