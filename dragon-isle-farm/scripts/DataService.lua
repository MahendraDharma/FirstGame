-- Loads/saves player profiles. Falls back to in-memory data if DataStores are unavailable (e.g. Studio API access off).
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.GameConfig)

local DataService = {}
local STORE_NAME = "DragonIsleFarm_v1"
local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then store = result else warn("[DataService] DataStore unavailable, using memory only:", result) end
end

local profiles: {[Player]: any} = {}
local loadFailed: {[Player]: boolean} = {}

local function defaultProfile()
	return {
		Version = 1,
		Ru = Config.StartingRu,
		Gems = Config.StartingGems,
		Seeds = {Carrot = 5},
		Crops = {},      -- ["Name" or "Name|Mutation"] = count
		Eggs = {},       -- [eggName] = count
		Pets = {},       -- [petId] = {Name = string, Equipped = bool}
		Items = {},      -- [gemItemName] = count
		PetSlots = Config.BasePetSlots,
		Tiles = {},      -- [tostring(index)] = {Crop, PlantedAt, Duration}
		SoilSlots = Config.BaseSoil, -- soil tiles owned (placed or not)
		Blocks = {},     -- [blockName] = count owned (placed or not)
		-- Layout = {Next, Items}: farm layout from Build Mode; GameServer creates the default (FarmGrid)
		Breeding = nil,  -- {A, B, EndsAt, Result}
		TradeLog = {},
		Stats = {Harvests = 0, Bred = 0, Trades = 0},
	}
end

local function reconcile(data)
	local def = defaultProfile()
	for k, v in pairs(def) do
		if data[k] == nil then data[k] = v end
	end
	return data
end

function DataService.Load(player: Player)
	local data = nil
	if store then
		local loaded = false
		for attempt = 1, 3 do
			local ok, result = pcall(function()
				return store:GetAsync("u_" .. player.UserId)
			end)
			if ok then data = result; loaded = true break end
			if string.find(tostring(result), "not allowed") then
				warn("[DataService] Studio API access is off - playing with temporary data (enable it in Game Settings > Security to test saving).")
				store = nil
				break
			end
			warn("[DataService] Load failed, attempt", attempt, result)
			task.wait(1)
		end
		if store and not loaded then
			-- Never overwrite a real save with a blank profile
			loadFailed[player] = true
		end
	end
	local profile = reconcile(data or defaultProfile())
	profiles[player] = profile
	return profile
end

function DataService.Get(player: Player)
	return profiles[player]
end

function DataService.Save(player: Player)
	local profile = profiles[player]
	if not profile or not store or loadFailed[player] then return end
	local ok, err = pcall(function()
		store:SetAsync("u_" .. player.UserId, profile)
	end)
	if not ok then warn("[DataService] Save failed for", player.Name, err) end
end

function DataService.Release(player: Player)
	DataService.Save(player)
	profiles[player] = nil
	loadFailed[player] = nil
end

function DataService.LoadFailed(player: Player)
	return loadFailed[player] == true
end

function DataService.All()
	return profiles
end

return DataService
