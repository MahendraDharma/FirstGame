-- Dragon Isle Farm: decoration blocks for Build Mode (Config.Blocks).
-- Studio path: ReplicatedStorage.Shared.Models.BuildModels (ModuleScript)
-- Built at real size around the origin, standing on the ground (y = 0), front -Z,
-- each filling its W x H footprint of 4-stud grid cells (see FarmGrid).
local Kit = require(script.Parent.ModelKit)

local M = Kit.Mat
local V, CF, ANG, rad = Vector3.new, CFrame.new, CFrame.Angles, math.rad

local B = {}

B["Dirt Path"] = function(k)
	k:block("Path", V(3.95, 0.12, 3.95), CF(0, 0.06, 0), "#8A6A48", M.Ground)
	for i = 1, 4 do
		k:ball("Pebble", V(0.35, 0.12, 0.3), CF(math.cos(i * 1.7) * 1.2, 0.13, math.sin(i * 2.3) * 1.2), "#A08B6E")
	end
end

B["Stone Path"] = function(k)
	for _, s in ipairs({{-0.9, -0.9, 1.6}, {0.95, -0.8, 1.4}, {-0.8, 0.95, 1.4}, {0.9, 0.9, 1.6}}) do
		k:cyl("Stone", 0.16, s[3], CF(s[1], 0.08, s[2]), "#9A9A9E", M.Slate)
	end
end

-- runs along X; rotate to turn corners
B["Wooden Fence"] = function(k)
	for _, x in ipairs({-1.8, 1.8}) do k:block("Post", V(0.4, 2.6, 0.4), CF(x, 1.3, 0), "#6B4A2E", M.Wood) end
	for _, y in ipairs({0.9, 1.9}) do k:block("Rail", V(4, 0.3, 0.2), CF(0, y, 0), "#8A6440", M.Wood) end
end

B["Hay Bale"] = function(k)
	k:cyl("Bale", 2.6, 2.2, CF(0, 1.1, 0) * ANG(0, 0, rad(90)), "#D8BE78", M.Fabric)
	for _, x in ipairs({-0.6, 0.6}) do
		k:cyl("Band", 0.14, 2.26, CF(x, 1.1, 0) * ANG(0, 0, rad(90)), "#9C7A3C", M.Fabric)
	end
end

B["Flower Bed"] = function(k)
	k:block("Box", V(3.4, 0.6, 3.4), CF(0, 0.3, 0), "#7A5232", M.Wood)
	k:block("Soil", V(3.0, 0.1, 3.0), CF(0, 0.62, 0), "#4A3222", M.Ground)
	local colors = {"#FF6FAE", "#FFD23F", "#B784FF", "#FF7A45", "#FFFFFF"}
	for i = 0, 8 do
		local x, z = (i % 3 - 1) * 0.95, (math.floor(i / 3) - 1) * 0.95
		k:cyl("Stem", 0.5, 0.08, CF(x, 0.9, z), "#3E8E3E")
		k:ball("Flower", V(0.45, 0.3, 0.45), CF(x, 1.2, z), colors[i % #colors + 1])
		k:ball("Leaf", V(0.35, 0.08, 0.18), CF(x + 0.15, 0.85, z), "#4CAF50")
	end
end

B["Berry Bush"] = function(k)
	k:ball("Bush", V(3.0, 2.2, 3.0), CF(0, 1.1, 0), "#3E7D3A")
	k:ball("Bush", V(2.0, 1.6, 2.0), CF(0.5, 1.9, 0.3), "#4A8F44")
	for i = 1, 8 do
		local a = i * 0.8
		k:ball("Berry", V(0.3, 0.3, 0.3), CF(math.cos(a) * 1.35, 1.0 + (i % 3) * 0.35, math.sin(a) * 1.35), "#C8143C")
	end
end

B["Boulder"] = function(k)
	k:ball("Rock", V(3.2, 1.8, 2.8), CF(0, 0.8, 0), "#7D7D82", M.Slate)
	k:ball("Rock", V(1.6, 1.2, 1.6), CF(1.0, 0.5, -0.9), "#6E6E73", M.Slate)
	k:ball("Moss", V(2.2, 0.4, 1.8), CF(-0.2, 1.6, 0.1), "#5E8C3A", M.Grass)
end

B["Lantern Post"] = function(k)
	k:block("Base", V(1.0, 0.3, 1.0), CF(0, 0.15, 0), "#4A4A4E", M.Slate)
	k:cyl("Pole", 4.6, 0.3, CF(0, 2.6, 0), "#3A2A1E", M.Wood)
	k:block("Arm", V(1.2, 0.2, 0.2), CF(0.5, 4.8, 0), "#3A2A1E", M.Wood)
	local lamp = k:block("Lamp", V(0.7, 0.9, 0.7), CF(1.0, 4.25, 0), "#FFC864", M.Neon)
	k:block("Cap", V(0.9, 0.2, 0.9), CF(1.0, 4.8, 0), "#2A2A2E", M.Metal)
	Kit.light(lamp, "#FFC864", 16, 1.5)
end

-- 2 x 2 cells; blocky like the island's other trees
B["Pine Tree"] = function(k)
	k:block("Trunk", V(1, 3, 1), CF(0, 1.5, 0), "#5A3A22", M.Wood)
	for i, s in ipairs({{6, 1.4, 3.2}, {4.6, 1.3, 4.4}, {3.2, 1.2, 5.5}, {1.8, 1.1, 6.5}}) do
		k:block("Leaves", V(s[1], s[2], s[1]), CF(0, s[3], 0) * ANG(0, rad(i * 20), 0), i % 2 == 0 and "#2E5E3A" or "#356B42", M.Grass)
	end
end

-- 2 x 2 cells
B["Duck Pond"] = function(k)
	k:cyl("Rim", 0.3, 7.6, CF(0, 0.15, 0), "#8E8E92", M.Slate)
	local water = k:cyl("Water", 0.32, 6.6, CF(0, 0.17, 0), "#4FA8D8", M.Glass)
	water.Transparency = 0.2
	k:ball("Duck", V(0.9, 0.6, 1.2), CF(1, 0.55, 0.5), "#FFE14A")
	k:ball("DuckHead", V(0.5, 0.5, 0.5), CF(1, 0.95, 0), "#FFE14A")
	k:block("Beak", V(0.25, 0.1, 0.3), CF(1, 0.92, -0.32), "#FF8C1A")
	for _, p in ipairs({{-1.6, -1}, {-0.8, 1.6}, {1.8, -1.6}}) do
		k:cyl("Lily", 0.05, 1.0, CF(p[1], 0.36, p[2]), "#3E8E3E")
	end
	for i = 1, 5 do
		k:cyl("Reed", 1.4, 0.12, CF(-3 + i * 0.25, 0.8, 2.6 - i * 0.15), "#5E8C3A")
	end
end

B["Rune Stone"] = function(k)
	local stone = k:block("Stone", V(1.4, 3.6, 0.9), CF(0, 1.8, 0), "#7A7A80", M.Slate)
	k:ball("Top", V(1.4, 0.7, 0.9), CF(0, 3.6, 0), "#7A7A80", M.Slate)
	for i = 0, 3 do
		k:block("Rune", V(0.5, 0.08, 0.05), CF(0, 0.9 + i * 0.7, -0.46) * ANG(0, 0, rad(i % 2 == 0 and 30 or -30)), "#3CE6F0", M.Neon)
	end
	Kit.light(stone, "#3CE6F0", 6, 0.6)
end

local Build = {}
Build.Builders = B

-- anchored decoration model for a Config.Blocks name
function Build.Block(name)
	local fn = B[name]
	if not fn then return nil end
	local k = Kit.new(name)
	fn(k)
	k.Model:SetAttribute("Block", name)
	return k:finish(true)
end

return Build
