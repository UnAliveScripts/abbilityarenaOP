--[[ ABILITY ARENA ULTIMATE OP v6.5 ]]
-- Health lock, IFrame bypass, Tween orbit, Lobby filter, ESP, hitbox, anti-KB, cooldown bypass, auto M1, skill spam, killbrick removal, auto join

local plr=game:GetService("Players").LocalPlayer
local RS=game:GetService("RunService")
local TS=game:GetService("TweenService")
local F=game:GetService("ReplicatedStorage"):FindFirstChild("Files")
local pg=plr.PlayerGui

for _,v in pg:GetChildren()do if v:IsA("ScreenGui")and v.Name=="UltimateOP"then v:Destroy()end end

-- Health lock every frame
RS.Heartbeat:Connect(function()
    if plr.Character then
        local h=plr.Character:FindFirstChildWhichIsA("Humanoid")
        if h and h.Parent then h.BreakJointsOnDeath=false;h.Health=100 end
    end
end)

-- Utility functions
local gu=function()
    local p=F and F.Shared and F.Shared.Utility and F.Shared.Utility:FindFirstChild("CharacterUtility")
    if p then local o,m=pcall(require,p);if o then return m end end
end

local gc=function()
    local p=F and F.Client and F.Client.Controllers and F.Client.Controllers:FindFirstChild("CombatController")
    if p then local o,m=pcall(require,p);if o then return m end end
end

local ga=function()
    local p=F and F.Shared and F.Shared.Managers and F.Shared.Managers:FindFirstChild("AbilityManager")
    if p then local o,m=pcall(require,p);if o then return m end end
end

-- IFrame invulnerability
local IF=function(c)
    if not c then return end
    local u=gu()
    if u and not u.HasStatusEffect(c,"IFrame")then u.AddStatusEffect(c,"IFrame",{},nil)end
end

-- Map bounds check (only target players inside Workspace.Map)
local mapMin,mapMax=nil,nil
local function calcMapBounds()
    local map=workspace:FindFirstChild("Map")
    if not map then return end
    local mn,mx
    for _,v in map:GetDescendants()do
        if v:IsA("BasePart")then
            local cf=v.CFrame;local sz=v.Size/2
            local corners={cf*CFrame.new(-sz.X,-sz.Y,-sz.Z),cf*CFrame.new(sz.X,-sz.Y,-sz.Z),cf*CFrame.new(-sz.X,sz.Y,-sz.Z),cf*CFrame.new(sz.X,sz.Y,-sz.Z),cf*CFrame.new(-sz.X,-sz.Y,sz.Z),cf*CFrame.new(sz.X,-sz.Y,sz.Z),cf*CFrame.new(-sz.X,sz.Y,sz.Z),cf*CFrame.new(sz.X,sz.Y,sz.Z)}
            for _,c in corners do local p=c.Position;if not mn then mn,mx=p,p else mn=Vector3.new(math.min(mn.X,p.X),math.min(mn.Y,p.Y),math.min(mn.Z,p.Z));mx=Vector3.new(math.max(mx.X,p.X),math.max(mx.Y,p.Y),math.max(mx.Z,p.Z))end end
        end
    end
    mapMin=mn;mapMax=mx
end
calcMapBounds()

-- Check if position is inside map bounds (fast, no function call)
local mm,MM=mapMin,mapMax
local cl=function()
    local b,bd=nil,math.huge
    if not plr.Character then return nil end
    local mp=plr.Character:FindFirstChild("HumanoidRootPart")
    if not mp then return nil end
    mp=mp.Position
    for _,p in game.Players:GetPlayers()do
        if p~=plr and p.Character then
            local r=p.Character:FindFirstChild("HumanoidRootPart")
            local h=p.Character:FindFirstChild("Humanoid")
            if r and h and h.Health>0 then
                local pos=r.Position
                -- Fast map bounds check inline (no function call)
                if mm and MM and pos.X>=mm.X and pos.X<=MM.X and pos.Y>=mm.Y and pos.Y<=MM.Y and pos.Z>=mm.Z and pos.Z<=MM.Z then
                    local d=(mp-pos).Magnitude
                    if d<bd then b,bd=p,d end
                end
            end
        end
    end
    return b,bd
end

-- Config
local cfg={
    hitbox={en=true,sz=20,op=0.35},
    noclip={en=false},
    speed={en=false,v=64},
    jump={en=false,v=80},
    loopsy={en=false},
    antiKB={en=false},
    abypass={en=false},
    spamSkill={en=false,idx=1},
    autoM1={en=false,range=25},
    kb={en=false},
    esp={en=true},
    orbit={en=false,dist=6,spd=5},
    autoJoin={en=false}
}

local orig={}
local esp={}
local ot=nil;local oa=0;local tw=nil
local at=0;local st=0;local mt=0;local jt=0

-- Cooldown bypass
local bc=function()
    if not cfg.abypass.en or not plr.Character then return end
    local m=gu();if not m then return end
    local d=m.GetCharacterData(plr.Character)
    if d then d.Timestamps={};if d.PersistentData and d.PersistentData.Timestamps then d.PersistentData.Timestamps={}end end
end

-- Skill spam
local ss=function(dt)
    if not cfg.spamSkill.en or not plr.Character then return end
    local a=ga();if not a then return end
    local ab=a.GetAbility(plr.Character);if not ab or not ab.Order then return end
    st=st+dt;if st<0.3 then return end;st=0
    local sk=a.GetSkills(plr.Character);if not sk then return end
    local sn=ab.Order[cfg.spamSkill.idx]
    if sn and sk[sn]then
        local m=gu();if m then local d=m.GetCharacterData(plr.Character);if d then d.Timestamps={}end end
        local ok,r=pcall(a.StartSkill,a,plr.Character,sn)
        if ok and r then cfg.spamSkill.idx=cfg.spamSkill.idx+1;if cfg.spamSkill.idx>#ab.Order then cfg.spamSkill.idx=1 end end
    end
end

-- Hitbox expander
local sh=function()
    if not cfg.hitbox.en then return end
    for _,p in game.Players:GetPlayers()do
        if p~=plr and p.Character then
            local h=p.Character:FindFirstChild("Hitbox")
            if h and h:IsA("BasePart")then
                if not orig[p]then orig[p]=h.Size end
                h.Size=Vector3.new(cfg.hitbox.sz,cfg.hitbox.sz,cfg.hitbox.sz)
                h.Transparency=cfg.hitbox.op;h.Color=Color3.fromRGB(255,50,50);h.Material=Enum.Material.ForceField
            end
        end
    end
end

-- Anti knockback
local ak=function()
    if not cfg.antiKB.en or not plr.Character then return end
    local r=plr.Character:FindFirstChild("HumanoidRootPart");local h=plr.Character:FindFirstChild("Humanoid");local m=gu()
    if not m or not r or not h then return end
    if m.GetState(plr.Character)=="Ragdoll"then
        pcall(m.SetState,m,plr.Character,"Free")
        pcall(function()h:SetStateEnabled(Enum.HumanoidStateType.Physics,false)h:ChangeState(Enum.HumanoidStateType.Running)end)
    end
    local v=r.AssemblyLinearVelocity;local t=math.max(h.WalkSpeed*2,50)
    if v.Magnitude>t then r.AssemblyLinearVelocity=Vector3.new(v.X*0.3,0,v.Z*0.3)end
end

-- Speed / Jump
local sj=function()
    if not plr.Character then return end;local h=plr.Character:FindFirstChild("Humanoid")
    if not h then return end
    if cfg.speed.en then h.WalkSpeed=cfg.speed.v end
    if cfg.jump.en then h.JumpHeight=cfg.jump.v end
end
local ls=function()
    if cfg.loopsy.en and plr.Character then
        local h=plr.Character:FindFirstChild("Humanoid")
        if h then h.WalkSpeed=cfg.speed.v end
    end
end

-- Auto M1 (only targets players in map)
local am1=function(dt)
    if not cfg.autoM1.en or not plr.Character then return end
    local h=plr.Character:FindFirstChild("Humanoid");local r=plr.Character:FindFirstChild("HumanoidRootPart")
    if not h or not r or h.Health<=0 then return end
    mt=mt+dt;if mt<0.12 then return end;mt=0
    local n,nd=nil,cfg.autoM1.range
    for _,p in game.Players:GetPlayers()do
        if p~=plr and p.Character then
            local t=p.Character:FindFirstChild("HumanoidRootPart");local th=p.Character:FindFirstChild("Humanoid")
            if t and th and th.Health>0 and mm and MM then
                local pos=t.Position
                if pos.X>=mm.X and pos.X<=MM.X and pos.Y>=mm.Y and pos.Y<=MM.Y and pos.Z>=mm.Z and pos.Z<=MM.Z then
                    local d=(r.Position-pos).Magnitude;if d<nd then n=p;nd=d end
                end
            end
        end
    end
    if n and n.Character then
        local t=n.Character:FindFirstChild("HumanoidRootPart")
        if t then r.CFrame=CFrame.lookAt(r.Position,Vector3.new(t.Position.X,r.Position.Y,t.Position.Z))end
        local c=gc();if c then pcall(function()c.UseM1(c)end)end
    end
end

-- ADVANCED ORBIT: tween approach at 200 studs/s, orbit when close
local ao=function(dt)
    if not cfg.orbit.en then ot=nil;oa=0;if tw then tw:Cancel()tw=nil end;return end
    if not plr.Character then ot=nil;return end
    local r=plr.Character:FindFirstChild("HumanoidRootPart");local h=plr.Character:FindFirstChild("Humanoid")
    if not r or not h or h.Health<=0 then ot=nil;return end

    h.BreakJointsOnDeath=false;h.Health=100;IF(plr.Character)

    -- Force Free state
    local m=gu()
    if m then
        local s=m.GetState(plr.Character)
        if s=="Ragdoll"or s=="Dying"then
            pcall(m.SetState,m,plr.Character,"Free")
            pcall(function()h:SetStateEnabled(Enum.HumanoidStateType.Physics,false)h:ChangeState(Enum.HumanoidStateType.Running)end)
        end
    end

    -- Noclip + remove killbricks
    for _,v in plr.Character:GetDescendants()do if v:IsA("BasePart")then v.CanCollide=false end end
    local kf=workspace:FindFirstChild("KillBricks")
    if kf then for _,v in kf:GetChildren()do if v:IsA("BasePart")then v.Anchored=false;v.CanCollide=false;v.Transparency=1 end end end

    -- Validate current target (must be in map bounds)
    if ot and ot.Character then
        local tr=ot.Character:FindFirstChild("HumanoidRootPart");local th=ot.Character:FindFirstChild("Humanoid")
        if not tr or not th or th.Health<=1 then ot=nil
        elseif mm and MM then local p=tr.Position
            if p.X<mm.X or p.X>MM.X or p.Y<mm.Y or p.Y>MM.Y or p.Z<mm.Z or p.Z>MM.Z then ot=nil end
        end
    end

    -- Find closest target
    if not ot then local c,d=cl();if c then ot=c;oa=0 end end
    if not ot or not ot.Character then return end

    local tr=ot.Character:FindFirstChild("HumanoidRootPart")
    if not tr then ot=nil;return end

    local d=(r.Position-tr.Position).Magnitude

    if d>25 then
        -- TWEEN approach at 200 studs/second
        if tw then tw:Cancel()tw=nil end
        tw=TS:Create(r,TweenInfo.new(d/200,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{
            CFrame=CFrame.lookAt(tr.Position+Vector3.new(0,0,6),tr.Position)
        })
        tw:Play()
    else
        -- ORBIT
        if tw then tw:Cancel()tw=nil end
        oa=(oa+dt*5*60)%360
        r.CFrame=r.CFrame:Lerp(CFrame.new(
            CFrame.new(tr.Position)*CFrame.Angles(0,math.rad(oa),0)*CFrame.new(6,0,0).Position,
            tr.Position
        ),0.25)
        r.AssemblyLinearVelocity=Vector3.new(0,0,0)
    end

    -- Always face target and attack
    r.CFrame=CFrame.lookAt(r.Position,Vector3.new(tr.Position.X,r.Position.Y,tr.Position.Z))
    at=at+dt;if at>=0.12 then at=0;local c=gc();if c then pcall(function()c.UseM1(c)end)end end
end

-- Auto join match
local aj=function(dt)
    if not cfg.autoJoin.en then return end
    if plr.Character then return end
    jt=jt+dt;if jt<1 then return end;jt=0
    local ok,ev=pcall(function()return game:GetService("ReplicatedStorage").Files.Shared.Components.Jolt.Utils.Remotes.Jolt_Reliable end)
    if ev then pcall(function()ev:FireServer(buffer.fromstring("\x06Deploy\x81\x11\x00"),{})end)end
end

-- ESP
local me=function(p)
    if p==plr or esp[p]then return end
    local function bld(c)
        if not c then return end
        local r=c:WaitForChild("HumanoidRootPart",5);local h=c:WaitForChild("Humanoid",5)
        if not r or not h then return end
        local hl=Instance.new("Highlight")
        hl.Adornee=c;hl.FillColor=Color3.fromRGB(200,20,20);hl.FillTransparency=0.6
        hl.OutlineColor=Color3.fromRGB(255,30,30);hl.OutlineTransparency=0.1
        hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;hl.Parent=c
        local bb=Instance.new("BillboardGui")
        bb.Adornee=r;bb.Size=UDim2.new(0,80,0,50);bb.StudsOffset=Vector3.new(0,4.5,0);bb.AlwaysOnTop=true;bb.Parent=c
        local t=Instance.new("TextLabel")
        t.Size=UDim2.new(1,0,1,0);t.BackgroundTransparency=1;t.Font=Enum.Font.GothamBold
        t.Text="100";t.TextColor3=Color3.fromRGB(255,255,255);t.TextSize=42
        t.TextStrokeTransparency=0.25;t.TextStrokeColor3=Color3.fromRGB(0,0,0);t.Parent=bb
        esp[p]={hl=hl,bb=bb,ht=t,hu=h,hr=r}
    end
    if p.Character then bld(p.Character)end
    p.CharacterAdded:Connect(function(c)task.wait(0.5);esp[p]=nil;bld(c)end)
end

local ue=function()
    for p,o in pairs(esp)do
        if not p.Character or not p.Character.Parent then
            if o.bb then o.bb.Enabled=false end;if o.hl then o.hl.Enabled=false end
        elseif not o.hu or not o.hu.Parent or not o.hr or not o.hr.Parent then
            if o.bb then o.bb:Destroy()end;if o.hl then o.hl:Destroy()end;esp[p]=nil
        else
            local en=cfg.esp.en
            if o.bb then o.bb.Enabled=en end;if o.hl then o.hl.Enabled=en end
            if en then
                o.ht.Text=math.floor(o.hu.Health)
                local r=o.hu.Health/math.max(o.hu.MaxHealth,1)
                if r>0.6 then o.ht.TextColor3=Color3.fromRGB(50,220,50)
                elseif r>0.3 then o.ht.TextColor3=Color3.fromRGB(255,200,50)
                else o.ht.TextColor3=Color3.fromRGB(255,50,50)end
            end
        end
    end
end

for _,p in game.Players:GetPlayers()do me(p)end
game.Players.PlayerAdded:Connect(me)
game.Players.PlayerRemoving:Connect(function(p)if esp[p]then esp[p]=nil end end)

-- Frame hooks
RS.Heartbeat:Connect(function()pcall(sh)pcall(ue)end)
RS.Stepped:Connect(function()pcall(sh)pcall(ls)pcall(bc)end)
RS.RenderStepped:Connect(function(dt)
    pcall(function()
        sh()sj()ls()am1(dt)ak()bc()ss(dt)ao(dt)aj(dt)
    end)
end)

-- GUI
local sg=Instance.new("ScreenGui");sg.Name="UltimateOP";sg.ResetOnSpawn=false;sg.Parent=pg
local f=Instance.new("Frame")
f.Size=UDim2.new(0,240,0,580);f.Position=UDim2.new(0,25,0,80)
f.BackgroundColor3=Color3.fromRGB(12,12,12);f.BackgroundTransparency=0.15;f.BorderSizePixel=0;f.Active=true;f.Parent=sg
local fc=Instance.new("UICorner");fc.CornerRadius=UDim.new(0,10);fc.Parent=f

local tb=Instance.new("Frame")
tb.Size=UDim2.new(1,0,0,30);tb.BackgroundColor3=Color3.fromRGB(30,30,30);tb.BackgroundTransparency=0.3
tb.BorderSizePixel=0;tb.Active=true;tb.Draggable=true;tb.Parent=f
local t2c=Instance.new("UICorner");t2c.CornerRadius=UDim.new(0,10);t2c.Parent=tb

local tl=Instance.new("TextLabel")
tl.Size=UDim2.new(1,-40,1,0);tl.Position=UDim2.new(0,10,0,0);tl.BackgroundTransparency=1
tl.Text="v6.5";tl.TextColor3=Color3.fromRGB(255,60,60);tl.TextSize=15;tl.Font=Enum.Font.GothamBold
tl.TextXAlignment=Enum.TextXAlignment.Left;tl.Parent=tb

local hb=Instance.new("TextButton")
hb.Size=UDim2.new(0,22,0,22);hb.Position=UDim2.new(1,-26,0,4)
hb.BackgroundColor3=Color3.fromRGB(60,60,60);hb.Text="X";hb.TextColor3=Color3.fromRGB(200,200,200)
hb.TextSize=12;hb.Font=Enum.Font.GothamBold;hb.BorderSizePixel=0;hb.Parent=tb
local hc=Instance.new("UICorner");hc.CornerRadius=UDim.new(0,4);hc.Parent=hb

-- Toggle buttons
local td={
    {k="hitbox",l="Hitbox [X]",c=Color3.fromRGB(255,70,70)},
    {k="esp",l="ESP",c=Color3.fromRGB(255,30,30)},
    {k="noclip",l="NoClip [C]",c=Color3.fromRGB(70,130,255)},
    {k="speed",l="Speed",c=Color3.fromRGB(70,200,70)},
    {k="loopsy",l="LoopS",c=Color3.fromRGB(50,230,100)},
    {k="jump",l="Jump",c=Color3.fromRGB(70,220,220)},
    {k="antiKB",l="AntiKB",c=Color3.fromRGB(255,180,50)},
    {k="abypass",l="CDwn",c=Color3.fromRGB(255,100,255)},
    {k="spamSkill",l="Skill",c=Color3.fromRGB(200,50,200)},
    {k="autoM1",l="M1",c=Color3.fromRGB(200,70,200)},
    {k="kb",l="KBrick",c=Color3.fromRGB(255,140,70)},
    {k="orbit",l="Orbit",c=Color3.fromRGB(255,100,50)},
    {k="autoJoin",l="Join",c=Color3.fromRGB(50,200,255)}
}

local y=42;local R={}
for _,t in ipairs(td)do
    local r=Instance.new("Frame")
    r.Size=UDim2.new(1,-20,0,28);r.Position=UDim2.new(0,10,0,y);r.BackgroundTransparency=1;r.Parent=f

    local lb=Instance.new("TextLabel")
    lb.Size=UDim2.new(0,145,1,0);lb.BackgroundTransparency=1;lb.Text=t.l
    lb.TextColor3=Color3.fromRGB(200,200,200);lb.TextSize=12;lb.Font=Enum.Font.Gotham
    lb.TextXAlignment=Enum.TextXAlignment.Left;lb.Parent=r

    local on=cfg[t.k].en
    local bn=Instance.new("TextButton")
    bn.Size=UDim2.new(0,46,0,22);bn.Position=UDim2.new(1,-50,0.5,-11)
    bn.BackgroundColor3=on and t.c or Color3.fromRGB(50,50,50);bn.Text=on and"ON"or"OFF"
    bn.TextColor3=on and Color3.fromRGB(255,255,255)or Color3.fromRGB(150,150,150)
    bn.TextSize=11;bn.Font=Enum.Font.GothamBold;bn.BorderSizePixel=0;bn.Parent=r
    local bc2=Instance.new("UICorner");bc2.CornerRadius=UDim.new(0,4);bc2.Parent=bn

    bn.MouseButton1Click:Connect(function()
        local k=t.k;cfg[k].en=not cfg[k].en;local o=cfg[k].en
        bn.BackgroundColor3=o and t.c or Color3.fromRGB(50,50,50)
        bn.Text=o and"ON"or"OFF";bn.TextColor3=o and Color3.fromRGB(255,255,255)or Color3.fromRGB(150,150,150)

        if k=="noclip"and plr.Character then
            for _,v in plr.Character:GetDescendants()do if v:IsA("BasePart")then v.CanCollide=not o end end
        end

        if k=="kb"then
            local f2=workspace:FindFirstChild("KillBricks")
            if f2 then for _,v in f2:GetChildren()do if v:IsA("BasePart")then v.Anchored=false;v.CanCollide=false;v.Transparency=1 end end end
        end

        if not o and k=="hitbox"then
            for p,s in next,orig do
                if p.Character then
                    local h=p.Character:FindFirstChild("Hitbox")
                    if h then h.Size=s;h.Transparency=1;h.Material=Enum.Material.Plastic;h.Color=Color3.fromRGB(163,162,165)end
                end
            end
            orig={}
        end

        if k=="orbit"then
            cfg.orbit.en=o
            if not o then ot=nil;oa=0;if tw then tw:Cancel()tw=nil end
            else local c,d=cl();ot=c;oa=0 end
        end
    end)

    y=y+32;R[t.k]=bn
end

-- Hotkeys
game:GetService("UserInputService").InputBegan:Connect(function(i,g)
    if g then return end
    if i.KeyCode==Enum.KeyCode.X then
        local k="hitbox";cfg[k].en=not cfg[k].en;local o=cfg[k].en;local b=R[k]
        b.BackgroundColor3=o and Color3.fromRGB(255,70,70)or Color3.fromRGB(50,50,50)
        b.Text=o and"ON"or"OFF";b.TextColor3=o and Color3.fromRGB(255,255,255)or Color3.fromRGB(150,150,150)
        if not o then for p,s in next,orig do if p.Character then local h=p.Character:FindFirstChild("Hitbox");if h then h.Size=s;h.Transparency=1;h.Material=Enum.Material.Plastic;h.Color=Color3.fromRGB(163,162,165)end end end;orig={}end
    end
    if i.KeyCode==Enum.KeyCode.C then
        local k="noclip";cfg[k].en=not cfg[k].en;local o=cfg[k].en;local b=R[k]
        b.BackgroundColor3=o and Color3.fromRGB(70,130,255)or Color3.fromRGB(50,50,50)
        b.Text=o and"ON"or"OFF";b.TextColor3=o and Color3.fromRGB(255,255,255)or Color3.fromRGB(150,150,150)
        if plr.Character then for _,v in plr.Character:GetDescendants()do if v:IsA("BasePart")then v.CanCollide=not o end end end
    end
end)

-- Minimize button
local hd=false
hb.MouseButton1Click:Connect(function()hd=not hd;f.Visible=not hd;hb.Text=hd and"+"or"X"end)

-- Save original hitbox sizes
for _,p in game.Players:GetPlayers()do
    if p.Character and p~=plr then
        local h=p.Character:FindFirstChild("Hitbox")
        if h then orig[p]=h.Size end
    end
end

-- Character respawn events
plr.CharacterAdded:Connect(function()
    task.wait(0.5)
    if cfg.noclip.en and plr.Character then
        for _,v in plr.Character:GetDescendants()do if v:IsA("BasePart")then v.CanCollide=false end end
    end
end)

plr.CharacterRemoving:Connect(function()
    if cfg.autoJoin.en then
        task.wait(0.5)
        local ok,ev=pcall(function()return game:GetService("ReplicatedStorage").Files.Shared.Components.Jolt.Utils.Remotes.Jolt_Reliable end)
        if ev then pcall(function()ev:FireServer(buffer.fromstring("\x06Deploy\x81\x11\x00"),{})end)end
    end
end)

print("v6.5 OK")
