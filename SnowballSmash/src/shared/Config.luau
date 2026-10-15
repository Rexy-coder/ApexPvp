--!nonstrict
-- Snowball Smash: shared game configuration (used by server and client).
-- Tweak the numbers here to balance the game.

local Config = {}

----------------------------------------------------------------------
-- Run physics (studs, seconds)
----------------------------------------------------------------------
Config.Physics = {
	StartRadius = 3, -- snowball radius at launch
	BaseLaunch = 72, -- speed at 100% power
	BaseFriction = 9, -- speed lost per second while rolling
	BaseGrowth = 0.012, -- radius gained per stud rolled
	BaseMaxRadius = 9,
	BaseSteer = 26, -- sideways speed
	BaseSmash = 1,
	BaseComboTime = 1.6,
	BaseCrit = 0.05,
	BaseBoost = 30, -- speed added by a boost pad
	RampLift = 42, -- upward speed off a ramp
	Gravity = 95,
	MaxSpeed = 175,
	StopSpeed = 2.5,
	SmashLoss = 9, -- speed lost per toughness point (divided by smash power)
	DistanceCoinRate = 0.5, -- coins per stud rolled
	MaxCombo = 5, -- highest combo multiplier
	SizeBonusDiv = 10, -- coins x(1 + (radius - start) / this)
	PickupValue = 5,
	MaxRunTime = 300,
}

----------------------------------------------------------------------
-- Upgrade tree (hex grid, flat-top axial coordinates {q, r})
----------------------------------------------------------------------
export type Branch = {
	Id: string,
	Name: string,
	Icon: string,
	Stat: string,
	Desc: string,
	Per: number,
	Unit: string, -- "%" or a suffix
	BaseCost: number,
	Growth: number,
	From: string, -- node id the first tier hangs off
	Cells: { { number } },
}

Config.Branches = {
	{ Id = "Push", Name = "Push Power", Icon = "🚀", Stat = "Launch", Desc = "Launch the snowball faster.", Per = 25, Unit = "%",
		BaseCost = 80, Growth = 3.5, From = "Start", Cells = { { 0, -1 }, { 0, -2 }, { 0, -3 }, { 0, -4 }, { 0, -5 } } },
	{ Id = "Growth", Name = "Snow Pack", Icon = "❄️", Stat = "Growth", Desc = "Your snowball grows faster while rolling.", Per = 35, Unit = "%",
		BaseCost = 120, Growth = 3.6, From = "Start", Cells = { { 1, -1 }, { 2, -2 }, { 3, -3 }, { 4, -4 } } },
	{ Id = "Smash", Name = "Smash Power", Icon = "🔨", Stat = "Smash", Desc = "Lose less speed when you smash things.", Per = 40, Unit = "%",
		BaseCost = 100, Growth = 3.5, From = "Start", Cells = { { 1, 0 }, { 2, 0 }, { 3, 0 }, { 4, 0 }, { 5, 0 } } },
	{ Id = "Coin", Name = "Coin Bonus", Icon = "💰", Stat = "Coins", Desc = "Earn more coins from everything.", Per = 50, Unit = "%",
		BaseCost = 150, Growth = 3.7, From = "Start", Cells = { { 0, 1 }, { 0, 2 }, { 0, 3 }, { 0, 4 }, { 0, 5 }, { 0, 6 } } },
	{ Id = "Combo", Name = "Combo Time", Icon = "🔥", Stat = "Combo window", Desc = "More time to chain smashes into a combo.", Per = 0.4, Unit = "s",
		BaseCost = 120, Growth = 3.5, From = "Start", Cells = { { -1, 1 }, { -2, 2 }, { -3, 3 }, { -4, 4 }, { -5, 5 } } },
	{ Id = "Steer", Name = "Carving", Icon = "💨", Stat = "Steering", Desc = "Steer left and right more sharply.", Per = 30, Unit = "%",
		BaseCost = 60, Growth = 3.2, From = "Start", Cells = { { -1, 0 }, { -2, 0 }, { -3, 0 }, { -4, 0 } } },
	{ Id = "Slick", Name = "Slick Wax", Icon = "⛸️", Stat = "Friction", Desc = "Less friction, so you roll further.", Per = -12, Unit = "%",
		BaseCost = 900, Growth = 3.8, From = "Push2", Cells = { { 1, -3 }, { 2, -4 }, { 3, -5 } } },
	{ Id = "Mega", Name = "Mega Ball", Icon = "⛄", Stat = "Max size", Desc = "Raise the biggest size your snowball can reach.", Per = 3, Unit = " studs",
		BaseCost = 1200, Growth = 3.8, From = "Growth2", Cells = { { 3, -2 }, { 4, -2 }, { 5, -2 }, { 6, -2 } } },
	{ Id = "Lucky", Name = "Lucky Flake", Icon = "🍀", Stat = "Critical chance", Desc = "Chance for a CRITICAL smash worth double coins.", Per = 5, Unit = "%",
		BaseCost = 1000, Growth = 3.8, From = "Smash2", Cells = { { 2, 1 }, { 2, 2 }, { 2, 3 } } },
	{ Id = "Boost", Name = "Turbo Pads", Icon = "⚡", Stat = "Boost pads", Desc = "Boost pads give you more speed.", Per = 30, Unit = "%",
		BaseCost = 800, Growth = 3.6, From = "Coin2", Cells = { { -1, 3 }, { -2, 4 }, { -3, 5 } } },
	{ Id = "Air", Name = "Big Air", Icon = "🎈", Stat = "Ramp height", Desc = "Fly higher off ramps and sail over obstacles.", Per = 25, Unit = "%",
		BaseCost = 700, Growth = 3.6, From = "Steer2", Cells = { { -2, -1 }, { -2, -2 }, { -2, -3 } } },
	-- Update 3: pets, eggs, candy and turbo upgrades
	{ Id = "PetPower", Name = "Pet Power", Icon = "🐾", Stat = "Pet bonuses", Desc = "Your equipped pets give bigger bonuses.", Per = 15, Unit = "%",
		BaseCost = 5000, Growth = 3.5, From = "Smash4", Cells = { { 4, 1 }, { 4, 2 }, { 4, 3 }, { 4, 4 }, { 4, 5 } } },
	{ Id = "HatchLuck", Name = "Hatch Luck", Icon = "🌈", Stat = "Rare+ pet luck", Desc = "Better chance to hatch Rare, Epic, Legendary and Secret pets.", Per = 10, Unit = "%",
		BaseCost = 8000, Growth = 4, From = "Growth4", Cells = { { 5, -4 }, { 6, -4 }, { 7, -4 }, { 8, -4 } } },
	{ Id = "EggDiscount", Name = "Egg Discount", Icon = "🏷️", Stat = "Egg price", Desc = "Eggs cost less to hatch.", Per = -5, Unit = "%",
		BaseCost = 6000, Growth = 3.8, From = "Air3", Cells = { { -3, -3 }, { -4, -3 }, { -5, -3 }, { -6, -3 } } },
	{ Id = "PetStorage", Name = "Pet Storage", Icon = "🎒", Stat = "Pet storage", Desc = "Hold more pets in your inventory.", Per = 15, Unit = " pets",
		BaseCost = 3000, Growth = 4, From = "Steer4", Cells = { { -4, -1 }, { -5, -1 }, { -6, -1 } } },
	{ Id = "Candy", Name = "Treat Collector", Icon = "🍬", Stat = "Candy & presents", Desc = "Get more Halloween candy and Winter presents from event obstacles.", Per = 25, Unit = "%",
		BaseCost = 2000, Growth = 3.5, From = "Steer4", Cells = { { -5, 1 }, { -6, 2 }, { -7, 3 }, { -8, 4 } } },
	{ Id = "TurboTime", Name = "Turbo Time", Icon = "⏱️", Stat = "Turbo length", Desc = "Your Turbo Boost lasts longer.", Per = 0.5, Unit = "s",
		BaseCost = 4000, Growth = 4, From = "Boost3", Cells = { { -3, 6 }, { -3, 7 }, { -3, 8 } } },
} :: { Branch }

local ROMAN = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII" }
Config.Roman = ROMAN

export type Node = {
	Id: string,
	Branch: Branch,
	Tier: number,
	Q: number,
	R: number,
	Cost: number,
	Requires: string,
	Title: string,
}

local function niceRound(n: number): number
	if n < 100 then
		return math.floor(n / 5 + 0.5) * 5
	end
	local mag = 10 ^ (math.floor(math.log10(n)) - 1)
	return math.floor(n / mag + 0.5) * mag
end

Config.Nodes = {} :: { [string]: Node }
Config.NodeList = {} :: { Node }
Config.BranchById = {} :: { [string]: Branch }

for _, branch in Config.Branches do
	Config.BranchById[branch.Id] = branch
	for tier, cell in branch.Cells do
		local node: Node = {
			Id = branch.Id .. tier,
			Branch = branch,
			Tier = tier,
			Q = cell[1],
			R = cell[2],
			Cost = niceRound(branch.BaseCost * branch.Growth ^ (tier - 1)),
			Requires = if tier == 1 then branch.From else branch.Id .. (tier - 1),
			Title = branch.Name .. " " .. ROMAN[tier],
		}
		Config.Nodes[node.Id] = node
		table.insert(Config.NodeList, node)
	end
end

function Config.BranchLevel(owned: { [string]: boolean }, branchId: string): number
	local level = 0
	local branch = Config.BranchById[branchId]
	for tier = 1, #branch.Cells do
		if owned[branchId .. tier] then
			level = tier
		else
			break
		end
	end
	return level
end

-- Text for the tooltip, e.g. "+25%" or "+0.8s"
function Config.StatText(branch: Branch, level: number): string
	local v = branch.Per * level
	local sign = if v >= 0 then "+" else ""
	local num = if math.floor(v) == v then tostring(v) else string.format("%.1f", v)
	return sign .. num .. branch.Unit
end

function Config.CanBuy(owned: { [string]: boolean }, nodeId: string): (boolean, string?)
	local node = Config.Nodes[nodeId]
	if not node then
		return false, "Unknown upgrade"
	end
	if owned[nodeId] then
		return false, "Already owned"
	end
	if node.Requires ~= "Start" and not owned[node.Requires] then
		return false, "Requires " .. Config.Nodes[node.Requires].Title
	end
	return true, nil
end

-- Pet / egg / candy perks from the upgrade tree
function Config.PetPowerMult(owned: { [string]: boolean }): number
	return 1 + 0.15 * Config.BranchLevel(owned, "PetPower")
end

function Config.HatchLuckMult(owned: { [string]: boolean }): number
	return 1 + 0.1 * Config.BranchLevel(owned, "HatchLuck")
end

function Config.EggPrice(owned: { [string]: boolean }, price: number): number
	return math.max(1, math.floor(price * (1 - 0.05 * Config.BranchLevel(owned, "EggDiscount")) + 0.5))
end

function Config.PetStorageBonus(owned: { [string]: boolean }): number
	return 15 * Config.BranchLevel(owned, "PetStorage")
end

function Config.CandyMult(owned: { [string]: boolean }): number
	return 1 + 0.25 * Config.BranchLevel(owned, "Candy")
end

----------------------------------------------------------------------
-- Snowball skins (Shop)
----------------------------------------------------------------------
export type Skin = {
	Id: string,
	Name: string,
	Price: number,
	Bonus: number, -- extra coin multiplier, 0.25 = +25%
	Color: Color3,
	Clump: Color3,
	Material: Enum.Material,
	Transparency: number,
	Trail: Color3,
	Pass: string?, -- game pass key needed instead of coins (see Monetization)
	Currency: string?, -- "Candy" / "Presents" = bought with event currency instead of coins
	Rainbow: boolean?,
}

Config.Skins = {
	{ Id = "Classic", Name = "Classic Snow", Price = 0, Bonus = 0, Color = Color3.fromRGB(246, 250, 255), Clump = Color3.fromRGB(222, 236, 250),
		Material = Enum.Material.Snow, Transparency = 0, Trail = Color3.fromRGB(255, 255, 255) },
	{ Id = "Ice", Name = "Ice Crystal", Price = 2500, Bonus = 0.1, Color = Color3.fromRGB(150, 220, 255), Clump = Color3.fromRGB(210, 245, 255),
		Material = Enum.Material.Ice, Transparency = 0.1, Trail = Color3.fromRGB(150, 230, 255) },
	{ Id = "Candy", Name = "Candy Swirl", Price = 12000, Bonus = 0.25, Color = Color3.fromRGB(255, 120, 190), Clump = Color3.fromRGB(255, 255, 255),
		Material = Enum.Material.SmoothPlastic, Transparency = 0, Trail = Color3.fromRGB(255, 150, 210) },
	{ Id = "Magma", Name = "Magma Core", Price = 45000, Bonus = 0.5, Color = Color3.fromRGB(255, 96, 32), Clump = Color3.fromRGB(60, 30, 25),
		Material = Enum.Material.CrackedLava, Transparency = 0, Trail = Color3.fromRGB(255, 140, 40) },
	{ Id = "Gold", Name = "Golden Ball", Price = 150000, Bonus = 1, Color = Color3.fromRGB(255, 200, 40), Clump = Color3.fromRGB(255, 235, 140),
		Material = Enum.Material.Foil, Transparency = 0, Trail = Color3.fromRGB(255, 220, 80) },
	{ Id = "Galaxy", Name = "Galaxy", Price = 500000, Bonus = 2, Color = Color3.fromRGB(130, 70, 255), Clump = Color3.fromRGB(60, 220, 255),
		Material = Enum.Material.Neon, Transparency = 0, Trail = Color3.fromRGB(180, 120, 255) },
	{ Id = "Rainbow", Name = "Rainbow Ball", Price = 0, Bonus = 0.5, Color = Color3.fromRGB(255, 80, 80), Clump = Color3.fromRGB(255, 255, 255),
		Material = Enum.Material.Neon, Transparency = 0, Trail = Color3.fromRGB(255, 255, 255), Pass = "RainbowBall", Rainbow = true },
	{ Id = "Pumpkin", Name = "Pumpkin Ball", Price = 750, Currency = "Candy", Bonus = 0.75, Color = Color3.fromRGB(255, 130, 20), Clump = Color3.fromRGB(60, 160, 60),
		Material = Enum.Material.SmoothPlastic, Transparency = 0, Trail = Color3.fromRGB(255, 160, 40) },
	{ Id = "CandyCane", Name = "Candy Cane Ball", Price = 900, Currency = "Presents", Bonus = 1, Color = Color3.fromRGB(235, 40, 50), Clump = Color3.fromRGB(255, 255, 255),
		Material = Enum.Material.SmoothPlastic, Transparency = 0, Trail = Color3.fromRGB(255, 90, 90) },
} :: { Skin }

Config.SkinById = {} :: { [string]: Skin }
for _, skin in Config.Skins do
	Config.SkinById[skin.Id] = skin
end

----------------------------------------------------------------------
-- HALLOWEEN EVENT
-- Enabled = true: pumpkins + ghost snowmen on the mountain drop Candy,
-- the Spooky Egg and the Pumpkin Ball skin show up, the lobby gets pumpkins.
-- NightLook = true: spooky orange/purple evening lighting.
-- Set Enabled = false after Halloween; candy and Halloween pets are kept.
----------------------------------------------------------------------
Config.Halloween = {
	Enabled = false, -- Halloween is over: candy, Spooky pets and the Pumpkin Ball are kept
	NightLook = true,
	SpawnChance = 0.22, -- share of obstacles that are pumpkins / ghost snowmen
}

----------------------------------------------------------------------
-- WINTER EVENT (Update 3)
-- Enabled = true: giant presents + gingerbread houses on the mountain drop
-- Presents, the Winter Egg and the Candy Cane Ball show up, the lobby gets a
-- giant Christmas tree and lights.
-- NightLook = true: cosy blue evening lighting.
-- Set Enabled = false after winter; presents and Winter pets are kept.
----------------------------------------------------------------------
Config.Winter = {
	Enabled = true,
	NightLook = true,
	SpawnChance = 0.2, -- share of obstacles that are giant presents / gingerbread houses
}

-- Event currencies (Coins are the main currency)
Config.Currencies = {
	Coins = { Icon = "🪙", Name = "coins", Color = Color3.fromRGB(255, 214, 50) },
	Candy = { Icon = "🍬", Name = "candy", Color = Color3.fromRGB(255, 150, 40) },
	Presents = { Icon = "🎁", Name = "presents", Color = Color3.fromRGB(255, 95, 110) },
}

----------------------------------------------------------------------
-- Daily login rewards (7-day streak, then it starts again).
-- Miss a day and the streak resets to day 1.
-- Each reward: Coins, Turbos, Candy, and/or Egg = egg id for a free hatch.
----------------------------------------------------------------------
Config.Daily = {
	{ Coins = 1000 },
	{ Turbos = 1 },
	{ Coins = 3000 },
	{ Turbos = 2, Candy = 50 },
	{ Coins = 8000 },
	{ Turbos = 3 },
	{ Coins = 15000, Egg = "Glacier" },
}

----------------------------------------------------------------------
-- Rebirth
----------------------------------------------------------------------
Config.Rebirth = {
	BaseCost = 500000,
	CostGrowth = 3,
	BonusPer = 0.5, -- +50% coins per rebirth
}

function Config.RebirthCost(rebirths: number): number
	return Config.Rebirth.BaseCost * Config.Rebirth.CostGrowth ^ rebirths
end

----------------------------------------------------------------------
-- Turbo (bought in the shop, used during a run with T / the TURBO button)
----------------------------------------------------------------------
Config.Turbo = {
	SpeedAdd = 90, -- instant speed boost
	Duration = 3, -- seconds of unstoppable smashing (no speed lost on hits)
}

----------------------------------------------------------------------
-- Server storms / events (started by admins or the Server Coin Storm product)
----------------------------------------------------------------------
export type EventDef = {
	Id: string,
	Name: string,
	Icon: string,
	Desc: string,
	Color: Color3,
	CoinMult: number?,
	GrowthMult: number?,
	LaunchMult: number?,
	CritBonus: number?,
	Mutations: { string }?, -- mutation ids (see Config.Mutations) obstacles can roll
	AirMult: number?,
	GravityMult: number?,
	HatchLuck: number?,
	Crazy: boolean?, -- a big "admin abuse" style event (see Config.CrazyEvents)
}

Config.Events = {
	{ Id = "Coins2", Name = "x2 Coins Storm", Icon = "💰", Desc = "All coins doubled!", Color = Color3.fromRGB(90, 220, 70), CoinMult = 2 },
	{ Id = "Coins3", Name = "x3 Coins Storm", Icon = "🤑", Desc = "All coins tripled!", Color = Color3.fromRGB(40, 190, 90), CoinMult = 3 },
	{ Id = "Mutation", Name = "Mutation Storm", Icon = "🔮", Desc = "Obstacles mutate into Golden (x3) and Diamond (x8)!", Color = Color3.fromRGB(190, 90, 255), Mutations = { "Diamond", "Golden" } },
	{ Id = "Growth", Name = "Mega Growth", Icon = "⛄", Desc = "Snowballs grow twice as fast!", Color = Color3.fromRGB(110, 200, 255), GrowthMult = 2 },
	{ Id = "Speed", Name = "Blizzard Speed", Icon = "🌪️", Desc = "Launch 50% faster!", Color = Color3.fromRGB(60, 150, 255), LaunchMult = 1.5 },
	{ Id = "Lucky", Name = "Lucky Storm", Icon = "🍀", Desc = "+25% critical chance!", Color = Color3.fromRGB(80, 210, 120), CritBonus = 0.25 },
	-- CRAZY EVENTS: start on their own every so often (and from the admin panel)
	{ Id = "Meteor", Name = "Meteor Shower", Icon = "☄️", Desc = "Meteors crash into the lobby - grab the glowing shards! Obstacles turn MOLTEN (x10)!",
		Color = Color3.fromRGB(255, 90, 40), Crazy = true, Mutations = { "Molten" }, CoinMult = 1.5 },
	{ Id = "Galaxy", Name = "Galaxy Event", Icon = "🌌", Desc = "Low gravity, x2 hatch luck, huge jumps and GALAXY obstacles (x15)!",
		Color = Color3.fromRGB(150, 90, 255), Crazy = true, Mutations = { "Galaxy" }, AirMult = 1.8, GravityMult = 0.55, HatchLuck = 2 },
} :: { EventDef }

Config.EventById = {} :: { [string]: EventDef }
for _, e in Config.Events do
	Config.EventById[e.Id] = e
end

-- Mutations an obstacle can roll while an event that lists them is on
Config.Mutations = {
	{ Id = "Diamond", Chance = 0.08, Mult = 8, Color = Color3.fromRGB(120, 235, 255), Material = Enum.Material.Glass },
	{ Id = "Golden", Chance = 0.25, Mult = 3, Color = Color3.fromRGB(255, 200, 40), Material = Enum.Material.Foil },
	{ Id = "Molten", Chance = 0.22, Mult = 10, Color = Color3.fromRGB(255, 90, 20), Material = Enum.Material.CrackedLava },
	{ Id = "Galaxy", Chance = 0.2, Mult = 15, Color = Color3.fromRGB(120, 60, 255), Material = Enum.Material.Neon },
}
Config.MutationById = {}
for _, m in Config.Mutations do
	Config.MutationById[m.Id] = m
end

-- Highest mutation multiplier among a list of mutation ids
function Config.MaxMutationMult(ids: { string }?): number
	local best = 1
	local list: { string } = ids or {}
	for _, id in list do
		local m = Config.MutationById[id]
		if m then
			best = math.max(best, m.Mult)
		end
	end
	return best
end

----------------------------------------------------------------------
-- CRAZY EVENTS (like admin abuse in Steal a Brainrot)
-- Every MinMinutes-MaxMinutes one random event from Pool starts by itself
-- for Minutes, after a big WarningSeconds countdown for the whole server.
----------------------------------------------------------------------
Config.CrazyEvents = {
	Auto = true,
	MinMinutes = 30,
	MaxMinutes = 50,
	Minutes = 5,
	WarningSeconds = 10,
	Pool = { "Meteor", "Galaxy" },
	-- Meteor Shower: a meteor crashes into the lobby every ShardEvery seconds and
	-- leaves a glowing shard; touching it pays max(ShardMinCoins, best run x ShardBestShare)
	ShardEvery = 2.5,
	ShardLifetime = 25,
	ShardMinCoins = 300,
	ShardBestShare = 0.25,
	-- Galaxy Event: lobby gravity multiplier (everyone jumps sky high)
	LobbyGravity = 0.35,
}

----------------------------------------------------------------------
-- Stats derived from upgrades / rebirths / skin / passes / events
----------------------------------------------------------------------
export type Stats = {
	Launch: number,
	Growth: number,
	MaxRadius: number,
	StartRadius: number,
	Smash: number,
	CoinMult: number,
	ComboTime: number,
	Steer: number,
	Friction: number,
	Crit: number,
	Boost: number,
	Air: number,
	Gravity: number,
	Mutations: { string },
	MutationKey: string,
	TurboTime: number,
}

-- extras: { CoinMult, GrowthMult, LaunchMult, CritBonus, StartRadiusBonus, Mutations, AirMult, GravityMult }
function Config.ComputeStats(owned: { [string]: boolean }, rebirths: number, skinId: string?, extras: { [string]: any }?): Stats
	local P = Config.Physics
	local e = extras or {}
	local function lv(id: string): number
		return Config.BranchLevel(owned, id)
	end
	local skin = Config.SkinById[skinId or "Classic"] or Config.SkinById.Classic
	return {
		Launch = P.BaseLaunch * (1 + 0.25 * lv("Push")) * (e.LaunchMult or 1),
		Growth = P.BaseGrowth * (1 + 0.35 * lv("Growth")) * (e.GrowthMult or 1),
		MaxRadius = P.BaseMaxRadius + 3 * lv("Mega") + (e.StartRadiusBonus or 0),
		StartRadius = P.StartRadius + (e.StartRadiusBonus or 0),
		Smash = P.BaseSmash * (1 + 0.4 * lv("Smash")),
		CoinMult = (1 + 0.5 * lv("Coin")) * (1 + Config.Rebirth.BonusPer * rebirths) * (1 + skin.Bonus) * (e.CoinMult or 1),
		ComboTime = P.BaseComboTime + 0.4 * lv("Combo"),
		Steer = P.BaseSteer * (1 + 0.3 * lv("Steer")),
		Friction = P.BaseFriction * (1 - 0.12 * lv("Slick")),
		Crit = P.BaseCrit + 0.05 * lv("Lucky") + (e.CritBonus or 0),
		Boost = P.BaseBoost * (1 + 0.3 * lv("Boost")),
		Air = (1 + 0.25 * lv("Air")) * (e.AirMult or 1),
		Gravity = P.Gravity * (e.GravityMult or 1),
		Mutations = e.Mutations or {},
		MutationKey = table.concat(e.Mutations or {}, ","),
		TurboTime = Config.Turbo.Duration + 0.5 * lv("TurboTime"),
	}
end

----------------------------------------------------------------------
-- Number formatting
----------------------------------------------------------------------
function Config.Commas(n: number): string
	local s = tostring(math.floor(n + 0.5))
	local neg = string.sub(s, 1, 1) == "-"
	if neg then
		s = string.sub(s, 2)
	end
	local out = string.reverse((string.gsub(string.reverse(s), "(%d%d%d)", "%1,")))
	if string.sub(out, 1, 1) == "," then
		out = string.sub(out, 2)
	end
	return (if neg then "-" else "") .. out
end

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }
function Config.Short(n: number): string
	if n < 1000 then
		return tostring(math.floor(n))
	end
	local i = 1
	while n >= 1000 and i < #SUFFIXES do
		n /= 1000
		i += 1
	end
	local str = if n >= 100 then string.format("%d", math.floor(n)) else string.format("%.1f", math.floor(n * 10) / 10)
	str = string.gsub(str, "%.0$", "")
	return str .. SUFFIXES[i]
end

return Config
