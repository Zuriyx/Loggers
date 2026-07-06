local sgui = game:GetService("CoreGui")
local rs = game:GetService("ReplicatedStorage")
local uis = game:GetService("UserInputService")
local lp = game:GetService("Players").LocalPlayer

if sgui:FindFirstChild("WinRAR_VFX") then sgui.WinRAR_VFX:Destroy() end

local main_gui = Instance.new("ScreenGui", sgui)
main_gui.Name = "WinRAR_VFX"
main_gui.ResetOnSpawn = false

local theme = {
    bg = Color3.fromRGB(240, 240, 240),
    title = Color3.fromRGB(0, 0, 170),
    white = Color3.fromRGB(255, 255, 255),
    border = Color3.fromRGB(160, 160, 160),
    text = Color3.fromRGB(0, 0, 0),
    sel = Color3.fromRGB(0, 120, 215)
}

local function create(class, props, parent)
    local obj = Instance.new(class)
    for i, v in pairs(props) do obj[i] = v end
    obj.Parent = parent
    return obj
end

local function drag(obj, move_obj)
    move_obj = move_obj or obj
    local dragging, input, startPos, startInput
    obj.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startInput = i.Position
            startPos = move_obj.Position
        end
    end)
    uis.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local delta = i.Position - startInput
            move_obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    uis.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function get_safe_path(obj)
    local path = "game"
    local parts = obj:GetFullName():split(".")
    for i, name in ipairs(parts) do
        if name:match("^%d") or name:find(" ") or name:find("[^%w_]") then
            path = path .. '["' .. name .. '"]'
        else
            path = path .. "." .. name
        end
    end
    return path
end

local function val_str(v)
    local t = typeof(v)
    if t == "string" then return "'" .. v:gsub("'", "\\'") .. "'" end
    if t == "Vector3" then return "Vector3.new("..v.X..","..v.Y..","..v.Z..")" end
    if t == "Vector2" then return "Vector2.new("..v.X..","..v.Y..")" end
    if t == "Color3" then return "Color3.new("..v.R..","..v.G..","..v.B..")" end
    if t == "NumberRange" then return "NumberRange.new("..v.Min..","..v.Max..")" end
    if t == "EnumItem" then return tostring(v) end
    if t == "NumberSequence" then
        local s = "NumberSequence.new({"
        for _, k in ipairs(v.Keypoints) do
            s = s .. "NumberSequenceKeypoint.new("..k.Time..","..k.Value..","..k.Envelope.."),"
        end
        return s:sub(1,-2) .. "})"
    end
    if t == "ColorSequence" then
        local s = "ColorSequence.new({"
        for _, k in ipairs(v.Keypoints) do
            s = s .. "ColorSequenceKeypoint.new("..k.Time..",Color3.new("..k.Value.R..","..k.Value.G..","..k.Value.B..")),"
        end
        return s:sub(1,-2) .. "})"
    end
    if t == "boolean" or t == "number" then return tostring(v) end
    return tostring(v)
end

local function get_univ(obj)
    local c = "local p = Instance.new('Part')\np.Anchored = true\np.CanCollide = false\np.Transparency = 1\np.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-5)\np.Parent = workspace\nlocal a0 = Instance.new('Attachment', p)\n"
    local count = 0

    local function process(v, par)
        if v:IsA("Attachment") then
            count = count + 1
            local av = "a" .. count
            c = c .. "local " .. av .. " = Instance.new('Attachment', " .. par .. ")\n"
            c = c .. av .. ".Position = " .. val_str(v.Position) .. "\n"
            c = c .. av .. ".Orientation = " .. val_str(v.Orientation) .. "\n"
            return av
        elseif v:IsA("ParticleEmitter") then
            count = count + 1
            local ev = "e" .. count
            c = c .. "local " .. ev .. " = Instance.new('ParticleEmitter', " .. par .. ")\n"
            local props = {"Name", "Texture", "Color", "Size", "Transparency", "ZOffset", "EmissionDirection", "Lifetime", "Rate", "Speed", "Rotation", "RotSpeed", "SpreadAngle", "Acceleration", "Drag", "LockedToPart", "LightEmission", "LightInfluence", "Orientation", "Squash", "Shape", "ShapeInOut", "ShapeStyle", "FlipbookMode", "FlipbookFramerate", "FlipbookLayout", "TimeScale", "Brightness"}
            for _, p in ipairs(props) do
                pcall(function()
                    local val = v[p]
                    if val ~= nil then
                        c = c .. ev .. "." .. p .. " = " .. val_str(val) .. "\n"
                    end
                end)
            end
            c = c .. ev .. ":Emit(50)\n"
        elseif v:IsA("PointLight") or v:IsA("SurfaceLight") or v:IsA("SpotLight") then
            count = count + 1
            local lv = "l" .. count
            c = c .. "local " .. lv .. " = Instance.new('"..v.ClassName.."', " .. par .. ")\n"
            local props = {"Color", "Range", "Brightness", "Shadows", "Angle", "Face"}
            for _, p in ipairs(props) do
                pcall(function()
                    local val = v[p]
                    if val ~= nil then
                        c = c .. lv .. "." .. p .. " = " .. val_str(val) .. "\n"
                    end
                end)
            end
        end
        return par
    end

    local function scan(n, par)
        local new_par = process(n, par)
        for _, child in ipairs(n:GetChildren()) do
            scan(child, new_par)
        end
    end

    if obj:IsA("Folder") or obj:IsA("Model") or obj:IsA("BasePart") then
        for _, child in ipairs(obj:GetChildren()) do
            scan(child, "a0")
        end
    else
        scan(obj, "a0")
    end

    return c
end

local toggle = create("TextButton", {
    Size = UDim2.new(0, 45, 0, 45),
    Position = UDim2.new(0, 15, 0, 15),
    BackgroundColor3 = theme.bg,
    BorderColor3 = theme.border,
    Text = "RAR",
    TextColor3 = theme.text,
    Font = "ArialBold",
    TextSize = 13
}, main_gui)
drag(toggle)

local main = create("Frame", {
    Size = UDim2.new(0, 480, 0, 360),
    Position = UDim2.new(0.5, -240, 0.5, -180),
    BackgroundColor3 = theme.bg,
    BorderColor3 = theme.border,
    BorderSizePixel = 1,
    Visible = false
}, main_gui)

local top = create("Frame", {Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = theme.title, BorderSizePixel = 0}, main)
create("TextLabel", {Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, Text = "WinRAR - VFX Explorer", TextColor3 = theme.white, Font = "ArialBold", TextSize = 12, TextXAlignment = "Left"}, top)
drag(top, main)
toggle.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

local tb = create("Frame", {Size = UDim2.new(1, 0, 0, 50), Position = UDim2.new(0, 0, 0, 22), BackgroundColor3 = theme.bg, BorderColor3 = theme.border, BorderSizePixel = 1}, main)
local lay = create("UIListLayout", {FillDirection = "Horizontal", Padding = UDim.new(0, 2)}, tb)

local function btn(icon, txt, p, cb)
    local b = create("TextButton", {Size = UDim2.new(0, 55, 1, 0), BackgroundTransparency = 1, Text = ""}, p)
    create("TextLabel", {Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0,0,0,2), BackgroundTransparency = 1, Text = icon, TextSize = 22, Font = "Arial"}, b)
    create("TextLabel", {Size = UDim2.new(1, 0, 0, 15), Position = UDim2.new(0,0,0,32), BackgroundTransparency = 1, Text = txt, TextSize = 11, Font = "Arial", TextColor3 = theme.text}, b)
    b.MouseButton1Click:Connect(cb)
    return b
end

local addr = create("Frame", {Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 0, 0, 72), BackgroundColor3 = theme.bg, BorderSizePixel = 0}, main)
create("TextLabel", {Size = UDim2.new(0, 55, 1, 0), BackgroundTransparency = 1, Text = " Address:", TextSize = 12, Font = "Arial", TextColor3 = theme.text, TextXAlignment = "Left"}, addr)
local sInput = create("TextBox", {Size = UDim2.new(1, -65, 0, 19), Position = UDim2.new(0, 60, 0, 3), BackgroundColor3 = theme.white, BorderColor3 = theme.border, Text = "", TextColor3 = theme.text, TextXAlignment = "Left", Font = "Arial", TextSize = 12, ClearTextOnFocus = false}, addr)

local explorer = create("ScrollingFrame", {Size = UDim2.new(1, -10, 1, -107), Position = UDim2.new(0, 5, 0, 102), BackgroundColor3 = theme.white, BorderColor3 = theme.border, BorderSizePixel = 1, ScrollBarThickness = 14, CanvasSize = UDim2.new(0, 0, 0, 0)}, main)
local list = create("UIListLayout", {Padding = UDim.new(0, 0)}, explorer)

local sel = nil
local path = rs
local spawned = {}

local function get_ico(obj)
    local n = obj.Name:lower()
    if obj:IsA("Folder") or obj:IsA("Configuration") or #obj:GetChildren() > 0 then return "📁" end
    if obj:IsA("Model") or obj:IsA("MeshPart") or n:match("human") or n:match("mesh") then return "📦" end
    if obj:IsA("ParticleEmitter") or obj:IsA("Attachment") then return "✨" end
    return "📄"
end

local function run(obj, is_folder)
    if not obj or not lp.Character then return end
    local hrp = lp.Character.HumanoidRootPart
    local base_cf = hrp.CFrame * CFrame.new(0, 0, -8)

    local function setup(o, cf)
        local cl = o:Clone()
        if cl:IsA("Model") or cl:IsA("BasePart") then
            cl.Parent = workspace
            if cl:IsA("Model") then cl:PivotTo(cf) else cl.CFrame = cf end
            for _, v in ipairs(cl:GetDescendants()) do
                if v:IsA("BasePart") then v.Anchored = true end
                if v:IsA("ParticleEmitter") then v:Emit(50) end
            end
            table.insert(spawned, cl)
        else
            local at = cl:IsA("Attachment") and cl or Instance.new("Attachment", hrp)
            if cl:IsA("ParticleEmitter") then cl.Parent = at end
            at.Parent = hrp; at.Position = (cf.Position - hrp.Position)
            if cl:IsA("ParticleEmitter") then cl:Emit(50) end
            table.insert(spawned, at)
        end
    end

    if is_folder then
        for i, child in ipairs(obj:GetChildren()) do
            setup(child, base_cf * CFrame.new((i-1) * 5, 0, 0))
        end
    else
        setup(obj, base_cf)
    end
end

local function render(alt)
    for _, v in ipairs(explorer:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    local items = alt or path:GetChildren()

    if path ~= rs and not alt then
        local b = create("TextButton", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "  📁 ..", TextColor3 = theme.text, Font = "Arial", TextSize = 12, TextXAlignment = "Left"}, explorer)
        b.MouseButton1Click:Connect(function() sInput.Text = "" path = path.Parent render() end)
    end

    for _, i in ipairs(items) do
        local b = create("TextButton", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "  " .. get_ico(i) .. " " .. i.Name, TextColor3 = theme.text, Font = "Arial", TextSize = 12, TextXAlignment = "Left"}, explorer)
        b.MouseButton1Click:Connect(function()
            sel = i
            sInput.Text = get_safe_path(i)
            for _, v in ipairs(explorer:GetChildren()) do if v:IsA("TextButton") then v.BackgroundColor3 = theme.white v.BackgroundTransparency = 1 v.TextColor3 = theme.text end end
            b.BackgroundTransparency = 0
            b.BackgroundColor3 = theme.sel
            b.TextColor3 = theme.white

            if b:GetAttribute("C") then
                sInput.Text = ""
                path = i
                render()
            else
                b:SetAttribute("C", true)
                task.delay(0.35, function() b:SetAttribute("C", nil) end)
            end
        end)
    end
    explorer.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y)
end

sInput.FocusLost:Connect(function(enter)
    if enter then
        local q = sInput.Text:lower()
        if q == "" then render() return end
        local res = {}
        for _, i in ipairs(path:GetChildren()) do
            if i.Name:lower():find(q) then table.insert(res, i) end
        end
        render(res)
    end
end)

btn("⚡", "Play", tb, function() run(sel, false) end)
btn("📂", "Play Dir", tb, function() run(sel, true) end)
btn("📋", "Script", tb, function()
    if not sel or not setclipboard then return end
    setclipboard("local s = " .. get_safe_path(sel) .. "\nlocal h = game.Players.LocalPlayer.Character.HumanoidRootPart\nlocal cf = h.CFrame * CFrame.new(0, 0, -8)\nlocal cl = s:Clone()\nif cl:IsA('Model') or cl:IsA('BasePart') then\n    cl.Parent = workspace\n    if cl:IsA('Model') then cl:PivotTo(cf) else cl.CFrame = cf end\n    for _,v in ipairs(cl:GetDescendants()) do\n        if v:IsA('BasePart') then v.Anchored = true end\n        if v:IsA('ParticleEmitter') then v:Emit(50) end\n    end\nelse\n    local a = cl:IsA('Attachment') and cl or Instance.new('Attachment', h)\n    if cl:IsA('ParticleEmitter') then cl.Parent = a end\n    a.Parent = h\n    a.Position = Vector3.zero\n    if cl:IsA('ParticleEmitter') then cl:Emit(50) end\nend")
end)
btn("🔗", "Path", tb, function()
    if sel and setclipboard then setclipboard(get_safe_path(sel)) end
end)
btn("🌐", "Universal", tb, function()
    if sel and setclipboard then setclipboard(get_univ(sel)) end
end)
btn("❌", "Delete", tb, function()
    for _, i in ipairs(spawned) do if i then i:Destroy() end end
    spawned = {}
end)

pcall(render)
