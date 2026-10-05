-- Dragon Isle Farm: Build Mode - rearrange your farm on a grid, Growtopia style.
-- Studio path: StarterPlayer.StarterPlayerScripts.BuildMode (LocalScript)
-- Opened from the "Build" side button (ClientUI fires MainUI.ToggleBuild). This script only draws the grid,
-- the palette and a preview; every place / move / remove / purchase is checked by GameServer.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Grid = require(Shared:WaitForChild("FarmGrid"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Request = Remotes:WaitForChild("Request")
local DataUpdate = Remotes:WaitForChild("DataUpdate")
local mainUI = player:WaitForChild("PlayerGui"):WaitForChild("MainUI")
local toggleEvent = mainUI:WaitForChild("ToggleBuild")

local fmt = Config.FormatNumber
local C = {
	bg = Color3.fromRGB(45, 32, 24), row = Color3.fromRGB(78, 58, 42), text = Color3.fromRGB(255, 244, 225),
	sub = Color3.fromRGB(215, 195, 165), green = Color3.fromRGB(70, 165, 80), red = Color3.fromRGB(195, 70, 60),
	blue = Color3.fromRGB(60, 125, 205), gold = Color3.fromRGB(225, 170, 40), grey = Color3.fromRGB(105, 95, 85),
}
local GOOD, BAD, PICK = Color3.fromRGB(90, 230, 110), Color3.fromRGB(240, 80, 70), Color3.fromRGB(255, 190, 60)

local data = nil      -- latest DataUpdate snapshot
local active = false
local tool = nil      -- {Mode = "place", T = type} | {Mode = "move", Id = id or nil} | {Mode = "remove"}
local rotation = 0
local tab = "Place"
local plot = nil

------------------------------------------------------------------ ui helpers (same look as ClientUI)
local function new(class, props, children)
	local o = Instance.new(class)
	local parent = nil
	for k, v in pairs(props or {}) do if k == "Parent" then parent = v else o[k] = v end end
	for _, c in ipairs(children or {}) do c.Parent = o end
	if parent then o.Parent = parent end
	return o
end
local function corner(r) return new("UICorner", {CornerRadius = UDim.new(0, r or 8)}) end
local function stroke(c, t) return new("UIStroke", {Color = c, Thickness = t or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}) end
local function label(p)
	p.BackgroundTransparency = 1
	p.Font = p.Font or Enum.Font.FredokaOne
	p.TextColor3 = p.TextColor3 or C.text
	return new("TextLabel", p)
end
local function button(o)
	local b = new("TextButton", {
		Text = o.Text, Font = Enum.Font.FredokaOne, TextSize = o.TextSize or 15, TextColor3 = Color3.new(1, 1, 1), TextWrapped = true,
		BackgroundColor3 = o.Color or C.blue, Size = o.Size, Position = o.Position or UDim2.new(), LayoutOrder = o.LayoutOrder or 0,
		AutoButtonColor = true, Parent = o.Parent,
	}, {corner(8), stroke(Color3.fromRGB(20, 14, 10), 1.5)})
	if o.Callback then b.MouseButton1Click:Connect(o.Callback) end
	return b
end

------------------------------------------------------------------ panel
local gui = new("ScreenGui", {Name = "BuildUI", ResetOnSpawn = false, Enabled = false, Parent = player:WaitForChild("PlayerGui")})
local panel = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.new(0.94, 0, 0, 176),
	BackgroundColor3 = C.bg, BackgroundTransparency = 0.08, Parent = gui},
	{corner(12), stroke(C.gold, 2.5), new("UISizeConstraint", {MaxSize = Vector2.new(780, 176)})})
label{Text = "Build Mode", TextSize = 20, Size = UDim2.fromOffset(130, 30), Position = UDim2.fromOffset(12, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = panel}
local status = label{Text = "", TextSize = 14, Font = Enum.Font.GothamMedium, TextColor3 = C.sub, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.new(1, -520, 0, 34), Position = UDim2.fromOffset(140, 4), Parent = panel}
local tools = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 6), Size = UDim2.fromOffset(370, 32), BackgroundTransparency = 1, Parent = panel},
	{new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})})
local tabs = new("Frame", {Position = UDim2.fromOffset(12, 42), Size = UDim2.new(1, -24, 0, 28), BackgroundTransparency = 1, Parent = panel},
	{new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})})
local list = new("ScrollingFrame", {Position = UDim2.fromOffset(12, 76), Size = UDim2.new(1, -24, 0, 92), BackgroundTransparency = 1, ScrollBarThickness = 5,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X, Parent = panel},
	{new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})})

local function clear(frame)
	for _, c in ipairs(frame:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
end

local messageAt = 0 -- server messages stay up for a few seconds before the tool hint comes back
local function setStatus(text, bad, isMessage)
	status.Text = text or ""
	status.TextColor3 = bad and C.red or C.sub
	if isMessage then messageAt = os.clock() end
end

local function call(action, ...)
	local ok, res = pcall(Request.InvokeServer, Request, action, ...)
	if not ok or not res then setStatus("Connection error", true, true) return false end
	if res.Msg then setStatus(res.Msg, not res.Ok, true) end
	return res.Ok
end

------------------------------------------------------------------ what you can place
local function placedCount(t)
	local n = 0
	if data and data.Layout then
		for _, it in pairs(data.Layout.Items) do if it.T == t then n += 1 end end
	end
	return n
end

-- {type, how many are not on the farm yet}
local function inventory()
	local out = {}
	if not data or not data.Layout then return out end
	local soil = (data.SoilSlots or Config.BaseSoil) - placedCount("Soil")
	if soil > 0 then table.insert(out, {"Soil", soil}) end
	for _, name in ipairs(Config.GemItemOrder) do
		if Config.FarmItemSize[name] and (data.Items[name] or 0) > 0 and placedCount(name) == 0 then table.insert(out, {name, 1}) end
	end
	for _, name in ipairs(Config.BlockOrder) do
		local n = (data.Blocks and data.Blocks[name] or 0) - placedCount(name)
		if n > 0 then table.insert(out, {name, n}) end
	end
	return out
end

local renderPanel

local function card(text, color, selected, order, callback)
	local b = button{Text = text, TextSize = 13, Color = selected and C.gold or C.row, Size = UDim2.fromOffset(112, 84), LayoutOrder = order, Parent = list, Callback = callback}
	b.UIStroke.Color = color or C.grey
	b.UIStroke.Thickness = selected and 3 or 2
	return b
end

renderPanel = function()
	if not active then return end
	clear(tabs)
	for i, name in ipairs({"Place", "Shop"}) do
		button{Text = name, TextSize = 14, Color = tab == name and C.gold or C.grey, Size = UDim2.fromOffset(96, 28), LayoutOrder = i, Parent = tabs,
			Callback = function() tab = name; renderPanel() end}
	end
	clear(tools)
	local mode = tool and tool.Mode
	button{Text = "Move", Color = mode == "move" and C.gold or C.blue, Size = UDim2.fromOffset(80, 32), LayoutOrder = 1, Parent = tools,
		Callback = function() tool = mode == "move" and nil or {Mode = "move"}; renderPanel() end}
	button{Text = "Remove", Color = mode == "remove" and C.gold or C.red, Size = UDim2.fromOffset(80, 32), LayoutOrder = 2, Parent = tools,
		Callback = function() tool = mode == "remove" and nil or {Mode = "remove"}; renderPanel() end}
	button{Text = "Rotate (R)", Color = C.grey, Size = UDim2.fromOffset(90, 32), LayoutOrder = 3, Parent = tools,
		Callback = function() rotation = (rotation + 1) % 4 end}
	button{Text = "Done", Color = C.green, Size = UDim2.fromOffset(80, 32), LayoutOrder = 4, Parent = tools,
		Callback = function() toggleEvent:Fire(false) end}
	clear(list)
	if not data then return end
	if tab == "Place" then
		local inv = inventory()
		for i, entry in ipairs(inv) do
			local t, n = entry[1], entry[2]
			local selected = tool and tool.Mode == "place" and tool.T == t
			card(string.format("%s\nx%d", t, n), t == "Soil" and Color3.fromRGB(105, 70, 45) or C.gold, selected, i, function()
				tool = selected and nil or {Mode = "place", T = t}
				renderPanel()
			end)
		end
		if #inv == 0 then
			label{Text = "Everything you own is on your farm. Buy soil and decorations in the Shop tab, or use Move to rearrange.",
				TextSize = 14, Font = Enum.Font.GothamMedium, TextColor3 = C.sub, TextWrapped = true, Size = UDim2.fromOffset(520, 80), Parent = list}
		end
	else
		local order = 0
		local slots = data.SoilSlots or Config.BaseSoil
		if slots < Config.MaxSoil then
			order += 1
			local price = Config.SoilPrice(slots)
			card(string.format("Soil #%d\n%s Ru", slots + 1, fmt(price)), Color3.fromRGB(105, 70, 45), false, order, function()
				call("BuySoil")
			end)
		end
		for _, name in ipairs(Config.BlockOrder) do
			order += 1
			local b = Config.Blocks[name]
			local owned = data.Blocks and data.Blocks[name] or 0
			card(string.format("%s\n%s Ru\n(have %d)", name, fmt(b.Price), owned), data.Ru >= b.Price and C.green or C.grey, false, order, function()
				call("BuyBlock", name, 1)
			end)
		end
	end
	-- hint for the current tool
	if os.clock() - messageAt < 3 then
		return
	elseif not tool then
		setStatus("Pick something to place, or use Move / Remove. R rotates.")
	elseif tool.Mode == "place" then
		setStatus("Click your farm to place " .. tool.T .. ". Click the card again to stop.")
	elseif tool.Mode == "move" then
		setStatus(tool.Id and "Click where it should go (R rotates)." or "Click something on your farm to pick it up.")
	else
		setStatus("Click something on your farm to put it back in your inventory.")
	end
end

------------------------------------------------------------------ grid overlay and preview (local parts only)
local overlay = nil
local ghost = nil

local function myPlot()
	for _, p in ipairs(workspace:WaitForChild("Plots"):GetChildren()) do
		if p:GetAttribute("OwnerUserId") == player.UserId then return p end
	end
	return nil
end

local function localPart(size, color, transparency, parent)
	return new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
		Material = Enum.Material.Neon, Size = size, Color = color, Transparency = transparency, Parent = parent})
end

local function floorTop() return plot.PrimaryPart.Size.Y / 2 end

local function drawOverlay()
	if overlay then overlay:Destroy() end
	overlay = new("Folder", {Name = "BuildGrid", Parent = workspace})
	local base, y, span = plot.PrimaryPart.CFrame, floorTop() + 0.66, Grid.CELL * Grid.SIZE
	for i = 0, Grid.SIZE do
		local o = -Grid.HALF + i * Grid.CELL
		localPart(Vector3.new(0.08, 0.04, span), Color3.new(1, 1, 1), 0.6, overlay).CFrame = base * CFrame.new(o, y, 0)
		localPart(Vector3.new(span, 0.04, 0.08), Color3.new(1, 1, 1), 0.6, overlay).CFrame = base * CFrame.new(0, y, o)
	end
	for key in pairs(Grid.Reserved) do
		local x, z = key // 100, key % 100
		localPart(Vector3.new(Grid.CELL - 0.3, 0.04, Grid.CELL - 0.3), BAD, 0.75, overlay).CFrame =
			base * CFrame.new(-Grid.HALF + Grid.CELL * (x + 0.5), y, -Grid.HALF + Grid.CELL * (z + 0.5))
	end
	ghost = localPart(Vector3.one, GOOD, 0.55, overlay)
	ghost.Material = Enum.Material.ForceField
end

-- the farm cell under a screen point (ray hits the floor plane, so items never block it)
local function cellAt(ray)
	if not plot or not plot.PrimaryPart then return nil end
	local base = plot.PrimaryPart.CFrame
	local o, d = base:PointToObjectSpace(ray.Origin), base:VectorToObjectSpace(ray.Direction)
	if math.abs(d.Y) < 1e-4 then return nil end
	local t = (floorTop() - o.Y) / d.Y
	if t < 0 then return nil end
	local x, z = Grid.cellAt(o + d * t)
	if x < 0 or z < 0 or x >= Grid.SIZE or z >= Grid.SIZE then return nil end
	return x, z
end

-- what a click at (x, z) would do: {T, X, Z, R, ok, id}
local function intent(x, z)
	local items = data and data.Layout and data.Layout.Items
	if not items or not tool then return nil end
	if tool.Mode == "place" or (tool.Mode == "move" and tool.Id) then
		local t = tool.Mode == "place" and tool.T or items[tool.Id] and items[tool.Id].T
		if not t then return nil end
		local r = t == "Nest" and 0 or rotation
		local ax, az = Grid.anchor(t, r, x, z)
		local ok = Grid.fits(items, t, ax, az, r, tool.Id)
		return {T = t, X = ax, Z = az, R = r, ok = ok}
	end
	local id = Grid.occupancy(items)[Grid.key(x, z)]
	if not id then return nil end
	local it = items[id]
	local ok = tool.Mode == "move" or (it.T ~= "Nest" and not (it.T == "Soil" and data.Tiles[tostring(it.I)]))
	return {T = it.T, X = it.X, Z = it.Z, R = it.R, ok = ok, id = id}
end

local function showGhost(i)
	if not ghost then return end
	if not i then ghost.Transparency = 1 return end
	local w, h = Grid.footprint(i.T, i.R)
	ghost.Size = Vector3.new(w * Grid.CELL - 0.3, 0.8, h * Grid.CELL - 0.3)
	ghost.CFrame = plot.PrimaryPart.CFrame * Grid.toLocal(i.T, i.X, i.Z, 0) * CFrame.new(0, floorTop() + 0.4, 0)
	if i.id then
		-- picking something up (orange) or removing it (red; grey when it can't be removed)
		ghost.Color = tool.Mode == "move" and PICK or (i.ok and BAD or Color3.fromRGB(150, 150, 150))
	else
		ghost.Color = i.ok and GOOD or BAD
	end
	ghost.Transparency = 0.45
end

RunService.RenderStepped:Connect(function()
	if not active or not plot then return end
	local cam = workspace.CurrentCamera
	local m = UserInputService:GetMouseLocation()
	local x, z = cellAt(cam:ViewportPointToRay(m.X, m.Y))
	showGhost(x and intent(x, z) or nil)
end)

local function click(screenPos)
	local x, z = cellAt(workspace.CurrentCamera:ScreenPointToRay(screenPos.X, screenPos.Y))
	if not x or not tool then return end
	local i = intent(x, z)
	if not i then return end
	if tool.Mode == "place" then
		call("BuildPlace", tool.T, i.X, i.Z, i.R)
	elseif tool.Mode == "move" then
		if tool.Id then
			if call("BuildMove", tool.Id, i.X, i.Z, i.R) then tool = {Mode = "move"} end
		else
			tool = {Mode = "move", Id = i.id}
			rotation = i.R
		end
		renderPanel()
	elseif tool.Mode == "remove" then
		call("BuildRemove", i.id)
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if not active or processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		click(input.Position)
	elseif input.KeyCode == Enum.KeyCode.R then
		rotation = (rotation + 1) % 4
	end
end)

------------------------------------------------------------------ open / close
local function setActive(on)
	if on then
		plot = myPlot()
		if not plot then return end
	end
	active = on
	gui.Enabled = on
	mainUI:SetAttribute("Building", on)
	tool = nil
	if on then
		drawOverlay()
		call("BuildSync") -- server pushes a fresh snapshot
		renderPanel()
	else
		if overlay then overlay:Destroy() end
		overlay, ghost = nil, nil
	end
end

toggleEvent.Event:Connect(function(on)
	if on == nil then on = not active end
	setActive(on)
end)

DataUpdate.OnClientEvent:Connect(function(snap)
	data = snap
	if active then
		-- stop placing a type you've run out of
		if tool and tool.Mode == "place" then
			local left = false
			for _, entry in ipairs(inventory()) do if entry[1] == tool.T then left = true end end
			if not left then tool = nil end
		end
		renderPanel()
	end
end)
