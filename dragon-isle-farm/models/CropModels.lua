-- CropModels: seed pouches, 4 growth stages, harvested crops and mutation looks.
-- Spec: 02_Seeds_and_Crops.md. Plant models sit with their origin on the soil surface.
local Kit = require(script.Parent.ModelKit)
local Config = require(script.Parent.Parent.GameConfig)
local M = Enum.Material
local rad = math.rad

local Crops = {}

local GREEN = "#4CAF50"
local DARKGREEN = "#2F7D32"
local SOIL = "#5A3A24"

local function around(i, n, r, phase)
	local a = (i / n) * math.pi * 2 + (phase or 0)
	return math.cos(a) * r, math.sin(a) * r, a
end

local function mound(k, w)
	w = w or 1.6
	k:ball("Mound", Vector3.new(w, 0.45, w), Vector3.new(0, 0, 0), SOIL, M.Ground)
end

local function sprout(k, color)
	mound(k)
	k:cyl("Stem", 0.5, 0.1, CFrame.new(0, 0.3, 0), color or GREEN)
	k:ball("Leaf", Vector3.new(0.45, 0.1, 0.3), CFrame.new(-0.2, 0.58, 0) * CFrame.Angles(0, 0, rad(25)), color or GREEN)
	k:ball("Leaf", Vector3.new(0.45, 0.1, 0.3), CFrame.new(0.2, 0.58, 0) * CFrame.Angles(0, 0, rad(-25)), color or GREEN)
end

-- n leaves fanned around the centre, tilted outward
local function tuft(k, n, y, size, tilt, color, phase)
	for i = 0, n - 1 do
		local _, _, a = around(i, n, 0, phase)
		local cf = CFrame.new(0, y, 0) * CFrame.Angles(0, a, 0) * CFrame.Angles(0, 0, rad(tilt)) * CFrame.new(0, size.Y / 2, 0)
		k:ball("Leaf", size, cf, color or GREEN)
	end
end

-- bush made of overlapping balls
local function bush(k, n, r, y, size, color)
	k:ball("Bush", size * 1.1, Vector3.new(0, y + size * 0.15, 0), color)
	for i = 0, n - 1 do
		local x, z = around(i, n, r)
		k:ball("Bush", size, Vector3.new(x, y, z), color)
	end
end

-- thin meridian stripes on an ellipsoid (melons, squash)
local function stripes(k, cf, size, n, color, mat)
	for i = 0, n - 1 do
		k:ball("Stripe", Vector3.new(size.X * 0.09, size.Y * 1.02, size.Z * 1.02), cf * CFrame.Angles(0, i * math.pi / n, 0), color, mat)
	end
end

local function glowRing(k, rarity)
	local disc = k:cyl("GlowRing", 0.04, 3.8, CFrame.new(0, 0.05, 0), Config.RarityColor(rarity), M.Neon)
	disc.Transparency = 0.7
	disc.CastShadow = false
end

------------------------------------------------------------------ crop definitions
-- each def: stage(k, s) -> fruit part (or nil); harvest(k) -> main part; size = harvested height; fx(k, fruit) optional
local Defs = {}

Defs.Carrot = {
	element = "#FF8C1E", size = 1.6,
	stage = function(k, s)
		if s == 1 then sprout(k) return nil end
		mound(k)
		if s == 2 then
			tuft(k, 5, 0.15, Vector3.new(0.12, 0.9, 0.3), 18)
			return nil
		end
		if s == 3 then
			k:cyl("Shoulder", 0.25, 0.75, CFrame.new(0, 0.18, 0), "#FF8C1E")
			tuft(k, 6, 0.25, Vector3.new(0.15, 1.6, 0.4), 16)
			return nil
		end
		local _, parts = k:taper("Carrot", CFrame.new(0, 0, 0), 1.0, 0.32, 0.46, 4, "#FF8C1E")
		k:cyl("Groove", 0.05, 0.86, CFrame.new(0, 0.35, 0), "#C8641A")
		k:cyl("Groove", 0.05, 0.9, CFrame.new(0, 0.65, 0), "#C8641A")
		tuft(k, 7, 1.0, Vector3.new(0.18, 1.8, 0.45), 15)
		return parts[#parts]
	end,
	harvest = function(k)
		local _, parts = k:taper("Carrot", CFrame.new(0, 0, 0), 1.6, 0.05, 0.42, 6, "#FF8C1E")
		k:cyl("Groove", 0.05, 0.62, CFrame.new(0, 0.6, 0), "#C8641A")
		k:cyl("Groove", 0.05, 0.74, CFrame.new(0, 0.95, 0), "#C8641A")
		k:cyl("Groove", 0.05, 0.8, CFrame.new(0, 1.25, 0), "#C8641A")
		tuft(k, 5, 1.55, Vector3.new(0.12, 0.8, 0.3), 20)
		return parts[#parts]
	end,
}

local WHEAT_SPOTS = {{0, 0}, {0.35, 0.1}, {-0.3, 0.25}, {0.1, -0.38}, {-0.25, -0.3}, {0.42, -0.25}, {-0.45, 0}, {0.2, 0.42}, {-0.1, 0.45}}
local function wheatField(k, n, h, stalkColor, earColor, droop)
	for i = 1, n do
		local p = WHEAT_SPOTS[i]
		local lean = CFrame.Angles(rad(p[2] * 12), 0, rad(-p[1] * 12))
		local base = CFrame.new(p[1], 0, p[2]) * lean
		k:cyl("Stalk", h, 0.08, base * CFrame.new(0, h / 2, 0), stalkColor)
		if earColor then
			k:ball("Ear", Vector3.new(0.2, 0.6, 0.2), base * CFrame.new(0, h, 0) * CFrame.Angles(rad(droop or 0), 0, 0) * CFrame.new(0, 0.25, 0), earColor)
		end
	end
end

Defs.Wheat = {
	element = "#E6C864", size = 1.6,
	stage = function(k, s)
		mound(k, 1.8)
		if s == 1 then
			for i = 0, 2 do
				k:block("Blade", Vector3.new(0.08, 0.6, 0.15), CFrame.new((i - 1) * 0.15, 0.4, 0) * CFrame.Angles(0, 0, rad((i - 1) * 20)), GREEN)
			end
			return nil
		end
		if s == 2 then wheatField(k, 7, 1.2, GREEN) return nil end
		if s == 3 then wheatField(k, 9, 2.6, "#7CB342", "#9CCC65", 0) return nil end
		wheatField(k, 9, 2.8, "#E6C864", "#C9A13E", 25)
		return nil
	end,
	harvest = function(k)
		for i = 0, 4 do
			local x = (i - 2) * 0.09
			local base = CFrame.new(x, 0, 0) * CFrame.Angles(0, 0, rad(-(i - 2) * 6))
			k:cyl("Stalk", 1.3, 0.07, base * CFrame.new(0, 0.65, 0), "#E6C864")
			k:ball("Ear", Vector3.new(0.18, 0.5, 0.18), base * CFrame.new(0, 1.45, 0), "#C9A13E")
		end
		return k:cyl("Twine", 0.12, 0.5, CFrame.new(0, 0.55, 0), "#8C6A46")
	end,
}

Defs.Potato = {
	element = "#B48C5A", size = 0.8,
	stage = function(k, s)
		if s == 1 then sprout(k) return nil end
		mound(k, 2)
		if s == 2 then bush(k, 3, 0.35, 0.55, 0.8, GREEN) return nil end
		bush(k, 5, 0.6, 0.9, 1.0, "#43A047")
		for i = 0, 3 do
			local x, z = around(i, 4, 0.55, 0.4)
			k:ball("Flower", 0.25, Vector3.new(x, 1.45, z), "#E6D2FF")
			k:ball("FlowerCore", 0.1, Vector3.new(x, 1.55, z), "#FFD54F")
		end
		if s == 3 then return nil end
		local fruit
		for i = 0, 2 do
			local x, z = around(i, 3, 1.05, 0.9)
			k:ball("Crack", Vector3.new(0.9, 0.06, 0.9), Vector3.new(x, 0.04, z), "#3E2716", M.Ground)
			fruit = k:ball("Potato", Vector3.new(0.75, 0.5, 0.6), CFrame.new(x, 0.18, z) * CFrame.Angles(0, i, 0), "#B48C5A")
		end
		return fruit
	end,
	harvest = function(k)
		local main = k:ball("Potato", Vector3.new(1.1, 0.8, 0.8), Vector3.new(0, 0.4, 0), "#B48C5A")
		for _, p in ipairs({{-0.3, 0.6, -0.3}, {0.2, 0.7, -0.25}, {0.35, 0.4, -0.36}, {-0.1, 0.3, -0.38}}) do
			k:ball("EyeSpot", 0.1, Vector3.new(p[1], p[2], p[3]), "#7A5A36")
		end
		return main
	end,
}

local function cornStalk(k, h, leaves)
	k:cyl("Stalk", h, 0.22, CFrame.new(0, h / 2, 0), "#7CB342")
	for i = 1, leaves do
		local y = h * (0.25 + 0.6 * (i / leaves))
		local cf = CFrame.new(0, y, 0) * CFrame.Angles(0, i * 2.3, 0) * CFrame.Angles(0, 0, rad(55)) * CFrame.new(0, 0.75, 0)
		k:ball("Leaf", Vector3.new(0.1, 1.6, 0.3), cf, "#689F38")
	end
end

Defs.Sweetcorn = {
	element = "#FFDC3C", size = 1.4,
	stage = function(k, s)
		if s == 1 then sprout(k, "#7CB342") return nil end
		mound(k)
		if s == 2 then cornStalk(k, 1.6, 2) return nil end
		cornStalk(k, 3.8, 5)
		for i = 0, 3 do
			k:wedge("Tassel", Vector3.new(0.06, 0.5, 0.25), CFrame.new(0, 3.9, 0) * CFrame.Angles(0, i * math.pi / 2, rad(20)) * CFrame.new(0, 0.2, 0), "#D4B160")
		end
		if s == 3 then return nil end
		local cobCF = CFrame.new(0.32, 2.0, 0) * CFrame.Angles(0, 0, rad(-22))
		local cob = k:ball("Cob", Vector3.new(0.45, 1.1, 0.45), cobCF, "#FFDC3C")
		stripes(k, cobCF, Vector3.new(0.45, 1.1, 0.45), 3, "#F5C518")
		k:wedge("Husk", Vector3.new(0.08, 0.9, 0.35), cobCF * CFrame.new(0.2, -0.25, 0) * CFrame.Angles(0, 0, rad(-25)), "#8BC34A")
		k:wedge("Husk", Vector3.new(0.08, 0.9, 0.35), cobCF * CFrame.new(-0.2, -0.25, 0) * CFrame.Angles(0, math.pi, rad(-25)), "#8BC34A")
		return cob
	end,
	harvest = function(k)
		local cf = CFrame.new(0, 0.7, 0)
		local cob = k:ball("Cob", Vector3.new(0.5, 1.3, 0.5), cf, "#FFDC3C")
		stripes(k, cf, Vector3.new(0.5, 1.3, 0.5), 3, "#F5C518")
		k:wedge("Husk", Vector3.new(0.08, 1.0, 0.4), cf * CFrame.new(0.24, -0.3, 0) * CFrame.Angles(0, 0, rad(-20)), "#8BC34A")
		k:wedge("Husk", Vector3.new(0.08, 1.0, 0.4), cf * CFrame.new(-0.24, -0.3, 0) * CFrame.Angles(0, math.pi, rad(-20)), "#8BC34A")
		return cob
	end,
}

local function berries(k, n, r, y, color, mat)
	local last
	for i = 0, n - 1 do
		local x, z = around(i, n, r, 0.3)
		last = k:ball("Berry", 0.3, Vector3.new(x, y + (i % 2) * 0.25, z), color, mat)
	end
	return last
end

Defs.Frostberry = {
	element = "#8CD2FF", size = 1.0,
	stage = function(k, s)
		if s == 1 then sprout(k, "#B8C8CC") return nil end
		mound(k, 1.9)
		if s == 2 then bush(k, 4, 0.4, 0.5, 0.8, "#5FA8A0") return nil end
		bush(k, 6, 0.7, 0.8, 1.0, "#5FA8A0")
		if s == 3 then berries(k, 6, 0.95, 0.8, "#DDEEF5") return nil end
		local b = berries(k, 7, 0.98, 0.8, "#8CD2FF", M.Neon)
		for i = 0, 4 do
			local x, z = around(i, 5, 0.55, 1)
			k:ball("Frost", 0.18, Vector3.new(x, 1.45, z), "#FFFFFF")
		end
		return b
	end,
	fx = function(k, fruit)
		Kit.particles(fruit, "#FFFFFF", {size = 0.5, rate = 2, life = 3, speed = 0.2, light = 0, alpha = 0.7, texture = "rbxasset://textures/particles/smoke_main.dds"})
	end,
	harvest = function(k)
		k:cyl("Twig", 1.0, 0.07, CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, rad(10)), "#6D4C41")
		local main
		for _, p in ipairs({{0, 0.95}, {-0.2, 0.75}, {0.2, 0.75}, {-0.1, 0.5}, {0.15, 0.48}}) do
			main = k:ball("Berry", 0.32, Vector3.new(p[1], p[2], 0), "#8CD2FF")
			k:ball("Shine", 0.09, Vector3.new(p[1] + 0.07, p[2] + 0.08, -0.14), "#FFFFFF", M.Neon)
		end
		return main
	end,
}

Defs.Honeyroot = {
	element = "#F0AA28", size = 1.1,
	stage = function(k, s)
		if s == 1 then sprout(k) return nil end
		mound(k, 1.8)
		local leafY = s == 4 and 1.0 or 0.3
		for i = 0, 3 do
			local _, _, a = around(i, 4, 0)
			local cf = CFrame.new(0, leafY, 0) * CFrame.Angles(0, a, 0) * CFrame.Angles(0, 0, rad(-15)) * CFrame.new(0.45, 0, 0)
			k:ball("Leaf", Vector3.new(0.8, 0.1, 0.45), cf, "#6C8E3A")
			k:block("Vein", Vector3.new(0.7, 0.04, 0.05), cf * CFrame.new(0, 0.05, 0), "#F0AA28", M.Neon)
		end
		if s == 2 then return nil end
		if s == 3 then
			local top = k:ball("Bulb", Vector3.new(1.0, 0.5, 1.0), Vector3.new(0, 0.12, 0), "#F0AA28")
			Kit.light(top, "#F0AA28", 4, 0.6)
			return nil
		end
		local bulb = k:ball("Bulb", Vector3.new(1.2, 1.1, 1.2), Vector3.new(0, 0.5, 0), "#F0AA28")
		k:ball("Drip", Vector3.new(0.22, 0.35, 0.22), Vector3.new(0.35, 0.1, -0.45), "#FFB300", M.Glass).Transparency = 0.2
		for i = 0, 1 do
			local x, z = around(i, 2, 1.0)
			k:ball("Bee", Vector3.new(0.18, 0.14, 0.24), Vector3.new(x, 1.3, z), "#FFD54F")
			k:block("BeeStripe", Vector3.new(0.19, 0.15, 0.05), Vector3.new(x, 1.3, z), "#212121")
		end
		return bulb
	end,
	harvest = function(k)
		local bulb = k:ball("Bulb", Vector3.new(1.1, 0.95, 1.1), Vector3.new(0, 0.5, 0), "#F0AA28")
		tuft(k, 3, 0.9, Vector3.new(0.12, 0.45, 0.25), 25, "#6C8E3A")
		k:ball("Drip", Vector3.new(0.2, 0.32, 0.2), Vector3.new(0.3, 0.12, -0.38), "#FFB300", M.Glass).Transparency = 0.2
		return bulb
	end,
}

local function pepper(k, cf, ripe, length)
	length = length or 0.9
	local color = ripe and "#FF4620" or "#558B2F"
	local tip, parts = k:taper("Pepper", cf, length, 0.2, 0.06, 4, color, nil, 0.18)
	if ripe then
		local last = parts[#parts]
		last.Color = Kit.col("#FFB04A")
		last.Material = M.Neon
	end
	return parts[#parts], tip
end

Defs["Ember Pepper"] = {
	element = "#FF7A2A", size = 1.2,
	stage = function(k, s)
		if s == 1 then sprout(k, DARKGREEN) return nil end
		mound(k, 1.8)
		if s == 2 then bush(k, 3, 0.35, 0.6, 0.8, DARKGREEN) return nil end
		bush(k, 5, 0.6, 1.1, 1.0, DARKGREEN)
		local fruit
		for i = 0, 3 do
			local x, z = around(i, 4, 0.75, 0.5)
			fruit = pepper(k, CFrame.new(x, 1.0, z) * CFrame.Angles(math.pi, 0, 0), s == 4)
		end
		return s == 4 and fruit or nil
	end,
	fx = function(k, fruit)
		Kit.light(fruit, "#FF7A2A", 6, 1.2)
		Kit.flame(fruit, "#FFB04A", 0.25)
	end,
	harvest = function(k)
		k:cyl("Stem", 0.3, 0.1, CFrame.new(0, 1.35, 0), "#558B2F")
		local main = pepper(k, CFrame.new(0, 1.25, 0) * CFrame.Angles(math.pi, 0, 0), true, 1.2)
		return main
	end,
}

local function melon(k, cf, size, base, stripe)
	local m = k:ball("Melon", size, cf, base)
	stripes(k, cf, size, 3, stripe)
	return m
end

local function vine(k, color)
	for i = 0, 2 do
		local _, _, a = around(i, 3, 0, 0.4)
		local cf = CFrame.new(0, 0.12, 0) * CFrame.Angles(0, a, 0) * CFrame.Angles(0, 0, rad(-85)) * CFrame.new(0, 0.9, 0)
		k:cyl("Vine", 1.8, 0.1, cf, color)
		k:ball("Leaf", Vector3.new(0.6, 0.1, 0.5), CFrame.new(0, 0.2, 0) * CFrame.Angles(0, a, 0) * CFrame.new(1.4, 0, 0), color)
	end
end

Defs.Moonmelon = {
	element = "#B8B8FF", size = 1.3,
	stage = function(k, s)
		if s == 1 then sprout(k) return nil end
		mound(k, 1.6)
		vine(k, "#5E9E5A")
		if s == 2 then return nil end
		if s == 3 then melon(k, CFrame.new(0.5, 0.35, 0), Vector3.new(0.7, 0.6, 0.7), "#A5D6A7", "#7CB342") return nil end
		return melon(k, CFrame.new(0, 0.62, 0), Vector3.new(1.6, 1.3, 1.6), "#C8C8FF", "#8C8CDC")
	end,
	harvest = function(k)
		return melon(k, CFrame.new(0, 0.65, 0), Vector3.new(1.6, 1.3, 1.6), "#C8C8FF", "#8C8CDC")
	end,
}

local function bigLeaves(k, n, r, color)
	for i = 0, n - 1 do
		local _, _, a = around(i, n, 0, 0.2)
		local cf = CFrame.new(0, 0.3, 0) * CFrame.Angles(0, a, 0) * CFrame.Angles(0, 0, rad(-20)) * CFrame.new(r, 0, 0)
		k:ball("Leaf", Vector3.new(1.3, 0.12, 0.9), cf, color)
		k:wedge("Spike", Vector3.new(0.08, 0.25, 0.3), cf * CFrame.new(0.6, 0.1, 0), color)
	end
end

local function squash(k, cf, size, base, stripe)
	local m = k:ball("Squash", size, cf, base)
	stripes(k, cf, size, 4, stripe)
	k:cyl("Stem", 0.35, 0.18, cf * CFrame.new(0, size.Y / 2 + 0.1, 0), "#5D4037")
	return m
end

Defs["Thunder Squash"] = {
	element = "#FFE600", size = 1.1,
	stage = function(k, s)
		if s == 1 then sprout(k) return nil end
		mound(k, 2)
		bigLeaves(k, 5, 0.9, "#388E3C")
		if s == 2 then return nil end
		if s == 3 then squash(k, CFrame.new(0, 0.5, 0), Vector3.new(1.6, 1.0, 1.4), "#7CB342", "#558B2F") return nil end
		return squash(k, CFrame.new(0, 0.7, 0), Vector3.new(2.0, 1.3, 1.8), "#FFE600", "#3A3A70")
	end,
	fx = function(k, fruit)
		Kit.tierFx(fruit, "Legendary", "#FFE600")
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0.6, 0.4, 0)
		a0.Parent = fruit
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(1.4, -0.7, -0.4)
		a1.Parent = fruit
		local beam = Instance.new("Beam")
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.Color = ColorSequence.new(Kit.col("#FFF59D"))
		beam.LightEmission = 1
		beam.Width0 = 0.08
		beam.Width1 = 0.04
		beam.CurveSize0 = 0.8
		beam.CurveSize1 = -0.8
		beam.Segments = 8
		beam.FaceCamera = true
		beam.Parent = fruit
	end,
	harvest = function(k)
		return squash(k, CFrame.new(0, 0.65, 0), Vector3.new(2.0, 1.3, 1.8), "#FFE600", "#3A3A70")
	end,
}

local function heart(k, cf)
	local c = "#C8143C"
	k:ball("Lobe", 0.8, cf * CFrame.new(-0.3, 0.25, 0), c)
	local main = k:ball("Lobe", 0.8, cf * CFrame.new(0.3, 0.25, 0), c)
	k:taper("Point", cf * CFrame.new(0, 0.35, 0) * CFrame.Angles(math.pi, 0, 0), 0.85, 0.55, 0.06, 4, c)
	k:block("Core", Vector3.new(0.12, 0.45, 0.06), cf * CFrame.new(0.05, 0.05, -0.38) * CFrame.Angles(0, 0, rad(15)), "#FF6E40", M.Neon)
	for _, p in ipairs({{-0.35, 0.45}, {0.35, 0.45}, {-0.15, 0.0}, {0.25, 0.1}}) do
		k:ball("Scale", Vector3.new(0.22, 0.16, 0.08), cf * CFrame.new(p[1], p[2], -0.35), "#8E0E2A")
	end
	return main
end

Defs["Dragonheart Fruit"] = {
	element = "#FF2E4A", size = 1.4,
	stage = function(k, s)
		k:ball("Rock", Vector3.new(1.4, 0.6, 1.1), Vector3.new(0.3, 0.15, 0.2), "#6E6E73", M.Slate)
		mound(k, 1.4)
		if s == 1 then
			k:taper("Sprout", CFrame.new(0, 0.1, 0), 0.6, 0.08, 0.03, 3, "#5A1E2A", nil, 0.2)
			k:wedge("Thorn", Vector3.new(0.05, 0.15, 0.12), CFrame.new(0.06, 0.35, 0), "#3C1E28")
			return nil
		end
		local h = s == 2 and 1.4 or 2.2
		local tip = k:taper("Vine", CFrame.new(0, 0.1, 0), h, 0.14, 0.07, 6, "#3C1E28", nil, 0.12)
		for i = 1, 3 do
			k:wedge("Thorn", Vector3.new(0.05, 0.2, 0.15), CFrame.new(0.1 * (i % 2 == 0 and 1 or -1), h * i / 4, 0.05 * i), "#2A121A")
		end
		if s == 2 then return nil end
		if s == 3 then
			k:ball("Bud", Vector3.new(0.5, 0.7, 0.5), tip * CFrame.new(0, 0.25, 0), "#8E0E2A")
			return nil
		end
		return heart(k, tip * CFrame.new(0, 0.3, 0))
	end,
	fx = function(k, fruit)
		Kit.tierFx(fruit, "Mythic", "#FF2E4A")
	end,
	harvest = function(k)
		k:cyl("Stem", 0.25, 0.08, CFrame.new(0, 1.35, 0), "#3C1E28")
		return heart(k, CFrame.new(0, 0.6, 0))
	end,
}

local function lotus(k, cf)
	for i = 0, 7 do
		local _, _, a = around(i, 8, 0)
		local p = k:ball("Petal", Vector3.new(0.4, 1.0, 0.12), cf * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, 0.35) * CFrame.Angles(rad(50), 0, 0) * CFrame.new(0, 0.45, 0), "#9FFFFF", M.Glass)
		p.Transparency = 0.15
	end
	for i = 0, 4 do
		local _, _, a = around(i, 5, 0, 0.3)
		k:ball("Petal", Vector3.new(0.3, 0.8, 0.1), cf * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, 0.15) * CFrame.Angles(rad(25), 0, 0) * CFrame.new(0, 0.38, 0), "#FFFFFF", M.Neon)
	end
	return k:ball("Center", 0.35, cf * CFrame.new(0, 0.18, 0), "#FFD86B", M.Neon)
end

local function pool(k)
	local p = k:cyl("Pool", 0.12, 2.8, CFrame.new(0, 0.06, 0), "#3CE6F0", M.Glass)
	p.Transparency = 0.25
	k:cyl("PoolGlow", 0.04, 2.4, CFrame.new(0, 0.1, 0), "#B2FFFF", M.Neon).Transparency = 0.5
	Kit.light(p, "#3CE6F0", 6, 0.8)
end

local function pads(k)
	for i = 0, 2 do
		local x, z = around(i, 3, 0.8, 0.6)
		k:cyl("Pad", 0.06, 0.8, CFrame.new(x, 0.16, z), "#2E7D32")
	end
end

Defs["Starbloom Lotus"] = {
	element = "#78FFFF", size = 1.5,
	stage = function(k, s)
		pool(k)
		if s == 1 then return nil end
		pads(k)
		if s == 2 then return nil end
		k:cyl("Stem", 0.6, 0.1, CFrame.new(0, 0.4, 0), "#2E7D32")
		if s == 3 then
			k:ball("Bud", Vector3.new(0.5, 1.0, 0.5), Vector3.new(0, 1.1, 0), "#CFFFFF", M.Glass)
			return nil
		end
		local center = lotus(k, CFrame.new(0, 0.75, 0))
		local beam = k:cyl("LightBeam", 10, 0.5, CFrame.new(0, 5.8, 0), "#B2FFFF", M.Neon)
		beam.Transparency = 0.75
		beam.CastShadow = false
		return center
	end,
	fx = function(k, fruit)
		Kit.tierFx(fruit, "Divine", "#78FFFF")
	end,
	harvest = function(k)
		k:cyl("Pad", 0.06, 1.0, CFrame.new(0, 0.03, 0), "#2E7D32")
		return lotus(k, CFrame.new(0, 0.35, 0))
	end,
}

Crops.Defs = Defs

------------------------------------------------------------------ public API
function Crops.StageFor(progress)
	if progress >= 1 then return 4 end
	if progress >= 0.6 then return 3 end
	if progress >= 0.25 then return 2 end
	return 1
end

-- Plant model for a growth stage (1..4). Anchored, origin on the soil surface.
-- scale (optional) enlarges the whole plant, e.g. 1.6 on the 8-stud farm tiles.
function Crops.Plant(name, stage, scale)
	local def = Defs[name]
	local data = Config.Crops[name]
	if not def or not data then return nil end
	local k = Kit.new(name .. "_Stage" .. stage)
	local fruit = def.stage(k, stage)
	if stage == 4 then
		local tier = Config.Rarities[data.Rarity].Tier
		if tier >= 3 then glowRing(k, data.Rarity) end
		if fruit then
			if def.fx then
				def.fx(k, fruit)
			elseif tier >= 3 then
				Kit.tierFx(fruit, data.Rarity, def.element)
			end
			fruit.Name = "Fruit"
		end
	end
	if scale and scale ~= 1 then k:scale(scale) end
	local _, hi = k:bounds()
	k.Model:SetAttribute("Crop", name)
	k.Model:SetAttribute("Stage", stage)
	k.Model:SetAttribute("Height", hi.Y)
	return k:finish(true)
end

-- Harvested crop (the item), optionally mutated. Anchored, origin at its base.
function Crops.Harvested(name, mutation)
	local def = Defs[name]
	if not def then return nil end
	local k = Kit.new(name)
	def.harvest(k)
	k:fitHeight(def.size)
	local model = k:finish(true)
	if mutation then Crops.ApplyMutation(model, mutation) end
	return model
end

local function mainPart(model)
	local best, vol = nil, -1
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Name ~= "Root" then
			local v = p.Size.X * p.Size.Y * p.Size.Z
			if v > vol then best, vol = p, v end
		end
	end
	return best
end

local function eachPart(model, fn)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Name ~= "Root" then fn(p) end
	end
end

-- Mutation looks (01_Art_Direction.md section 5)
function Crops.ApplyMutation(model, mutation)
	local main = mainPart(model)
	if not main then return model end
	if mutation == "Golden" then
		eachPart(model, function(p)
			p.Color = Kit.col("#FFD700")
			p.Material = M.Foil
		end)
		Kit.particles(main, "#FFE680", {size = 0.15, rate = 6, life = 1, speed = 0.4, texture = "rbxasset://textures/particles/sparkles_main.dds"})
	elseif mutation == "Scorched" then
		eachPart(model, function(p) p.Color = p.Color:Lerp(Kit.col("#2B1B12"), 0.75) end)
		local s = main.Size
		for i = -1, 1 do
			local crack = Instance.new("Part")
			crack.Name = "Crack"
			crack.Anchored = main.Anchored
			crack.CanCollide = false
			crack.CanQuery = false
			crack.CanTouch = false
			crack.Material = M.Neon
			crack.Color = Kit.col("#FF5A14")
			crack.Size = Vector3.new(s.X * 0.08, s.Y * 0.5, 0.04)
			crack.CFrame = main.CFrame * CFrame.new(i * s.X * 0.22, 0, -s.Z * 0.47) * CFrame.Angles(0, 0, math.rad(i * 25))
			crack.Parent = model
			if not main.Anchored then
				local w = Instance.new("WeldConstraint")
				w.Part0 = main
				w.Part1 = crack
				w.Parent = crack
			end
		end
		Kit.smoke(main, 0.3)
	elseif mutation == "Frozen" then
		local cf, size = model:GetBoundingBox()
		local ice = Instance.new("Part")
		ice.Name = "IceCube"
		ice.Anchored = main.Anchored
		ice.CanCollide = false
		ice.CanQuery = false
		ice.CanTouch = false
		ice.Material = M.Glass
		ice.Color = Kit.col("#AEE6FF")
		ice.Transparency = 0.4
		ice.Size = size * 1.15
		ice.CFrame = cf
		ice.Parent = model
		if not main.Anchored then
			local w = Instance.new("WeldConstraint")
			w.Part0 = main
			w.Part1 = ice
			w.Parent = ice
		end
		Kit.particles(ice, "#FFFFFF", {size = 0.1, rate = 3, life = 2, speed = 0.2, accel = Vector3.new(0, -0.5, 0)})
	elseif mutation == "Shocked" then
		eachPart(model, function(p) p.Color = p.Color:Lerp(Kit.col("#FFFF78"), 0.5) end)
		Kit.light(main, "#FFFF78", 5, 1.2)
		Kit.particles(main, "#FFFF78", {size = 0.15, rate = 10, life = 0.25, speed = 3, texture = "rbxasset://textures/particles/sparkles_main.dds"})
	elseif mutation == "Celestial" then
		eachPart(model, function(p) p.Color = p.Color:Lerp(Kit.col("#C88CFF"), 0.7) end)
		main.Material = M.Neon
		Kit.light(main, "#C88CFF", 6, 1.2)
		Kit.particles(main, "#FFFFFF", {size = 0.18, rate = 6, life = 1.5, speed = 0.3, texture = "rbxasset://textures/particles/sparkles_main.dds"})
	end
	model:SetAttribute("Mutation", mutation)
	return model
end

------------------------------------------------------------------ seed pouches
local POUCH = {
	Common = {body = "#C8AA78", tie = "#8C6A46", mat = M.Fabric},
	Uncommon = {body = "#6FAF5A", tie = "#8C6A46", mat = M.Fabric},
	Rare = {body = "#4A78C8", tie = "#5D4037", mat = M.Fabric},
	Epic = {body = "#7D3CB4", tie = "#FFBE28", mat = M.Fabric},
	Legendary = {body = "#F2E6C8", tie = "#FFBE28", mat = M.Leather, trim = "#FFBE28"},
	Mythic = {body = "#8C141E", tie = "#2A1A22", mat = M.Leather},
	Divine = {body = "#E8F4FF", tie = "#B2FFFF", mat = M.Fabric},
}

function Crops.Pouch(name)
	local data = Config.Crops[name]
	if not data then return nil end
	local style = POUCH[data.Rarity]
	local k = Kit.new(name .. " Seeds")
	k:ball("Pouch", Vector3.new(1.0, 0.95, 0.9), Vector3.new(0, 0.48, 0), style.body, style.mat)
	k:cyl("Neck", 0.28, 0.42, CFrame.new(0, 1.02, 0), style.body, style.mat)
	k:ball("Ruffle", Vector3.new(0.6, 0.22, 0.6), Vector3.new(0, 1.2, 0), style.body, style.mat)
	local tieMat = (data.Rarity == "Epic" or data.Rarity == "Legendary") and M.Foil or (data.Rarity == "Divine" and M.Neon or M.Fabric)
	k:cyl("Tie", 0.08, 0.5, CFrame.new(0, 0.97, 0), style.tie, tieMat)
	k:ball("Emblem", Vector3.new(0.38, 0.38, 0.08), Vector3.new(0, 0.5, -0.44), data.Color)
	local r = data.Rarity
	if r == "Uncommon" then
		k:ball("Leaf", Vector3.new(0.22, 0.1, 0.12), CFrame.new(0.28, 0.75, -0.36) * CFrame.Angles(0, 0, rad(30)), "#2E7D32")
	elseif r == "Rare" then
		k:block("Rune", Vector3.new(0.05, 0.22, 0.03), CFrame.new(0.3, 0.3, -0.37), "#CFD8DC", M.Metal)
	elseif r == "Epic" then
		k:block("Rune", Vector3.new(0.05, 0.22, 0.03), CFrame.new(0.3, 0.3, -0.37), "#D8C4FF", M.Neon)
	elseif r == "Legendary" then
		k:ball("Clasp", Vector3.new(0.22, 0.14, 0.08), Vector3.new(0, 0.97, -0.26), style.trim, M.Foil)
		k:cyl("Trim", 0.04, 0.98, CFrame.new(0, 0.25, 0), style.trim, M.Foil)
	elseif r == "Mythic" then
		for i = -1, 1 do
			k:taper("Claw", CFrame.new(i * 0.1, 0.92, -0.24) * CFrame.Angles(rad(-150), 0, 0), 0.22, 0.04, 0.01, 2, "#F2E6C8")
		end
		Kit.particles(k.Model:FindFirstChild("Pouch"), "#FF7A2A", {size = 0.1, rate = 3, life = 1, speed = 0.5})
	elseif r == "Divine" then
		local star = k:ball("Star", 0.22, Vector3.new(0, 1.6, 0), "#FFFFFF", M.Neon)
		Kit.light(star, "#B2FFFF", 5, 1)
	end
	k.Model:SetAttribute("Seed", name)
	return k:finish(true)
end

return Crops
