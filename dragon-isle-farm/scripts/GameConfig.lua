--!strict
-- Dragon Isle Farm: all tunable game data lives here.
local Config = {}

Config.StartingRu = 100
Config.StartingGems = 0
Config.BasePetSlots = 3
Config.MaxPetSlots = 5
Config.TilesPerPlot = 24 -- soil tile parts per plot (= MaxSoil); the farm layout decides which are placed
Config.GoldenChance = 0.01

-- Rarity tiers (order matters: index = tier number)
Config.RarityOrder = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine"}
Config.Rarities = {
	Common    = {Tier = 1, Color = Color3.fromRGB(170,170,170), HarvestGems = 1,   BreedGems = 5,    PetSell = 300,     BreedFee = 200,    BreedTime = 60},
	Uncommon  = {Tier = 2, Color = Color3.fromRGB(85,200,90),   HarvestGems = 2,   BreedGems = 10,   PetSell = 1000,    BreedFee = 600,    BreedTime = 120},
	Rare      = {Tier = 3, Color = Color3.fromRGB(70,140,255),  HarvestGems = 5,   BreedGems = 25,   PetSell = 4000,    BreedFee = 2000,   BreedTime = 300},
	Epic      = {Tier = 4, Color = Color3.fromRGB(170,80,240),  HarvestGems = 12,  BreedGems = 60,   PetSell = 15000,   BreedFee = 8000,   BreedTime = 600},
	Legendary = {Tier = 5, Color = Color3.fromRGB(255,190,40),  HarvestGems = 30,  BreedGems = 150,  PetSell = 60000,   BreedFee = 30000,  BreedTime = 1200},
	Mythic    = {Tier = 6, Color = Color3.fromRGB(235,60,60),   HarvestGems = 75,  BreedGems = 400,  PetSell = 250000,  BreedFee = 100000, BreedTime = 1800},
	Divine    = {Tier = 7, Color = Color3.fromRGB(60,230,240),  HarvestGems = 200, BreedGems = 1000, PetSell = 1000000, BreedFee = 250000, BreedTime = 3600},
}

-- Crops. Currency "Ru" = NPC Market, "Gems" = Gem Store.
Config.Crops = {
	Carrot           = {Rarity = "Common",    Price = 10,   Currency = "Ru",   GrowTime = 20,  Sell = 18,     Color = Color3.fromRGB(255,140,30)},
	Wheat            = {Rarity = "Common",    Price = 20,   Currency = "Ru",   GrowTime = 30,  Sell = 35,     Color = Color3.fromRGB(230,200,100)},
	Potato           = {Rarity = "Uncommon",  Price = 60,   Currency = "Ru",   GrowTime = 45,  Sell = 110,    Color = Color3.fromRGB(180,140,90)},
	Sweetcorn        = {Rarity = "Uncommon",  Price = 100,  Currency = "Ru",   GrowTime = 60,  Sell = 180,    Color = Color3.fromRGB(255,220,60)},
	Frostberry       = {Rarity = "Rare",      Price = 400,  Currency = "Ru",   GrowTime = 90,  Sell = 700,    Color = Color3.fromRGB(140,210,255)},
	Honeyroot        = {Rarity = "Rare",      Price = 650,  Currency = "Ru",   GrowTime = 120, Sell = 1150,   Color = Color3.fromRGB(240,170,40)},
	["Ember Pepper"]  = {Rarity = "Epic",      Price = 150,  Currency = "Gems", GrowTime = 180, Sell = 4000,   Color = Color3.fromRGB(255,70,30)},
	Moonmelon        = {Rarity = "Epic",      Price = 200,  Currency = "Gems", GrowTime = 240, Sell = 6000,   Color = Color3.fromRGB(200,200,255)},
	["Thunder Squash"] = {Rarity = "Legendary", Price = 500,  Currency = "Gems", GrowTime = 360, Sell = 18000,  Color = Color3.fromRGB(255,230,0)},
	["Dragonheart Fruit"] = {Rarity = "Mythic", Price = 1500, Currency = "Gems", GrowTime = 600, Sell = 60000, Color = Color3.fromRGB(200,20,60)},
	["Starbloom Lotus"] = {Rarity = "Divine",   Price = 5000, Currency = "Gems", GrowTime = 900, Sell = 200000, Color = Color3.fromRGB(120,255,255)},
}
Config.CropOrder = {"Carrot","Wheat","Potato","Sweetcorn","Frostberry","Honeyroot","Ember Pepper","Moonmelon","Thunder Squash","Dragonheart Fruit","Starbloom Lotus"}

-- Mutations: Ru multiplier (Golden also doubles gems)
Config.Mutations = {
	Golden    = {Mult = 20, Color = Color3.fromRGB(255,215,0)},
	Scorched  = {Mult = 3,  Color = Color3.fromRGB(255,90,20)},
	Frozen    = {Mult = 4,  Color = Color3.fromRGB(170,230,255)},
	Shocked   = {Mult = 5,  Color = Color3.fromRGB(255,255,120)},
	Celestial = {Mult = 10, Color = Color3.fromRGB(200,140,255)},
}

-- Pets. Bonuses: GrowSpeed, SellBonus, MutationChance, GemBonus (fractions); Mutation = {Name, Chance}
Config.Pets = {
	Imp                 = {Rarity = "Common",    Color = Color3.fromRGB(150,60,60),   GrowSpeed = 0.05},
	["Fairy Sprite"]     = {Rarity = "Common",    Color = Color3.fromRGB(255,170,230), SellBonus = 0.05},
	Jackalope           = {Rarity = "Uncommon",  Color = Color3.fromRGB(170,130,90),  GrowSpeed = 0.10},
	["Kitsune Kit"]      = {Rarity = "Uncommon",  Color = Color3.fromRGB(255,150,60),  MutationChance = 0.03},
	["Gryphon Chick"]    = {Rarity = "Rare",      Color = Color3.fromRGB(220,190,120), SellBonus = 0.10},
	Unicorn             = {Rarity = "Rare",      Color = Color3.fromRGB(255,255,255), SellBonus = 0.15},
	["Pegasus Foal"]     = {Rarity = "Rare",      Color = Color3.fromRGB(230,240,255), GrowSpeed = 0.15},
	["Sky Kitsune"]      = {Rarity = "Rare",      Color = Color3.fromRGB(120,200,255), MutationChance = 0.08, BreedOnly = true},
	["Fire Drake"]       = {Rarity = "Epic",      Color = Color3.fromRGB(220,60,20),   Mutation = {Name = "Scorched", Chance = 0.05}},
	["Frost Wyvern"]     = {Rarity = "Epic",      Color = Color3.fromRGB(150,220,255), Mutation = {Name = "Frozen", Chance = 0.05}},
	["Thunder Dragon"]   = {Rarity = "Legendary", Color = Color3.fromRGB(60,60,120),   Mutation = {Name = "Shocked", Chance = 0.06}, GrowSpeed = 0.20},
	Phoenix             = {Rarity = "Legendary", Color = Color3.fromRGB(255,120,0),   SellBonus = 0.25},
	Emberhorn           = {Rarity = "Legendary", Color = Color3.fromRGB(255,80,120),  Mutation = {Name = "Scorched", Chance = 0.08}, SellBonus = 0.20, BreedOnly = true},
	["Glacier Pegasus"]  = {Rarity = "Legendary", Color = Color3.fromRGB(180,240,255), Mutation = {Name = "Frozen", Chance = 0.08}, GrowSpeed = 0.20, BreedOnly = true},
	Hydra               = {Rarity = "Mythic",    Color = Color3.fromRGB(40,140,80),   GrowSpeed = 0.35, GemBonus = 0.10},
	Leviathan           = {Rarity = "Mythic",    Color = Color3.fromRGB(20,60,160),   SellBonus = 0.40, GemBonus = 0.10},
	["Stormfire Dragon"] = {Rarity = "Mythic",    Color = Color3.fromRGB(255,60,0),    Mutation = {Name = "Shocked", Chance = 0.10}, SellBonus = 0.30, BreedOnly = true},
	["Aether Dragon"]    = {Rarity = "Divine",    Color = Color3.fromRGB(200,170,255), Mutation = {Name = "Celestial", Chance = 0.05}, SellBonus = 0.50, GrowSpeed = 0.50, GemBonus = 0.25, BreedOnly = true},
}

-- Eggs: odds per rarity tier; species chosen evenly within the tier (BreedOnly excluded)
Config.Eggs = {
	["Hatchling Egg"] = {Price = 1500, Currency = "Ru",   Color = Color3.fromRGB(240,230,200), Odds = {Common = 70, Uncommon = 25, Rare = 5}},
	["Mystic Egg"]    = {Price = 250,  Currency = "Gems", Color = Color3.fromRGB(160,110,255), Odds = {Uncommon = 45, Rare = 35, Epic = 17, Legendary = 3}},
	["Dragon Egg"]    = {Price = 1000, Currency = "Gems", Color = Color3.fromRGB(200,50,40),   Odds = {Rare = 35, Epic = 45, Legendary = 17, Mythic = 3}},
}
Config.EggOrder = {"Hatchling Egg", "Mystic Egg", "Dragon Egg"}

-- Breeding recipes (order independent)
Config.Recipes = {
	{A = "Kitsune Kit",      B = "Gryphon Chick", Result = "Sky Kitsune"},
	{A = "Fire Drake",       B = "Unicorn",       Result = "Emberhorn"},
	{A = "Frost Wyvern",     B = "Pegasus Foal",  Result = "Glacier Pegasus"},
	{A = "Thunder Dragon",   B = "Phoenix",       Result = "Stormfire Dragon"},
	{A = "Stormfire Dragon", B = "Leviathan",     Result = "Aether Dragon"},
}
Config.BreedUpgradeChance = 0.10

-- Gem Store gear & cosmetics
Config.GemItems = {
	["Golden Watering Can"] = {Price = 300, Type = "Gear",     Desc = "+10% grow speed (permanent)", GrowSpeed = 0.10},
	["Rune Totem"]          = {Price = 500, Type = "Gear",     Desc = "+2% mutation chance (permanent)", MutationChance = 0.02},
	["Extra Pet Slot"]      = {Price = 400, Type = "Upgrade",  Desc = "+1 equipped pet (max 5)"},
	["Viking Banner"]       = {Price = 100, Type = "Cosmetic", Desc = "A banner on your farm"},
	["Dragon Statue"]       = {Price = 750, Type = "Cosmetic", Desc = "A dragon statue on your farm"},
}
Config.GemItemOrder = {"Golden Watering Can", "Rune Totem", "Extra Pet Slot", "Viking Banner", "Dragon Statue"}

-- Farm layout (Build Mode, see FarmGrid). Players start with BaseSoil tiles and can buy more up to MaxSoil.
Config.BaseSoil = 12
Config.MaxSoil = 24
Config.MaxLayoutItems = 200 -- soil + nest + Gem Store items + decorations on one farm

-- price of the next soil tile when you already have `owned` (12 -> 2,500 Ru, then +45% each)
function Config.SoilPrice(owned: number): number
	return math.floor(2500 * 1.45 ^ (owned - Config.BaseSoil) / 100 + 0.5) * 100
end

-- Gem Store items that stand on the farm grid: footprint in cells {W, H}
Config.FarmItemSize = {
	["Viking Banner"] = {2, 1},
	["Dragon Statue"] = {2, 2},
	["Golden Watering Can"] = {1, 1},
	["Rune Totem"] = {1, 1},
}

-- Decorations bought with Ru in Build Mode. W x H = footprint in 4-stud cells. Models: Models.BuildModels
Config.Blocks = {
	["Dirt Path"]    = {Price = 20,   W = 1, H = 1},
	["Stone Path"]   = {Price = 40,   W = 1, H = 1},
	["Wooden Fence"] = {Price = 60,   W = 1, H = 1},
	["Hay Bale"]     = {Price = 90,   W = 1, H = 1},
	["Flower Bed"]   = {Price = 150,  W = 1, H = 1},
	["Berry Bush"]   = {Price = 200,  W = 1, H = 1},
	["Boulder"]      = {Price = 250,  W = 1, H = 1},
	["Lantern Post"] = {Price = 400,  W = 1, H = 1},
	["Pine Tree"]    = {Price = 600,  W = 2, H = 2},
	["Duck Pond"]    = {Price = 2500, W = 2, H = 2},
	["Rune Stone"]   = {Price = 5000, W = 1, H = 1},
}
Config.BlockOrder = {"Dirt Path", "Stone Path", "Wooden Fence", "Hay Bale", "Flower Bed", "Berry Bush", "Boulder", "Lantern Post", "Pine Tree", "Duck Pond", "Rune Stone"}

function Config.RarityColor(rarity: string): Color3
	local r = Config.Rarities[rarity]
	return r and r.Color or Color3.new(1,1,1)
end

function Config.FormatNumber(n: number): string
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if formatted:sub(1,1) == "," then formatted = formatted:sub(2) end
	return formatted
end

return Config
