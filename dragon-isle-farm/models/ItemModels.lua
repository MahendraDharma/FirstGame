-- ItemModels: shop eggs, the Breeding Nest egg, and Gem Store items.
-- Specs: 04_Eggs_and_Hatching.md and 05_Gem_Store_Items.md. Origin at the base; front is -Z.
local Kit = require(script.Parent.ModelKit)
local Config = require(script.Parent.Parent.GameConfig)
local M = Enum.Material
local rad = math.rad
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles

local Items = {}

-- point on an ellipsoid surface (radii a, b, a) centred at c
local function surface(c, a, b, theta, phi, push)
	push = push or 1
	return c + V(a * math.cos(phi) * math.cos(theta), b * math.sin(phi), a * math.cos(phi) * math.sin(theta)) * push
end

-- CFrame on the egg surface, facing outward (-Z points out)
local function onSurface(c, a, b, theta, phi)
	local p = surface(c, a, b, theta, phi, 0.98)
	return CFrame.lookAt(p, p + (p - c).Unit)
end

-- width of the egg at height dy from its centre
local function widthAt(a, b, dy)
	return 2 * a * math.sqrt(math.max(0, 1 - (dy / b) ^ 2))
end

------------------------------------------------------------------ shop eggs
local EGGS = {}

EGGS["Hatchling Egg"] = function(k)
	local a, b = 0.62, 0.8
	local c = V(0, 0.8, 0)
	local shell = k:ball("Shell", V(a * 2, b * 2, a * 2), c, "#F0E6C8")
	local spots = {{0.3, 0.5}, {1.4, 0.2}, {2.5, 0.55}, {3.6, 0.1}, {4.6, 0.45}, {5.5, -0.15}, {0.9, -0.3}, {3.1, -0.4}}
	for _, s in ipairs(spots) do
		k:ball("Speckle", V(0.14, 0.11, 0.05), onSurface(c, a, b, s[1], s[2]), "#8C6A46")
	end
	k:cyl("StrawBand", 0.16, widthAt(a, b, -0.25) * 1.06, CF(c + V(0, -0.25, 0)), "#D8BE78", M.Fabric)
	for i = 0, 5 do
		local th = i * math.pi / 3
		k:block("Straw", V(0.04, 0.25, 0.04), CF(surface(c + V(0, -0.25, 0), a * 0.95, 0.01, th, 0, 1.08)) * ANG(0, -th, rad(20)), "#C9A75C")
	end
	return shell
end

EGGS["Mystic Egg"] = function(k)
	local a, b = 0.7, 0.9
	local c = V(0, 1.25, 0)
	local shell = k:ball("Shell", V(a * 2, b * 2, a * 2), c, "#A06EFF")
	for _, dy in ipairs({0.28, -0.2}) do
		k:cyl("RuneBand", 0.08, widthAt(a, b, dy) * 1.03, CF(c + V(0, dy, 0)), "#D8C4FF", M.Neon)
	end
	for i = 0, 3 do
		local th = i * math.pi / 2
		k:block("Rune", V(0.05, 0.2, 0.03), onSurface(c, a, b, th, 0.05), "#F3EAFF", M.Neon)
	end
	for i = 0, 4 do
		local x = math.cos(i * 1.3) * 0.4
		local z = math.sin(i * 1.3) * 0.4
		local m = k:ball("Mist", V(0.6, 0.3, 0.6), V(x, 0.15, z), "#FFFFFF")
		m.Transparency = 0.55
	end
	Kit.light(shell, "#A06EFF", 6, 1)
	Kit.particles(shell, "#D8C4FF", {size = 0.12, rate = 3, life = 1.5, speed = 0.3})
	return shell
end

EGGS["Dragon Egg"] = function(k)
	local a, b = 0.75, 1.0
	local c = V(0, 1.3, 0)
	local shell = k:ball("Shell", V(a * 2, b * 2, a * 2), c, "#C83228")
	local i = 0
	for _, phi in ipairs({-0.3, 0.35}) do
		for j = 0, 4 do
			i += 1
			k:ball("Scale", V(0.34, 0.24, 0.06), onSurface(c, a, b, j * math.pi * 0.4 + (i % 2) * 0.6, phi), "#8E1F18")
		end
	end
	for _, th in ipairs({0.6, 2.4, 4.3}) do
		local base = onSurface(c, a, b, th, 0.15)
		k:block("Crack", V(0.05, 0.4, 0.04), base * ANG(0, 0, rad(25)), "#FF8C3C", M.Neon)
		k:block("Crack", V(0.05, 0.3, 0.04), base * CF(0.08, -0.3, 0) * ANG(0, 0, rad(-30)), "#FF8C3C", M.Neon)
	end
	k:cyl("Stand", 0.3, 1.6, CF(0, 0.15, 0), "#FFBE28", M.Foil)
	for j = 0, 3 do
		local th = j * math.pi / 2 + math.pi / 4
		local pos = V(math.cos(th) * 0.8, 0.25, math.sin(th) * 0.8)
		local cf = CFrame.lookAt(pos, V(0, pos.Y, 0)) * ANG(rad(12), 0, 0)
		k:taper("Claw", cf, 1.1, 0.12, 0.04, 3, "#FFBE28", M.Foil, rad(-18))
	end
	Kit.light(shell, "#FF8C3C", 7, 1.3)
	Kit.particles(shell, "#FF8C3C", {size = 0.12, rate = 4, life = 1.2, speed = 0.6, accel = V(0, 1, 0)})
	return shell
end

function Items.Egg(name)
	local build = EGGS[name]
	if not build then return nil end
	local k = Kit.new(name)
	build(k)
	k.Model:SetAttribute("Egg", name)
	return k:finish(true)
end

------------------------------------------------------------------ breeding nest egg
-- rarity colours the shell; secret = a hybrid recipe is growing (rune ring)
function Items.NestEgg(rarity, secret)
	local color = Config.RarityColor(rarity)
	local k = Kit.new("BreedEgg")
	local a, b = 1.1, 1.5
	local c = V(0, 1.5, 0)
	local shell = k:ball("Shell", V(a * 2, b * 2, a * 2), c, color)
	for i = 0, 1 do
		k:ball("Swirl", V(a * 2 * 1.02, b * 0.35, a * 2 * 1.02), CF(c + V(0, -0.35 + i * 0.7, 0)) * ANG(rad(18), i * 1.2, rad(-12)), color:Lerp(Color3.new(1, 1, 1), 0.45))
	end
	if secret then
		k:ring("RuneRing", CF(c), 1.55, 0.1, 16, Kit.col("#3CE6F0"), M.Neon)
		k:sigil(CF(c + V(0, 0, -1.7)), 0.3)
	end
	shell.Name = "Shell"
	k.Model:SetAttribute("Rarity", rarity)
	return k:finish(true)
end

-- Ready state: glowing shell + a beam of light so the owner can spot it from the village
function Items.SetNestReady(model, ready)
	local shell = model:FindFirstChild("Shell")
	if not shell then return end
	shell.Material = ready and M.Neon or M.SmoothPlastic
	local beam = model:FindFirstChild("ReadyBeam")
	if ready and not beam then
		beam = Instance.new("Part")
		beam.Name = "ReadyBeam"
		beam.Shape = Enum.PartType.Cylinder
		beam.Anchored = true
		beam.CanCollide = false
		beam.CanQuery = false
		beam.CanTouch = false
		beam.CastShadow = false
		beam.Material = M.Neon
		beam.Color = shell.Color
		beam.Transparency = 0.7
		beam.Size = V(30, 0.8, 0.8)
		beam.CFrame = CF(shell.Position + V(0, 15, 0)) * ANG(0, 0, math.pi / 2)
		beam.Parent = model
	elseif not ready and beam then
		beam:Destroy()
	end
end

------------------------------------------------------------------ Gem Store items
local GEM = {}

local function dragonHead(k, cf, size, color, mat, eyeColor)
	k:ball("DragonHead", V(0.5, 0.42, 0.55) * size, cf, color, mat)
	k:ball("DragonSnout", V(0.32, 0.25, 0.35) * size, cf * CF(0, -0.05 * size, -0.3 * size), color, mat)
	for _, s in ipairs({-1, 1}) do
		k:taper("DragonHorn", cf * CF(s * 0.14 * size, 0.18 * size, 0.12 * size) * ANG(rad(40), 0, rad(-s * 15)), 0.25 * size, 0.05 * size, 0.015 * size, 2, color, mat)
		k:ball("DragonEye", 0.08 * size, cf * CF(s * 0.14 * size, 0.06 * size, -0.24 * size), eyeColor or "#141414", eyeColor and M.Neon or nil)
	end
end

GEM["Golden Watering Can"] = function(k)
	local gold = "#FFBE28"
	local body = k:cyl("Can", 1.0, 1.0, CF(0, 0.5, 0), gold, M.Foil)
	k:cyl("Rim", 0.08, 1.06, CF(0, 1.0, 0), "#E0A21A", M.Foil)
	k:block("Handle", V(0.14, 0.14, 0.55), CF(0, 1.3, 0.25), gold, M.Foil)
	k:block("Handle", V(0.14, 0.6, 0.14), CF(0, 1.05, 0.52), gold, M.Foil)
	k:block("Handle", V(0.14, 0.4, 0.14), CF(0, 1.15, -0.02), gold, M.Foil)
	local tip = k:taper("Spout", CF(0, 0.35, -0.42) * ANG(rad(-55), 0, 0), 0.9, 0.11, 0.07, 3, gold, M.Foil)
	dragonHead(k, tip * ANG(rad(55), 0, 0) * CF(0, 0, -0.12), 0.7, gold, M.Foil)
	k:block("Rune", V(0.05, 0.3, 0.03), CF(-0.08, 0.5, -0.5) * ANG(0, 0, rad(30)), "#B2FFFF", M.Neon)
	k:block("Rune", V(0.05, 0.3, 0.03), CF(0.08, 0.5, -0.5) * ANG(0, 0, rad(-30)), "#B2FFFF", M.Neon)
	Kit.particles(body, "#FFE680", {size = 0.1, rate = 2, life = 1, speed = 0.3, texture = "rbxasset://textures/particles/sparkles_main.dds"})
	return body
end

local function rune(k, cf, kind)
	local c, m = "#3CE6F0", M.Neon
	k:block("Rune", V(0.1, 0.8, 0.05), cf, c, m)
	if kind == 1 then
		k:block("Rune", V(0.1, 0.45, 0.05), cf * CF(0.15, 0.18, 0) * ANG(0, 0, rad(-45)), c, m)
		k:block("Rune", V(0.1, 0.45, 0.05), cf * CF(0.15, -0.05, 0) * ANG(0, 0, rad(45)), c, m)
	elseif kind == 2 then
		k:block("Rune", V(0.1, 0.5, 0.05), cf * CF(0.17, 0.12, 0) * ANG(0, 0, rad(-40)), c, m)
	else
		k:block("Rune", V(0.1, 0.5, 0.05), cf * CF(0.15, 0, 0) * ANG(0, 0, rad(45)), c, m)
		k:block("Rune", V(0.1, 0.5, 0.05), cf * CF(-0.15, 0, 0) * ANG(0, 0, rad(-45)), c, m)
	end
end

GEM["Rune Totem"] = function(k)
	local slate = "#6E6E73"
	local pillar = k:block("Pillar", V(1.2, 6, 1.2), CF(0, 3, 0), slate, M.Slate)
	k:block("Base", V(1.6, 0.4, 1.6), CF(0, 0.2, 0), "#5A5A5F", M.Slate)
	for _, y in ipairs({2.25, 3.75}) do
		k:block("Band", V(1.28, 0.12, 1.28), CF(0, y, 0), "#4A4A4F", M.Slate)
	end
	rune(k, CF(0, 1.4, -0.62), 1)
	rune(k, CF(0, 3.0, -0.62), 2)
	rune(k, CF(0, 4.6, -0.62), 3)
	local skull = CF(0, 6.4, 0)
	k:ball("Skull", V(1.0, 0.8, 1.1), skull, "#E8E2D0", M.Slate)
	k:ball("Snout", V(0.6, 0.45, 0.6), skull * CF(0, -0.1, -0.5), "#E8E2D0", M.Slate)
	for _, s in ipairs({-1, 1}) do
		k:ball("Socket", V(0.2, 0.22, 0.1), skull * CF(s * 0.22, 0.08, -0.48), "#2A2A2A")
		k:taper("Horn", skull * CF(s * 0.35, 0.25, 0.2) * ANG(rad(50), 0, rad(-s * 25)), 0.6, 0.1, 0.03, 3, "#E8E2D0", M.Slate, rad(10))
	end
	Kit.light(pillar, "#3CE6F0", 8, 1)
	return pillar
end

GEM["Extra Pet Slot"] = function(k)
	local face = CF(0, 1.0, 0)
	local disc = k:cyl("Token", 0.15, 1.6, face * ANG(rad(90), 0, 0), "#4E3A2A", M.Wood)
	k:ring("RuneCircle", face * ANG(rad(90), 0, 0) * CF(0, -0.09, 0), 0.68, 0.06, 16, Kit.col("#3CE6F0"), M.Neon)
	k:ball("Pad", V(0.5, 0.42, 0.05), face * CF(0, -0.15, -0.09), "#FFD86B", M.Neon)
	for _, p in ipairs({{-0.3, 0.12}, {-0.11, 0.3}, {0.11, 0.3}, {0.3, 0.12}}) do
		k:ball("Toe", V(0.17, 0.2, 0.05), face * CF(p[1], p[2], -0.09), "#FFD86B", M.Neon)
	end
	k:block("Stand", V(0.6, 0.2, 0.4), CF(0, 0.1, 0), "#4E3A2A", M.Wood)
	return disc
end

GEM["Viking Banner"] = function(k)
	local wood, red, cream = "#50341E", "#B41E28", "#F2E6C8"
	k:cyl("Pole", 14, 0.45, CF(0, 7, 0), wood, M.Wood)
	dragonHead(k, CF(0, 14.3, -0.1), 1.4, wood, M.Wood)
	k:cyl("Crossbar", 4.4, 0.25, CF(2.1, 13, 0) * ANG(0, 0, math.pi / 2), wood, M.Wood)
	local mid
	for i = 0, 2 do
		local y = 12.0 - i * 1.8
		local seg = k:block("Cloth", V(3.8, 1.8, 0.1), CF(2.25, y, 0), red, M.Fabric)
		if i == 1 then mid = seg end
		k:block("Trim", V(0.18, 1.8, 0.12), CF(0.45, y, 0), cream, M.Fabric)
		k:block("Trim", V(0.18, 1.8, 0.12), CF(4.05, y, 0), cream, M.Fabric)
	end
	k:block("Trim", V(3.8, 0.18, 0.12), CF(2.25, 7.5, 0), cream, M.Fabric)
	for _, s in ipairs({-1, 1}) do
		k:block("Wheat", V(0.12, 1.6, 0.05), CF(2.25, 10.2, -0.08) * ANG(0, 0, rad(s * 30)), "#E6C864", M.Fabric)
		k:wedge("WingEmblem", V(0.05, 0.9, 1.1), CF(2.25 + s * 0.7, 10.6, -0.08) * ANG(0, rad(90 * s), 0), cream, M.Fabric)
	end
	return mid
end

GEM["Dragon Statue"] = function(k)
	local stone, slate = "#96969B", M.Slate
	k:block("Plinth", V(5, 1.6, 5), CF(0, 0.8, 0), "#7A7A80", slate)
	for _, p in ipairs({{-1.8, -1.6}, {1.5, -2.0}, {2.0, 1.7}, {-1.2, 2.1}}) do
		k:ball("Moss", V(1.3, 0.2, 1.0), V(p[1], 1.62, p[2]), "#50823A", M.Grass)
	end
	k:ball("Body", V(2.4, 2.6, 2.6), V(0, 3.0, 0.4), stone, slate)
	k:ball("Chest", V(1.6, 1.8, 1.0), V(0, 3.1, -0.65), "#A8A8AD", slate)
	for _, s in ipairs({-1, 1}) do
		k:ball("Haunch", V(0.9, 1.4, 1.6), V(s * 1.1, 2.3, 0.6), stone, slate)
		k:cyl("FrontLeg", 1.5, 0.5, CF(s * 0.6, 2.35, -0.9), stone, slate)
		k:ball("Claw", V(0.6, 0.3, 0.7), V(s * 0.6, 1.75, -1.15), stone, slate)
		k:wedge("FoldedWing", V(0.25, 2.2, 2.2), CF(s * 1.25, 3.9, 0.7) * ANG(rad(-15), 0, rad(-s * 12)), "#86868B", slate)
	end
	local neckTip = k:taper("Neck", CF(0, 3.9, -0.4) * ANG(rad(-20), 0, 0), 1.6, 0.6, 0.45, 4, stone, slate)
	local head = CF(neckTip.Position + V(0, 0.3, -0.15))
	k:ball("Head", V(1.1, 0.95, 1.2), head, stone, slate)
	k:ball("Snout", V(0.75, 0.6, 0.8), head * CF(0, -0.15, -0.65), stone, slate)
	for _, s in ipairs({-1, 1}) do
		local eye = k:ball("Eye", V(0.18, 0.14, 0.08), head * CF(s * 0.3, 0.1, -0.52), "#FFB04A", M.Neon)
		if s == 1 then Kit.light(eye, "#FFB04A", 8, 0.8) end
		k:taper("Horn", head * CF(s * 0.35, 0.4, 0.25) * ANG(rad(55), 0, rad(-s * 18)), 0.9, 0.16, 0.05, 3, "#B4B4B8", slate, rad(8))
	end
	-- tail leaves the back and curls round the right side to the front, lying on the plinth
	k:taper("Tail", CFrame.fromMatrix(V(0.5, 1.95, 1.6), V(0, 1, 0), V(0, 0, 1)), 4.2, 0.45, 0.12, 7, stone, slate, rad(24))
	return nil
end

Items.GemItemNames = {"Golden Watering Can", "Rune Totem", "Extra Pet Slot", "Viking Banner", "Dragon Statue"}

function Items.GemItem(name)
	local build = GEM[name]
	if not build then return nil end
	local k = Kit.new(name)
	build(k)
	k.Model:SetAttribute("GemItem", name)
	return k:finish(true)
end

return Items
