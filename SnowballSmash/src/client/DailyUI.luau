--!nonstrict
-- Snowball Smash: daily login rewards (7-day streak) and redeem codes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Pets = require(Shared:WaitForChild("Pets"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Panels = require(script.Parent:WaitForChild("Panels"))

local C = UIKit.Colors
local new = UIKit.new

local DailyUI = {}
DailyUI.Callbacks = {
	Claim = function() end,
	Redeem = function(_code: string) end,
}

local data = nil

local function today(): number
	return math.floor(os.time() / 86400)
end

-- day (1-7) you would get if you claimed now, and whether you can
function DailyUI.status(d): (number, boolean)
	if not d then
		return 1, false
	end
	local day = today()
	if d.LastDaily == day then
		return d.DailyStreak, false
	end
	local streak = if d.LastDaily == day - 1 then d.DailyStreak % #Config.Daily + 1 else 1
	return streak, true
end

local function rewardText(r): (string, string)
	if r.Egg then
		local egg = Pets.EggById[r.Egg]
		return "🥚", (if egg then egg.Name else "Egg") .. (if r.Coins then "\n+" .. Config.Short(r.Coins) else "")
	elseif r.Turbos then
		return "🚀", r.Turbos .. " Turbo" .. (if r.Turbos > 1 then "s" else "") .. (if r.Candy then "\n+" .. r.Candy .. " 🍬" else "")
	elseif r.Candy then
		return "🍬", "+" .. r.Candy .. " candy"
	end
	return "🪙", "+" .. Config.Short(r.Coins or 0)
end

local panel = UIKit.panel(Hud.Root, "Daily Rewards", "🎁", 860, 560)
Panels.register("Daily", panel)

local daysRow = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 170), Parent = panel.Content })
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 10), Parent = daysRow })

local dayTiles = {}
for i, reward in Config.Daily do
	local tile = new("Frame", { BackgroundColor3 = C.WoodLight, Size = UDim2.fromOffset(104, 160), LayoutOrder = i, Parent = daysRow })
	UIKit.corner(tile, 12)
	local stroke = UIKit.stroke(tile, 3)
	UIKit.label({ Text = "DAY " .. i, Size = UDim2.new(1, -10, 0, 24), Position = UDim2.fromOffset(5, 8), Stroke = 2.5, Parent = tile })
	local icon, text = rewardText(reward)
	UIKit.label({ Text = icon, Size = UDim2.fromOffset(54, 54), Position = UDim2.new(0.5, 0, 0, 38), AnchorPoint = Vector2.new(0.5, 0), Stroke = 0, Parent = tile })
	UIKit.label({ Text = text, TextScaled = false, TextSize = 16, TextWrapped = true, Size = UDim2.new(1, -8, 0, 50), Position = UDim2.fromOffset(4, 100), Stroke = 2, Parent = tile })
	local check = UIKit.label({ Text = "✔", TextColor3 = Color3.fromRGB(120, 255, 100), Size = UDim2.fromOffset(40, 40), Position = UDim2.new(1, -6, 0, -10), AnchorPoint = Vector2.new(1, 0), Stroke = 3, Visible = false, Parent = tile })
	dayTiles[i] = { Tile = tile, Stroke = stroke, Check = check }
end

local claim = UIKit.button({
	Size = UDim2.fromOffset(300, 66),
	Position = UDim2.new(0.5, -150, 0, 186),
	Color = C.Green,
	DarkColor = C.GreenDark,
	Text = "Claim!",
	Studs = true,
	Parent = panel.Content,
	OnClick = function()
		DailyUI.Callbacks.Claim()
	end,
})
claim.Label.TextXAlignment = Enum.TextXAlignment.Center
local timer = UIKit.label({ Text = "", Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, 258), Stroke = 2, TextColor3 = Color3.fromRGB(255, 225, 120), Parent = panel.Content })

-- codes
local codes = new("Frame", { BackgroundColor3 = C.WoodLight, Size = UDim2.new(1, 0, 0, 112), Position = UDim2.new(0, 0, 1, -112), Parent = panel.Content })
UIKit.corner(codes, 12)
UIKit.stroke(codes, 3)
UIKit.label({ Text = "🎟️ Got a code? (follow the game for new ones!)", TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -24, 0, 26), Position = UDim2.fromOffset(14, 8), Stroke = 2.5, Parent = codes })
local codeBox = UIKit.textbox(codes, "Enter code...", UDim2.new(1, -200, 0, 50), UDim2.fromOffset(14, 46))
local redeem = UIKit.button({ Size = UDim2.fromOffset(160, 54), Position = UDim2.new(1, -174, 0, 44), Color = C.Purple, DarkColor = C.PurpleDark, Text = "Redeem", Parent = codes, OnClick = function()
	DailyUI.Callbacks.Redeem(codeBox.Text)
	codeBox.Text = ""
end })
redeem.Label.TextXAlignment = Enum.TextXAlignment.Center

local function refresh()
	local day, can = DailyUI.status(data)
	for i, t in dayTiles do
		local claimed = data ~= nil and ((can and i < day) or (not can and i <= day))
		t.Check.Visible = claimed
		t.Tile.BackgroundColor3 = if claimed then C.WoodDark elseif i == day and can then Color3.fromRGB(70, 150, 60) else C.WoodLight
		t.Stroke.Color = if i == day and can then C.Yellow else C.Outline
		t.Stroke.Thickness = if i == day and can then 5 else 3
	end
	claim.SetText(if can then "Claim Day " .. day .. "!" else "Claimed ✔")
	claim.SetColors(if can then C.Green else C.Grey, if can then C.GreenDark else C.GreyDark)
end

RunService.Heartbeat:Connect(function()
	if panel.IsOpen then
		local _, can = DailyUI.status(data)
		if can then
			timer.Text = "Come back every day - miss a day and the streak starts over!"
		else
			local left = (today() + 1) * 86400 - os.time()
			timer.Text = string.format("Next reward in %d:%02d:%02d", left // 3600, (left % 3600) // 60, left % 60)
		end
	end
end)

function DailyUI.refresh(newData)
	data = newData
	refresh()
	local _, can = DailyUI.status(data)
	Hud.setAlert("Daily", can)
end

return DailyUI
