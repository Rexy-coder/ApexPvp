--!nonstrict
-- Snowball Smash: the endless mountain.
-- The course is cut into chunks. Each chunk's contents come from a seeded
-- Random, so the server and every client generate exactly the same course.
-- Obstacles get tougher (and pay more) the further down you go, so nobody
-- can ever reach the bottom.

local Config = require(script.Parent:WaitForChild("Config"))

local CourseGen = {}

CourseGen.Seed = 2026
CourseGen.Origin = Vector3.new(0, 500, 0) -- top of the slope (where the lobby ends)
CourseGen.AngleDeg = 14
CourseGen.Width = 100
CourseGen.ChunkLength = 250
CourseGen.StartOffset = -16 -- where the snowball waits on the start pad
CourseGen.GateEvery = 1500 -- a Snow Fort gate across the whole slope every N studs
CourseGen.MarkerEvery = 500 -- distance sign every N studs

local ANGLE = math.rad(CourseGen.AngleDeg)
CourseGen.Right = Vector3.new(1, 0, 0)
CourseGen.Down = Vector3.new(0, -math.sin(ANGLE), -math.cos(ANGLE)) -- forward, down the slope
CourseGen.Normal = Vector3.new(0, math.cos(ANGLE), -math.sin(ANGLE))
CourseGen.Flat = Vector3.new(0, 0, -1)
CourseGen.SlopeCF = CFrame.fromMatrix(CourseGen.Origin, CourseGen.Right, CourseGen.Normal)

-- Obstacle kinds: size footprint (W across, D along the slope, H tall),
-- base toughness and base coins.
CourseGen.Kinds = {
	Snowman = { W = 4.4, D = 4.4, H = 10.5, Tough = 1, Coins = 12 },
	Fence = { W = 13.4, D = 1.2, H = 3.6, Tough = 1, Coins = 8 },
	Gifts = { W = 6, D = 3.6, H = 6, Tough = 1, Coins = 22 },
	Penguin = { W = 2.8, D = 2.8, H = 4.5, Tough = 1, Coins = 28 },
	Tree = { W = 8, D = 8, H = 17, Tough = 2, Coins = 18 },
	IceWall = { W = 16, D = 2, H = 8, Tough = 3, Coins = 30 },
	SnowWall = { W = 20.5, D = 3.4, H = 8, Tough = 4, Coins = 40 },
	IceTower = { W = 5, D = 5, H = 19, Tough = 6, Coins = 70 },
	Cabin = { W = 17, D = 15, H = 14, Tough = 7, Coins = 90 },
	Gate = { W = 100, D = 6, H = 20, Tough = 25, Coins = 400 },
	-- Halloween (only while Config.Halloween.Enabled)
	Pumpkin = { W = 5.5, D = 5.5, H = 6, Tough = 1, Coins = 20, Candy = 1 },
	GhostSnowman = { W = 4.6, D = 4.6, H = 11, Tough = 2, Coins = 30, Candy = 2 },
	-- Winter (only while Config.Winter.Enabled)
	GiantPresent = { W = 6, D = 6, H = 8, Tough = 1, Coins = 24, Presents = 1 },
	GingerHouse = { W = 9, D = 9, H = 11, Tough = 3, Coins = 45, Presents = 3 },
}

local POOLS = {
	{ Until = 600, Kinds = { "Snowman", "Snowman", "Fence", "Gifts", "Penguin" } },
	{ Until = 2000, Kinds = { "Snowman", "Tree", "Tree", "Fence", "Gifts", "Penguin", "IceWall", "SnowWall" } },
	{ Until = math.huge, Kinds = { "Tree", "IceWall", "SnowWall", "Cabin", "IceTower", "Penguin", "Gifts", "Tree", "Snowman" } },
}

-- difficulty / reward scaling with distance (in thousands of studs)
function CourseGen.ToughScale(s: number): number
	return 1 + 0.6 * math.max(0, s) / 1000
end
function CourseGen.CoinScale(s: number): number
	return 1 + 0.8 * math.max(0, s) / 1000
end

----------------------------------------------------------------------
-- Geometry
----------------------------------------------------------------------
-- point on the surface, its up vector and the forward direction
function CourseGen.Surface(s: number, x: number): (Vector3, Vector3, Vector3)
	if s < 0 then
		return CourseGen.Origin + CourseGen.Flat * s + CourseGen.Right * x, Vector3.yAxis, CourseGen.Flat
	end
	return CourseGen.Origin + CourseGen.Down * s + CourseGen.Right * x, CourseGen.Normal, CourseGen.Down
end

-- frame tilted with the slope (x right, y = surface normal, -z = downhill)
function CourseGen.SlopeFrame(s: number, x: number, h: number): CFrame
	return CourseGen.SlopeCF * CFrame.new(x, h, -s)
end

-- upright frame standing on the slope, sunk a little so the downhill edge touches
function CourseGen.Upright(s: number, x: number, depth: number?): CFrame
	local p = CourseGen.Origin + CourseGen.Down * s + CourseGen.Right * x
	return CFrame.new(p - Vector3.new(0, (depth or 4) * 0.5 * math.tan(ANGLE), 0))
end

----------------------------------------------------------------------
-- Chunk contents
----------------------------------------------------------------------
export type ObstacleSpec = {
	Kind: string,
	S: number,
	X: number,
	Rot: number,
	W: number,
	D: number,
	H: number,
	Tough: number,
	Coins: number,
	Candy: number,
	Presents: number,
	Variant: number,
}
export type PadSpec = { Kind: string, S: number, X: number }
export type CoinSpec = { S: number, X: number, H: number }
export type ChunkSpec = {
	Index: number,
	S0: number,
	S1: number,
	Obstacles: { ObstacleSpec },
	Pads: { PadSpec },
	Coins: { CoinSpec },
	Marker: number?,
	Value: number,
	Candy: number,
	Presents: number,
}

local cache: { [number]: ChunkSpec } = {}

local function inRange(list: { { number } }, s: number): boolean
	for _, r in list do
		if s > r[1] and s < r[2] then
			return true
		end
	end
	return false
end

function CourseGen.Chunk(index: number): ChunkSpec
	local cached = cache[index]
	if cached then
		return cached
	end
	local L = CourseGen.ChunkLength
	local s0, s1 = index * L, (index + 1) * L
	local rng = Random.new(CourseGen.Seed * 7919 + index * 104729)
	local half = CourseGen.Width / 2 - 8
	local chunk: ChunkSpec = { Index = index, S0 = s0, S1 = s1, Obstacles = {}, Pads = {}, Coins = {}, Marker = nil, Value = 0, Candy = 0, Presents = 0 }
	local reserved = {}

	local function addObstacle(kind: string, s: number, x: number)
		local k = CourseGen.Kinds[kind]
		local o: ObstacleSpec = {
			Kind = kind,
			S = s,
			X = x,
			Rot = rng:NextNumber() * math.pi * 2,
			W = k.W,
			D = k.D,
			H = k.H,
			Tough = k.Tough * CourseGen.ToughScale(s),
			Coins = math.floor(k.Coins * CourseGen.CoinScale(s) + 0.5),
			Candy = k.Candy or 0,
			Presents = k.Presents or 0,
			Variant = rng:NextInteger(1, 4),
		}
		table.insert(chunk.Obstacles, o)
		chunk.Value += o.Coins
		chunk.Candy += o.Candy
		chunk.Presents += o.Presents
	end

	-- gate across the slope
	local gateAt = math.ceil(s0 / CourseGen.GateEvery) * CourseGen.GateEvery
	if gateAt > 0 and gateAt >= s0 and gateAt < s1 then
		addObstacle("Gate", gateAt, 0)
		table.insert(reserved, { gateAt - 30, gateAt + 20 })
	end
	local markerAt = math.ceil(s0 / CourseGen.MarkerEvery) * CourseGen.MarkerEvery
	if markerAt > 0 and markerAt >= s0 and markerAt < s1 then
		chunk.Marker = markerAt
	end

	-- one boost pad per chunk, a ramp every other chunk
	if index >= 0 then
		local bs = s0 + rng:NextNumber(30, L - 60)
		if not inRange(reserved, bs) then
			local bx = rng:NextNumber(-half + 6, half - 6)
			table.insert(chunk.Pads, { Kind = "Boost", S = bs, X = bx })
			table.insert(reserved, { bs - 12, bs + 14 })
			for i = 0, 4 do
				table.insert(chunk.Coins, { S = bs + 14 + i * 6, X = bx, H = 3 })
			end
		end
		if index % 2 == 1 then
			local rs = s0 + rng:NextNumber(40, L - 80)
			if not inRange(reserved, rs) and not inRange(reserved, rs + 40) then
				local rx = rng:NextNumber(-half + 10, half - 10)
				table.insert(chunk.Pads, { Kind = "Ramp", S = rs, X = rx })
				table.insert(reserved, { rs - 25, rs + 60 })
				for i = 0, 6 do
					table.insert(chunk.Coins, { S = rs + 14 + i * 7, X = rx, H = 6 + math.sin(i / 6 * math.pi) * 14 })
				end
			end
		end
	end

	-- rows of obstacles, denser the further you go
	local s = math.max(s0, 50)
	while s < s1 do
		local d = s / 1000
		if not inRange(reserved, s) then
			local pool
			for _, p in POOLS do
				if s < p.Until then
					pool = p.Kinds
					break
				end
			end
			local perRow = rng:NextInteger(2, 3) + math.min(3, math.floor(d))
			local used = {}
			for _ = 1, perRow do
				local kind = pool[rng:NextInteger(1, #pool)]
				local spooky = rng:NextNumber()
				if Config.Halloween.Enabled and spooky < Config.Halloween.SpawnChance then
					kind = if spooky < Config.Halloween.SpawnChance * 0.6 then "Pumpkin" else "GhostSnowman"
				elseif Config.Winter.Enabled and spooky < Config.Winter.SpawnChance then
					kind = if spooky < Config.Winter.SpawnChance * 0.7 then "GiantPresent" else "GingerHouse"
				end
				local x = rng:NextNumber(-half, half)
				if kind == "Cabin" then
					x = math.clamp(x, -half + 4, half - 4)
				end
				local ok = true
				for _, ux in used do
					if math.abs(ux - x) < 15 then
						ok = false
					end
				end
				if ok then
					table.insert(used, x)
					addObstacle(kind, s + rng:NextNumber(-3, 3), x)
				end
			end
			if rng:NextNumber() < 0.45 then
				local cx = rng:NextNumber(-half, half)
				for i = 0, rng:NextInteger(3, 5) - 1 do
					table.insert(chunk.Coins, { S = s + 8 + i * 6, X = cx, H = 3 })
				end
			end
		end
		s += rng:NextNumber(18, 28) * math.max(0.55, 1.2 - d * 0.12)
	end

	cache[index] = chunk
	return chunk
end

-- Total coin value of every obstacle and coin pickup up to distance `s`
-- (used by the server to reject impossible run results).
function CourseGen.ValueUpTo(s: number, pickupValue: number): number
	local total = 0
	local last = math.floor(math.max(0, s) / CourseGen.ChunkLength)
	for i = 0, last do
		local chunk = CourseGen.Chunk(i)
		total += chunk.Value + #chunk.Coins * pickupValue
	end
	return total
end

-- Most Halloween candy a run up to distance `s` could collect
function CourseGen.CandyUpTo(s: number): number
	local total = 0
	for i = 0, math.floor(math.max(0, s) / CourseGen.ChunkLength) do
		total += CourseGen.Chunk(i).Candy
	end
	return total
end

-- Most Winter presents a run up to distance `s` could collect
function CourseGen.PresentsUpTo(s: number): number
	local total = 0
	for i = 0, math.floor(math.max(0, s) / CourseGen.ChunkLength) do
		total += CourseGen.Chunk(i).Presents
	end
	return total
end

function CourseGen.CountUpTo(s: number): number
	local total = 0
	for i = 0, math.floor(math.max(0, s) / CourseGen.ChunkLength) do
		total += #CourseGen.Chunk(i).Obstacles
	end
	return total
end

return CourseGen
