--!nonstrict
-- Snowball Smash: builds the 3D models for one chunk of the endless course
-- (slope, rails, obstacles, pads, coins, distance signs) from CourseGen specs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CourseGen = require(Shared:WaitForChild("CourseGen"))

local CourseBuilder = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local SNOW_A = rgb(244, 249, 255)
local SNOW_B = rgb(214, 232, 252)
local ICE = rgb(150, 215, 255)
local WOOD = rgb(140, 88, 52)
local WOOD_DARK = rgb(98, 60, 36)
local PINE = rgb(46, 150, 84)
local PINE_DARK = rgb(30, 118, 70)
local RED = rgb(230, 52, 60)
local WHITE = rgb(255, 255, 255)
local YELLOW = rgb(255, 204, 40)
local ROCK = rgb(150, 168, 196)

local WIDTH = CourseGen.Width
local TAN = math.tan(math.rad(CourseGen.AngleDeg))

local function part(parent: Instance, props)
	local p = Instance.new(props.Class or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Color = props.Color or WHITE
	p.Size = props.Size
	p.CFrame = props.CFrame
	if props.Shape then
		p.Shape = props.Shape
	end
	if props.Transparency then
		p.Transparency = props.Transparency
	end
	if props.Reflectance then
		p.Reflectance = props.Reflectance
	end
	if props.CanCollide ~= nil then
		p.CanCollide = props.CanCollide
	end
	if props.CastShadow ~= nil then
		p.CastShadow = props.CastShadow
	end
	p.CanTouch = false
	p.Name = props.Name or "Part"
	p.Parent = parent
	return p
end

local function model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

----------------------------------------------------------------------
-- Obstacle models (cf = upright frame at the base, facing uphill)
----------------------------------------------------------------------
local Builders = {}

function Builders.Snowman(m, cf, o)
	cf = cf * CFrame.Angles(0, math.pi + (o.Rot - math.pi) * 0.12, 0)
	part(m, { Shape = Enum.PartType.Ball, Size = Vector3.new(4.4, 4.4, 4.4), CFrame = cf * CFrame.new(0, 2.2, 0), Color = SNOW_A, Material = Enum.Material.Snow })
	part(m, { Shape = Enum.PartType.Ball, Size = Vector3.new(3.3, 3.3, 3.3), CFrame = cf * CFrame.new(0, 5.4, 0), Color = SNOW_A, Material = Enum.Material.Snow })
	part(m, { Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2.4, 2.4), CFrame = cf * CFrame.new(0, 7.9, 0), Color = SNOW_A, Material = Enum.Material.Snow })
	part(m, { Size = Vector3.new(0.4, 0.4, 1.4), CFrame = cf * CFrame.new(0, 7.9, -1.6), Color = rgb(255, 140, 30) })
	part(m, { Size = Vector3.new(0.35, 0.35, 0.2), CFrame = cf * CFrame.new(-0.45, 8.3, -1.1), Color = rgb(20, 20, 20) })
	part(m, { Size = Vector3.new(0.35, 0.35, 0.2), CFrame = cf * CFrame.new(0.45, 8.3, -1.1), Color = rgb(20, 20, 20) })
	part(m, { Size = Vector3.new(2.6, 0.3, 2.6), CFrame = cf * CFrame.new(0, 9, 0), Color = rgb(30, 30, 36) })
	part(m, { Size = Vector3.new(1.7, 1.6, 1.7), CFrame = cf * CFrame.new(0, 9.9, 0), Color = rgb(30, 30, 36) })
	local scarf = ({ RED, rgb(70, 130, 255), rgb(60, 200, 90), YELLOW })[o.Variant]
	part(m, { Size = Vector3.new(2.8, 0.6, 2.8), CFrame = cf * CFrame.new(0, 6.8, 0), Color = scarf })
end

function Builders.Fence(m, cf)
	for i = -1, 1 do
		part(m, { Size = Vector3.new(1, 4, 1), CFrame = cf * CFrame.new(i * 6, 2, 0), Color = WOOD_DARK, Material = Enum.Material.Wood })
	end
	part(m, { Size = Vector3.new(13, 0.8, 0.6), CFrame = cf * CFrame.new(0, 2.8, 0), Color = WOOD, Material = Enum.Material.WoodPlanks })
	part(m, { Size = Vector3.new(13, 0.8, 0.6), CFrame = cf * CFrame.new(0, 1.4, 0), Color = WOOD, Material = Enum.Material.WoodPlanks })
	part(m, { Size = Vector3.new(13.4, 0.3, 1), CFrame = cf * CFrame.new(0, 3.35, 0), Color = SNOW_A, Material = Enum.Material.Snow })
end

function Builders.Gifts(m, cf, o)
	cf = cf * CFrame.Angles(0, (o.Rot - math.pi) * 0.15, 0)
	local colors = { RED, rgb(60, 190, 90), rgb(70, 130, 255), rgb(190, 90, 240) }
	local boxes = { { -1.6, 0, 3.4, 0 }, { 1.6, 0.6, 2.6, 0 }, { 0.8, 0, 2, 3.4 } }
	for i, b in boxes do
		local size = b[3]
		local boxCF = cf * CFrame.new(b[1], b[4] + size / 2, b[2])
		part(m, { Size = Vector3.new(size, size, size), CFrame = boxCF, Color = colors[(i + o.Variant) % #colors + 1] })
		part(m, { Size = Vector3.new(size + 0.1, size + 0.1, 0.5), CFrame = boxCF, Color = YELLOW })
		part(m, { Size = Vector3.new(0.5, size + 0.1, size + 0.1), CFrame = boxCF, Color = YELLOW })
	end
end

function Builders.Penguin(m, cf, o)
	cf = cf * CFrame.Angles(0, math.pi + (o.Rot - math.pi) * 0.2, 0)
	local black = rgb(30, 34, 46)
	local orange = rgb(255, 160, 30)
	part(m, { Shape = Enum.PartType.Ball, Size = Vector3.new(2.8, 2.8, 2.8), CFrame = cf * CFrame.new(0, 1.6, 0), Color = black })
	part(m, { Shape = Enum.PartType.Ball, Size = Vector3.new(2.1, 2.3, 2.1), CFrame = cf * CFrame.new(0, 1.5, -0.45), Color = WHITE })
	part(m, { Shape = Enum.PartType.Ball, Size = Vector3.new(1.9, 1.9, 1.9), CFrame = cf * CFrame.new(0, 3.5, 0), Color = black })
	part(m, { Size = Vector3.new(0.5, 0.35, 0.8), CFrame = cf * CFrame.new(0, 3.4, -1.1), Color = orange })
	part(m, { Size = Vector3.new(0.7, 0.25, 0.9), CFrame = cf * CFrame.new(-0.6, 0.15, -0.4), Color = orange })
	part(m, { Size = Vector3.new(0.7, 0.25, 0.9), CFrame = cf * CFrame.new(0.6, 0.15, -0.4), Color = orange })
end

local function pineTree(m, cf, s: number)
	part(m, { Size = Vector3.new(1.6, 4, 1.6) * s, CFrame = cf * CFrame.new(0, 2 * s, 0), Color = WOOD, Material = Enum.Material.Wood })
	local tiers = { { 8, 3 }, { 6.4, 2.8 }, { 4.6, 2.6 }, { 2.8, 2.4 } }
	local y = 4 * s
	for i, t in tiers do
		local w, h = t[1] * s, t[2] * s
		local rot = CFrame.Angles(0, math.rad(i * 12), 0)
		part(m, { Size = Vector3.new(w, h, w), CFrame = cf * CFrame.new(0, y + h / 2, 0) * rot, Color = if i % 2 == 0 then PINE_DARK else PINE, Material = Enum.Material.Grass })
		part(m, { Size = Vector3.new(w * 0.8, 0.5 * s, w * 0.8), CFrame = cf * CFrame.new(0, y + h + 0.1, 0) * rot, Color = SNOW_A, Material = Enum.Material.Snow })
		y += h * 0.85
	end
	part(m, { Size = Vector3.new(1.4, 1.4, 1.4) * s, CFrame = cf * CFrame.new(0, y + s, 0) * CFrame.Angles(0, 0, math.rad(45)), Color = YELLOW, Material = Enum.Material.Neon })
end
CourseBuilder.PineTree = pineTree

function Builders.Tree(m, cf, o)
	pineTree(m, cf * CFrame.Angles(0, o.Rot, 0), 1)
end

function Builders.IceWall(m, cf)
	for c = 0, 3 do
		for r = 0, 1 do
			part(m, { Size = Vector3.new(3.9, 3.9, 2), CFrame = cf * CFrame.new((c - 1.5) * 4, r * 4 + 2, 0), Color = ICE, Material = Enum.Material.Ice, Transparency = 0.25, Reflectance = 0.1 })
		end
	end
end

function Builders.SnowWall(m, cf, o)
	local colors = { rgb(120, 170, 255), rgb(90, 140, 240), rgb(150, 195, 255) }
	for r = 0, 2 do
		local offset = if r % 2 == 0 then 0 else 2
		for c = 0, 4 do
			part(m, { Size = Vector3.new(3.9, 2.4, 3), CFrame = cf * CFrame.new((c - 2) * 4 + offset - 1, r * 2.5 + 1.2, 0), Color = colors[(r + c + o.Variant) % 3 + 1], Material = Enum.Material.Glacier })
		end
	end
	part(m, { Size = Vector3.new(20.5, 0.6, 3.4), CFrame = cf * CFrame.new(0, 7.8, 0), Color = SNOW_A, Material = Enum.Material.Snow })
end

function Builders.IceTower(m, cf)
	for i = 0, 3 do
		local size = 5 - i * 0.7
		part(m, { Size = Vector3.new(size, 4, size), CFrame = cf * CFrame.new(0, i * 4 + 2, 0) * CFrame.Angles(0, math.rad(i * 20), 0), Color = ICE, Material = Enum.Material.Ice, Transparency = 0.2, Reflectance = 0.1 })
	end
	part(m, { Size = Vector3.new(1.6, 3, 1.6), CFrame = cf * CFrame.new(0, 17.5, 0) * CFrame.Angles(0, 0, math.rad(45)), Color = rgb(120, 230, 255), Material = Enum.Material.Neon })
end

function Builders.Cabin(m, cf, o)
	cf = cf * CFrame.Angles(0, if o.Variant % 2 == 0 then 0 else math.pi, 0)
	local W, D, H = 14, 12, 8
	for i = 0, H / 2 - 1 do
		local y = i * 2 + 1
		local c = if i % 2 == 0 then WOOD else WOOD_DARK
		part(m, { Size = Vector3.new(W, 2, 1.4), CFrame = cf * CFrame.new(0, y, -D / 2), Color = c, Material = Enum.Material.Wood })
		part(m, { Size = Vector3.new(W, 2, 1.4), CFrame = cf * CFrame.new(0, y, D / 2), Color = c, Material = Enum.Material.Wood })
		part(m, { Size = Vector3.new(1.4, 2, D), CFrame = cf * CFrame.new(-W / 2, y, 0), Color = c, Material = Enum.Material.Wood })
		part(m, { Size = Vector3.new(1.4, 2, D), CFrame = cf * CFrame.new(W / 2, y, 0), Color = c, Material = Enum.Material.Wood })
	end
	part(m, { Size = Vector3.new(3, 5, 0.4), CFrame = cf * CFrame.new(0, 2.5, -D / 2 - 0.6), Color = rgb(200, 60, 50) })
	part(m, { Size = Vector3.new(2.6, 2.4, 0.3), CFrame = cf * CFrame.new(-4.2, 4.6, -D / 2 - 0.6), Color = rgb(255, 220, 120), Material = Enum.Material.Neon })
	part(m, { Size = Vector3.new(2.6, 2.4, 0.3), CFrame = cf * CFrame.new(4.2, 4.6, -D / 2 - 0.6), Color = rgb(255, 220, 120), Material = Enum.Material.Neon })
	local roofAngle = math.rad(32)
	for _, side in { -1, 1 } do
		local roofCF = cf * CFrame.new(side * W / 4, H + 2.2, 0) * CFrame.Angles(0, 0, side * -roofAngle)
		part(m, { Size = Vector3.new(W / 2 / math.cos(roofAngle) + 1.6, 1, D + 2.4), CFrame = roofCF, Color = rgb(196, 44, 50) })
		part(m, { Size = Vector3.new(W / 2 / math.cos(roofAngle) + 1.2, 0.6, D + 2.6), CFrame = roofCF * CFrame.new(0, 0.75, 0), Color = SNOW_A, Material = Enum.Material.Snow })
	end
	part(m, { Size = Vector3.new(1.8, 4, 1.8), CFrame = cf * CFrame.new(3, H + 4.5, 2), Color = rgb(150, 70, 60), Material = Enum.Material.Brick })
end

-- Halloween ------------------------------------------------------------
function Builders.Pumpkin(m, cf, o)
	cf = cf * CFrame.Angles(0, math.pi + (o.Rot - math.pi) * 0.25, 0)
	local orange = rgb(255, 130, 20)
	for i = -2, 2 do
		part(m, { Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 4.6, 4.6), CFrame = cf * CFrame.new(i * 0.85, 2.3, 0) * CFrame.Angles(0, i * 0.35, 0), Color = if i % 2 == 0 then orange else rgb(240, 110, 15) })
	end
	part(m, { Size = Vector3.new(0.7, 1.4, 0.7), CFrame = cf * CFrame.new(0, 4.9, 0) * CFrame.Angles(0, 0, 0.3), Color = rgb(70, 120, 40) })
	-- glowing face
	local glow = rgb(255, 230, 90)
	part(m, { Size = Vector3.new(0.9, 0.7, 0.3), CFrame = cf * CFrame.new(-0.9, 2.9, -2.25) * CFrame.Angles(0, 0, math.rad(20)), Color = glow, Material = Enum.Material.Neon })
	part(m, { Size = Vector3.new(0.9, 0.7, 0.3), CFrame = cf * CFrame.new(0.9, 2.9, -2.25) * CFrame.Angles(0, 0, math.rad(-20)), Color = glow, Material = Enum.Material.Neon })
	part(m, { Size = Vector3.new(2.2, 0.5, 0.3), CFrame = cf * CFrame.new(0, 1.7, -2.25), Color = glow, Material = Enum.Material.Neon })
	part(m, { Shape = Enum.PartType.Ball, Size = Vector3.new(5, 0.6, 5), CFrame = cf * CFrame.new(0, 4.4, 0), Color = SNOW_A, Material = Enum.Material.Snow })
end

function Builders.GhostSnowman(m, cf, o)
	cf = cf * CFrame.Angles(0, math.pi + (o.Rot - math.pi) * 0.12, 0)
	local ghost = rgb(225, 235, 255)
	for _, b in { { 4.4, 2.2 }, { 3.3, 5.4 }, { 2.4, 7.9 } } do
		part(m, { Shape = Enum.PartType.Ball, Size = Vector3.one * b[1], CFrame = cf * CFrame.new(0, b[2], 0), Color = ghost, Material = Enum.Material.SmoothPlastic, Transparency = 0.35 })
	end
	local eye = rgb(140, 255, 120)
	part(m, { Size = Vector3.new(0.45, 0.5, 0.2), CFrame = cf * CFrame.new(-0.45, 8.2, -1.1), Color = eye, Material = Enum.Material.Neon })
	part(m, { Size = Vector3.new(0.45, 0.5, 0.2), CFrame = cf * CFrame.new(0.45, 8.2, -1.1), Color = eye, Material = Enum.Material.Neon })
	part(m, { Size = Vector3.new(0.7, 0.5, 0.2), CFrame = cf * CFrame.new(0, 7.4, -1.15), Color = rgb(30, 30, 40) })
	part(m, { Size = Vector3.new(2.6, 0.3, 2.6), CFrame = cf * CFrame.new(0, 9, 0), Color = rgb(30, 30, 36) })
	part(m, { Size = Vector3.new(1.7, 1.6, 1.7), CFrame = cf * CFrame.new(0, 9.9, 0), Color = rgb(30, 30, 36) })
	part(m, { Size = Vector3.new(1.8, 0.35, 1.8), CFrame = cf * CFrame.new(0, 9.35, 0), Color = rgb(255, 130, 20) })
end

-- Winter ---------------------------------------------------------------
function Builders.GiantPresent(m, cf, o)
	cf = cf * CFrame.Angles(0, (o.Rot - math.pi) * 0.2, 0)
	local wraps = { { RED, rgb(255, 215, 60) }, { rgb(40, 170, 80), RED }, { rgb(70, 130, 255), WHITE }, { rgb(190, 90, 240), rgb(255, 215, 60) } }
	local wrap = wraps[o.Variant]
	local box = part(m, { Size = Vector3.new(6, 6, 6), CFrame = cf * CFrame.new(0, 3, 0), Color = wrap[1] })
	part(m, { Size = Vector3.new(6.1, 6.1, 1.1), CFrame = box.CFrame, Color = wrap[2] })
	part(m, { Size = Vector3.new(1.1, 6.1, 6.1), CFrame = box.CFrame, Color = wrap[2] })
	-- bow on top
	for _, side in { -1, 1 } do
		part(m, { Shape = Enum.PartType.Ball, Size = Vector3.new(2.2, 1.4, 1.4), CFrame = cf * CFrame.new(side * 1, 6.6, 0) * CFrame.Angles(0, 0, side * 0.5), Color = wrap[2] })
	end
	part(m, { Shape = Enum.PartType.Ball, Size = Vector3.new(1.1, 1.1, 1.1), CFrame = cf * CFrame.new(0, 6.5, 0), Color = wrap[2], Material = Enum.Material.Neon })
	part(m, { Size = Vector3.new(6.2, 0.4, 6.2), CFrame = cf * CFrame.new(0, 6.15, 0), Color = SNOW_A, Material = Enum.Material.Snow })
end

function Builders.GingerHouse(m, cf, o)
	cf = cf * CFrame.Angles(0, if o.Variant % 2 == 0 then 0 else math.pi, 0)
	local ginger = rgb(196, 120, 60)
	local icing = WHITE
	part(m, { Size = Vector3.new(8, 6, 7), CFrame = cf * CFrame.new(0, 3, 0), Color = ginger, Material = Enum.Material.SmoothPlastic })
	part(m, { Size = Vector3.new(8.2, 0.5, 7.2), CFrame = cf * CFrame.new(0, 0.6, 0), Color = icing })
	-- door + windows
	part(m, { Size = Vector3.new(1.8, 3, 0.3), CFrame = cf * CFrame.new(0, 1.5, -3.55), Color = rgb(120, 60, 30) })
	for _, side in { -1, 1 } do
		part(m, { Size = Vector3.new(1.4, 1.4, 0.3), CFrame = cf * CFrame.new(side * 2.5, 3.8, -3.55), Color = rgb(255, 220, 120), Material = Enum.Material.Neon })
		part(m, { Size = Vector3.new(1.8, 0.3, 0.4), CFrame = cf * CFrame.new(side * 2.5, 3.0, -3.6), Color = icing })
	end
	-- iced roof
	local roofAngle = math.rad(35)
	for _, side in { -1, 1 } do
		local roofCF = cf * CFrame.new(side * 2.1, 7.3, 0) * CFrame.Angles(0, 0, side * -roofAngle)
		part(m, { Size = Vector3.new(5.6, 0.8, 8), CFrame = roofCF, Color = rgb(170, 95, 45) })
		part(m, { Size = Vector3.new(5.4, 0.4, 8.2), CFrame = roofCF * CFrame.new(0, 0.5, 0), Color = icing })
	end
	-- gumdrops + candy canes
	local drops = { RED, rgb(60, 200, 90), rgb(255, 215, 60), rgb(190, 90, 240) }
	for i = 0, 3 do
		part(m, { Shape = Enum.PartType.Ball, Size = Vector3.one * 0.8, CFrame = cf * CFrame.new(-3 + i * 2, 9.3 - math.abs(i - 1.5) * 0.4, 0), Color = drops[i + 1], Material = Enum.Material.Neon })
	end
	for _, side in { -1, 1 } do
		for k = 0, 3 do
			part(m, { Size = Vector3.new(0.6, 1, 0.6), CFrame = cf * CFrame.new(side * 4.6, k + 0.5, -3.8), Color = if k % 2 == 0 then RED else WHITE })
		end
	end
end

function Builders.Gate(m, cf)
	local w = WIDTH - 4
	for r = 0, 3 do
		local offset = if r % 2 == 0 then 0 else 3
		for c = 0, math.floor(w / 6) - 1 do
			local bx = -w / 2 + c * 6 + 3 + offset
			if bx < w / 2 - 2 then
				part(m, { Size = Vector3.new(5.9, 3.9, 6), CFrame = cf * CFrame.new(bx, r * 4 + 2, 0), Color = if (r + c) % 2 == 0 then SNOW_A else SNOW_B, Material = Enum.Material.Snow })
			end
		end
	end
	for c = 0, math.floor(w / 12) - 1 do
		part(m, { Size = Vector3.new(5, 4, 6), CFrame = cf * CFrame.new(-w / 2 + c * 12 + 4, 18, 0), Color = SNOW_A, Material = Enum.Material.Snow })
	end
	for _, fx in { -w / 2 + 4, 0, w / 2 - 4 } do
		part(m, { Size = Vector3.new(0.6, 10, 0.6), CFrame = cf * CFrame.new(fx, 25, 0), Color = WOOD_DARK })
		part(m, { Size = Vector3.new(4, 2.6, 0.3), CFrame = cf * CFrame.new(fx + 2.2, 28.6, 0), Color = RED })
	end
end

----------------------------------------------------------------------
-- Mutations (Mutation Storm, Meteor Shower, Galaxy): recolour + sparkles
----------------------------------------------------------------------
local function mutate(m: Model, mutation)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Color = mutation.Color
			d.Material = mutation.Material
			d.Transparency = if mutation.Material == Enum.Material.Glass then 0.15 else 0
			d.Reflectance = 0.2
		end
	end
	local first = m:FindFirstChildWhichIsA("BasePart")
	if first then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Color = ColorSequence.new(mutation.Color, WHITE)
		sparkle.LightEmission = 0.8
		sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
		sparkle.Lifetime = NumberRange.new(0.6, 1.2)
		sparkle.Rate = 14
		sparkle.Speed = NumberRange.new(2, 5)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Parent = first
	end
end

----------------------------------------------------------------------
-- Chunk
----------------------------------------------------------------------
export type Obstacle = {
	S0: number,
	S1: number,
	X0: number,
	X1: number,
	Top: number,
	Toughness: number,
	Coins: number,
	Candy: number,
	Presents: number,
	Mult: number,
	Model: Model?,
	Smashed: boolean,
}
export type Pad = { S0: number, S1: number, X0: number, X1: number, Top: number, Kind: string, Used: boolean }
export type Pickup = { S: number, X: number, Part: BasePart?, Base: CFrame, Taken: boolean }
export type Built = { Folder: Folder, Obstacles: { Obstacle }, Pads: { Pad }, Pickups: { Pickup } }

local function boostPad(folder, s, x)
	part(folder, { Name = "BoostPad", Size = Vector3.new(12, 0.4, 16), CFrame = CourseGen.SlopeFrame(s, x, 0.15), Color = rgb(40, 220, 255), Material = Enum.Material.Neon, CanCollide = false })
	for i = 0, 1 do
		for _, side in { -1, 1 } do
			part(folder, { Name = "Arrow", Size = Vector3.new(6, 0.3, 1.4), CFrame = CourseGen.SlopeFrame(s - 3 + i * 6, x + side * 2.3, 0.45) * CFrame.Angles(0, math.rad(side * 40), 0), Color = WHITE, Material = Enum.Material.Neon, CanCollide = false })
		end
	end
end

local function ramp(folder, s, x)
	local w = 18
	part(folder, { Class = "WedgePart", Name = "Ramp", Size = Vector3.new(w, 5, 16), CFrame = CourseGen.SlopeFrame(s, x, 2.5) * CFrame.Angles(0, math.pi, 0), Color = SNOW_A, Material = Enum.Material.Snow })
	for _, side in { -1, 1 } do
		part(folder, { Class = "WedgePart", Name = "RampEdge", Size = Vector3.new(1, 5.2, 16.2), CFrame = CourseGen.SlopeFrame(s, x + side * (w / 2 + 0.5), 2.6) * CFrame.Angles(0, math.pi, 0), Color = YELLOW })
	end
end

local function marker(folder, s)
	for _, side in { -1, 1 } do
		local base = CourseGen.Surface(s, side * (WIDTH / 2 + 2))
		for i = 0, 9 do
			part(folder, { Name = "Cane", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 3.2, 3.2), CFrame = CFrame.new(base + Vector3.new(0, i * 3 + 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = if i % 2 == 0 then RED else WHITE })
		end
	end
	local top = CourseGen.Surface(s, 0) + Vector3.new(0, 32, 0)
	local sign = part(folder, { Name = "Sign", Size = Vector3.new(WIDTH + 8, 8, 1.5), CFrame = CFrame.new(top), Color = rgb(98, 60, 38), Material = Enum.Material.WoodPlanks })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 16
	gui.LightInfluence = 0
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = rgb(255, 220, 70)
	label.Text = "🏁 " .. Config.Commas(s) .. " STUDS"
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 5
	stroke.Color = rgb(28, 18, 12)
	stroke.Parent = label
end

-- mutations: mutation ids obstacles may roll (from the active events)
function CourseBuilder.Build(index: number, parent: Instance, mutations: { string }): Built
	local spec = CourseGen.Chunk(index)
	local L = CourseGen.ChunkLength
	local folder = Instance.new("Folder")
	folder.Name = "Chunk" .. index
	local built: Built = { Folder = folder, Obstacles = {}, Pads = {}, Pickups = {} }
	local rng = Random.new(index * 31 + 7)

	-- ground: checker tiles, rails, body underneath, wide shoulders
	local TILE = 50
	for row = 0, L / TILE - 1 do
		for col = 0, WIDTH / TILE - 1 do
			local s = spec.S0 + row * TILE + TILE / 2
			local x = -WIDTH / 2 + col * TILE + TILE / 2
			part(folder, { Name = "Snow", Size = Vector3.new(TILE, 4, TILE), CFrame = CourseGen.SlopeFrame(s, x, -2), Color = if (row + col + index * 5) % 2 == 0 then SNOW_A else SNOW_B, Material = Enum.Material.Snow })
		end
	end
	local SEG = 10
	for i = 0, L / SEG - 1 do
		for _, side in { -1, 1 } do
			part(folder, { Name = "Rail", Size = Vector3.new(2, 2, SEG), CFrame = CourseGen.SlopeFrame(spec.S0 + i * SEG + SEG / 2, side * (WIDTH / 2 + 1), 1), Color = if i % 2 == 0 then RED else WHITE })
		end
	end
	local mid = spec.S0 + L / 2
	part(folder, { Name = "Body", Size = Vector3.new(WIDTH + 6, 120, L + 1), CFrame = CourseGen.SlopeFrame(mid, 0, -64), Color = rgb(226, 238, 250), Material = Enum.Material.Snow, CastShadow = false })
	for _, side in { -1, 1 } do
		part(folder, { Name = "Shoulder", Size = Vector3.new(360, 40, L + 1), CFrame = CourseGen.SlopeFrame(mid, side * (WIDTH / 2 + 183), -42), Color = ROCK, Material = Enum.Material.Snow, CastShadow = false })
	end
	-- trees beside the run
	for _ = 1, 4 do
		local side = if rng:NextNumber() < 0.5 then -1 else 1
		local s = rng:NextNumber(spec.S0, spec.S1)
		local off = rng:NextNumber(WIDTH / 2 + 10, WIDTH / 2 + 80)
		local p = CourseGen.Surface(s, side * off) - Vector3.new(0, 22.5 + 2, 0)
		local tree = model(folder, "SideTree")
		pineTree(tree, CFrame.new(p) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), rng:NextNumber(1.3, 2.2))
	end
	if spec.Marker then
		marker(folder, spec.Marker)
	end

	-- obstacles
	local obstacles = Instance.new("Folder")
	obstacles.Name = "Smashables"
	obstacles.Parent = folder
	for _, o in spec.Obstacles do
		local m = model(obstacles, o.Kind)
		local builder = Builders[o.Kind]
		if builder then
			builder(m, CourseGen.Upright(o.S, o.X, math.min(o.D, 12)), o)
		end
		local mult = 1
		if #mutations > 0 and o.Kind ~= "Gate" then
			local roll = rng:NextNumber()
			local acc = 0
			for _, id in mutations do
				local mutation = Config.MutationById[id]
				acc += mutation.Chance
				if roll < acc then
					mult = mutation.Mult
					mutate(m, mutation)
					break
				end
			end
		end
		table.insert(built.Obstacles, {
			S0 = o.S - o.D / 2,
			S1 = o.S + o.D / 2,
			X0 = o.X - o.W / 2,
			X1 = o.X + o.W / 2,
			Top = o.H + o.D * 0.5 * TAN,
			Toughness = o.Tough,
			Coins = o.Coins,
			Candy = o.Candy or 0,
			Presents = o.Presents or 0,
			Mult = mult,
			Model = m,
			Smashed = false,
		})
	end
	table.sort(built.Obstacles, function(a, b)
		return a.S0 < b.S0
	end)

	-- pads
	for _, p in spec.Pads do
		if p.Kind == "Boost" then
			boostPad(folder, p.S, p.X)
			table.insert(built.Pads, { S0 = p.S - 8, S1 = p.S + 8, X0 = p.X - 6, X1 = p.X + 6, Top = 0, Kind = "Boost", Used = false })
		else
			ramp(folder, p.S, p.X)
			table.insert(built.Pads, { S0 = p.S - 8, S1 = p.S + 8, X0 = p.X - 9, X1 = p.X + 9, Top = 5, Kind = "Ramp", Used = false })
		end
	end

	-- coins
	for _, c in spec.Coins do
		local cf = CFrame.new(CourseGen.Surface(c.S, c.X) + Vector3.new(0, c.H, 0)) * CFrame.Angles(0, math.pi / 2, 0)
		local coin = part(folder, {
			Name = "Coin",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.6, 3, 3),
			CFrame = cf,
			Color = rgb(255, 196, 30),
			Reflectance = 0.15,
			CanCollide = false,
			CastShadow = false,
		})
		table.insert(built.Pickups, { S = c.S, X = c.X, Part = coin, Base = cf, Taken = false })
	end

	folder.Parent = parent
	return built
end

return CourseBuilder
