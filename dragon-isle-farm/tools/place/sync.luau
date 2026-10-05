-- Loads the place file, puts the repo's script copies into it, and runs the hatch reveal offline.
--   lune run sync.luau          test only
--   lune run sync.luau write    test, then save the scripts into the .rbxl
-- Needs Lune 0.10.5+ (https://github.com/lune-org/lune/releases). Studio stays the source of truth: open the
-- saved place in Studio (or paste the scripts) and publish from there.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

local ROOT = "../.."
local PLACE = ROOT .. "/Dragon Iske Farm.rbxl"
local SCRIPTS = {
	["ServerScriptService.GameServer"] = {"Script", "scripts/GameServer.lua"},
	["ServerScriptService.DataService"] = {"ModuleScript", "scripts/DataService.lua"},
	["StarterPlayer.StarterPlayerScripts.ClientUI"] = {"LocalScript", "scripts/ClientUI.lua"},
	["StarterPlayer.StarterPlayerScripts.BuildMode"] = {"LocalScript", "scripts/BuildMode.lua"},
	["StarterPlayer.StarterPlayerScripts.IdleAnimations"] = {"LocalScript", "scripts/IdleAnimations.lua"},
	["StarterPlayer.StarterPlayerScripts.HatchReveal"] = {"ModuleScript", "scripts/HatchReveal.lua"},
	["ReplicatedStorage.Shared.GameConfig"] = {"ModuleScript", "scripts/GameConfig.lua"},
	["ReplicatedStorage.Shared.FarmGrid"] = {"ModuleScript", "scripts/FarmGrid.lua"},
	["ReplicatedStorage.Shared.Models.ModelKit"] = {"ModuleScript", "models/ModelKit.lua"},
	["ReplicatedStorage.Shared.Models.CropModels"] = {"ModuleScript", "models/CropModels.lua"},
	["ReplicatedStorage.Shared.Models.PetModels"] = {"ModuleScript", "models/PetModels.lua"},
	["ReplicatedStorage.Shared.Models.ItemModels"] = {"ModuleScript", "models/ItemModels.lua"},
	["ReplicatedStorage.Shared.Models.BuildModels"] = {"ModuleScript", "models/BuildModels.lua"},
}

local game = roblox.deserializePlace(fs.readFile(PLACE))

local function find(path)
	local node = game
	local parts = string.split(path, ".")
	for i, name in parts do
		local child = node:FindFirstChild(name)
		if not child then
			assert(i == #parts, "missing " .. path)
			return nil, node, name
		end
		node = child
	end
	return node
end

local changed = 0
for path, spec in SCRIPTS do
	local source = fs.readFile(ROOT .. "/" .. spec[2])
	local inst, parent, name = find(path)
	if not inst then
		inst = roblox.Instance.new(spec[1])
		inst.Name = name
		inst.Parent = parent
		print("added   " .. path)
		changed += 1
	elseif inst.Source ~= source then
		print("updated " .. path)
		changed += 1
	end
	inst.Source = source
end

------------------------------------------------------------------ offline run of the hatch reveal
local frames, taps = 0, {}
local playerGui = roblox.Instance.new("Folder") -- outside the place, so the test UI is never saved
local tapAt = nil
local mocks = {
	TweenService = {Create = function(_, o, _, goal)
		return {Play = function() for k, v in goal do o[k] = v end end}
	end},
	RunService = {RenderStepped = {Wait = function()
		frames += 1
		if tapAt and frames == tapAt then for _, f in taps do f() end end
		return 1 / 60
	end}},
	SoundService = {PlayLocalSound = function(_, s) assert(s:IsA("Sound")) end},
	Players = {LocalPlayer = {WaitForChild = function() return playerGui end}},
}
roblox.implementMethod("Instance", "WaitForChild", function(self, name)
	return assert(self:FindFirstChild(name), "WaitForChild would hang: " .. name)
end)
roblox.implementProperty("TextButton", "Activated", function()
	return {Connect = function(_, f) table.insert(taps, f) end}
end)
local gameProxy = setmetatable({}, {__index = function(_, k)
	if k == "GetService" then return function(_, name) return mocks[name] or game:GetService(name) end end
	return game[k]
end})
local cache = {}
local env
local function load(inst)
	if cache[inst] == nil then
		-- Lune can't read the derived BasePart.Position; the model builders read it from these parts
		local source = inst.Source
		for _, name in {"d", "shell"} do
			source = source:gsub("%f[%w]" .. name .. "%.Position%f[^%w]", name .. ".CFrame.Position")
		end
		local scriptEnv = table.clone(env)
		scriptEnv.script = inst
		local fn = luau.load(source, {debugName = inst:GetFullName(), environment = scriptEnv})
		cache[inst] = fn()
	end
	return cache[inst]
end
local Random = {new = function() return {
	NextNumber = function(_, a, b) a, b = a or 0, b or 1 return a + math.random() * (b - a) end,
	NextInteger = function(_, a, b) return math.random(a, b) end,
} end}
env = {
	game = gameProxy, require = load, task = task, Random = Random,
	TweenInfo = {new = function(...) return {...} end},
}
for _, k in {"Instance", "Vector3", "Vector2", "CFrame", "Color3", "UDim", "UDim2", "Enum", "NumberSequence",
	"NumberSequenceKeypoint", "ColorSequence", "ColorSequenceKeypoint", "NumberRange", "BrickColor", "Ray", "Rect", "Font"} do
	env[k] = roblox[k]
end

local failures, runs = 0, 0
env.warn = function(...) failures += 1 print("WARN", ...) end
local HatchReveal = load(find("StarterPlayer.StarterPlayerScripts.HatchReveal"))
local Config = load(find("ReplicatedStorage.Shared.GameConfig"))
local gui = assert(playerGui:FindFirstChild("HatchRevealUI"))
local function play(info, tap)
	frames, taps, tapAt = 0, {}, tap
	local done = false
	HatchReveal.Play(info, function() done = true end)
	while not done do task.wait() end
	runs += 1
	if #gui:GetChildren() > 0 then failures += 1 print("FAIL  leftover UI after " .. info.Pet) end
	if frames < 10 or frames > 60 * 8 then failures += 1 print("FAIL  " .. info.Pet .. " ran " .. frames .. " frames") end
end

for name, d in Config.Pets do
	for _, egg in Config.EggOrder do play({Pet = name, Rarity = d.Rarity, Egg = egg}) end
	play({Pet = name, Rarity = d.Rarity, Egg = "Nest", Secret = d.BreedOnly == true})
	play({Pet = name, Rarity = d.Rarity, Egg = "Nest"}, 30)   -- tap during the shake
	play({Pet = name, Rarity = d.Rarity, Egg = "Mystic Egg"}, 150) -- tap during the reveal
end
play({Pet = "Unknown pet", Rarity = "Nope", Egg = "Unknown egg"})
print(string.format("hatch reveal: %d runs, %d failures", runs, failures))
if failures > 0 then process.exit(1) end

if process.args[1] == "write" then
	fs.writeFile(PLACE, roblox.serializePlace(game))
	print(string.format("saved %d script change(s) to %s", changed, PLACE))
end
