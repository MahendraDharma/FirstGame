-- Dragon Isle Farm: hatch reveal. The egg shakes, cracks, bursts, and the pet spins in.
-- Studio path: StarterPlayer.StarterPlayerScripts.HatchReveal (ModuleScript, required by ClientUI)
-- Spec: 04_Eggs_and_Hatching.md section 3.
--   HatchReveal.Play({Pet = name, Rarity = rarity, Egg = eggName | "Nest", Secret = bool}, onDone)
-- Reveals queue up if several arrive at once. A tap skips to the pet; a second tap closes it.
-- The egg and pet are the real models (ItemModels / PetModels) drawn in a ViewportFrame. ViewportFrames
-- don't draw ParticleEmitters or lights, so sparkles, motes, beam and flashes are 2D UI.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Models = Shared:WaitForChild("Models")
local PetModels = require(Models:WaitForChild("PetModels"))
local ItemModels = require(Models:WaitForChild("ItemModels"))

local V = Vector3.new
local rad = math.rad
local rand = Random.new()

------------------------------------------------------------------ tunables
local T_CRACK, T_BURST, T_REVEAL, T_SETTLE = 1.5, 2.0, 2.2, 3.0 -- seconds, from the spec
local HOLD = 1.8          -- the pet stays on screen this long after it settles (a tap closes it sooner)
local SHAKES = {{0.15, 0.5, 7}, {0.6, 0.98, 12}, {1.06, 1.46, 19}} -- start, end, max tilt in degrees
local FOV = 35
local EGG_Y = 0.42        -- egg / pet centre on screen (0 = top, 1 = bottom)

-- Placeholder sounds: these built-in ones always load. Paste Creator Store asset ids ("rbxassetid://...")
-- for the fanfare, roar and choir when they are picked; an empty id is skipped.
local SOUNDS = {
	pop = {"rbxasset://sounds/electronicpingshort.wav", 0.6, 0.5},  -- id, playback speed, volume
	chime = {"rbxasset://sounds/electronicpingshort.wav", 1.0, 0.6},
	bigChime = {"rbxasset://sounds/electronicpingshort.wav", 1.25, 0.8},
	fanfare = {"", 1, 0.8},
	roar = {"", 1, 0.8},
	choir = {"", 1, 0.8},
}
-- per tier: sounds on the burst, then what the burst adds
local TIERS = {
	{sounds = {"pop"}},
	{sounds = {"pop"}},
	{sounds = {"chime"}, sparkles = true},
	{sounds = {"bigChime"}, sparkles = true, motes = true},
	{sounds = {"bigChime", "fanfare"}, sparkles = true, motes = true, beam = true},
	{sounds = {"bigChime", "roar", "fanfare"}, sparkles = true, motes = true, beam = true, screenShake = true},
	{sounds = {"bigChime", "choir", "fanfare"}, sparkles = true, motes = true, beam = true, screenShake = true, rainbow = true},
}

------------------------------------------------------------------ helpers
local function new(class, props, children)
	local o = Instance.new(class)
	local parent = nil
	for k, v in pairs(props or {}) do if k == "Parent" then parent = v else o[k] = v end end
	for _, c in ipairs(children or {}) do c.Parent = o end
	if parent then o.Parent = parent end
	return o
end
local function tween(o, time, goal, style, dir)
	local t = TweenService:Create(o, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	t:Play()
	return t
end
local function circle(props)
	props.AnchorPoint = Vector2.new(0.5, 0.5)
	props.BorderSizePixel = 0
	return new("Frame", props, {new("UICorner", {CornerRadius = UDim.new(0.5, 0)})})
end
local function playSound(key)
	local s = SOUNDS[key]
	if not s or s[1] == "" then return end
	local sound = new("Sound", {SoundId = s[1], PlaybackSpeed = s[2], Volume = s[3]})
	SoundService:PlayLocalSound(sound)
	task.delay(6, function() sound:Destroy() end)
end
local function easeOutBack(p)
	local c = 1.4
	return 1 + (c + 1) * (p - 1) ^ 3 + c * (p - 1) ^ 2
end
local function easeOut(p) return 1 - (1 - p) ^ 3 end

-- a model's visible parts and their CFrames relative to `origin`; moved as one with place()
local function snapshot(model, origin)
	local list = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then table.insert(list, {d, origin:ToObjectSpace(d.CFrame)}) end
	end
	return list
end
local function place(list, cf)
	for _, e in ipairs(list) do e[1].CFrame = cf * e[2] end
end
-- world-space bounds of the visible parts
local function bounds(list)
	local lo, hi = V(math.huge, math.huge, math.huge), V(-math.huge, -math.huge, -math.huge)
	for _, e in ipairs(list) do
		local p = e[1]
		if p.Transparency < 1 then
			local cf, h = p.CFrame, p.Size / 2
			local x, y, z = cf.XVector, cf.YVector, cf.ZVector
			local ext = V(math.abs(x.X) * h.X + math.abs(y.X) * h.Y + math.abs(z.X) * h.Z,
				math.abs(x.Y) * h.X + math.abs(y.Y) * h.Y + math.abs(z.Y) * h.Z,
				math.abs(x.Z) * h.X + math.abs(y.Z) * h.Y + math.abs(z.Z) * h.Z)
			lo = lo:Min(cf.Position - ext)
			hi = hi:Max(cf.Position + ext)
		end
	end
	if lo.X > hi.X then return V(), V(1, 1, 1) end
	return (lo + hi) / 2, hi - lo
end
-- camera distance that fits an object of this size on screen (fill = share of the screen height)
local function fitDistance(size, fill)
	local r = math.max(size.X, size.Y, size.Z * 0.6) / 2
	return r / math.tan(rad(FOV / 2)) / fill
end
-- point on an ellipsoid (radii a, b, a) around c; theta = 3*pi/2 faces the camera (-Z)
local function onShell(c, a, b, theta, phi)
	return c + V(a * math.cos(phi) * math.cos(theta), b * math.sin(phi), a * math.cos(phi) * math.sin(theta))
end

------------------------------------------------------------------ screen
local player = Players.LocalPlayer
local gui = new("ScreenGui", {Name = "HatchRevealUI", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 20,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui")})

local HatchReveal = {}

local function run(info)
	local rarity = Config.Rarities[info.Rarity] and info.Rarity or "Common"
	local tierN = Config.Rarities[rarity].Tier
	local fx = TIERS[tierN] or TIERS[1]
	local color = Config.RarityColor(rarity)
	local white = Color3.new(1, 1, 1)
	local shakeSpeed = 1 + (tierN - 1) * 0.15 -- higher tiers shake faster

	-- layers, back to front: dim + vignette, glow, beam, 3D view, sparkles, text, flashes, tap catcher
	local root = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = gui}) -- offset = screen shake
	local backdrop = new("CanvasGroup", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, ZIndex = 1, Parent = root})
	new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(8, 6, 14), BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = backdrop})
	for _, rot in ipairs({0, 90, 180, 270}) do -- vignette: a dark edge on each side
		new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = backdrop},
			{new("UIGradient", {Rotation = rot, Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.3, 1), NumberSequenceKeypoint.new(1, 1)})})})
	end
	local glows = {}
	for i, k in ipairs({{0.55, 0.8}, {0.8, 0.88}, {1.15, 0.94}}) do
		glows[i] = circle({Position = UDim2.fromScale(0.5, EGG_Y), Size = UDim2.fromScale(0, 0), BackgroundColor3 = color,
			BackgroundTransparency = 1, ZIndex = 2, Parent = root})
		glows[i]:SetAttribute("Grow", k[1])
		glows[i]:SetAttribute("Alpha", k[2])
	end
	local view = new("ViewportFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 4, ImageTransparency = 1,
		Ambient = Color3.fromRGB(165, 155, 150), LightColor = Color3.fromRGB(255, 245, 230), LightDirection = V(0.45, -1, 0.8), Parent = root})
	local cam = new("Camera", {FieldOfView = FOV, Parent = view})
	view.CurrentCamera = cam
	local fxLayer = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5, Parent = root})
	local flash = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = white, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 8, Parent = root})
	local tap = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 10, Parent = root})

	tween(backdrop, 0.25, {GroupTransparency = 0})
	tween(view, 0.2, {ImageTransparency = 0})

	-- the egg, standing on the origin; the camera looks at it from the front (-Z)
	local egg = (info.Egg == "Nest" and ItemModels.NestEgg(rarity, info.Secret == true)) or ItemModels.Egg(info.Egg or "") or ItemModels.Egg("Hatchling Egg")
	egg.Parent = view
	local eggParts = snapshot(egg, CFrame.new())
	local eggCenter, eggSize = bounds(eggParts)
	local eggDist = fitDistance(eggSize, 0.42)
	local function aim(center, dist)
		cam.CFrame = CFrame.lookAt(center + V(0, dist * 0.08, -dist), center)
	end
	aim(eggCenter, eggDist)
	local shell = egg:FindFirstChild("Shell")
	local shellColor = shell and shell.Color or color
	local shellC = shell and shell.CFrame.Position or eggCenter
	local shellA = shell and shell.Size.X / 2 or eggSize.X / 2
	local shellB = shell and shell.Size.Y / 2 or eggSize.Y / 2

	local updaters = {} -- per-frame functions; return true when finished
	local t, closeAt = 0, nil
	local fired = {}
	local skip, close = false, false
	tap.Activated:Connect(function()
		if t < T_REVEAL then skip = true else close = true end
	end)

	local function sparkles(count)
		for _ = 1, count do
			local s = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, EGG_Y), Rotation = 45,
				Size = UDim2.fromOffset(rand:NextInteger(8, 16), rand:NextInteger(8, 16)), BorderSizePixel = 0,
				BackgroundColor3 = rand:NextNumber() < 0.5 and white or color, Parent = fxLayer})
			local a, d = rand:NextNumber(0, math.pi * 2), rand:NextNumber(140, 320)
			local time = rand:NextNumber(0.6, 1.0)
			tween(s, time, {Position = UDim2.new(0.5, math.cos(a) * d, EGG_Y, math.sin(a) * d), Rotation = 45 + rand:NextNumber(-180, 180), BackgroundTransparency = 1})
			task.delay(time, function() s:Destroy() end)
		end
	end
	local function motes(count)
		for i = 1, count do
			local m = circle({Size = UDim2.fromOffset(10, 10), BackgroundColor3 = color, Position = UDim2.fromScale(0.5, EGG_Y), Parent = fxLayer})
			local a0, life, age = i / count * math.pi * 2, 0.55, 0
			table.insert(updaters, function(dt)
				age += dt
				local p = math.min(age / life, 1)
				local a, r = a0 + p * 4, 300 * (1 - easeOut(p))
				m.Position = UDim2.new(0.5, math.cos(a) * r, EGG_Y, math.sin(a) * r * 0.75)
				m.BackgroundTransparency = p * 0.6
				if p >= 1 then m:Destroy() return true end
				return false
			end)
		end
	end
	local function beam()
		local b = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, EGG_Y + 0.12), Size = UDim2.new(0, 0, 1.2, 0),
			BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = 3, Parent = root}, {
			new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 1)})}),
		})
		tween(b, 0.3, {Size = UDim2.new(0, 220, 1.2, 0)}, Enum.EasingStyle.Back)
		task.delay(1.2, function() if b.Parent then tween(b, 0.8, {Size = UDim2.new(0, 120, 1.2, 0), BackgroundTransparency = 0.6}) end end)
		return b
	end
	local function screenShake(time, px)
		local age = 0
		table.insert(updaters, function(dt)
			age += dt
			local k = math.max(0, 1 - age / time) * px
			root.Position = UDim2.fromOffset(rand:NextNumber(-k, k), rand:NextNumber(-k, k))
			if age >= time then root.Position = UDim2.new() return true end
			return false
		end)
	end
	local function rainbow()
		local r = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = white, BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 7, Parent = root}, {
			new("UIGradient", {Rotation = 30, Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)), ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 190, 60)),
				ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 255, 110)), ColorSequenceKeypoint.new(0.6, Color3.fromRGB(90, 230, 120)),
				ColorSequenceKeypoint.new(0.8, Color3.fromRGB(80, 170, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 110, 255))})}),
		})
		tween(r, 0.9, {BackgroundTransparency = 1})
		task.delay(1, function() r:Destroy() end)
	end

	-- 3. crack: zigzag lines in the pet's rarity colour, and light leaking out behind the egg
	local function crack()
		for i = 1, 5 do
			local theta = math.pi * 1.5 + (i - 3) * 0.42 + rand:NextNumber(-0.12, 0.12)
			local phi = rand:NextNumber(-0.15, 0.55)
			local prev = onShell(shellC, shellA * 1.01, shellB * 1.01, theta, phi)
			for _ = 1, 3 do
				theta += rand:NextNumber(-0.25, 0.25)
				phi -= rand:NextNumber(0.12, 0.25)
				local nextP = onShell(shellC, shellA * 1.01, shellB * 1.01, theta, phi)
				local mid = (prev + nextP) / 2
				local up = (mid - shellC).Unit
				local seg = new("Part", {Name = "Crack", Anchored = true, CanCollide = false, Material = Enum.Material.Neon, Color = color,
					Size = V(shellA * 0.07, shellA * 0.04, (nextP - prev).Magnitude + shellA * 0.04),
					CFrame = CFrame.lookAt(mid, nextP, up), Parent = egg})
				table.insert(eggParts, {seg, seg.CFrame})
				prev = nextP
			end
		end
		for _, g in ipairs(glows) do
			local s = g:GetAttribute("Grow")
			tween(g, 0.4, {Size = UDim2.fromScale(s * 0.45, s * 0.45), BackgroundTransparency = g:GetAttribute("Alpha")})
		end
	end

	-- 4. burst: shell pieces fly out, a flash, and the tier extras
	local function burst()
		local count = 12 + tierN * 2
		for i = 1, count do
			local theta = i / count * math.pi * 2 + rand:NextNumber(-0.2, 0.2)
			local phi = rand:NextNumber(-0.9, 1.1)
			local pos = onShell(shellC, shellA, shellB, theta, phi)
			local out = (pos - shellC).Unit
			local piece = new("Part", {Name = "ShellPiece", Anchored = true, CanCollide = false, Material = Enum.Material.SmoothPlastic,
				Color = i % 4 == 0 and color or shellColor, Size = V(shellA * rand:NextNumber(0.35, 0.6), shellB * rand:NextNumber(0.3, 0.5), shellA * 0.1),
				CFrame = CFrame.lookAt(pos, pos + out), Parent = view})
			local vel = (out * rand:NextNumber(5, 9) + V(0, rand:NextNumber(2, 5), 0)) * shellB
			local spin = V(rand:NextNumber(-12, 12), rand:NextNumber(-12, 12), rand:NextNumber(-12, 12))
			local age = 0
			table.insert(updaters, function(dt)
				age += dt
				vel += V(0, -22 * shellB * dt, 0)
				piece.CFrame = (piece.CFrame + vel * dt) * CFrame.Angles(spin.X * dt, spin.Y * dt, spin.Z * dt)
				piece.Transparency = math.clamp((age - 0.45) / 0.4, 0, 1)
				if age > 0.9 then piece:Destroy() return true end
				return false
			end)
		end
		egg:Destroy()
		local orb = new("Part", {Name = "Flash", Shape = Enum.PartType.Ball, Anchored = true, CanCollide = false, Material = Enum.Material.Neon,
			Color = color, Size = V(1, 1, 1) * shellB * 2, CFrame = CFrame.new(shellC), Transparency = 0.1, Parent = view})
		tween(orb, 0.35, {Size = V(1, 1, 1) * shellB * 6, Transparency = 1})
		task.delay(0.4, function() orb:Destroy() end)
		flash.BackgroundTransparency = 0.35
		tween(flash, 0.3, {BackgroundTransparency = 1})
		for _, g in ipairs(glows) do
			local s = g:GetAttribute("Grow")
			tween(g, 0.25, {Size = UDim2.fromScale(s, s), BackgroundTransparency = 0.6 + g:GetAttribute("Alpha") * 0.4})
		end
		if fx.sparkles then sparkles(18 + tierN * 3) end
		if fx.motes then motes(14) end
		if fx.beam then beam() end
		if fx.screenShake then screenShake(0.6, 14) end
		if fx.rainbow then rainbow() end
		for _, key in ipairs(fx.sounds) do playSound(key) end
	end

	-- 5. reveal: the pet spins in while the camera pulls in; name and tier in big text
	local pet, petParts, petCenter, petSize, petDist
	local function reveal()
		pet = PetModels.Build(info.Pet, true)
		if pet then
			pet.Parent = view
			petParts = snapshot(pet, CFrame.new())
			petCenter, petSize = bounds(petParts)
			petDist = fitDistance(petSize, 0.5)
			place(petParts, CFrame.new(petCenter) * CFrame.Angles(0, -math.pi * 4, 0) * CFrame.new(-petCenter))
			aim(petCenter, petDist * 1.8)
		end
		local nameLabel = new("TextLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.78), Size = UDim2.new(1, 0, 0, 150),
			BackgroundTransparency = 1, Font = Enum.Font.FredokaOne, Text = string.format("%s\n%s", info.Pet, rarity), TextSize = 40,
			TextColor3 = color, TextStrokeTransparency = 0, TextTransparency = 1, ZIndex = 6, Parent = root})
		tween(nameLabel, 0.35, {TextTransparency = 0, TextSize = 56}, Enum.EasingStyle.Back)
		if info.Secret then
			local s = new("TextLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.9), Size = UDim2.fromOffset(500, 36),
				BackgroundTransparency = 1, Font = Enum.Font.FredokaOne, Text = "Secret hybrid!", TextSize = 28,
				TextColor3 = Color3.fromRGB(60, 230, 240), TextStrokeTransparency = 0, TextTransparency = 1, ZIndex = 6, Parent = root})
			tween(s, 0.4, {TextTransparency = 0})
		end
		task.delay(0.9, function()
			if not root.Parent then return end
			local hint = new("TextLabel", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.fromOffset(300, 24),
				BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = "Tap to continue", TextSize = 16,
				TextColor3 = Color3.fromRGB(215, 195, 165), TextTransparency = 1, ZIndex = 6, Parent = root})
			tween(hint, 0.4, {TextTransparency = 0.2})
		end)
	end

	-- timeline
	local eggDrop = eggSize.Y * 0.6
	while true do
		local dt = RunService.RenderStepped:Wait()
		t += dt
		if skip and t < T_REVEAL then
			-- jump straight to the pet
			if not fired.burst then
				if egg.Parent then egg:Destroy() end
				for _, key in ipairs(fx.sounds) do playSound(key) end
				if fx.beam then beam() end
			end
			fired.crack, fired.burst = true, true
			for _, g in ipairs(glows) do
				local s = g:GetAttribute("Grow")
				g.Size = UDim2.fromScale(s, s)
				g.BackgroundTransparency = 0.6 + g:GetAttribute("Alpha") * 0.4
			end
			t = T_REVEAL
		end
		skip = false

		-- 1-2. spawn and shake: drop in with a small bounce, then three shakes, each stronger
		if not fired.burst then
			local y = 0
			if t < 0.3 then y = eggDrop * (1 - easeOutBack(t / 0.3)) end
			local tilt = 0
			for _, s in ipairs(SHAKES) do
				if t >= s[1] and t <= s[2] then
					local p = (t - s[1]) / (s[2] - s[1])
					tilt = rad(s[3]) * math.sin(p * math.pi) * math.sin((t - s[1]) * 38 * shakeSpeed)
				end
			end
			if t >= T_CRACK then tilt = rad(3) * math.sin(t * 70 * shakeSpeed) end -- trembling before the burst
			place(eggParts, CFrame.new(0, y, 0) * CFrame.Angles(0, 0, tilt))
		end
		if t >= T_CRACK and not fired.crack then fired.crack = true crack() end
		if t >= T_BURST and not fired.burst then fired.burst = true burst() end
		if t >= T_REVEAL and not fired.reveal then fired.reveal = true reveal() end

		if pet then
			local p = math.clamp((t - T_REVEAL) / (T_SETTLE - T_REVEAL), 0, 1)
			local spin = -math.pi * 4 * (1 - easeOut(p))
			local bob = math.sin((t - T_REVEAL) * 2.5) * petSize.Y * 0.03
			place(petParts, CFrame.new(petCenter + V(0, bob, 0)) * CFrame.Angles(0, spin, 0) * CFrame.new(-petCenter))
			aim(petCenter, petDist * (1 + 0.8 * (1 - easeOut(p))))
		end

		for i = #updaters, 1, -1 do
			if updaters[i](dt) then table.remove(updaters, i) end
		end

		if fired.reveal and not closeAt and (close or t >= T_SETTLE + HOLD) then
			closeAt = t
			tween(backdrop, 0.35, {GroupTransparency = 1})
			tween(view, 0.35, {ImageTransparency = 1})
			for _, d in ipairs(root:GetDescendants()) do
				if d:IsA("TextLabel") then tween(d, 0.3, {TextTransparency = 1, TextStrokeTransparency = 1})
				elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then tween(d, 0.3, {BackgroundTransparency = 1}) end
			end
		end
		if closeAt and t - closeAt >= 0.4 then break end
	end
	root:Destroy()
end

local queue, playing = {}, false

function HatchReveal.Play(info, onDone)
	table.insert(queue, {info, onDone})
	if playing then return end
	playing = true
	task.spawn(function()
		while #queue > 0 do
			local item = table.remove(queue, 1)
			local ok, err = pcall(run, item[1])
			if not ok then
				warn("[HatchReveal]", err)
				for _, c in ipairs(gui:GetChildren()) do c:Destroy() end
			end
			if item[2] then task.spawn(item[2]) end
		end
		playing = false
	end)
end

return HatchReveal
