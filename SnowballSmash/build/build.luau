-- Snowball Smash place builder.
-- Run with Lune (https://lune-org.github.io/docs):  lune run build/build.luau
-- Builds the whole map + scripts and writes SnowballSmash.rbxl / .rbxlx

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local process = require("@lune/process")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum
local UDim2 = roblox.UDim2
local ColorSequence = roblox.ColorSequence
local NumberSequence = roblox.NumberSequence

local ROOT = process.args[1] or "."
local function read(path: string): string
	return fs.readFile(ROOT .. "/" .. path)
end

math.randomseed(1337)
local function rand(a: number, b: number): number
	return a + math.random() * (b - a)
end
local function pick<T>(list: { T }): T
	return list[math.random(1, #list)]
end

local game = Instance.new("DataModel")
local workspace = game:GetService("Workspace")
local lighting = game:GetService("Lighting")
local replicated = game:GetService("ReplicatedStorage")
local serverScripts = game:GetService("ServerScriptService")
local starterPlayer = game:GetService("StarterPlayer")
local _starterGui = game:GetService("StarterGui")
local _soundService = game:GetService("SoundService")
local _players = game:GetService("Players")

----------------------------------------------------------------------
-- Colours
----------------------------------------------------------------------
local function rgb(r: number, g: number, b: number)
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
local BLUE = rgb(70, 130, 255)
local ROCK = rgb(150, 168, 196)

----------------------------------------------------------------------
-- Part helpers
----------------------------------------------------------------------
local function part(parent, props)
	local className = props.Class or "Part"
	local p = Instance.new(className)
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Color = props.Color or WHITE
	p.Size = props.Size or Vector3.new(4, 1, 2)
	p.CFrame = props.CFrame or CFrame.new()
	if props.Shape then
		p.Shape = props.Shape
	end
	if props.Transparency then
		p.Transparency = props.Transparency
	end
	if props.CanCollide ~= nil then
		p.CanCollide = props.CanCollide
	end
	if props.CastShadow ~= nil then
		p.CastShadow = props.CastShadow
	end
	if props.Reflectance then
		p.Reflectance = props.Reflectance
	end
	p.Name = props.Name or "Part"
	p.Parent = parent
	return p
end

local function folder(parent, name: string)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function model(parent, name: string)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

----------------------------------------------------------------------
-- Slope geometry (shared with the client via attributes)
----------------------------------------------------------------------
local ANGLE_DEG = 15
local ANGLE = math.rad(ANGLE_DEG)
local LENGTH = 1800
local WIDTH = 100
local P0 = Vector3.new(0, 500, 0)
local RIGHT = Vector3.new(1, 0, 0)
local DOWN = Vector3.new(0, -math.sin(ANGLE), -math.cos(ANGLE))
local NORMAL = Vector3.new(0, math.cos(ANGLE), -math.sin(ANGLE))
local SLOPE_CF = CFrame.fromMatrix(P0, RIGHT, NORMAL)
local TAN = math.tan(ANGLE)

local function slopeCF(s: number, x: number, h: number)
	return SLOPE_CF * CFrame.new(x, h, -s)
end
local function surfacePoint(s: number, x: number)
	return P0 + DOWN * s + RIGHT * x
end
-- upright frame standing on the slope; sink a bit so the downhill edge touches
local function uprightCF(s: number, x: number, depth: number?)
	local p = surfacePoint(s, x) - Vector3.new(0, (depth or 4) * 0.5 * TAN, 0)
	return CFrame.new(p)
end

local course = model(workspace, "Course")
course:SetAttribute("SlopeOrigin", P0)
course:SetAttribute("SlopeAngle", ANGLE_DEG)
course:SetAttribute("SlopeLength", LENGTH)
course:SetAttribute("SlopeWidth", WIDTH)
course:SetAttribute("StartOffset", -16)

local terrainFolder = folder(course, "Mountain")
local decor = folder(course, "Decor")
local smashables = folder(course, "Smashables")
local pickups = folder(course, "Pickups")
local pads = folder(course, "Pads")

----------------------------------------------------------------------
-- The mountain: checker snow slope, candy-cane rails, rock body
----------------------------------------------------------------------
local TILE = 25
for row = 0, LENGTH / TILE - 1 do
	for col = 0, WIDTH / TILE - 1 do
		local s = row * TILE + TILE / 2
		local x = -WIDTH / 2 + col * TILE + TILE / 2
		part(terrainFolder, {
			Name = "Snow",
			Size = Vector3.new(TILE, 4, TILE),
			CFrame = slopeCF(s, x, -2),
			Color = if (row + col) % 2 == 0 then SNOW_A else SNOW_B,
			Material = Enum.Material.Snow,
		})
	end
end

-- candy-cane rails along both edges
local SEG = 10
for i = 0, LENGTH / SEG - 1 do
	for _, side in { -1, 1 } do
		part(terrainFolder, {
			Name = "Rail",
			Size = Vector3.new(2, 2, SEG),
			CFrame = slopeCF(i * SEG + SEG / 2, side * (WIDTH / 2 + 1), 1),
			Color = if i % 2 == 0 then RED else WHITE,
		})
	end
end

-- rock body under the slope (wedges point downhill)
local runZ = LENGTH * math.cos(ANGLE)
local drop = LENGTH * math.sin(ANGLE)
local bottomY = P0.Y - drop
for _, spec in { { W = WIDTH + 6, Sink = 4, X = 0, Color = rgb(226, 238, 250) }, { W = 140, Sink = 22, X = -WIDTH / 2 - 70, Color = ROCK }, { W = 140, Sink = 22, X = WIDTH / 2 + 70, Color = ROCK } } do
	part(terrainFolder, {
		Class = "WedgePart",
		Name = "MountainBody",
		Size = Vector3.new(spec.W, drop, runZ),
		CFrame = CFrame.new(spec.X, bottomY + drop / 2 - spec.Sink, -runZ / 2),
		Color = spec.Color,
		Material = Enum.Material.Snow,
	})
	if bottomY - spec.Sink > 1 then
		part(terrainFolder, {
			Name = "MountainBase",
			Size = Vector3.new(spec.W, bottomY - spec.Sink, runZ),
			CFrame = CFrame.new(spec.X, (bottomY - spec.Sink) / 2, -runZ / 2),
			Color = spec.Color,
			Material = Enum.Material.Snow,
		})
	end
end

-- valley floor
for gx = -1, 1 do
	for gz = -1, 1 do
		part(terrainFolder, {
			Name = "Ground",
			Size = Vector3.new(2048, 4, 2048),
			CFrame = CFrame.new(gx * 2048, -2, -800 + gz * 2048),
			Color = rgb(232, 242, 252),
			Material = Enum.Material.Snow,
		})
	end
end

----------------------------------------------------------------------
-- Lobby plaza at the top
----------------------------------------------------------------------
local lobby = folder(course, "Lobby")
local PLAZA_W, PLAZA_D = 180, 130
local PZ = 20
for ix = 0, PLAZA_W / 20 - 1 do
	for iz = 0, PLAZA_D / 20 - 1 do
		part(lobby, {
			Name = "PlazaTile",
			Size = Vector3.new(20, 4, 20),
			CFrame = CFrame.new(-PLAZA_W / 2 + ix * 20 + 10, P0.Y - 2, iz * 20 + 10),
			Color = if (ix + iz) % 2 == 0 then SNOW_A else SNOW_B,
			Material = Enum.Material.Snow,
		})
	end
end
part(lobby, {
	Name = "PlazaBase",
	Size = Vector3.new(PLAZA_W, P0.Y - 4, PLAZA_D),
	CFrame = CFrame.new(0, (P0.Y - 4) / 2, PLAZA_D / 2),
	Color = ROCK,
	Material = Enum.Material.Snow,
})

-- start pad: blue with a yellow border (where the snowball sits)
local padModel = model(lobby, "StartPad")
part(padModel, { Name = "Border", Size = Vector3.new(30, 1, 30), CFrame = CFrame.new(0, P0.Y + 0.2, 16), Color = YELLOW })
local padTop = part(padModel, { Name = "Pad", Size = Vector3.new(26, 1, 26), CFrame = CFrame.new(0, P0.Y + 0.35, 16), Color = BLUE })
local prompt = Instance.new("ProximityPrompt")
prompt.Name = "RollPrompt"
prompt.ActionText = "Roll!"
prompt.ObjectText = "Snowball Launcher"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.HoldDuration = 0
prompt.MaxActivationDistance = 22
prompt.RequiresLineOfSight = false
prompt.Parent = padTop

-- the giant decorative snowball next to the pad
part(lobby, { Name = "BigSnowball", Shape = Enum.PartType.Ball, Size = Vector3.new(14, 14, 14), CFrame = CFrame.new(-32, P0.Y + 7, 40), Color = SNOW_A, Material = Enum.Material.Snow })
part(lobby, { Name = "BigSnowball", Shape = Enum.PartType.Ball, Size = Vector3.new(9, 9, 9), CFrame = CFrame.new(30, P0.Y + 4.5, 46), Color = SNOW_A, Material = Enum.Material.Snow })

-- spawn
local spawn = Instance.new("SpawnLocation")
spawn.Name = "Spawn"
spawn.Anchored = true
spawn.Size = Vector3.new(12, 1, 12)
spawn.CFrame = CFrame.new(0, P0.Y + 0.5, 60)
spawn.Color = YELLOW
spawn.Material = Enum.Material.SmoothPlastic
spawn.TopSurface = Enum.SurfaceType.Smooth
spawn.Neutral = true
spawn.Duration = 0
spawn.Parent = lobby

-- candy-cane arch over the start of the slope with a big sign
local function caneColumn(x: number, z: number, height: number)
	for i = 0, height / 3 - 1 do
		part(decor, {
			Name = "Cane",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(3, 3.2, 3.2),
			CFrame = CFrame.new(x, P0.Y + i * 3 + 1.5, z) * CFrame.Angles(0, 0, math.rad(90)),
			Color = if i % 2 == 0 then RED else WHITE,
		})
	end
end
caneColumn(-WIDTH / 2 - 6, 3, 33)
caneColumn(WIDTH / 2 + 6, 3, 33)
local sign = part(decor, {
	Name = "Sign",
	Size = Vector3.new(WIDTH + 18, 12, 2),
	CFrame = CFrame.new(0, P0.Y + 38, 3),
	Color = rgb(98, 60, 38),
	Material = Enum.Material.WoodPlanks,
})
part(decor, { Name = "SignTrim", Size = Vector3.new(WIDTH + 22, 2, 3), CFrame = CFrame.new(0, P0.Y + 44.5, 3), Color = YELLOW })
part(decor, { Name = "SignTrim", Size = Vector3.new(WIDTH + 22, 2, 3), CFrame = CFrame.new(0, P0.Y + 31.5, 3), Color = YELLOW })
for _, face in { Enum.NormalId.Back, Enum.NormalId.Front } do
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.Text = "❄ SNOWBALL SMASH ❄"
	label.TextScaled = true
	label.TextColor3 = WHITE
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 6
	stroke.Color = rgb(28, 18, 12)
	stroke.Parent = label
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(rgb(255, 240, 120), rgb(255, 170, 40))
	grad.Rotation = 90
	grad.Parent = label
end

----------------------------------------------------------------------
-- Decoration builders
----------------------------------------------------------------------
local function pineTree(parent, cf, scale: number)
	local m = model(parent, "PineTree")
	local s = scale
	part(m, { Name = "Trunk", Size = Vector3.new(1.6, 4, 1.6) * s, CFrame = cf * CFrame.new(0, 2 * s, 0), Color = WOOD, Material = Enum.Material.Wood })
	local tiers = { { 9, 3 }, { 7, 2.8 }, { 5, 2.6 }, { 3, 2.4 } }
	local y = 4 * s
	for i, t in tiers do
		local w, h = t[1] * s, t[2] * s
		part(m, { Name = "Leaves", Size = Vector3.new(w, h, w), CFrame = cf * CFrame.new(0, y + h / 2, 0) * CFrame.Angles(0, math.rad(i * 12), 0), Color = if i % 2 == 0 then PINE_DARK else PINE, Material = Enum.Material.Grass })
		part(m, { Name = "SnowCap", Size = Vector3.new(w * 0.8, 0.5 * s, w * 0.8), CFrame = cf * CFrame.new(0, y + h + 0.1, 0) * CFrame.Angles(0, math.rad(i * 12), 0), Color = SNOW_A, Material = Enum.Material.Snow })
		y += h * 0.85
	end
	part(m, { Name = "Star", Size = Vector3.new(1.4, 1.4, 1.4) * s, CFrame = cf * CFrame.new(0, y + 1 * s, 0) * CFrame.Angles(0, 0, math.rad(45)), Color = YELLOW, Material = Enum.Material.Neon })
	return m
end

local function cloud(parent, pos)
	local m = model(parent, "Cloud")
	local n = math.random(3, 6)
	for _ = 1, n do
		local size = Vector3.new(rand(20, 46), rand(8, 14), rand(16, 30))
		part(m, {
			Name = "Puff",
			Size = size,
			CFrame = CFrame.new(pos + Vector3.new(rand(-30, 30), rand(-4, 6), rand(-14, 14))),
			Color = WHITE,
			CanCollide = false,
			CastShadow = false,
		})
	end
end

local function peak(parent, pos, w: number, h: number, color)
	-- two wedges back to back make a ridge, plus a snow cap
	local m = model(parent, "Peak")
	part(m, { Class = "WedgePart", Name = "Side", Size = Vector3.new(w, h, w / 2), CFrame = CFrame.new(pos + Vector3.new(0, h / 2, w / 4)) * CFrame.Angles(0, math.pi, 0), Color = color, Material = Enum.Material.Slate })
	part(m, { Class = "WedgePart", Name = "Side", Size = Vector3.new(w, h, w / 2), CFrame = CFrame.new(pos + Vector3.new(0, h / 2, -w / 4)), Color = color, Material = Enum.Material.Slate })
	local ch = h * 0.3
	part(m, { Class = "WedgePart", Name = "Cap", Size = Vector3.new(w * 0.3 + 2, ch, w * 0.15 + 1), CFrame = CFrame.new(pos + Vector3.new(0, h - ch / 2 + 0.6, w * 0.075)) * CFrame.Angles(0, math.pi, 0), Color = SNOW_A, Material = Enum.Material.Snow })
	part(m, { Class = "WedgePart", Name = "Cap", Size = Vector3.new(w * 0.3 + 2, ch, w * 0.15 + 1), CFrame = CFrame.new(pos + Vector3.new(0, h - ch / 2 + 0.6, -w * 0.075)), Color = SNOW_A, Material = Enum.Material.Snow })
end

-- trees around the plaza
for _ = 1, 22 do
	local x = rand(-PLAZA_W / 2 + 6, PLAZA_W / 2 - 6)
	local z = rand(30, PLAZA_D - 6)
	if math.abs(x) > 24 or z > 80 then
		if not (math.abs(x) < 10 and math.abs(z - 60) < 10) then
			pineTree(decor, CFrame.new(x, P0.Y, z) * CFrame.Angles(0, rand(0, 6), 0), rand(1, 1.6))
		end
	end
end
-- trees on the mountain shoulders beside the run
for i = 1, 70 do
	local s = rand(20, LENGTH - 20)
	local side = if i % 2 == 0 then -1 else 1
	local off = rand(WIDTH / 2 + 8, WIDTH / 2 + 60)
	-- the shoulder wedges sit 22 studs below the slope surface
	local p = surfacePoint(s, side * off) - Vector3.new(0, 22.5, 0)
	pineTree(decor, CFrame.new(p) * CFrame.Angles(0, rand(0, 6), 0), rand(1.3, 2.2))
end
-- clouds
for _ = 1, 40 do
	cloud(decor, Vector3.new(rand(-700, 700), rand(560, 720), rand(-2000, 400)))
end
-- distant peaks
for i = 1, 16 do
	local side = if i % 2 == 0 then -1 else 1
	peak(decor, Vector3.new(side * rand(320, 650), 0, rand(-1900, 200)), rand(180, 320), rand(260, 520), pick({ rgb(160, 176, 206), rgb(140, 158, 192), rgb(176, 190, 216) }))
end
for i = 1, 6 do
	peak(decor, Vector3.new(rand(-500, 500), 0, -2100 - rand(0, 300)), rand(260, 380), rand(300, 560), rgb(150, 166, 200))
	local _ = i
end

----------------------------------------------------------------------
-- Smashable builders. Each returns a Model with Kind/Toughness/Coins.
----------------------------------------------------------------------
local function smashable(name: string, toughness: number, coins: number)
	local m = model(smashables, name)
	m:SetAttribute("Kind", name)
	m:SetAttribute("Toughness", toughness)
	m:SetAttribute("Coins", coins)
	return m
end

local function snowman(s: number, x: number)
	local m = smashable("Snowman", 1, 12)
	local cf = uprightCF(s, x, 4.4) * CFrame.Angles(0, math.pi + rand(-0.4, 0.4), 0)
	part(m, { Shape = Enum.PartType.Ball, Name = "Base", Size = Vector3.new(4.4, 4.4, 4.4), CFrame = cf * CFrame.new(0, 2.2, 0), Color = SNOW_A, Material = Enum.Material.Snow })
	part(m, { Shape = Enum.PartType.Ball, Name = "Middle", Size = Vector3.new(3.3, 3.3, 3.3), CFrame = cf * CFrame.new(0, 5.4, 0), Color = SNOW_A, Material = Enum.Material.Snow })
	part(m, { Shape = Enum.PartType.Ball, Name = "Head", Size = Vector3.new(2.4, 2.4, 2.4), CFrame = cf * CFrame.new(0, 7.9, 0), Color = SNOW_A, Material = Enum.Material.Snow })
	part(m, { Name = "Nose", Size = Vector3.new(0.4, 0.4, 1.4), CFrame = cf * CFrame.new(0, 7.9, -1.6), Color = rgb(255, 140, 30) })
	part(m, { Name = "Eye", Size = Vector3.new(0.35, 0.35, 0.2), CFrame = cf * CFrame.new(-0.45, 8.3, -1.1), Color = rgb(20, 20, 20) })
	part(m, { Name = "Eye", Size = Vector3.new(0.35, 0.35, 0.2), CFrame = cf * CFrame.new(0.45, 8.3, -1.1), Color = rgb(20, 20, 20) })
	part(m, { Name = "HatBrim", Size = Vector3.new(2.6, 0.3, 2.6), CFrame = cf * CFrame.new(0, 9, 0), Color = rgb(30, 30, 36) })
	part(m, { Name = "Hat", Size = Vector3.new(1.7, 1.6, 1.7), CFrame = cf * CFrame.new(0, 9.9, 0), Color = rgb(30, 30, 36) })
	part(m, { Name = "Scarf", Size = Vector3.new(2.8, 0.6, 2.8), CFrame = cf * CFrame.new(0, 6.8, 0), Color = pick({ RED, BLUE, rgb(60, 200, 90) }) })
end

local function fence(s: number, x: number)
	local m = smashable("Fence", 1, 8)
	local cf = uprightCF(s, x, 1)
	for i = -1, 1 do
		part(m, { Name = "Post", Size = Vector3.new(1, 4, 1), CFrame = cf * CFrame.new(i * 6, 2, 0), Color = WOOD_DARK, Material = Enum.Material.Wood })
	end
	part(m, { Name = "Rail", Size = Vector3.new(13, 0.8, 0.6), CFrame = cf * CFrame.new(0, 2.8, 0), Color = WOOD, Material = Enum.Material.WoodPlanks })
	part(m, { Name = "Rail", Size = Vector3.new(13, 0.8, 0.6), CFrame = cf * CFrame.new(0, 1.4, 0), Color = WOOD, Material = Enum.Material.WoodPlanks })
	part(m, { Name = "Snow", Size = Vector3.new(13.4, 0.3, 1), CFrame = cf * CFrame.new(0, 3.35, 0), Color = SNOW_A, Material = Enum.Material.Snow })
end

local function gifts(s: number, x: number)
	local m = smashable("Gifts", 1, 22)
	local cf = uprightCF(s, x, 5) * CFrame.Angles(0, rand(-0.5, 0.5), 0)
	local colors = { RED, rgb(60, 190, 90), BLUE, rgb(190, 90, 240) }
	local boxes = { { 0, 0, 3.4 }, { 3.2, 0.6, 2.6 }, { 1.4, 0, 2 } }
	local y = 0
	for i, b in boxes do
		local size = b[3]
		local bx = if i == 3 then 0.8 else b[1] - 1.6
		local by = if i == 3 then 3.4 else 0
		local c = colors[(i + math.random(0, 3)) % #colors + 1]
		local boxCF = cf * CFrame.new(bx, by + size / 2, b[2])
		part(m, { Name = "Box", Size = Vector3.new(size, size, size), CFrame = boxCF, Color = c })
		part(m, { Name = "Ribbon", Size = Vector3.new(size + 0.1, size + 0.1, 0.5), CFrame = boxCF, Color = YELLOW })
		part(m, { Name = "Ribbon", Size = Vector3.new(0.5, size + 0.1, size + 0.1), CFrame = boxCF, Color = YELLOW })
		y = math.max(y, by + size)
	end
end

local function tree(s: number, x: number)
	local m = smashable("Tree", 2, 18)
	m:SetAttribute("Kind", "Tree")
	local built = pineTree(smashables, uprightCF(s, x, 9) * CFrame.Angles(0, rand(0, 6), 0), 1)
	for _, p in built:GetChildren() do
		p.Parent = m
	end
	built:Destroy()
end

local function iceWall(s: number, x: number, cols: number?)
	local m = smashable("IceWall", 3, 30)
	local n = cols or 4
	local cf = uprightCF(s, x, 2)
	for c = 0, n - 1 do
		for r = 0, 1 do
			part(m, {
				Name = "Ice",
				Size = Vector3.new(3.9, 3.9, 2),
				CFrame = cf * CFrame.new((c - (n - 1) / 2) * 4, r * 4 + 2, 0),
				Color = ICE,
				Material = Enum.Material.Ice,
				Transparency = 0.25,
				Reflectance = 0.1,
			})
		end
	end
end

local function brickWall(s: number, x: number)
	local m = smashable("SnowWall", 4, 40)
	local cf = uprightCF(s, x, 3)
	local colors = { rgb(120, 170, 255), rgb(90, 140, 240), rgb(150, 195, 255) }
	for r = 0, 2 do
		local offset = if r % 2 == 0 then 0 else 2
		for c = 0, 4 do
			part(m, {
				Name = "Brick",
				Size = Vector3.new(3.9, 2.4, 3),
				CFrame = cf * CFrame.new((c - 2) * 4 + offset - 1, r * 2.5 + 1.2, 0),
				Color = pick(colors),
				Material = Enum.Material.Glacier,
			})
		end
	end
	part(m, { Name = "SnowTop", Size = Vector3.new(20.5, 0.6, 3.4), CFrame = cf * CFrame.new(0, 7.8, 0), Color = SNOW_A, Material = Enum.Material.Snow })
end

local function penguin(s: number, x: number)
	local m = smashable("Penguin", 1, 28)
	local cf = uprightCF(s, x, 2.6) * CFrame.Angles(0, math.pi + rand(-0.6, 0.6), 0)
	part(m, { Shape = Enum.PartType.Ball, Name = "Body", Size = Vector3.new(2.8, 2.8, 2.8), CFrame = cf * CFrame.new(0, 1.6, 0), Color = rgb(30, 34, 46) })
	part(m, { Shape = Enum.PartType.Ball, Name = "Belly", Size = Vector3.new(2.1, 2.3, 2.1), CFrame = cf * CFrame.new(0, 1.5, -0.45), Color = WHITE })
	part(m, { Shape = Enum.PartType.Ball, Name = "Head", Size = Vector3.new(1.9, 1.9, 1.9), CFrame = cf * CFrame.new(0, 3.5, 0), Color = rgb(30, 34, 46) })
	part(m, { Name = "Beak", Size = Vector3.new(0.5, 0.35, 0.8), CFrame = cf * CFrame.new(0, 3.4, -1.1), Color = rgb(255, 160, 30) })
	part(m, { Name = "Foot", Size = Vector3.new(0.7, 0.25, 0.9), CFrame = cf * CFrame.new(-0.6, 0.15, -0.4), Color = rgb(255, 160, 30) })
	part(m, { Name = "Foot", Size = Vector3.new(0.7, 0.25, 0.9), CFrame = cf * CFrame.new(0.6, 0.15, -0.4), Color = rgb(255, 160, 30) })
end

local function cabin(s: number, x: number)
	local m = smashable("Cabin", 7, 90)
	local cf = uprightCF(s, x, 12) * CFrame.Angles(0, if math.random() < 0.5 then 0 else math.pi, 0)
	local W, D, H = 14, 12, 8
	for i = 0, H / 2 - 1 do
		local y = i * 2 + 1
		local c = if i % 2 == 0 then WOOD else WOOD_DARK
		part(m, { Name = "Log", Size = Vector3.new(W, 2, 1.4), CFrame = cf * CFrame.new(0, y, -D / 2), Color = c, Material = Enum.Material.Wood })
		part(m, { Name = "Log", Size = Vector3.new(W, 2, 1.4), CFrame = cf * CFrame.new(0, y, D / 2), Color = c, Material = Enum.Material.Wood })
		part(m, { Name = "Log", Size = Vector3.new(1.4, 2, D), CFrame = cf * CFrame.new(-W / 2, y, 0), Color = c, Material = Enum.Material.Wood })
		part(m, { Name = "Log", Size = Vector3.new(1.4, 2, D), CFrame = cf * CFrame.new(W / 2, y, 0), Color = c, Material = Enum.Material.Wood })
	end
	part(m, { Name = "Door", Size = Vector3.new(3, 5, 0.4), CFrame = cf * CFrame.new(0, 2.5, -D / 2 - 0.6), Color = rgb(200, 60, 50) })
	part(m, { Name = "Window", Size = Vector3.new(2.6, 2.4, 0.3), CFrame = cf * CFrame.new(-4.2, 4.6, -D / 2 - 0.6), Color = rgb(255, 220, 120), Material = Enum.Material.Neon })
	part(m, { Name = "Window", Size = Vector3.new(2.6, 2.4, 0.3), CFrame = cf * CFrame.new(4.2, 4.6, -D / 2 - 0.6), Color = rgb(255, 220, 120), Material = Enum.Material.Neon })
	-- roof: two tilted slabs + snow
	local roofAngle = math.rad(32)
	for _, side in { -1, 1 } do
		local roofCF = cf * CFrame.new(side * W / 4, H + 2.2, 0) * CFrame.Angles(0, 0, side * -roofAngle)
		part(m, { Name = "Roof", Size = Vector3.new(W / 2 / math.cos(roofAngle) + 1.6, 1, D + 2.4), CFrame = roofCF, Color = rgb(196, 44, 50) })
		part(m, { Name = "RoofSnow", Size = Vector3.new(W / 2 / math.cos(roofAngle) + 1.2, 0.6, D + 2.6), CFrame = roofCF * CFrame.new(0, 0.75, 0), Color = SNOW_A, Material = Enum.Material.Snow })
	end
	part(m, { Name = "Chimney", Size = Vector3.new(1.8, 4, 1.8), CFrame = cf * CFrame.new(3, H + 4.5, 2), Color = rgb(150, 70, 60), Material = Enum.Material.Brick })
end

local function iceTower(s: number, x: number)
	local m = smashable("IceTower", 6, 70)
	local cf = uprightCF(s, x, 5)
	for i = 0, 3 do
		local size = 5 - i * 0.7
		part(m, {
			Name = "Ice",
			Size = Vector3.new(size, 4, size),
			CFrame = cf * CFrame.new(0, i * 4 + 2, 0) * CFrame.Angles(0, math.rad(i * 20), 0),
			Color = ICE,
			Material = Enum.Material.Ice,
			Transparency = 0.2,
			Reflectance = 0.1,
		})
	end
	part(m, { Name = "Crystal", Size = Vector3.new(1.6, 3, 1.6), CFrame = cf * CFrame.new(0, 17.5, 0) * CFrame.Angles(0, 0, math.rad(45)), Color = rgb(120, 230, 255), Material = Enum.Material.Neon })
end

local function snowFort(s: number)
	local m = smashable("SnowFort", 30, 600)
	local cf = uprightCF(s, 0, 8)
	local w = WIDTH - 4
	for r = 0, 3 do
		local offset = if r % 2 == 0 then 0 else 3
		local count = math.floor(w / 6)
		for c = 0, count - 1 do
			local bx = -w / 2 + c * 6 + 3 + offset
			if bx < w / 2 - 2 then
				part(m, {
					Name = "Block",
					Size = Vector3.new(5.9, 3.9, 6),
					CFrame = cf * CFrame.new(bx, r * 4 + 2, 0),
					Color = if (r + c) % 2 == 0 then SNOW_A else SNOW_B,
					Material = Enum.Material.Snow,
				})
			end
		end
	end
	for c = 0, math.floor(w / 12) - 1 do
		part(m, { Name = "Crenel", Size = Vector3.new(5, 4, 6), CFrame = cf * CFrame.new(-w / 2 + c * 12 + 4, 18, 0), Color = SNOW_A, Material = Enum.Material.Snow })
	end
	for _, fx in { -w / 2 + 4, 0, w / 2 - 4 } do
		part(m, { Name = "FlagPole", Size = Vector3.new(0.6, 10, 0.6), CFrame = cf * CFrame.new(fx, 25, 0), Color = WOOD_DARK })
		part(m, { Name = "Flag", Size = Vector3.new(4, 2.6, 0.3), CFrame = cf * CFrame.new(fx + 2.2, 28.6, 0), Color = RED })
	end
end

----------------------------------------------------------------------
-- Pads and coins
----------------------------------------------------------------------
local function boostPad(s: number, x: number)
	local base = part(pads, {
		Name = "BoostPad",
		Size = Vector3.new(12, 0.4, 16),
		CFrame = slopeCF(s, x, 0.15),
		Color = rgb(40, 220, 255),
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	base:SetAttribute("PadType", "Boost")
	for i = 0, 1 do
		for _, side in { -1, 1 } do
			part(pads, {
				Name = "Arrow",
				Size = Vector3.new(6, 0.3, 1.4),
				CFrame = slopeCF(s - 3 + i * 6, x + side * 2.3, 0.45) * CFrame.Angles(0, math.rad(side * 40), 0),
				Color = WHITE,
				Material = Enum.Material.Neon,
				CanCollide = false,
			})
		end
	end
end

local function ramp(s: number, x: number)
	local w = 18
	local wedge = part(pads, {
		Class = "WedgePart",
		Name = "Ramp",
		Size = Vector3.new(w, 5, 16),
		CFrame = slopeCF(s, x, 2.5) * CFrame.Angles(0, math.pi, 0),
		Color = SNOW_A,
		Material = Enum.Material.Snow,
	})
	wedge:SetAttribute("PadType", "Ramp")
	for _, side in { -1, 1 } do
		part(pads, {
			Class = "WedgePart",
			Name = "RampEdge",
			Size = Vector3.new(1, 5.2, 16.2),
			CFrame = slopeCF(s, x + side * (w / 2 + 0.5), 2.6) * CFrame.Angles(0, math.pi, 0),
			Color = YELLOW,
		})
	end
end

local function coin(s: number, x: number, h: number)
	part(pickups, {
		Name = "Coin",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 3, 3),
		CFrame = CFrame.new(surfacePoint(s, x) + Vector3.new(0, h, 0)) * CFrame.Angles(0, math.pi / 2, 0),
		Color = rgb(255, 196, 30),
		Material = Enum.Material.SmoothPlastic,
		Reflectance = 0.15,
		CanCollide = false,
	})
end

local function coinLine(s: number, x: number, count: number)
	for i = 0, count - 1 do
		coin(s + i * 6, x, 3)
	end
end

----------------------------------------------------------------------
-- Course layout (seeded, so the course is the same every build)
----------------------------------------------------------------------
local HALF = WIDTH / 2 - 8
local reserved: { { number } } = {}
local function isFree(s: number): boolean
	for _, r in reserved do
		if s > r[1] and s < r[2] then
			return false
		end
	end
	return true
end

-- ramps and boost pads first so obstacles stay clear of them
local s = 120
local n = 0
while s < LENGTH - 120 do
	n += 1
	if n % 2 == 0 then
		local x = rand(-HALF + 10, HALF - 10)
		ramp(s, x)
		table.insert(reserved, { s - 25, s + 60 })
		-- arc of coins in the air after the ramp
		for i = 0, 6 do
			coin(s + 14 + i * 7, x, 6 + math.sin(i / 6 * math.pi) * 14)
		end
	else
		local x = rand(-HALF + 6, HALF - 6)
		boostPad(s, x)
		table.insert(reserved, { s - 12, s + 14 })
		coinLine(s + 14, x, 5)
	end
	s += rand(130, 190)
end

local EARLY = { snowman, snowman, fence, gifts, penguin }
local MID = { snowman, tree, tree, fence, gifts, penguin, iceWall, brickWall }
local LATE = { tree, iceWall, brickWall, cabin, iceTower, penguin, gifts, tree }

s = 50
while s < LENGTH - 70 do
	if isFree(s) then
		local t = s / LENGTH
		local pool = if t < 0.25 then EARLY elseif t < 0.6 then MID else LATE
		local perRow = if t < 0.25 then math.random(2, 3) elseif t < 0.6 then math.random(3, 4) else math.random(3, 5)
		local used: { number } = {}
		for _ = 1, perRow do
			local builder = pick(pool)
			local x = rand(-HALF, HALF)
			local ok = true
			for _, ux in used do
				if math.abs(ux - x) < 15 then
					ok = false
				end
			end
			if ok then
				table.insert(used, x)
				if builder == cabin then
					x = math.clamp(x, -HALF + 4, HALF - 4)
				end
				builder(s + rand(-3, 3), x)
			end
		end
		-- sprinkle coins between rows
		if math.random() < 0.45 then
			coinLine(s + 8, rand(-HALF, HALF), math.random(3, 5))
		end
	end
	s += rand(18, 28) * (if s / LENGTH < 0.25 then 1.2 else 1)
end

snowFort(LENGTH - 26)

-- finish arch at the bottom
local finishS = LENGTH - 4
for _, side in { -1, 1 } do
	local base = surfacePoint(finishS, side * (WIDTH / 2 + 2))
	for i = 0, 12 do
		part(decor, {
			Name = "Cane",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(3, 3.2, 3.2),
			CFrame = CFrame.new(base + Vector3.new(0, i * 3 + 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = if i % 2 == 0 then RED else WHITE,
		})
	end
end
part(decor, {
	Name = "EndWall",
	Size = Vector3.new(WIDTH + 10, 30, 6),
	CFrame = slopeCF(LENGTH + 3, 0, 12),
	Color = ICE,
	Material = Enum.Material.Ice,
	Transparency = 0.15,
})

----------------------------------------------------------------------
-- Lighting: bright, saturated cartoon winter
----------------------------------------------------------------------
lighting.ClockTime = 13.6
lighting.Brightness = 3
lighting.Ambient = rgb(118, 128, 150)
lighting.OutdoorAmbient = rgb(170, 182, 205)
lighting.GlobalShadows = true
lighting.EnvironmentDiffuseScale = 0.6
lighting.EnvironmentSpecularScale = 0.6
lighting.ShadowSoftness = 0.25
lighting.Technology = Enum.Technology.ShadowMap

local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.28
atmosphere.Offset = 0.2
atmosphere.Color = rgb(205, 226, 255)
atmosphere.Decay = rgb(120, 150, 200)
atmosphere.Glare = 0.2
atmosphere.Haze = 1.1
atmosphere.Parent = lighting

local sky = Instance.new("Sky")
sky.SunAngularSize = 14
sky.Parent = lighting

local cc = Instance.new("ColorCorrectionEffect")
cc.Saturation = 0.2
cc.Contrast = 0.08
cc.Brightness = 0.02
cc.TintColor = rgb(250, 252, 255)
cc.Parent = lighting

local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.5
bloom.Size = 24
bloom.Threshold = 1.4
bloom.Parent = lighting

local rays = Instance.new("SunRaysEffect")
rays.Intensity = 0.04
rays.Spread = 0.6
rays.Parent = lighting

workspace.StreamingEnabled = false
workspace.Gravity = 196.2

starterPlayer.CameraMaxZoomDistance = 80
starterPlayer.CharacterWalkSpeed = 20

----------------------------------------------------------------------
-- Scripts and remotes
----------------------------------------------------------------------
local shared = folder(replicated, "Shared")
local config = Instance.new("ModuleScript")
config.Name = "Config"
config.Source = read("src/shared/Config.luau")
config.Parent = shared

local remotes = folder(replicated, "Remotes")
for _, name in { "GetData", "StartRun", "FinishRun", "BuyUpgrade", "BuySkin", "Rebirth" } do
	local r = Instance.new("RemoteFunction")
	r.Name = name
	r.Parent = remotes
end
for _, name in { "DataChanged", "SetSetting" } do
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
end

local server = Instance.new("Script")
server.Name = "GameServer"
server.Source = read("src/server/GameServer.server.luau")
server.Parent = serverScripts

local sps = starterPlayer:FindFirstChildOfClass("StarterPlayerScripts")
if not sps then
	sps = Instance.new("StarterPlayerScripts")
	sps.Parent = starterPlayer
end
local client = Instance.new("LocalScript")
client.Name = "SnowballClient"
client.Source = read("src/client/Main.client.luau")
client.Parent = sps
for _, name in { "UIKit", "Effects", "Hud", "Panels", "UpgradeTree", "Runner" } do
	local m = Instance.new("ModuleScript")
	m.Name = name
	m.Source = read("src/client/" .. name .. ".luau")
	m.Parent = client
end

----------------------------------------------------------------------
-- Write the place
----------------------------------------------------------------------
local count = 0
for _, d in game:GetDescendants() do
	if d:IsA("BasePart") then
		count += 1
	end
end
fs.writeFile(ROOT .. "/SnowballSmash.rbxl", roblox.serializePlace(game))
fs.writeFile(ROOT .. "/SnowballSmash.rbxlx", roblox.serializePlace(game, true))
print(string.format("Built SnowballSmash.rbxl  (%d parts, %d smashables, %d coins, %d pads)", count, #smashables:GetChildren(), #pickups:GetChildren(), #pads:GetChildren()))
