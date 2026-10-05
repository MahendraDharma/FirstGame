-- Minimal Roblox API mock for running the model builders outside Studio.
local Mock = {}

------------------------------------------------------------------ Vector3
local V3 = {}
V3.__index = function(t, k)
	if k == "Unit" then
		local m = math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
		return V3.new(t.X / m, t.Y / m, t.Z / m)
	elseif k == "Magnitude" then
		return math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
	end
	return V3[k]
end
function V3.new(x, y, z)
	x, y, z = x or 0, y or 0, z or 0
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number", "Vector3.new expects numbers")
	return setmetatable({X = x, Y = y, Z = z, __type = "Vector3"}, V3)
end
V3.__add = function(a, b) return V3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3.__sub = function(a, b) return V3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V3.__unm = function(a) return V3.new(-a.X, -a.Y, -a.Z) end
V3.__mul = function(a, b)
	if type(a) == "number" then a, b = b, a end
	if type(b) == "number" then return V3.new(a.X * b, a.Y * b, a.Z * b) end
	return V3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b)
	if type(b) == "number" then return V3.new(a.X / b, a.Y / b, a.Z / b) end
	return V3.new(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
function V3:Min(o) return V3.new(math.min(self.X, o.X), math.min(self.Y, o.Y), math.min(self.Z, o.Z)) end
function V3:Max(o) return V3.new(math.max(self.X, o.X), math.max(self.Y, o.Y), math.max(self.Z, o.Z)) end
function V3:Cross(o) return V3.new(self.Y * o.Z - self.Z * o.Y, self.Z * o.X - self.X * o.Z, self.X * o.Y - self.Y * o.X) end
function V3:Dot(o) return self.X * o.X + self.Y * o.Y + self.Z * o.Z end
V3.zero = V3.new(0, 0, 0)
V3.one = V3.new(1, 1, 1)

------------------------------------------------------------------ CFrame (columns = X, Y, Z axes)
local CF = {}
CF.__index = function(t, k)
	if k == "Position" or k == "p" then return t.pos end
	if k == "Rotation" then return CF.raw(V3.zero, t.x, t.y, t.z) end
	if k == "RightVector" or k == "XVector" then return t.x end
	if k == "UpVector" or k == "YVector" then return t.y end
	if k == "ZVector" then return t.z end
	if k == "LookVector" then return -t.z end
	return CF[k]
end
function CF.raw(pos, x, y, z)
	return setmetatable({pos = pos, x = x, y = y, z = z, __type = "CFrame"}, CF)
end
function CF.new(a, b, c)
	if a == nil then return CF.raw(V3.zero, V3.new(1, 0, 0), V3.new(0, 1, 0), V3.new(0, 0, 1)) end
	if type(a) == "table" then return CF.raw(a, V3.new(1, 0, 0), V3.new(0, 1, 0), V3.new(0, 0, 1)) end
	return CF.raw(V3.new(a, b, c), V3.new(1, 0, 0), V3.new(0, 1, 0), V3.new(0, 0, 1))
end
local function rot(x, y, z) return CF.raw(V3.zero, x, y, z) end
local function Rx(a) local c, s = math.cos(a), math.sin(a) return rot(V3.new(1, 0, 0), V3.new(0, c, s), V3.new(0, -s, c)) end
local function Ry(a) local c, s = math.cos(a), math.sin(a) return rot(V3.new(c, 0, -s), V3.new(0, 1, 0), V3.new(s, 0, c)) end
local function Rz(a) local c, s = math.cos(a), math.sin(a) return rot(V3.new(c, s, 0), V3.new(-s, c, 0), V3.new(0, 0, 1)) end
function CF.Angles(x, y, z)
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number", "CFrame.Angles expects 3 numbers")
	return Rx(x) * Ry(y) * Rz(z)
end
function CF.lookAt(pos, target, up)
	up = up or V3.new(0, 1, 0)
	local look = (target - pos).Unit
	local z = -look
	local x = up:Cross(z).Unit
	local y = z:Cross(x)
	return CF.raw(pos, x, y, z)
end
function CF.fromMatrix(pos, vx, vy, vz)
	vz = vz or vx:Cross(vy).Unit
	return CF.raw(pos, vx, vy, vz)
end
local function apply(c, v) return c.x * v.X + c.y * v.Y + c.z * v.Z end
CF.__mul = function(a, b)
	if getmetatable(b) == CF then
		return CF.raw(a.pos + apply(a, b.pos), apply(a, b.x), apply(a, b.y), apply(a, b.z))
	end
	assert(getmetatable(b) == V3, "CFrame * expects CFrame or Vector3")
	return a.pos + apply(a, b)
end
CF.__add = function(a, v) return CF.raw(a.pos + v, a.x, a.y, a.z) end
CF.__sub = function(a, v) return CF.raw(a.pos - v, a.x, a.y, a.z) end
function CF:PointToWorldSpace(v) return self * v end

------------------------------------------------------------------ Color3
local C3 = {}
C3.__index = C3
function C3.new(r, g, b) return setmetatable({R = r or 0, G = g or 0, B = b or 0, __type = "Color3"}, C3) end
function C3.fromRGB(r, g, b) return C3.new(r / 255, g / 255, b / 255) end
function C3.fromHex(h)
	h = h:gsub("#", "")
	assert(#h == 6, "bad hex colour " .. h)
	local r, g, b = tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16)
	assert(r and g and b, "bad hex colour " .. h)
	return C3.fromRGB(r, g, b)
end
function C3:Lerp(o, t) return C3.new(self.R + (o.R - self.R) * t, self.G + (o.G - self.G) * t, self.B + (o.B - self.B) * t) end
function C3:ToHex() return string.format("%02X%02X%02X", self.R * 255, self.G * 255, self.B * 255) end

------------------------------------------------------------------ Enum
local KNOWN = {
	Material = {"SmoothPlastic", "Plastic", "Neon", "Glass", "Foil", "Metal", "Wood", "WoodPlanks", "Slate", "Grass", "Ground", "Fabric", "Leather", "ForceField", "Sand", "Cobblestone", "LeafyGrass"},
	PartType = {"Ball", "Block", "Cylinder", "Wedge", "CornerWedge"},
	MeshType = {"Sphere", "Brick", "Cylinder", "Wedge", "FileMesh"},
	SurfaceType = {"Smooth"},
	NormalId = {"Top", "Bottom", "Front", "Back", "Left", "Right"},
}
local Enum = {}
for cat, list in pairs(KNOWN) do
	local t = {}
	for _, n in ipairs(list) do t[n] = {Name = n, EnumType = cat, __type = "EnumItem"} end
	Enum[cat] = setmetatable(t, {__index = function(_, k) error("Unknown Enum." .. cat .. "." .. tostring(k), 2) end})
end
setmetatable(Enum, {__index = function(_, k) error("Unknown Enum category " .. tostring(k), 2) end})

------------------------------------------------------------------ Instances
local CLASSES = {
	Model = {"Name", "PrimaryPart", "Parent"},
	Part = {"Name", "Size", "CFrame", "Color", "Material", "TopSurface", "BottomSurface", "Anchored", "CanCollide", "CanTouch", "CanQuery", "Parent", "Shape", "Transparency", "Massless", "CastShadow"},
	SpecialMesh = {"MeshType", "Scale", "Parent"},
	WeldConstraint = {"Part0", "Part1", "Parent"},
	PointLight = {"Color", "Range", "Brightness", "Shadows", "Parent"},
	ParticleEmitter = {"Color", "LightEmission", "LightInfluence", "Size", "Transparency", "Rate", "Lifetime", "Speed", "SpreadAngle", "EmissionDirection", "Acceleration", "Drag", "RotSpeed", "Texture", "Parent"},
	Attachment = {"Position", "Parent", "Name"},
	Beam = {"Attachment0", "Attachment1", "Color", "LightEmission", "Width0", "Width1", "CurveSize0", "CurveSize1", "Segments", "FaceCamera", "Parent"},
}
CLASSES.WedgePart = CLASSES.Part
CLASSES.CornerWedgePart = CLASSES.Part
local PARTS = {Part = true, WedgePart = true, CornerWedgePart = true}

local Inst = {}
local function newInstance(class)
	local allowed = CLASSES[class]
	assert(allowed, "Instance.new: unsupported class " .. tostring(class))
	local set = {}
	for _, p in ipairs(allowed) do set[p] = true end
	local data = {ClassName = class, Name = class, _children = {}, _attrs = {}}
	if PARTS[class] then
		data.Size = V3.new(4, 1, 2)
		data.CFrame = CF.new()
		data.Transparency = 0
	end
	local obj = {}
	setmetatable(obj, {
		__index = function(_, k)
			if k == "Position" and PARTS[class] then return data.CFrame.pos end
			if Inst[k] then return Inst[k] end
			if data[k] ~= nil then return data[k] end
			for _, c in ipairs(data._children) do if c.Name == k then return c end end
			return nil
		end,
		__newindex = function(_, k, v)
			assert(set[k], class .. " has no settable property '" .. tostring(k) .. "'")
			if k == "Parent" then
				if data.Parent then
					local sib = rawget(data.Parent, "__data")._children
					for i, c in ipairs(sib) do if c == obj then table.remove(sib, i) break end end
				end
				if v then table.insert(rawget(v, "__data")._children, obj) end
			end
			if k == "Size" and PARTS[class] then
				assert(v.X == v.X and v.Y == v.Y and v.Z == v.Z, "NaN size")
				assert(v.X > 0 and v.Y > 0 and v.Z > 0, "non-positive size on " .. tostring(data.Name))
			end
			if k == "CFrame" then
				local p = v.pos
				assert(p.X == p.X and p.Y == p.Y and p.Z == p.Z, "NaN position on " .. tostring(data.Name))
			end
			data[k] = v
		end,
	})
	rawset(obj, "__data", data)
	return obj
end
function Inst:IsA(c)
	local cls = self.ClassName
	if c == cls then return true end
	if c == "BasePart" and PARTS[cls] then return true end
	if c == "Light" and cls == "PointLight" then return true end
	return false
end
function Inst:GetChildren() return table.clone(rawget(self, "__data")._children) end
function Inst:GetDescendants()
	local out = {}
	local function walk(o)
		for _, c in ipairs(rawget(o, "__data")._children) do
			table.insert(out, c)
			walk(c)
		end
	end
	walk(self)
	return out
end
function Inst:FindFirstChild(n)
	for _, c in ipairs(rawget(self, "__data")._children) do if c.Name == n then return c end end
	return nil
end
function Inst:SetAttribute(k, v) rawget(self, "__data")._attrs[k] = v end
function Inst:GetAttribute(k) return rawget(self, "__data")._attrs[k] end
function Inst:Destroy() self.Parent = nil end
function Inst:GetBoundingBox()
	local lo, hi = V3.new(math.huge, math.huge, math.huge), V3.new(-math.huge, -math.huge, -math.huge)
	for _, p in ipairs(self:GetDescendants()) do
		if p:IsA("BasePart") then
			local h = p.Size / 2
			for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
				local w = p.CFrame * V3.new(h.X * sx, h.Y * sy, h.Z * sz)
				lo = lo:Min(w)
				hi = hi:Max(w)
			end end end
		end
	end
	return CF.new((lo + hi) / 2), hi - lo
end

------------------------------------------------------------------ globals
local function seq(...) return {__type = "Sequence", ...} end
Mock.globals = {
	Vector3 = V3,
	CFrame = CF,
	Color3 = C3,
	Enum = Enum,
	Instance = {new = newInstance},
	Vector2 = {new = function(x, y) return {X = x, Y = y} end},
	ColorSequence = {new = seq},
	NumberSequence = {new = seq},
	NumberSequenceKeypoint = {new = function(t, v) return {Time = t, Value = v} end},
	NumberRange = {new = function(a, b) return {Min = a, Max = b or a} end},
	typeof = function(v)
		if type(v) == "table" and rawget(v, "__type") then return rawget(v, "__type") end
		if type(v) == "table" and rawget(v, "__data") then return "Instance" end
		return type(v)
	end,
}

return Mock
