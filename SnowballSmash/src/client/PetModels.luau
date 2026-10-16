--!nonstrict
-- Snowball Smash: 3D pet models (Pet Simulator style), built from parts so no
-- uploaded meshes are needed. Every pet is a chunky round critter with big
-- shiny eyes, blush and little feet, plus its own ears, horns, wings, hats...
--
-- PetModels.build(petId) -> Model (PrimaryPart "Root" sits in the middle of the
-- body, the face looks along -Z). Move it with Model:PivotTo().

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Pets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Pets"))

local PetModels = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local BLACK = rgb(28, 26, 38)
local WHITE = rgb(255, 255, 255)
local PINK = rgb(255, 150, 185)
local GOLD = rgb(255, 205, 50)
local ORANGE = rgb(255, 160, 40)

local function darker(c: Color3, k: number?): Color3
	return c:Lerp(Color3.new(0, 0, 0), k or 0.22)
end
local function lighter(c: Color3, k: number?): Color3
	return c:Lerp(Color3.new(1, 1, 1), k or 0.35)
end

----------------------------------------------------------------------
-- Part helpers
----------------------------------------------------------------------
type Opts = { Material: Enum.Material?, Transparency: number?, Name: string? }

local function newPart(m: Model, class: string, size: Vector3, cf: CFrame, color: Color3, opts: Opts?): BasePart
	local p = Instance.new(class)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = (opts and opts.Material) or Enum.Material.SmoothPlastic
	p.Transparency = (opts and opts.Transparency) or 0
	p.Name = (opts and opts.Name) or "Part"
	p.Parent = m
	return p
end

-- squashed sphere of any size
local function blob(m: Model, size: Vector3, cf: CFrame, color: Color3, opts: Opts?): BasePart
	local p = newPart(m, "Part", size, cf, color, opts)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

local function block(m: Model, size: Vector3, cf: CFrame, color: Color3, opts: Opts?): BasePart
	return newPart(m, "Part", size, cf, color, opts)
end

-- cylinder standing up (along Y)
local function cyl(m: Model, height: number, diameter: number, cf: CFrame, color: Color3, opts: Opts?): BasePart
	local p = newPart(m, "Part", Vector3.new(height, diameter, diameter), cf * CFrame.Angles(0, 0, math.rad(90)), color, opts)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- stacked cylinders getting thinner: hats, horns, spikes
local function cone(m: Model, base: CFrame, radius: number, height: number, color: Color3, steps: number?, opts: Opts?)
	local n = steps or 5
	local h = height / n
	for i = 0, n - 1 do
		local r = radius * (1 - i / n) + 0.02
		cyl(m, h + 0.02, r * 2, base * CFrame.new(0, h * (i + 0.5), 0), color, opts)
	end
end

-- a square turned 45 degrees: pointy ears, spikes, stars
local function diamond(m: Model, size: Vector3, cf: CFrame, color: Color3, opts: Opts?): BasePart
	return block(m, size, cf * CFrame.Angles(0, 0, math.rad(45)), color, opts)
end

local function at(x: number, y: number, z: number): CFrame
	return CFrame.new(x, y, z)
end

----------------------------------------------------------------------
-- The critter body
----------------------------------------------------------------------
type Ctx = { A: number, B: number, C: number, Top: number, Bottom: number, Spec: any }

-- point on the front of the body (front = -Z), pushed out a little
local function front(ctx: Ctx, x: number, y: number, out: number?): Vector3
	if ctx.Spec.Cube then
		return Vector3.new(x, y, -ctx.C - (out or 0))
	end
	local k = 1 - (x / ctx.A) ^ 2 - (y / ctx.B) ^ 2
	return Vector3.new(x, y, -ctx.C * math.sqrt(math.max(0.04, k)) - (out or 0))
end

local function ears(m: Model, ctx: Ctx, kind: string, color: Color3, inner: Color3)
	local top = ctx.Top
	for _, side in { -1, 1 } do
		if kind == "Cat" or kind == "Fox" then
			local s = if kind == "Fox" then 0.78 else 0.62
			local cf = at(side * ctx.A * 0.52, top - 0.08, 0.1) * CFrame.Angles(0, 0, side * math.rad(-14))
			diamond(m, Vector3.new(s, s, 0.24), cf, color)
			diamond(m, Vector3.new(s * 0.55, s * 0.55, 0.05), cf * at(0, 0.04, -0.13), inner)
		elseif kind == "Bunny" then
			local cf = at(side * 0.4, top + 0.5, 0.1) * CFrame.Angles(0, 0, side * math.rad(-10))
			blob(m, Vector3.new(0.42, 1.35, 0.3), cf, color)
			blob(m, Vector3.new(0.22, 0.95, 0.06), cf * at(0, 0.02, -0.15), inner)
		elseif kind == "Bear" then
			local cf = at(side * ctx.A * 0.68, top - 0.18, 0.1)
			blob(m, Vector3.new(0.6, 0.6, 0.36), cf, color)
			blob(m, Vector3.new(0.32, 0.32, 0.06), cf * at(0, 0, -0.18), inner)
		elseif kind == "Tufts" then
			diamond(m, Vector3.new(0.4, 0.4, 0.16), at(side * ctx.A * 0.6, top - 0.02, 0) * CFrame.Angles(0, 0, side * math.rad(-25)), color)
		elseif kind == "Pointy" then
			block(m, Vector3.new(0.7, 0.26, 0.14), at(side * (ctx.A + 0.15), 0.2, 0.05) * CFrame.Angles(0, 0, side * math.rad(25)), color)
		end
	end
end

local function face(m: Model, ctx: Ctx, spec)
	local ex = spec.EyeX or 0.42
	local ey = spec.EyeY or 0.22
	local es = spec.EyeSize or 1
	local out = spec.FaceOut or 0
	if not spec.NoEyes then
		for _, side in { -1, 1 } do
			local p = front(ctx, side * ex, ey, out - 0.04)
			if spec.EyeRing then
				blob(m, Vector3.new(0.56, 0.62, 0.12) * es, CFrame.new(p + Vector3.new(0, 0, -0.02)), spec.EyeRing)
			end
			local eyeColor = spec.Eye or BLACK
			blob(m, Vector3.new(0.36, 0.48, 0.16) * es, CFrame.new(p + Vector3.new(0, 0, -0.05)), eyeColor, if spec.EyeGlow then { Material = Enum.Material.Neon } else nil)
			if not spec.EyeGlow then
				blob(m, Vector3.new(0.14, 0.14, 0.06) * es, CFrame.new(p + Vector3.new(0.06 * es, 0.1 * es, -0.13)), WHITE, { Material = Enum.Material.Neon })
			end
		end
	end
	if not spec.NoBlush then
		for _, side in { -1, 1 } do
			local p = front(ctx, side * (ex + 0.36), ey - 0.32, out - 0.02)
			blob(m, Vector3.new(0.3, 0.15, 0.08), CFrame.new(p), spec.Blush or PINK, { Transparency = 0.15 })
		end
	end
	if spec.Smile then
		local p = front(ctx, 0, ey - 0.38, -0.03)
		block(m, Vector3.new(0.3, 0.08, 0.06), CFrame.new(p), spec.Smile)
	end
end

-- body + face + feet + ears; returns the context for extras
local function critter(m: Model, spec): Ctx
	local size = spec.Size or Vector3.new(2.4, 2.2, 2.2)
	local ctx: Ctx = { A = size.X / 2, B = size.Y / 2, C = size.Z / 2, Top = size.Y / 2, Bottom = -size.Y / 2, Spec = spec }
	local opts = { Material = spec.Material, Transparency = spec.Transparency, Name = "Body" }
	if spec.Cube then
		block(m, size, CFrame.new(), spec.Body, opts)
	else
		blob(m, size, CFrame.new(), spec.Body, opts)
	end
	if spec.Belly then
		local p = front(ctx, 0, -0.32, -0.32)
		blob(m, Vector3.new(size.X * 0.62, size.Y * 0.55, 0.7), CFrame.new(p), spec.Belly, { Transparency = spec.Transparency })
	end
	face(m, ctx, spec)
	if spec.Feet ~= false then
		local fc = spec.FeetColor or darker(spec.Body, 0.12)
		for _, side in { -1, 1 } do
			blob(m, Vector3.new(0.62, 0.38, 0.75), at(side * ctx.A * 0.46, ctx.Bottom + 0.06, -0.2), fc, { Transparency = spec.Transparency })
		end
	end
	if spec.Ears then
		ears(m, ctx, spec.Ears, spec.EarColor or spec.Body, spec.EarInner or PINK)
	end
	return ctx
end

----------------------------------------------------------------------
-- Reusable extras
----------------------------------------------------------------------
local function snout(m, ctx, color, nose)
	local p = front(ctx, 0, -0.12, -0.12)
	blob(m, Vector3.new(0.75, 0.5, 0.45), CFrame.new(p), color)
	blob(m, Vector3.new(0.26, 0.18, 0.12), CFrame.new(p + Vector3.new(0, 0.1, -0.24)), nose or BLACK)
end

local function nose(m, ctx, color, size)
	local p = front(ctx, 0, -0.05, -0.05)
	blob(m, Vector3.one * (size or 0.2), CFrame.new(p), color)
end

local function beak(m, ctx, color)
	local p = front(ctx, 0, -0.08, -0.12)
	diamond(m, Vector3.new(0.34, 0.34, 0.3), CFrame.new(p) * CFrame.Angles(math.rad(10), 0, 0), color)
end

local function sideWings(m, ctx, color, size)
	local s = size or 1
	for _, side in { -1, 1 } do
		blob(m, Vector3.new(0.28, 1.05 * s, 0.95 * s), at(side * (ctx.A - 0.02), -0.1, 0.1) * CFrame.Angles(0, 0, side * math.rad(18)), color)
	end
end

local function batWings(m, ctx, color, size)
	local s = size or 1
	for _, side in { -1, 1 } do
		local root = at(side * (ctx.A - 0.1), 0.3, 0.35) * CFrame.Angles(0, side * math.rad(-25), side * math.rad(-30))
		block(m, Vector3.new(1.3 * s, 0.9 * s, 0.1), root * at(side * 0.6 * s, 0, 0), color)
		diamond(m, Vector3.new(0.55 * s, 0.55 * s, 0.1), root * at(side * 1.15 * s, -0.25 * s, 0), color)
		diamond(m, Vector3.new(0.45 * s, 0.45 * s, 0.1), root * at(side * 0.55 * s, -0.42 * s, 0), color)
	end
end

local function horns(m, ctx, color, length, spread)
	for _, side in { -1, 1 } do
		cone(m, at(side * (spread or 0.45), ctx.Top - 0.15, 0.15) * CFrame.Angles(math.rad(-15), 0, side * math.rad(-22)), 0.17, length or 0.7, color, 4)
	end
end

local function tail(m, ctx, color, size, tip)
	local s = size or Vector3.new(0.6, 0.6, 1)
	local p = at(0, -0.35, ctx.C + s.Z * 0.3) * CFrame.Angles(math.rad(-30), 0, 0)
	blob(m, s, p, color)
	if tip then
		blob(m, s * 0.55, p * at(0, 0, s.Z * 0.38), tip)
	end
end

local function backSpikes(m, ctx, color, count)
	for i = 0, (count or 3) - 1 do
		local y = ctx.Top - 0.25 - i * 0.45
		diamond(m, Vector3.new(0.38, 0.38, 0.12), at(0, y, ctx.C * math.sqrt(math.max(0.05, 1 - (y / ctx.B) ^ 2)) - 0.05) * CFrame.Angles(0, math.rad(90), 0), color)
	end
end

local function hat(m, ctx, color, trim, pom)
	local base = at(0, ctx.Top - 0.2, 0.05) * CFrame.Angles(math.rad(-12), 0, math.rad(-10))
	cyl(m, 0.28, ctx.A * 1.75, base, trim)
	cone(m, base * at(0, 0.1, 0), ctx.A * 0.78, 1.25, color, 9)
	blob(m, Vector3.one * 0.42, base * at(0.12, 1.4, 0), pom)
end

local function crown(m, ctx, color, gem)
	local y = ctx.Top - 0.05
	cyl(m, 0.38, 1.3, at(0, y, 0), color, { Material = Enum.Material.Foil })
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		diamond(m, Vector3.new(0.3, 0.3, 0.1), at(math.cos(a) * 0.58, y + 0.3, math.sin(a) * 0.58) * CFrame.Angles(0, -a + math.pi / 2, 0), color, { Material = Enum.Material.Foil })
	end
	blob(m, Vector3.one * 0.26, at(0, y + 0.05, -0.66), gem, { Material = Enum.Material.Neon })
end

local function scarf(m, ctx, color)
	cyl(m, 0.32, ctx.A * 2 - 0.15, at(0, -0.42, 0), color)
	block(m, Vector3.new(0.34, 0.75, 0.12), at(0.45, -0.75, -ctx.C + 0.15) * CFrame.Angles(0, 0, math.rad(8)), color)
end

-- a band hugging the body at height y (belts)
local function belt(m, ctx, y, height, color)
	local k = math.sqrt(math.max(0.05, 1 - (y / ctx.B) ^ 2))
	local band = blob(m, Vector3.new(ctx.A * 2 * k + 0.08, height, ctx.C * 2 * k + 0.08), at(0, y, 0), color)
	return band
end

local function cape(m, ctx, color, inner)
	local cf = at(0, -0.15, ctx.C + 0.06) * CFrame.Angles(math.rad(8), 0, 0)
	block(m, Vector3.new(ctx.A * 1.9, ctx.B * 1.9, 0.12), cf, color)
	if inner then
		block(m, Vector3.new(ctx.A * 1.7, ctx.B * 1.7, 0.06), cf * at(0, 0, -0.08), inner)
	end
	-- collar points
	for _, side in { -1, 1 } do
		diamond(m, Vector3.new(0.6, 0.6, 0.1), at(side * 0.75, ctx.Top - 0.45, ctx.C * 0.55) * CFrame.Angles(math.rad(-20), side * math.rad(30), 0), color)
	end
end

local function fangs(m, ctx, color)
	for _, side in { -1, 1 } do
		diamond(m, Vector3.new(0.12, 0.12, 0.05), CFrame.new(front(ctx, side * 0.12, -0.32, -0.06)), color or WHITE)
	end
end

local function sparkleGem(m, cf, color)
	diamond(m, Vector3.new(0.35, 0.35, 0.35), cf * CFrame.Angles(math.rad(45), 0, 0), color, { Material = Enum.Material.Neon })
end

----------------------------------------------------------------------
-- Every pet
----------------------------------------------------------------------
local SPECS = {}

-- Frosty Egg -------------------------------------------------------------
SPECS.Penguin = { Body = rgb(46, 52, 74), Belly = WHITE, FeetColor = ORANGE, Extra = function(m, ctx)
	beak(m, ctx, ORANGE)
	sideWings(m, ctx, rgb(36, 40, 60), 0.9)
end }
SPECS.SnowBunny = { Body = rgb(250, 250, 255), Ears = "Bunny", Extra = function(m, ctx)
	nose(m, ctx, PINK, 0.18)
	blob(m, Vector3.one * 0.55, at(0, -0.5, ctx.C + 0.05), WHITE)
end }
SPECS.ArcticFox = { Body = rgb(240, 246, 255), Ears = "Fox", EarInner = rgb(200, 220, 245), Extra = function(m, ctx)
	snout(m, ctx, WHITE)
	tail(m, ctx, rgb(240, 246, 255), Vector3.new(0.75, 0.75, 1.4), rgb(200, 225, 255))
end }
SPECS.SnowBear = { Body = rgb(248, 246, 240), Ears = "Bear", EarInner = rgb(220, 210, 200), Extra = function(m, ctx)
	snout(m, ctx, rgb(255, 252, 248))
	scarf(m, ctx, rgb(80, 150, 255))
end }
SPECS.SnowOwl = { Body = rgb(245, 245, 250), Ears = "Tufts", EyeRing = GOLD, EyeX = 0.46, Belly = rgb(225, 230, 240), Extra = function(m, ctx)
	beak(m, ctx, rgb(255, 190, 60))
	sideWings(m, ctx, rgb(225, 230, 240), 1.1)
	for _, s in { { -0.5, 0.75 }, { 0.6, 0.55 }, { -0.2, -0.6 }, { 0.4, -0.75 } } do
		blob(m, Vector3.new(0.14, 0.1, 0.06), CFrame.new(front(ctx, s[1] * 0.9, s[2] * 0.9, -0.02)), rgb(120, 120, 140))
	end
end }

-- Glacier Egg ------------------------------------------------------------
SPECS.IceWolf = { Body = rgb(175, 205, 235), Ears = "Fox", EarInner = rgb(220, 235, 255), Belly = rgb(235, 245, 255), Extra = function(m, ctx)
	snout(m, ctx, rgb(225, 238, 255))
	tail(m, ctx, rgb(175, 205, 235), Vector3.new(0.6, 0.6, 1.3), WHITE)
	sparkleGem(m, CFrame.new(front(ctx, 0, 0.75, -0.02)), rgb(120, 230, 255))
end }
SPECS.SnowCat = { Body = rgb(250, 250, 255), Ears = "Cat", Extra = function(m, ctx)
	nose(m, ctx, PINK, 0.16)
	for _, side in { -1, 1 } do
		for k = -1, 1 do
			block(m, Vector3.new(0.5, 0.04, 0.04), CFrame.new(front(ctx, side * 0.62, -0.08 + k * 0.1, -0.06)) * CFrame.Angles(0, 0, math.rad(k * 10 * side)), rgb(120, 130, 150))
		end
	end
	for i = 0, 2 do
		block(m, Vector3.new(0.12, 0.5, 0.06), CFrame.new(front(ctx, -0.25 + i * 0.25, 0.85, 0)), rgb(140, 190, 255))
	end
	tail(m, ctx, WHITE, Vector3.new(0.3, 0.3, 1.3), rgb(140, 190, 255))
end }
SPECS.IceWhale = { Body = rgb(80, 150, 235), Size = Vector3.new(2.6, 2, 2.6), Belly = rgb(190, 225, 255), Feet = false, Extra = function(m, ctx)
	local base = at(0, 0.1, ctx.C + 0.25)
	for _, side in { -1, 1 } do
		block(m, Vector3.new(0.9, 0.12, 0.6), base * at(side * 0.4, 0.35, 0.2) * CFrame.Angles(0, 0, side * math.rad(30)), rgb(70, 135, 220))
		blob(m, Vector3.new(0.25, 0.4, 0.7), at(side * (ctx.A - 0.05), -0.45, -0.1) * CFrame.Angles(0, 0, side * math.rad(40)), rgb(70, 135, 220))
	end
	for i = 0, 2 do
		blob(m, Vector3.one * (0.35 - i * 0.08), at((i - 1) * 0.25, ctx.Top + 0.25 + i * 0.25, 0), rgb(150, 230, 255), { Material = Enum.Material.Neon, Transparency = 0.2 })
	end
end }
SPECS.FrostDragon = { Body = rgb(130, 195, 255), Belly = rgb(215, 240, 255), Extra = function(m, ctx)
	horns(m, ctx, WHITE, 0.65)
	batWings(m, ctx, rgb(170, 225, 255), 0.9)
	backSpikes(m, ctx, WHITE, 3)
	tail(m, ctx, rgb(130, 195, 255), Vector3.new(0.45, 0.45, 1.3), WHITE)
	nose(m, ctx, rgb(100, 160, 230), 0.14)
end }
SPECS.Unicorn = { Body = WHITE, Ears = "Cat", EarInner = rgb(255, 200, 230), Extra = function(m, ctx)
	cone(m, at(0, ctx.Top - 0.2, -0.45) * CFrame.Angles(math.rad(-25), 0, 0), 0.2, 1.1, GOLD, 6, { Material = Enum.Material.Foil })
	local mane = { rgb(255, 150, 210), rgb(160, 150, 255), rgb(120, 220, 255), rgb(255, 220, 120) }
	for i, c in mane do
		blob(m, Vector3.new(0.5, 0.55, 0.5), at(0.15 * ((i % 2) * 2 - 1), ctx.Top - 0.05 - i * 0.28, 0.35 + i * 0.22), c)
	end
	tail(m, ctx, rgb(255, 150, 210), Vector3.new(0.5, 0.5, 1.1), rgb(160, 150, 255))
end }
SPECS.Yeti = { Body = rgb(245, 248, 255), Size = Vector3.new(2.7, 2.6, 2.4), EyeY = 0.3, FaceOut = 0.08, Extra = function(m, ctx)
	local p = front(ctx, 0, 0.12, 0)
	blob(m, Vector3.new(1.75, 1.35, 0.3), CFrame.new(p + Vector3.new(0, 0, 0.06)), rgb(150, 190, 235))
	horns(m, ctx, rgb(200, 210, 230), 0.55, 0.65)
	fangs(m, ctx)
	for _, side in { -1, 1 } do
		blob(m, Vector3.new(0.7, 1.2, 0.7), at(side * (ctx.A + 0.05), -0.4, -0.1) * CFrame.Angles(0, 0, side * math.rad(15)), rgb(240, 244, 255))
	end
end }

-- Aurora Egg -------------------------------------------------------------
SPECS.AuroraBird = { Body = rgb(80, 225, 195), Belly = rgb(200, 255, 235), FeetColor = ORANGE, Extra = function(m, ctx)
	beak(m, ctx, rgb(255, 200, 60))
	sideWings(m, ctx, rgb(170, 120, 255), 1.1)
	for i, c in { rgb(255, 110, 200), rgb(170, 120, 255), rgb(90, 200, 255) } do
		diamond(m, Vector3.new(0.4, 0.4, 0.1), at((i - 2) * 0.22, ctx.Top + 0.1, 0.1) * CFrame.Angles(0, math.rad(90), math.rad((i - 2) * 20)), c)
	end
	tail(m, ctx, rgb(170, 120, 255), Vector3.new(0.6, 0.2, 1.1), rgb(255, 110, 200))
end }
SPECS.FrostOcto = { Body = rgb(160, 125, 255), Size = Vector3.new(2.5, 2.3, 2.4), Feet = false, EyeY = 0.3, Extra = function(m, ctx)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		blob(m, Vector3.new(0.4, 0.9, 0.4), at(math.cos(a) * 0.8, ctx.Bottom - 0.05, math.sin(a) * 0.8) * CFrame.Angles(math.sin(a) * 0.4, 0, -math.cos(a) * 0.4), rgb(140, 105, 235))
	end
	for _, s in { { -0.6, 0.7 }, { 0.5, 0.85 }, { 0.75, 0.3 } } do
		blob(m, Vector3.one * 0.22, CFrame.new(front(ctx, s[1], s[2], -0.02)), rgb(200, 180, 255))
	end
end }
SPECS.IceDragon = { Body = rgb(70, 115, 235), Belly = rgb(160, 205, 255), Size = Vector3.new(2.5, 2.3, 2.3), EyeGlow = true, Eye = rgb(120, 240, 255), Extra = function(m, ctx)
	horns(m, ctx, GOLD, 0.8)
	batWings(m, ctx, rgb(110, 160, 255), 1.15)
	backSpikes(m, ctx, rgb(150, 230, 255), 3)
	tail(m, ctx, rgb(70, 115, 235), Vector3.new(0.5, 0.5, 1.4), rgb(150, 230, 255))
end }
SPECS.StarSpirit = { Body = rgb(255, 225, 90), Material = Enum.Material.Neon, Feet = false, NoBlush = true, Extra = function(m, ctx)
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2 + math.pi / 2
		diamond(m, Vector3.new(0.9, 0.9, 0.5), at(math.cos(a) * 1.25, math.sin(a) * 1.25, 0) * CFrame.Angles(0, 0, a - math.pi / 4), rgb(255, 210, 60), { Material = Enum.Material.Neon })
	end
end }
SPECS.CrystalGolem = { Body = rgb(110, 220, 255), Cube = true, Size = Vector3.new(2.4, 2.3, 2.1), Material = Enum.Material.Glass, Transparency = 0.1, EyeGlow = true, Eye = rgb(220, 255, 255), NoBlush = true, Extra = function(m, ctx)
	for i, s in { { -0.6, 0.5 }, { 0.1, 0.8 }, { 0.65, 0.45 } } do
		diamond(m, Vector3.new(0.5, 0.5, 0.5) * (1 + i * 0.1), at(s[1], ctx.Top + s[2] * 0.6, 0.1) * CFrame.Angles(math.rad(45), 0, 0), rgb(150, 240, 255), { Material = Enum.Material.Neon })
	end
	for _, side in { -1, 1 } do
		block(m, Vector3.new(0.8, 1, 0.8), at(side * (ctx.A + 0.3), -0.2, 0), rgb(90, 190, 240), { Material = Enum.Material.Glass })
	end
end }
SPECS.SnowKing = { Body = rgb(250, 252, 255), Size = Vector3.new(2.5, 2.5, 2.3), Extra = function(m, ctx)
	crown(m, ctx, GOLD, rgb(255, 60, 90))
	cape(m, ctx, rgb(200, 30, 50), rgb(255, 255, 255))
	nose(m, ctx, ORANGE, 0.22)
	for i = 0, 1 do
		blob(m, Vector3.one * 0.18, CFrame.new(front(ctx, 0, -0.55 - i * 0.35, -0.02)), BLACK)
	end
end }

-- Spooky Egg -------------------------------------------------------------
SPECS.Bat = { Body = rgb(80, 60, 110), Ears = "Cat", EarInner = rgb(255, 140, 180), Feet = false, Extra = function(m, ctx)
	batWings(m, ctx, rgb(60, 44, 88), 1)
	fangs(m, ctx)
end }
SPECS.Ghost = { Body = rgb(245, 248, 255), Size = Vector3.new(2.2, 2.6, 2.2), Transparency = 0.15, Feet = false, Smile = BLACK, Extra = function(m, ctx)
	for i = -1, 1 do
		blob(m, Vector3.new(0.75, 0.6, 0.75), at(i * 0.65, ctx.Bottom + 0.1, 0), rgb(245, 248, 255), { Transparency = 0.15 })
	end
	for _, side in { -1, 1 } do
		blob(m, Vector3.new(0.45, 0.8, 0.4), at(side * (ctx.A + 0.05), -0.2, 0) * CFrame.Angles(0, 0, side * math.rad(-35)), rgb(245, 248, 255), { Transparency = 0.15 })
	end
end }
SPECS.PumpkinCat = { Body = rgb(255, 135, 25), Ears = "Cat", EarColor = rgb(230, 105, 15), EarInner = rgb(255, 210, 90), Extra = function(m, ctx)
	for _, x in { -0.8, -0.3, 0.3, 0.8 } do
		local k = math.sqrt(1 - (x / ctx.A) ^ 2) * 1.02
		blob(m, Vector3.new(0.1, ctx.B * 2 * k, ctx.C * 2 * k), at(x, 0, 0), rgb(225, 105, 12))
	end
	cyl(m, 0.5, 0.25, at(0.15, ctx.Top + 0.15, 0.2), rgb(70, 130, 40))
	nose(m, ctx, rgb(90, 40, 10), 0.16)
	tail(m, ctx, rgb(230, 105, 15), Vector3.new(0.3, 0.3, 1.2), rgb(70, 130, 40))
end }
SPECS.Spider = { Body = rgb(40, 50, 80), EyeSize = 0.85, Extra = function(m, ctx)
	for _, side in { -1, 1 } do
		for k = 0, 3 do
			local z = -0.5 + k * 0.42
			local root = at(side * (ctx.A - 0.2), -0.2, z) * CFrame.Angles(0, side * math.rad(-10 + k * 8), 0)
			block(m, Vector3.new(0.9, 0.12, 0.12), root * at(side * 0.4, 0.2, 0) * CFrame.Angles(0, 0, side * math.rad(35)), rgb(30, 38, 62))
			block(m, Vector3.new(0.12, 0.8, 0.12), root * at(side * 0.82, -0.2, 0) * CFrame.Angles(0, 0, side * math.rad(-15)), rgb(30, 38, 62))
		end
	end
	for _, side in { -1, 1 } do
		blob(m, Vector3.one * 0.16, CFrame.new(front(ctx, side * 0.2, 0.62, -0.02)), rgb(120, 230, 255), { Material = Enum.Material.Neon })
	end
	sparkleGem(m, at(0, ctx.Top - 0.1, 0.4), rgb(120, 230, 255))
	fangs(m, ctx, rgb(180, 240, 255))
end }
SPECS.Skeleton = { Body = rgb(240, 240, 232), EyeGlow = true, Eye = rgb(110, 240, 255), EyeRing = rgb(40, 40, 50), NoBlush = true, Extra = function(m, ctx)
	blob(m, Vector3.new(0.2, 0.25, 0.1), CFrame.new(front(ctx, 0, -0.1, -0.03)), rgb(40, 40, 50))
	for i = -2, 2 do
		block(m, Vector3.new(0.1, 0.22, 0.06), CFrame.new(front(ctx, i * 0.14, -0.45, -0.03)), rgb(60, 60, 70))
	end
	for _, side in { -1, 1 } do
		local cf = at(side * 0.55, -0.1, ctx.C + 0.15) * CFrame.Angles(0, 0, side * math.rad(40))
		block(m, Vector3.new(0.22, 1.5, 0.22), cf, rgb(235, 235, 225))
		blob(m, Vector3.one * 0.32, cf * at(0, 0.75, 0), rgb(235, 235, 225))
		blob(m, Vector3.one * 0.32, cf * at(0, -0.75, 0), rgb(235, 235, 225))
	end
end }
SPECS.Vampire = { Body = rgb(232, 228, 245), EyeGlow = true, Eye = rgb(255, 40, 70), Extra = function(m, ctx)
	blob(m, Vector3.new(ctx.A * 2.05, 0.8, ctx.C * 2.05), at(0, ctx.Top - 0.25, 0.1), rgb(30, 25, 40))
	diamond(m, Vector3.new(0.45, 0.45, 0.2), CFrame.new(front(ctx, 0, 0.72, 0.05)), rgb(30, 25, 40))
	cape(m, ctx, rgb(25, 20, 35), rgb(190, 20, 40))
	fangs(m, ctx)
end }

-- Winter Egg -------------------------------------------------------------
SPECS.Reindeer = { Body = rgb(160, 105, 65), Belly = rgb(235, 205, 160), Ears = "Bear", EarInner = rgb(235, 205, 160), Extra = function(m, ctx)
	local p = front(ctx, 0, -0.1, -0.05)
	blob(m, Vector3.one * 0.38, CFrame.new(p), rgb(255, 40, 40), { Material = Enum.Material.Neon })
	for _, side in { -1, 1 } do
		local base = at(side * 0.42, ctx.Top - 0.1, 0.15) * CFrame.Angles(0, 0, side * math.rad(-20))
		local brown = rgb(110, 70, 40)
		block(m, Vector3.new(0.14, 0.9, 0.14), base * at(0, 0.45, 0), brown)
		block(m, Vector3.new(0.12, 0.5, 0.12), base * at(side * 0.2, 0.6, 0) * CFrame.Angles(0, 0, side * math.rad(-50)), brown)
		block(m, Vector3.new(0.12, 0.4, 0.12), base * at(side * -0.15, 0.8, 0) * CFrame.Angles(0, 0, side * math.rad(40)), brown)
	end
	scarf(m, ctx, rgb(40, 170, 80))
end }
SPECS.PolarBear = { Body = rgb(252, 252, 255), Ears = "Bear", EarInner = rgb(225, 225, 235), Size = Vector3.new(2.5, 2.3, 2.3), Extra = function(m, ctx)
	snout(m, ctx, WHITE)
	scarf(m, ctx, rgb(230, 50, 60))
end }
SPECS.Gingerbread = { Body = rgb(200, 125, 65), Cube = true, Size = Vector3.new(2.3, 2.3, 1.4), Smile = WHITE, Extra = function(m, ctx)
	for i, c in { rgb(230, 50, 60), rgb(60, 190, 90) } do
		blob(m, Vector3.one * 0.26, at(0, -0.55 - (i - 1) * 0.4, -ctx.C - 0.05), c)
	end
	-- icing trim
	block(m, Vector3.new(ctx.A * 2 + 0.05, 0.1, 0.06), at(0, ctx.Top - 0.25, -ctx.C - 0.02), WHITE)
	block(m, Vector3.new(ctx.A * 2 + 0.05, 0.1, 0.06), at(0, ctx.Bottom + 0.3, -ctx.C - 0.02), WHITE)
	for _, side in { -1, 1 } do
		blob(m, Vector3.new(0.6, 0.6, 0.5), at(side * (ctx.A + 0.15), -0.1, 0), rgb(200, 125, 65))
	end
end }
SPECS.Elf = { Body = rgb(60, 180, 90), EyeY = 0.3, Extra = function(m, ctx)
	local p = front(ctx, 0, 0.2, -0.15)
	blob(m, Vector3.new(1.6, 1.15, 0.45), CFrame.new(p + Vector3.new(0, 0, 0.12)), rgb(255, 215, 180))
	ears(m, ctx, "Pointy", rgb(255, 215, 180), PINK)
	hat(m, ctx, rgb(50, 160, 80), rgb(230, 50, 60), rgb(255, 220, 60))
	belt(m, ctx, -0.45, 0.25, rgb(110, 70, 40))
	block(m, Vector3.new(0.35, 0.3, 0.1), CFrame.new(front(ctx, 0, -0.45, 0.02)), GOLD)
end }
SPECS.Santa = { Body = rgb(225, 40, 50), EyeY = 0.35, Extra = function(m, ctx)
	local p = front(ctx, 0, 0.3, -0.12)
	blob(m, Vector3.new(1.4, 0.95, 0.45), CFrame.new(p + Vector3.new(0, 0, 0.12)), rgb(255, 215, 180))
	blob(m, Vector3.new(1.3, 0.9, 0.5), CFrame.new(front(ctx, 0, -0.3, -0.12)), WHITE)
	nose(m, ctx, rgb(255, 150, 150), 0.22)
	hat(m, ctx, rgb(225, 40, 50), WHITE, WHITE)
	belt(m, ctx, -0.7, 0.28, BLACK)
	block(m, Vector3.new(0.4, 0.34, 0.1), CFrame.new(front(ctx, 0, -0.7, 0.02)), GOLD, { Material = Enum.Material.Foil })
end }
SPECS.FrostTitan = { Body = rgb(150, 220, 255), Cube = true, Size = Vector3.new(2.7, 2.6, 2.3), Material = Enum.Material.Glass, Transparency = 0.05, EyeGlow = true, Eye = rgb(60, 240, 255), NoBlush = true, Extra = function(m, ctx)
	for i = -2, 2 do
		diamond(m, Vector3.new(0.45, 0.45, 0.45) * (1.3 - math.abs(i) * 0.2), at(i * 0.5, ctx.Top + 0.25 - math.abs(i) * 0.1, 0) * CFrame.Angles(math.rad(45), 0, 0), rgb(200, 245, 255), { Material = Enum.Material.Neon })
	end
	for _, side in { -1, 1 } do
		block(m, Vector3.new(1, 1.2, 1), at(side * (ctx.A + 0.4), 0.1, 0), rgb(120, 200, 245), { Material = Enum.Material.Glass })
		cone(m, at(side * (ctx.A + 0.4), 0.7, 0) * CFrame.Angles(0, 0, side * math.rad(-20)), 0.3, 0.8, rgb(200, 245, 255), 4, { Material = Enum.Material.Neon })
	end
	block(m, Vector3.new(1.2, 0.18, 0.08), CFrame.new(front(ctx, 0, -0.5, -0.02)), rgb(60, 240, 255), { Material = Enum.Material.Neon })
end }

-- Blizzard Egg -----------------------------------------------------------
SPECS.SnowSprite = { Body = rgb(110, 195, 255), Size = Vector3.new(1.9, 1.9, 1.9), Feet = false, Material = Enum.Material.Neon, Extra = function(m, ctx)
	sideWings(m, ctx, rgb(235, 250, 255), 1.15)
	for _, side in { -1, 1 } do
		blob(m, Vector3.new(0.5, 0.9, 0.12), at(side * (ctx.A + 0.35), 0.35, 0.3) * CFrame.Angles(0, 0, side * math.rad(-35)), rgb(235, 250, 255), { Material = Enum.Material.Neon, Transparency = 0.25 })
	end
	diamond(m, Vector3.new(0.4, 0.4, 0.4), at(0, ctx.Top + 0.3, 0) * CFrame.Angles(math.rad(45), 0, 0), WHITE, { Material = Enum.Material.Neon })
end }
SPECS.IciclePup = { Body = rgb(185, 222, 250), Belly = rgb(240, 248, 255), Ears = "Bear", EarColor = rgb(120, 175, 235), EarInner = rgb(225, 240, 255), Extra = function(m, ctx)
	snout(m, ctx, rgb(240, 248, 255))
	tail(m, ctx, rgb(185, 222, 250), Vector3.new(0.5, 0.5, 1), rgb(120, 175, 235))
	cone(m, at(0, ctx.Top - 0.15, 0) * CFrame.Angles(math.rad(8), 0, 0), 0.22, 0.75, rgb(200, 245, 255), 4, { Material = Enum.Material.Glass, Transparency = 0.1 })
	blob(m, Vector3.new(0.3, 0.2, 0.1), CFrame.new(front(ctx, 0, -0.55, -0.02)), PINK)
end }
SPECS.FrostMammoth = { Body = rgb(150, 112, 90), Size = Vector3.new(2.7, 2.4, 2.5), Ears = "Bear", EarColor = rgb(125, 90, 72), EarInner = rgb(205, 160, 140), Extra = function(m, ctx)
	-- frosty fur cap
	blob(m, Vector3.new(ctx.A * 1.9, 0.7, ctx.C * 1.9), at(0, ctx.Top - 0.18, 0.05), rgb(235, 245, 255), { Material = Enum.Material.Snow })
	-- trunk
	local trunk = CFrame.new(front(ctx, 0, -0.35, -0.15))
	blob(m, Vector3.new(0.55, 0.7, 0.6), trunk, rgb(150, 112, 90))
	blob(m, Vector3.new(0.5, 0.5, 0.7), trunk * at(0, -0.5, -0.1), rgb(150, 112, 90))
	for _, side in { -1, 1 } do
		cone(m, at(side * 0.75, -0.55, -ctx.C + 0.3) * CFrame.Angles(math.rad(-90), 0, 0) * CFrame.Angles(0, 0, side * math.rad(12)), 0.2, 1.1, rgb(250, 245, 230), 5)
	end
end }
SPECS.BlizzardEagle = { Body = rgb(120, 175, 235), Belly = rgb(235, 245, 255), EyeRing = GOLD, EyeX = 0.46, FeetColor = ORANGE, Extra = function(m, ctx)
	beak(m, ctx, rgb(255, 200, 60))
	batWings(m, ctx, rgb(225, 240, 255), 1.3)
	for i = -1, 1 do
		diamond(m, Vector3.new(0.4, 0.55, 0.1), at(i * 0.26, ctx.Top + 0.12 - math.abs(i) * 0.08, 0.1) * CFrame.Angles(0, math.rad(90), math.rad(i * 24)), rgb(70, 130, 220))
	end
	tail(m, ctx, rgb(225, 240, 255), Vector3.new(0.9, 0.2, 1.1), rgb(70, 130, 220))
end }
SPECS.SnowLeopard = { Body = rgb(228, 230, 240), Ears = "Cat", EarInner = rgb(170, 175, 200), Extra = function(m, ctx)
	snout(m, ctx, rgb(245, 245, 252), rgb(120, 110, 130))
	local dark = rgb(70, 72, 98)
	for _, sp in { { -0.7, 0.7 }, { 0.75, 0.55 }, { -0.95, 0.05 }, { 0.95, -0.1 }, { -0.5, -0.65 }, { 0.55, -0.7 }, { 0, 0.95 } } do
		local sx, sy = sp[1], sp[2]
		local k = math.sqrt(math.max(0.02, 1 - (sx / ctx.A) ^ 2 - (sy / ctx.B) ^ 2))
		blob(m, Vector3.new(0.34, 0.28, 0.12), at(sx, sy, -ctx.C * k - 0.02), dark)
	end
	local t = at(0, -0.3, ctx.C + 0.4) * CFrame.Angles(math.rad(-25), 0, 0)
	blob(m, Vector3.new(0.38, 0.38, 1.7), t, rgb(228, 230, 240))
	for i = 0, 2 do
		blob(m, Vector3.new(0.42, 0.42, 0.18), t * at(0, 0, -0.5 + i * 0.5), dark)
	end
end }
SPECS.BlizzardWyrm = { Body = rgb(90, 65, 210), Belly = rgb(170, 150, 255), Size = Vector3.new(2.6, 2.4, 2.4), EyeGlow = true, Eye = rgb(100, 245, 255), Material = Enum.Material.Neon, Extra = function(m, ctx)
	horns(m, ctx, rgb(120, 245, 255), 0.85)
	batWings(m, ctx, rgb(120, 245, 255), 1.3)
	backSpikes(m, ctx, rgb(200, 255, 255), 3)
	tail(m, ctx, rgb(90, 65, 210), Vector3.new(0.55, 0.55, 1.6), rgb(120, 245, 255))
	cyl(m, 0.1, 3.2, at(0, ctx.Top + 0.75, 0), rgb(180, 255, 255), { Material = Enum.Material.Neon, Transparency = 0.35 })
end }

----------------------------------------------------------------------
-- Glow for the rare ones
----------------------------------------------------------------------
local function addFX(m: Model, root: BasePart, rarity: string)
	if rarity ~= "Legendary" and rarity ~= "Secret" then
		return
	end
	local e = Instance.new("ParticleEmitter")
	e.Name = "RarityFX"
	e.LightEmission = 1
	e.Rate = if rarity == "Secret" then 12 else 6
	e.Lifetime = NumberRange.new(0.8, 1.4)
	e.Speed = NumberRange.new(0.5, 1.5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.4, 0.3), NumberSequenceKeypoint.new(1, 0) })
	if rarity == "Secret" then
		e.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, rgb(255, 80, 80)),
			ColorSequenceKeypoint.new(0.33, rgb(255, 220, 60)),
			ColorSequenceKeypoint.new(0.66, rgb(80, 220, 255)),
			ColorSequenceKeypoint.new(1, rgb(200, 90, 255)),
		})
	else
		e.Color = ColorSequence.new(rgb(255, 230, 120), rgb(255, 180, 40))
	end
	e.Parent = root
	local light = Instance.new("PointLight")
	light.Range = 7
	light.Brightness = 1
	light.Color = if rarity == "Secret" then rgb(210, 150, 255) else rgb(255, 210, 100)
	light.Parent = root
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------
-- fallback for a pet without a spec: a coloured critter
local function fallbackSpec(petId: string)
	local pet = Pets.ById[petId]
	local rarity = pet and Pets.Rarities[pet.Rarity]
	return { Body = if rarity then lighter(rarity.Color, 0.2) else WHITE, Ears = "Cat" }
end

function PetModels.has(petId: string): boolean
	return SPECS[petId] ~= nil
end

-- fx = false skips the sparkles/light (e.g. for small UI previews)
function PetModels.build(petId: string, fx: boolean?): Model
	local m = Instance.new("Model")
	m.Name = petId
	local root = newPart(m, "Part", Vector3.one * 0.4, CFrame.new(), WHITE, { Transparency = 1, Name = "Root" })
	m.PrimaryPart = root
	local spec = SPECS[petId] or fallbackSpec(petId)
	local ctx = critter(m, spec)
	if spec.Extra then
		spec.Extra(m, ctx)
	end
	local pet = Pets.ById[petId]
	if pet and fx ~= false then
		addFX(m, root, pet.Rarity)
	end
	return m
end

-- a ViewportFrame showing the pet (for tiles and the hatch screen)
function PetModels.viewport(petId: string, parent: Instance, size: UDim2, position: UDim2?, anchor: Vector2?): (ViewportFrame, Model)
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = size
	vp.Position = position or UDim2.new()
	vp.AnchorPoint = anchor or Vector2.zero
	vp.Ambient = Color3.fromRGB(200, 200, 210)
	vp.LightColor = Color3.fromRGB(255, 255, 255)
	vp.LightDirection = Vector3.new(-0.4, -1, -0.6)
	local model = PetModels.build(petId, false)
	model:PivotTo(CFrame.Angles(0, math.rad(-25), 0))
	model.Parent = vp
	local camera = Instance.new("Camera")
	camera.FieldOfView = 32
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 1.6, -8.2), Vector3.new(0, 0.15, 0))
	camera.Parent = vp
	vp.CurrentCamera = camera
	vp.Parent = parent
	return vp, model
end

return PetModels
