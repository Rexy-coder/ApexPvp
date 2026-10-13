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
	Currency: string?, -- "Candy" = bought with Halloween candy instead of coins
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
	Enabled = true,
	NightLook = true,
	SpawnChance = 0.22, -- share of obstacles that are pumpkins / ghost snowmen
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
	Mutation: boolean?,
}

Config.Events = {
	{ Id = "Coins2", Name = "x2 Coins Storm", Icon = "💰", Desc = "All coins doubled!", Color = Color3.fromRGB(90, 220, 70), CoinMult = 2 },
	{ Id = "Coins3", Name = "x3 Coins Storm", Icon = "🤑", Desc = "All coins tripled!", Color = Color3.fromRGB(40, 190, 90), CoinMult = 3 },
	{ Id = "Mutation", Name = "Mutation Storm", Icon = "🔮", Desc = "Obstacles mutate into Golden (x3) and Diamond (x8)!", Color = Color3.fromRGB(190, 90, 255), Mutation = true },
	{ Id = "Growth", Name = "Mega Growth", Icon = "⛄", Desc = "Snowballs grow twice as fast!", Color = Color3.fromRGB(110, 200, 255), GrowthMult = 2 },
	{ Id = "Speed", Name = "Blizzard Speed", Icon = "🌪️", Desc = "Launch 50% faster!", Color = Color3.fromRGB(60, 150, 255), LaunchMult = 1.5 },
	{ Id = "Lucky", Name = "Lucky Storm", Icon = "🍀", Desc = "+25% critical chance!", Color = Color3.fromRGB(80, 210, 120), CritBonus = 0.25 },
} :: { EventDef }

Config.EventById = {} :: { [string]: EventDef }
for _, e in Config.Events do
	Config.EventById[e.Id] = e
end

-- Mutations rolled per obstacle while a Mutation Storm is on
Config.Mutations = {
	{ Id = "Diamond", Chance = 0.08, Mult = 8, Color = Color3.fromRGB(120, 235, 255), Material = Enum.Material.Glass },
	{ Id = "Golden", Chance = 0.25, Mult = 3, Color = Color3.fromRGB(255, 200, 40), Material = Enum.Material.Foil },
}
Config.MaxMutationMult = 8

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
	Mutation: boolean,
}

-- extras: { CoinMult, GrowthMult, LaunchMult, CritBonus, StartRadiusBonus, Mutation }
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
		Air = 1 + 0.25 * lv("Air"),
		Mutation = e.Mutation == true,
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
