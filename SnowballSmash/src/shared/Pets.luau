--!nonstrict
-- Snowball Smash: pets ("Snow Buddies"), eggs, rarities and the Index.
-- Bonuses are percentages: Coins = 25 means +25% coins while equipped.

local Pets = {}

Pets.MaxInventory = 75
Pets.BaseEquipSlots = 3
Pets.ExtraSlotsPass = 2 -- with the "+2 Pet Slots" game pass
Pets.IndexBonus = 10 -- +10% coins for every egg you complete in the Index

Pets.Rarities = {
	Common = { Order = 1, Color = Color3.fromRGB(190, 200, 215) },
	Rare = { Order = 2, Color = Color3.fromRGB(70, 160, 255) },
	Epic = { Order = 3, Color = Color3.fromRGB(175, 90, 255) },
	Legendary = { Order = 4, Color = Color3.fromRGB(255, 190, 40) },
	Secret = { Order = 5, Color = Color3.fromRGB(255, 60, 90) },
}

-- Chance is in percent. Luck (Lucky Eggs pass) boosts everything Rare and above.
Pets.Eggs = {
	{
		Id = "Frosty",
		Name = "Frosty Egg",
		Currency = "Coins",
		Price = 2500,
		Color = Color3.fromRGB(170, 225, 255),
		Pets = {
			{ Id = "Penguin", Name = "Penguin", Icon = "🐧", Rarity = "Common", Chance = 45, Coins = 10 },
			{ Id = "SnowBunny", Name = "Snow Bunny", Icon = "🐰", Rarity = "Common", Chance = 30, Coins = 15 },
			{ Id = "ArcticFox", Name = "Arctic Fox", Icon = "🦊", Rarity = "Rare", Chance = 17, Coins = 30, Growth = 5 },
			{ Id = "SnowBear", Name = "Snow Bear", Icon = "🐻", Rarity = "Epic", Chance = 7, Coins = 60, Growth = 10 },
			{ Id = "SnowOwl", Name = "Snow Owl", Icon = "🦉", Rarity = "Legendary", Chance = 1, Coins = 150, Launch = 10 },
		},
	},
	{
		Id = "Glacier",
		Name = "Glacier Egg",
		Currency = "Coins",
		Price = 40000,
		Color = Color3.fromRGB(90, 170, 255),
		Pets = {
			{ Id = "IceWolf", Name = "Ice Wolf", Icon = "🐺", Rarity = "Common", Chance = 45, Coins = 35 },
			{ Id = "SnowCat", Name = "Snow Cat", Icon = "🐱", Rarity = "Common", Chance = 30, Coins = 45 },
			{ Id = "IceWhale", Name = "Ice Whale", Icon = "🐳", Rarity = "Rare", Chance = 17, Coins = 90, Growth = 10 },
			{ Id = "FrostDragon", Name = "Frost Dragon", Icon = "🐲", Rarity = "Epic", Chance = 7, Coins = 180, Launch = 10 },
			{ Id = "Unicorn", Name = "Glacier Unicorn", Icon = "🦄", Rarity = "Legendary", Chance = 0.9, Coins = 400, Growth = 20 },
			{ Id = "Yeti", Name = "Yeti", Icon = "🦍", Rarity = "Secret", Chance = 0.1, Coins = 1000, Growth = 30, Launch = 20 },
		},
	},
	{
		Id = "Aurora",
		Name = "Aurora Egg",
		Currency = "Coins",
		Price = 500000,
		Color = Color3.fromRGB(190, 120, 255),
		Pets = {
			{ Id = "AuroraBird", Name = "Aurora Bird", Icon = "🐦", Rarity = "Common", Chance = 45, Coins = 120 },
			{ Id = "FrostOcto", Name = "Frost Octo", Icon = "🐙", Rarity = "Common", Chance = 30, Coins = 150 },
			{ Id = "IceDragon", Name = "Ice Dragon", Icon = "🐉", Rarity = "Rare", Chance = 17, Coins = 300, Launch = 10 },
			{ Id = "StarSpirit", Name = "Star Spirit", Icon = "🌟", Rarity = "Epic", Chance = 7, Coins = 600, Growth = 20 },
			{ Id = "CrystalGolem", Name = "Crystal Golem", Icon = "💎", Rarity = "Legendary", Chance = 0.9, Coins = 1500, Growth = 30 },
			{ Id = "SnowKing", Name = "Snow King", Icon = "👑", Rarity = "Secret", Chance = 0.1, Coins = 4000, Growth = 50, Launch = 30 },
		},
	},
	{
		Id = "Blizzard",
		Name = "Blizzard Egg",
		Currency = "Coins",
		Price = 5000000,
		Color = Color3.fromRGB(110, 90, 235),
		Pets = {
			{ Id = "SnowSprite", Name = "Snow Sprite", Icon = "✨", Rarity = "Common", Chance = 45, Coins = 300 },
			{ Id = "IciclePup", Name = "Icicle Pup", Icon = "🐶", Rarity = "Common", Chance = 30, Coins = 400 },
			{ Id = "FrostMammoth", Name = "Frost Mammoth", Icon = "🦣", Rarity = "Rare", Chance = 17, Coins = 800, Growth = 15 },
			{ Id = "BlizzardEagle", Name = "Blizzard Eagle", Icon = "🦅", Rarity = "Epic", Chance = 7, Coins = 1600, Launch = 25 },
			{ Id = "SnowLeopard", Name = "Snow Leopard", Icon = "🐆", Rarity = "Legendary", Chance = 0.9, Coins = 4000, Growth = 40 },
			{ Id = "BlizzardWyrm", Name = "Blizzard Wyrm", Icon = "🌀", Rarity = "Secret", Chance = 0.1, Coins = 10000, Growth = 60, Launch = 40 },
		},
	},
	{
		Id = "Spooky",
		Name = "Spooky Egg",
		Currency = "Candy",
		Price = 250,
		Color = Color3.fromRGB(255, 130, 30),
		Halloween = true, -- only shown while Config.Halloween.Enabled is true
		Pets = {
			{ Id = "Bat", Name = "Bat", Icon = "🦇", Rarity = "Common", Chance = 45, Coins = 40 },
			{ Id = "Ghost", Name = "Ghost", Icon = "👻", Rarity = "Common", Chance = 30, Coins = 55 },
			{ Id = "PumpkinCat", Name = "Pumpkin Cat", Icon = "🎃", Rarity = "Rare", Chance = 17, Coins = 120, Growth = 10 },
			{ Id = "Spider", Name = "Frost Spider", Icon = "🕷️", Rarity = "Epic", Chance = 7, Coins = 250, Launch = 15 },
			{ Id = "Skeleton", Name = "Ice Skeleton", Icon = "💀", Rarity = "Legendary", Chance = 0.9, Coins = 600, Growth = 25 },
			{ Id = "Vampire", Name = "Vampire", Icon = "🧛", Rarity = "Secret", Chance = 0.1, Coins = 1500, Growth = 40, Launch = 25 },
		},
	},
	{
		Id = "Winter",
		Name = "Winter Egg",
		Currency = "Presents",
		Price = 300,
		Color = Color3.fromRGB(235, 60, 70),
		Winter = true, -- only shown while Config.Winter.Enabled is true
		Pets = {
			{ Id = "Reindeer", Name = "Reindeer", Icon = "🦌", Rarity = "Common", Chance = 45, Coins = 60 },
			{ Id = "PolarBear", Name = "Polar Bear", Icon = "🐻‍❄️", Rarity = "Common", Chance = 30, Coins = 80 },
			{ Id = "Gingerbread", Name = "Gingerbread", Icon = "🍪", Rarity = "Rare", Chance = 17, Coins = 160, Growth = 10 },
			{ Id = "Elf", Name = "Snow Elf", Icon = "🧝", Rarity = "Epic", Chance = 7, Coins = 350, Launch = 15 },
			{ Id = "Santa", Name = "Santa Paws", Icon = "🎅", Rarity = "Legendary", Chance = 0.9, Coins = 900, Growth = 30 },
			{ Id = "FrostTitan", Name = "Frost Titan", Icon = "🧊", Rarity = "Secret", Chance = 0.1, Coins = 2500, Growth = 50, Launch = 35 },
		},
	},
}

Pets.EggById = {}
Pets.ById = {}
Pets.All = {}
for _, egg in Pets.Eggs do
	Pets.EggById[egg.Id] = egg
	for _, pet in egg.Pets do
		pet.Egg = egg.Id
		pet.Coins = pet.Coins or 0
		pet.Growth = pet.Growth or 0
		pet.Launch = pet.Launch or 0
		Pets.ById[pet.Id] = pet
		table.insert(Pets.All, pet)
	end
end

-- Strength used by "Equip Best"
function Pets.Score(petId: string): number
	local p = Pets.ById[petId]
	if not p then
		return 0
	end
	return p.Coins + p.Growth * 2 + p.Launch * 2
end

function Pets.BonusText(petId: string): string
	local p = Pets.ById[petId]
	if not p then
		return ""
	end
	local parts = { "+" .. p.Coins .. "% coins" }
	if p.Growth > 0 then
		table.insert(parts, "+" .. p.Growth .. "% growth")
	end
	if p.Launch > 0 then
		table.insert(parts, "+" .. p.Launch .. "% speed")
	end
	return table.concat(parts, "  ")
end

-- Chances (percent) for an egg, with an optional luck multiplier on Rare+.
function Pets.Odds(eggId: string, luck: number?): { [string]: number }
	local egg = Pets.EggById[eggId]
	local l = luck or 1
	local weights = {}
	local total = 0
	for _, p in egg.Pets do
		local w = p.Chance
		if Pets.Rarities[p.Rarity].Order >= 2 then
			w *= l
		end
		weights[p.Id] = w
		total += w
	end
	for id, w in weights do
		weights[id] = w / total * 100
	end
	return weights
end

-- Roll a pet. `rng` is a Random object (server only).
function Pets.Roll(eggId: string, luck: number?, rng): string
	local odds = Pets.Odds(eggId, luck)
	local roll = rng:NextNumber() * 100
	local acc = 0
	local egg = Pets.EggById[eggId]
	for _, p in egg.Pets do
		acc += odds[p.Id]
		if roll <= acc then
			return p.Id
		end
	end
	return egg.Pets[1].Id
end

-- A random Legendary (5% chance: Secret) from the coin eggs (Legendary Pet product)
function Pets.RollLegendary(rng): string
	local pool = {}
	local wantSecret = rng:NextNumber() < 0.05
	for _, p in Pets.All do
		local egg = Pets.EggById[p.Egg]
		if not egg.Halloween and not egg.Winter and p.Rarity == (if wantSecret then "Secret" else "Legendary") then
			table.insert(pool, p.Id)
		end
	end
	return pool[rng:NextInteger(1, #pool)]
end

-- Eggs completed in the Index (every pet except Secrets discovered)
function Pets.CompletedEggs(index: { [string]: boolean }): { string }
	local done = {}
	for _, egg in Pets.Eggs do
		local complete = true
		for _, p in egg.Pets do
			if p.Rarity ~= "Secret" and not index[p.Id] then
				complete = false
				break
			end
		end
		if complete then
			table.insert(done, egg.Id)
		end
	end
	return done
end

return Pets
