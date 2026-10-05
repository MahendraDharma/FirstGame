-- ModelKit: helpers for building stylised low-poly models out of parts.
-- Models are authored around the origin, then scaled and welded by :finish().
local Kit = {}
Kit.__index = Kit

local M = Enum.Material
Kit.Mat = M

local function col(c)
	if typeof(c) == "string" then return Color3.fromHex(c) end
	return c
end
Kit.col = col

local function toCF(at)
	if typeof(at) == "Vector3" then return CFrame.new(at) end
	return at
end

function Kit.new(name)
	local m = Instance.new("Model")
	m.Name = name
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.Transparency = 1
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Anchored = true
	root.CFrame = CFrame.new()
	root.Parent = m
	m.PrimaryPart = root
	return setmetatable({Model = m, Root = root}, Kit)
end

local function basePart(self, class, name, size, at, color, mat)
	local p = Instance.new(class)
	p.Name = name
	p.Size = size
	p.CFrame = toCF(at)
	p.Color = col(color)
	p.Material = mat or M.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Parent = self.Model
	return p
end

function Kit:block(name, size, at, color, mat)
	return basePart(self, "Part", name, size, at, color, mat)
end

-- Ellipsoid of any proportions (Block + Sphere mesh so it can be non-uniform)
function Kit:ball(name, size, at, color, mat)
	if typeof(size) == "number" then size = Vector3.new(size, size, size) end
	local p = basePart(self, "Part", name, size, at, color, mat)
	local sm = Instance.new("SpecialMesh")
	sm.MeshType = Enum.MeshType.Sphere
	sm.Parent = p
	return p
end

-- Cylinder whose length runs along the CFrame's UpVector
function Kit:cyl(name, length, diameter, at, color, mat)
	local p = basePart(self, "Part", name, Vector3.new(length, diameter, diameter), toCF(at) * CFrame.Angles(0, 0, math.pi / 2), color, mat)
	p.Shape = Enum.PartType.Cylinder
	return p
end

function Kit:wedge(name, size, at, color, mat)
	return basePart(self, "WedgePart", name, size, at, color, mat)
end

function Kit:corner(name, size, at, color, mat)
	return basePart(self, "CornerWedgePart", name, size, at, color, mat)
end

-- Tapered (optionally curving) tube made of stacked cylinders.
-- Grows along baseCF.UpVector; bend (radians per step) curls it toward local +Z.
-- Returns the CFrame at the tip, and the parts.
function Kit:taper(name, baseCF, length, r0, r1, steps, color, mat, bend)
	bend = bend or 0
	local seg = length / steps
	local cf = baseCF
	local parts = {}
	for i = 0, steps - 1 do
		local t = (i + 0.5) / steps
		local d = math.max((r0 + (r1 - r0) * t) * 2, 0.04)
		cf = cf * CFrame.Angles(bend, 0, 0)
		table.insert(parts, self:cyl(name, seg * 1.2, d, cf * CFrame.new(0, seg / 2, 0), color, mat))
		cf = cf * CFrame.new(0, seg, 0)
	end
	return cf, parts
end

-- Cartoon eyes on the front (-Z) of a head of radius r
function Kit:eyes(headCF, r, spread, iris, style)
	iris = iris or "#141414"
	for _, s in ipairs({-1, 1}) do
		local pos = headCF * CFrame.new(s * spread * r, 0.12 * r, -0.86 * r)
		if style == "sleepy" then
			self:block("Eye", Vector3.new(0.34 * r, 0.06 * r, 0.06 * r), pos, iris)
		elseif style == "happy" then
			self:block("Eye", Vector3.new(0.2 * r, 0.06 * r, 0.06 * r), pos * CFrame.new(-0.07 * r, 0, 0) * CFrame.Angles(0, 0, math.rad(35)), iris)
			self:block("Eye", Vector3.new(0.2 * r, 0.06 * r, 0.06 * r), pos * CFrame.new(0.07 * r, 0, 0) * CFrame.Angles(0, 0, math.rad(-35)), iris)
		else
			self:ball("Eye", Vector3.new(0.28 * r, 0.38 * r, 0.12 * r), pos, iris)
			self:ball("EyeShine", Vector3.new(0.1 * r, 0.1 * r, 0.05 * r), pos * CFrame.new(0.05 * r, 0.09 * r, -0.06 * r), "#FFFFFF", M.Neon)
			if style == "grumpy" then
				self:block("Brow", Vector3.new(0.34 * r, 0.07 * r, 0.06 * r), pos * CFrame.new(0, 0.26 * r, -0.02 * r) * CFrame.Angles(0, 0, math.rad(-22 * s)), iris)
			end
		end
	end
end

-- Small floating rune sigil (marks breed-only hybrids); faces -Z
function Kit:sigil(at, size)
	size = size or 0.4
	local cf = toCF(at)
	for i = 0, 7 do
		local a = i * math.pi / 4
		self:block("Sigil", Vector3.new(size * 0.3, size * 0.06, size * 0.06), cf * CFrame.Angles(0, 0, a) * CFrame.new(0, size, 0), "#3CE6F0", M.Neon)
	end
	self:block("Sigil", Vector3.new(size * 0.35, size * 0.35, size * 0.06), cf * CFrame.Angles(0, 0, math.rad(45)), "#3CE6F0", M.Neon)
end

-- Ring of small blocks (bands, halos, glow rings); ring lies in the cf's XZ plane
function Kit:ring(name, cf, radius, thickness, count, color, mat, transparency)
	local parts = {}
	local segLen = 2 * math.pi * radius / count * 1.1
	for i = 0, count - 1 do
		local a = i * 2 * math.pi / count
		local p = self:block(name, Vector3.new(segLen, thickness, thickness), cf * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, radius), color, mat)
		if transparency then p.Transparency = transparency end
		table.insert(parts, p)
	end
	return parts
end

------------------------------------------------------------------ effects
function Kit.light(part, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color = col(color)
	l.Range = range or 8
	l.Brightness = brightness or 1.5
	l.Shadows = false
	l.Parent = part
	return l
end

function Kit.particles(part, color, o)
	o = o or {}
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(col(color))
	e.LightEmission = o.light or 1
	e.LightInfluence = 0
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, o.size or 0.2), NumberSequenceKeypoint.new(1, 0)})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, o.alpha or 0.1), NumberSequenceKeypoint.new(1, 1)})
	e.Rate = o.rate or 4
	e.Lifetime = NumberRange.new(o.life or 1, (o.life or 1) * 1.5)
	e.Speed = NumberRange.new(o.speed or 0.5)
	e.SpreadAngle = Vector2.new(o.spread or 180, o.spread or 180)
	e.EmissionDirection = o.dir or Enum.NormalId.Top
	e.Acceleration = o.accel or Vector3.zero
	e.Drag = o.drag or 0
	e.RotSpeed = NumberRange.new(-90, 90)
	if o.texture then e.Texture = o.texture end
	e.Parent = part
	return e
end

function Kit.flame(part, color, size)
	return Kit.particles(part, color, {size = size or 0.35, rate = 18, life = 0.5, speed = 1.2, spread = 15, accel = Vector3.new(0, 2, 0), texture = "rbxasset://textures/particles/fire_main.dds"})
end

function Kit.smoke(part, size)
	return Kit.particles(part, "#3A3A3A", {size = size or 0.4, rate = 3, life = 2, speed = 0.6, spread = 20, light = 0, alpha = 0.6, texture = "rbxasset://textures/particles/smoke_main.dds"})
end

-- Rarity effects (01_Art_Direction.md section 4). element = the item's own glow colour.
function Kit.tierFx(part, rarity, element)
	if not part then return end
	if rarity == "Rare" then
		Kit.particles(part, element, {size = 0.12, rate = 2, life = 1.2, speed = 0.3})
	elseif rarity == "Epic" then
		Kit.light(part, element, 6, 1.2)
		Kit.particles(part, element, {size = 0.18, rate = 4, life = 1.6, speed = 0.4})
	elseif rarity == "Legendary" then
		Kit.light(part, element, 8, 1.5)
		Kit.particles(part, element, {size = 0.22, rate = 8, life = 1.4, speed = 0.8, accel = Vector3.new(0, 1, 0)})
	elseif rarity == "Mythic" then
		Kit.light(part, element, 10, 1.8)
		Kit.particles(part, element, {size = 0.45, rate = 10, life = 1.2, speed = 1, alpha = 0.5})
	elseif rarity == "Divine" then
		Kit.light(part, element, 12, 2)
		Kit.particles(part, "#FFFFFF", {size = 0.2, rate = 14, life = 2, speed = 0.4, texture = "rbxasset://textures/particles/sparkles_main.dds"})
	end
end

------------------------------------------------------------------ finishing
function Kit:parts()
	local list = {}
	for _, p in ipairs(self.Model:GetDescendants()) do
		if p:IsA("BasePart") and p ~= self.Root then table.insert(list, p) end
	end
	return list
end

function Kit:bounds()
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = -minV
	for _, p in ipairs(self:parts()) do
		local h = p.Size / 2
		for _, sx in ipairs({-1, 1}) do
			for _, sy in ipairs({-1, 1}) do
				for _, sz in ipairs({-1, 1}) do
					local w = p.CFrame:PointToWorldSpace(Vector3.new(h.X * sx, h.Y * sy, h.Z * sz))
					minV = minV:Min(w)
					maxV = maxV:Max(w)
				end
			end
		end
	end
	return minV, maxV
end

-- Uniform scale about the origin (parts, attachments, lights, beams)
function Kit:scale(f)
	for _, d in ipairs(self.Model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= self.Root then
			d.Size *= f
			d.CFrame = CFrame.new(d.Position * f) * d.CFrame.Rotation
		elseif d:IsA("Attachment") then
			d.Position *= f
		elseif d:IsA("PointLight") then
			d.Range = math.min(d.Range * math.max(f, 0.6), 60)
		elseif d:IsA("Beam") then
			d.Width0 *= f
			d.Width1 *= f
		end
	end
end

function Kit:fitHeight(h)
	local lo, hi = self:bounds()
	local cur = hi.Y - lo.Y
	if cur > 0 then self:scale(h / cur) end
end

-- Scale so the longest side (X, Y or Z) equals s; used for long serpent pets
function Kit:fitMax(s)
	local lo, hi = self:bounds()
	local d = hi - lo
	local cur = math.max(d.X, d.Y, d.Z)
	if cur > 0 then self:scale(s / cur) end
end

-- anchored=true: everything anchored (crops, props). false: welded to Root (pets).
function Kit:finish(anchored)
	for _, p in ipairs(self:parts()) do
		p.Massless = true
		if not anchored then
			local w = Instance.new("WeldConstraint")
			w.Part0 = self.Root
			w.Part1 = p
			w.Parent = p
			p.Anchored = false
		end
	end
	if not anchored then self.Root.Anchored = false end
	return self.Model
end

return Kit
