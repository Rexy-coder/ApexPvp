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
	Admin = function(_action: string, _args: { [string]: any }): (boolean, any) return false, nil end,
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
		local event = skin.Currency ~= nil and skin.Currency ~= "Coins"
		card.Coin.Visible = not unlocked and skin.Pass == nil and not event
		-- event skins only show during their event (or once you own them)
		local eventOn = (skin.Currency == "Candy" and Config.Halloween.Enabled) or (skin.Currency == "Presents" and Config.Winter.Enabled)
		card.Card.Visible = not event or eventOn or unlocked
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
		elseif event then
			local currency = Config.Currencies[skin.Currency]
			card.Button.SetText(currency.Icon .. " " .. Config.Short(skin.Price))
			if (data[skin.Currency] or 0) >= skin.Price then
				local c = currency.Color
				card.Button.SetColors(c, Color3.new(c.R * 0.7, c.G * 0.7, c.B * 0.7))
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
-- Tabs: Server (announcements + info), Events (crazy events + storms),
-- Players (pick a player, give stuff, passes, pets, moderation)
----------------------------------------------------------------------
local Players = game:GetService("Players")
local Pets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Pets"))
local PetModels = require(script.Parent:WaitForChild("PetModels"))

local adminPanel = UIKit.panel(Hud.Root, "Admin Panel", "🛡️", 960, 640)
register("Admin", adminPanel)

local globalOn = false -- send announcements / events to ALL servers

local function admin(action: string, args: { [string]: any }): (boolean, any)
	return Panels.Callbacks.Admin(action, args)
end

local function smallButton(parent: Instance, text: string, size: UDim2, position: UDim2, color: Color3, dark: Color3, onClick: () -> ()): UIKit.Button
	local b = UIKit.button({ Size = size, Position = position, Color = color, DarkColor = dark, Text = text, Parent = parent, OnClick = onClick, Corner = 10 })
	b.Label.TextXAlignment = Enum.TextXAlignment.Center
	return b
end

local function darker(c: Color3): Color3
	return Color3.new(c.R * 0.6, c.G * 0.6, c.B * 0.6)
end

-- tab bar + "all servers" switch
local adminTabBar = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 54), Parent = adminPanel.Content })
local adminPages: { [string]: Frame } = {}
local adminTabButtons: { [string]: UIKit.Button } = {}

local function showAdminTab(name: string)
	for n, p in adminPages do
		p.Visible = n == name
		if n == name then
			adminTabButtons[n].SetColors(C.Yellow, C.YellowDark)
		else
			adminTabButtons[n].SetColors(C.WoodLight, C.WoodDark)
		end
	end
end

for i, tab in { { "Server", "🌍 Server" }, { "Events", "🤯 Events" }, { "Players", "👥 Players" } } do
	local b = UIKit.button({
		Size = UDim2.fromOffset(190, 50),
		Position = UDim2.fromOffset((i - 1) * 202, 0),
		Text = tab[2],
		Parent = adminTabBar,
		OnClick = function()
			showAdminTab(tab[1])
		end,
	})
	b.Label.TextXAlignment = Enum.TextXAlignment.Center
	adminTabButtons[tab[1]] = b
end

local globalButton = smallButton(adminTabBar, "", UDim2.fromOffset(290, 50), UDim2.new(1, -290, 0, 0), C.Grey, C.GreyDark, function() end)
local function refreshGlobal()
	globalButton.SetText(if globalOn then "🌍 ALL SERVERS: ON" else "🏠 THIS SERVER ONLY")
	globalButton.SetColors(if globalOn then C.Pink else C.Slate, if globalOn then C.PurpleDark else Color3.fromRGB(18, 22, 32))
end
globalButton.Clicked = function()
	globalOn = not globalOn
	refreshGlobal()
end
refreshGlobal()

local function adminPage(name: string, scroll: boolean): Frame
	local f
	if scroll then
		f = new("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 8,
			ScrollBarImageColor3 = C.Yellow,
			ScrollingDirection = Enum.ScrollingDirection.Y,
		})
		new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = f })
		new("UIPadding", { PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 12), Parent = f })
	else
		f = new("Frame", { BackgroundTransparency = 1 })
	end
	f.Name = name
	f.Size = UDim2.new(1, 0, 1, -66)
	f.Position = UDim2.fromOffset(0, 66)
	f.Visible = false
	f.Parent = adminPanel.Content
	adminPages[name] = f
	return f
end

local sectionOrder = 0
local function section(parent: Instance, title: string, height: number): Frame
	sectionOrder += 1
	local f = new("Frame", {
		BackgroundColor3 = C.WoodLight,
		Size = UDim2.new(1, 0, 0, height),
		LayoutOrder = sectionOrder,
		Parent = parent,
	})
	UIKit.corner(f, 12)
	UIKit.stroke(f, 3)
	UIKit.label({ Text = title, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -24, 0, 28), Position = UDim2.fromOffset(14, 8), Stroke = 2.5, Parent = f })
	return f
end

local function infoText(parent: Instance, position: UDim2, size: UDim2): TextLabel
	return UIKit.label({
		Text = "",
		RichText = true,
		TextScaled = false,
		TextSize = 20,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Size = size,
		Position = position,
		Stroke = 2,
		Parent = parent,
	})
end

local function clock(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 3600 then
		return string.format("%d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function gameState(): Instance?
	return ReplicatedStorage:FindFirstChild("GameState")
end

----------------------------------------------------------------------
-- Server tab
----------------------------------------------------------------------
local serverPage = adminPage("Server", true)

local annSection = section(serverPage, "📢 Announcement (uses the server switch at the top right)", 104)
local annBox = UIKit.textbox(annSection, "Type an announcement...", UDim2.new(1, -170, 0, 46), UDim2.fromOffset(14, 46))
smallButton(annSection, "Send", UDim2.fromOffset(130, 46), UDim2.new(1, -144, 0, 44), C.Green, C.GreenDark, function()
	admin("Announce", { Text = annBox.Text, Global = globalOn })
	annBox.Text = ""
end)

local quickSection = section(serverPage, "⚡ Quick messages", 104)
for i, q in { "ADMIN ABUSE STARTING! 🔥", "Thanks for playing! ❤️", "Big update soon! 👀", "Event in 5 minutes! ⏰" } do
	smallButton(quickSection, q, UDim2.fromOffset(212, 46), UDim2.fromOffset(14 + (i - 1) * 222, 46), C.Blue, C.BlueDark, function()
		admin("Announce", { Text = q, Global = globalOn })
	end)
end

local infoSection = section(serverPage, "📊 This server", 210)
local serverInfo = infoText(infoSection, UDim2.fromOffset(16, 44), UDim2.new(1, -32, 1, -52))

----------------------------------------------------------------------
-- Events tab
----------------------------------------------------------------------
local eventsPage = adminPage("Events", true)

local crazyCount = 0
for _, e in Config.Events do
	if e.Crazy then
		crazyCount += 1
	end
end
local crazyRows = math.ceil(crazyCount / 2)
local crazyBottom = 44 + crazyRows * 84
local crazySection = section(eventsPage, "🤯 Crazy events (10 second countdown for everyone)", crazyBottom + 104)
local crazyButtons: { [string]: UIKit.Button } = {}
local crazyIndex = 0
for _, e in Config.Events do
	if e.Crazy then
		local col = crazyIndex % 2
		local rowI = crazyIndex // 2
		crazyIndex += 1
		local b = UIKit.button({
			Size = UDim2.fromOffset(300, 74),
			Position = UDim2.fromOffset(14 + col * 314, 44 + rowI * 84),
			Color = e.Color,
			DarkColor = darker(e.Color),
			Text = e.Name,
			Icon = e.Icon,
			Studs = true,
			Parent = crazySection,
			Corner = 12,
			OnClick = function()
				admin("StartEvent", { Id = e.Id, Minutes = Config.CrazyEvents.Minutes, Global = globalOn })
			end,
		})
		crazyButtons[e.Id] = b
	end
end
local autoButton = smallButton(crazySection, "", UDim2.fromOffset(300, 48), UDim2.fromOffset(14, crazyBottom + 4), C.Green, C.GreenDark, function() end)
autoButton.Clicked = function()
	local state = gameState()
	admin("CrazyAuto", { On = not (state and state:GetAttribute("CrazyAuto") == true) })
end
smallButton(crazySection, "🎲 Random one NOW", UDim2.fromOffset(300, 48), UDim2.fromOffset(328, crazyBottom + 4), C.Purple, C.PurpleDark, function()
	admin("CrazyNext", { Minutes = 0 })
end)
local nextLabel = UIKit.label({ Text = "", TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -30, 0, 26), Position = UDim2.fromOffset(16, crazyBottom + 64), Stroke = 2, TextColor3 = Color3.fromRGB(255, 225, 120), Parent = crazySection })

local stormSection = section(eventsPage, "🌪️ Storms (whole server)", 300)
local chosenMinutes = 5
local durationButtons: { [number]: UIKit.Button } = {}
UIKit.label({ Text = "Duration:", TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(110, 24), Position = UDim2.fromOffset(14, 52), Stroke = 2, Parent = stormSection })
local function refreshDurations()
	for m, b in durationButtons do
		if m == chosenMinutes then
			b.SetColors(C.Yellow, C.YellowDark)
		else
			b.SetColors(C.WoodDark, Color3.fromRGB(40, 24, 14))
		end
	end
end
for i, m in { 1, 5, 15, 30, 60 } do
	durationButtons[m] = smallButton(stormSection, m .. " min", UDim2.fromOffset(96, 40), UDim2.fromOffset(124 + (i - 1) * 106, 44), C.WoodDark, C.Outline, function()
		chosenMinutes = m
		refreshDurations()
	end)
end
refreshDurations()

local eventButtons: { [string]: UIKit.Button } = {}
local stormIndex = 0
for _, e in Config.Events do
	if not e.Crazy and not e.Custom then
		local col = stormIndex % 3
		local rowI = stormIndex // 3
		stormIndex += 1
		eventButtons[e.Id] = UIKit.button({
			Size = UDim2.fromOffset(280, 56),
			Position = UDim2.fromOffset(14 + col * 292, 98 + rowI * 66),
			Color = e.Color,
			DarkColor = darker(e.Color),
			Text = e.Name,
			Icon = e.Icon,
			Parent = stormSection,
			Corner = 10,
			OnClick = function()
				admin("StartEvent", { Id = e.Id, Minutes = chosenMinutes, Global = globalOn })
			end,
		})
	end
end
smallButton(stormSection, "⛔ Stop ALL events", UDim2.fromOffset(280, 46), UDim2.fromOffset(14, 240), C.Red, C.RedDark, function()
	admin("StopEvent", { Id = "All", Global = globalOn })
end)

-- custom multipliers: type any number (x999, x10000, x1000000...)
local customSection = section(eventsPage, "✖️ Custom multiplier storms (type ANY multiplier)", 214)
UIKit.label({ Text = "x", Size = UDim2.fromOffset(30, 46), Position = UDim2.fromOffset(14, 44), Stroke = 3, Parent = customSection })
local multBox = UIKit.textbox(customSection, "999", UDim2.fromOffset(250, 46), UDim2.fromOffset(44, 44))
multBox.Text = "100"
for i, quick in { 10, 100, 999, 10000, 1000000 } do
	smallButton(customSection, "x" .. Config.Short(quick), UDim2.fromOffset(104, 46), UDim2.fromOffset(310 + (i - 1) * 112, 44), C.WoodDark, C.Outline, function()
		multBox.Text = tostring(quick)
	end)
end
UIKit.label({ Text = "Uses the duration picked above. Everyone in the server gets it.", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 230, 190), Size = UDim2.new(1, -30, 0, 22), Position = UDim2.fromOffset(16, 100), Stroke = 1.5, Parent = customSection })
local customIndex = 0
for _, e in Config.Events do
	if e.Custom then
		eventButtons[e.Id] = UIKit.button({
			Size = UDim2.fromOffset(280, 56),
			Position = UDim2.fromOffset(14 + customIndex * 292, 138),
			Color = e.Color,
			DarkColor = darker(e.Color),
			Text = e.Name,
			Icon = e.Icon,
			Parent = customSection,
			Corner = 10,
			OnClick = function()
				admin("StartEvent", { Id = e.Id, Minutes = chosenMinutes, Global = globalOn, Mult = tonumber(multBox.Text) })
			end,
		})
		customIndex += 1
	end
end

----------------------------------------------------------------------
-- Players tab: list on the left, actions on the right
----------------------------------------------------------------------
local playersPage = adminPage("Players", false)
local selectedId: number = 0 -- user id, 0 = nobody picked yet (= me)

local listFrame = new("ScrollingFrame", {
	BackgroundColor3 = C.WoodDark,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 250, 1, 0),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 6,
	ScrollBarImageColor3 = C.Yellow,
	Parent = playersPage,
})
UIKit.corner(listFrame, 12)
UIKit.stroke(listFrame, 3)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = listFrame })
new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 8), Parent = listFrame })

local actionScroll = new("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -264, 1, 0),
	Position = UDim2.fromOffset(264, 0),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 8,
	ScrollBarImageColor3 = C.Yellow,
	Parent = playersPage,
})
new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = actionScroll })
new("UIPadding", { PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 12), Parent = actionScroll })

local function selectedPlayer(): Player?
	if selectedId == 0 then
		return Players.LocalPlayer
	end
	return Players:GetPlayerByUserId(selectedId)
end

local function targetName(): string
	local p = selectedPlayer()
	return if p then p.Name else ""
end

-- info card
local infoCard = section(actionScroll, "", 128)
local headshot = new("ImageLabel", {
	BackgroundColor3 = C.WoodDark,
	Size = UDim2.fromOffset(96, 96),
	Position = UDim2.fromOffset(14, 16),
	Image = "",
	Parent = infoCard,
})
UIKit.corner(headshot, 12)
UIKit.stroke(headshot, 2.5)
local infoName = UIKit.label({ Text = "", TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -260, 0, 30), Position = UDim2.fromOffset(124, 14), Stroke = 2.5, Parent = infoCard })
local infoStats = infoText(infoCard, UDim2.fromOffset(124, 50), UDim2.new(1, -140, 0, 70))
infoStats.TextSize = 18
local refreshInspect = function() end
smallButton(infoCard, "🔄", UDim2.fromOffset(56, 44), UDim2.new(1, -70, 0, 12), C.Blue, C.BlueDark, function()
	refreshInspect()
end)

refreshInspect = function()
	local p = selectedPlayer()
	if not p then
		infoName.Text = "Player left"
		infoStats.Text = ""
		return
	end
	infoName.Text = p.DisplayName .. "  (@" .. p.Name .. ")"
	headshot.Image = "rbxthumb://type=AvatarHeadShot&id=" .. p.UserId .. "&w=150&h=150"
	infoStats.Text = "Loading..."
	task.spawn(function()
		local ok, info = admin("Inspect", { Target = p.Name })
		if ok and type(info) == "table" and selectedPlayer() == p then
			infoStats.Text = string.format(
				"🪙 %s   🍬 %s   🎁 %s   🚀 %s\n🐾 %d pets   🔄 %d rebirths   🏁 best %s studs",
				Config.Short(info.Coins), Config.Short(info.Candy), Config.Short(info.Presents), Config.Short(info.Turbos),
				info.Pets, info.Rebirths, Config.Commas(info.BestDistance)
			)
		elseif selectedPlayer() == p then
			infoStats.Text = "Couldn't load"
		end
	end)
end

-- give currencies
local giveSection = section(actionScroll, "🎁 Give (use a minus amount to take away)", 160)
local amountBox = UIKit.textbox(giveSection, "Amount", UDim2.fromOffset(220, 46), UDim2.fromOffset(14, 44))
for i, quick in { 1000, 100000, 10000000 } do
	smallButton(giveSection, Config.Short(quick), UDim2.fromOffset(110, 46), UDim2.fromOffset(246 + (i - 1) * 118, 44), C.WoodDark, C.Outline, function()
		amountBox.Text = tostring(quick)
	end)
end
for i, cur in { { "Coins", "🪙 Coins", C.Yellow }, { "Turbos", "🚀 Turbos", C.Red }, { "Candy", "🍬 Candy", Config.Currencies.Candy.Color }, { "Presents", "🎁 Presents", Config.Currencies.Presents.Color } } do
	smallButton(giveSection, cur[2], UDim2.fromOffset(150, 48), UDim2.fromOffset(14 + (i - 1) * 160, 102), cur[3], darker(cur[3]), function()
		task.spawn(function()
			local ok = admin("GiveCurrency", { Target = targetName(), Currency = cur[1], Amount = tonumber(amountBox.Text) or (if cur[1] == "Turbos" then 5 else nil) })
			if ok then
				refreshInspect()
			end
		end)
	end)
end

-- moderation
local modSection = section(actionScroll, "🛠️ Moderation", 104)
smallButton(modSection, "🧲 Bring", UDim2.fromOffset(150, 48), UDim2.fromOffset(14, 44), C.Blue, C.BlueDark, function()
	admin("Bring", { Target = targetName() })
end)
smallButton(modSection, "🚪 Go to", UDim2.fromOffset(150, 48), UDim2.fromOffset(174, 44), C.Green, C.GreenDark, function()
	admin("GoTo", { Target = targetName() })
end)
local kickArmed = 0
local kickButton
kickButton = smallButton(modSection, "👢 Kick", UDim2.fromOffset(150, 48), UDim2.fromOffset(334, 44), C.Red, C.RedDark, function()
	if os.clock() - kickArmed > 3 then
		kickArmed = os.clock()
		kickButton.SetText("Sure? Click again")
		task.delay(3, function()
			kickButton.SetText("👢 Kick")
		end)
		return
	end
	kickArmed = 0
	kickButton.SetText("👢 Kick")
	admin("Kick", { Target = targetName() })
end)

-- pets: tap a pet to give it
local petSection = section(actionScroll, "🐾 Give a pet (pick a type, then tap a pet)", 112 + math.ceil(#Pets.All / 6) * 92)
local giveVariant = 0
local variantButtons: { [number]: UIKit.Button } = {}
local function refreshVariants()
	for v, b in variantButtons do
		if v == giveVariant then
			b.SetColors(C.Yellow, C.YellowDark)
		else
			b.SetColors(C.WoodDark, Color3.fromRGB(40, 24, 14))
		end
	end
end
for v = 0, Pets.MaxVariant do
	variantButtons[v] = smallButton(petSection, if v == 0 then "Normal" else "★ " .. Pets.VariantName(v), UDim2.fromOffset(130, 38), UDim2.fromOffset(14 + v * 140, 44), C.WoodDark, C.Outline, function()
		giveVariant = v
		refreshVariants()
	end)
end
refreshVariants()
local petGrid = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -28, 1, -104), Position = UDim2.fromOffset(14, 96), Parent = petSection })
new("UIGridLayout", { CellSize = UDim2.fromOffset(92, 84), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = petGrid })
for i, pet in Pets.All do
	local rarity = Pets.Rarities[pet.Rarity]
	local tile = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = rarity.Color, LayoutOrder = i, Parent = petGrid })
	UIKit.corner(tile, 10)
	UIKit.stroke(tile, 2.5)
	UIKit.gradient(tile, { Color3.new(1, 1, 1), Color3.new(0.6, 0.6, 0.65) }, 90)
	PetModels.viewport(pet.Id, tile, UDim2.fromOffset(64, 56), UDim2.new(0.5, 0, 0, 2), Vector2.new(0.5, 0))
	UIKit.label({ Text = pet.Name, Size = UDim2.new(1, -6, 0, 20), Position = UDim2.new(0.5, 0, 1, -4), AnchorPoint = Vector2.new(0.5, 1), Stroke = 2, Parent = tile })
	tile.Activated:Connect(function()
		Effects.play("Click", 1.2)
		UIKit.pop(tile, 0.85)
		if selectedPlayer() == Players.LocalPlayer then
			Panels.closeAll() -- so you can watch your own hatch animation
		end
		admin("GivePet", { Target = targetName(), Pet = pet.Id, Variant = giveVariant })
	end)
end

-- game passes
local passSection = section(actionScroll, "👑 Game passes", 52 + #Monetization.Passes * 56)
for i, pass in Monetization.Passes do
	local y = 46 + (i - 1) * 56
	UIKit.label({ Text = pass.Icon .. "  " .. pass.Name, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(280, 30), Position = UDim2.fromOffset(18, y + 8), Stroke = 2, Parent = passSection })
	smallButton(passSection, "Give", UDim2.fromOffset(140, 46), UDim2.fromOffset(310, y), C.Green, C.GreenDark, function()
		admin("SetPass", { Target = targetName(), Pass = pass.Key, Give = true })
	end)
	smallButton(passSection, "Remove", UDim2.fromOffset(140, 46), UDim2.fromOffset(460, y), C.Red, C.RedDark, function()
		admin("SetPass", { Target = targetName(), Pass = pass.Key, Give = false })
	end)
end

-- player list
local chips: { [number]: { Button: TextButton, Stroke: UIStroke } } = {}
local function paintChips()
	local sel = selectedPlayer()
	for id, chip in chips do
		local on = sel ~= nil and sel.UserId == id
		chip.Button.BackgroundColor3 = if on then C.Yellow else C.WoodLight
		chip.Stroke.Color = if on then C.White else C.Outline
	end
end

local function selectPlayer(p: Player)
	selectedId = if p == Players.LocalPlayer then 0 else p.UserId
	paintChips()
	refreshInspect()
end

local function rebuildList()
	for _, c in chips do
		c.Button:Destroy()
	end
	table.clear(chips)
	local list = Players:GetPlayers()
	table.sort(list, function(a, b)
		if a == Players.LocalPlayer then
			return true
		elseif b == Players.LocalPlayer then
			return false
		end
		return string.lower(a.DisplayName) < string.lower(b.DisplayName)
	end)
	for i, p in list do
		local chip = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = C.WoodLight, Size = UDim2.new(1, 0, 0, 56), LayoutOrder = i, Parent = listFrame })
		UIKit.corner(chip, 10)
		local stroke = UIKit.stroke(chip, 2.5)
		local img = new("ImageLabel", {
			BackgroundColor3 = C.WoodDark,
			Size = UDim2.fromOffset(44, 44),
			Position = UDim2.fromOffset(6, 6),
			Image = "rbxthumb://type=AvatarHeadShot&id=" .. p.UserId .. "&w=48&h=48",
			Parent = chip,
		})
		UIKit.round(img)
		UIKit.label({
			Text = p.DisplayName .. (if p == Players.LocalPlayer then " (me)" else ""),
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, -64, 0, 24),
			Position = UDim2.fromOffset(58, 6),
			Stroke = 2,
			Parent = chip,
		})
		UIKit.label({
			Text = "@" .. p.Name,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(255, 230, 200),
			Size = UDim2.new(1, -64, 0, 16),
			Position = UDim2.fromOffset(58, 32),
			Stroke = 1.5,
			Parent = chip,
		})
		chip.Activated:Connect(function()
			Effects.play("Click", 1.2)
			selectPlayer(p)
		end)
		chips[p.UserId] = { Button = chip, Stroke = stroke }
	end
	if not selectedPlayer() then
		selectedId = 0
	end
	paintChips()
end
Players.PlayerAdded:Connect(rebuildList)
Players.PlayerRemoving:Connect(function()
	task.defer(rebuildList)
end)
rebuildList()

adminPanel.Root:GetPropertyChangedSignal("Visible"):Connect(function()
	if adminPanel.Root.Visible then
		rebuildList()
		refreshInspect()
	end
end)

showAdminTab("Server")

----------------------------------------------------------------------
-- Live info (only while the panel is open)
----------------------------------------------------------------------
local infoTick = 0
RunService.RenderStepped:Connect(function(dt)
	if not adminPanel.IsOpen then
		return
	end
	infoTick += dt
	if infoTick < 0.25 then
		return
	end
	infoTick = 0
	local state = gameState()
	local t = workspace:GetServerTimeNow()
	local running = {}
	for _, e in Config.Events do
		local ends = state and state:GetAttribute("Event_" .. e.Id)
		local on = type(ends) == "number" and ends > t
		if on then
			table.insert(running, e.Icon .. " " .. e.Name .. " (" .. clock(ends - t) .. ")")
		end
		local b = eventButtons[e.Id] or crazyButtons[e.Id]
		if b then
			b.SetText(e.Name .. (if on then " ✔" else ""))
		end
	end
	local auto = state and state:GetAttribute("CrazyAuto") == true
	autoButton.SetText(if auto then "🎲 Random events: ON" else "🎲 Random events: OFF")
	autoButton.SetColors(if auto then C.Green else C.Grey, if auto then C.GreenDark else C.GreyDark)
	local incoming = state and state:GetAttribute("CrazyIncoming")
	local nextAt = state and state:GetAttribute("NextCrazy")
	if type(incoming) == "string" and incoming ~= "" then
		nextLabel.Text = "⏳ " .. Config.EventById[incoming].Name .. " is starting!"
	elseif auto and type(nextAt) == "number" then
		nextLabel.Text = "⏱️ Next random crazy event in " .. clock(nextAt - t)
	else
		nextLabel.Text = "Random crazy events are off"
	end
	local started = state and state:GetAttribute("ServerStart")
	serverInfo.Text = string.format(
		"👥 Players: <b>%d / %d</b>\n⏱️ Server up for: <b>%s</b>\n🌪️ Running: %s\n🎲 Next crazy event: %s",
		#Players:GetPlayers(), Players.MaxPlayers,
		clock(if type(started) == "number" then t - started else 0),
		if #running > 0 then table.concat(running, ", ") else "nothing",
		if auto and type(nextAt) == "number" then clock(nextAt - t) else "off"
	)
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
