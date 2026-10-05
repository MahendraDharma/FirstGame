-- Dragon Isle Farm: client UI
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local HatchReveal = require(script.Parent:WaitForChild("HatchReveal"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Request = Remotes:WaitForChild("Request")
local DataUpdate = Remotes:WaitForChild("DataUpdate")
local Notify = Remotes:WaitForChild("Notify")
local TradeUpdate = Remotes:WaitForChild("TradeUpdate")

local fmt = Config.FormatNumber
local data = nil
local timeOffset = 0
local openName = nil
local tradeState = nil
local myOffer = {Ru = 0, Crops = {}, Seeds = {}, Eggs = {}, Pets = {}}
local breedPick = {A = nil, B = nil}
local currentTab = {Market = "Buy", GemStore = "Seeds", Inventory = "Crops", Trade = "Offer"}
local scrollMemory = {}
local breedTimerLabel = nil

local C = {
	bg = Color3.fromRGB(45, 32, 24), row = Color3.fromRGB(78, 58, 42), text = Color3.fromRGB(255, 244, 225),
	sub = Color3.fromRGB(215, 195, 165), green = Color3.fromRGB(70, 165, 80), red = Color3.fromRGB(195, 70, 60),
	blue = Color3.fromRGB(60, 125, 205), gold = Color3.fromRGB(225, 170, 40), purple = Color3.fromRGB(130, 80, 210),
	grey = Color3.fromRGB(105, 95, 85), cyan = Color3.fromRGB(60, 200, 220),
}

------------------------------------------------------------------ ui helpers
local function new(class, props, children)
	local o = Instance.new(class)
	local parent = nil
	for k, v in pairs(props or {}) do if k == "Parent" then parent = v else o[k] = v end end
	for _, c in ipairs(children or {}) do c.Parent = o end
	if parent then o.Parent = parent end
	return o
end
local function corner(r) return new("UICorner", {CornerRadius = UDim.new(0, r or 8)}) end
local function stroke(c, t) return new("UIStroke", {Color = c or Color3.new(0, 0, 0), Thickness = t or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}) end
local function label(p)
	p.BackgroundTransparency = 1
	p.Font = p.Font or Enum.Font.FredokaOne
	p.TextColor3 = p.TextColor3 or C.text
	return new("TextLabel", p)
end
local function button(o)
	local b = new("TextButton", {
		Text = o.Text, Font = Enum.Font.FredokaOne, TextSize = o.TextSize or 16, TextColor3 = Color3.new(1, 1, 1), TextWrapped = true,
		BackgroundColor3 = o.Disabled and C.grey or (o.Color or C.blue), Size = o.Size, Position = o.Position or UDim2.new(),
		AnchorPoint = o.AnchorPoint or Vector2.zero, LayoutOrder = o.LayoutOrder or 0, AutoButtonColor = not o.Disabled, Parent = o.Parent,
	}, {corner(8), stroke(Color3.fromRGB(20, 14, 10), 1.5)})
	if o.Callback and not o.Disabled then b.MouseButton1Click:Connect(o.Callback) end
	return b
end
local function tag(rarity)
	return string.format('<font color="#%s">[%s]</font>', Config.RarityColor(rarity):ToHex(), rarity)
end
local function tier(rarity) return Config.Rarities[rarity] and Config.Rarities[rarity].Tier or 0 end
local function splitKey(key)
	local name, mut = string.match(key, "^(.-)|(.+)$")
	if name then return name, mut end
	return key, nil
end
local function cropValue(name, mut)
	local d = Config.Crops[name]
	local mult = mut and Config.Mutations[mut] and Config.Mutations[mut].Mult or 1
	return math.floor(d.Sell * mult * (1 + ((data and data.Bonuses.SellBonus) or 0)))
end
local function petBonusText(name)
	local d = Config.Pets[name]
	local t = {}
	if d.GrowSpeed then table.insert(t, "+" .. math.floor(d.GrowSpeed * 100 + 0.5) .. "% grow") end
	if d.SellBonus then table.insert(t, "+" .. math.floor(d.SellBonus * 100 + 0.5) .. "% sell") end
	if d.MutationChance then table.insert(t, "+" .. math.floor(d.MutationChance * 100 + 0.5) .. "% mutation") end
	if d.GemBonus then table.insert(t, "+" .. math.floor(d.GemBonus * 100 + 0.5) .. "% Gems") end
	if d.Mutation then table.insert(t, math.floor(d.Mutation.Chance * 100 + 0.5) .. "% " .. d.Mutation.Name) end
	return table.concat(t, ", ")
end
local function oddsText(eggName)
	local egg = Config.Eggs[eggName]
	local t = {}
	for _, r in ipairs(Config.RarityOrder) do
		if egg.Odds[r] then table.insert(t, string.format('<font color="#%s">%s %d%%</font>', Config.RarityColor(r):ToHex(), r, egg.Odds[r])) end
	end
	return table.concat(t, "  ")
end
local function sortedCropKeys(tbl)
	local keys = {}
	for k in pairs(tbl) do table.insert(keys, k) end
	table.sort(keys, function(a, b)
		local na, nb = splitKey(a), splitKey(b)
		local ta, tb = Config.Crops[na] and tier(Config.Crops[na].Rarity) or 0, Config.Crops[nb] and tier(Config.Crops[nb].Rarity) or 0
		if ta ~= tb then return ta > tb end
		return a < b
	end)
	return keys
end
local function sortedPetIds(pets)
	local ids = {}
	for id in pairs(pets) do table.insert(ids, id) end
	table.sort(ids, function(a, b)
		local pa, pb = pets[a], pets[b]
		local ta, tb = tier(Config.Pets[pa.Name].Rarity), tier(Config.Pets[pb.Name].Rarity)
		if ta ~= tb then return ta > tb end
		if pa.Name ~= pb.Name then return pa.Name < pb.Name end
		return a < b
	end)
	return ids
end

------------------------------------------------------------------ root gui
local gui = new("ScreenGui", {Name = "MainUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui")})
-- the held item is a Tool; hide Roblox's default backpack bar so our hotbar is the only one
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)

-- toasts
local toastHolder = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 60), Size = UDim2.fromOffset(340, 400), BackgroundTransparency = 1, Parent = gui},
	{new("UIListLayout", {Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder})})
local toastCount = 0
local lastToast, lastToastAt = nil, 0
local function toast(text, kind)
	if not text then return end
	if text == lastToast and os.clock() - lastToastAt < 2 then return end
	lastToast, lastToastAt = text, os.clock()
	local existing = {}
	for _, c in ipairs(toastHolder:GetChildren()) do if c:IsA("Frame") then table.insert(existing, c) end end
	if #existing >= 5 then
		table.sort(existing, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
		existing[1]:Destroy()
	end
	toastCount += 1
	local color = ({success = C.green, error = C.red, rare = C.gold, info = C.blue})[kind or "info"] or C.blue
	local f = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.bg, LayoutOrder = toastCount, Parent = toastHolder}, {
		corner(8), stroke(color, 2), new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8)}),
	})
	label{Text = text, RichText = true, TextWrapped = true, TextSize = 16, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextXAlignment = Enum.TextXAlignment.Left, Parent = f}
	task.delay(4, function() if f then f:Destroy() end end)
end

local function call(action, ...)
	local ok, res = pcall(Request.InvokeServer, Request, action, ...)
	if not ok then toast("Connection error", "error") return nil end
	local hatched = res and res.Ok and res.Extra and res.Extra.Pet
	if res and res.Msg then
		local kind = res.Ok and "success" or "error"
		if res.Extra and res.Extra.Rarity and tier(res.Extra.Rarity) >= 4 then kind = "rare" end
		-- a hatch plays the reveal first; its toast would spoil the surprise, so it waits until the reveal closes
		if hatched then HatchReveal.Play(res.Extra, function() toast(res.Msg, kind) end) else toast(res.Msg, kind) end
	elseif hatched then
		HatchReveal.Play(res.Extra)
	end
	return res
end

-- HUD currencies
local hud = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(330, 42), BackgroundTransparency = 1, Parent = gui},
	{new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 10)})})
local function pill(color)
	local f = new("Frame", {Size = UDim2.fromOffset(155, 40), BackgroundColor3 = C.bg, Parent = hud}, {corner(20), stroke(color, 2.5)})
	return label{Size = UDim2.fromScale(1, 1), TextSize = 20, TextColor3 = color, Text = "...", Parent = f}
end
local ruLabel = pill(C.gold)
local gemLabel = pill(C.cyan)

-- side menu
local side = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(120, 160), BackgroundTransparency = 1, Parent = gui},
	{new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})})

-- seed hotbar
local hotbar = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.new(0.6, 0, 0, 78), BackgroundColor3 = C.bg, BackgroundTransparency = 0.15, Parent = gui},
	{corner(10), stroke(Color3.fromRGB(20, 14, 10), 2), new("UISizeConstraint", {MaxSize = Vector2.new(640, 78)})})
label{Text = "Seeds - click to hold, then press E on your soil", TextSize = 13, Font = Enum.Font.GothamMedium, TextColor3 = C.sub, Size = UDim2.new(1, -16, 0, 16), Position = UDim2.fromOffset(8, 2), TextXAlignment = Enum.TextXAlignment.Left, Parent = hotbar}
local hotList = new("ScrollingFrame", {Size = UDim2.new(1, -12, 0, 56), Position = UDim2.fromOffset(6, 19), BackgroundTransparency = 1, ScrollBarThickness = 4, CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X, Parent = hotbar},
	{new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder})})

------------------------------------------------------------------ panels
local panels = {}
local renderers = {}

local function closePanel()
	if openName and panels[openName] then panels[openName].Frame.Visible = false end
	openName = nil
	breedTimerLabel = nil
end

local function makePanel(name, title)
	local f = new("Frame", {Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), Size = UDim2.new(0.9, 0, 0.72, 0),
		BackgroundColor3 = C.bg, Visible = false, Parent = gui}, {corner(12), stroke(Color3.fromRGB(20, 14, 10), 3), new("UISizeConstraint", {MaxSize = Vector2.new(660, 470)})})
	local titleLabel = label{Text = title, TextSize = 26, Size = UDim2.new(1, -70, 0, 40), Position = UDim2.fromOffset(16, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = f}
	button{Text = "X", Color = C.red, Size = UDim2.fromOffset(36, 36), Position = UDim2.new(1, -46, 0, 8), Parent = f, Callback = closePanel}
	local tabs = new("Frame", {Name = "Tabs", Size = UDim2.new(1, -24, 0, 32), Position = UDim2.fromOffset(12, 48), BackgroundTransparency = 1, Parent = f},
		{new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})})
	local body = new("Frame", {Name = "Body", Size = UDim2.new(1, -24, 1, -98), Position = UDim2.fromOffset(12, 88), BackgroundTransparency = 1, Parent = f})
	panels[name] = {Frame = f, Tabs = tabs, Body = body, Title = titleLabel}
	return panels[name]
end

local function clear(frame)
	for _, c in ipairs(frame:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
end

local function setTabs(name, list)
	local p = panels[name]
	clear(p.Tabs)
	for i, t in ipairs(list) do
		button{Text = t, TextSize = 15, Color = currentTab[name] == t and C.gold or C.grey, Size = UDim2.fromOffset(110, 30), LayoutOrder = i, Parent = p.Tabs,
			Callback = function() currentTab[name] = t; renderers[name](p) end}
	end
end

local function makeList(parent, key, size, pos)
	local s = new("ScrollingFrame", {Size = size or UDim2.fromScale(1, 1), Position = pos or UDim2.new(), BackgroundTransparency = 1, ScrollBarThickness = 6,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = parent},
		{new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})})
	if scrollMemory[key] then task.defer(function() s.CanvasPosition = scrollMemory[key] end) end
	s:GetPropertyChangedSignal("CanvasPosition"):Connect(function() scrollMemory[key] = s.CanvasPosition end)
	return s
end

local function row(list, o)
	local r = new("Frame", {Size = UDim2.new(1, -10, 0, 54), BackgroundColor3 = C.row, LayoutOrder = o.order or 0, Parent = list}, {corner(8)})
	new("Frame", {Size = UDim2.new(0, 6, 1, -12), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = o.color or C.grey, BorderSizePixel = 0, Parent = r}, {corner(3)})
	local buttons = o.buttons or {}
	local bw = #buttons * 86
	label{Text = o.title, RichText = true, TextSize = 18, Size = UDim2.new(1, -(26 + bw), 0, 24), Position = UDim2.fromOffset(18, 4), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r}
	if o.sub then
		label{Text = o.sub, RichText = true, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.sub, Size = UDim2.new(1, -(26 + bw), 0, 20), Position = UDim2.fromOffset(18, 29), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r}
	end
	local holder = new("Frame", {Size = UDim2.new(0, bw, 1, 0), Position = UDim2.new(1, -bw - 8, 0, 0), BackgroundTransparency = 1, Parent = r},
		{new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})})
	for i, b in ipairs(buttons) do
		button{Text = b[1], Color = b[2], Size = UDim2.fromOffset(80, 36), LayoutOrder = i, Parent = holder, Callback = b[3], Disabled = b[4], TextSize = 14}
	end
	return r
end

local function emptyNote(list, text)
	label{Text = text, TextSize = 16, Font = Enum.Font.GothamMedium, TextColor3 = C.sub, TextWrapped = true, Size = UDim2.new(1, -10, 0, 40), Parent = list}
end

local function openPanel(name)
	if not data then return end
	if openName and openName ~= name then closePanel() end
	openName = name
	panels[name].Frame.Visible = true
	renderers[name](panels[name])
end

local function rerender()
	if openName and renderers[openName] then renderers[openName](panels[openName]) end
end

------------------------------------------------------------------ holding & dropping
local function heldIs(kind, key) return data.Held ~= nil and data.Held.Kind == kind and data.Held.Key == key end
local function heldCount(h)
	if h.Kind == "Seed" then return data.Seeds[h.Key] or 0 end
	if h.Kind == "Crop" then return data.Crops[h.Key] or 0 end
	if h.Kind == "Egg" then return data.Eggs[h.Key] or 0 end
	return data.Pets[h.Key] and 1 or 0
end
local function heldName(h)
	if h.Kind == "Seed" then return h.Key .. " seed" end
	if h.Kind == "Crop" then
		local name, mut = splitKey(h.Key)
		return (mut and (mut .. " ") or "") .. name
	end
	if h.Kind == "Pet" then return data.Pets[h.Key] and data.Pets[h.Key].Name or "Pet" end
	return h.Key
end
-- Hold toggles: holding the same item again puts it away
local function hold(kind, key)
	if heldIs(kind, key) then call("HoldItem", nil) else call("HoldItem", kind, key) end
end
-- dropping a pet or a whole stack needs a second click within 3 s
local confirmKey, confirmAt = nil, 0
local function drop(kind, key, qty)
	if kind == "Pet" or qty > 1 then
		local k = kind .. "|" .. key .. "|" .. qty
		if confirmKey ~= k or os.clock() - confirmAt > 3 then
			confirmKey, confirmAt = k, os.clock()
			toast("Click Drop again to confirm. Anyone nearby can pick it up!", "info")
			return
		end
		confirmKey = nil
	end
	call("DropItem", kind, key, qty)
end

local heldBar = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -96), Size = UDim2.new(0.9, 0, 0, 44), BackgroundColor3 = C.bg, BackgroundTransparency = 0.15, Visible = false, Parent = gui},
	{corner(10), stroke(C.gold, 2), new("UISizeConstraint", {MaxSize = Vector2.new(600, 44)})})
local heldText = label{Text = "", TextSize = 16, Size = UDim2.new(1, -296, 1, 0), Position = UDim2.fromOffset(12, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = heldBar}
local function dropHeld(all)
	local h = data and data.Held
	if not h then return end
	drop(h.Kind, h.Key, all and math.max(1, heldCount(h)) or 1)
end
button{Text = "Drop 1 (G)", Color = C.red, Size = UDim2.fromOffset(88, 34), Position = UDim2.new(1, -284, 0, 5), TextSize = 13, Parent = heldBar, Callback = function() dropHeld(false) end}
button{Text = "Drop all", Color = C.red, Size = UDim2.fromOffset(88, 34), Position = UDim2.new(1, -190, 0, 5), TextSize = 13, Parent = heldBar, Callback = function() dropHeld(true) end}
button{Text = "Put away", Color = C.grey, Size = UDim2.fromOffset(88, 34), Position = UDim2.new(1, -96, 0, 5), TextSize = 13, Parent = heldBar, Callback = function() call("HoldItem", nil) end}
local function renderHeld()
	local h = data and data.Held
	heldBar.Visible = h ~= nil and not gui:GetAttribute("Building")
	if h then
		heldText.Text = h.Kind == "Pet" and ("Holding: " .. heldName(h)) or string.format("Holding: %s x%d", heldName(h), heldCount(h))
	end
end

------------------------------------------------------------------ Inventory
makePanel("Inventory", "Inventory")
renderers.Inventory = function(p)
	setTabs("Inventory", {"Crops", "Seeds", "Eggs", "Items"})
	clear(p.Body)
	local tab = currentTab.Inventory
	local list = makeList(p.Body, "Inv" .. tab)
	if tab == "Crops" then
		local keys = sortedCropKeys(data.Crops)
		if #keys == 0 then emptyNote(list, "No crops yet. Harvest your farm!") end
		for i, key in ipairs(keys) do
			local name, mut = splitKey(key)
			local d = Config.Crops[name]
			local mutText = mut and string.format('<font color="#%s">%s</font> ', Config.Mutations[mut].Color:ToHex(), mut) or ""
			local h = heldIs("Crop", key)
			row(list, {order = i, color = Config.RarityColor(d.Rarity), title = string.format("%s%s x%d %s", mutText, name, data.Crops[key], tag(d.Rarity)),
				sub = string.format("Worth %s Ru each at the NPC Market", fmt(cropValue(name, mut))),
				buttons = {{h and "Holding" or "Hold", h and C.gold or C.blue, function() hold("Crop", key) end}, {"Drop", C.red, function() drop("Crop", key, 1) end}}})
		end
	elseif tab == "Seeds" then
		local any = false
		for i, name in ipairs(Config.CropOrder) do
			local n = data.Seeds[name]
			if n and n > 0 then
				any = true
				local d = Config.Crops[name]
				local h = heldIs("Seed", name)
				row(list, {order = i, color = Config.RarityColor(d.Rarity), title = string.format("%s seed x%d %s", name, n, tag(d.Rarity)),
					sub = string.format("Grows in %ds, +%d Gems on harvest", d.GrowTime, Config.Rarities[d.Rarity].HarvestGems),
					buttons = {{h and "Holding" or "Hold", h and C.gold or C.blue, function() if h then call("HoldItem", nil) else call("SelectSeed", name) end end},
						{"Drop", C.red, function() drop("Seed", name, 1) end}}})
			end
		end
		if not any then emptyNote(list, "No seeds. Buy some at the NPC Market or Gem Store.") end
	elseif tab == "Eggs" then
		local any = false
		for i, name in ipairs(Config.EggOrder) do
			local n = data.Eggs[name]
			if n and n > 0 then
				any = true
				local h = heldIs("Egg", name)
				row(list, {order = i, color = Config.Eggs[name].Color, title = string.format("%s x%d", name, n), sub = oddsText(name),
					buttons = {{"Hatch", C.purple, function() call("HatchEgg", name) end}, {h and "Holding" or "Hold", h and C.gold or C.blue, function() hold("Egg", name) end},
						{"Drop", C.red, function() drop("Egg", name, 1) end}}})
			end
		end
		if not any then emptyNote(list, "No eggs. The Hatchling Egg is at the NPC Market; rarer eggs are in the Gem Store.") end
	else
		row(list, {order = 0, color = C.cyan, title = string.format("Pet slots: %d / %d", data.PetSlots, Config.MaxPetSlots), sub = "Buy Extra Pet Slots in the Gem Store"})
		for i, name in ipairs(Config.GemItemOrder) do
			if (data.Items[name] or 0) > 0 then
				row(list, {order = i, color = C.gold, title = name, sub = Config.GemItems[name].Desc})
			end
		end
	end
end

------------------------------------------------------------------ Pets
makePanel("Pets", "My Pets")
renderers.Pets = function(p)
	clear(p.Tabs); clear(p.Body)
	local equipped = 0
	for _, pet in pairs(data.Pets) do if pet.Equipped then equipped += 1 end end
	local b = data.Bonuses
	label{Text = string.format("Equipped %d/%d   |   Grow +%d%%   Sell +%d%%   Mutation +%d%%   Gems +%d%%", equipped, data.PetSlots,
		math.floor(b.GrowSpeed * 100 + 0.5), math.floor(b.SellBonus * 100 + 0.5), math.floor(b.MutationChance * 100 + 0.5), math.floor(b.GemBonus * 100 + 0.5)),
		TextSize = 15, Font = Enum.Font.GothamMedium, TextColor3 = C.sub, Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = p.Tabs}
	local list = makeList(p.Body, "Pets")
	local ids = sortedPetIds(data.Pets)
	if #ids == 0 then emptyNote(list, "No pets yet. Buy and hatch an egg!") end
	for i, id in ipairs(ids) do
		local pet = data.Pets[id]
		local d = Config.Pets[pet.Name]
		local inNest = data.Breeding and (data.Breeding.A == id or data.Breeding.B == id)
		local btn
		if inNest then btn = {"In Nest", C.grey, nil, true}
		elseif pet.Equipped then btn = {"Unequip", C.red, function() call("EquipPet", id, false) end}
		else btn = {"Equip", C.green, function() call("EquipPet", id, true) end} end
		local h = heldIs("Pet", id)
		row(list, {order = i, color = Config.RarityColor(d.Rarity), title = string.format("%s %s%s", pet.Name, tag(d.Rarity), pet.Equipped and "  (equipped)" or ""),
			sub = petBonusText(pet.Name), buttons = {btn, {h and "Holding" or "Hold", h and C.gold or C.blue, function() hold("Pet", id) end, inNest or pet.Equipped},
				{"Drop", C.red, function() drop("Pet", id, 1) end, inNest}}})
	end
end

------------------------------------------------------------------ NPC Market
makePanel("Market", "NPC Market - Trader Brann")
renderers.Market = function(p)
	setTabs("Market", {"Buy", "Sell"})
	clear(p.Body)
	local list = makeList(p.Body, "Market" .. currentTab.Market)
	if currentTab.Market == "Buy" then
		local order = 0
		for _, name in ipairs(Config.CropOrder) do
			local d = Config.Crops[name]
			if d.Currency == "Ru" then
				order += 1
				row(list, {order = order, color = Config.RarityColor(d.Rarity), title = string.format("%s seed %s - %s Ru", name, tag(d.Rarity), fmt(d.Price)),
					sub = string.format("Grows %ds | Sells %s Ru | +%d Gems on harvest | You have %d", d.GrowTime, fmt(d.Sell), Config.Rarities[d.Rarity].HarvestGems, data.Seeds[name] or 0),
					buttons = {{"Buy 1", C.green, function() call("BuySeed", name, 1) end}, {"Buy 10", C.green, function() call("BuySeed", name, 10) end}}})
			end
		end
		for _, name in ipairs(Config.EggOrder) do
			local e = Config.Eggs[name]
			if e.Currency == "Ru" then
				order += 1
				row(list, {order = order, color = e.Color, title = string.format("%s - %s Ru", name, fmt(e.Price)), sub = oddsText(name),
					buttons = {{"Buy", C.purple, function() call("BuyEgg", name) end}}})
			end
		end
	else
		local keys = sortedCropKeys(data.Crops)
		local total = 0
		for _, key in ipairs(keys) do local n, m = splitKey(key); total += cropValue(n, m) * data.Crops[key] end
		row(list, {order = 0, color = C.gold, title = "Sell ALL crops", sub = "Total: " .. fmt(total) .. " Ru",
			buttons = {{"Sell All", C.gold, function() call("SellAllCrops") end, #keys == 0}}})
		for i, key in ipairs(keys) do
			local name, mut = splitKey(key)
			local d = Config.Crops[name]
			local n = data.Crops[key]
			row(list, {order = i, color = Config.RarityColor(d.Rarity), title = string.format("%s%s x%d %s", mut and (mut .. " ") or "", name, n, tag(d.Rarity)),
				sub = string.format("%s Ru each", fmt(cropValue(name, mut))),
				buttons = {{"Sell 1", C.green, function() call("SellCrop", key, 1) end}, {"Sell " .. n, C.green, function() call("SellCrop", key, n) end}}})
		end
		local ids = sortedPetIds(data.Pets)
		for i, id in ipairs(ids) do
			local pet = data.Pets[id]
			local d = Config.Pets[pet.Name]
			local inNest = data.Breeding and (data.Breeding.A == id or data.Breeding.B == id)
			row(list, {order = 1000 + i, color = Config.RarityColor(d.Rarity), title = string.format("Pet: %s %s", pet.Name, tag(d.Rarity)),
				sub = string.format("Sells for %s Ru", fmt(Config.Rarities[d.Rarity].PetSell)),
				buttons = {{"Sell", C.red, function() call("SellPet", id) end, inNest}}})
		end
	end
end

------------------------------------------------------------------ Gem Store
makePanel("GemStore", "Gem Store - Runekeeper Sigrid")
renderers.GemStore = function(p)
	setTabs("GemStore", {"Seeds", "Eggs", "Items"})
	clear(p.Body)
	local list = makeList(p.Body, "Gem" .. currentTab.GemStore)
	local tab = currentTab.GemStore
	if tab == "Seeds" then
		local order = 0
		for _, name in ipairs(Config.CropOrder) do
			local d = Config.Crops[name]
			if d.Currency == "Gems" then
				order += 1
				row(list, {order = order, color = Config.RarityColor(d.Rarity), title = string.format("%s seed %s - %s Gems", name, tag(d.Rarity), fmt(d.Price)),
					sub = string.format("Grows %ds | Sells %s Ru | +%d Gems on harvest", d.GrowTime, fmt(d.Sell), Config.Rarities[d.Rarity].HarvestGems),
					buttons = {{"Buy", C.cyan, function() call("BuySeed", name, 1) end, data.Gems < d.Price}}})
			end
		end
	elseif tab == "Eggs" then
		local order = 0
		for _, name in ipairs(Config.EggOrder) do
			local e = Config.Eggs[name]
			if e.Currency == "Gems" then
				order += 1
				row(list, {order = order, color = e.Color, title = string.format("%s - %s Gems", name, fmt(e.Price)), sub = oddsText(name),
					buttons = {{"Buy", C.cyan, function() call("BuyEgg", name) end, data.Gems < e.Price}}})
			end
		end
	else
		for i, name in ipairs(Config.GemItemOrder) do
			local it = Config.GemItems[name]
			local owned = (data.Items[name] or 0) > 0
			local maxed = name == "Extra Pet Slot" and data.PetSlots >= Config.MaxPetSlots
			row(list, {order = i, color = C.gold, title = string.format("%s - %s Gems  <font color=\"#b4a58c\">(%s)</font>", name, fmt(it.Price), it.Type), sub = it.Desc,
				buttons = {{(owned or maxed) and "Owned" or "Buy", C.cyan, function() call("BuyItem", name) end, owned or maxed or data.Gems < it.Price}}})
		end
	end
end

------------------------------------------------------------------ Breeding Nest
makePanel("Breed", "Breeding Nest")
renderers.Breed = function(p)
	clear(p.Tabs); clear(p.Body)
	breedTimerLabel = nil
	local br = data.Breeding
	if br then
		local d = Config.Pets[br.Result]
		label{Text = string.format("A %s egg is in your nest!", tag(d.Rarity)), RichText = true, TextSize = 24, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 20), Parent = p.Body}
		breedTimerLabel = label{Text = "", TextSize = 34, TextColor3 = C.gold, Size = UDim2.new(1, 0, 0, 50), Position = UDim2.fromOffset(0, 70), Parent = p.Body}
		local function tick()
			local left = br.EndsAt - (os.time() + timeOffset)
			if breedTimerLabel then breedTimerLabel.Text = left > 0 and string.format("%d:%02d", left // 60, left % 60) or "Ready to hatch!" end
			return left
		end
		local left = tick()
		button{Text = "Collect Hatchling", Color = C.green, Size = UDim2.fromOffset(220, 50), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, -120, 0, 150), Parent = p.Body,
			Disabled = left > 0, Callback = function() call("CollectBreed") end}
		button{Text = "Cancel", Color = C.red, Size = UDim2.fromOffset(160, 50), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 110, 0, 150), Parent = p.Body,
			Callback = function() call("CancelBreed") end}
		label{Text = "Gems on collect: " .. Config.Rarities[d.Rarity].BreedGems .. " (more with Gem-bonus pets)", TextSize = 16, Font = Enum.Font.GothamMedium, TextColor3 = C.sub,
			Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 215), Parent = p.Body}
		return
	end
	-- validate picks
	if breedPick.A and not data.Pets[breedPick.A] then breedPick.A = nil end
	if breedPick.B and not data.Pets[breedPick.B] then breedPick.B = nil end
	local function nameOf(id) return id and data.Pets[id] and data.Pets[id].Name end
	local a, b = nameOf(breedPick.A), nameOf(breedPick.B)
	local fee, time = 0, 0
	if a and b then
		local top = math.max(tier(Config.Pets[a].Rarity), tier(Config.Pets[b].Rarity))
		local t = Config.Rarities[Config.RarityOrder[top]]
		fee, time = t.BreedFee, t.BreedTime
	end
	local header = new("Frame", {Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Parent = p.Body})
	label{Text = string.format("%s  x  %s", a and (a .. " " .. tag(Config.Pets[a].Rarity)) or "[pick A]", b and (b .. " " .. tag(Config.Pets[b].Rarity)) or "[pick B]"),
		RichText = true, TextSize = 20, Size = UDim2.new(1, -190, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, Parent = header}
	label{Text = (a and b) and string.format("Fee %s Ru  |  Time %d:%02d  |  Some pairs make secret hybrids!", fmt(fee), time // 60, time % 60) or "Pick two pets. Parents are kept; some pairs make secret hybrids!",
		TextSize = 14, Font = Enum.Font.GothamMedium, TextColor3 = C.sub, Size = UDim2.new(1, -190, 0, 22), Position = UDim2.fromOffset(0, 30), TextXAlignment = Enum.TextXAlignment.Left, Parent = header}
	button{Text = "Start Breeding", Color = C.green, Size = UDim2.fromOffset(170, 46), Position = UDim2.new(1, -172, 0, 4), Parent = header, Disabled = not (a and b),
		Callback = function()
			local res = call("StartBreed", breedPick.A, breedPick.B)
			if res and res.Ok then breedPick.A, breedPick.B = nil, nil end
		end}
	local list = makeList(p.Body, "Breed", UDim2.new(1, 0, 1, -66), UDim2.fromOffset(0, 66))
	local ids = sortedPetIds(data.Pets)
	if #ids < 2 then emptyNote(list, "You need at least two pets to breed.") end
	for i, id in ipairs(ids) do
		local pet = data.Pets[id]
		local d = Config.Pets[pet.Name]
		local isA, isB = breedPick.A == id, breedPick.B == id
		row(list, {order = i, color = Config.RarityColor(d.Rarity), title = pet.Name .. " " .. tag(d.Rarity), sub = petBonusText(pet.Name),
			buttons = {
				{isA and "A (set)" or "Set A", isA and C.gold or C.blue, function() breedPick.A = id; if breedPick.B == id then breedPick.B = nil end; rerender() end},
				{isB and "B (set)" or "Set B", isB and C.gold or C.blue, function() breedPick.B = id; if breedPick.A == id then breedPick.A = nil end; rerender() end},
			}})
	end
end

------------------------------------------------------------------ Trading
makePanel("Trade", "Trading")
local function sendOffer()
	call("TradeSetOffer", myOffer)
end
local function offerLines(list, offer, mine, startOrder)
	local order = startOrder
	local function line(text, color, removeFn)
		order += 1
		row(list, {order = order, color = color, title = text, buttons = removeFn and {{"Remove", C.red, removeFn}} or nil})
	end
	if offer.Ru and offer.Ru > 0 then line(fmt(offer.Ru) .. " Ru", C.gold, mine and function() myOffer.Ru = 0; sendOffer() end) end
	for key, n in pairs(offer.Crops) do
		local name, mut = splitKey(key)
		local d = Config.Crops[name]
		line(string.format("%s%s x%d %s", mut and (mut .. " ") or "", name, n, tag(d.Rarity)), Config.RarityColor(d.Rarity), mine and function() myOffer.Crops[key] = nil; sendOffer() end)
	end
	for key, n in pairs(offer.Seeds) do
		local d = Config.Crops[key]
		line(string.format("%s seed x%d %s", key, n, tag(d.Rarity)), Config.RarityColor(d.Rarity), mine and function() myOffer.Seeds[key] = nil; sendOffer() end)
	end
	for key, n in pairs(offer.Eggs) do
		line(string.format("%s x%d", key, n), Config.Eggs[key].Color, mine and function() myOffer.Eggs[key] = nil; sendOffer() end)
	end
	for _, pet in ipairs(offer.Pets) do
		line(string.format("Pet: %s %s", pet.Name, tag(pet.Rarity)), Config.RarityColor(pet.Rarity), mine and function()
			for i, id in ipairs(myOffer.Pets) do if id == pet.Id then table.remove(myOffer.Pets, i) break end end
			sendOffer()
		end)
	end
	if order == startOrder then emptyNote(list, mine and "Add items from the 'Add Items' tab" or "Nothing offered yet") end
end

renderers.Trade = function(p)
	clear(p.Tabs); clear(p.Body)
	if not tradeState then
		p.Title.Text = "Trading - pick a player"
		local list = makeList(p.Body, "TradePlayers")
		local any = false
		for i, pl in ipairs(Players:GetPlayers()) do
			if pl ~= player then
				any = true
				row(list, {order = i, color = C.blue, title = pl.DisplayName, sub = "@" .. pl.Name, buttons = {{"Request", C.green, function() call("TradeRequest", pl.UserId) end}}})
			end
		end
		if not any then emptyNote(list, "No other players in this server yet. Invite a friend to trade!") end
		return
	end
	local s = tradeState
	p.Title.Text = "Trading with " .. s.Partner
	setTabs("Trade", {"Offer", "Add Items"})
	local bottom = new("Frame", {Size = UDim2.new(1, 0, 0, 50), Position = UDim2.new(0, 0, 1, -50), BackgroundTransparency = 1, Parent = p.Body})
	local status
	if s.Stage == "Offer" then
		status = string.format("You: %s  |  %s: %s", s.MyAccept and "Accepted" or "Not accepted", s.Partner, s.TheirAccept and "Accepted" or "Not accepted")
		button{Text = s.MyAccept and "Accepted" or "Accept", Color = C.green, Disabled = s.MyAccept, Size = UDim2.fromOffset(140, 44), Position = UDim2.new(1, -290, 0, 3), Parent = bottom, Callback = function() call("TradeAccept") end}
	else
		status = string.format("FINAL CHECK - You: %s  |  %s: %s", s.MyConfirm and "Confirmed" or "waiting", s.Partner, s.TheirConfirm and "Confirmed" or "waiting")
		button{Text = s.MyConfirm and "Confirmed" or "Confirm", Color = C.gold, Disabled = s.MyConfirm, Size = UDim2.fromOffset(140, 44), Position = UDim2.new(1, -290, 0, 3), Parent = bottom, Callback = function() call("TradeConfirm") end}
	end
	button{Text = "Cancel", Color = C.red, Size = UDim2.fromOffset(140, 44), Position = UDim2.new(1, -142, 0, 3), Parent = bottom, Callback = function() call("TradeCancel") end}
	label{Text = status, TextSize = 14, Font = Enum.Font.GothamMedium, TextColor3 = C.sub, TextWrapped = true, Size = UDim2.new(1, -300, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = bottom}

	if currentTab.Trade == "Offer" then
		local left = new("Frame", {Size = UDim2.new(0.5, -4, 1, -56), BackgroundTransparency = 1, Parent = p.Body})
		local right = new("Frame", {Size = UDim2.new(0.5, -4, 1, -56), Position = UDim2.new(0.5, 4, 0, 0), BackgroundTransparency = 1, Parent = p.Body})
		label{Text = "Your offer", TextSize = 18, Size = UDim2.new(1, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, Parent = left}
		label{Text = s.Partner .. "'s offer", TextSize = 18, Size = UDim2.new(1, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, Parent = right}
		local l1 = makeList(left, "TradeMine", UDim2.new(1, 0, 1, -28), UDim2.fromOffset(0, 28))
		local l2 = makeList(right, "TradeTheirs", UDim2.new(1, 0, 1, -28), UDim2.fromOffset(0, 28))
		offerLines(l1, s.Mine, true, 0)
		offerLines(l2, s.Theirs, false, 0)
	else
		local top = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = p.Body})
		label{Text = "Ru to offer:", TextSize = 16, Size = UDim2.fromOffset(110, 36), TextXAlignment = Enum.TextXAlignment.Left, Parent = top}
		local box = new("TextBox", {Text = tostring(myOffer.Ru or 0), PlaceholderText = "0", Font = Enum.Font.FredokaOne, TextSize = 18, TextColor3 = C.text, BackgroundColor3 = C.row,
			Size = UDim2.fromOffset(160, 34), Position = UDim2.fromOffset(110, 1), ClearTextOnFocus = false, Parent = top}, {corner(6)})
		button{Text = "Set Ru", Color = C.gold, Size = UDim2.fromOffset(90, 34), Position = UDim2.fromOffset(280, 1), Parent = top, Callback = function()
			myOffer.Ru = math.max(0, math.floor(tonumber(box.Text) or 0)); sendOffer()
		end}
		local list = makeList(p.Body, "TradeAdd", UDim2.new(1, 0, 1, -100), UDim2.fromOffset(0, 44))
		local order = 0
		local offeredPets = {}
		for _, id in ipairs(myOffer.Pets) do offeredPets[id] = true end
		local function addRow(cat, key, have, titleText, color)
			local inOffer = myOffer[cat][key] or 0
			if have - inOffer <= 0 then return end
			order += 1
			row(list, {order = order, color = color, title = titleText .. string.format("  (%d left)", have - inOffer),
				buttons = {{"+1", C.green, function() myOffer[cat][key] = inOffer + 1; sendOffer() end}, {"+All", C.green, function() myOffer[cat][key] = have; sendOffer() end}}})
		end
		for _, key in ipairs(sortedCropKeys(data.Crops)) do
			local name, mut = splitKey(key)
			local d = Config.Crops[name]
			addRow("Crops", key, data.Crops[key], string.format("%s%s %s", mut and (mut .. " ") or "", name, tag(d.Rarity)), Config.RarityColor(d.Rarity))
		end
		for _, name in ipairs(Config.CropOrder) do
			if data.Seeds[name] then addRow("Seeds", name, data.Seeds[name], name .. " seed " .. tag(Config.Crops[name].Rarity), Config.RarityColor(Config.Crops[name].Rarity)) end
		end
		for _, name in ipairs(Config.EggOrder) do
			if data.Eggs[name] then addRow("Eggs", name, data.Eggs[name], name, Config.Eggs[name].Color) end
		end
		for _, id in ipairs(sortedPetIds(data.Pets)) do
			local pet = data.Pets[id]
			local inNest = data.Breeding and (data.Breeding.A == id or data.Breeding.B == id)
			if not offeredPets[id] and not inNest then
				order += 1
				local d = Config.Pets[pet.Name]
				row(list, {order = order, color = Config.RarityColor(d.Rarity), title = "Pet: " .. pet.Name .. " " .. tag(d.Rarity), sub = petBonusText(pet.Name),
					buttons = {{"Add", C.green, function() table.insert(myOffer.Pets, id); sendOffer() end}}})
			end
		end
		if order == 0 then emptyNote(list, "Nothing left to add.") end
	end
end

-- trade request popup
local requestPopup = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 60), Size = UDim2.fromOffset(380, 110), BackgroundColor3 = C.bg, Visible = false, Parent = gui},
	{corner(10), stroke(C.gold, 2.5)})
local requestText = label{Text = "", TextSize = 18, TextWrapped = true, Size = UDim2.new(1, -20, 0, 50), Position = UDim2.fromOffset(10, 4), Parent = requestPopup}
local requestFrom = nil
button{Text = "Accept", Color = C.green, Size = UDim2.fromOffset(150, 40), Position = UDim2.new(0.5, -158, 0, 60), Parent = requestPopup, Callback = function()
	requestPopup.Visible = false
	if requestFrom then call("TradeRespond", requestFrom, true) end
end}
button{Text = "Decline", Color = C.red, Size = UDim2.fromOffset(150, 40), Position = UDim2.new(0.5, 8, 0, 60), Parent = requestPopup, Callback = function()
	requestPopup.Visible = false
	if requestFrom then call("TradeRespond", requestFrom, false) end
end}

------------------------------------------------------------------ side buttons
local function sideButton(text, color, order, panelName)
	button{Text = text, Color = color, Size = UDim2.fromOffset(120, 44), LayoutOrder = order, TextSize = 18, Parent = side, Callback = function()
		if openName == panelName then closePanel() else openPanel(panelName) end
	end}
end
sideButton("Inventory", C.blue, 1, "Inventory")
sideButton("Pets", C.purple, 2, "Pets")
sideButton("Trade", C.green, 3, "Trade")
-- Build Mode lives in the BuildMode script; this button and event connect the two
local toggleBuild = Instance.new("BindableEvent"); toggleBuild.Name = "ToggleBuild"; toggleBuild.Parent = gui
button{Text = "Build", Color = C.gold, Size = UDim2.fromOffset(120, 44), LayoutOrder = 4, TextSize = 18, Parent = side, Callback = function()
	closePanel()
	toggleBuild:Fire()
end}
gui:GetAttributeChangedSignal("Building"):Connect(function()
	local building = gui:GetAttribute("Building") == true
	hotbar.Visible = not building
	renderHeld()
	if building then closePanel() end
end)
if game:GetService("RunService"):IsStudio() then
	-- Studio-only test hook: fire this BindableEvent with a panel name to open it
	local hook = Instance.new("BindableEvent"); hook.Name = "DevOpenPanel"; hook.Parent = gui
	hook.Event:Connect(function(name) if name then openPanel(name) else closePanel() end end)
	button{Text = "[Studio] Test $", Color = C.grey, Size = UDim2.fromOffset(120, 34), LayoutOrder = 9, TextSize = 14, Parent = side, Callback = function() call("DevGrant") end}
	button{Text = "[Studio] All items", Color = C.grey, Size = UDim2.fromOffset(120, 34), LayoutOrder = 10, TextSize = 14, Parent = side, Callback = function() call("DevGrantAll") end}
	button{Text = "[Studio] Grow all", Color = C.grey, Size = UDim2.fromOffset(120, 34), LayoutOrder = 11, TextSize = 14, Parent = side, Callback = function() call("DevFinishTimers") end}
end

------------------------------------------------------------------ hotbar
local function renderHotbar()
	clear(hotList)
	local any = false
	for i, name in ipairs(Config.CropOrder) do
		local n = data.Seeds[name]
		if n and n > 0 then
			any = true
			local d = Config.Crops[name]
			local sel = data.SelectedSeed == name
			local b = button{Text = string.format("%s\nx%d", name, n), TextSize = 13, Color = sel and C.gold or C.row, Size = UDim2.fromOffset(92, 50), LayoutOrder = i, Parent = hotList,
				Callback = function() if heldIs("Seed", name) then call("HoldItem", nil) else call("SelectSeed", name) end end}
			b.UIStroke.Color = Config.RarityColor(d.Rarity)
			b.UIStroke.Thickness = sel and 3 or 2
		end
	end
	if not any then
		label{Text = "No seeds - visit the NPC Market in the village square", TextSize = 15, Font = Enum.Font.GothamMedium, TextColor3 = C.sub, Size = UDim2.fromOffset(420, 50), Parent = hotList}
	end
end

------------------------------------------------------------------ events
DataUpdate.OnClientEvent:Connect(function(snap)
	data = snap
	timeOffset = snap.Now - os.time()
	ruLabel.Text = "Ru " .. fmt(snap.Ru)
	gemLabel.Text = "Gems " .. fmt(snap.Gems)
	renderHotbar()
	renderHeld()
	rerender()
end)

-- G drops one of the held item
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= Enum.KeyCode.G then return end
	dropHeld(false)
end)

Notify.OnClientEvent:Connect(function(text, kind) toast(text, kind) end)

TradeUpdate.OnClientEvent:Connect(function(msg)
	if msg.Type == "Request" then
		requestFrom = msg.FromUserId
		requestText.Text = msg.From .. " wants to trade with you!"
		requestPopup.Visible = true
		task.delay(20, function() if requestFrom == msg.FromUserId then requestPopup.Visible = false end end)
	elseif msg.Type == "State" then
		local first = tradeState == nil
		tradeState = msg
		local pets = {}
		for _, p in ipairs(msg.Mine.Pets) do table.insert(pets, p.Id) end
		myOffer = {Ru = msg.Mine.Ru, Crops = table.clone(msg.Mine.Crops), Seeds = table.clone(msg.Mine.Seeds), Eggs = table.clone(msg.Mine.Eggs), Pets = pets}
		if first then currentTab.Trade = "Offer" end
		if openName ~= "Trade" then openPanel("Trade") else rerender() end
	elseif msg.Type == "Closed" then
		tradeState = nil
		myOffer = {Ru = 0, Crops = {}, Seeds = {}, Eggs = {}, Pets = {}}
		toast(msg.Reason, string.find(msg.Reason or "", "complete") and "success" or "info")
		if openName == "Trade" then closePanel() end
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt.Name == "OpenPrompt" then
		local m = prompt:FindFirstAncestorOfClass("Model")
		if m and m.Name == "Market" then openPanel("Market") elseif m and m.Name == "GemStore" then openPanel("GemStore") end
	elseif prompt.Name == "NestPrompt" then
		local plot = prompt:FindFirstAncestorOfClass("Model")
		if plot and plot:GetAttribute("OwnerUserId") == player.UserId then openPanel("Breed") else toast("That's not your nest!", "error") end
	end
end)

-- live countdown for the nest
task.spawn(function()
	while true do
		task.wait(1)
		if openName == "Breed" and data and data.Breeding and breedTimerLabel then
			local left = data.Breeding.EndsAt - (os.time() + timeOffset)
			if left <= 0 and breedTimerLabel.Text ~= "Ready to hatch!" then rerender()
			elseif left > 0 then breedTimerLabel.Text = string.format("%d:%02d", left // 60, left % 60) end
		end
	end
end)
