--!nonstrict
-- Snowball Smash: every sound in the game lives here.
--
-- Paste sound ids as "rbxassetid://123456789" (find sounds in the Creator Store /
-- Toolbox → Audio). Leave a sound as "" to switch it off.
-- The defaults are Roblox's built-in sounds, so they always work.

local Sounds = {}

----------------------------------------------------------------------
-- Volumes (0 - 1)
----------------------------------------------------------------------
Sounds.MusicVolume = 0.35
Sounds.SfxVolume = 0.6
Sounds.UIVolume = 0.5

----------------------------------------------------------------------
-- BACKGROUND MUSIC: a playlist, played in order and looped.
-- Example: Sounds.Music = { "rbxassetid://1234", "rbxassetid://5678" }
----------------------------------------------------------------------
Sounds.Music = {
	"", -- << put your music id here
}

-- Plays instead of the playlist while a server storm/event is active ("" = keep playlist)
Sounds.EventMusic = ""

----------------------------------------------------------------------
-- GUI SOUNDS
----------------------------------------------------------------------
Sounds.UI = {
	Click = "rbxasset://sounds/electronicpingshort.wav", -- any button press
	Hover = "", -- mouse over a button (leave "" for none)
	Open = "rbxasset://sounds/electronicpingshort.wav", -- a menu opens
	Close = "", -- a menu closes
	Purchase = "rbxasset://sounds/electronicpingshort.wav", -- bought something
	Error = "rbxasset://sounds/action_get_up.mp3", -- "not enough coins" etc.
	Notify = "rbxasset://sounds/electronicpingshort.wav", -- announcements / storms
	Toggle = "rbxasset://sounds/electronicpingshort.wav", -- settings ON/OFF
}

----------------------------------------------------------------------
-- GAMEPLAY SOUNDS
----------------------------------------------------------------------
Sounds.Game = {
	Launch = "rbxasset://sounds/action_jump.mp3",
	Smash = "rbxasset://sounds/impact_water.mp3",
	Land = "rbxasset://sounds/action_jump_land.mp3",
	Boost = "rbxasset://sounds/swordlunge.wav",
	Coin = "rbxasset://sounds/electronicpingshort.wav",
	Critical = "rbxasset://sounds/electronicpingshort.wav",
	MaxPower = "rbxasset://sounds/electronicpingshort.wav",
	NewBest = "rbxasset://sounds/electronicpingshort.wav",
	Mutation = "rbxasset://sounds/electronicpingshort.wav",
}

return Sounds
