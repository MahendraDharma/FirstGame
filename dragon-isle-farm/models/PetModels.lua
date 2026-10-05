-- PetModels: all 18 pets. Spec: 03_Pets.md.
-- Front of every pet is -Z. Models are welded to an invisible Root at the body centre.
local Kit = require(script.Parent.ModelKit)
local Config = require(script.Parent.Parent.GameConfig)
local M = Enum.Material
local rad = math.rad
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles

local Pets = {}
local SIDES = {-1, 1}

------------------------------------------------------------------ shared body plans
local function horse(k, p)
	local body = k:ball("Body", V(1.1, 1.0, 1.6), V(0, 0, 0), p.coat)
	for _, x in ipairs({-0.33, 0.33}) do
		for _, z in ipairs({-0.5, 0.5}) do
			k:cyl("Leg", 0.8, 0.28, CF(x, -0.62, z), p.coat)
			k:cyl("Hoof", 0.18, 0.32, CF(x, -1.05, z), p.hoof, p.hoofMat)
		end
	end
	k:ball("Neck", V(0.55, 1.0, 0.6), CF(0, 0.6, -0.62) * ANG(rad(-25), 0, 0), p.coat)
	local head = CF(0, 1.2, -0.85)
	k:ball("Head", V(0.85, 0.85, 0.95), head, p.coat)
	k:ball("Snout", V(0.6, 0.5, 0.6), head * CF(0, -0.18, -0.42), p.snout or p.coat)
	k:eyes(head, 0.43, 0.48)
	for _, s in ipairs(SIDES) do
		k:wedge("Ear", V(0.08, 0.3, 0.2), head * CF(s * 0.22, 0.47, 0.15) * ANG(0, 0, rad(-s * 10)), p.coat)
	end
	local manes = {{V(0, 1.62, -0.72), 0}, {V(0, 1.3, -0.44), 0.5}, {V(0, 0.95, -0.18), 1}}
	for _, m in ipairs(manes) do
		k:ball("Mane", V(0.26, 0.55, 0.45), m[1], Kit.col(p.mane1):Lerp(Kit.col(p.mane2), m[2]), p.maneMat)
	end
	k:ball("Mane", V(0.3, 0.25, 0.35), head * CF(0, 0.42, -0.25), p.mane1, p.maneMat)
	k:taper("Tail", CF(0, 0.25, 0.78) * ANG(rad(125), 0, 0), 1.0, 0.15, 0.08, 4, p.mane2, p.maneMat, rad(10))
	return head, body
end

local HOOVES = {V(-0.33, -1.15, -0.5), V(0.33, -1.15, -0.5), V(-0.33, -1.15, 0.5), V(0.33, -1.15, 0.5)}

-- feathered wing: n layered feathers fanning upward from the shoulder
local function featherWing(k, s, colors, mat, transparency, big)
	big = big or 1
	for j = 1, #colors do
		local len = (1.4 - (j - 1) * 0.25) * big
		local f = k:ball("Wing", V(0.14, len, 0.45 * big), CF(s * 0.55, 0.45, 0.05) * ANG(0, 0, rad(-s * (50 + (j - 1) * 16))) * CF(0, len / 2 - 0.1, 0.12 * (j - 1)), colors[j], mat)
		if transparency then f.Transparency = transparency end
	end
end

local function fox(k, p)
	local body = k:ball("Body", V(0.7, 0.65, 1.0), V(0, -0.1, 0.15), p.fur)
	k:ball("Chest", V(0.5, 0.5, 0.35), V(0, -0.05, -0.3), p.white)
	for _, x in ipairs({-0.2, 0.2}) do
		for _, z in ipairs({-0.15, 0.45}) do
			k:cyl("Leg", 0.42, 0.16, CF(x, -0.5, z), p.fur)
			k:ball("Paw", V(0.2, 0.12, 0.24), V(x, -0.72, z - 0.03), p.white)
		end
	end
	local head = CF(0, 0.45, -0.5)
	k:ball("Head", 0.9, head, p.fur)
	k:ball("Muzzle", V(0.5, 0.32, 0.42), head * CF(0, -0.17, -0.33), p.white)
	k:ball("Nose", 0.1, head * CF(0, -0.1, -0.55), "#1A1A1A")
	k:eyes(head, 0.45, 0.42)
	for _, s in ipairs(SIDES) do
		local ear = head * CF(s * 0.25, 0.52, 0) * ANG(0, rad(90 * s), rad(0))
		k:wedge("Ear", V(0.1, 0.45, 0.32), ear, p.fur)
		k:wedge("EarInner", V(0.04, 0.3, 0.2), ear * CF(-0.05 * s, -0.05, 0.02), p.inner)
	end
	k:block("Mark", V(0.08, 0.16, 0.04), head * CF(0, 0.25, -0.43), p.mark, M.Neon)
	return head, body
end

local function serpent(k, p, n)
	local first
	local segs = {}
	for i = 1, n do
		local t = (i - 1) / (n - 1)
		local z = -0.3 + i * 0.5
		local x = math.sin(i * 0.9) * 0.45
		local y = math.sin(i * 0.6) * 0.25
		local d = 0.85 - 0.5 * t
		local seg = k:ball("Body", V(d, d * 0.9, d * 1.3), CF(x, y, z), p.body, p.bodyMat)
		k:ball("Stripe", V(d * 0.35, d * 0.25, d * 0.9), CF(x, y + d * 0.4, z), p.stripe, p.stripeMat)
		table.insert(segs, {seg = seg, pos = V(x, y, z), d = d})
		first = first or seg
	end
	local head = CF(0, 0.15, -0.55)
	k:ball("Head", V(0.85, 0.7, 1.0), head, p.body, p.bodyMat)
	k:ball("Snout", V(0.6, 0.45, 0.55), head * CF(0, -0.12, -0.45), p.belly)
	k:eyes(head, 0.42, 0.5)
	return head, first, segs
end

local function antlers(k, head, color, size)
	size = size or 1
	for _, s in ipairs(SIDES) do
		local base = head * CF(s * 0.2, 0.3, 0.1) * ANG(rad(25), 0, rad(-s * 25))
		k:taper("Antler", base, 0.6 * size, 0.06, 0.03, 3, color)
		k:taper("Antler", base * CF(0, 0.3 * size, 0) * ANG(0, 0, rad(-s * 50)), 0.25 * size, 0.04, 0.02, 1, color)
	end
end

local function flameWings(k, at, s, colors, scale)
	scale = scale or 1
	for j = 1, #colors do
		local len = (1.2 - 0.25 * (j - 1)) * scale
		k:ball("Wing", V(0.12, len, 0.4 * scale), at * ANG(0, 0, rad(-s * (60 + (j - 1) * 18))) * CF(0, len / 2 - 0.05, 0), colors[j], M.Neon)
	end
end

------------------------------------------------------------------ builders
-- each returns the part that carries the rarity effects
local B = {}

B["Imp"] = function(k)
	local red = "#B4463C"
	local body = k:ball("Body", V(1.2, 1.15, 1.1), V(0, 0, 0), red)
	k:ball("Belly", V(0.8, 0.75, 0.4), V(0, -0.08, -0.4), "#E89A7A")
	local head = CF(0, 0.95, -0.1)
	k:ball("Head", 1.1, head, red)
	k:eyes(head, 0.55, 0.38)
	k:block("Grin", V(0.4, 0.06, 0.05), head * CF(0, -0.2, -0.53), "#3A0D0A")
	for _, s in ipairs(SIDES) do
		k:taper("Horn", head * CF(s * 0.28, 0.42, 0) * ANG(0, 0, rad(-s * 25)), 0.4, 0.1, 0.02, 3, "#F2E6C8")
		k:wedge("Wing", V(0.08, 0.6, 0.7), CF(s * 0.72, 0.35, 0.3) * ANG(0, 0, rad(-s * 35)), "#7A2A24")
		k:ball("Foot", V(0.3, 0.2, 0.35), V(s * 0.3, -0.58, -0.05), red)
	end
	local tip = k:taper("Tail", CF(0, -0.25, 0.5) * ANG(rad(100), 0, 0), 0.9, 0.07, 0.04, 4, red, nil, rad(-15))
	k:block("Spade", V(0.28, 0.28, 0.06), tip * ANG(0, 0, rad(45)), "#7A2A24")
	return body
end

B["Fairy Sprite"] = function(k)
	local body = k:ball("Body", V(0.55, 0.85, 0.55), V(0, 0, 0), "#FFAAE6")
	for i = 0, 4 do
		local a = i * math.pi * 2 / 5
		k:ball("Petal", V(0.35, 0.6, 0.1), CF(0, -0.3, 0) * ANG(0, a, 0) * CF(0, 0, 0.25) * ANG(rad(-35), 0, 0), "#FFD6F0")
	end
	local head = CF(0, 0.72, 0)
	k:ball("Head", 0.8, head, "#FFD6F0")
	k:eyes(head, 0.4, 0.42)
	k:ball("Cap", V(0.78, 0.25, 0.78), head * CF(0, 0.32, 0.02) * ANG(rad(-10), 0, 0), "#6FAF5A")
	k:cyl("CapStem", 0.18, 0.05, head * CF(0, 0.5, 0.05), "#4E8A3C")
	for _, s in ipairs(SIDES) do
		local up = k:ball("Wing", V(0.06, 0.9, 0.4), CF(s * 0.42, 0.55, 0.32) * ANG(0, 0, rad(-s * 40)), "#E8F6FF", M.Glass)
		up.Transparency = 0.3
		local low = k:ball("Wing", V(0.06, 0.6, 0.32), CF(s * 0.35, 0.1, 0.32) * ANG(0, 0, rad(-s * 70)), "#E8F6FF", M.Glass)
		low.Transparency = 0.3
	end
	Kit.particles(body, "#FFAAE6", {size = 0.08, rate = 3, life = 1.5, speed = 0.2, accel = V(0, -0.8, 0), texture = "rbxasset://textures/particles/sparkles_main.dds"})
	return nil
end

B["Jackalope"] = function(k)
	local fur, cream = "#AA825A", "#F2E2C4"
	local body = k:ball("Body", V(1.1, 0.95, 1.3), V(0, 0, 0), fur)
	k:ball("Belly", V(0.75, 0.6, 0.5), V(0, -0.15, -0.45), cream)
	local head = CF(0, 0.75, -0.55)
	k:ball("Head", 0.95, head, fur)
	k:ball("Snout", V(0.45, 0.35, 0.3), head * CF(0, -0.15, -0.4), cream)
	k:ball("Nose", 0.1, head * CF(0, -0.05, -0.55), "#F2A6B4")
	k:eyes(head, 0.47, 0.45)
	for _, s in ipairs(SIDES) do
		local ear = head * CF(s * 0.26, 0.65, 0.12) * ANG(rad(10), 0, rad(-s * 15))
		k:ball("Ear", V(0.24, 0.85, 0.12), ear, fur)
		k:ball("EarInner", V(0.14, 0.65, 0.06), ear * CF(0, 0, -0.05), "#F2A6B4")
		local base = head * CF(s * 0.08, 0.45, -0.05) * ANG(rad(-8), 0, rad(-s * 8))
		k:taper("Antler", base, 0.6, 0.05, 0.03, 2, "#D9C3A0")
		k:taper("Antler", base * CF(0, 0.32, 0) * ANG(0, 0, rad(-s * 50)), 0.25, 0.035, 0.02, 1, "#D9C3A0")
		k:taper("Antler", base * CF(0, 0.18, 0) * ANG(rad(-50), 0, 0), 0.2, 0.035, 0.02, 1, "#D9C3A0")
		k:ball("Foot", V(0.35, 0.18, 0.6), V(s * 0.35, -0.45, 0.1), fur)
		k:ball("Paw", V(0.22, 0.2, 0.25), V(s * 0.22, -0.48, -0.45), cream)
	end
	k:ball("Tail", 0.4, V(0, 0.05, 0.68), "#FFFFFF")
	return body
end

B["Kitsune Kit"] = function(k)
	local head, body = fox(k, {fur = "#FF9640", white = "#FFF6EC", inner = "#F2A6B4", mark = "#D23C3C"})
	k:ball("Tail", V(0.35, 0.35, 0.45), V(0, 0.0, 0.7), "#FF9640")
	k:ball("Tail", V(0.55, 0.55, 0.6), V(0, 0.32, 0.95), "#FF9640")
	k:ball("Tail", V(0.6, 0.65, 0.6), V(0, 0.78, 1.08), "#FF9640")
	k:ball("TailTip", 0.45, V(0, 1.15, 1.1), "#FFF6EC")
	local wisp = k:ball("FoxFire", 0.22, head * CF(0.62, 0.35, 0), "#7FD4FF", M.Neon)
	Kit.light(wisp, "#7FD4FF", 4, 1)
	return body
end

B["Gryphon Chick"] = function(k)
	local cream, tan = "#F0E2B8", "#DCBE78"
	local body = k:ball("Chest", 1.2, V(0, 0, -0.15), cream)
	k:ball("Hind", V(1.0, 0.9, 1.0), V(0, -0.1, 0.45), tan)
	local head = CF(0, 0.8, -0.35)
	k:ball("Head", 0.95, head, cream)
	for i = -1, 1 do
		k:wedge("Tuft", V(0.06, 0.3, 0.25), head * CF(i * 0.1, 0.5, 0.05) * ANG(0, 0, rad(-i * 20)), "#E2CC92")
	end
	k:taper("Beak", head * CF(0, -0.05, -0.42) * ANG(rad(-90), 0, 0), 0.35, 0.15, 0.03, 3, "#E8A33C", nil, rad(-20))
	k:eyes(head, 0.47, 0.42)
	for _, s in ipairs(SIDES) do
		k:ball("Wing", V(0.2, 0.55, 0.7), CF(s * 0.62, 0.05, -0.05) * ANG(0, 0, rad(-s * 15)), "#E8D29C")
		k:cyl("BirdLeg", 0.4, 0.1, CF(s * 0.25, -0.62, -0.3), "#E8A33C")
		k:ball("BirdFoot", V(0.25, 0.08, 0.3), V(s * 0.25, -0.82, -0.36), "#E8A33C")
		k:cyl("LionLeg", 0.45, 0.28, CF(s * 0.3, -0.6, 0.55), tan)
		k:ball("Paw", V(0.3, 0.16, 0.34), V(s * 0.3, -0.82, 0.5), tan)
	end
	local tip = k:taper("Tail", CF(0, -0.05, 0.9) * ANG(rad(70), 0, 0), 0.7, 0.05, 0.03, 3, tan, nil, rad(-12))
	k:ball("TailTuft", 0.3, tip.Position, "#A0784A")
	return body
end

B["Unicorn"] = function(k)
	local head, body = horse(k, {coat = "#FFFFFF", mane1 = "#FFB3DE", mane2 = "#C3A6FF", hoof = "#FFD86B", hoofMat = M.Foil})
	local _, parts = k:taper("Horn", head * CF(0, 0.42, -0.25) * ANG(rad(-20), 0, 0), 0.7, 0.1, 0.02, 4, "#FFD86B", M.Foil)
	parts[#parts].Material = M.Neon
	for i = 1, 3 do
		k:cyl("HornSpiral", 0.03, 0.2 - i * 0.035, head * CF(0, 0.42, -0.25) * ANG(rad(-20), 0, 0) * CF(0, i * 0.15, 0) * ANG(0, 0, rad(15)), "#E8B84A")
	end
	return body
end

B["Pegasus Foal"] = function(k)
	local _, body = horse(k, {coat = "#E6F0FF", mane1 = "#BCD8FF", mane2 = "#9CC8FF", hoof = "#C5D6EE"})
	for _, s in ipairs(SIDES) do
		featherWing(k, s, {"#FFFFFF", "#F2F7FF", "#9CC8FF"}, nil, nil, 1.15)
	end
	for _, h in ipairs(HOOVES) do
		k:ball("Cloud", V(0.45, 0.22, 0.45), h, "#FFFFFF")
	end
	return body
end

B["Sky Kitsune"] = function(k)
	local head, body = fox(k, {fur = "#78C8FF", white = "#F4FAFF", inner = "#E0EEFF", mark = "#FFFFFF"})
	for i = -1, 1 do
		k:ball("CloudTail", 0.42, V(i * 0.3, 0.3, 0.85), "#F4FAFF")
		k:ball("CloudTail", 0.52, V(i * 0.5, 0.72, 1.0), "#F4FAFF")
		k:ball("CloudTail", 0.36, V(i * 0.62, 1.05, 1.0), "#FFFFFF")
	end
	for _, s in ipairs(SIDES) do
		k:ball("EarTuft", V(0.14, 0.22, 0.1), head * CF(s * 0.28, 0.82, 0), "#FFFFFF")
		k:ball("Wing", V(0.12, 0.45, 0.55), CF(s * 0.42, 0.1, 0.1) * ANG(0, 0, rad(-s * 40)), "#FFFFFF")
	end
	k:sigil(head * CF(0, 0.45, 0.55), 0.22)
	return body
end

B["Fire Drake"] = function(k)
	local red = "#DC3C14"
	local body = k:ball("Body", V(1.3, 1.1, 1.6), V(0, 0, 0), red)
	k:ball("Belly", V(0.9, 0.8, 0.9), V(0, -0.12, -0.45), "#FFB04A")
	for _, y in ipairs({-0.3, -0.05, 0.2}) do
		k:block("Plate", V(0.6, 0.05, 0.05), V(0, y, -0.86), "#E08A2E")
	end
	local head = CF(0, 0.75, -0.95)
	k:ball("Head", 1.0, head, red)
	k:ball("Snout", V(0.75, 0.55, 0.6), head * CF(0, -0.15, -0.42), red)
	for _, s in ipairs(SIDES) do
		k:ball("Nostril", 0.08, head * CF(s * 0.15, -0.05, -0.72), "#3A0D0A")
		k:taper("Horn", head * CF(s * 0.28, 0.4, 0.15) * ANG(rad(30), 0, rad(-s * 15)), 0.35, 0.09, 0.04, 3, "#F2E6C8")
		k:wedge("Wing", V(0.08, 0.55, 0.8), CF(s * 0.65, 0.5, 0.15) * ANG(0, 0, rad(-s * 40)), "#8C2810")
		for _, z in ipairs({-0.45, 0.5}) do
			k:cyl("Leg", 0.55, 0.4, CF(s * 0.42, -0.6, z), red)
			k:ball("Foot", V(0.45, 0.2, 0.55), V(s * 0.42, -0.88, z - 0.05), "#A82E10")
		end
	end
	k:eyes(head, 0.5, 0.45)
	for i = 0, 3 do
		k:taper("Spike", CF(0, 0.5 - i * 0.03, -0.4 + i * 0.33), 0.25, 0.12, 0.04, 2, "#8C2810")
	end
	local tip = k:taper("Tail", CF(0, 0, 0.75) * ANG(rad(105), 0, 0), 1.2, 0.3, 0.1, 5, red, nil, rad(-10))
	local flame = k:ball("TailFlame", 0.35, tip.Position, "#FFB04A", M.Neon)
	Kit.flame(flame, "#FFB04A", 0.3)
	return body
end

B["Frost Wyvern"] = function(k)
	local ice = "#96DCFF"
	local body = k:ball("Body", V(0.8, 0.8, 1.3), V(0, 0, 0), ice)
	k:ball("Belly", V(0.55, 0.55, 0.8), V(0, -0.12, -0.25), "#FFFFFF")
	local neckTip = k:taper("Neck", CF(0, 0.25, -0.5) * ANG(rad(-35), 0, 0), 0.8, 0.22, 0.17, 3, ice)
	local head = CF(neckTip.Position + V(0, 0.15, -0.1))
	k:ball("Head", V(0.7, 0.6, 0.85), head, ice)
	k:ball("Snout", V(0.45, 0.35, 0.5), head * CF(0, -0.1, -0.4), ice)
	k:eyes(head, 0.35, 0.45)
	for i = 0, 2 do
		k:wedge("Crest", V(0.06, 0.35, 0.4), head * CF(0, 0.32, 0.1 + i * 0.15), "#FFFFFF")
	end
	for _, s in ipairs(SIDES) do
		k:cyl("Leg", 0.5, 0.22, CF(s * 0.25, -0.55, 0.2), ice)
		k:ball("Foot", V(0.25, 0.12, 0.35), V(s * 0.25, -0.8, 0.15), "#7CC8F0")
		k:wedge("WingArm", V(0.06, 1.1, 1.3), CF(s * 0.85, 0.4, 0) * ANG(0, 0, rad(-s * 30)), "#7CC8F0")
	end
	for i = 0, 4 do
		local c = k:block("Crystal", V(0.18, 0.3, 0.18), CF(0, 0.42 - 0.04 * i, -0.35 + i * 0.3) * ANG(0, rad(45), 0), "#CFF2FF", M.Glass)
		c.Transparency = 0.2
	end
	local tip = k:taper("Tail", CF(0, -0.05, 0.6) * ANG(rad(100), 0, 0), 1.3, 0.2, 0.05, 5, ice, nil, rad(-8))
	local tc = k:block("Crystal", V(0.25, 0.25, 0.25), tip * ANG(rad(45), 0, rad(45)), "#CFF2FF", M.Glass)
	tc.Transparency = 0.2
	return body
end

B["Thunder Dragon"] = function(k)
	local head, body, segs = serpent(k, {body = "#4A4E6E", belly = "#9AA0C8", stripe = "#FFE14A", stripeMat = M.Neon}, 8)
	antlers(k, head, "#D9C3A0")
	for _, s in ipairs(SIDES) do
		k:taper("Whisker", head * CF(s * 0.25, -0.15, -0.7) * ANG(0, 0, rad(s * 100)), 0.9, 0.025, 0.012, 4, "#FFF2A0", nil, rad(10))
	end
	for i = 1, 3 do
		k:ball("Mane", V(0.15, 0.3, 0.2), head * CF(0, 0.35, 0.2 + i * 0.18), "#FFE14A", M.Neon)
	end
	for _, idx in ipairs({2, 5}) do
		local sg = segs[idx]
		for _, s in ipairs(SIDES) do
			local foot = sg.pos + V(s * sg.d * 0.45, -sg.d * 0.55, 0)
			k:cyl("Leg", 0.35, 0.12, CF(foot + V(0, 0.1, 0)), "#4A4E6E")
			k:ball("Cloud", V(0.35, 0.18, 0.3), foot - V(0, 0.1, 0), "#E8EAF6")
		end
	end
	return body
end

B["Phoenix"] = function(k)
	local orange = "#FF7800"
	local body = k:ball("Body", V(0.9, 1.0, 1.1), V(0, 0, 0), orange)
	k:ball("Chest", V(0.6, 0.6, 0.4), V(0, -0.05, -0.4), "#FFC832")
	local head = CF(0, 0.75, -0.35)
	k:ball("Head", 0.7, head, orange)
	k:taper("Beak", head * CF(0, -0.05, -0.32) * ANG(rad(-90), 0, 0), 0.3, 0.1, 0.02, 3, "#FFD86B", nil, rad(-25))
	k:eyes(head, 0.35, 0.45)
	for i = -1, 1 do
		k:taper("Crest", head * CF(i * 0.1, 0.3, 0.05) * ANG(rad(-15), 0, rad(-i * 22)), 0.55, 0.07, 0.02, 3, "#FF3C1E", M.Neon, rad(12))
		local tip = k:taper("TailFeather", CF(i * 0.12, -0.2, 0.5) * ANG(rad(120), 0, rad(i * 10)), 1.4, 0.09, 0.04, 5, "#FFE08A", M.Neon, rad(-5))
		k:ball("TailEye", V(0.22, 0.3, 0.08), tip.Position, "#FF3C1E", M.Neon)
	end
	for _, s in ipairs(SIDES) do
		flameWings(k, CF(s * 0.45, 0.3, 0.1), s, {"#FF7800", "#FF9E1F", "#FFC832"})
		k:cyl("Leg", 0.3, 0.08, CF(s * 0.18, -0.6, 0.05), "#FFD86B")
	end
	Kit.flame(body, "#FF9E1F", 0.5)
	return body
end

B["Emberhorn"] = function(k)
	local head, body = horse(k, {coat = "#FF5078", mane1 = "#FFB04A", mane2 = "#FF7A2A", maneMat = M.Neon, hoof = "#2A1A22"})
	local _, parts = k:taper("Horn", head * CF(0, 0.42, -0.25) * ANG(rad(-20), 0, 0), 0.75, 0.11, 0.02, 4, "#2A1A22", M.Slate)
	for i = 1, #parts - 1 do
		k:block("HornCrack", V(0.03, 0.16, 0.03), parts[i].CFrame * ANG(0, 0, math.pi / 2) * CF(0, 0, -0.08 + 0.01 * i), "#FF7A2A", M.Neon)
	end
	for _, h in ipairs(HOOVES) do
		k:ball("Scales", V(0.3, 0.25, 0.3), h + V(0, 0.45, 0), "#FF8C3C")
	end
	k:sigil(head * CF(0, 0.5, 0.75), 0.25)
	return body
end

B["Glacier Pegasus"] = function(k)
	local head, body = horse(k, {coat = "#B4F0FF", mane1 = "#FFFFFF", mane2 = "#DFF8FF", hoof = "#9ADCF2", hoofMat = M.Glass})
	for _, s in ipairs(SIDES) do
		for j = 0, 3 do
			local len = 1.5 - j * 0.25
			local f = k:block("CrystalWing", V(0.1, len, 0.35), CF(s * 0.55, 0.45, 0.05) * ANG(0, 0, rad(-s * (45 + j * 15))) * CF(0, len / 2 - 0.1, 0.1 * j) * ANG(0, rad(45), 0), "#DFF8FF", M.Glass)
			f.Transparency = 0.25
		end
	end
	k:sigil(head * CF(0, 0.5, 0.75), 0.25)
	return body
end

B["Hydra"] = function(k)
	local green, belly, fin = "#288C50", "#A8D88A", "#1E6E3C"
	local body = k:ball("Body", V(1.5, 1.2, 1.6), V(0, 0, 0), green)
	k:ball("Belly", V(1.0, 0.8, 0.6), V(0, -0.2, -0.55), belly)
	for _, x in ipairs({-0.5, 0.5}) do
		for _, z in ipairs({-0.5, 0.5}) do
			k:cyl("Leg", 0.5, 0.4, CF(x, -0.7, z), green)
			k:ball("Foot", V(0.45, 0.2, 0.5), V(x, -0.95, z - 0.05), fin)
		end
	end
	local moods = {[-1] = "sleepy", [0] = "happy", [1] = "grumpy"}
	for i = -1, 1 do
		local tip = k:taper("Neck", CF(i * 0.45, 0.4, -0.5) * ANG(rad(-25), 0, rad(-i * 28)), 0.9, 0.25, 0.2, 3, green)
		local head = CF(tip.Position + V(0, 0.15, -0.05)) * ANG(0, -i * 0.3, 0)
		k:ball("Head", V(0.65, 0.55, 0.75), head, green)
		k:ball("Snout", V(0.45, 0.3, 0.4), head * CF(0, -0.1, -0.35), belly)
		k:wedge("Fin", V(0.05, 0.3, 0.35), head * CF(0, 0.32, 0.15), fin)
		local mood = moods[i]
		k:eyes(head, 0.32, 0.45, mood == "grumpy" and "#FFD86B" or "#1A1A1A", mood)
	end
	k:taper("Tail", CF(0, -0.1, 0.75) * ANG(rad(110), 0, 0), 0.7, 0.3, 0.08, 3, green)
	return body
end

B["Leviathan"] = function(k)
	local blue, fin = "#143CA0", "#2A5AC8"
	local orb = k:ball("Orb", 1.0, V(0, 0, 0), "#7FD4FF", M.Glass)
	orb.Transparency = 0.3
	k:ball("OrbCore", 0.35, V(0, 0, 0), "#B2FFFF", M.Neon)
	local tilt = ANG(rad(25), 0, 0)
	local n = 12
	for i = 1, n do
		local a = -math.pi / 2 + (i / n) * math.pi * 1.8
		local d = 0.6 - 0.35 * (i / n)
		local pos = (tilt * CF(math.cos(a) * 1.05, 0, math.sin(a) * 1.05)).Position
		k:ball("Body", d, pos, blue)
		if i % 2 == 0 then
			k:ball("Spot", d * 0.25, pos + V(0, d * 0.45, 0), "#3CE6F0", M.Neon)
		end
		if i == n then
			k:wedge("TailFin", V(0.05, 0.4, 0.5), CF(pos) * ANG(0, -a, 0), fin)
		end
	end
	local head = CF(0, 0.45, -1.15)
	k:ball("Head", V(0.75, 0.6, 0.9), head, blue)
	k:ball("Snout", V(0.5, 0.35, 0.45), head * CF(0, -0.1, -0.4), "#2D5BD0")
	k:eyes(head, 0.37, 0.48)
	for _, s in ipairs(SIDES) do
		for j = 0, 2 do
			k:wedge("FanFin", V(0.04, 0.45, 0.3), head * CF(s * 0.38, 0.05, 0.1) * ANG(0, rad(90 * s), rad(-s * (20 + j * 30))) * CF(0, 0.2, 0), fin)
		end
	end
	Kit.particles(orb, "#B2FFFF", {size = 0.12, rate = 2, life = 2, speed = 0.3, accel = V(0, 0.6, 0)})
	return orb
end

B["Stormfire Dragon"] = function(k)
	local head, body, segs = serpent(k, {body = "#FF3C00", belly = "#5A1E14", stripe = "#FFE14A", stripeMat = M.Neon}, 8)
	antlers(k, head, "#FFE14A")
	local wingAt = segs[2].pos + V(0, segs[2].d * 0.3, 0)
	for _, s in ipairs(SIDES) do
		flameWings(k, CF(wingAt + V(s * 0.35, 0, 0)), s, {"#FF5A00", "#FF9E1F", "#FFB04A"}, 1.1)
	end
	k:sigil(head * CF(0, 0.55, 0.45), 0.25)
	Kit.flame(segs[#segs].seg, "#FFB04A", 0.3)
	return body
end

B["Aether Dragon"] = function(k)
	local head, body, segs = serpent(k, {body = "#C8AAFF", bodyMat = M.Glass, belly = "#E8DCFF", stripe = "#FFFFFF", stripeMat = M.Neon}, 8)
	for _, sg in ipairs(segs) do
		sg.seg.Transparency = 0.35
		k:ball("Star", sg.d * 0.18, sg.pos + V(sg.d * 0.1, 0, 0), "#FFFFFF", M.Neon)
	end
	k.Model:FindFirstChild("Head").Transparency = 0.25
	antlers(k, head, "#FFD86B", 0.8)
	k:ring("Halo", head * CF(0, 0.25, 0.6) * ANG(rad(90), 0, 0), 0.6, 0.08, 14, "#FFD86B", M.Neon)
	for i = 0, 3 do
		k:block("Rune", V(0.06, 0.18, 0.04), head * CF(0, 0.25, 0.6) * ANG(0, 0, i * math.pi / 2) * CF(0, 0.6, -0.02), "#FFF2C0", M.Neon)
	end
	local wingAt = segs[3].pos
	for _, s in ipairs(SIDES) do
		for j = 0, 1 do
			local w = k:block("LightWing", V(0.05, 1.4 - j * 0.35, 0.6), CF(wingAt + V(s * 0.3, 0.2, 0)) * ANG(0, 0, rad(-s * (50 + j * 25))) * CF(0, 0.65 - j * 0.15, 0), "#E8DCFF", M.Neon)
			w.Transparency = 0.4
		end
	end
	local last = segs[#segs]
	k:taper("TailWisp", CF(last.pos) * ANG(rad(95), 0, 0), 1.2, 0.12, 0.02, 4, "#E8DCFF", M.Neon, rad(-6))
	return body
end

------------------------------------------------------------------ settings per pet
-- fit: "height" or "max" (longest side); size in studs from the design quick-view table
local INFO = {
	["Imp"] = {size = 1.3, flying = true, element = "#FF7A5A"},
	["Fairy Sprite"] = {size = 1.2, flying = true, element = "#FFAAE6"},
	["Jackalope"] = {size = 1.6, flying = false, element = "#D9C3A0"},
	["Kitsune Kit"] = {size = 1.6, flying = false, element = "#7FD4FF"},
	["Gryphon Chick"] = {size = 2.0, flying = false, element = "#FFE08A"},
	["Unicorn"] = {size = 2.2, flying = false, element = "#FFB3DE"},
	["Pegasus Foal"] = {size = 2.2, flying = true, element = "#9CC8FF"},
	["Sky Kitsune"] = {size = 2.0, flying = true, element = "#B2E4FF"},
	["Fire Drake"] = {size = 2.6, flying = false, element = "#FF8C3C"},
	["Frost Wyvern"] = {size = 2.6, flying = true, element = "#9ADCFF"},
	["Thunder Dragon"] = {size = 3.2, fit = "max", flying = true, element = "#FFE14A"},
	["Phoenix"] = {size = 3.0, flying = true, element = "#FF9E1F"},
	["Emberhorn"] = {size = 2.8, flying = false, element = "#FF7A2A"},
	["Glacier Pegasus"] = {size = 2.8, flying = true, element = "#B4F0FF"},
	["Hydra"] = {size = 3.4, flying = false, element = "#4CE08A"},
	["Leviathan"] = {size = 3.6, fit = "max", flying = true, element = "#3CE6F0"},
	["Stormfire Dragon"] = {size = 3.6, fit = "max", flying = true, element = "#FF7A2A"},
	["Aether Dragon"] = {size = 4.0, fit = "max", flying = true, element = "#C8AAFF"},
}
Pets.Info = INFO
Pets.Builders = B

-- Build a pet. anchored=true for display (showcase/statues), false for following pets.
function Pets.Build(name, anchored)
	local build, info = B[name], INFO[name]
	local data = Config.Pets[name]
	if not build or not info or not data then return nil end
	local k = Kit.new(name)
	local fxPart = build(k) or k.Model:FindFirstChild("Body")
	if info.fit == "max" then k:fitMax(info.size) else k:fitHeight(info.size) end
	Kit.tierFx(fxPart, data.Rarity, info.element)
	local lo, hi = k:bounds()
	k.Model:SetAttribute("Pet", name)
	k.Model:SetAttribute("Rarity", data.Rarity)
	k.Model:SetAttribute("Flying", info.flying)
	k.Model:SetAttribute("Height", hi.Y - lo.Y)
	k.Model:SetAttribute("BottomOffset", -lo.Y)
	return k:finish(anchored == true)
end

return Pets
