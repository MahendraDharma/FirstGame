-- Dragon Isle Farm: client idle animations (pets, eggs, crops)
-- Studio path: StarterPlayer.StarterPlayerScripts.IdleAnimations (LocalScript)
-- Specs: design/03_Pets.md (Idle), 04_Eggs_and_Hatching.md (Idle), 02_Seeds_and_Crops.md (Ripe effect).
--
-- Everything here is cosmetic and local to this client:
--  * anchored models (eggs, plants, showcase) are moved on this client only;
--  * pet wings, tails, legs, ears and heads get a local Weld in place of their WeldConstraint so they can hinge;
--  * your own pets bob, hop and flip through their AlignPosition attachment. You own their physics,
--    so that body motion is what other players see too.
--  * particles, hoofprints, beams and lightning are created locally and never replicate.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

local ACTIVE_RANGE = 140   -- studs from the camera; farther models hold their last pose
local CULL_INTERVAL = 0.5
local REBUILD_DELAY = 0.25 -- wait for streamed-in parts to settle before (re)reading a model
local MAX_FX_PARTS = 80    -- hoofprints, beams, rings and droplets alive at once
local TAU = math.pi * 2
local rad, sin, cos, abs = math.rad, math.sin, math.cos, math.abs

-- Per-pet tuning (03_Pets.md).
--  flap = wing beats/s, burst = flaps only now and then (ground pets), takeoff = hops while it flaps
--  bob/bobHz = hover, figure8/sway/circle = drift in studs
--  hop/hopHz = gait while walking (hops per second), gait = "trot" (diagonal legs) or "bound" (front/back pairs)
--  prance = high leg lift, waddle = side-to-side roll, stepFx = particles or hoofprints at each footfall
--  trick/every = signature move every ~N s (see TRICK_TIME), orbit = part that circles the head
--  coil = body swims around its Orb in a wave, droplets = water drops orbiting the orb, surge = tidal pulse every N s
local PETS = {
	["Imp"] = {flap = 3.2, bob = 0.25, bobHz = 1.4, trick = "backflip", every = 8},
	["Fairy Sprite"] = {flap = 5, bob = 0.15, bobHz = 0.7, figure8 = 0.5},
	["Jackalope"] = {hop = 0.6, hopHz = 2.2, gait = "bound", trick = "thump", every = 6},
	["Kitsune Kit"] = {tailHz = 1.3, hop = 0.12, hopHz = 3, orbit = "FoxFire"},
	["Gryphon Chick"] = {flap = 3, burst = true, takeoff = true, waddle = true, hop = 0.1, hopHz = 2.4},
	["Unicorn"] = {hop = 0.2, hopHz = 2.6, prance = true, stepFx = "rainbow"},
	["Pegasus Foal"] = {flap = 1.1, bob = 0.3, bobHz = 0.55, trick = "puff", every = 3},
	["Sky Kitsune"] = {flap = 1, bob = 0.3, bobHz = 0.5, sway = 0.3},
	["Fire Drake"] = {flap = 2, burst = true, hop = 0.1, hopHz = 2, trick = "sneeze", every = 6},
	["Frost Wyvern"] = {flap = 0.8, bob = 0.35, bobHz = 0.4, circle = 0.6},
	["Thunder Dragon"] = {bob = 0.2, bobHz = 0.6, sway = 0.6, trick = "zap", every = 3},
	["Phoenix"] = {flap = 1.3, bob = 0.3, bobHz = 0.65, trick = "flare", every = 10},
	["Emberhorn"] = {hop = 0.1, hopHz = 2.2, prance = true, stepFx = "fire"},
	["Glacier Pegasus"] = {flap = 0.9, bob = 0.3, bobHz = 0.5, flapFx = "snow"},
	["Hydra"] = {hop = 0.08, hopHz = 1.6, heads = true, trick = "bonk", every = 7},
	["Leviathan"] = {bob = 0.25, bobHz = 0.45, coil = true, droplets = 10, surge = 6},
	["Stormfire Dragon"] = {flap = 1.4, bob = 0.25, bobHz = 0.6, sway = 0.5},
	["Aether Dragon"] = {flap = 0.6, bob = 0.35, bobHz = 0.35, sway = 0.3, spawnBeam = true},
}
local DEFAULT_FLYER = {flap = 1.5, bob = 0.25, bobHz = 0.6}
local DEFAULT_WALKER = {}
local TRICK_TIME = {backflip = 0.7, thump = 0.6, puff = 0.1, sneeze = 0.6, zap = 0.1, flare = 1.1, bonk = 0.7, bubbles = 0.1}
local IDLE_ONLY = {thump = true} -- tricks that wait until the pet stands still

-- plant parts that stay put (soil, rocks, ponds, rarity ring/beam)
local GROUND = {Root = true, Mound = true, Rock = true, Pool = true, PoolGlow = true, Pad = true, GlowRing = true, LightBeam = true}
-- the Dragonheart fruit (CropModels heart()) pulses 1.00 -> 1.08 -> 1.00 once per second
local HEART = {Fruit = true, Lobe = true, Point = true, Core = true, Scale = true}
-- ripe parts that flutter on their own base (02: leaf/tassel flutter), value = strength
local FLUTTER = {Leaf = 1, Tassel = 1.6, Flower = 1, FlowerCore = 1}

-- particle bursts for signature moves
local FX = {
	rainbow = {color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 110, 110)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(130, 255, 150)), ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 130, 255))}), size = 0.25, life = 0.7, speed = 2, light = 1},
	spark = {color = Color3.fromRGB(255, 180, 60), size = 0.15, life = 0.4, speed = 6, light = 1},
	puff = {color = Color3.fromRGB(255, 255, 255), size = 0.5, grow = true, life = 1.2, speed = 1, transparency = 0.35},
	zap = {color = Color3.fromRGB(255, 240, 120), size = 0.2, life = 0.25, speed = 9, light = 1},
	ember = {color = Color3.fromRGB(255, 120, 30), size = 0.22, life = 1, speed = 5, light = 1, accel = Vector3.new(0, 3, 0)},
	snow = {color = Color3.fromRGB(232, 246, 255), size = 0.15, life = 1.4, speed = 1, accel = Vector3.new(0, -2, 0)},
	bubble = {color = Color3.fromRGB(156, 220, 255), size = 0.25, life = 1.8, speed = 0.4, transparency = 0.4, accel = Vector3.new(0, 2.5, 0)},
	sparkle = {color = Color3.fromRGB(60, 230, 240), size = 0.12, life = 1.2, speed = 0.6, light = 1},
}

local rigs = {}                         -- [Model] = rig
local baseRel = setmetatable({}, {__mode = "k"}) -- [BasePart] = CFrame relative to Root, read before we ever move it
local baseSize = setmetatable({}, {__mode = "k"})
local baseTransparency = setmetatable({}, {__mode = "k"})
local tileStage = setmetatable({}, {__mode = "k"}) -- [tile] = last plant stage seen, for the ripe "pop"
local emitters = setmetatable({}, {__mode = "k"})  -- [BasePart] = {[fx kind] = ParticleEmitter}

local fxFolder = Instance.new("Folder")
fxFolder.Name = "IdleFx"
fxFolder.Parent = workspace

------------------------------------------------------------------ helpers
local function hinge(point, rotation)
	return CFrame.new(point) * rotation * CFrame.new(-point)
end

local function ease(u) return u * u * (3 - 2 * u) end

-- face centre of a part (in Root space) that scores lowest
local FACES = {Vector3.xAxis, -Vector3.xAxis, Vector3.yAxis, -Vector3.yAxis, Vector3.zAxis, -Vector3.zAxis}
local function face(rel, size, score)
	local best, bestScore
	for _, f in ipairs(FACES) do
		local p = rel * (f * size / 2)
		local s = score(p)
		if not bestScore or s < bestScore then best, bestScore = p, s end
	end
	return best
end
local function nearMidline(p) return abs(p.X) end -- wing shoulder
local function nearCentre(p) return p.Magnitude end -- tail root
local function lowest(p) return p.Y end           -- ear, neck, leaf base
local function highest(p) return -p.Y end         -- hip/shoulder of a leg

local function average(points)
	if #points == 0 then return nil end
	local sum = Vector3.zero
	for _, p in ipairs(points) do sum += p end
	return sum / #points
end

local function inGemItem(model)
	local m = model
	while m and m ~= workspace do
		if m:GetAttribute("GemItem") then return true end
		m = m.Parent
	end
	return false
end

local function kindOf(model)
	if model:GetAttribute("DropId") then return "Drop" end -- an item lying on the ground (GameServer spawnDrop)
	if model:GetAttribute("Pet") then return "Pet" end
	if model:GetAttribute("Egg") then return "Egg" end
	if model:GetAttribute("Crop") and model:GetAttribute("Stage") then return "Plant" end
	if model.Name == "BreedEgg" or (model:GetAttribute("Rarity") and model:FindFirstChild("Shell")) then return "NestEgg" end
	return nil
end

local function isLeg(n)
	return n:find("Leg") or n:find("Foot") or n:find("Paw") or n:find("Hoof")
end

------------------------------------------------------------------ local effects
local function emitter(part, kind)
	local byKind = emitters[part]
	if not byKind then byKind = {}; emitters[part] = byKind end
	local em = byKind[kind]
	if not em then
		local fx = FX[kind]
		em = Instance.new("ParticleEmitter")
		em.Name = "IdleFx"
		em.Enabled = false
		em.Color = typeof(fx.color) == "ColorSequence" and fx.color or ColorSequence.new(fx.color)
		em.Size = NumberSequence.new(fx.size, fx.grow and fx.size * 2 or fx.size * 0.3)
		em.Transparency = NumberSequence.new(fx.transparency or 0, 1)
		em.Lifetime = NumberRange.new(fx.life * 0.7, fx.life)
		em.Speed = NumberRange.new(fx.speed * 0.5, fx.speed)
		em.SpreadAngle = Vector2.new(180, 180)
		em.LightEmission = fx.light or 0
		em.Acceleration = fx.accel or Vector3.zero
		em.Parent = part
		byKind[kind] = em
	end
	return em
end

local function burst(part, kind, count)
	if not part or not part.Parent then return end
	emitter(part, kind):Emit(count)
end

-- a steady local stream (e.g. Leviathan bubbles), on top of the model's own emitters
local function stream(part, kind, rate)
	if not part or not part.Parent then return end
	local em = emitter(part, kind)
	em.Rate = rate
	em.Enabled = true
end

local function fxPart(shape, size, color, cf, transparency)
	if #fxFolder:GetChildren() >= MAX_FX_PARTS then return nil end
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.Neon
	p.Transparency = transparency
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.CFrame = cf
	p.Parent = fxFolder
	return p
end

local function fadeOut(p, time)
	if not p then return end
	TweenService:Create(p, TweenInfo.new(time), {Transparency = 1}):Play()
	task.delay(time, function() p:Destroy() end)
end

-- Emberhorn: fire hoofprints that fade (03_Pets.md)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function hoofprint(rig, foot)
	rayParams.FilterDescendantsInstances = {rig.model, fxFolder, player.Character}
	local hit = workspace:Raycast(foot.Position + Vector3.new(0, 0.5, 0), Vector3.new(0, -4, 0), rayParams)
	if not hit then return end
	local cf = CFrame.new(hit.Position + Vector3.new(0, 0.03, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	fadeOut(fxPart(Enum.PartType.Cylinder, Vector3.new(0.05, 0.45, 0.45), Color3.fromRGB(255, 110, 30), cf, 0.15), 1.6)
end

-- Leviathan: a ring of water that spreads out along the ground and fades
local function shockwave(position)
	local p = fxPart(Enum.PartType.Cylinder, Vector3.new(0.1, 1, 1), Color3.fromRGB(127, 212, 255), CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2), 0.35)
	if not p then return end
	p.Material = Enum.Material.Glass
	TweenService:Create(p, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(0.1, 11, 11), Transparency = 1}):Play()
	task.delay(1.1, function() p:Destroy() end)
end

-- Aether Dragon: beam of light on spawn
local function lightBeam(position)
	local cf = CFrame.new(position + Vector3.new(0, 12, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	fadeOut(fxPart(Enum.PartType.Cylinder, Vector3.new(24, 1.2, 1.2), Color3.fromRGB(232, 220, 255), cf, 0.3), 1.8)
end

-- Thunder Squash: a short lightning arc between the squash and the ground
local function lightning(rig)
	local from = rig.model:FindFirstChild("Fruit")
	if not from then return end
	local a0 = Instance.new("Attachment")
	a0.Parent = from
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(math.random() * 2 - 1, 0, math.random() * 2 - 1) * 1.5
	a1.Parent = rig.root
	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 240, 120))
	beam.LightEmission = 1
	beam.Width0 = 0.18
	beam.Width1 = 0.06
	beam.FaceCamera = true
	beam.Segments = 8
	beam.CurveSize0 = math.random(-3, 3)
	beam.CurveSize1 = math.random(-3, 3)
	beam.Parent = from
	task.delay(0.18, function()
		beam:Destroy(); a0:Destroy(); a1:Destroy()
	end)
end

------------------------------------------------------------------ rig setup per kind
local Setup, Pose = {}, {}

function Setup.Pet(rig, entries)
	local model = rig.model
	local name = model:GetAttribute("Pet")
	local flying = model:GetAttribute("Flying") == true
	local tune = PETS[name] or (flying and DEFAULT_FLYER or DEFAULT_WALKER)
	rig.tune, rig.flying = tune, flying
	local height = model:GetAttribute("Height") or 2
	local bottom = model:GetAttribute("BottomOffset") or 1
	rig.center = Vector3.new(0, -bottom + height / 2, 0)
	rig.bottomPoint = Vector3.new(0, -bottom, 0)
	local now = os.clock()
	rig.trickAt = rig.trickAt or now + math.random() * (tune.every or 5)
	rig.earAt = rig.earAt or now + 2 + math.random() * 3
	rig.bodyPart = model:FindFirstChild("Body") or rig.root

	local heads = {}
	for _, e in ipairs(entries) do if e.part.Name == "Head" then table.insert(heads, e) end end
	local wingR, wingL, tail, legs, ears = {}, {}, {}, {}, {earL = {}, earR = {}}
	rig.wingParts = {}
	for _, e in ipairs(entries) do
		local n = e.part.Name
		local p = e.rel.Position
		if n:find("Wing") then
			e.group = p.X >= 0 and "wingR" or "wingL"
			table.insert(e.group == "wingR" and wingR or wingL, face(e.rel, e.part.Size, nearMidline))
			table.insert(rig.wingParts, e.part)
		elseif n:find("Tail") then
			e.group = "tail"
			table.insert(tail, face(e.rel, e.part.Size, nearCentre))
		elseif not flying and isLeg(n) then
			table.insert(legs, e)
		elseif n:find("^Ear") then
			e.group = p.X >= 0 and "earR" or "earL"
			if n == "Ear" then table.insert(ears[e.group], face(e.rel, e.part.Size, lowest)) end
		elseif tune.orbit and n == tune.orbit then
			e.group = "orbit"
		elseif n == "Snout" then
			rig.snout = e.part
		elseif n == "Orb" then
			rig.orb = e.part
		end
	end
	rig.hingeR, rig.hingeL = average(wingR), average(wingL)
	rig.earHinge = {earL = average(ears.earL), earR = average(ears.earR)}
	rig.orbitCenter = #heads == 1 and heads[1].rel.Position or nil
	-- the tail swings from its innermost point
	local best
	for _, p in ipairs(tail) do if not best or p.Magnitude < best.Magnitude then best = p end end
	rig.hingeTail = best

	-- legs: one cluster per corner (leg + foot/hoof/paw), hinged at the top of the leg
	rig.legs = {}
	if #legs > 0 then
		local meanZ = 0
		for _, e in ipairs(legs) do meanZ += e.rel.Position.Z end
		meanZ /= #legs
		local clusters = {}
		for _, e in ipairs(legs) do
			local p = e.rel.Position
			local side, front = p.X >= 0 and "R" or "L", p.Z < meanZ - 0.05 and "F" or "B"
			local c = clusters[side .. front]
			if not c then
				c = {group = "leg" .. side .. front, footY = math.huge}
				if tune.gait == "bound" then
					c.sign = front == "F" and 1 or -1
				else
					c.sign = ((side == "R") == (front == "F")) and 1 or -1 -- diagonal pairs move together
				end
				clusters[side .. front] = c
				table.insert(rig.legs, c)
			end
			e.group = c.group
			local top = face(e.rel, e.part.Size, highest)
			if not c.top or top.Y > c.top.Y then c.top = top end
			if p.Y < c.footY then c.footY = p.Y; c.foot = e.part end
		end
	end

	-- several heads (Hydra): each neck + head + face parts nod from the base of its neck
	rig.heads = nil
	if tune.heads and #heads > 1 then
		rig.heads = {}
		for i, h in ipairs(heads) do rig.heads[i] = {group = "head" .. i, pos = h.rel.Position} end
		for _, e in ipairs(entries) do
			if e.group == "body" and e.rel.Position.Y > 0.35 then
				local bi, bd
				for i, h in ipairs(rig.heads) do
					local d = (e.rel.Position - h.pos).Magnitude
					if not bd or d < bd then bi, bd = i, d end
				end
				if bd < 1.1 then
					local h = rig.heads[bi]
					e.group = h.group
					local low = face(e.rel, e.part.Size, lowest)
					if not h.base or low.Y < h.base.Y then h.base = low end
				end
			end
		end
	end

	-- coiled serpent (Leviathan): every coil swims around the orb at the Root; the orb core pulses, spots glow
	if tune.coil then
		for _, e in ipairs(entries) do
			local n = e.part.Name
			if n == "Orb" or n == "OrbCore" then
				e.group = "orb"
				e.pulse = n == "OrbCore"
			else
				e.group = "coil"
				e.theta = math.atan2(e.rel.Position.X, e.rel.Position.Z)
				e.glow = n == "Spot"
			end
		end
		rig.orbLight = rig.orb and rig.orb:FindFirstChildOfClass("PointLight")
		if rig.orbLight and not rig.orbLightBase then rig.orbLightBase = rig.orbLight.Brightness end
		rig.surgeAt = rig.surgeAt or now + 2 + math.random() * 2
		stream(rig.orb, "bubble", 4)
		stream(rig.orb, "sparkle", 6)
		if tune.droplets and not rig.satellites then
			rig.satellites = {}
			for i = 1, tune.droplets do
				local p = fxPart(Enum.PartType.Ball, Vector3.new(0.28, 0.28, 0.28), Color3.fromRGB(127, 212, 255), rig.root.CFrame, 0.25)
				if p then
					p.Material = Enum.Material.Glass
					table.insert(rig.satellites, {part = p, angle = (i - 1) / tune.droplets * TAU})
				end
			end
		end
	end

	if not rig.anchored then
		-- a following pet: the body rides the physics root; only our own pets get body motion
		local folder = model.Parent
		if folder and folder.Name == player.Name then
			local align = rig.root:FindFirstChildOfClass("AlignPosition")
			rig.attachment = align and align.Attachment0
		end
		if tune.spawnBeam and not rig.beamDone then
			rig.beamDone = true
			lightBeam(rig.root.Position)
		end
	end
end

function Setup.Egg(rig, entries)
	rig.egg = rig.model:GetAttribute("Egg")
	for _, e in ipairs(entries) do
		local n = e.part.Name
		if rig.egg == "Mystic Egg" then
			if n == "Mist" then e.group = "static" else e.group = "spin" end
			if n == "Rune" or n == "RuneBand" then e.glow = true end
		elseif rig.egg == "Dragon Egg" then
			if n == "Crack" then e.glow = true end
			e.group = "static" -- Dragon Egg breathes through its cracks; the stand stays still
		end
	end
	local shell = rig.model:FindFirstChild("Shell")
	rig.light = shell and shell:FindFirstChildOfClass("PointLight")
	if rig.light and not rig.lightBase then rig.lightBase = rig.light.Brightness end
end

function Setup.Drop(rig, entries) end

function Setup.NestEgg(rig, entries)
	for _, e in ipairs(entries) do
		if e.part.Name == "ReadyBeam" then e.group = "static" end
	end
end

function Setup.Plant(rig, entries)
	local stage = rig.model:GetAttribute("Stage")
	local crop = rig.model:GetAttribute("Crop")
	rig.stage = stage
	rig.slowSway = crop == "Wheat"
	local heartPoints, petals = {}, {}
	for _, e in ipairs(entries) do
		local n = e.part.Name
		if GROUND[n] then
			e.group = "static"
		elseif stage == 4 then
			if crop == "Dragonheart Fruit" and HEART[n] then
				e.group = "heart"
				if n == "Fruit" or n == "Lobe" then table.insert(heartPoints, e.rel.Position) end
			elseif crop == "Honeyroot" and n:find("^Bee") then
				e.group = "orbit" -- two bee motes circling
			elseif crop == "Starbloom Lotus" and (n == "Petal" or n == "Fruit") then
				e.group = "spin" -- slow petal rotation
				if n == "Petal" then table.insert(petals, e.rel.Position) end
			elseif FLUTTER[n] then
				e.group = "flutter"
				e.hinge = face(e.rel, e.part.Size, lowest)
				e.amp = FLUTTER[n]
				e.seed = math.random() * TAU
			end
		end
	end
	rig.heartCenter = average(heartPoints)
	local pc = average(petals)
	rig.spinCenter = pc and Vector3.new(pc.X, 0, pc.Z)
	rig.zapAt = (stage == 4 and crop == "Thunder Squash") and os.clock() + math.random() * 2.5 or nil
	rig.nightLight = nil
	if stage == 4 and crop == "Moonmelon" then
		rig.nightLight = rig.model:FindFirstChildWhichIsA("PointLight", true)
		if rig.nightLight and not rig.nightBase then rig.nightBase = rig.nightLight.Brightness end
	end
	-- one-off "pop" when a plant on a farm tile turns ripe while we watch (02_Seeds_and_Crops.md stage 4)
	local tile = rig.model.Parent
	if tile and tile.Parent and tile.Parent.Name == "Tiles" and not rig.popChecked then
		rig.popChecked = true
		if stage == 4 and tileStage[tile] == 3 then rig.popAt = os.clock() end
		tileStage[tile] = stage
	end
end

------------------------------------------------------------------ poses: fill {group = CFrame or function(entry)} in Root space
local IDENTITY = CFrame.identity

function Pose.Pet(rig, t, groups, dt, now)
	local tune = rig.tune
	-- walking: how fast this pet travels (replicated for other players' pets, 0 for display models)
	local target = 0
	if not rig.anchored then
		local v = rig.root.AssemblyLinearVelocity
		target = math.clamp((Vector3.new(v.X, 0, v.Z).Magnitude - 1) / 6, 0, 1)
	end
	rig.walk = (rig.walk or 0) + (target - (rig.walk or 0)) * math.min(1, dt * 6)
	local walk = rig.walk
	if walk > 0.01 then rig.gait = (rig.gait or 0) + dt * math.pi * (tune.hopHz or 2.6) end
	local phi = rig.gait or 0

	-- signature move
	local trick, u = nil, nil
	if tune.trick then
		if not rig.trickStart and now >= rig.trickAt and not (IDLE_ONLY[tune.trick] and walk > 0.2) then
			rig.trickStart, rig.trickFired = now, false
			rig.trickAt = now + tune.every * (0.8 + math.random() * 0.4)
		end
		if rig.trickStart then
			u = (now - rig.trickStart) / TRICK_TIME[tune.trick]
			if u >= 1 then rig.trickStart, u = nil, nil else trick = tune.trick end
		end
	end
	local fire = trick and not rig.trickFired
	if fire then rig.trickFired = true end

	local x, y, z, pitch, yaw, roll = 0, 0, 0, 0, 0, 0
	if tune.bob then
		local w = TAU * tune.bobHz
		y = tune.bob * sin(w * t)
		pitch = rad(4) * cos(w * t) - rad(10) * walk -- lean into the flight
		if tune.figure8 then x = tune.figure8 * sin(w * 0.5 * t); z = tune.figure8 * 0.5 * sin(w * t) end
	elseif not rig.flying then
		y = 0.05 * sin(TAU * 0.8 * t) * (1 - walk) + (tune.hop or 0.15) * walk * abs(sin(phi))
		if tune.waddle then roll = rad(8) * walk * sin(phi) end
	end
	if tune.sway then
		x += tune.sway * sin(TAU * 0.25 * t)
		yaw = rad(10) * cos(TAU * 0.25 * t)
	end
	if tune.circle then
		local a = TAU * 0.12 * t
		x += tune.circle * cos(a); z += tune.circle * sin(a)
		roll = rad(10) * sin(a)
	end

	local flap = 0
	if tune.flap then
		local beat = sin(TAU * tune.flap * t)
		if tune.burst then
			local c = t % 4
			if c < 1.2 then
				local envelope = sin(math.pi * c / 1.2)
				flap = rad(28) * beat * envelope
				if tune.takeoff then y += 0.25 * envelope end -- flaps and fails to take off
			end
		else
			flap = rad(30) * beat
		end
		if tune.flapFx and rig.lastBeat and rig.lastBeat > 0 and beat <= 0 then burst(rig.wingParts[1], tune.flapFx, 3) end
		rig.lastBeat = beat
	end

	if trick == "backflip" then
		y += 0.5 * sin(math.pi * u)
	elseif trick == "sneeze" then
		pitch += rad(12) * sin(TAU * u) -- head back, then forward
		if u > 0.5 and not rig.sneezed then rig.sneezed = true; burst(rig.snout or rig.bodyPart, "spark", 12) end
	elseif trick == "flare" then
		flap = rad(70) * math.min(1, sin(math.pi * u) * 1.6)
	end
	if trick ~= "sneeze" then rig.sneezed = nil end
	if fire then
		if trick == "puff" then burst(rig.bodyPart, "puff", 4)
		elseif trick == "zap" then burst(rig.bodyPart, "zap", 14)
		elseif trick == "bubbles" then burst(rig.orb or rig.bodyPart, "bubble", 3)
		elseif trick == "flare" then for _, w in ipairs(rig.wingParts) do burst(w, "ember", 6) end end
	end

	local body = CFrame.new(x, y, z) * CFrame.Angles(pitch, yaw, roll)
	if trick == "backflip" then body = body * hinge(rig.center, CFrame.Angles(TAU * ease(u), 0, 0)) end
	-- following pets: the body moves through physics, joints are relative to Root
	local jointBase = rig.anchored and body or IDENTITY
	groups.body = body
	if rig.attachment then rig.attachment.CFrame = body:Inverse() end

	if rig.hingeR then groups.wingR = jointBase * hinge(rig.hingeR, CFrame.Angles(0, 0, flap)) end
	if rig.hingeL then groups.wingL = jointBase * hinge(rig.hingeL, CFrame.Angles(0, 0, -flap)) end
	if rig.hingeTail then
		local swish = rad(12) * sin(TAU * (tune.tailHz or 0.8) * t) + rad(10) * walk * sin(phi)
		groups.tail = jointBase * hinge(rig.hingeTail, CFrame.Angles(0, swish, 0))
	end

	-- walk cycle
	local lift = rad(tune.prance and 40 or 28) * walk * sin(phi)
	for _, leg in ipairs(rig.legs) do
		local g = jointBase * hinge(leg.top, CFrame.Angles(lift * leg.sign, 0, 0))
		if trick == "thump" and leg.group == "legRB" then g = g * CFrame.new(0, 0.15 * abs(sin(3 * math.pi * u)), 0) end
		groups[leg.group] = g
	end
	local step = math.floor(phi / math.pi)
	if tune.stepFx and rig.lastStep and step ~= rig.lastStep and walk > 0.5 then
		local landing = step % 2 == 0 and -1 or 1
		for _, leg in ipairs(rig.legs) do
			if leg.sign == landing and leg.foot then
				if tune.stepFx == "fire" then hoofprint(rig, leg.foot) else burst(leg.foot, tune.stepFx, 3) end
			end
		end
	end
	rig.lastStep = step

	-- ear twitch every few seconds
	local earL, earR = 0, 0
	if rig.earHinge.earL or rig.earHinge.earR then
		if not rig.earStart and now >= rig.earAt then
			rig.earStart, rig.earSide = now, math.random(3)
			rig.earAt = now + 2.5 + math.random() * 3
		end
		if rig.earStart then
			local v = (now - rig.earStart) / 0.3
			if v >= 1 then
				rig.earStart = nil
			else
				local a = rad(18) * sin(math.pi * v)
				if rig.earSide ~= 2 then earL = a end
				if rig.earSide ~= 1 then earR = -a end
			end
		end
		if rig.earHinge.earL then groups.earL = jointBase * hinge(rig.earHinge.earL, CFrame.Angles(0, 0, earL)) end
		if rig.earHinge.earR then groups.earR = jointBase * hinge(rig.earHinge.earR, CFrame.Angles(0, 0, earR)) end
	end

	-- heads nod out of sync; now and then the outer two bonk the middle one
	if rig.heads then
		for i, h in ipairs(rig.heads) do
			if h.base then
				local lean = 0
				if trick == "bonk" then lean = rad(20) * sin(math.pi * u) * (h.pos.X > 0.2 and 1 or h.pos.X < -0.2 and -1 or 0) end
				groups[h.group] = jointBase * hinge(h.base, CFrame.Angles(rad(8) * sin(TAU * 0.45 * t + i * 2.1), 0, lean))
			end
		end
	end

	if rig.orbitCenter then groups.orbit = jointBase * hinge(rig.orbitCenter, CFrame.Angles(0, 2.2 * t, 0)) end

	if tune.coil then
		-- the coils swim one slow lap around the orb every 9 s, with a wave rolling through them
		local swim = jointBase * CFrame.Angles(0, -TAU * t / 9, 0)
		groups.coil = function(e) return swim * CFrame.new(0, 0.14 * sin(2 * e.theta - 2.4 * t), 0) end
		groups.orb = jointBase * CFrame.Angles(0, 0.5 * t, 0)
		rig.glow = 0.5 - 0.5 * cos(TAU * 0.6 * t)
		rig.pulseScale = 1 + 0.15 * (0.5 - 0.5 * cos(TAU * 0.8 * t))
		-- tidal surge: water ring, bubble burst and a flash from the orb
		if now >= rig.surgeAt then
			rig.surgeAt = now + tune.surge * (0.8 + math.random() * 0.4)
			rig.surgeStart = now
			shockwave((rig.root.CFrame * CFrame.new(rig.bottomPoint)).Position)
			burst(rig.orb, "bubble", 14)
			burst(rig.orb, "sparkle", 20)
		end
		local flash = 0
		if rig.surgeStart then
			local age = now - rig.surgeStart
			if age < 1 then flash = 1 - age else rig.surgeStart = nil end
		end
		if rig.orbLight then rig.orbLight.Brightness = rig.orbLightBase * (1 + 0.4 * rig.glow + 2 * flash) end
		-- water droplets orbit the other way, rising and falling
		if rig.satellites then
			for _, s in ipairs(rig.satellites) do
				local a = s.angle + 0.8 * t
				s.cf = jointBase * CFrame.new(cos(a) * 2.1, 0.3 * sin(3 * s.angle + 2 * t), sin(a) * 2.1)
			end
		end
	end
end

function Pose.Egg(rig, t, groups)
	if rig.egg == "Hatchling Egg" then
		-- gentle wobble every few seconds
		local c = t % 3.5
		local a = c < 1 and rad(9) * sin(TAU * 2.5 * c) * (1 - c) or 0
		groups.body = CFrame.Angles(a * 0.4, 0, a)
	elseif rig.egg == "Mystic Egg" then
		-- slow spin and float over the mist; runes pulse
		groups.spin = CFrame.new(0, 0.12 * sin(TAU * 0.4 * t), 0) * CFrame.Angles(0, TAU * t / 12, 0)
		rig.glow = 0.5 - 0.5 * cos(TAU * 0.5 * t)
	elseif rig.egg == "Dragon Egg" then
		-- cracks pulse like breathing
		rig.glow = 0.5 - 0.5 * cos(TAU * 0.3 * t)
	end
end

function Pose.Drop(rig, t, groups)
	-- dropped items float a little above the ground and turn slowly so they catch the eye
	groups.body = CFrame.new(0, 0.3 + 0.2 * sin(TAU * 0.5 * t), 0) * CFrame.Angles(0, 1.2 * t, 0)
end

function Pose.NestEgg(rig, t, groups)
	if rig.model:GetAttribute("Ready") or rig.model:FindFirstChild("ReadyBeam") then
		-- ready: bounce
		groups.body = CFrame.new(0, 0.45 * abs(sin(math.pi * 1.2 * t)), 0)
	else
		-- breeding: slow wobble
		groups.body = CFrame.Angles(rad(2) * cos(TAU * 0.3 * t), 0, rad(4) * sin(TAU * 0.45 * t))
	end
end

function Pose.Plant(rig, t, groups, dt, now)
	local ripe = rig.stage == 4
	local amp, hzA, hzB = rad(ripe and 3 or 2), 0.3, 0.23
	if ripe and rig.slowSway then amp, hzA, hzB = rad(5), 0.16, 0.12 end
	local y = 0
	if ripe then
		local c = t % 2.8
		if c < 0.4 then y = 0.15 * sin(math.pi * c / 0.4) end
	end
	if rig.popAt then
		local age = now - rig.popAt
		if age < 0.6 then y = 0.6 * sin(math.pi * age / 0.6) else rig.popAt = nil end
	end
	local body = CFrame.new(0, y, 0) * CFrame.Angles(amp * sin(TAU * hzA * t), 0, amp * cos(TAU * hzB * t))
	groups.body = body
	if rig.heartCenter then rig.scale = 1 + 0.04 * (1 - cos(TAU * t)) end
	groups.flutter = function(e)
		return body * hinge(e.hinge, CFrame.Angles(rad(8) * e.amp * sin(TAU * 2 * t + e.seed), 0, rad(6) * e.amp * cos(TAU * 1.7 * t + e.seed)))
	end
	groups.orbit = body * CFrame.new(0, 0.15 * sin(TAU * 1.3 * t), 0) * CFrame.Angles(0, TAU * 0.25 * t, 0)
	if rig.spinCenter then groups.spin = body * hinge(rig.spinCenter, CFrame.Angles(0, TAU * t / 40, 0)) end
	if rig.zapAt and now >= rig.zapAt then
		rig.zapAt = now + 2 + math.random()
		lightning(rig)
	end
	if rig.nightLight then
		local clock = Lighting.ClockTime
		rig.nightLight.Brightness = rig.nightBase * ((clock < 6 or clock >= 18) and 2 or 1)
	end
end

------------------------------------------------------------------ tracking
local function buildRig(rig)
	local model = rig.model
	local root = model.PrimaryPart or model:FindFirstChild("Root")
	if not root then return false end
	rig.root = root
	rig.anchored = root.Anchored
	local rootInv = root.CFrame:Inverse()
	local entries = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= root and d:FindFirstAncestorOfClass("Model") == model then
			if not baseRel[d] then
				baseRel[d] = rootInv * d.CFrame
				baseSize[d] = d.Size
				baseTransparency[d] = d.Transparency
			end
			table.insert(entries, {part = d, rel = baseRel[d], group = "body"})
		end
	end
	Setup[rig.kind](rig, entries)
	if not rig.anchored then
		-- following pets: joint only the moving parts; everything else stays on its WeldConstraint
		local jointed = {}
		for _, e in ipairs(entries) do
			if e.group ~= "body" then
				local weld = rig.welds[e.part]
				if not weld then
					weld = Instance.new("Weld")
					weld.Name = "IdleJoint"
					weld.Part0 = root
					weld.Part1 = e.part
					weld.C0 = e.rel
					weld.Parent = e.part
					rig.welds[e.part] = weld
					for _, c in ipairs(e.part:GetChildren()) do
						if c:IsA("WeldConstraint") then c.Enabled = false end
					end
				end
				e.weld = weld
				table.insert(jointed, e)
			end
		end
		entries = jointed
	end
	rig.entries = entries
	return true
end

local function markDirty(rig)
	rig.dirty = true
	rig.rebuildAt = os.clock() + REBUILD_DELAY
end

local function untrack(model)
	local rig = rigs[model]
	if not rig then return end
	rigs[model] = nil
	for _, c in ipairs(rig.connections) do c:Disconnect() end
	if rig.satellites then
		for _, s in ipairs(rig.satellites) do s.part:Destroy() end
	end
end

local function track(model)
	if rigs[model] or not model:IsA("Model") then return end
	local kind = kindOf(model)
	if not kind or inGemItem(model) then return end
	local rig = {model = model, kind = kind, phase = math.random() * 10, welds = {}, entries = {}, connections = {}}
	rigs[model] = rig
	local function onPart(d)
		if d:IsA("BasePart") and not d:IsDescendantOf(fxFolder) then markDirty(rig) end
	end
	table.insert(rig.connections, model.DescendantAdded:Connect(onPart))
	table.insert(rig.connections, model.DescendantRemoving:Connect(onPart))
	table.insert(rig.connections, model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(workspace) then untrack(model) end
	end))
	markDirty(rig)
end

local function watch(container)
	for _, d in ipairs(container:GetDescendants()) do track(d) end
	container.DescendantAdded:Connect(track)
end

------------------------------------------------------------------ main loop
local moveParts, moveCFrames = {}, {}

RunService.PreSimulation:Connect(function(dt)
	local now = os.clock()
	local n = 0
	for _, rig in pairs(rigs) do
		if rig.dirty and now >= rig.rebuildAt then
			rig.dirty = not buildRig(rig)
			if rig.dirty then rig.rebuildAt = now + 1 end
		end
		if rig.active and not rig.dirty and rig.root.Parent then
			local groups = {body = IDENTITY, static = IDENTITY}
			Pose[rig.kind](rig, now + rig.phase, groups, dt, now)
			local rootCF = rig.root.CFrame
			for _, e in ipairs(rig.entries) do
				local g = groups[e.group] or groups.body
				if type(g) == "function" then g = g(e) end
				local rel = e.rel
				if e.group == "heart" and rig.scale then
					local c = rig.heartCenter
					rel = CFrame.new(c + (rel.Position - c) * rig.scale) * rel.Rotation
					e.part.Size = baseSize[e.part] * rig.scale
				end
				if e.glow and rig.glow then
					e.part.Transparency = baseTransparency[e.part] + 0.5 * rig.glow
				end
				if e.pulse and rig.pulseScale then
					e.part.Size = baseSize[e.part] * rig.pulseScale
				end
				if e.weld then
					e.weld.C0 = g * rel
				elseif rig.anchored and e.group ~= "static" then
					n += 1
					moveParts[n] = e.part
					moveCFrames[n] = rootCF * g * rel
				end
			end
			if rig.light and rig.glow then rig.light.Brightness = rig.lightBase * (1 - 0.5 * rig.glow) end
			if rig.satellites then
				for _, s in ipairs(rig.satellites) do
					if s.cf and s.part.Parent then
						n += 1
						moveParts[n] = s.part
						moveCFrames[n] = rootCF * s.cf
					end
				end
			end
		end
	end
	for i = #moveParts, n + 1, -1 do moveParts[i] = nil; moveCFrames[i] = nil end
	if n > 0 then workspace:BulkMoveTo(moveParts, moveCFrames, Enum.BulkMoveMode.FireCFrameChanged) end
end)

-- distance culling
task.spawn(function()
	while true do
		local cam = workspace.CurrentCamera
		local eye = cam and cam.CFrame.Position
		for _, rig in pairs(rigs) do
			rig.active = eye ~= nil and rig.root ~= nil and rig.root.Parent ~= nil
				and (rig.root.Position - eye).Magnitude <= ACTIVE_RANGE
		end
		task.wait(CULL_INTERVAL)
	end
end)

for _, name in ipairs({"ActivePets", "Plots", "Showcase", "Drops"}) do
	task.spawn(function()
		local container = workspace:WaitForChild(name, 30)
		if container then watch(container) end
	end)
end
task.spawn(function()
	local village = workspace:WaitForChild("Village", 30)
	local displays = village and village:WaitForChild("EggDisplays", 30)
	if displays then watch(displays) end
end)
