--[[ ABILITY ARENA - ULTIMATE OP v4 ]]
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer
local pg = lp.PlayerGui

for _, v in pg:GetChildren() do
    if v:IsA("ScreenGui") and (v.Name == "UltimateOP" or v.Name == "ESP_Overlay") then v:Destroy() end
end

if _G.orbitConns then for _, c in pairs(_G.orbitConns) do c:Disconnect() end; _G.orbitConns = nil end

-- Adonis AC Bypass
do
    local AdonisTables = {}
    local function bypassAC()
        if not getreg or not getgc then return end
        for _, thread in getreg() do
            if typeof(thread) == "thread" then
                local Source = debug.info(thread, 1, "s")
                if Source and (Source:match(".Core.Anti") or Source:match(".Plugins.Anti_Cheat")) then
                    pcall(coroutine.close, thread)
                end
            end
        end
        local Found
        if filtergc then
            Found = filtergc("table", { Keys = { "Detected", "RLocked" } }, false)
        else
            Found = {}
            for _, t in getgc(true) do
                if typeof(t) == "table" and typeof(rawget(t, "Detected")) == "function" and rawget(t, "RLocked") then
                    table.insert(Found, t)
                end
            end
        end
        for _, t in Found do
            if typeof(rawget(t, "Detected")) ~= "function" then continue end
            for _, fn in t do
                if typeof(fn) == "function" and not isfunctionhooked(fn) then
                    hookfunction(fn, function() coroutine.yield(); return task.wait(9e9) end)
                end
            end
        end
    end
    local ok, err = pcall(bypassAC)
    if ok then print("AC Bypass: Active") else warn("AC Bypass: " .. tostring(err)) end
end

local cfg = {
    hitbox = { en = true, sz = 20, op = 0.35 },
    noclip = { en = false }, speed = { en = false, v = 64 }, jump = { en = false, v = 80 },
    loopsy = { en = false }, antiKB = { en = false }, abypass = { en = false },
    spamSkill = { en = false, idx = 1 }, autoM1 = { en = false, range = 25 }, kb = { en = false },
    esp = { en = true },
    orbit = { en = false, dist = 6, spd = 5 },
    autoJoin = { en = false },
}
local orig = {}; local espObjs = {}; local cu = nil; local combatMod = nil; local abilityMod = nil
local orbitTarget = nil; local orbitAngle = 0
local rs = game:GetService("ReplicatedStorage")
local F = rs:FindFirstChild("Files")
local function getDeployEvent()
    local ok, ev = pcall(function()
        return rs.Files.Shared.Components.Jolt.Utils.Remotes.Jolt_Reliable
    end)
    return ok and ev or nil
end

local function gcu()
    if cu then return cu end
    local p = F and F.Shared and F.Shared.Utility and F.Shared.Utility:FindFirstChild("CharacterUtility")
    if p then local ok, m = pcall(require, p); if ok then cu = m; return m end end
end

local function gc()
    if combatMod then return combatMod end
    local p = F and F.Client and F.Client.Controllers and F.Client.Controllers:FindFirstChild("CombatController")
    if p then local ok, m = pcall(require, p); if ok then combatMod = m; return m end end
end

local function ga()
    if abilityMod then return abilityMod end
    local p = F and F.Shared and F.Shared.Managers and F.Shared.Managers:FindFirstChild("AbilityManager")
    if p then local ok, m = pcall(require, p); if ok then abilityMod = m; return m end end
end

-- ESP
local function createESP(p)
    if p.Character then
        local oldHl = p.Character:FindFirstChild("Highlight")
        if oldHl then oldHl:Destroy() end
        local oldBb = p.Character:FindFirstChild("BillboardGui")
        if oldBb then oldBb:Destroy() end
    end
    if p == lp or espObjs[p] then return end
    local function build(c)
        if not c then return end
        local hrp = c:WaitForChild("HumanoidRootPart", 5)
        local hum = c:WaitForChild("Humanoid", 5)
        if not hrp or not hum then return end
        local hl = Instance.new("Highlight")
        hl.Adornee = c; hl.FillColor = Color3.fromRGB(200,20,20); hl.FillTransparency = 0.6
        hl.OutlineColor = Color3.fromRGB(255,30,30); hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = c
        local bb = Instance.new("BillboardGui")
        bb.Adornee = hrp; bb.Size = UDim2.new(0,80,0,50); bb.StudsOffset = Vector3.new(0,4.5,0)
        bb.AlwaysOnTop = true; bb.Parent = c
        local hpT = Instance.new("TextLabel")
        hpT.Size = UDim2.new(1,0,1,0); hpT.BackgroundTransparency = 1; hpT.Font = Enum.Font.GothamBold
        hpT.Text = "100"; hpT.TextColor3 = Color3.fromRGB(255,255,255); hpT.TextSize = 42
        hpT.TextStrokeTransparency = 0.25; hpT.TextStrokeColor3 = Color3.fromRGB(0,0,0)
        hpT.Parent = bb
        espObjs[p] = {hl=hl, bb=bb, ht=hpT, hu=hum, hr=hrp}
    end
    if p.Character then build(p.Character) end
    p.CharacterAdded:Connect(function(c) task.wait(0.5); espObjs[p] = nil; build(c) end)
end

local function updateESP()
    for p, o in pairs(espObjs) do
        if not p.Character or not p.Character.Parent then
            if o.bb then o.bb.Enabled = false end; if o.hl then o.hl.Enabled = false end
        elseif not o.hu or not o.hu.Parent or not o.hr or not o.hr.Parent then
            if o.bb then o.bb:Destroy() end; if o.hl then o.hl:Destroy() end; espObjs[p] = nil
        else
            local en = cfg.esp.en
            if o.bb then o.bb.Enabled = en end; if o.hl then o.hl.Enabled = en end
            if en then
                o.ht.Text = math.floor(o.hu.Health)
                local r = o.hu.Health / math.max(o.hu.MaxHealth, 1)
                if r > 0.6 then o.ht.TextColor3 = Color3.fromRGB(50,220,50)
                elseif r > 0.3 then o.ht.TextColor3 = Color3.fromRGB(255,200,50)
                else o.ht.TextColor3 = Color3.fromRGB(255,50,50) end
            end
        end
    end
end

for _, p in Players:GetPlayers() do
    if p.Character then
        local oldHl = p.Character:FindFirstChild("Highlight"); if oldHl then oldHl:Destroy() end
        local oldBb = p.Character:FindFirstChild("BillboardGui"); if oldBb then oldBb:Destroy() end
    end
    createESP(p)
end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p) if espObjs[p] then espObjs[p] = nil end end)

-- Cooldown bypass
local function bc()
    if not cfg.abypass.en or not lp.Character then return end
    local m = gcu(); if not m then return end
    local d = m.GetCharacterData(lp.Character)
    if d then d.Timestamps = {}; if d.PersistentData and d.PersistentData.Timestamps then d.PersistentData.Timestamps = {} end end
end

-- Skill spam
local st = 0
local function ss(dt)
    if not cfg.spamSkill.en or not lp.Character then return end
    local am = ga(); if not am then return end
    local ab = am.GetAbility(lp.Character); if not ab or not ab.Order then return end
    st = st + dt; if st < 0.3 then return end; st = 0
    local sk = am.GetSkills(lp.Character); if not sk then return end
    local sn = ab.Order[cfg.spamSkill.idx]
    if sn and sk[sn] then
        local m = gcu(); if m then local d = m.GetCharacterData(lp.Character); if d then d.Timestamps = {} end end
        local ok, r = pcall(am.StartSkill, am, lp.Character, sn)
        if ok and r then cfg.spamSkill.idx = cfg.spamSkill.idx + 1; if cfg.spamSkill.idx > #ab.Order then cfg.spamSkill.idx = 1 end end
    end
end

-- Hitbox
local function sh()
    if not cfg.hitbox.en then return end
    for _, p in Players:GetPlayers() do
        if p ~= lp and p.Character then
            local hb = p.Character:FindFirstChild("Hitbox")
            if hb and hb:IsA("BasePart") then
                if not orig[p] then orig[p] = hb.Size end
                hb.Size = Vector3.new(cfg.hitbox.sz,cfg.hitbox.sz,cfg.hitbox.sz)
                hb.Transparency = cfg.hitbox.op; hb.Color = Color3.fromRGB(255,50,50); hb.Material = Enum.Material.ForceField
            end
        end
    end
end

-- Anti-KB
local prevVel = Vector3.new()
local function ak()
    if not cfg.antiKB.en or not lp.Character then return end
    local hrp = lp.Character:FindFirstChild("HumanoidRootPart"); local hum = lp.Character:FindFirstChild("Humanoid"); local m = gcu()
    if not m or not hrp or not hum then return end
    if m.GetState(lp.Character) == "Ragdoll" then
        m.SetState(lp.Character, "Free"); hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false); hum:ChangeState(Enum.HumanoidStateType.Running)
    end
    local vel = hrp.AssemblyLinearVelocity
    local currentWS = hum.WalkSpeed
    local threshold = math.max(currentWS * 2, 50)
    if vel.Magnitude > threshold then
        hrp.AssemblyLinearVelocity = Vector3.new(vel.X * 0.3, 0, vel.Z * 0.3)
    end
end

-- Speed+Jump
local function sj()
    if not lp.Character then return end
    local hum = lp.Character:FindFirstChild("Humanoid"); if not hum then return end
    if cfg.speed.en then hum.WalkSpeed = cfg.speed.v end; if cfg.jump.en then hum.JumpHeight = cfg.jump.v end
end
local function ls() if cfg.loopsy.en and lp.Character then local hum = lp.Character:FindFirstChild("Humanoid"); if hum then hum.WalkSpeed = cfg.speed.v end end end

-- Auto M1
local amt = 0
local function am1(dt)
    if not cfg.autoM1.en or not lp.Character then return end
    local hum = lp.Character:FindFirstChild("Humanoid"); local hrp = lp.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then return end
    amt = amt + dt; if amt < 0.12 then return end; amt = 0
    local near, nd = nil, cfg.autoM1.range
    for _, p in Players:GetPlayers() do
        if p ~= lp and p.Character then
            local t = p.Character:FindFirstChild("HumanoidRootPart"); local th = p.Character:FindFirstChild("Humanoid")
            if t and th and th.Health > 0 then local d = (hrp.Position - t.Position).Magnitude; if d < nd then near = p; nd = d end end
        end
    end
    if near and near.Character then
        local thrp = near.Character:FindFirstChild("HumanoidRootPart")
        if thrp then hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(thrp.Position.X, hrp.Position.Y, thrp.Position.Z)) end
        local cm = gc(); if cm then pcall(function() cm.UseM1(cm) end) end
    end
end

-- Auto Orbit (orbit until 1 HP, then switch)
local orbitAttackT = 0
local function ao(dt)
    if not cfg.orbit.en or not lp.Character then
        if orbitTarget then orbitTarget = nil; orbitAngle = 0 end
        return
    end
    local hrp = lp.Character:FindFirstChild("HumanoidRootPart")
    local hum = lp.Character:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then orbitTarget = nil; return end
    if orbitTarget and orbitTarget.Character then
        local thrp = orbitTarget.Character:FindFirstChild("HumanoidRootPart")
        local thum = orbitTarget.Character:FindFirstChild("Humanoid")
        if not thrp or not thum or thum.Health <= 1 then orbitTarget = nil end
    end
    if not orbitTarget then
        local best, bestHp = nil, math.huge
        for _, p in Players:GetPlayers() do
            if p ~= lp and p.Character then
                local thrp = p.Character:FindFirstChild("HumanoidRootPart")
                local thum = p.Character:FindFirstChild("Humanoid")
                if thrp and thum and thum.Health > 0 and thum.Health < bestHp then
                    best, bestHp = p, thum.Health
                end
            end
        end
        orbitTarget = best; orbitAngle = 0
    end
    if not orbitTarget or not orbitTarget.Character then return end
    local thrp = orbitTarget.Character:FindFirstChild("HumanoidRootPart")
    if not thrp then orbitTarget = nil; return end
    orbitAngle = (orbitAngle + dt * cfg.orbit.spd * 60) % 360
    hrp.CFrame = CFrame.new(thrp.Position) * CFrame.Angles(0, math.rad(orbitAngle), 0) * CFrame.new(cfg.orbit.dist, 0, 0)
    hrp.CFrame = CFrame.new(hrp.Position, thrp.Position)
    -- Attack while orbiting
    orbitAttackT = orbitAttackT + dt
    if orbitAttackT >= 0.15 then
        orbitAttackT = 0
        local cm = gc()
        if cm then pcall(function() cm.UseM1(cm) end) end
    end
end

-- Auto Join Match
local ajt = 0
local function aj(dt)
    if not cfg.autoJoin.en then return end
    if lp.Character then return end
    ajt = ajt + dt; if ajt < 1 then return end; ajt = 0
    local ev = getDeployEvent()
    if ev then
        pcall(function()
            ev:FireServer(buffer.fromstring("\x06Deploy\x81\x11\x00"), {})
        end)
    end
end

-- Frame hooks
RunService.Heartbeat:Connect(function() sh(); updateESP() end)
RunService.Stepped:Connect(function() sh(); ls(); bc() end)
RunService.RenderStepped:Connect(function(dt)
    sh(); sj(); ls(); am1(dt); ak(); bc(); ss(dt); ao(dt); aj(dt)
    if cfg.noclip.en and lp.Character then for _, v in lp.Character:GetDescendants() do if v:IsA("BasePart") then v.CanCollide = false end end end
    if lp.Character then local hb = lp.Character:FindFirstChild("Hitbox"); if hb and hb:IsA("BasePart") and hb.Size.X > 5 then hb.Size = Vector3.new(4,6,2); hb.Transparency = 1; hb.Material = Enum.Material.Plastic end end
end)

-- GUI
local sg = Instance.new("ScreenGui")
sg.Name = "UltimateOP"; sg.ResetOnSpawn = false; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; sg.Parent = pg
local f = Instance.new("Frame")
f.Size = UDim2.new(0,240,0,580); f.Position = UDim2.new(0,25,0,80)
f.BackgroundColor3 = Color3.fromRGB(12,12,12); f.BackgroundTransparency = 0.15; f.BorderSizePixel = 0; f.Active = true; f.Parent = sg
local fic = Instance.new("UICorner"); fic.CornerRadius = UDim.new(0,10); fic.Parent = f
local tb = Instance.new("Frame")
tb.Size = UDim2.new(1,0,0,30); tb.BackgroundColor3 = Color3.fromRGB(30,30,30); tb.BackgroundTransparency = 0.3
tb.BorderSizePixel = 0; tb.Active = true; tb.Draggable = true; tb.Parent = f
local tic = Instance.new("UICorner"); tic.CornerRadius = UDim.new(0,10); tic.Parent = tb
local ttl = Instance.new("TextLabel")
ttl.Size = UDim2.new(1,-40,1,0); ttl.Position = UDim2.new(0,10,0,0); ttl.BackgroundTransparency = 1
ttl.Text = "ULTIMATE OP v4"; ttl.TextColor3 = Color3.fromRGB(255,60,60); ttl.TextSize = 15; ttl.Font = Enum.Font.GothamBold; ttl.TextXAlignment = Enum.TextXAlignment.Left; ttl.Parent = tb
local hbB = Instance.new("TextButton")
hbB.Size = UDim2.new(0,22,0,22); hbB.Position = UDim2.new(1,-26,0,4); hbB.BackgroundColor3 = Color3.fromRGB(60,60,60)
hbB.Text = "X"; hbB.TextColor3 = Color3.fromRGB(200,200,200); hbB.TextSize = 12; hbB.Font = Enum.Font.GothamBold; hbB.BorderSizePixel = 0; hbB.Parent = tb
local hic = Instance.new("UICorner"); hic.CornerRadius = UDim.new(0,4); hic.Parent = hbB

local td = {
    {k="hitbox", l="Hitbox Expander [X]", c=Color3.fromRGB(255,70,70)},
    {k="esp", l="ESP Wallhack", c=Color3.fromRGB(255,30,30)},
    {k="noclip", l="NoClip [C]", c=Color3.fromRGB(70,130,255)},
    {k="speed", l="Speed Boost", c=Color3.fromRGB(70,200,70)},
    {k="loopsy", l="Loop Speed", c=Color3.fromRGB(50,230,100)},
    {k="jump", l="Jump Boost", c=Color3.fromRGB(70,220,220)},
    {k="antiKB", l="Anti Knockback", c=Color3.fromRGB(255,180,50)},
    {k="abypass", l="Cooldown Bypass", c=Color3.fromRGB(255,100,255)},
    {k="spamSkill", l="Spam Skills", c=Color3.fromRGB(200,50,200)},
    {k="autoM1", l="Auto M1 Attack", c=Color3.fromRGB(200,70,200)},
    {k="kb", l="Remove KillBricks", c=Color3.fromRGB(255,140,70)},
    {k="orbit", l="Auto Orbit", c=Color3.fromRGB(255,100,50)},
    {k="autoJoin", l="Auto Join Match", c=Color3.fromRGB(50,200,255)},
}
local y = 42; local refs = {}
for _, t in ipairs(td) do
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1,-20,0,28); r.Position = UDim2.new(0,10,0,y); r.BackgroundTransparency = 1; r.Parent = f
    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(0,145,1,0); lb.BackgroundTransparency = 1; lb.Text = t.l; lb.TextColor3 = Color3.fromRGB(200,200,200)
    lb.TextSize = 12; lb.Font = Enum.Font.Gotham; lb.TextXAlignment = Enum.TextXAlignment.Left; lb.Parent = r
    local on = cfg[t.k].en
    local bn = Instance.new("TextButton")
    bn.Size = UDim2.new(0,46,0,22); bn.Position = UDim2.new(1,-50,0.5,-11)
    bn.BackgroundColor3 = on and t.c or Color3.fromRGB(50,50,50); bn.Text = on and "ON" or "OFF"
    bn.TextColor3 = on and Color3.fromRGB(255,255,255) or Color3.fromRGB(150,150,150); bn.TextSize = 11; bn.Font = Enum.Font.GothamBold; bn.BorderSizePixel = 0; bn.Parent = r
    local bnc = Instance.new("UICorner"); bnc.CornerRadius = UDim.new(0,4); bnc.Parent = bn
    bn.MouseButton1Click:Connect(function()
        local k = t.k; cfg[k].en = not cfg[k].en; local on2 = cfg[k].en
        bn.BackgroundColor3 = on2 and t.c or Color3.fromRGB(50,50,50)
        bn.Text = on2 and "ON" or "OFF"; bn.TextColor3 = on2 and Color3.fromRGB(255,255,255) or Color3.fromRGB(150,150,150)
        if k == "noclip" and lp.Character then for _, v in lp.Character:GetDescendants() do if v:IsA("BasePart") then v.CanCollide = not on2 end end end
        if k == "kb" then local ff = workspace:FindFirstChild("KillBricks"); if ff then for _, v in ff:GetChildren() do if v:IsA("BasePart") then v.Anchored = false; v.CanCollide = false; v.Transparency = 1 end end end end
        if not on2 and k == "hitbox" then for p, s in next, orig do if p.Character then local h = p.Character:FindFirstChild("Hitbox"); if h then h.Size = s; h.Transparency = 1; h.Material = Enum.Material.Plastic; h.Color = Color3.fromRGB(163,162,165) end end end; orig = {} end
        if not on2 and k == "orbit" then orbitTarget = nil; orbitAngle = 0 end
    end)
    y = y + 32; refs[t.k] = bn
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.X then
        local k = "hitbox"; cfg[k].en = not cfg[k].en; local o = cfg[k].en; local b = refs[k]
        b.BackgroundColor3 = o and Color3.fromRGB(255,70,70) or Color3.fromRGB(50,50,50)
        b.Text = o and "ON" or "OFF"; b.TextColor3 = o and Color3.fromRGB(255,255,255) or Color3.fromRGB(150,150,150)
        if not o then for p, s in next, orig do if p.Character then local h = p.Character:FindFirstChild("Hitbox"); if h then h.Size = s; h.Transparency = 1; h.Material = Enum.Material.Plastic; h.Color = Color3.fromRGB(163,162,165) end end end; orig = {} end
    end
    if input.KeyCode == Enum.KeyCode.C then
        local k = "noclip"; cfg[k].en = not cfg[k].en; local o = cfg[k].en; local b = refs[k]
        b.BackgroundColor3 = o and Color3.fromRGB(70,130,255) or Color3.fromRGB(50,50,50)
        b.Text = o and "ON" or "OFF"; b.TextColor3 = o and Color3.fromRGB(255,255,255) or Color3.fromRGB(150,150,150)
        if lp.Character then for _, v in lp.Character:GetDescendants() do if v:IsA("BasePart") then v.CanCollide = not o end end end
    end
end)

local hidden = false
hbB.MouseButton1Click:Connect(function() hidden = not hidden; f.Visible = not hidden; hbB.Text = hidden and "+" or "X" end)

for _, p in Players:GetPlayers() do if p.Character and p ~= lp then local h = p.Character:FindFirstChild("Hitbox"); if h then orig[p] = h.Size end end end
lp.CharacterAdded:Connect(function() task.wait(0.5); if cfg.noclip.en and lp.Character then for _, v in lp.Character:GetDescendants() do if v:IsA("BasePart") then v.CanCollide = false end end end end)
lp.CharacterRemoving:Connect(function()
    if cfg.autoJoin.en then
        task.wait(0.5)
        local ev = getDeployEvent()
        if ev then pcall(function() ev:FireServer(buffer.fromstring("\x06Deploy\x81\x11\x00"), {}) end) end
    end
end)
