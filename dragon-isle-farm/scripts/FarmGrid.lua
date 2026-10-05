-- Dragon Isle Farm: the farm build grid, shared by GameServer (the rules) and BuildMode (the preview).
-- Studio path: ReplicatedStorage.Shared.FarmGrid (ModuleScript)
--
-- The fenced farm is a SIZE x SIZE grid of CELL-stud cells in plot-local space: the plot's PrimaryPart
-- (Floor) is the origin and the gate is at +Z. A layout item sits at cell (X, Z), its lowest-index corner,
-- covers W x H cells (swapped when turned 90 or 270 degrees) and R is the number of quarter turns.
-- A profile's layout is {Next = number, Items = {[id] = {T = type, X, Z, R, I = soil index}}}.
local Config = require(script.Parent.GameConfig)

local Grid = {}
Grid.CELL = 4
Grid.SIZE = 15
Grid.HALF = Grid.CELL * Grid.SIZE / 2

-- cells kept clear so players can always walk in through the gate and land on PlotSpawn
local RESERVED = {}
for x = 6, 8 do
	for z = 13, 14 do RESERVED[x * 100 + z] = true end
end
Grid.Reserved = RESERVED

function Grid.key(x, z) return x * 100 + z end

-- footprint in cells for a layout type: "Soil", "Nest", a Gem Store farm item or a block
function Grid.size(t)
	if t == "Soil" then return 2, 2 end
	if t == "Nest" then return 3, 3 end
	local item = Config.FarmItemSize[t]
	if item then return item[1], item[2] end
	local block = Config.Blocks[t]
	if block then return block.W, block.H end
	return nil
end

function Grid.footprint(t, r)
	local w, h = Grid.size(t)
	if not w then return nil end
	if r % 2 == 1 then return h, w end
	return w, h
end

-- plot-local CFrame of an item's centre at floor-pivot height
function Grid.toLocal(t, x, z, r)
	local w, h = Grid.footprint(t, r)
	return CFrame.new(-Grid.HALF + Grid.CELL * (x + w / 2), 0, -Grid.HALF + Grid.CELL * (z + h / 2))
		* CFrame.Angles(0, -r * math.pi / 2, 0)
end

-- cell under a plot-local position
function Grid.cellAt(localPos)
	return math.floor((localPos.X + Grid.HALF) / Grid.CELL), math.floor((localPos.Z + Grid.HALF) / Grid.CELL)
end

-- corner cell that centres a footprint on the hovered cell
function Grid.anchor(t, r, hoverX, hoverZ)
	local w, h = Grid.footprint(t, r)
	return hoverX - math.floor((w - 1) / 2), hoverZ - math.floor((h - 1) / 2)
end

-- [cell key] = item id for every occupied cell
function Grid.occupancy(items)
	local occ = {}
	for id, it in pairs(items) do
		local w, h = Grid.footprint(it.T, it.R)
		if w then
			for dx = 0, w - 1 do
				for dz = 0, h - 1 do occ[Grid.key(it.X + dx, it.Z + dz)] = id end
			end
		end
	end
	return occ
end

-- can type t go at (x, z) turned r? ignoreId is the item being moved
function Grid.fits(items, t, x, z, r, ignoreId)
	local w, h = Grid.footprint(t, r)
	if not w then return false, "You can't place that" end
	if x < 0 or z < 0 or x + w > Grid.SIZE or z + h > Grid.SIZE then return false, "That's outside your farm" end
	local occ = Grid.occupancy(items)
	for dx = 0, w - 1 do
		for dz = 0, h - 1 do
			local key = Grid.key(x + dx, z + dz)
			if RESERVED[key] then return false, "Keep the path by the gate clear" end
			local other = occ[key]
			if other and other ~= ignoreId then return false, "Something is already there" end
		end
	end
	return true
end

-- starting farm: 12 soil tiles in a 4x3 block, the nest, and where Gem Store items go when first bought
Grid.TemplateSoil = {
	{2, 1}, {5, 1}, {8, 1}, {11, 1},
	{2, 4}, {5, 4}, {8, 4}, {11, 4},
	{2, 7}, {5, 7}, {8, 7}, {11, 7},
}
Grid.TemplateNest = {1, 11}
Grid.TemplateItems = {
	["Viking Banner"] = {13, 13},
	["Dragon Statue"] = {11, 10},
	["Golden Watering Can"] = {5, 14},
	["Rune Totem"] = {13, 1},
}

function Grid.defaultLayout()
	local items, n = {}, 0
	local function add(it)
		n += 1
		items[tostring(n)] = it
	end
	for i, c in ipairs(Grid.TemplateSoil) do add({T = "Soil", X = c[1], Z = c[2], R = 0, I = i}) end
	add({T = "Nest", X = Grid.TemplateNest[1], Z = Grid.TemplateNest[2], R = 0})
	return {Next = n + 1, Items = items}
end

return Grid
