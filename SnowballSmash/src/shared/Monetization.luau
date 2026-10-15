--!nonstrict
-- Snowball Smash: Robux shop items.
--
-- ┌──────────────────────────────────────────────────────────────────┐
-- │  PUT YOUR IDS HERE                                               │
-- │  1. Create the Game Passes / Developer Products on the Creator   │
-- │     Dashboard (Monetization → Passes / Developer Products).      │
-- │  2. Copy each ID into the matching `Id = 0` below.               │
-- │  3. Set the real Robux price on the website. `Price` here is     │
-- │     only shown until the real price loads from Roblox.          │
-- │  An item with Id = 0 shows "Coming soon" when clicked.           │
-- └──────────────────────────────────────────────────────────────────┘

local Monetization = {}

-- In Studio, pretend the tester owns every game pass (handy for testing perks).
Monetization.StudioOwnsAllPasses = false

----------------------------------------------------------------------
-- GAME PASSES (bought once, kept forever)
----------------------------------------------------------------------
Monetization.Passes = {
	{
		Key = "VIP",
		Id = 2027211169,
		Price = 349,
		Name = "VIP",
		Icon = "👑",
		Desc = "[VIP] chat tag, VIP name tag and +25% coins forever!",
		Color = Color3.fromRGB(255, 200, 40),
	},
	{
		Key = "DoubleCoins",
		Id = 2025405231,
		Price = 399,
		Name = "2x Coins",
		Icon = "💰",
		Desc = "Double the coins from every run, forever.",
		Color = Color3.fromRGB(90, 220, 70),
	},
	{
		Key = "PerfectPush",
		Id = 2025975197,
		Price = 199,
		Name = "Perfect Push",
		Icon = "🎯",
		Desc = "The power bar fills to MAX instantly, every time.",
		Color = Color3.fromRGB(60, 150, 255),
	},
	{
		Key = "MegaStart",
		Id = 2025675230,
		Price = 249,
		Name = "Mega Start",
		Icon = "⛄",
		Desc = "Start every run with a bigger snowball (+2 size).",
		Color = Color3.fromRGB(150, 220, 255),
	},
	{
		Key = "LuckyCharm",
		Id = 2026497223,
		Price = 179,
		Name = "Lucky Charm",
		Icon = "🍀",
		Desc = "+10% chance for CRITICAL smashes (double coins).",
		Color = Color3.fromRGB(80, 210, 120),
	},
	{
		Key = "RainbowBall",
		Id = 2025657163,
		Price = 149,
		Name = "Rainbow Ball",
		Icon = "🌈",
		Desc = "Exclusive colour-shifting snowball skin, +50% coins.",
		Color = Color3.fromRGB(255, 92, 196),
	},
	-- Update 2: pets
	{
		Key = "TripleHatch",
		Id = 2037824676,
		Price = 249,
		Name = "Triple Hatch",
		Icon = "🥚",
		Desc = "Hatch 3 eggs at once!",
		Color = Color3.fromRGB(120, 200, 255),
	},
	{
		Key = "AutoHatch",
		Id = 2036564657,
		Price = 299,
		Name = "Auto Hatch",
		Icon = "🔁",
		Desc = "Keep hatching eggs automatically.",
		Color = Color3.fromRGB(90, 220, 160),
	},
	{
		Key = "LuckyEggs",
		Id = 2037728649,
		Price = 399,
		Name = "Lucky Eggs",
		Icon = "🍀",
		Desc = "x1.5 chance for Rare, Epic, Legendary and Secret pets.",
		Color = Color3.fromRGB(80, 210, 120),
	},
	{
		Key = "ExtraPets",
		Id = 2036678663,
		Price = 199,
		Name = "+2 Pet Slots",
		Icon = "🐾",
		Desc = "Equip 2 more pets at the same time.",
		Color = Color3.fromRGB(255, 160, 80),
	},
}

----------------------------------------------------------------------
-- DEVELOPER PRODUCTS (can be bought again and again)
-- Kind = "Coins"       -> gives Amount coins
-- Kind = "Boost"       -> personal x2 coins for Minutes (stacks time)
-- Kind = "ServerBoost" -> x2 coins storm for the WHOLE server for Minutes
-- Kind = "Turbo"       -> gives Amount turbo boosts
-- Kind = "Candy"       -> gives Amount Halloween candy
-- Kind = "LegendaryPet"-> a random Legendary pet (5% Secret)
----------------------------------------------------------------------
Monetization.Products = {
	{
		Key = "CoinsSmall",
		Id = 3718165495,
		Price = 25,
		Name = "Pile of Coins",
		Icon = "✨",
		Desc = "+2,500 coins",
		Kind = "Coins",
		Amount = 2500,
		Color = Color3.fromRGB(255, 200, 40),
	},
	{
		Key = "CoinsMedium",
		Id = 3718165497,
		Price = 99,
		Name = "Bag of Coins",
		Icon = "💰",
		Desc = "+15,000 coins",
		Kind = "Coins",
		Amount = 15000,
		Color = Color3.fromRGB(255, 180, 30),
	},
	{
		Key = "CoinsLarge",
		Id = 3718165503,
		Price = 299,
		Name = "Chest of Coins",
		Icon = "📦",
		Desc = "+60,000 coins",
		Kind = "Coins",
		Amount = 60000,
		Color = Color3.fromRGB(240, 150, 30),
	},
	{
		Key = "CoinsHuge",
		Id = 3718165507,
		Price = 799,
		Name = "Vault of Coins",
		Icon = "🏦",
		Desc = "+250,000 coins",
		Kind = "Coins",
		Amount = 250000,
		Color = Color3.fromRGB(220, 120, 30),
	},
	{
		Key = "Turbo5",
		Id = 3718165483,
		Price = 99,
		Name = "Turbo Boost x5",
		Icon = "🚀",
		Desc = "5 Turbos! Press T (or TURBO) mid-run: huge speed + unstoppable smashing.",
		Kind = "Turbo",
		Amount = 5,
		Color = Color3.fromRGB(255, 90, 60),
	},
	{
		Key = "Turbo20",
		Id = 3718165489,
		Price = 299,
		Name = "Turbo Boost x20",
		Icon = "🔥",
		Desc = "20 Turbos for the price of 15!",
		Kind = "Turbo",
		Amount = 20,
		Color = Color3.fromRGB(240, 60, 60),
	},
	{
		Key = "Boost15",
		Id = 3718165511,
		Price = 49,
		Name = "x2 Coins (15 min)",
		Icon = "⏱️",
		Desc = "Your coins are doubled for 15 minutes.",
		Kind = "Boost",
		Minutes = 15,
		Color = Color3.fromRGB(150, 96, 245),
	},
	{
		Key = "Boost60",
		Id = 3718165517,
		Price = 149,
		Name = "x2 Coins (1 hour)",
		Icon = "⌛",
		Desc = "Your coins are doubled for a whole hour.",
		Kind = "Boost",
		Minutes = 60,
		Color = Color3.fromRGB(120, 70, 220),
	},
	{
		Key = "ServerStorm",
		Id = 3718165522,
		Price = 199,
		Name = "Server Coin Storm",
		Icon = "🌪️",
		Desc = "x2 coins for EVERYONE in the server for 10 minutes!",
		Kind = "ServerBoost",
		Minutes = 10,
		Color = Color3.fromRGB(40, 200, 255),
	},
	-- Update 2: pets & Halloween
	{
		Key = "LegendaryPet",
		Id = 3718766844,
		Price = 299,
		Name = "Legendary Pet",
		Icon = "🌟",
		Desc = "Get a random Legendary pet (5% chance: SECRET)!",
		Kind = "LegendaryPet",
		Color = Color3.fromRGB(255, 190, 40),
	},
	{
		Key = "CandySmall",
		Id = 3718766847,
		Price = 49,
		Name = "Bag of Candy",
		Icon = "🍬",
		Desc = "+250 Halloween candy",
		Kind = "Candy",
		Amount = 250,
		Color = Color3.fromRGB(255, 140, 40),
	},
	{
		Key = "CandyLarge",
		Id = 3718766851,
		Price = 149,
		Name = "Cauldron of Candy",
		Icon = "🎃",
		Desc = "+1,000 Halloween candy",
		Kind = "Candy",
		Amount = 1000,
		Color = Color3.fromRGB(240, 110, 30),
	},
}

----------------------------------------------------------------------
-- Perks (numbers used by the game)
----------------------------------------------------------------------
Monetization.Perks = {
	VIPCoinBonus = 0.25, -- +25%
	DoubleCoinsMult = 2,
	BoostMult = 2,
	MegaStartRadius = 2,
	LuckyCharmCrit = 0.10,
	LuckyEggsLuck = 1.5,
}

-- lookup tables
Monetization.PassByKey = {}
Monetization.ProductByKey = {}
Monetization.ProductById = {}
Monetization.PassById = {}
for _, pass in Monetization.Passes do
	Monetization.PassByKey[pass.Key] = pass
	if pass.Id ~= 0 then
		Monetization.PassById[pass.Id] = pass
	end
end
for _, product in Monetization.Products do
	Monetization.ProductByKey[product.Key] = product
	if product.Id ~= 0 then
		Monetization.ProductById[product.Id] = product
	end
end

return Monetization
