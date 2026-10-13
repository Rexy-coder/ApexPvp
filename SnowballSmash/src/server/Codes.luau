--!nonstrict
-- Snowball Smash: redeem codes (players type them in the Daily panel).
-- Each code can be redeemed once per player.
-- Rewards: Coins, Turbos, Candy, Egg (egg id for a free hatch).
-- Optional Expires = os.time({year=2026, month=11, day=1}) to make a code stop working.
-- Codes are not case sensitive.

return {
	RELEASE = { Coins = 2500, Turbos = 1 },
	SNOWBALL = { Turbos = 3 },
	SPOOKY = { Candy = 150, Expires = os.time({ year = 2026, month = 11, day = 8 }) },
	-- MYCODE = { Coins = 10000 },
}
