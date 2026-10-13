--!nonstrict
-- Snowball Smash: menu panels (Settings, Stats, Shop, Rebirth, Admin) and the
-- "Run Complete!" results card.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Monetization = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Monetization"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Effects = require(script.Parent:WaitForChild("Effects"))

local C = UIKit.Colors
local new = UIKit.new

local Panels = {}
Panels.Callbacks = {
	SetSetting = function(_key: string, _value: boolean) end,
	BuySkin = function(_id: string) end,
	BuyRobux = function(_kind: string, _key: string) end,
	Admin = function(_action: string, _args: { [string]: any }) end,
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

-- other UI modules (pets, daily) add their panels here so only one is open at a time
function Panels.register(name: string, panel: UIKit.Panel)
	register(name, panel)
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
local settingsPanel = UIKit.panel(Hud.Root, "Settings", "⚙️", 560, 538)
register("Settings", settingsPanel)
list(settingsPanel.Content)

local toggles: { [string]: UIKit.Button } = {}
local SETTINGS = {
	{ Key = "Music", Text = "Music" },
	{ Key = "SFX", Text = "SFX" },
	{ Key = "Shake", Text = "Camera Shake" },
	{ Key = "SpeedLines", Text = "Speed Lines" },
	{ Key = "Hints", Text = "Hints" },
	{ Key = "PerfectPush", Text = "Perfect Push (pass)" },
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
		Effects.play("Toggle", 1.1)
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
-- Shop: Robux passes, coins & boosts (developer products), snowball skins
----------------------------------------------------------------------
local shopPanel = UIKit.panel(Hud.Root, "Shop", "🛒", 860, 600)
register("Shop", shopPanel)

local passOwned: { [string]: boolean } = {}
local robuxPrices: { [string]: number } = {}

local tabBar = new("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 54),
	Parent = shopPanel.Content,
})
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 12),
	Parent = tabBar,
})

local pages: { [string]: ScrollingFrame } = {}
local tabButtons: { [string]: UIKit.Button } = {}

local function page(name: string): ScrollingFrame
	local sf = new("ScrollingFrame", {
		Name = name,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -66),
		Position = UDim2.fromOffset(0, 66),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = C.Yellow,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		Parent = shopPanel.Content,
	})
	new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 10), Parent = sf })
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(240, 236),
		CellPadding = UDim2.fromOffset(16, 16),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = sf,
	})
	pages[name] = sf
	return sf
end

local function showTab(name: string)
	for n, p in pages do
		p.Visible = n == name
		local b = tabButtons[n]
		if n == name then
			b.SetColors(C.Yellow, C.YellowDark)
		else
			b.SetColors(C.WoodLight, C.WoodDark)
		end
	end
end
Panels.showShopTab = showTab

for i, tab in { { "Passes", "👑 Passes" }, { "Products", "💰 Coins & Boosts" }, { "Skins", "⛄ Skins" } } do
	local b = UIKit.button({
		Size = UDim2.fromOffset(230, 50),
		Text = tab[2],
		Parent = tabBar,
		OnClick = function()
			showTab(tab[1])
		end,
	})
	b.Holder.LayoutOrder = i
	b.Label.TextXAlignment = Enum.TextXAlignment.Center
	tabButtons[tab[1]] = b
end

type RobuxCard = { Button: UIKit.Button, Kind: string, Item: any }
local robuxCards: { [string]: RobuxCard } = {}

local function robuxCard(parent: Instance, order: number, kind: string, item)
	local card = new("Frame", { BackgroundColor3 = C.WoodLight, LayoutOrder = order, Parent = parent })
	UIKit.corner(card, 14)
	UIKit.stroke(card, 3)
	local band = new("Frame", {
		BackgroundColor3 = item.Color,
		Size = UDim2.new(1, -12, 0, 86),
		Position = UDim2.fromOffset(6, 6),
		Parent = card,
	})
	UIKit.corner(band, 10)
	UIKit.gradient(band, { Color3.new(1, 1, 1), Color3.new(0.72, 0.72, 0.72) }, 90)
	UIKit.studs(band, 228, 86, 16, 0.85)
	local icon = UIKit.label({ Text = item.Icon, Size = UDim2.fromOffset(70, 70), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Stroke = 0, Parent = band })
	-- idle wobble on the icon
	RunService.RenderStepped:Connect(function()
		if shopPanel.IsOpen then
			icon.Rotation = math.sin(os.clock() * 2 + order) * 8
		end
	end)
	UIKit.label({ Text = item.Name, Size = UDim2.new(1, -16, 0, 26), Position = UDim2.new(0.5, 0, 0, 96), AnchorPoint = Vector2.new(0.5, 0), Stroke = 2.5, Parent = card })
	UIKit.label({
		Text = item.Desc,
		TextScaled = false,
		TextSize = 15,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = Color3.fromRGB(255, 236, 200),
		Size = UDim2.new(1, -20, 0, 52),
		Position = UDim2.new(0.5, 0, 0, 124),
		AnchorPoint = Vector2.new(0.5, 0),
		Stroke = 1.5,
		Parent = card,
	})
	local b = UIKit.button({
		Size = UDim2.fromOffset(210, 46),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Color = C.Green,
		DarkColor = C.GreenDark,
		Text = "R$ " .. item.Price,
		Parent = card,
		OnClick = function()
			Panels.Callbacks.BuyRobux(kind, item.Key)
		end,
	})
	b.Label.TextXAlignment = Enum.TextXAlignment.Center
	robuxCards[item.Key] = { Button = b, Kind = kind, Item = item }
end

local passesPage = page("Passes")
for i, pass in Monetization.Passes do
	robuxCard(passesPage, i, "Pass", pass)
end
local productsPage = page("Products")
for i, product in Monetization.Products do
	robuxCard(productsPage, i, "Product", product)
end

local function refreshRobux()
	for key, card in robuxCards do
		local price = robuxPrices[key] or card.Item.Price
		if card.Kind == "Pass" and passOwned[key] then
			card.Button.SetText("✔ OWNED")
			card.Button.SetColors(C.Purple, C.PurpleDark)
		else
			card.Button.SetText("R$ " .. Config.Commas(price))
			card.Button.SetColors(C.Green, C.GreenDark)
		end
	end
end

function Panels.setRobuxPrice(key: string, price: number)
	robuxPrices[key] = price
	refreshRobux()
end

function Panels.setPasses(owned: { [string]: boolean })
	passOwned = owned
	refreshRobux()
	Panels.refresh(data)
end

-- skins
local skinsPage = page("Skins")
type SkinCard = { Button: UIKit.Button, Ball: Frame, Coin: Frame, Card: Frame }
local skinCards: { [string]: SkinCard } = {}

for i, skin in Config.Skins do
	local card = new("Frame", { BackgroundColor3 = C.WoodLight, LayoutOrder = i, Parent = skinsPage })
	UIKit.corner(card, 14)
	UIKit.stroke(card, 3)
	local ball = new("Frame", {
		BackgroundColor3 = skin.Color,
		Size = UDim2.fromOffset(90, 90),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Parent = card,
	})
	UIKit.round(ball)
	UIKit.stroke(ball, 3)
	local shade = UIKit.gradient(ball, { Color3.new(1, 1, 1), Color3.new(0.7, 0.72, 0.8) }, 60)
	if skin.Rainbow then
		shade.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 60)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 230, 110)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(70, 150, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 90, 255)),
		})
		ball.BackgroundColor3 = Color3.new(1, 1, 1)
	end
	for k = 1, 3 do
		local clump = new("Frame", {
			BackgroundColor3 = skin.Clump,
			Size = UDim2.fromOffset(16 + k * 3, 16 + k * 3),
			Position = UDim2.fromScale(0.15 + k * 0.18, 0.2 + (k % 2) * 0.35),
			Parent = ball,
		})
		UIKit.round(clump)
	end
	RunService.RenderStepped:Connect(function()
		if shopPanel.IsOpen then
			ball.Rotation = (os.clock() * 40 + i * 50) % 360
		end
	end)
	UIKit.label({ Text = skin.Name, Size = UDim2.new(1, -16, 0, 26), Position = UDim2.new(0.5, 0, 0, 108), AnchorPoint = Vector2.new(0.5, 0), Stroke = 2.5, Parent = card })
	UIKit.label({
		Text = if skin.Bonus > 0 then "+" .. math.floor(skin.Bonus * 100) .. "% coins" else "Starter ball",
		TextColor3 = Color3.fromRGB(140, 255, 110),
		Size = UDim2.new(1, -16, 0, 20),
		Position = UDim2.new(0.5, 0, 0, 138),
		AnchorPoint = Vector2.new(0.5, 0),
		Stroke = 2,
		Parent = card,
	})
	local b = UIKit.button({
		Size = UDim2.fromOffset(210, 46),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Text = "",
		Parent = card,
		OnClick = function()
			if skin.Pass and not passOwned[skin.Pass] then
				Panels.Callbacks.BuyRobux("Pass", skin.Pass)
			else
				Panels.Callbacks.BuySkin(skin.Id)
			end
		end,
	})
	b.Label.TextXAlignment = Enum.TextXAlignment.Center
	local coinIcon = UIKit.coin(b.Face, 26, UDim2.new(0, 12, 0.5, 0), Vector2.new(0, 0.5))
	skinCards[skin.Id] = { Button = b, Ball = ball, Coin = coinIcon, Card = card }
end

local function refreshShop()
	refreshRobux()
	if not data then
		return
	end
	for id, card in skinCards do
		local skin = Config.SkinById[id]
		local unlocked = data.Skins[id] or (skin.Pass ~= nil and passOwned[skin.Pass])
		local candy = skin.Currency == "Candy"
		card.Coin.Visible = not unlocked and skin.Pass == nil and not candy
		-- Halloween skins only show during the event (or once you own them)
		card.Card.Visible = not candy or Config.Halloween.Enabled or unlocked
		if data.Skin == id then
			card.Button.SetText("Equipped")
			card.Button.SetColors(C.Purple, C.PurpleDark)
		elseif unlocked then
			card.Button.SetText("Equip")
			card.Button.SetColors(C.Blue, C.BlueDark)
		elseif skin.Pass then
			local pass = Monetization.PassByKey[skin.Pass]
			card.Button.SetText("R$ " .. Config.Commas(robuxPrices[skin.Pass] or pass.Price))
			card.Button.SetColors(C.Green, C.GreenDark)
		elseif candy then
			card.Button.SetText("🍬 " .. Config.Short(skin.Price))
			if (data.Candy or 0) >= skin.Price then
				card.Button.SetColors(Color3.fromRGB(255, 140, 30), Color3.fromRGB(190, 80, 10))
			else
				card.Button.SetColors(C.Grey, C.GreyDark)
			end
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

showTab("Passes")

function Panels.anySkinAffordable(d: any): boolean
	if not d then
		return false
	end
	for _, skin in Config.Skins do
		if not skin.Pass and not d.Skins[skin.Id] and d.Coins >= skin.Price then
			return true
		end
	end
	return false
end

----------------------------------------------------------------------
-- Admin panel (only shown to admins; every action is checked on the server)
----------------------------------------------------------------------
local adminPanel = UIKit.panel(Hud.Root, "Admin Panel", "🛡️", 860, 600)
register("Admin", adminPanel)

local adminScroll = new("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 8,
	ScrollBarImageColor3 = C.Yellow,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	Parent = adminPanel.Content,
})
new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = adminScroll })
new("UIPadding", { PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 12), Parent = adminScroll })

local sectionOrder = 0
local function section(title: string, height: number): Frame
	sectionOrder += 1
	local f = new("Frame", {
		BackgroundColor3 = C.WoodLight,
		Size = UDim2.new(1, 0, 0, height),
		LayoutOrder = sectionOrder,
		Parent = adminScroll,
	})
	UIKit.corner(f, 12)
	UIKit.stroke(f, 3)
	UIKit.label({ Text = title, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -24, 0, 28), Position = UDim2.fromOffset(14, 8), Stroke = 2.5, Parent = f })
	return f
end

local function smallButton(parent: Instance, text: string, size: UDim2, position: UDim2, color: Color3, dark: Color3, onClick: () -> ()): UIKit.Button
	local b = UIKit.button({ Size = size, Position = position, Color = color, DarkColor = dark, Text = text, Parent = parent, OnClick = onClick, Corner = 10 })
	b.Label.TextXAlignment = Enum.TextXAlignment.Center
	return b
end

local function admin(action: string, args: { [string]: any })
	Panels.Callbacks.Admin(action, args)
end

-- announcement
local annSection = section("📢 Announcement (everyone sees it)", 100)
local annBox = UIKit.textbox(annSection, "Type an announcement...", UDim2.new(1, -170, 0, 46), UDim2.fromOffset(14, 44))
smallButton(annSection, "Send", UDim2.fromOffset(130, 46), UDim2.new(1, -144, 0, 42), C.Green, C.GreenDark, function()
	admin("Announce", { Text = annBox.Text })
	annBox.Text = ""
end)

-- storms
local stormSection = section("🌪️ Storms & events (whole server)", 288)
local durations = { 1, 5, 15, 30 }
local chosenMinutes = 5
local durationButtons: { [number]: UIKit.Button } = {}
UIKit.label({ Text = "Duration:", TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(110, 24), Position = UDim2.fromOffset(14, 50), Stroke = 2, Parent = stormSection })
local function refreshDurations()
	for m, b in durationButtons do
		if m == chosenMinutes then
			b.SetColors(C.Yellow, C.YellowDark)
		else
			b.SetColors(C.WoodDark, Color3.fromRGB(40, 24, 14))
		end
	end
end
for i, m in durations do
	durationButtons[m] = smallButton(stormSection, m .. " min", UDim2.fromOffset(96, 40), UDim2.fromOffset(124 + (i - 1) * 106, 42), C.WoodDark, C.Outline, function()
		chosenMinutes = m
		refreshDurations()
	end)
end
refreshDurations()

local eventButtons: { [string]: UIKit.Button } = {}
for i, e in Config.Events do
	local col = (i - 1) % 3
	local rowI = (i - 1) // 3
	local b = UIKit.button({
		Size = UDim2.fromOffset(246, 56),
		Position = UDim2.fromOffset(14 + col * 258, 96 + rowI * 66),
		Color = e.Color,
		DarkColor = Color3.new(e.Color.R * 0.6, e.Color.G * 0.6, e.Color.B * 0.6),
		Text = e.Name,
		Icon = e.Icon,
		Parent = stormSection,
		Corner = 10,
		OnClick = function()
			admin("StartEvent", { Id = e.Id, Minutes = chosenMinutes })
		end,
	})
	eventButtons[e.Id] = b
end
smallButton(stormSection, "⛔ Stop all storms", UDim2.fromOffset(250, 46), UDim2.fromOffset(14, 230), C.Red, C.RedDark, function()
	admin("StopEvent", { Id = "All" })
end)

-- players
local giveSection = section("🎁 Give to a player (leave the name empty = yourself)", 160)
local targetBox = UIKit.textbox(giveSection, "Player name (empty = me)", UDim2.fromOffset(380, 46), UDim2.fromOffset(14, 44))
local amountBox = UIKit.textbox(giveSection, "Amount", UDim2.fromOffset(200, 46), UDim2.fromOffset(408, 44))
smallButton(giveSection, "🪙 Give Coins", UDim2.fromOffset(250, 48), UDim2.fromOffset(14, 102), C.Yellow, C.YellowDark, function()
	admin("GiveCoins", { Target = targetBox.Text, Amount = tonumber(amountBox.Text) })
end)
smallButton(giveSection, "🚀 Give Turbos", UDim2.fromOffset(250, 48), UDim2.fromOffset(278, 102), C.Red, C.RedDark, function()
	admin("GiveTurbos", { Target = targetBox.Text, Amount = tonumber(amountBox.Text) or 5 })
end)
smallButton(giveSection, "🍬 Give Candy", UDim2.fromOffset(250, 48), UDim2.fromOffset(542, 102), Color3.fromRGB(255, 140, 30), Color3.fromRGB(190, 80, 10), function()
	admin("GiveCandy", { Target = targetBox.Text, Amount = tonumber(amountBox.Text) })
end)

-- game passes
local passSection = section("👑 Game passes (uses the player name above)", 52 + #Monetization.Passes * 56)
for i, pass in Monetization.Passes do
	local y = 46 + (i - 1) * 56
	UIKit.label({
		Text = pass.Icon .. "  " .. pass.Name,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromOffset(300, 30),
		Position = UDim2.fromOffset(18, y + 8),
		Stroke = 2,
		Parent = passSection,
	})
	smallButton(passSection, "Give", UDim2.fromOffset(150, 46), UDim2.fromOffset(340, y), C.Green, C.GreenDark, function()
		admin("SetPass", { Target = targetBox.Text, Pass = pass.Key, Give = true })
	end)
	smallButton(passSection, "Remove", UDim2.fromOffset(150, 46), UDim2.fromOffset(504, y), C.Red, C.RedDark, function()
		admin("SetPass", { Target = targetBox.Text, Pass = pass.Key, Give = false })
	end)
end

-- highlight running storms
RunService.RenderStepped:Connect(function()
	if not adminPanel.IsOpen then
		return
	end
	local state = ReplicatedStorage:FindFirstChild("GameState")
	local t = workspace:GetServerTimeNow()
	for id, b in eventButtons do
		local ends = state and state:GetAttribute("Event_" .. id)
		local on = type(ends) == "number" and ends > t
		b.SetText(Config.EventById[id].Name .. (if on then " ✔" else ""))
	end
end)

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
