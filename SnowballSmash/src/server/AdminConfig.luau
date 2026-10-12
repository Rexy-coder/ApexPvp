--!nonstrict
-- Snowball Smash: who can open the Admin Panel.
--
-- Put Roblox user ids in Admins (find yours in your profile URL:
-- roblox.com/users/<USER ID>/profile).

local AdminConfig = {}

AdminConfig.Admins = {
	0, -- << your user id here
	-- 12345678,
}

-- The owner of the game (user-owned games) is always an admin.
AdminConfig.CreatorIsAdmin = true

-- Everyone is admin while testing in Roblox Studio.
AdminConfig.StudioEveryoneIsAdmin = true

-- Longest announcement allowed
AdminConfig.MaxAnnouncementLength = 140

-- Choices shown in the panel for how long a storm lasts (minutes)
AdminConfig.Durations = { 1, 5, 15, 30 }

return AdminConfig
