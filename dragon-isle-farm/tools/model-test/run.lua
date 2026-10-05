-- Builds every model with the mock API and reports part counts against the budget.
local Pets, Crops, Items, Config = Load("PetModels"), Load("CropModels"), Load("ItemModels"), Load("GameConfig")

local failures = 0
local rows = {}

local function stats(model)
	local parts, emitters, lights = 0, 0, 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "Root" then parts += 1 end
		if d.ClassName == "ParticleEmitter" then emitters += 1 end
		if d.ClassName == "PointLight" then lights += 1 end
	end
	local _, size = model:GetBoundingBox()
	return parts, emitters, lights, size
end

local function check(label, kind, fn, maxParts)
	local ok, model = pcall(fn)
	if not ok or not model then
		failures += 1
		print(string.format("FAIL  %-34s %s", label, tostring(model)))
		return
	end
	local parts, emitters, lights, size = stats(model)
	local flag = (maxParts and parts > maxParts) and ("  OVER BUDGET (" .. maxParts .. ")") or ""
	table.insert(rows, string.format("%-10s %-34s parts=%3d fx=%d lights=%d size=%.1fx%.1fx%.1f%s", kind, label, parts, emitters, lights, size.X, size.Y, size.Z, flag))
end

for _, name in ipairs(Config.CropOrder) do
	check(name .. " seeds", "pouch", function() return Crops.Pouch(name) end, 8)
	for s = 1, 4 do
		check(name .. " stage " .. s, "plant", function() return Crops.Plant(name, s) end, 40)
	end
	check(name, "harvest", function() return Crops.Harvested(name) end, 25)
end
for _, mut in ipairs({"Golden", "Scorched", "Frozen", "Shocked", "Celestial"}) do
	check("Moonmelon " .. mut, "mutation", function() return Crops.Harvested("Moonmelon", mut) end, 25)
end

for _, name in ipairs({"Imp", "Fairy Sprite", "Jackalope", "Kitsune Kit", "Gryphon Chick", "Unicorn", "Pegasus Foal", "Sky Kitsune", "Fire Drake", "Frost Wyvern", "Thunder Dragon", "Phoenix", "Emberhorn", "Glacier Pegasus", "Hydra", "Leviathan", "Stormfire Dragon", "Aether Dragon"}) do
	check(name, "pet", function()
		local m = Pets.Build(name, false)
		assert(m:GetAttribute("Rarity") == Config.Pets[name].Rarity, "rarity attribute")
		return m
	end, 60)
end

for _, name in ipairs(Config.EggOrder) do
	check(name, "egg", function() return Items.Egg(name) end, 30)
end
for _, r in ipairs(Config.RarityOrder) do
	check("Nest egg " .. r, "nest", function() return Items.NestEgg(r, false) end, 30)
end
check("Nest egg secret", "nest", function()
	local m = Items.NestEgg("Legendary", true)
	Items.SetNestReady(m, true)
	assert(m:FindFirstChild("ReadyBeam"), "ready beam missing")
	Items.SetNestReady(m, false)
	assert(not m:FindFirstChild("ReadyBeam"), "ready beam not removed")
	return m
end, 40)
for _, name in ipairs(Items.GemItemNames) do
	check(name, "gem item", function() return Items.GemItem(name) end, 60)
end

for _, r in ipairs(rows) do print(r) end
print(string.format("\n%d models built, %d failures", #rows, failures))
