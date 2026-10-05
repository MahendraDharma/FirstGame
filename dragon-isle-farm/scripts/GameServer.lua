-- Dragon Isle Farm: server game logic
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage.Shared.GameConfig)
local DataService = require(script.Parent.DataService)
local Models = ReplicatedStorage.Shared.Models
local PetModels = require(Models.PetModels)
local CropModels = require(Models.CropModels)
local ItemModels = require(Models.ItemModels)
local BuildModels = require(Models.BuildModels)
local FarmGrid = require(ReplicatedStorage.Shared.FarmGrid)

local PLANT_SCALE = 1.6 -- plants are authored small; this fills the 8-stud soil tiles

------------------------------------------------------------------ remotes
local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
Remotes.Name = "Remotes"; Remotes.Parent = ReplicatedStorage
local function remote(class, name)
	local r = Remotes:FindFirstChild(name) or Instance.new(class)
	r.Name = name; r.Parent = Remotes
	return r
end
local Request = remote("RemoteFunction", "Request")
local DataUpdate = remote("RemoteEvent", "DataUpdate")
local Notify = remote("RemoteEvent", "Notify")
local TradeUpdate = remote("RemoteEvent", "TradeUpdate")

local PlotsFolder = workspace:WaitForChild("Plots")
local Village = workspace:WaitForChild("Village")
local PetsFolder = workspace:FindFirstChild("ActivePets") or Instance.new("Folder")
PetsFolder.Name = "ActivePets"; PetsFolder.Parent = workspace

local plotOwner: {[Model]: Player} = {}
local playerPlot: {[Player]: Model} = {}
local selectedSeed: {[Player]: string} = {}
local busy: {[Player]: boolean} = {}
local held: {[Player]: {Kind: string, Key: string}} = {} -- item in the player's hand (see "held items & drops")
local validateHeld -- defined below; push() calls it so a hand never shows an item the player no longer owns

------------------------------------------------------------------ helpers
local function notify(player, text, kind)
	Notify:FireClient(player, text, kind or "info")
end

local function rarityTier(r) return Config.Rarities[r] and Config.Rarities[r].Tier or 0 end

local function cropKey(name, mutation) return mutation and (name .. "|" .. mutation) or name end
local function splitKey(key)
	local name, mut = string.match(key, "^(.-)|(.+)$")
	if name then return name, mut end
	return key, nil
end

local function addCount(tbl, key, n)
	tbl[key] = (tbl[key] or 0) + n
	if tbl[key] <= 0 then tbl[key] = nil end
end

local function getBonuses(profile)
	local b = {GrowSpeed = 0, SellBonus = 0, MutationChance = 0, GemBonus = 0, PetMutations = {}}
	for _, pet in pairs(profile.Pets) do
		if pet.Equipped then
			local d = Config.Pets[pet.Name]
			if d then
				b.GrowSpeed += d.GrowSpeed or 0
				b.SellBonus += d.SellBonus or 0
				b.MutationChance += d.MutationChance or 0
				b.GemBonus += d.GemBonus or 0
				if d.Mutation then table.insert(b.PetMutations, d.Mutation) end
			end
		end
	end
	for name, count in pairs(profile.Items) do
		local d = Config.GemItems[name]
		if d and count > 0 then
			b.GrowSpeed += d.GrowSpeed or 0
			b.MutationChance += d.MutationChance or 0
		end
	end
	return b
end

local function cropValue(name, mutation, sellBonus)
	local d = Config.Crops[name]
	if not d then return 0 end
	local mult = mutation and Config.Mutations[mutation] and Config.Mutations[mutation].Mult or 1
	return math.floor(d.Sell * mult * (1 + (sellBonus or 0)))
end

local function equippedCount(profile)
	local n = 0
	for _, p in pairs(profile.Pets) do if p.Equipped then n += 1 end end
	return n
end

local function petLocked(profile, id)
	local br = profile.Breeding
	return br ~= nil and (br.A == id or br.B == id)
end

local function nearModel(player, model, dist)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or not model or not model.PrimaryPart then return false end
	return (hrp.Position - model.PrimaryPart.Position).Magnitude <= dist
end

local function snapshot(player)
	local profile = DataService.Get(player)
	if not profile then return nil end
	local sel = selectedSeed[player]
	if not sel or (profile.Seeds[sel] or 0) <= 0 then
		sel = nil
		for _, name in ipairs(Config.CropOrder) do if (profile.Seeds[name] or 0) > 0 then sel = name break end end
		selectedSeed[player] = sel
	end
	return {
		Ru = profile.Ru, Gems = profile.Gems, Seeds = profile.Seeds, Crops = profile.Crops,
		Eggs = profile.Eggs, Pets = profile.Pets, Items = profile.Items, PetSlots = profile.PetSlots,
		Breeding = profile.Breeding, Stats = profile.Stats, Bonuses = getBonuses(profile),
		Tiles = profile.Tiles, Layout = profile.Layout, Blocks = profile.Blocks, SoilSlots = profile.SoilSlots,
		SelectedSeed = selectedSeed[player], Held = held[player], Now = os.time(),
	}
end

local function push(player)
	if validateHeld then validateHeld(player) end
	local snap = snapshot(player)
	if not snap then return end
	DataUpdate:FireClient(player, snap)
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		ls.Ru.Value = snap.Ru
		ls.Gems.Value = snap.Gems
	end
end

local function newPet(profile, name)
	local id = HttpService:GenerateGUID(false)
	profile.Pets[id] = {Name = name, Equipped = false}
	return id
end

local function speciesOfTier(rarity, allowBreedOnly)
	local list = {}
	for name, d in pairs(Config.Pets) do
		if d.Rarity == rarity and (allowBreedOnly or not d.BreedOnly) then table.insert(list, name) end
	end
	table.sort(list)
	return list
end

local function rollEgg(eggName)
	local egg = Config.Eggs[eggName]
	local total = 0
	for _, w in pairs(egg.Odds) do total += w end
	local roll = math.random() * total
	local tier = nil
	for _, r in ipairs(Config.RarityOrder) do
		local w = egg.Odds[r]
		if w then
			if roll <= w then tier = r break end
			roll -= w
		end
	end
	tier = tier or "Common"
	local list = speciesOfTier(tier, false)
	return list[math.random(1, #list)]
end

------------------------------------------------------------------ pets in the world
-- Pet models come from ReplicatedStorage.Shared.Models.PetModels (see 03_Pets.md)
local function buildPetModel(name)
	local m = PetModels.Build(name, false)
	if not m then return nil end
	local d = Config.Pets[name]
	local h = m:GetAttribute("Height") or 2
	local bb = Instance.new("BillboardGui"); bb.Size = UDim2.fromOffset(160, 36); bb.StudsOffset = Vector3.new(0, h * 0.6 + 1, 0); bb.MaxDistance = 60; bb.Parent = m.PrimaryPart
	local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1,1); t.Font = Enum.Font.FredokaOne; t.TextScaled = true
	t.TextColor3 = Config.RarityColor(d.Rarity); t.TextStrokeTransparency = 0.2; t.Text = name; t.Parent = bb
	return m
end

local function refreshPets(player)
	local folder = PetsFolder:FindFirstChild(player.Name)
	if folder then folder:Destroy() end
	local profile = DataService.Get(player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not profile or not hrp then return end
	folder = Instance.new("Folder"); folder.Name = player.Name; folder.Parent = PetsFolder
	local i = 0
	local ids = {}
	for id, pet in pairs(profile.Pets) do if pet.Equipped and Config.Pets[pet.Name] then table.insert(ids, id) end end
	table.sort(ids)
	for _, id in ipairs(ids) do
		local pet = profile.Pets[id]
		i += 1
		local m = buildPetModel(pet.Name)
		if not m then continue end
		-- spread pets in an arc behind the player; ground pets walk, flyers hover at shoulder height
		local hum = char:FindFirstChildOfClass("Humanoid")
		local hrpHeight = (hum and hum.HipHeight or 2) + hrp.Size.Y / 2
		local radius = 4 + (m:GetAttribute("Height") or 2) * 0.5
		local y = m:GetAttribute("Flying") and 1.2 or (-hrpHeight + (m:GetAttribute("BottomOffset") or 1))
		local angle = math.rad(-60 + (i - 1) * 40)
		local offset = Vector3.new(math.sin(angle) * radius, y, math.cos(angle) * radius)
		m:PivotTo(hrp.CFrame * CFrame.new(offset))
		m.Parent = folder
		local a0 = Instance.new("Attachment"); a0.Parent = m.PrimaryPart
		local a1 = Instance.new("Attachment"); a1.Name = "PetSlot" .. i; a1.Position = offset; a1.Parent = hrp
		local ap = Instance.new("AlignPosition"); ap.Attachment0 = a0; ap.Attachment1 = a1; ap.MaxForce = 1e6; ap.Responsiveness = 18; ap.Parent = m.PrimaryPart
		local ao = Instance.new("AlignOrientation"); ao.Attachment0 = a0; ao.Attachment1 = a1; ao.MaxTorque = 1e6; ao.Responsiveness = 18; ao.Parent = m.PrimaryPart
		pcall(function() m.PrimaryPart:SetNetworkOwner(player) end)
	end
end

------------------------------------------------------------------ plots & tiles
local function tilePart(plot, index)
	return plot.Tiles:FindFirstChild("Tile" .. index)
end

local function renderTile(plot, index, state)
	local tile = tilePart(plot, index)
	if not tile or not tile:GetAttribute("Placed") then return end
	local prompt = tile:FindFirstChild("TilePrompt")
	local plant = tile:FindFirstChild("Plant")
	if not state then
		if plant then plant:Destroy() end
		if prompt then prompt.ActionText = "Plant"; prompt.ObjectText = "Empty soil" end
		return
	end
	local d = Config.Crops[state.Crop]
	if not d then return end
	local progress = math.clamp((os.time() - state.PlantedAt) / math.max(state.Duration, 1), 0, 1)
	local ready = progress >= 1
	-- swap in the model for the current growth stage (see 02_Seeds_and_Crops.md)
	local stage = CropModels.StageFor(progress)
	if not plant or plant:GetAttribute("Crop") ~= state.Crop or plant:GetAttribute("Stage") ~= stage then
		if plant then plant:Destroy() end
		plant = CropModels.Plant(state.Crop, stage, PLANT_SCALE)
		if not plant then return end
		plant.Name = "Plant"
		plant:PivotTo(tile.CFrame * CFrame.new(0, tile.Size.Y / 2, 0))
		local bb = Instance.new("BillboardGui"); bb.Name = "Info"; bb.Size = UDim2.fromOffset(150, 40)
		bb.StudsOffset = Vector3.new(0, (plant:GetAttribute("Height") or 2) + 1.5, 0); bb.MaxDistance = 45; bb.Parent = plant.PrimaryPart
		local t = Instance.new("TextLabel"); t.Name = "Text"; t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1,1); t.Font = Enum.Font.FredokaOne; t.TextScaled = true
		t.TextColor3 = Config.RarityColor(d.Rarity); t.TextStrokeTransparency = 0.2; t.Parent = bb
		plant.Parent = tile
	end
	local txt = plant.PrimaryPart.Info.Text
	if ready then
		txt.Text = state.Crop .. " - Ready!"
	else
		local left = math.max(0, math.ceil(state.Duration - (os.time() - state.PlantedAt)))
		txt.Text = string.format("%s %d%% (%ds)", state.Crop, math.floor(progress * 100), left)
	end
	if prompt then
		prompt.ActionText = ready and "Harvest" or "Growing..."
		prompt.ObjectText = state.Crop .. " [" .. d.Rarity .. "]"
	end
end

local function renderNest(plot, profile)
	local nest = plot:FindFirstChild("Nest")
	if not nest then return end
	local egg = plot:FindFirstChild("BreedEgg")
	local br = profile and profile.Breeding
	if not br then if egg then egg:Destroy() end return end
	if not egg then
		-- nest egg model (see 04_Eggs_and_Hatching.md): rarity colour, rune ring for secret recipes
		local rarity = Config.Pets[br.Result] and Config.Pets[br.Result].Rarity or "Common"
		egg = ItemModels.NestEgg(rarity, br.Recipe == true)
		egg.Name = "BreedEgg"
		egg:PivotTo(CFrame.new(nest.Position + Vector3.new(0, 0.5, 0)))
		local bb = Instance.new("BillboardGui"); bb.Size = UDim2.fromOffset(170, 40); bb.StudsOffset = Vector3.new(0, 4.2, 0); bb.MaxDistance = 50; bb.Parent = egg.PrimaryPart
		local t = Instance.new("TextLabel"); t.Name = "Text"; t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1,1); t.Font = Enum.Font.FredokaOne; t.TextScaled = true
		t.TextColor3 = Color3.new(1,1,1); t.TextStrokeTransparency = 0.2; t.Parent = bb
		egg.Parent = plot
	end
	local left = br.EndsAt - os.time()
	local t = egg.PrimaryPart:FindFirstChildOfClass("BillboardGui").Text
	if left <= 0 then
		t.Text = "Egg ready to hatch!"
		if not egg:GetAttribute("Ready") then
			egg:SetAttribute("Ready", true)
			ItemModels.SetNestReady(egg, true)
		end
	else
		t.Text = string.format("Breeding... %d:%02d", left // 60, left % 60)
	end
end

------------------------------------------------------------------ farm layout (Build Mode, see FarmGrid)
-- Each plot shows its owner's layout: which soil tiles are placed and where, the nest, Gem Store items
-- and decorations. Unclaimed plots show FarmGrid's default template.
local TILE_Y = 0.3   -- plot-local height of a soil tile's centre (0.6 thick, standing on the floor)
local nestRest = {}  -- [plot] = how the nest parts sit relative to the nest centre

local function layoutOf(profile)
	return profile and profile.Layout or FarmGrid.defaultLayout()
end

-- give a newly bought Gem Store farm item a spot: its usual one if free, else the first free one
local function autoPlaceFarmItems(profile)
	local layout = profile.Layout
	for name in pairs(Config.FarmItemSize) do
		if (profile.Items[name] or 0) > 0 then
			local placed = false
			for _, it in pairs(layout.Items) do if it.T == name then placed = true break end end
			if not placed then
				local spot = FarmGrid.TemplateItems[name]
				local x, z
				if spot and FarmGrid.fits(layout.Items, name, spot[1], spot[2], 0) then
					x, z = spot[1], spot[2]
				else
					for cz = FarmGrid.SIZE - 1, 0, -1 do -- search from the gate side
						for cx = 0, FarmGrid.SIZE - 1 do
							if not x and FarmGrid.fits(layout.Items, name, cx, cz, 0) then x, z = cx, cz end
						end
					end
				end
				if x then -- no room: it waits in the Build Mode palette
					layout.Items[tostring(layout.Next)] = {T = name, X = x, Z = z, R = 0}
					layout.Next += 1
				end
			end
		end
	end
end

-- make sure a profile (including saves from before Build Mode) has a layout and the build fields
local function ensureLayout(profile)
	profile.SoilSlots = math.clamp(profile.SoilSlots or Config.BaseSoil, Config.BaseSoil, Config.MaxSoil)
	profile.Blocks = profile.Blocks or {}
	if not profile.Layout then profile.Layout = FarmGrid.defaultLayout() end
	autoPlaceFarmItems(profile)
end

-- move the plot's parts and models to match a layout (profile = nil: the default template)
local function applyLayout(plot, profile)
	local layout = layoutOf(profile)
	local base = plot.PrimaryPart.CFrame
	local top = plot.PrimaryPart.Size.Y / 2
	-- soil tiles: placed ones go to their cells, the rest are parked under the floor
	local soilAt = {}
	for _, it in pairs(layout.Items) do if it.T == "Soil" and it.I then soilAt[it.I] = it end end
	for i = 1, Config.MaxSoil do
		local tile = tilePart(plot, i)
		if tile then
			local it = soilAt[i]
			local prompt = tile:FindFirstChild("TilePrompt")
			local cf = it and base * FarmGrid.toLocal("Soil", it.X, it.Z, it.R) * CFrame.new(0, TILE_Y, 0) or base * CFrame.new(0, -10, 0)
			if (tile.Position - cf.Position).Magnitude > 0.01 then
				tile.CFrame = cf
				local plant = tile:FindFirstChild("Plant")
				if plant then plant:Destroy() end -- renderTile rebuilds it on the tile's new spot
			end
			tile:SetAttribute("Placed", it ~= nil)
			tile.Transparency = it and 0 or 1
			tile.CanCollide = it ~= nil
			tile.CanQuery = it ~= nil
			if prompt then prompt.Enabled = it ~= nil end
		end
	end
	-- the nest
	local rest = nestRest[plot]
	for _, it in pairs(layout.Items) do
		if it.T == "Nest" and rest then
			local c = FarmGrid.toLocal("Nest", it.X, it.Z, 0).Position
			local nestCF = base * CFrame.new(c.X, rest.NestY, c.Z) * rest.NestRot
			if (plot.Nest.Position - nestCF.Position).Magnitude > 0.01 then
				plot.Nest.CFrame = nestCF
				plot.NestRim.CFrame = base * CFrame.new(c.X, rest.RimY, c.Z) * rest.RimRot
				local egg = plot:FindFirstChild("BreedEgg")
				if egg then egg:Destroy() end -- renderNest rebuilds it in the nest
			end
		end
	end
	-- Gem Store items and decorations: rebuild only the models whose type or spot changed
	local folder = plot:FindFirstChild("LayoutItems")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "LayoutItems"
		folder.Parent = plot
	end
	local want = {}
	for id, it in pairs(layout.Items) do
		local show = Config.Blocks[it.T] or (Config.FarmItemSize[it.T] and profile and (profile.Items[it.T] or 0) > 0)
		if show then want[id] = string.format("%s|%d|%d|%d", it.T, it.X, it.Z, it.R) end
	end
	for _, m in ipairs(folder:GetChildren()) do
		local id = m:GetAttribute("LayoutId")
		if id and want[id] == m:GetAttribute("Sig") then want[id] = nil else m:Destroy() end
	end
	for id, sig in pairs(want) do
		local it = layout.Items[id]
		local m = Config.Blocks[it.T] and BuildModels.Block(it.T) or ItemModels.GemItem(it.T)
		if m then
			local cf = base * FarmGrid.toLocal(it.T, it.X, it.Z, it.R) * CFrame.new(0, top, 0)
			if Config.FarmItemSize[it.T] then cf = cf * CFrame.Angles(0, math.pi, 0) end -- Gem Store models face the gate
			if it.T == "Golden Watering Can" then
				-- the can hangs on a little post (05_Gem_Store_Items.md)
				m:PivotTo(cf * CFrame.new(0, 3.5, 0))
				local post = Instance.new("Part"); post.Name = "Post"; post.Anchored = true; post.Size = Vector3.new(0.6, 3.5, 0.6)
				post.Material = Enum.Material.Wood; post.Color = Color3.fromRGB(80, 52, 30); post.CFrame = cf * CFrame.new(0, 1.75, 0); post.Parent = m
			else
				m:PivotTo(cf)
			end
			m:SetAttribute("LayoutId", id)
			m:SetAttribute("Sig", sig)
			m.Parent = folder
		end
	end
end

local function renderPlot(player)
	local plot = playerPlot[player]
	local profile = DataService.Get(player)
	if not plot or not profile then return end
	for i = 1, Config.TilesPerPlot do renderTile(plot, i, profile.Tiles[tostring(i)]) end
	renderNest(plot, profile)
end

local function claimPlot(player)
	for _, plot in ipairs(PlotsFolder:GetChildren()) do
		if not plotOwner[plot] then
			plotOwner[plot] = player
			playerPlot[player] = plot
			plot.Sign.SignGui.Owner.Text = player.DisplayName .. "'s Farm"
			plot:SetAttribute("OwnerUserId", player.UserId)
			return plot
		end
	end
	return nil
end

local function releasePlot(player)
	local plot = playerPlot[player]
	if not plot then return end
	plotOwner[plot] = nil
	playerPlot[player] = nil
	plot.Sign.SignGui.Owner.Text = "Unclaimed Farm"
	plot:SetAttribute("OwnerUserId", nil)
	for i = 1, Config.TilesPerPlot do renderTile(plot, i, nil) end
	renderNest(plot, nil)
	applyLayout(plot, nil)
end

local function rollMutation(profile)
	if math.random() < Config.GoldenChance then return "Golden" end
	local b = getBonuses(profile)
	local best, bestMult = nil, 0
	for _, m in ipairs(b.PetMutations) do
		if math.random() < m.Chance and Config.Mutations[m.Name].Mult > bestMult then best, bestMult = m.Name, Config.Mutations[m.Name].Mult end
	end
	if not best and b.MutationChance > 0 and math.random() < b.MutationChance then
		local pool = {"Scorched", "Frozen", "Shocked"}
		best = pool[math.random(1, #pool)]
	end
	return best
end

local function onTile(player, plot, index)
	local tile = tilePart(plot, index)
	if not tile or not tile:GetAttribute("Placed") then return end
	if plotOwner[plot] ~= player then notify(player, "This isn't your farm!", "error") return end
	local profile = DataService.Get(player)
	if not profile then return end
	local key = tostring(index)
	local state = profile.Tiles[key]
	if not state then
		local seed = selectedSeed[player]
		if not seed or (profile.Seeds[seed] or 0) <= 0 then
			-- auto-pick the first owned seed
			seed = nil
			for _, name in ipairs(Config.CropOrder) do if (profile.Seeds[name] or 0) > 0 then seed = name break end end
			if not seed then notify(player, "You have no seeds. Buy some at the NPC Market!", "error") return end
			selectedSeed[player] = seed
		end
		local b = getBonuses(profile)
		local d = Config.Crops[seed]
		addCount(profile.Seeds, seed, -1)
		profile.Tiles[key] = {Crop = seed, PlantedAt = os.time(), Duration = math.max(1, math.floor(d.GrowTime / (1 + b.GrowSpeed)))}
		renderTile(plot, index, profile.Tiles[key])
		push(player)
		return
	end
	if os.time() - state.PlantedAt < state.Duration then
		notify(player, state.Crop .. " is still growing.", "info")
		return
	end
	-- harvest
	local d = Config.Crops[state.Crop]
	local mutation = rollMutation(profile)
	local b = getBonuses(profile)
	local gems = Config.Rarities[d.Rarity].HarvestGems * (mutation == "Golden" and 2 or 1)
	gems = math.max(1, math.floor(gems * (1 + b.GemBonus)))
	profile.Tiles[key] = nil
	addCount(profile.Crops, cropKey(state.Crop, mutation), 1)
	profile.Gems += gems
	profile.Stats.Harvests += 1
	renderTile(plot, index, nil)
	local label = (mutation and (mutation .. " ") or "") .. state.Crop
	notify(player, string.format("Harvested %s [%s]  +%d Gems", label, d.Rarity, gems), mutation and "rare" or "success")
	-- auto replant same seed if available
	if (profile.Seeds[state.Crop] or 0) > 0 and selectedSeed[player] == state.Crop then
		addCount(profile.Seeds, state.Crop, -1)
		profile.Tiles[key] = {Crop = state.Crop, PlantedAt = os.time(), Duration = math.max(1, math.floor(d.GrowTime / (1 + b.GrowSpeed)))}
		renderTile(plot, index, profile.Tiles[key])
	end
	push(player)
end

-- every plot gets Config.MaxSoil soil tiles; the layout decides which are on the farm
for _, plot in ipairs(PlotsFolder:GetChildren()) do
	local first = plot.Tiles:FindFirstChild("Tile1")
	for i = 1, Config.MaxSoil do
		local tile = plot.Tiles:FindFirstChild("Tile" .. i)
		if not tile and first then
			tile = first:Clone()
			for _, c in ipairs(tile:GetChildren()) do if c.Name == "Plant" then c:Destroy() end end
			tile.Name = "Tile" .. i
			tile:SetAttribute("TileIndex", i)
			tile.Parent = plot.Tiles
		end
		if tile then tile.Size = Vector3.new(7.6, tile.Size.Y, 7.6) end -- a small seam between neighbouring tiles
	end
	local base = plot.PrimaryPart.CFrame
	local nest, rim = plot:FindFirstChild("Nest"), plot:FindFirstChild("NestRim")
	if nest and rim then
		local n, r = base:ToObjectSpace(nest.CFrame), base:ToObjectSpace(rim.CFrame)
		nestRest[plot] = {NestY = n.Y, NestRot = n.Rotation, RimY = r.Y, RimRot = r.Rotation}
	end
	applyLayout(plot, nil)
end

for _, plot in ipairs(PlotsFolder:GetChildren()) do
	for _, tile in ipairs(plot.Tiles:GetChildren()) do
		local prompt = tile:FindFirstChild("TilePrompt")
		local index = tile:GetAttribute("TileIndex")
		if prompt and index then
			prompt.Triggered:Connect(function(player)
				if busy[player] then return end
				busy[player] = true
				local ok, err = pcall(onTile, player, plot, index)
				busy[player] = nil
				if not ok then warn(err) end
			end)
		end
	end
end

------------------------------------------------------------------ breeding
local function breedResult(nameA, nameB)
	for _, r in ipairs(Config.Recipes) do
		if (r.A == nameA and r.B == nameB) or (r.A == nameB and r.B == nameA) then return r.Result, true end
	end
	local top = math.max(rarityTier(Config.Pets[nameA].Rarity), rarityTier(Config.Pets[nameB].Rarity))
	if math.random() < Config.BreedUpgradeChance and top < 6 then
		local list = speciesOfTier(Config.RarityOrder[top + 1], false)
		if #list > 0 then return list[math.random(1, #list)], false end
	end
	return (math.random() < 0.5) and nameA or nameB, false
end

------------------------------------------------------------------ trading
local trades = {}          -- [tradeId] = trade
local playerTrade = {}     -- [player] = tradeId
local pendingRequest = {}  -- [target] = requester

local function emptyOffer() return {Ru = 0, Crops = {}, Seeds = {}, Eggs = {}, Pets = {}} end

local function describeOffer(profile, offer)
	local pets = {}
	for _, id in ipairs(offer.Pets) do
		local p = profile.Pets[id]
		if p then table.insert(pets, {Id = id, Name = p.Name, Rarity = Config.Pets[p.Name].Rarity}) end
	end
	return {Ru = offer.Ru, Crops = offer.Crops, Seeds = offer.Seeds, Eggs = offer.Eggs, Pets = pets}
end

local function sendTrade(trade)
	for _, pl in ipairs({trade.A, trade.B}) do
		local other = pl == trade.A and trade.B or trade.A
		TradeUpdate:FireClient(pl, {
			Type = "State", Id = trade.Id, Stage = trade.Stage, Partner = other.DisplayName,
			Mine = describeOffer(DataService.Get(pl), trade.Offers[pl]),
			Theirs = describeOffer(DataService.Get(other), trade.Offers[other]),
			MyAccept = trade.Accepted[pl] == true, TheirAccept = trade.Accepted[other] == true,
			MyConfirm = trade.Confirmed[pl] == true, TheirConfirm = trade.Confirmed[other] == true,
		})
	end
end

local function endTrade(tradeId, reason)
	local trade = trades[tradeId]
	if not trade then return end
	trades[tradeId] = nil
	for _, pl in ipairs({trade.A, trade.B}) do
		playerTrade[pl] = nil
		if pl.Parent then TradeUpdate:FireClient(pl, {Type = "Closed", Reason = reason}) end
	end
end

-- Validate an offer against a profile; returns sanitized offer or nil, error
local function validateOffer(profile, offer)
	if type(offer) ~= "table" then return nil, "Bad offer" end
	local clean = emptyOffer()
	local ru = tonumber(offer.Ru) or 0
	ru = math.floor(ru)
	if ru < 0 or ru > profile.Ru then return nil, "Not enough Ru" end
	clean.Ru = ru
	for _, cat in ipairs({"Crops", "Seeds", "Eggs"}) do
		if type(offer[cat]) == "table" then
			for key, n in pairs(offer[cat]) do
				n = math.floor(tonumber(n) or 0)
				if type(key) ~= "string" or n < 0 then return nil, "Bad item" end
				if n > 0 then
					if (profile[cat][key] or 0) < n then return nil, "You don't have enough " .. key end
					clean[cat][key] = n
				end
			end
		end
	end
	if type(offer.Pets) == "table" then
		local seen = {}
		for _, id in ipairs(offer.Pets) do
			if type(id) ~= "string" or seen[id] then return nil, "Bad pet" end
			seen[id] = true
			if not profile.Pets[id] then return nil, "Pet not found" end
			if petLocked(profile, id) then return nil, "That pet is in the Breeding Nest" end
			table.insert(clean.Pets, id)
		end
	end
	return clean
end

local function executeTrade(trade)
	local pa, pb = DataService.Get(trade.A), DataService.Get(trade.B)
	if not pa or not pb then return false, "Player left" end
	local oa, ea = validateOffer(pa, trade.Offers[trade.A])
	local ob, eb = validateOffer(pb, trade.Offers[trade.B])
	if not oa then return false, trade.A.DisplayName .. ": " .. ea end
	if not ob then return false, trade.B.DisplayName .. ": " .. eb end
	local function move(from, to, offer)
		from.Ru -= offer.Ru; to.Ru += offer.Ru
		for _, cat in ipairs({"Crops", "Seeds", "Eggs"}) do
			for key, n in pairs(offer[cat]) do addCount(from[cat], key, -n); addCount(to[cat], key, n) end
		end
		for _, id in ipairs(offer.Pets) do
			local pet = from.Pets[id]
			from.Pets[id] = nil
			pet.Equipped = false
			to.Pets[id] = pet
		end
	end
	move(pa, pb, oa)
	move(pb, pa, ob)
	pa.Stats.Trades += 1; pb.Stats.Trades += 1
	local stamp = os.time()
	table.insert(pa.TradeLog, {With = trade.B.Name, At = stamp})
	table.insert(pb.TradeLog, {With = trade.A.Name, At = stamp})
	while #pa.TradeLog > 50 do table.remove(pa.TradeLog, 1) end
	while #pb.TradeLog > 50 do table.remove(pb.TradeLog, 1) end
	return true
end

------------------------------------------------------------------ held items & drops
-- The item in a player's hand is a Tool (so the arm holds it out) built from the item models; everyone sees it.
-- Dropped items lie on the ground and anyone can pick them up, but for the first few seconds only the dropper can.
-- A drop nobody takes goes back to its owner after DROP_LIFETIME, when the owner leaves, or on shutdown.
local DropsFolder = workspace:FindFirstChild("Drops") or Instance.new("Folder")
DropsFolder.Name = "Drops"; DropsFolder.Parent = workspace

local ITEM_TABLE = {Seed = "Seeds", Crop = "Crops", Egg = "Eggs"} -- profile table per item kind (pets are by id)
local HOLD_SIZE = {Seed = 1.1, Crop = 1.4, Egg = 1.3, Pet = 2.0}   -- longest side in the hand, studs
local DROP_SIZE = {Seed = 1.5, Crop = 1.8, Egg = 1.8, Pet = 2.6}   -- longest side on the ground
local HOLD_GRIP = CFrame.new()
local DROP_OWNER_ONLY = 5      -- seconds before other players may pick a drop up
local DROP_LIFETIME = 300      -- seconds before an untouched drop goes back to its owner
local MAX_DROPS_PER_PLAYER = 25
local MAX_DROPS = 200

local drops = {}      -- [dropId] = {Kind, Key, Qty, Pet, OwnerId, At, Model}
local dropCount = {}  -- [userId] = drops on the ground

local function owns(profile, kind, key)
	if type(key) ~= "string" then return false end
	if kind == "Pet" then return profile.Pets[key] ~= nil end
	local tbl = ITEM_TABLE[kind]
	return tbl ~= nil and (profile[tbl][key] or 0) > 0
end

-- display name and colour of an item
local function itemInfo(kind, key, pet)
	if kind == "Seed" then
		local d = Config.Crops[key]
		return key .. " seed", d and Config.RarityColor(d.Rarity)
	elseif kind == "Crop" then
		local name, mut = splitKey(key)
		local d = Config.Crops[name]
		return (mut and (mut .. " ") or "") .. name, d and Config.RarityColor(d.Rarity)
	elseif kind == "Egg" then
		local d = Config.Eggs[key]
		return key, d and d.Color
	end
	local d = pet and Config.Pets[pet.Name]
	return pet and pet.Name or "Pet", d and Config.RarityColor(d.Rarity)
end

local function itemModel(kind, key, pet)
	if kind == "Seed" then return CropModels.Pouch(key) end
	if kind == "Crop" then
		local name, mut = splitKey(key)
		return CropModels.Harvested(name, mut)
	end
	if kind == "Egg" then return ItemModels.Egg(key) end
	if kind == "Pet" and pet then return PetModels.Build(pet.Name, true) end
	return nil
end

-- uniform scale of a finished model about its Root so its longest side is `size` (like ModelKit:fitMax)
local function fitModel(model, size)
	local root = model.PrimaryPart
	local _, extents = model:GetBoundingBox()
	local longest = math.max(extents.X, extents.Y, extents.Z)
	if longest <= 0 then return end
	local f = math.clamp(size / longest, 0.25, 3)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= root then
			local rel = root.CFrame:ToObjectSpace(d.CFrame)
			d.Size *= f
			d.CFrame = root.CFrame * CFrame.new(rel.Position * f) * rel.Rotation
		elseif d:IsA("Attachment") then
			d.Position *= f
		elseif d:IsA("PointLight") then
			d.Range = math.min(d.Range * math.max(f, 0.6), 60)
		end
	end
end

local function clearHeldTool(player)
	local char = player.Character
	local tool = char and char:FindFirstChild("HeldItem")
	if tool then tool:Destroy() end
end

local function attachHeld(player)
	clearHeldTool(player)
	local h = held[player]
	local profile = DataService.Get(player)
	local char = player.Character
	if not h or not profile or not char or not char:FindFirstChildOfClass("Humanoid") then return end
	local pet = h.Kind == "Pet" and profile.Pets[h.Key] or nil
	local model = itemModel(h.Kind, h.Key, pet)
	if not model then return end
	fitModel(model, HOLD_SIZE[h.Kind])
	local tool = Instance.new("Tool")
	tool.Name = "HeldItem"
	tool.CanBeDropped = false
	tool.ManualActivationOnly = true
	tool.ToolTip = (itemInfo(h.Kind, h.Key, pet))
	tool.Grip = HOLD_GRIP
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.2, 0.2, 0.2)
	handle.Transparency = 1
	handle.CanCollide = false; handle.CanQuery = false; handle.CanTouch = false; handle.Massless = true
	handle.CFrame = CFrame.new()
	handle.Parent = tool
	-- centre the item on the handle, then weld everything to it
	local box = model:GetBoundingBox()
	model:PivotTo(CFrame.new(-model.PrimaryPart.CFrame:PointToObjectSpace(box.Position)))
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true
			local w = Instance.new("WeldConstraint"); w.Part0 = handle; w.Part1 = p; w.Parent = p
		end
	end
	model.Parent = tool
	tool.Parent = char
end

validateHeld = function(player)
	local h = held[player]
	if not h then return end
	local profile = DataService.Get(player)
	local ok = profile ~= nil and owns(profile, h.Kind, h.Key)
	if ok and h.Kind == "Pet" then
		ok = not profile.Pets[h.Key].Equipped and not petLocked(profile, h.Key)
	end
	if not ok then
		held[player] = nil
		clearHeldTool(player)
	end
end

local function takeDrop(id)
	local d = drops[id]
	if not d then return nil end
	drops[id] = nil
	dropCount[d.OwnerId] = math.max(0, (dropCount[d.OwnerId] or 1) - 1)
	if d.Model then d.Model:Destroy() end
	return d
end

local function giveItem(profile, d)
	if d.Kind == "Pet" then
		local id = d.Key
		if profile.Pets[id] then id = HttpService:GenerateGUID(false) end
		d.Pet.Equipped = false
		profile.Pets[id] = d.Pet
	else
		addCount(profile[ITEM_TABLE[d.Kind]], d.Key, d.Qty)
	end
end

local function pickUp(player, id)
	local d = drops[id]
	local profile = DataService.Get(player)
	if not d or not profile then return end
	if d.OwnerId ~= player.UserId and os.clock() - d.At < DROP_OWNER_ONLY then
		notify(player, "That was just dropped - give it a few seconds", "info")
		return
	end
	takeDrop(id)
	giveItem(profile, d)
	notify(player, string.format("Picked up %s%s", d.Qty > 1 and (d.Qty .. "x ") or "", (itemInfo(d.Kind, d.Key, d.Pet))), "success")
	push(player)
end

local dropRay = RaycastParams.new()
dropRay.FilterType = Enum.RaycastFilterType.Exclude

local function spawnDrop(player, kind, key, qty, pet)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local model = itemModel(kind, key, pet)
	if not model then return nil end
	fitModel(model, DROP_SIZE[kind])
	-- a few studs in front of the player, away from other drops so labels don't stack, resting on the ground
	local spot, bestGap = nil, -1
	for _ = 1, 10 do
		local try = hrp.CFrame * CFrame.new((math.random() - 0.5) * 6, 0, -3 - math.random() * 3)
		local gap = math.huge
		for _, d in pairs(drops) do
			if d.Model and d.Model.PrimaryPart then
				local a, b = d.Model.PrimaryPart.Position, try.Position
				gap = math.min(gap, Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude)
			end
		end
		if gap > bestGap then spot, bestGap = try, gap end
		if gap >= 2 then break end
	end
	dropRay.FilterDescendantsInstances = {DropsFolder, PetsFolder, char}
	local hit = workspace:Raycast(spot.Position + Vector3.new(0, 2, 0), Vector3.new(0, -20, 0), dropRay)
	local ground = hit and hit.Position or (spot.Position - Vector3.new(0, 3, 0))
	local box, size = model:GetBoundingBox()
	local lift = model.PrimaryPart.Position.Y - (box.Position.Y - size.Y / 2)
	model:PivotTo(CFrame.new(ground + Vector3.new(0, lift, 0)) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	local id = HttpService:GenerateGUID(false)
	model.Name = "Drop"
	model:SetAttribute("DropId", id)
	local name, color = itemInfo(kind, key, pet)
	local text = (qty > 1 and (qty .. "x ") or "") .. name
	local root = model.PrimaryPart
	local bb = Instance.new("BillboardGui"); bb.Size = UDim2.fromOffset(160, 30); bb.StudsOffset = Vector3.new(0, size.Y + 1, 0); bb.MaxDistance = 40; bb.Parent = root
	local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1, 1); t.Font = Enum.Font.FredokaOne; t.TextScaled = true
	t.TextColor3 = color or Color3.new(1, 1, 1); t.TextStrokeTransparency = 0.2; t.Text = text; t.Parent = bb
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DropPrompt"; prompt.ActionText = "Pick up"; prompt.ObjectText = text
	prompt.KeyboardKeyCode = Enum.KeyCode.F; prompt.HoldDuration = 0.2; prompt.MaxActivationDistance = 8; prompt.RequiresLineOfSight = false
	prompt.Parent = root
	prompt.Triggered:Connect(function(p)
		if busy[p] then return end
		busy[p] = true
		local ok, err = pcall(pickUp, p, id)
		busy[p] = nil
		if not ok then warn(err) end
	end)
	model.Parent = DropsFolder
	drops[id] = {Kind = kind, Key = key, Qty = qty, Pet = pet, OwnerId = player.UserId, At = os.clock(), Model = model}
	dropCount[player.UserId] = (dropCount[player.UserId] or 0) + 1
	task.delay(DROP_LIFETIME, function()
		local d = drops[id]
		local owner = d and Players:GetPlayerByUserId(d.OwnerId)
		local profile = owner and DataService.Get(owner)
		if not profile then return end
		takeDrop(id)
		giveItem(profile, d)
		notify(owner, "Nobody picked up your " .. name .. ", so it went back to your inventory", "info")
		push(owner)
	end)
	return id
end

------------------------------------------------------------------ request handlers
local Handlers = {}

function Handlers.SelectSeed(player, profile, name)
	if type(name) ~= "string" or not Config.Crops[name] then return false, "Unknown seed" end
	selectedSeed[player] = name
	-- picking a seed also puts its pouch in your hand
	if (profile.Seeds[name] or 0) > 0 then
		held[player] = {Kind = "Seed", Key = name}
		attachHeld(player)
	end
	return true
end

-- kind = "Seed" | "Crop" | "Egg" | "Pet" (key = pet id), or nil to put the item away
function Handlers.HoldItem(player, profile, kind, key)
	if kind == nil then
		held[player] = nil
		clearHeldTool(player)
		return true
	end
	if kind ~= "Pet" and not ITEM_TABLE[kind] then return false, "You can't hold that" end
	if not owns(profile, kind, key) then return false, "You don't have that" end
	if kind == "Pet" then
		if profile.Pets[key].Equipped then return false, "Unequip that pet to hold it" end
		if petLocked(profile, key) then return false, "That pet is in the Breeding Nest" end
	end
	held[player] = {Kind = kind, Key = key}
	if kind == "Seed" then selectedSeed[player] = key end
	attachHeld(player)
	return true
end

function Handlers.DropItem(player, profile, kind, key, qty)
	if playerTrade[player] then return false, "Finish your trade first" end
	if kind ~= "Pet" and not ITEM_TABLE[kind] then return false, "You can't drop that" end
	if not owns(profile, kind, key) then return false, "You don't have that" end
	if (dropCount[player.UserId] or 0) >= MAX_DROPS_PER_PLAYER then return false, "You have too many items on the ground - pick some up first" end
	local total = 0
	for _ in pairs(drops) do total += 1 end
	if total >= MAX_DROPS then return false, "Too many items on the ground in this server" end
	local pet = nil
	if kind == "Pet" then
		if petLocked(profile, key) then return false, "That pet is in the Breeding Nest" end
		pet = profile.Pets[key]
		qty = 1
	else
		qty = math.clamp(math.floor(tonumber(qty) or 1), 1, profile[ITEM_TABLE[kind]][key])
	end
	-- build the drop before taking the item, so a failure never eats it
	if not spawnDrop(player, kind, key, qty, pet) then return false, "You can't drop that here" end
	if kind == "Pet" then
		profile.Pets[key] = nil
		if pet.Equipped then pet.Equipped = false; refreshPets(player) end
	else
		addCount(profile[ITEM_TABLE[kind]], key, -qty)
	end
	return true, string.format("Dropped %s%s", qty > 1 and (qty .. "x ") or "", (itemInfo(kind, key, pet)))
end

function Handlers.BuySeed(player, profile, name, qty)
	local d = Config.Crops[name]
	qty = math.clamp(math.floor(tonumber(qty) or 1), 1, 100)
	if not d then return false, "Unknown seed" end
	local shop = d.Currency == "Ru" and Village.Market or Village.GemStore
	if not nearModel(player, shop, 25) then return false, "Walk to the shop first" end
	local cost = d.Price * qty
	if profile[d.Currency] < cost then return false, "Not enough " .. d.Currency end
	profile[d.Currency] -= cost
	addCount(profile.Seeds, name, qty)
	if not selectedSeed[player] then selectedSeed[player] = name end
	return true, string.format("Bought %d %s seed%s", qty, name, qty > 1 and "s" or "")
end

function Handlers.BuyEgg(player, profile, name)
	local d = Config.Eggs[name]
	if not d then return false, "Unknown egg" end
	local shop = d.Currency == "Ru" and Village.Market or Village.GemStore
	if not nearModel(player, shop, 25) then return false, "Walk to the shop first" end
	if profile[d.Currency] < d.Price then return false, "Not enough " .. d.Currency end
	profile[d.Currency] -= d.Price
	addCount(profile.Eggs, name, 1)
	return true, "Bought a " .. name .. "! Hatch it from your Inventory."
end

function Handlers.BuyItem(player, profile, name)
	local d = Config.GemItems[name]
	if not d then return false, "Unknown item" end
	if not nearModel(player, Village.GemStore, 25) then return false, "Walk to the Gem Store first" end
	if d.Type ~= "Upgrade" and (profile.Items[name] or 0) > 0 then return false, "You already own this" end
	if name == "Extra Pet Slot" and profile.PetSlots >= Config.MaxPetSlots then return false, "Max pet slots reached" end
	if profile.Gems < d.Price then return false, "Not enough Gems" end
	profile.Gems -= d.Price
	if name == "Extra Pet Slot" then
		profile.PetSlots += 1
	else
		addCount(profile.Items, name, 1)
	end
	autoPlaceFarmItems(profile)
	if playerPlot[player] then applyLayout(playerPlot[player], profile) end
	return true, "Bought " .. name .. "!"
end

function Handlers.SellCrop(player, profile, key, qty)
	if not nearModel(player, Village.Market, 25) then return false, "Walk to the NPC Market first" end
	if type(key) ~= "string" or not profile.Crops[key] then return false, "You don't have that" end
	qty = math.clamp(math.floor(tonumber(qty) or 1), 1, profile.Crops[key])
	local name, mut = splitKey(key)
	local value = cropValue(name, mut, getBonuses(profile).SellBonus) * qty
	addCount(profile.Crops, key, -qty)
	profile.Ru += value
	return true, string.format("Sold %dx %s for %s Ru", qty, key:gsub("|", " "), Config.FormatNumber(value))
end

function Handlers.SellAllCrops(player, profile)
	if not nearModel(player, Village.Market, 25) then return false, "Walk to the NPC Market first" end
	local bonus = getBonuses(profile).SellBonus
	local total, count = 0, 0
	for key, n in pairs(profile.Crops) do
		local name, mut = splitKey(key)
		total += cropValue(name, mut, bonus) * n
		count += n
	end
	if count == 0 then return false, "No crops to sell" end
	profile.Crops = {}
	profile.Ru += total
	return true, string.format("Sold %d crops for %s Ru", count, Config.FormatNumber(total))
end

function Handlers.SellPet(player, profile, id)
	if not nearModel(player, Village.Market, 25) then return false, "Walk to the NPC Market first" end
	local pet = type(id) == "string" and profile.Pets[id]
	if not pet then return false, "Pet not found" end
	if petLocked(profile, id) then return false, "That pet is in the Breeding Nest" end
	if playerTrade[player] then return false, "Finish your trade first" end
	local price = Config.Rarities[Config.Pets[pet.Name].Rarity].PetSell
	profile.Pets[id] = nil
	profile.Ru += price
	if pet.Equipped then refreshPets(player) end
	return true, string.format("Sold %s for %s Ru", pet.Name, Config.FormatNumber(price))
end

function Handlers.HatchEgg(player, profile, name)
	if type(name) ~= "string" or (profile.Eggs[name] or 0) <= 0 then return false, "You don't have that egg" end
	if playerTrade[player] then return false, "Finish your trade first" end
	addCount(profile.Eggs, name, -1)
	local petName = rollEgg(name)
	newPet(profile, petName)
	local rarity = Config.Pets[petName].Rarity
	return true, string.format("You hatched: %s [%s]!", petName, rarity), {Pet = petName, Rarity = rarity, Egg = name}
end

function Handlers.EquipPet(player, profile, id, on)
	local pet = type(id) == "string" and profile.Pets[id]
	if not pet then return false, "Pet not found" end
	if on and not pet.Equipped then
		if equippedCount(profile) >= profile.PetSlots then return false, "All pet slots are full" end
		if petLocked(profile, id) then return false, "That pet is in the Breeding Nest" end
	end
	pet.Equipped = on and true or false
	refreshPets(player)
	return true
end

function Handlers.StartBreed(player, profile, idA, idB)
	if profile.Breeding then return false, "Your nest is already busy" end
	if idA == idB then return false, "Pick two different pets" end
	local a = type(idA) == "string" and profile.Pets[idA]
	local b = type(idB) == "string" and profile.Pets[idB]
	if not a or not b then return false, "Pick two pets" end
	if playerTrade[player] then return false, "Finish your trade first" end
	local top = math.max(rarityTier(Config.Pets[a.Name].Rarity), rarityTier(Config.Pets[b.Name].Rarity))
	local tierData = Config.Rarities[Config.RarityOrder[top]]
	if profile.Ru < tierData.BreedFee then return false, "Breeding costs " .. Config.FormatNumber(tierData.BreedFee) .. " Ru" end
	profile.Ru -= tierData.BreedFee
	local result, isRecipe = breedResult(a.Name, b.Name)
	if a.Equipped or b.Equipped then a.Equipped = false; b.Equipped = false; refreshPets(player) end
	profile.Breeding = {A = idA, B = idB, EndsAt = os.time() + tierData.BreedTime, Result = result, Recipe = isRecipe}
	if playerPlot[player] then renderNest(playerPlot[player], profile) end
	return true, isRecipe and "Secret recipe! Something special is growing in your nest..." or "Breeding started!"
end

function Handlers.CollectBreed(player, profile)
	local br = profile.Breeding
	if not br then return false, "Nothing in your nest" end
	if os.time() < br.EndsAt then return false, "Not ready yet" end
	local d = Config.Pets[br.Result]
	local gems = Config.Rarities[d.Rarity].BreedGems
	gems = math.floor(gems * (1 + getBonuses(profile).GemBonus))
	newPet(profile, br.Result)
	profile.Gems += gems
	profile.Stats.Bred += 1
	profile.Breeding = nil
	if playerPlot[player] then renderNest(playerPlot[player], profile) end
	return true, string.format("Your nest hatched: %s [%s]!  +%d Gems", br.Result, d.Rarity, gems), {Pet = br.Result, Rarity = d.Rarity, Egg = "Nest", Secret = br.Recipe == true}
end

function Handlers.CancelBreed(player, profile)
	if not profile.Breeding then return false, "Nothing in your nest" end
	profile.Breeding = nil
	if playerPlot[player] then renderNest(playerPlot[player], profile) end
	return true, "Breeding cancelled (fee not refunded)"
end

-- trading handlers
function Handlers.TradeRequest(player, profile, targetUserId)
	local target = Players:GetPlayerByUserId(tonumber(targetUserId) or 0)
	if not target or target == player then return false, "Player not found" end
	if playerTrade[player] or playerTrade[target] then return false, "Someone is already trading" end
	pendingRequest[target] = player
	TradeUpdate:FireClient(target, {Type = "Request", From = player.DisplayName, FromUserId = player.UserId})
	return true, "Trade request sent to " .. target.DisplayName
end

function Handlers.TradeRespond(player, profile, fromUserId, accept)
	local from = Players:GetPlayerByUserId(tonumber(fromUserId) or 0)
	if not from or pendingRequest[player] ~= from then return false, "Request expired" end
	pendingRequest[player] = nil
	if not accept then notify(from, player.DisplayName .. " declined your trade.", "error") return true end
	if playerTrade[player] or playerTrade[from] then return false, "Someone is already trading" end
	local id = HttpService:GenerateGUID(false)
	local trade = {Id = id, A = from, B = player, Stage = "Offer", Offers = {[from] = emptyOffer(), [player] = emptyOffer()}, Accepted = {}, Confirmed = {}}
	trades[id] = trade
	playerTrade[from] = id; playerTrade[player] = id
	sendTrade(trade)
	return true
end

function Handlers.TradeSetOffer(player, profile, offer)
	local trade = trades[playerTrade[player] or ""]
	if not trade then return false, "No active trade" end
	local clean, err = validateOffer(profile, offer)
	if not clean then return false, err end
	trade.Offers[player] = clean
	trade.Accepted = {}; trade.Confirmed = {}; trade.Stage = "Offer"
	sendTrade(trade)
	return true
end

function Handlers.TradeAccept(player, profile)
	local trade = trades[playerTrade[player] or ""]
	if not trade then return false, "No active trade" end
	trade.Accepted[player] = true
	if trade.Accepted[trade.A] and trade.Accepted[trade.B] then trade.Stage = "Confirm" end
	sendTrade(trade)
	return true
end

function Handlers.TradeConfirm(player, profile)
	local trade = trades[playerTrade[player] or ""]
	if not trade or trade.Stage ~= "Confirm" then return false, "Both players must accept first" end
	trade.Confirmed[player] = true
	if trade.Confirmed[trade.A] and trade.Confirmed[trade.B] then
		local ok, err = executeTrade(trade)
		local a, b = trade.A, trade.B
		endTrade(trade.Id, ok and "Trade complete!" or ("Trade failed: " .. tostring(err)))
		for _, pl in ipairs({a, b}) do push(pl); refreshPets(pl) end
		return true
	end
	sendTrade(trade)
	return true
end

function Handlers.TradeCancel(player, profile)
	local id = playerTrade[player]
	if id then endTrade(id, player.DisplayName .. " cancelled the trade.") end
	return true
end

-- Build Mode (BuildMode client script). Every change is checked here against FarmGrid's rules.
local function layoutCount(profile, t)
	local n = 0
	for _, it in pairs(profile.Layout.Items) do if it.T == t then n += 1 end end
	return n
end

local function validSpot(x, z, r)
	for _, v in ipairs({x, z, r}) do
		if type(v) ~= "number" or v ~= math.floor(v) then return false end
	end
	return r >= 0 and r <= 3
end

function Handlers.BuildSync(player, profile)
	return true -- the Request wrapper pushes a fresh snapshot
end

function Handlers.BuildPlace(player, profile, t, x, z, r)
	local plot = playerPlot[player]
	if not plot then return false, "You don't have a farm" end
	if type(t) ~= "string" or t == "Nest" or not FarmGrid.size(t) then return false, "You can't place that" end
	if not validSpot(x, z, r) then return false, "Bad spot" end
	local total = 0
	for _ in pairs(profile.Layout.Items) do total += 1 end
	if total >= Config.MaxLayoutItems then return false, "Your farm can't hold any more things" end
	local index = nil
	if t == "Soil" then
		local used = {}
		for _, it in pairs(profile.Layout.Items) do if it.T == "Soil" then used[it.I] = true end end
		for i = 1, profile.SoilSlots do if not used[i] then index = i break end end
		if not index then return false, "All your soil is placed - buy more in the Shop tab" end
	elseif Config.FarmItemSize[t] then
		if (profile.Items[t] or 0) <= 0 then return false, "You don't own that" end
		if layoutCount(profile, t) > 0 then return false, "That's already on your farm" end
	elseif (profile.Blocks[t] or 0) - layoutCount(profile, t) <= 0 then
		return false, "You have none left - buy more in the Shop tab"
	end
	local ok, why = FarmGrid.fits(profile.Layout.Items, t, x, z, r)
	if not ok then return false, why end
	profile.Layout.Items[tostring(profile.Layout.Next)] = {T = t, X = x, Z = z, R = r, I = index}
	profile.Layout.Next += 1
	applyLayout(plot, profile)
	return true
end

function Handlers.BuildMove(player, profile, id, x, z, r)
	local plot = playerPlot[player]
	local it = type(id) == "string" and profile.Layout.Items[id]
	if not plot or not it then return false, "There's nothing to move" end
	if not validSpot(x, z, r) then return false, "Bad spot" end
	if it.T == "Nest" then r = 0 end
	local ok, why = FarmGrid.fits(profile.Layout.Items, it.T, x, z, r, id)
	if not ok then return false, why end
	it.X, it.Z, it.R = x, z, r
	applyLayout(plot, profile)
	return true
end

function Handlers.BuildRemove(player, profile, id)
	local plot = playerPlot[player]
	local it = type(id) == "string" and profile.Layout.Items[id]
	if not plot or not it then return false, "There's nothing there" end
	if it.T == "Nest" then return false, "The nest can be moved but not removed" end
	if it.T == "Soil" and profile.Tiles[tostring(it.I)] then return false, "Harvest that soil before picking it up" end
	profile.Layout.Items[id] = nil
	applyLayout(plot, profile)
	return true
end

function Handlers.BuySoil(player, profile)
	if profile.SoilSlots >= Config.MaxSoil then return false, "Your farm already has the most soil it can hold" end
	local price = Config.SoilPrice(profile.SoilSlots)
	if profile.Ru < price then return false, "Not enough Ru" end
	profile.Ru -= price
	profile.SoilSlots += 1
	return true, string.format("Bought soil #%d - place it from the Place tab", profile.SoilSlots)
end

function Handlers.BuyBlock(player, profile, name, qty)
	local b = type(name) == "string" and Config.Blocks[name]
	if not b then return false, "Unknown decoration" end
	qty = math.clamp(math.floor(tonumber(qty) or 1), 1, 50)
	local cost = b.Price * qty
	if profile.Ru < cost then return false, "Not enough Ru" end
	profile.Ru -= cost
	addCount(profile.Blocks, name, qty)
	return true, string.format("Bought %dx %s", qty, name)
end

-- Studio-only testing helper (never works in live servers)
if game:GetService("RunService"):IsStudio() then
	function Handlers.DevGrant(player, profile)
		profile.Ru += 100000
		profile.Gems += 10000
		return true, "[Studio] +100,000 Ru and +10,000 Gems"
	end
	function Handlers.DevTile(player, profile, index)
		local plot = playerPlot[player]
		if plot then onTile(player, plot, index) end
		return true
	end
	function Handlers.DevFinishTimers(player, profile)
		for _, t in pairs(profile.Tiles) do t.PlantedAt -= 100000 end
		if profile.Breeding then profile.Breeding.EndsAt = os.time() end
		return true
	end
	-- one of everything, to check content: seeds, crops (plain + every mutation), eggs, one pet per species
	-- not yet owned, every Gem Store item, max pet slots, and a ripe plant of each crop on the empty tiles
	function Handlers.DevGrantAll(player, profile)
		profile.Ru += 1000000
		profile.Gems += 100000
		for _, name in ipairs(Config.CropOrder) do
			addCount(profile.Seeds, name, 10)
			addCount(profile.Crops, name, 5)
			for mutation in pairs(Config.Mutations) do addCount(profile.Crops, cropKey(name, mutation), 1) end
		end
		for _, name in ipairs(Config.EggOrder) do addCount(profile.Eggs, name, 3) end
		local owned = {}
		for _, pet in pairs(profile.Pets) do owned[pet.Name] = true end
		local species = {}
		for name in pairs(Config.Pets) do if not owned[name] then table.insert(species, name) end end
		table.sort(species)
		for _, name in ipairs(species) do newPet(profile, name) end
		for name, d in pairs(Config.GemItems) do
			if d.Type ~= "Upgrade" and (profile.Items[name] or 0) == 0 then addCount(profile.Items, name, 1) end
		end
		profile.PetSlots = Config.MaxPetSlots
		profile.SoilSlots = Config.MaxSoil
		for name in pairs(Config.Blocks) do addCount(profile.Blocks, name, 5) end
		autoPlaceFarmItems(profile)
		local plot = playerPlot[player]
		if plot then
			-- a ripe plant of each crop on the empty placed soil, in tile order
			local free = {}
			for _, it in pairs(profile.Layout.Items) do
				if it.T == "Soil" and not profile.Tiles[tostring(it.I)] then table.insert(free, it.I) end
			end
			table.sort(free)
			for n, name in ipairs(Config.CropOrder) do
				local i = free[n]
				if not i then break end
				profile.Tiles[tostring(i)] = {Crop = name, PlantedAt = os.time() - 100000, Duration = Config.Crops[name].GrowTime}
			end
			applyLayout(plot, profile)
			renderPlot(player)
		end
		return true, "[Studio] Added every seed, crop, mutation, egg, pet and Gem Store item, max soil and 5 of each decoration"
	end
end

Request.OnServerInvoke = function(player, action, ...)
	local profile = DataService.Get(player)
	local handler = type(action) == "string" and Handlers[action]
	if not profile or not handler then return {Ok = false, Msg = "Not ready"} end
	if busy[player] then return {Ok = false, Msg = "Slow down!"} end
	busy[player] = true
	local ok, success, msg, extra = pcall(handler, player, profile, ...)
	busy[player] = nil
	if not ok then
		warn("[GameServer]", action, success)
		return {Ok = false, Msg = "Something went wrong"}
	end
	push(player)
	return {Ok = success, Msg = msg, Extra = extra}
end

------------------------------------------------------------------ player lifecycle
local function onCharacter(player, char)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	local plot = playerPlot[player]
	if hrp and plot then
		task.wait(0.1)
		char:PivotTo(plot.PlotSpawn.CFrame * CFrame.new(0, 2, 0))
	end
	task.wait(0.5)
	refreshPets(player)
	attachHeld(player)
end

Players.PlayerAdded:Connect(function(player)
	local ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = player
	local ru = Instance.new("IntValue"); ru.Name = "Ru"; ru.Parent = ls
	local gems = Instance.new("IntValue"); gems.Name = "Gems"; gems.Parent = ls
	local profile = DataService.Load(player)
	if not player.Parent then DataService.Release(player) return end
	ensureLayout(profile)
	local plot = claimPlot(player)
	if plot then
		applyLayout(plot, profile)
		renderPlot(player)
	else
		notify(player, "Server is full of farms, sorry!", "error")
	end
	player.CharacterAdded:Connect(function(char) onCharacter(player, char) end)
	if player.Character then task.spawn(onCharacter, player, player.Character) end
	push(player)
	notify(player, "Welcome to Dragon Isle Farm! Plant your Carrot seeds on your farm.", "success")
	if DataService.LoadFailed(player) then
		notify(player, "We couldn't load your save. Progress this session won't be saved - please rejoin.", "error")
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local id = playerTrade[player]
	if id then endTrade(id, player.DisplayName .. " left the game.") end
	pendingRequest[player] = nil
	for target, from in pairs(pendingRequest) do if from == player then pendingRequest[target] = nil end end
	local f = PetsFolder:FindFirstChild(player.Name)
	if f then f:Destroy() end
	-- this player's drops that nobody took go back into their save
	local profile = DataService.Get(player)
	for id, d in pairs(drops) do
		if d.OwnerId == player.UserId then
			takeDrop(id)
			if profile then giveItem(profile, d) end
		end
	end
	held[player] = nil
	releasePlot(player)
	selectedSeed[player] = nil
	busy[player] = nil
	DataService.Release(player)
end)

game:BindToClose(function()
	-- drops still on the ground go back to their owners before the final save
	for id, d in pairs(drops) do
		local owner = Players:GetPlayerByUserId(d.OwnerId)
		local profile = owner and DataService.Get(owner)
		takeDrop(id)
		if profile then giveItem(profile, d) end
	end
	for _, player in ipairs(Players:GetPlayers()) do DataService.Save(player) end
end)

-- growth / nest refresh loop + autosave
task.spawn(function()
	local lastSave = os.clock()
	while true do
		task.wait(1)
		for player in pairs(playerPlot) do
			local ok, err = pcall(renderPlot, player)
			if not ok then warn(err) end
		end
		if os.clock() - lastSave > 120 then
			lastSave = os.clock()
			for _, player in ipairs(Players:GetPlayers()) do task.spawn(DataService.Save, player) end
		end
	end
end)
