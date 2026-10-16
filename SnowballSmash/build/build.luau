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
local UDim = roblox.UDim
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
-- Slope geometry (must match ReplicatedStorage.Shared.CourseGen)
----------------------------------------------------------------------
local ANGLE_DEG = 14
local ANGLE = math.rad(ANGLE_DEG)
local WIDTH = 100
local P0 = Vector3.new(0, 500, 0)
local RIGHT = Vector3.new(1, 0, 0)
local DOWN = Vector3.new(0, -math.sin(ANGLE), -math.cos(ANGLE))
local NORMAL = Vector3.new(0, math.cos(ANGLE), -math.sin(ANGLE))
local SLOPE_CF = CFrame.fromMatrix(P0, RIGHT, NORMAL)

local function slopeCF(s: number, x: number, h: number)
	return SLOPE_CF * CFrame.new(x, h, -s)
end
local function surfacePoint(s: number, x: number)
	return P0 + DOWN * s + RIGHT * x
end

-- The real course is endless and built by each client while playing
-- (ReplicatedStorage.Shared.CourseGen + CourseBuilder). This preview of the
-- first stretch only exists so you can see the slope in Studio's editor;
-- the server deletes it when the game starts.
local course = model(workspace, "Course")
local preview = folder(course, "Preview")
local TILE = 50
for row = 0, 500 / TILE - 1 do
	for col = 0, WIDTH / TILE - 1 do
		part(preview, {
			Name = "Snow",
			Size = Vector3.new(TILE, 4, TILE),
			CFrame = slopeCF(row * TILE + TILE / 2, -WIDTH / 2 + col * TILE + TILE / 2, -2),
			Color = if (row + col) % 2 == 0 then SNOW_A else SNOW_B,
			Material = Enum.Material.Snow,
		})
	end
end
for i = 0, 49 do
	for _, side in { -1, 1 } do
		part(preview, {
			Name = "Rail",
			Size = Vector3.new(2, 2, 10),
			CFrame = slopeCF(i * 10 + 5, side * (WIDTH / 2 + 1), 1),
			Color = if i % 2 == 0 then RED else WHITE,
		})
	end
end

local decor = folder(workspace, "Decor")

----------------------------------------------------------------------
-- Lobby plaza at the top
----------------------------------------------------------------------
local lobby = folder(workspace, "Lobby")
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

----------------------------------------------------------------------
-- Egg stands (Update 2: pets). Client shows the egg panel when you walk up.
----------------------------------------------------------------------
local EGGS = {
	{ Id = "Frosty", Name = "Frosty Egg", Price = "2,500 coins", Color = rgb(170, 225, 255), X = -75 },
	{ Id = "Glacier", Name = "Glacier Egg", Price = "40,000 coins", Color = rgb(90, 170, 255), X = -45 },
	{ Id = "Aurora", Name = "Aurora Egg", Price = "500,000 coins", Color = rgb(190, 120, 255), X = -15 },
	{ Id = "Blizzard", Name = "Blizzard Egg", Price = "5,000,000 coins", Color = rgb(110, 90, 235), X = 15 },
	{ Id = "Spooky", Name = "Spooky Egg", Price = "250 candy", Color = rgb(255, 130, 30), X = 45 },
	{ Id = "Winter", Name = "Winter Egg", Price = "300 presents", Color = rgb(235, 60, 70), X = 75 },
}
local eggFolder = folder(lobby, "Eggs")
for _, e in EGGS do
	local m = model(eggFolder, "Egg_" .. e.Id)
	local base = Vector3.new(e.X, P0.Y, 104)
	part(m, { Name = "Pedestal", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 12, 12), CFrame = CFrame.new(base + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(120, 140, 175), Material = Enum.Material.Slate })
	part(m, { Name = "Rim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 12.6, 12.6), CFrame = CFrame.new(base + Vector3.new(0, 3.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = e.Color, Material = Enum.Material.Neon })
	local egg = part(m, { Name = "Egg", Size = Vector3.new(7, 9, 7), CFrame = CFrame.new(base + Vector3.new(0, 8, 0)), Color = e.Color })
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = egg
	for _, spot in { { 1.6, 9.8, -2.6, 1.6 }, { -1.8, 7, -2.9, 1.3 }, { 0.6, 6, -3.2, 1 }, { -1, 10.6, -1.9, 1 } } do
		part(m, { Name = "Spot", Shape = Enum.PartType.Ball, Size = Vector3.one * spot[4], CFrame = CFrame.new(base + Vector3.new(spot[1], spot[2], spot[3])), Color = WHITE })
	end
	m.PrimaryPart = egg
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(240, 80)
	gui.StudsOffset = Vector3.new(0, 7.5, 0)
	gui.MaxDistance = 90
	gui.LightInfluence = 0
	gui.Parent = egg
	for i, info in { { e.Name, 46, WHITE }, { e.Price, 30, rgb(255, 220, 80) } } do
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 0, info[2])
		label.Position = UDim2.fromOffset(0, if i == 1 then 0 else 46)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.Text = info[1]
		label.TextColor3 = info[3]
		label.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 3
		stroke.Color = rgb(28, 18, 12)
		stroke.Parent = label
	end
end

----------------------------------------------------------------------
-- Global leaderboards (filled by the server every minute)
----------------------------------------------------------------------
local boardsFolder = folder(lobby, "Leaderboards")
for _, b in { { Name = "DistanceBoard", Title = "🏁 TOP DISTANCE", X = -76, Dir = 1 }, { Name = "CoinsBoard", Title = "💰 TOP COINS EARNED", X = 76, Dir = -1 } } do
	local m = model(boardsFolder, b.Name)
	local pos = Vector3.new(b.X, P0.Y + 15, 70)
	local cf = CFrame.lookAt(pos, pos + Vector3.new(b.Dir, 0, 0))
	for _, side in { -1, 1 } do
		part(m, { Name = "Post", Size = Vector3.new(2, 30, 2), CFrame = cf * CFrame.new(side * 12, 0, 0.8), Color = rgb(98, 60, 38), Material = Enum.Material.Wood })
	end
	local board = part(m, { Name = "Board", Size = Vector3.new(24, 28, 1), CFrame = cf, Color = rgb(98, 60, 38), Material = Enum.Material.WoodPlanks })
	part(m, { Name = "Snow", Size = Vector3.new(25, 1.2, 2.4), CFrame = cf * CFrame.new(0, 14.4, 0), Color = SNOW_A, Material = Enum.Material.Snow })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 25
	gui.LightInfluence = 0
	gui.Parent = board
	local title = Instance.new("TextLabel")
	title.BackgroundColor3 = YELLOW
	title.Size = UDim2.new(1, -40, 0, 80)
	title.Position = UDim2.fromOffset(20, 18)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.Text = b.Title
	title.TextColor3 = WHITE
	title.Parent = gui
	local tStroke = Instance.new("UIStroke")
	tStroke.Thickness = 4
	tStroke.Color = rgb(28, 18, 12)
	tStroke.Parent = title
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = title
	local list = Instance.new("Frame")
	list.Name = "List"
	list.BackgroundTransparency = 1
	list.Size = UDim2.new(1, -40, 1, -130)
	list.Position = UDim2.fromOffset(20, 115)
	list.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	for i = 1, 10 do
		local row = Instance.new("Frame")
		row.Name = "Row" .. i
		row.LayoutOrder = i
		row.Size = UDim2.new(1, 0, 0, 50)
		row.BackgroundColor3 = if i == 1 then rgb(255, 205, 60) elseif i == 2 then rgb(200, 210, 225) elseif i == 3 then rgb(215, 140, 80) else rgb(70, 42, 26)
		row.Parent = list
		local rc = Instance.new("UICorner")
		rc.CornerRadius = UDim.new(0, 10)
		rc.Parent = row
		for _, col in { { "Rank", "#" .. i, 0, 0.14, Enum.TextXAlignment.Center }, { "PlayerName", "-", 0.15, 0.55, Enum.TextXAlignment.Left }, { "Value", "", 0.7, 0.28, Enum.TextXAlignment.Right } } do
			local label = Instance.new("TextLabel")
			label.Name = col[1]
			label.BackgroundTransparency = 1
			label.Size = UDim2.new(col[4], 0, 1, -10)
			label.Position = UDim2.new(col[3], 0, 0, 5)
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			label.Text = col[2]
			label.TextColor3 = WHITE
			label.TextXAlignment = col[5]
			label.Parent = row
			local st = Instance.new("UIStroke")
			st.Thickness = 2.5
			st.Color = rgb(28, 18, 12)
			st.Parent = label
		end
	end
end

----------------------------------------------------------------------
-- Halloween decorations (the server removes them when the event is off)
----------------------------------------------------------------------
local spooky = folder(lobby, "Halloween")
local function pumpkin(pos, s)
	local m = model(spooky, "Pumpkin")
	for i = -2, 2 do
		part(m, { Name = "Body", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 4.6, 4.6) * s, CFrame = CFrame.new(pos + Vector3.new(i * 0.85 * s, 2.3 * s, 0)) * CFrame.Angles(0, i * 0.35, 0), Color = if i % 2 == 0 then rgb(255, 130, 20) else rgb(240, 110, 15) })
	end
	part(m, { Name = "Stem", Size = Vector3.new(0.7, 1.4, 0.7) * s, CFrame = CFrame.new(pos + Vector3.new(0, 4.9 * s, 0)), Color = rgb(70, 120, 40) })
	for _, eye in { -0.9, 0.9 } do
		part(m, { Name = "Eye", Size = Vector3.new(0.9, 0.7, 0.3) * s, CFrame = CFrame.new(pos + Vector3.new(eye * s, 2.9 * s, -2.25 * s)), Color = rgb(255, 230, 90), Material = Enum.Material.Neon })
	end
	part(m, { Name = "Mouth", Size = Vector3.new(2.2, 0.5, 0.3) * s, CFrame = CFrame.new(pos + Vector3.new(0, 1.7 * s, -2.25 * s)), Color = rgb(255, 230, 90), Material = Enum.Material.Neon })
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 160, 60)
	light.Range = 14 * s
	light.Brightness = 1.5
	light.Parent = m:FindFirstChild("Mouth")
end
for _, p in { { -20, 30, 1.2 }, { 20, 30, 1 }, { -60, 40, 1.4 }, { 60, 45, 1.2 }, { -30, 92, 0.9 }, { 30, 92, 0.9 }, { -84, 110, 1.3 }, { 84, 110, 1.3 } } do
	pumpkin(Vector3.new(p[1], P0.Y, p[2]), p[3])
end

----------------------------------------------------------------------
-- Winter decorations (the server removes them when the event is off)
----------------------------------------------------------------------
local winter = folder(lobby, "Winter")
local LIGHT_COLORS = { RED, rgb(60, 220, 90), rgb(70, 150, 255), YELLOW, rgb(255, 120, 220) }

-- giant Christmas tree behind the eggs
do
	local m = model(winter, "ChristmasTree")
	local s = 2.7
	local base = Vector3.new(0, P0.Y, 124)
	part(m, { Name = "Trunk", Size = Vector3.new(2, 5, 2) * s, CFrame = CFrame.new(base + Vector3.new(0, 2.5 * s, 0)), Color = WOOD, Material = Enum.Material.Wood })
	local tiers = { { 9, 3.4 }, { 7.6, 3.2 }, { 6, 3 }, { 4.4, 2.8 }, { 2.8, 2.6 } }
	local y = 4.5 * s
	local n = 0
	for i, t in tiers do
		local w, h = t[1] * s, t[2] * s
		local rot = CFrame.Angles(0, math.rad(i * 15), 0)
		part(m, { Name = "Leaves", Size = Vector3.new(w, h, w), CFrame = CFrame.new(base + Vector3.new(0, y + h / 2, 0)) * rot, Color = if i % 2 == 0 then PINE_DARK else PINE, Material = Enum.Material.Grass })
		part(m, { Name = "SnowCap", Size = Vector3.new(w * 0.8, 0.5 * s, w * 0.8), CFrame = CFrame.new(base + Vector3.new(0, y + h + 0.1, 0)) * rot, Color = SNOW_A, Material = Enum.Material.Snow })
		-- glowing ornaments around each tier
		local count = 10 - i
		for k = 0, count - 1 do
			local a = k / count * math.pi * 2 + i
			local r = w * 0.52
			n += 1
			local ball = part(m, {
				Name = "Ornament",
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * (1.1 * s * 0.6),
				CFrame = CFrame.new(base + Vector3.new(math.cos(a) * r, y + h * 0.35, math.sin(a) * r)),
				Color = LIGHT_COLORS[n % #LIGHT_COLORS + 1],
				Material = Enum.Material.Neon,
				CanCollide = false,
			})
			if k % 3 == 0 then
				local light = Instance.new("PointLight")
				light.Color = ball.Color
				light.Range = 10
				light.Brightness = 1.2
				light.Parent = ball
			end
		end
		y += h * 0.85
	end
	local star = part(m, { Name = "Star", Size = Vector3.new(2.4, 2.4, 0.8) * s, CFrame = CFrame.new(base + Vector3.new(0, y + 1.6 * s, 0)) * CFrame.Angles(0, 0, math.rad(45)), Color = YELLOW, Material = Enum.Material.Neon })
	local starLight = Instance.new("PointLight")
	starLight.Color = rgb(255, 220, 120)
	starLight.Range = 30
	starLight.Brightness = 2
	starLight.Parent = star
end

-- piles of presents
local function present(pos: Vector3, size: number, color, ribbon, turn: number)
	local m = model(winter, "Present")
	local cf = CFrame.new(pos + Vector3.new(0, size / 2, 0)) * CFrame.Angles(0, turn, 0)
	part(m, { Name = "Box", Size = Vector3.one * size, CFrame = cf, Color = color })
	part(m, { Name = "Ribbon", Size = Vector3.new(size + 0.1, size + 0.1, size * 0.18), CFrame = cf, Color = ribbon })
	part(m, { Name = "Ribbon", Size = Vector3.new(size * 0.18, size + 0.1, size + 0.1), CFrame = cf, Color = ribbon })
	part(m, { Name = "Bow", Shape = Enum.PartType.Ball, Size = Vector3.one * size * 0.3, CFrame = cf * CFrame.new(0, size / 2 + size * 0.1, 0), Color = ribbon, Material = Enum.Material.Neon })
end
for _, g in { { -10, 116, 4, 1 }, { 9, 117, 3.4, 2 }, { -14, 121, 2.6, 3 }, { 13, 121, 3, 4 }, { -6, 113, 2.4, 5 }, { 6, 112, 2.2, 1 }, { 0, 113, 2.8, 3 } } do
	local wrap = ({ { RED, YELLOW }, { rgb(40, 170, 80), RED }, { BLUE, WHITE }, { rgb(190, 90, 240), YELLOW }, { WHITE, RED } })[g[4]]
	present(Vector3.new(g[1], P0.Y, g[2]), g[3], wrap[1], wrap[2], math.rad(g[1] * 7))
end

-- string lights hanging under the big sign over the slope
for i = 0, 40 do
	local x = -WIDTH / 2 - 4 + i * ((WIDTH + 8) / 40)
	local sag = math.sin(i / 40 * math.pi) * 3
	part(winter, {
		Name = "Bulb",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 1.1,
		CFrame = CFrame.new(x, P0.Y + 29.5 - sag, 3),
		Color = LIGHT_COLORS[i % #LIGHT_COLORS + 1],
		Material = Enum.Material.Neon,
		CanCollide = false,
		CastShadow = false,
	})
end

-- warm lamp posts along the plaza
for _, l in { { -40, 28 }, { 40, 28 }, { -40, 84 }, { 40, 84 } } do
	local m = model(winter, "LampPost")
	part(m, { Name = "Pole", Shape = Enum.PartType.Cylinder, Size = Vector3.new(12, 0.8, 0.8), CFrame = CFrame.new(l[1], P0.Y + 6, l[2]) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(40, 40, 50) })
	local lamp = part(m, { Name = "Lamp", Shape = Enum.PartType.Ball, Size = Vector3.one * 2.2, CFrame = CFrame.new(l[1], P0.Y + 12.6, l[2]), Color = rgb(255, 220, 140), Material = Enum.Material.Neon })
	part(m, { Name = "Cap", Size = Vector3.new(2.6, 0.5, 2.6), CFrame = CFrame.new(l[1], P0.Y + 13.9, l[2]), Color = SNOW_A, Material = Enum.Material.Snow })
	for k = 0, 3 do
		part(m, { Name = "Cane", Size = Vector3.new(1, 1.4, 1), CFrame = CFrame.new(l[1], P0.Y + 0.7 + k * 1.4, l[2]), Color = if k % 2 == 0 then RED else WHITE })
	end
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 200, 130)
	light.Range = 24
	light.Brightness = 1.6
	light.Parent = lamp
end

----------------------------------------------------------------------
-- Fusion Machine (Update 5): walk up and press E to open the Pets menu
----------------------------------------------------------------------
do
	local m = model(lobby, "FusionMachine")
	local base = Vector3.new(62, P0.Y, 24)
	part(m, { Name = "Base", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 15, 15), CFrame = CFrame.new(base + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(96, 110, 150), Material = Enum.Material.Slate })
	part(m, { Name = "Ring", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 15.6, 15.6), CFrame = CFrame.new(base + Vector3.new(0, 3.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = YELLOW, Material = Enum.Material.Neon })
	local dome = part(m, { Name = "Dome", Shape = Enum.PartType.Ball, Size = Vector3.new(11, 11, 11), CFrame = CFrame.new(base + Vector3.new(0, 9.5, 0)), Color = rgb(255, 150, 230), Material = Enum.Material.Glass, Transparency = 0.45 })
	part(m, { Name = "Core", Shape = Enum.PartType.Ball, Size = Vector3.new(4.5, 4.5, 4.5), CFrame = CFrame.new(base + Vector3.new(0, 9.5, 0)), Color = rgb(255, 225, 110), Material = Enum.Material.Neon })
	for i = 0, 2 do
		local a = i / 3 * math.pi * 2
		part(m, { Name = "Pod", Shape = Enum.PartType.Ball, Size = Vector3.one * 2, CFrame = CFrame.new(base + Vector3.new(math.cos(a) * 5.4, 4.8, math.sin(a) * 5.4)), Color = ({ rgb(255, 215, 70), rgb(255, 120, 200), rgb(110, 200, 255) })[i + 1], Material = Enum.Material.Neon })
	end
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 190, 240)
	light.Range = 26
	light.Brightness = 2
	light.Parent = dome
	local fuse = Instance.new("ProximityPrompt")
	fuse.Name = "FusePrompt"
	fuse.ActionText = "Fuse pets"
	fuse.ObjectText = "Fusion Machine"
	fuse.KeyboardKeyCode = Enum.KeyCode.F
	fuse.HoldDuration = 0
	fuse.MaxActivationDistance = 16
	fuse.RequiresLineOfSight = false
	fuse.Parent = dome
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(300, 90)
	gui.StudsOffset = Vector3.new(0, 11.5, 0)
	gui.MaxDistance = 120
	gui.LightInfluence = 0
	gui.Parent = dome
	for i, info in { { "✨ PET FUSION", 50, WHITE }, { "3 same pets = 1 shiny!", 28, rgb(255, 225, 120) } } do
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 0, info[2])
		label.Position = UDim2.fromOffset(0, if i == 1 then 0 else 52)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.Text = info[1]
		label.TextColor3 = info[3]
		label.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 3
		stroke.Color = rgb(28, 18, 12)
		stroke.Parent = label
	end
end

-- trees around the plaza
for _ = 1, 48 do
	local x = rand(-PLAZA_W / 2 + 6, PLAZA_W / 2 - 6)
	local z = rand(30, PLAZA_D - 6)
	-- keep clear of the pad, spawn, egg row (z ~ 100) and the leaderboards (x ~ +-72)
	local nearEggs = z > 86 and math.abs(x) < 86
	local nearBoards = math.abs(x) > 56 and z > 48 and z < 92
	local nearMachine = math.abs(x - 62) < 14 and math.abs(z - 24) < 14
	local nearLamps = math.abs(math.abs(x) - 40) < 7 and (math.abs(z - 28) < 7 or math.abs(z - 84) < 7)
	if (math.abs(x) > 24 or z > 80) and not nearEggs and not nearBoards and not nearLamps and not nearMachine then
		if not (math.abs(x) < 10 and math.abs(z - 60) < 10) then
			pineTree(decor, CFrame.new(x, P0.Y, z) * CFrame.Angles(0, rand(0, 6), 0), rand(1, 1.6))
		end
	end
end
-- clouds
for _ = 1, 40 do
	cloud(decor, Vector3.new(rand(-700, 700), rand(560, 720), rand(-2000, 400)))
end
-- distant peaks
for i = 1, 16 do
	local side = if i % 2 == 0 then -1 else 1
	peak(decor, Vector3.new(side * rand(480, 850), 0, rand(-1900, 200)), rand(180, 320), rand(260, 520), pick({ rgb(160, 176, 206), rgb(140, 158, 192), rgb(176, 190, 216) }))
end
for i = 1, 6 do
	local side2 = if i % 2 == 0 then -1 else 1
	peak(decor, Vector3.new(side2 * rand(500, 900), 0, -2100 - rand(0, 600)), rand(260, 380), rand(300, 560), rgb(150, 166, 200))
	local _ = i
end

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
workspace.FallenPartsDestroyHeight = -50000
workspace.Gravity = 196.2

starterPlayer.CameraMaxZoomDistance = 80
starterPlayer.CharacterWalkSpeed = 20

----------------------------------------------------------------------
-- Scripts and remotes
----------------------------------------------------------------------
local function module(parent, name: string, path: string)
	local m = Instance.new("ModuleScript")
	m.Name = name
	m.Source = read(path)
	m.Parent = parent
	return m
end

local shared = folder(replicated, "Shared")
module(shared, "Config", "src/shared/Config.luau")
module(shared, "Monetization", "src/shared/Monetization.luau")
module(shared, "Sounds", "src/shared/Sounds.luau")
module(shared, "CourseGen", "src/shared/CourseGen.luau")
module(shared, "Pets", "src/shared/Pets.luau")

local remotes = folder(replicated, "Remotes")
for _, name in { "GetData", "StartRun", "FinishRun", "BuyUpgrade", "BuySkin", "Rebirth", "UseTurbo", "AdminAction", "HatchEgg", "PetAction", "ClaimDaily", "RedeemCode" } do
	local r = Instance.new("RemoteFunction")
	r.Name = name
	r.Parent = remotes
end
for _, name in { "DataChanged", "SetSetting", "Notify" } do
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
end

-- live server state (storm end times) replicated to every client as attributes
local gameState = Instance.new("Configuration")
gameState.Name = "GameState"
for _, id in { "Coins2", "Coins3", "Mutation", "Growth", "Speed", "Lucky", "Meteor", "Galaxy", "PetParty" } do
	gameState:SetAttribute("Event_" .. id, 0)
end
gameState:SetAttribute("CrazyAuto", true)
gameState:SetAttribute("CrazyIncoming", "")
gameState:SetAttribute("CrazyIncomingAt", 0)
gameState:SetAttribute("NextCrazy", 0)
gameState.Parent = replicated

local server = Instance.new("Script")
server.Name = "GameServer"
server.Source = read("src/server/GameServer.server.luau")
server.Parent = serverScripts
module(serverScripts, "AdminConfig", "src/server/AdminConfig.luau")
module(serverScripts, "Codes", "src/server/Codes.luau")

local sps = starterPlayer:FindFirstChildOfClass("StarterPlayerScripts")
if not sps then
	sps = Instance.new("StarterPlayerScripts")
	sps.Parent = starterPlayer
end
local client = Instance.new("LocalScript")
client.Name = "SnowballClient"
client.Source = read("src/client/Main.client.luau")
client.Parent = sps
for _, name in { "UIKit", "Effects", "Hud", "Panels", "UpgradeTree", "CourseBuilder", "Runner", "PetsUI", "DailyUI", "CrazyFX", "PetModels" } do
	module(client, name, "src/client/" .. name .. ".luau")
end

-- new chat (needed for the [VIP] / [ADMIN] chat tags)
local textChat = game:GetService("TextChatService")
textChat.ChatVersion = Enum.ChatVersion.TextChatService

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
print(string.format("Built SnowballSmash.rbxl  (%d parts in the lobby / preview)", count))
