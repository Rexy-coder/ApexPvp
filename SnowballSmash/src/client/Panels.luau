--!nonstrict
-- Snowball Smash: menu panels (Settings, Stats, Shop, Rebirth) and the
-- "Run Complete!" results card.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Effects = require(script.Parent:WaitForChild("Effects"))

local C = UIKit.Colors
local new = UIKit.new

local Panels = {}
Panels.Callbacks = {
	SetSetting = function(_key: string, _value: boolean) end,
	BuySkin = function(_id: string) end,
	Rebirth = function() end,
	Closed = function() end,
}

local panels: { [string]: UIKit.Panel } = {}
local data: any = nil

local function register(name: string, panel: UIKit.Panel)
	panels[name] = panel
	panel.OnClose = function()
		UIKit.closePanel(panel)
		Panels.Callbacks.Closed()
	end
end

function Panels.anyOpen(): boolean
	for _, p in panels do
		if p.IsOpen then
			return true
		end
	end
	return false
end

function Panels.closeAll()
	for _, p in panels do
		UIKit.closePanel(p)
	end
end

function Panels.open(name: string)
	for other, p in panels do
		if other ~= name then
			UIKit.closePanel(p)
		end
	end
	local p = panels[name]
	if p then
		UIKit.openPanel(p)
	end
end

-- A brown row with a label on the left
local function row(parent: Instance, order: number, text: string): Frame
	local r = new("Frame", {
		BackgroundColor3 = C.WoodLight,
		Size = UDim2.new(1, 0, 0, 58),
		LayoutOrder = order,
		Parent = parent,
	})
	UIKit.corner(r, 10)
	UIKit.stroke(r, 3)
	UIKit.label({
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(0.6, 0, 0, 28),
		Position = UDim2.new(0, 16, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Stroke = 2.5,
		Parent = r,
	})
	return r
end

local function list(parent: Instance, padding: number?)
	new("UIListLayout", {
		Padding = UDim.new(0, padding or 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = parent,
	})
end

----------------------------------------------------------------------
-- Settings
----------------------------------------------------------------------
local settingsPanel = UIKit.panel(Hud.Root, "Settings", "⚙️", 560, 470)
register("Settings", settingsPanel)
list(settingsPanel.Content)

local toggles: { [string]: UIKit.Button } = {}
local SETTINGS = {
	{ Key = "Music", Text = "Music" },
	{ Key = "SFX", Text = "SFX" },
	{ Key = "Shake", Text = "Camera Shake" },
	{ Key = "SpeedLines", Text = "Speed Lines" },
	{ Key = "Hints", Text = "Hints" },
}
for i, s in SETTINGS do
	local r = row(settingsPanel.Content, i, s.Text)
	local b = UIKit.button({
		Size = UDim2.fromOffset(120, 46),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 2),
		Text = "ON",
		Studs = true,
		Parent = r,
	})
	b.Label.TextXAlignment = Enum.TextXAlignment.Center
	b.Clicked = function()
		local value = not Effects.Settings[s.Key]
		Panels.Callbacks.SetSetting(s.Key, value)
	end
	toggles[s.Key] = b
end

local function refreshSettings()
	for key, b in toggles do
		local on = Effects.Settings[key]
		b.SetText(if on then "ON" else "OFF")
		if on then
			b.SetColors(C.Green, C.GreenDark)
		else
			b.SetColors(C.Red, C.RedDark)
		end
	end
end
Panels.refreshSettings = refreshSettings

----------------------------------------------------------------------
-- Stats
----------------------------------------------------------------------
local statsPanel = UIKit.panel(Hud.Root, "Stats", "📊", 560, 520)
register("Stats", statsPanel)
list(statsPanel.Content, 8)

local statValues: { [string]: TextLabel } = {}
local STATS = {
	{ Key = "Runs", Text = "Runs" },
	{ Key = "BestEarn", Text = "Best Score" },
	{ Key = "BestDistance", Text = "Best Distance" },
	{ Key = "BestCombo", Text = "Best Combo" },
	{ Key = "TotalSmashed", Text = "Smashed" },
	{ Key = "Rebirths", Text = "Rebirths" },
}
for i, s in STATS do
	local r = row(statsPanel.Content, i, s.Text)
	r.Size = UDim2.new(1, 0, 0, 52)
	local valueBox = new("Frame", {
		BackgroundColor3 = C.WoodDark,
		Size = UDim2.fromOffset(170, 36),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Parent = r,
	})
	UIKit.corner(valueBox, 8)
	UIKit.stroke(valueBox, 2)
	statValues[s.Key] = UIKit.label({
		Text = "0",
		TextXAlignment = Enum.TextXAlignment.Right,
		Size = UDim2.new(1, -20, 0, 24),
		Position = UDim2.new(0, 10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Stroke = 2,
		Parent = valueBox,
	})
end

local function refreshStats()
	if not data then
		return
	end
	statValues.Runs.Text = Config.Commas(data.Runs)
	statValues.BestEarn.Text = Config.Commas(data.BestEarn)
	statValues.BestDistance.Text = Config.Commas(data.BestDistance) .. " STUDS"
	statValues.BestCombo.Text = "x" .. data.BestCombo
	statValues.TotalSmashed.Text = Config.Commas(data.TotalSmashed)
	statValues.Rebirths.Text = tostring(data.Rebirths)
end

----------------------------------------------------------------------
-- Shop (snowball skins)
----------------------------------------------------------------------
local shopPanel = UIKit.panel(Hud.Root, "Shop", "🛒", 700, 540)
register("Shop", shopPanel)
new("UIGridLayout", {
	CellSize = UDim2.fromOffset(200, 196),
	CellPadding = UDim2.fromOffset(18, 16),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = shopPanel.Content,
})

type SkinCard = { Button: UIKit.Button, Price: TextLabel, Ball: Frame, Coin: Frame }
local skinCards: { [string]: SkinCard } = {}

for i, skin in Config.Skins do
	local card = new("Frame", { BackgroundColor3 = C.WoodLight, LayoutOrder = i, Parent = shopPanel.Content })
	UIKit.corner(card, 12)
	UIKit.stroke(card, 3)
	local ball = new("Frame", {
		BackgroundColor3 = skin.Color,
		Size = UDim2.fromOffset(74, 74),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Parent = card,
	})
	UIKit.round(ball)
	UIKit.stroke(ball, 3)
	UIKit.gradient(ball, { Color3.new(1, 1, 1), Color3.new(0.7, 0.72, 0.8) }, 60)
	-- little clumps so it reads as a snowball
	for k = 1, 3 do
		local clump = new("Frame", {
			BackgroundColor3 = skin.Clump,
			Size = UDim2.fromOffset(14 + k * 3, 14 + k * 3),
			Position = UDim2.fromScale(0.15 + k * 0.18, 0.2 + (k % 2) * 0.35),
			Parent = ball,
		})
		UIKit.round(clump)
	end
	-- slow spin so the shop feels alive
	RunService.RenderStepped:Connect(function()
		if shopPanel.IsOpen then
			ball.Rotation = (os.clock() * 40 + i * 50) % 360
		end
	end)

	UIKit.label({
		Text = skin.Name,
		Size = UDim2.new(1, -16, 0, 24),
		Position = UDim2.new(0.5, 0, 0, 90),
		AnchorPoint = Vector2.new(0.5, 0),
		Stroke = 2.5,
		Parent = card,
	})
	local priceLabel = UIKit.label({
		Text = if skin.Bonus > 0 then "+" .. math.floor(skin.Bonus * 100) .. "% coins" else "Starter ball",
		TextColor3 = Color3.fromRGB(140, 255, 110),
		Size = UDim2.new(1, -16, 0, 18),
		Position = UDim2.new(0.5, 0, 0, 116),
		AnchorPoint = Vector2.new(0.5, 0),
		Stroke = 2,
		Parent = card,
	})
	local _ = priceLabel
	local b = UIKit.button({
		Size = UDim2.fromOffset(176, 46),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Text = "",
		Parent = card,
		OnClick = function()
			Panels.Callbacks.BuySkin(skin.Id)
		end,
	})
	b.Label.TextXAlignment = Enum.TextXAlignment.Center
	local coinIcon = UIKit.coin(b.Face, 26, UDim2.new(0, 12, 0.5, 0), Vector2.new(0, 0.5))
	skinCards[skin.Id] = { Button = b, Price = priceLabel, Ball = ball, Coin = coinIcon }
end

local function refreshShop()
	if not data then
		return
	end
	for id, card in skinCards do
		local skin = Config.SkinById[id]
		card.Coin.Visible = not data.Skins[id]
		if data.Skin == id then
			card.Button.SetText("Equipped")
			card.Button.SetColors(C.Purple, C.PurpleDark)
		elseif data.Skins[id] then
			card.Button.SetText("Equip")
			card.Button.SetColors(C.Blue, C.BlueDark)
		else
			card.Button.SetText(Config.Short(skin.Price))
			if data.Coins >= skin.Price then
				card.Button.SetColors(C.Green, C.GreenDark)
			else
				card.Button.SetColors(C.Grey, C.GreyDark)
			end
		end
	end
end

function Panels.anySkinAffordable(d: any): boolean
	if not d then
		return false
	end
	for _, skin in Config.Skins do
		if not d.Skins[skin.Id] and d.Coins >= skin.Price then
			return true
		end
	end
	return false
end

----------------------------------------------------------------------
-- Rebirth
----------------------------------------------------------------------
local rebirthPanel = UIKit.panel(Hud.Root, "Rebirth", "🔄", 560, 430)
register("Rebirth", rebirthPanel)

local rebirthInfo = UIKit.label({
	Text = "",
	RichText = true,
	TextScaled = false,
	TextSize = 22,
	TextWrapped = true,
	Size = UDim2.new(1, -10, 0, 150),
	Position = UDim2.fromOffset(5, 0),
	Stroke = 2,
	Parent = rebirthPanel.Content,
})
local rebirthBonus = UIKit.label({
	Text = "",
	TextColor3 = Color3.fromRGB(140, 255, 110),
	Size = UDim2.new(1, -10, 0, 30),
	Position = UDim2.fromOffset(5, 160),
	Stroke = 2.5,
	Parent = rebirthPanel.Content,
})
local rebirthButton = UIKit.button({
	Size = UDim2.fromOffset(300, 64),
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Color = C.Purple,
	DarkColor = C.PurpleDark,
	Text = "Rebirth",
	Icon = "🔄",
	Studs = true,
	Parent = rebirthPanel.Content,
	OnClick = function()
		Panels.Callbacks.Rebirth()
	end,
})

local function refreshRebirth()
	if not data then
		return
	end
	local cost = Config.RebirthCost(data.Rebirths)
	rebirthInfo.Text = string.format(
		'Reset your coins and upgrades to get a <font color="#FFD23C">permanent coin bonus</font>.\nSkins and stats are kept.\n\nCost: <font color="#FFD23C">%s coins</font>',
		Config.Commas(cost)
	)
	local now = math.floor(data.Rebirths * Config.Rebirth.BonusPer * 100)
	local nextB = math.floor((data.Rebirths + 1) * Config.Rebirth.BonusPer * 100)
	rebirthBonus.Text = string.format("Coin bonus: +%d%%  →  +%d%%", now, nextB)
	if data.Coins >= cost then
		rebirthButton.SetColors(C.Purple, C.PurpleDark)
	else
		rebirthButton.SetColors(C.Grey, C.GreyDark)
	end
end

function Panels.canRebirth(d: any): boolean
	return d ~= nil and d.Coins >= Config.RebirthCost(d.Rebirths)
end

----------------------------------------------------------------------
-- Result card ("Run Complete!")
----------------------------------------------------------------------
local result = UIKit.panel(Hud.Root, "Run Complete!", "🏆", 520, 470, false)
result.Root.Name = "ResultCard"

local resultTitle = UIKit.label({
	Text = "NEW BEST!",
	Size = UDim2.new(1, 0, 0, 46),
	Position = UDim2.fromOffset(0, 0),
	Stroke = 3.5,
	Parent = result.Content,
})
local resultGradient = UIKit.gradient(resultTitle, {
	Color3.fromRGB(80, 255, 160),
	Color3.fromRGB(60, 200, 255),
	Color3.fromRGB(120, 90, 255),
	Color3.fromRGB(255, 80, 200),
}, 0)
UIKit.label({
	Text = "You earned:",
	Size = UDim2.new(1, 0, 0, 26),
	Position = UDim2.fromOffset(0, 50),
	Stroke = 2.5,
	Parent = result.Content,
})
local earnedRow = new("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(330, 70),
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 80),
	Parent = result.Content,
})
local earnedCoin = UIKit.coin(earnedRow, 60, UDim2.new(0, 0, 0.5, 0), Vector2.new(0, 0.5))
local earnedLabel = UIKit.label({
	Text = "+0",
	TextColor3 = Color3.fromRGB(110, 255, 90),
	TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.new(1, -72, 0, 60),
	Position = UDim2.new(0, 72, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	Stroke = 4,
	Parent = earnedRow,
})

local tiles: { TextLabel } = {}
local TILE_ICONS = { "🏁", "🔨", "🔥" }
for i = 1, 3 do
	local tile = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(56, 34, 22),
		Size = UDim2.fromOffset(142, 58),
		Position = UDim2.fromOffset((i - 1) * 157, 164),
		Parent = result.Content,
	})
	UIKit.corner(tile, 10)
	UIKit.stroke(tile, 2.5, C.WoodLight)
	UIKit.label({ Text = TILE_ICONS[i], Size = UDim2.fromOffset(36, 36), Position = UDim2.new(0, 10, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Stroke = 0, Parent = tile })
	tiles[i] = UIKit.label({
		Text = "0",
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -60, 0, 28),
		Position = UDim2.new(0, 52, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Stroke = 2.5,
		Parent = tile,
	})
end

local onRetry: () -> () = function() end
local onReturn: () -> () = function() end

local retryButton = UIKit.button({
	Size = UDim2.fromOffset(222, 70),
	Position = UDim2.new(0, 0, 1, -70),
	Color = C.Green,
	DarkColor = C.GreenDark,
	Text = "Retry",
	Studs = true,
	Key = "R",
	Parent = result.Content,
	OnClick = function()
		onRetry()
	end,
})
retryButton.Label.TextXAlignment = Enum.TextXAlignment.Center
local returnButton = UIKit.button({
	Size = UDim2.fromOffset(222, 70),
	Position = UDim2.new(1, -222, 1, -70),
	Color = C.Yellow,
	DarkColor = C.YellowDark,
	Text = "Return",
	Studs = true,
	Key = "Q",
	Parent = result.Content,
	OnClick = function()
		onReturn()
	end,
})
returnButton.Label.TextXAlignment = Enum.TextXAlignment.Center

Panels.ResultOpen = false

RunService.RenderStepped:Connect(function()
	if result.IsOpen then
		resultGradient.Offset = Vector2.new(math.sin(os.clock() * 2) * 0.3, 0)
	end
end)

export type RunResult = { Earned: number, NewBest: boolean, Distance: number, Smashed: number, Combo: number }

function Panels.showResult(r: RunResult, retry: () -> (), back: () -> ())
	onRetry = retry
	onReturn = back
	Panels.ResultOpen = true
	if r.NewBest and r.Earned > 0 then
		resultTitle.Text = "NEW BEST!"
		resultGradient.Enabled = true
		resultTitle.TextColor3 = C.White
	else
		resultGradient.Enabled = false
		if r.Earned >= 1000 then
			resultTitle.Text = "GREAT ROLL!"
			resultTitle.TextColor3 = Color3.fromRGB(255, 220, 60)
		elseif r.Earned >= 100 then
			resultTitle.Text = "NICE ROLL!"
			resultTitle.TextColor3 = Color3.fromRGB(255, 220, 60)
		else
			resultTitle.Text = "KEEP ROLLING!"
			resultTitle.TextColor3 = Color3.fromRGB(150, 210, 255)
		end
	end
	tiles[1].Text = Config.Commas(r.Distance)
	tiles[2].Text = Config.Commas(r.Smashed)
	tiles[3].Text = "x" .. math.max(1, r.Combo)
	earnedLabel.Text = "+0"
	UIKit.openPanel(result)
	UIKit.pop(resultTitle, 1.6)

	-- count the coins up
	task.spawn(function()
		task.wait(0.25)
		local duration = 0.9
		local start = os.clock()
		local lastTick = 0
		while Panels.ResultOpen do
			local t = math.min(1, (os.clock() - start) / duration)
			local eased = 1 - (1 - t) ^ 3
			earnedLabel.Text = "+" .. Config.Commas(r.Earned * eased)
			if os.clock() - lastTick > 0.07 and t < 1 then
				lastTick = os.clock()
				Effects.play("Coin", 1 + t * 0.8, 0.25)
			end
			if t >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end
		UIKit.pop(earnedCoin, 1.4)
		UIKit.pop(earnedLabel, 1.2)
	end)
end

function Panels.hideResult()
	Panels.ResultOpen = false
	UIKit.closePanel(result)
end

----------------------------------------------------------------------
-- Refresh everything from new player data
----------------------------------------------------------------------
function Panels.refresh(newData: any)
	data = newData
	refreshSettings()
	refreshStats()
	refreshShop()
	refreshRebirth()
end

return Panels
