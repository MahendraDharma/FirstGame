-- Local copy of ReplicatedStorage.Shared.GameConfig (only used by the offline test)
local Config = {}
Config.StartingRu = 100
Config.StartingGems = 0
Config.BasePetSlots = 3
Config.MaxPetSlots = 5
Config.TilesPerPlot = 12
Config.GoldenChance = 0.01
Config.RarityOrder = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine"}
Config.Rarities = {
	Common    = {Tier = 1, Color = Color3.fromRGB(170,170,170), HarvestGems = 1,   BreedGems = 5,    PetSell = 300},
	Uncommon  = {Tier = 2, Color = Color3.fromRGB(85,200,90),   HarvestGems = 2,   BreedGems = 10,   PetSell = 1000},
	Rare      = {Tier = 3, Color = Color3.fromRGB(70,140,255),  HarvestGems = 5,   BreedGems = 25,   PetSell = 4000},
	Epic      = {Tier = 4, Color = Color3.fromRGB(170,80,240),  HarvestGems = 12,  BreedGems = 60,   PetSell = 15000},
	Legendary = {Tier = 5, Color = Color3.fromRGB(255,190,40),  HarvestGems = 30,  BreedGems = 150,  PetSell = 60000},
	Mythic    = {Tier = 6, Color = Color3.fromRGB(235,60,60),   HarvestGems = 75,  BreedGems = 400,  PetSell = 250000},
	Divine    = {Tier = 7, Color = Color3.fromRGB(60,230,240),  HarvestGems = 200, BreedGems = 1000, PetSell = 1000000},
}
Config.Crops = {
	Carrot = {Rarity = "Common", Color = Color3.fromRGB(255,140,30)},
	Wheat = {Rarity = "Common", Color = Color3.fromRGB(230,200,100)},
	Potato = {Rarity = "Uncommon", Color = Color3.fromRGB(180,140,90)},
	Sweetcorn = {Rarity = "Uncommon", Color = Color3.fromRGB(255,220,60)},
	Frostberry = {Rarity = "Rare", Color = Color3.fromRGB(140,210,255)},
	Honeyroot = {Rarity = "Rare", Color = Color3.fromRGB(240,170,40)},
	["Ember Pepper"] = {Rarity = "Epic", Color = Color3.fromRGB(255,70,30)},
	Moonmelon = {Rarity = "Epic", Color = Color3.fromRGB(200,200,255)},
	["Thunder Squash"] = {Rarity = "Legendary", Color = Color3.fromRGB(255,230,0)},
	["Dragonheart Fruit"] = {Rarity = "Mythic", Color = Color3.fromRGB(200,20,60)},
	["Starbloom Lotus"] = {Rarity = "Divine", Color = Color3.fromRGB(120,255,255)},
}
Config.CropOrder = {"Carrot","Wheat","Potato","Sweetcorn","Frostberry","Honeyroot","Ember Pepper","Moonmelon","Thunder Squash","Dragonheart Fruit","Starbloom Lotus"}
Config.Pets = {
	Imp = {Rarity = "Common"}, ["Fairy Sprite"] = {Rarity = "Common"},
	Jackalope = {Rarity = "Uncommon"}, ["Kitsune Kit"] = {Rarity = "Uncommon"},
	["Gryphon Chick"] = {Rarity = "Rare"}, Unicorn = {Rarity = "Rare"}, ["Pegasus Foal"] = {Rarity = "Rare"}, ["Sky Kitsune"] = {Rarity = "Rare"},
	["Fire Drake"] = {Rarity = "Epic"}, ["Frost Wyvern"] = {Rarity = "Epic"},
	["Thunder Dragon"] = {Rarity = "Legendary"}, Phoenix = {Rarity = "Legendary"}, Emberhorn = {Rarity = "Legendary"}, ["Glacier Pegasus"] = {Rarity = "Legendary"},
	Hydra = {Rarity = "Mythic"}, Leviathan = {Rarity = "Mythic"}, ["Stormfire Dragon"] = {Rarity = "Mythic"},
	["Aether Dragon"] = {Rarity = "Divine"},
}
Config.EggOrder = {"Hatchling Egg", "Mystic Egg", "Dragon Egg"}
function Config.RarityColor(rarity)
	local r = Config.Rarities[rarity]
	return r and r.Color or Color3.new(1, 1, 1)
end
return Config
