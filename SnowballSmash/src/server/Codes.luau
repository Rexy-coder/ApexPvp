--!nonstrict
-- Snowball Smash: redeem codes (players type them in the Daily panel).
-- Each code can be redeemed once per player.
-- Rewards: Coins, Turbos, Candy, Presents, Egg (egg id for a free hatch).
-- Optional Expires = os.time({year=2026, month=11, day=1}) to make a code stop working.
-- Codes are not case sensitive.

return {
	RELEASE = { Coins = 2500, Turbos = 1 },
	SNOWBALL = { Turbos = 3 },
	SPOOKY = { Candy = 150, Expires = os.time({ year = 2026, month = 11, day = 8 }) },
	WINTER = { Presents = 150, Turbos = 2, Expires = os.time({ year = 2027, month = 1, day = 15 }) },
	METEOR = { Coins = 5000 },
	-- MYCODE = { Coins = 10000 },
}
