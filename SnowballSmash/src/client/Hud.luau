--!nonstrict
-- Snowball Smash: the always-on HUD. Coins, side menu, top tabs, power bar,
-- run counters, combo tags and toasts.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Effects = require(script.Parent:WaitForChild("Effects"))

local C = UIKit.Colors
local new = UIKit.new

local Hud = {}

Hud.Callbacks = {
	Turbo = function() end,
	Roll = function() end,
	Upgrade = function() end,
	Menu = function(_name: string) end,
	CancelCharge = function() end,
}

local player = Players.LocalPlayer

----------------------------------------------------------------------
-- Root: everything is designed at 1280x720 and scaled to the screen.
----------------------------------------------------------------------
local DESIGN = Vector2.new(1280, 720)

local screenGui = new("ScreenGui", {
	Name = "SnowballSmashUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})
Hud.ScreenGui = screenGui

local speedLayer = new("Frame", {
	Name = "SpeedLines",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 0,
	Parent = screenGui,
})
Effects.setSpeedLayer(speedLayer)

local root = new("Frame", { Name = "Root", BackgroundTransparency = 1, ZIndex = 1, Parent = screenGui })
local rootScale = new("UIScale", { Parent = root })
Hud.Root = root

local function rescale()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local vp = camera.ViewportSize
	local s = math.clamp(math.min(vp.X / DESIGN.X, vp.Y / DESIGN.Y), 0.45, 1.6)
	rootScale.Scale = s
	root.Size = UDim2.fromScale(1 / s, 1 / s)
	Hud.UIScale = s
end
Hud.UIScale = 1
rescale()
local function hookCamera()
	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	end
	rescale()
end
hookCamera()
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hookCamera)

----------------------------------------------------------------------
-- Helper to slide whole groups in and out smoothly
----------------------------------------------------------------------
type Slider = { Frame: GuiObject, Shown: UDim2, Hidden: UDim2, Visible: boolean }
local sliders: { [string]: Slider } = {}

local function makeSlider(name: string, frame: GuiObject, shown: UDim2, hidden: UDim2)
	frame.Position = hidden
	frame.Visible = false
	sliders[name] = { Frame = frame, Shown = shown, Hidden = hidden, Visible = false }
end

local function slide(name: string, visible: boolean, instant: boolean?)
	local s = sliders[name]
	if not s or s.Visible == visible then
		return
	end
	s.Visible = visible
	if visible then
		s.Frame.Visible = true
		if instant then
			s.Frame.Position = s.Shown
		else
			UIKit.tween(s.Frame, 0.45, { Position = s.Shown }, Enum.EasingStyle.Back)
		end
	else
		local t = UIKit.tween(s.Frame, 0.3, { Position = s.Hidden }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		t.Completed:Connect(function()
			if not s.Visible then
				s.Frame.Visible = false
			end
		end)
	end
end

----------------------------------------------------------------------
-- Bottom-left: coins + best
----------------------------------------------------------------------
local wallet = new("Frame", {
	Name = "Wallet",
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(330, 110),
	AnchorPoint = Vector2.new(0, 1),
	Parent = root,
})
makeSlider("Wallet", wallet, UDim2.new(0, 22, 1, -14), UDim2.new(0, -360, 1, -14))
local walletCoin = UIKit.coin(wallet, 62, UDim2.fromOffset(0, 4))
local coinsLabel = UIKit.label({
	Name = "Coins",
	Text = "0",
	TextColor3 = Color3.fromRGB(255, 214, 50),
	TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.fromOffset(260, 58),
	Position = UDim2.fromOffset(72, 6),
	Stroke = 4,
	Parent = wallet,
})
UIKit.gradient(coinsLabel, { Color3.fromRGB(255, 240, 140), Color3.fromRGB(255, 190, 30) }, 90)
local bestLabel = UIKit.label({
	Name = "Best",
	Text = "🏆 BEST 0",
	TextColor3 = Color3.fromRGB(150, 255, 90),
	TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.fromOffset(250, 30),
	Position = UDim2.fromOffset(6, 74),
	Stroke = 3,
	Parent = wallet,
})

local shownCoins = 0
local targetCoins = 0
function Hud.setCoins(amount: number, instant: boolean?)
	if amount > targetCoins and not instant then
		UIKit.pop(walletCoin, 1.3)
	end
	targetCoins = amount
	if instant then
		shownCoins = amount
	end
end
local candyLabel = UIKit.label({
	Name = "Candy",
	Text = "🍬 0",
	TextColor3 = Color3.fromRGB(255, 160, 50),
	TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.fromOffset(150, 30),
	Position = UDim2.fromOffset(190, 74),
	Visible = Config.Halloween.Enabled,
	Stroke = 3,
	Parent = wallet,
})
local lastCandy = 0
function Hud.setCandy(amount: number)
	candyLabel.Text = "🍬 " .. Config.Short(amount)
	candyLabel.Visible = Config.Halloween.Enabled
	if amount > lastCandy then
		UIKit.pop(candyLabel, 1.3)
	end
	lastCandy = amount
end

local presentsLabel = UIKit.label({
	Name = "Presents",
	Text = "🎁 0",
	TextColor3 = Config.Currencies.Presents.Color,
	TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.fromOffset(130, 30),
	Position = UDim2.fromOffset(if Config.Halloween.Enabled then 280 else 190, 74),
	Visible = Config.Winter.Enabled,
	Stroke = 3,
	Parent = wallet,
})
local lastPresents = 0
function Hud.setPresents(amount: number)
	presentsLabel.Text = "🎁 " .. Config.Short(amount)
	presentsLabel.Visible = Config.Winter.Enabled
	if amount > lastPresents then
		UIKit.pop(presentsLabel, 1.3)
	end
	lastPresents = amount
end

function Hud.setBest(best: number)
	bestLabel.Text = "🏆 BEST " .. Config.Short(best)
end

----------------------------------------------------------------------
-- Left: menu tiles (2 x 3), like a little app grid
----------------------------------------------------------------------
local menu = new("Frame", {
	Name = "Menu",
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(296, 290),
	AnchorPoint = Vector2.new(0, 0.5),
	Parent = root,
})
makeSlider("Menu", menu, UDim2.new(0, 16, 0.5, -10), UDim2.new(0, -340, 0.5, -10))

local badges: { [string]: { Alert: Frame, Soon: Frame? } } = {}

local MENU_ITEMS = {
	{ Name = "Shop", Icon = "🛒", Col = 0, Row = 0 },
	{ Name = "Upgrades", Icon = "⬆️", Col = 1, Row = 0 },
	{ Name = "Pets", Icon = "🐧", Col = 2, Row = 0 },
	{ Name = "Index", Icon = "📘", Col = 0, Row = 1 },
	{ Name = "Daily", Icon = "🎁", Col = 1, Row = 1 },
	{ Name = "Rebirth", Icon = "🔄", Col = 2, Row = 1 },
	{ Name = "Stats", Icon = "📊", Col = 0, Row = 2 },
	{ Name = "Settings", Icon = "⚙️", Col = 1, Row = 2 },
	{ Name = "Admin", Icon = "🛡️", Col = 2, Row = 2, AdminOnly = true },
}
local adminTile: Frame? = nil

for _, item in MENU_ITEMS do
	local tile = new("Frame", {
		Name = item.Name,
		Size = UDim2.fromOffset(90, 90),
		Position = UDim2.fromOffset(item.Col * 100, item.Row * 100),
		BackgroundColor3 = C.Slate,
		BackgroundTransparency = 0.25,
		Visible = not item.AdminOnly,
		Parent = menu,
	})
	if item.AdminOnly then
		adminTile = tile
	end
	UIKit.corner(tile, 14)
	UIKit.stroke(tile, 3, C.Outline, 0.1)
	local tileScale = new("UIScale", { Parent = tile })
	local icon = UIKit.label({
		Text = item.Icon,
		Size = UDim2.fromOffset(56, 52),
		Position = UDim2.new(0.5, 0, 0, 6),
		AnchorPoint = Vector2.new(0.5, 0),
		Stroke = 0,
		Parent = tile,
	})
	UIKit.label({
		Text = item.Name,
		Size = UDim2.new(1, -8, 0, 22),
		Position = UDim2.new(0.5, 0, 1, -6),
		AnchorPoint = Vector2.new(0.5, 1),
		Stroke = 2.5,
		Parent = tile,
	})

	local soon: Frame? = nil
	if item.Soon then
		local s = new("Frame", {
			Size = UDim2.fromOffset(54, 22),
			Position = UDim2.new(1, 6, 0, -8),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = C.Yellow,
			Rotation = 6,
			Parent = tile,
		})
		UIKit.corner(s, 8)
		UIKit.stroke(s, 2)
		UIKit.label({ Text = "SOON", Size = UDim2.new(1, -6, 1, -4), Position = UDim2.fromOffset(3, 2), Stroke = 2, Parent = s })
		soon = s
	end

	local alert = new("Frame", {
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, 8, 0, -8),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = C.Red,
		Visible = false,
		Parent = tile,
	})
	UIKit.round(alert)
	UIKit.stroke(alert, 2.5, C.White)
	UIKit.label({ Text = "!", Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), Stroke = 0, Parent = alert })
	badges[item.Name] = { Alert = alert, Soon = soon }

	local hit = new("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		Parent = tile,
	})
	hit.MouseEnter:Connect(function()
		UIKit.tween(tileScale, 0.18, { Scale = 1.08 }, Enum.EasingStyle.Back)
		UIKit.tween(tile, 0.18, { BackgroundTransparency = 0.05 })
		UIKit.tween(icon, 0.25, { Rotation = -8 }, Enum.EasingStyle.Back)
	end)
	hit.MouseLeave:Connect(function()
		UIKit.tween(tileScale, 0.18, { Scale = 1 })
		UIKit.tween(tile, 0.18, { BackgroundTransparency = 0.25 })
		UIKit.tween(icon, 0.25, { Rotation = 0 }, Enum.EasingStyle.Back)
	end)
	hit.MouseButton1Down:Connect(function()
		UIKit.tween(tileScale, 0.08, { Scale = 0.94 })
	end)
	hit.Activated:Connect(function()
		UIKit.tween(tileScale, 0.3, { Scale = 1.08 }, Enum.EasingStyle.Back)
		Effects.play("Click", 1.1)
		Hud.Callbacks.Menu(item.Name)
	end)
end

function Hud.setAdmin(on: boolean)
	if adminTile then
		adminTile.Visible = on
	end
end

-- Gently bob the "!" badges so they catch the eye
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, b in badges do
		if b.Alert.Visible then
			b.Alert.Rotation = math.sin(t * 6) * 10
		end
	end
end)

function Hud.setAlert(name: string, on: boolean)
	local b = badges[name]
	if b then
		b.Alert.Visible = on
	end
end

----------------------------------------------------------------------
-- Top: Roll! / Upgrade tabs
----------------------------------------------------------------------
local tabs = new("Frame", {
	Name = "Tabs",
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(420, 72),
	AnchorPoint = Vector2.new(0.5, 0),
	Parent = root,
})
makeSlider("Tabs", tabs, UDim2.new(0.5, 0, 0, 14), UDim2.new(0.5, 0, 0, -110))
UIKit.button({
	Size = UDim2.fromOffset(204, 70),
	Position = UDim2.fromOffset(0, 0),
	Color = C.Blue,
	DarkColor = C.BlueDark,
	Text = "Roll!",
	Icon = "⛄",
	Studs = true,
	Key = "E",
	Parent = tabs,
	OnClick = function()
		Hud.Callbacks.Roll()
	end,
})
UIKit.button({
	Size = UDim2.fromOffset(204, 70),
	Position = UDim2.fromOffset(216, 0),
	Color = C.Green,
	DarkColor = C.GreenDark,
	Text = "Upgrade",
	Icon = "⬆️",
	Studs = true,
	Key = "U",
	Parent = tabs,
	OnClick = function()
		Hud.Callbacks.Upgrade()
	end,
})

----------------------------------------------------------------------
-- Run counters: coins this run (top centre) and distance (top right)
----------------------------------------------------------------------
local function pill(width: number, height: number): Frame
	local f = new("Frame", {
		BackgroundColor3 = C.Slate,
		BackgroundTransparency = 0.3,
		Size = UDim2.fromOffset(width, height),
		Parent = root,
	})
	UIKit.corner(f, 12)
	UIKit.stroke(f, 3, C.Outline, 0.15)
	return f
end

local runCoins = pill(230, 54)
runCoins.AnchorPoint = Vector2.new(0.5, 0)
makeSlider("RunCoins", runCoins, UDim2.new(0.5, 0, 0, 14), UDim2.new(0.5, 0, 0, -90))
local runCoinIcon = UIKit.coin(runCoins, 40, UDim2.new(0, 8, 0.5, 0), Vector2.new(0, 0.5))
local runCoinsLabel = UIKit.label({
	Text = "0",
	TextColor3 = Color3.fromRGB(255, 220, 70),
	TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.new(1, -64, 0, 36),
	Position = UDim2.new(0, 56, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	Stroke = 3,
	Parent = runCoins,
})

local distance = pill(170, 50)
distance.AnchorPoint = Vector2.new(1, 0)
makeSlider("Distance", distance, UDim2.new(1, -20, 0, 20), UDim2.new(1, 200, 0, 20))
UIKit.label({ Text = "🏁", Size = UDim2.fromOffset(36, 36), Position = UDim2.new(0, 8, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Stroke = 0, Parent = distance })
local distanceLabel = UIKit.label({
	Text = "0",
	TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.new(1, -60, 0, 30),
	Position = UDim2.new(0, 50, 0, 6),
	Stroke = 3,
	Parent = distance,
})
UIKit.label({
	Text = "STUDS",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(190, 200, 220),
	Size = UDim2.new(1, -60, 0, 12),
	Position = UDim2.new(0, 51, 1, -16),
	Stroke = 1.5,
	Parent = distance,
})

-- speed gauge under the distance pill
local speedBar = pill(170, 18)
speedBar.AnchorPoint = Vector2.new(1, 0)
makeSlider("Speed", speedBar, UDim2.new(1, -20, 0, 78), UDim2.new(1, 200, 0, 78))
local speedFill = new("Frame", {
	BackgroundColor3 = C.White,
	Size = UDim2.new(0, 0, 1, -6),
	Position = UDim2.fromOffset(3, 3),
	Parent = speedBar,
})
UIKit.corner(speedFill, 6)
UIKit.gradient(speedFill, { Color3.fromRGB(90, 200, 255), Color3.fromRGB(255, 90, 200) }, 0)

local shownRunCoins = 0
local targetRunCoins = 0
function Hud.setRunCoins(n: number, instant: boolean?)
	if n > targetRunCoins then
		UIKit.pop(runCoinIcon, 1.35)
	end
	targetRunCoins = n
	if instant then
		shownRunCoins = n
		runCoinsLabel.Text = Config.Commas(n)
	end
end
function Hud.setDistance(d: number)
	distanceLabel.Text = Config.Commas(d)
end
function Hud.setSpeed(fraction: number)
	speedFill.Size = UDim2.new(math.clamp(fraction, 0, 1), -6, 1, -6)
end

----------------------------------------------------------------------
-- Combo tag + CRITICAL! text
----------------------------------------------------------------------
local comboTag = new("Frame", {
	Name = "Combo",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 70, 0, 92),
	Size = UDim2.fromOffset(96, 52),
	BackgroundColor3 = C.Pink,
	Rotation = -6,
	Visible = false,
	Parent = root,
})
UIKit.corner(comboTag, 12)
UIKit.stroke(comboTag, 3)
UIKit.gradient(comboTag, { Color3.fromRGB(255, 140, 220), C.Pink }, 90)
local comboLabel = UIKit.label({ Text = "x2", Size = UDim2.new(1, -12, 1, -10), Position = UDim2.fromOffset(6, 5), Stroke = 3, Parent = comboTag })
local comboHideAt = 0

function Hud.combo(n: number, window: number)
	if n < 2 then
		return
	end
	comboLabel.Text = "x" .. n
	comboTag.Visible = true
	comboTag.Rotation = (math.random() - 0.5) * 16
	UIKit.pop(comboTag, 1.6)
	comboHideAt = os.clock() + window
end

local critLabel = UIKit.label({
	Text = "CRITICAL!",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0, 150),
	Size = UDim2.fromOffset(300, 64),
	Rotation = -8,
	Visible = false,
	Stroke = 4,
	Parent = root,
})
UIKit.gradient(critLabel, { Color3.fromRGB(255, 240, 90), Color3.fromRGB(255, 110, 30) }, 90)

function Hud.critical()
	critLabel.Visible = true
	critLabel.TextTransparency = 0
	critLabel.Rotation = -8 + (math.random() - 0.5) * 8
	UIKit.pop(critLabel, 1.8)
	task.delay(0.7, function()
		local t = UIKit.tween(critLabel, 0.25, { TextTransparency = 1 })
		t.Completed:Connect(function()
			critLabel.Visible = false
		end)
	end)
end

----------------------------------------------------------------------
-- Power panel (bottom centre)
----------------------------------------------------------------------
local power = new("Frame", {
	Name = "Power",
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(540, 150),
	AnchorPoint = Vector2.new(0.5, 1),
	Parent = root,
})
makeSlider("Power", power, UDim2.new(0.5, 0, 1, -18), UDim2.new(0.5, 0, 1, 200))

local powerBody = new("Frame", {
	BackgroundColor3 = C.Wood,
	Size = UDim2.new(0, 460, 0, 112),
	Position = UDim2.fromOffset(0, 36),
	Parent = power,
})
UIKit.corner(powerBody, 16)
UIKit.stroke(powerBody, 4)

local powerTag = new("Frame", {
	BackgroundColor3 = C.Green,
	Size = UDim2.fromOffset(150, 42),
	Position = UDim2.fromOffset(14, 14),
	Parent = power,
})
UIKit.corner(powerTag, 10)
UIKit.stroke(powerTag, 3)
UIKit.label({ Text = "⚡ POWER", Size = UDim2.new(1, -14, 1, -10), Position = UDim2.fromOffset(7, 5), Stroke = 3, Parent = powerTag })

local percent = UIKit.label({
	Text = "0%",
	TextXAlignment = Enum.TextXAlignment.Right,
	Size = UDim2.fromOffset(130, 38),
	Position = UDim2.new(0, 440, 0, 22),
	AnchorPoint = Vector2.new(1, 0),
	Stroke = 3,
	Parent = power,
})

local barBack = new("Frame", {
	BackgroundColor3 = Color3.fromRGB(30, 22, 18),
	Size = UDim2.fromOffset(424, 38),
	Position = UDim2.fromOffset(18, 64),
	Parent = power,
})
UIKit.corner(barBack, 12)
UIKit.stroke(barBack, 3)
local barClip = new("Frame", {
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	Size = UDim2.new(0, 0, 1, -8),
	Position = UDim2.fromOffset(4, 4),
	Parent = barBack,
})
local barFill = new("Frame", {
	BackgroundColor3 = C.White,
	Size = UDim2.fromOffset(416, 30),
	Parent = barClip,
})
UIKit.corner(barFill, 9)
UIKit.gradient(barFill, {
	Color3.fromRGB(40, 140, 255),
	Color3.fromRGB(150, 70, 255),
	Color3.fromRGB(255, 60, 200),
	Color3.fromRGB(255, 70, 70),
	Color3.fromRGB(255, 170, 40),
	Color3.fromRGB(255, 240, 60),
	Color3.fromRGB(90, 230, 70),
}, 0)
for i = 1, 19 do
	new("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 2, 1, -8),
		Position = UDim2.new(i / 20, 0, 0, 4),
		Parent = barBack,
	})
end

local powerHint = UIKit.label({
	Text = "HOLD CLICK OR SPACE TO CHARGE",
	TextColor3 = Color3.fromRGB(255, 214, 80),
	Size = UDim2.fromOffset(424, 18),
	Position = UDim2.fromOffset(18, 112),
	Stroke = 2,
	Parent = power,
})

UIKit.closeButton(power, UDim2.fromOffset(500, 92), 5, function()
	Hud.Callbacks.CancelCharge()
end)

local maxPower = UIKit.label({
	Text = "MAX POWER!",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -176),
	Size = UDim2.fromOffset(380, 70),
	Visible = false,
	Stroke = 4,
	Parent = root,
})
UIKit.gradient(maxPower, { Color3.fromRGB(110, 255, 80), Color3.fromRGB(60, 220, 255), Color3.fromRGB(110, 120, 255) }, 0)

local wasMax = false
function Hud.setPower(p: number, charging: boolean)
	barClip.Size = UDim2.new(p, -8 * p, 1, -8)
	percent.Text = math.floor(p * 100 + 0.5) .. "%"
	powerHint.Text = if charging then "RELEASE TO LAUNCH!" else "HOLD CLICK OR SPACE TO CHARGE"
	local isMax = p >= 0.97
	if isMax and not wasMax then
		maxPower.Visible = true
		UIKit.pop(maxPower, 1.5)
		Effects.play("MaxPower", 1.6, 0.6)
	elseif not isMax and wasMax then
		maxPower.Visible = false
	end
	wasMax = isMax
end

----------------------------------------------------------------------
-- Hint pill (bottom centre during a run)
----------------------------------------------------------------------
local hint = pill(260, 40)
hint.AnchorPoint = Vector2.new(0.5, 1)
makeSlider("Hint", hint, UDim2.new(0.5, 0, 1, -22), UDim2.new(0.5, 0, 1, 80))
local hintLabel = UIKit.label({
	Text = if RunService:IsStudio() or not game:GetService("UserInputService").TouchEnabled
		then "A / D TO STEER"
		else "TOUCH LEFT / RIGHT TO STEER",
	Size = UDim2.new(1, -20, 0, 22),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Stroke = 2,
	Parent = hint,
})
Hud.HintLabel = hintLabel

----------------------------------------------------------------------
-- Toasts
----------------------------------------------------------------------
local toastHolder = new("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(500, 200),
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 100),
	ZIndex = 50,
	Parent = root,
})
new("UIListLayout", {
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = toastHolder,
})

function Hud.toast(text: string, color: Color3?)
	local box = new("Frame", {
		BackgroundColor3 = color or C.Red,
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = toastHolder,
	})
	UIKit.corner(box, 10)
	UIKit.stroke(box, 3)
	new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), Parent = box })
	local label = UIKit.label({
		Text = text,
		TextScaled = false,
		TextSize = 22,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Stroke = 2.5,
		Parent = box,
	})
	UIKit.pop(box, 0.6)
	task.delay(1.8, function()
		UIKit.tween(box, 0.25, { BackgroundTransparency = 1 })
		UIKit.tween(label, 0.25, { TextTransparency = 1 })
		for _, d in box:GetChildren() do
			if d:IsA("UIStroke") then
				UIKit.tween(d, 0.25, { Transparency = 1 })
			end
		end
		local s = label:FindFirstChildOfClass("UIStroke")
		if s then
			UIKit.tween(s, 0.25, { Transparency = 1 })
		end
	end)
	Debris:AddItem(box, 2.2)
end

----------------------------------------------------------------------
-- Active boosts / storms (right side, with countdowns)
----------------------------------------------------------------------
local boostList = new("Frame", {
	Name = "Boosts",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -16, 0.5, 20),
	Size = UDim2.fromOffset(250, 320),
	Parent = root,
})
new("UIListLayout", {
	Padding = UDim.new(0, 8),
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = boostList,
})

type BoostEntry = { Key: string, Icon: string, Text: string, Color: Color3, EndsAt: number? }
local boostRows: { [string]: { Frame: Frame, Label: TextLabel, Entry: BoostEntry } } = {}

local function formatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 3600 then
		return string.format("%d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- entries: list of { Key, Icon, Text, Color, EndsAt? (server time) }
function Hud.setBoosts(entries: { BoostEntry })
	local keep = {}
	for i, e in entries do
		keep[e.Key] = true
		local row = boostRows[e.Key]
		if not row then
			local f = new("Frame", {
				BackgroundColor3 = e.Color,
				Size = UDim2.fromOffset(0, 42),
				AutomaticSize = Enum.AutomaticSize.X,
				Parent = boostList,
			})
			UIKit.corner(f, 12)
			UIKit.stroke(f, 3)
			UIKit.gradient(f, { Color3.new(1, 1, 1), Color3.new(0.75, 0.75, 0.75) }, 90)
			new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12), Parent = f })
			new("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 6),
				Parent = f,
			})
			UIKit.label({ Text = e.Icon, Size = UDim2.fromOffset(30, 30), Stroke = 0, LayoutOrder = 1, Parent = f })
			local label = UIKit.label({
				Text = e.Text,
				TextScaled = false,
				TextSize = 19,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromOffset(0, 30),
				Stroke = 2.5,
				LayoutOrder = 2,
				Parent = f,
			})
			row = { Frame = f, Label = label, Entry = e }
			boostRows[e.Key] = row
			UIKit.pop(f, 0.4)
		end
		row.Entry = e
		row.Frame.LayoutOrder = i
		row.Frame.BackgroundColor3 = e.Color
	end
	for key, row in boostRows do
		if not keep[key] then
			row.Frame:Destroy()
			boostRows[key] = nil
		end
	end
end

RunService.RenderStepped:Connect(function()
	local t = Workspace:GetServerTimeNow()
	for _, row in boostRows do
		local e = row.Entry
		row.Label.Text = if e.EndsAt then e.Text .. "  " .. formatTime(e.EndsAt - t) else e.Text
	end
end)

----------------------------------------------------------------------
-- Announcement banner (admin announcements, storms, purchases)
----------------------------------------------------------------------
local banner = new("Frame", {
	Name = "Announcement",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, -200),
	Size = UDim2.fromOffset(620, 118),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 40,
	Parent = root,
})
local bannerBody = new("Frame", {
	BackgroundColor3 = C.Wood,
	Size = UDim2.new(1, 0, 1, -24),
	Position = UDim2.fromOffset(0, 24),
	Parent = banner,
})
UIKit.corner(bannerBody, 16)
UIKit.stroke(bannerBody, 4)
local bannerHead = new("Frame", {
	BackgroundColor3 = C.Yellow,
	Size = UDim2.fromOffset(300, 44),
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 0),
	Parent = banner,
})
UIKit.corner(bannerHead, 12)
UIKit.stroke(bannerHead, 3.5)
local bannerTitle = UIKit.label({ Text = "📢 ANNOUNCEMENT", Size = UDim2.new(1, -20, 1, -12), Position = UDim2.fromOffset(10, 6), Stroke = 3, Parent = bannerHead })
local bannerText = UIKit.label({
	Text = "",
	TextWrapped = true,
	Size = UDim2.new(1, -40, 0, 54),
	Position = UDim2.fromOffset(20, 50),
	Stroke = 2.5,
	MaxTextSize = 30,
	Parent = banner,
})
local bannerToken = 0

function Hud.announce(title: string, text: string, color: Color3?)
	bannerToken += 1
	local token = bannerToken
	bannerTitle.Text = title
	bannerText.Text = text
	bannerHead.BackgroundColor3 = color or C.Yellow
	banner.Visible = true
	banner.Position = UDim2.new(0.5, 0, 0, -200)
	UIKit.tween(banner, 0.5, { Position = UDim2.new(0.5, 0, 0, 96) }, Enum.EasingStyle.Back)
	task.delay(6, function()
		if token ~= bannerToken then
			return
		end
		local t = UIKit.tween(banner, 0.35, { Position = UDim2.new(0.5, 0, 0, -200) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		t.Completed:Connect(function()
			if token == bannerToken then
				banner.Visible = false
			end
		end)
	end)
end

----------------------------------------------------------------------
-- Crazy event countdown: huge "☄️ METEOR SHOWER  5 4 3 2 1  NOW!" in the
-- middle of the screen
----------------------------------------------------------------------
local countdown = new("Frame", {
	Name = "CrazyCountdown",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.36),
	Size = UDim2.fromOffset(900, 300),
	Visible = false,
	ZIndex = 60,
	Parent = root,
})
local countdownScale = new("UIScale", { Parent = countdown })
local countdownTitle = UIKit.label({ Text = "", Size = UDim2.new(1, 0, 0, 90), Stroke = 6, ZIndex = 61, Parent = countdown })
local countdownSub = UIKit.label({ Text = "INCOMING IN", Size = UDim2.new(1, 0, 0, 36), Position = UDim2.fromOffset(0, 96), Stroke = 4, ZIndex = 61, Parent = countdown })
local countdownNumber = UIKit.label({ Text = "10", Size = UDim2.new(1, 0, 0, 150), Position = UDim2.fromOffset(0, 136), Stroke = 8, ZIndex = 61, Parent = countdown })
local countdownGradient = UIKit.gradient(countdownTitle, { Color3.new(1, 1, 1), Color3.new(1, 1, 1) }, 90)
local countdownToken = 0

function Hud.crazyCountdown(icon: string, name: string, color: Color3, endsAt: number)
	countdownToken += 1
	local token = countdownToken
	countdownTitle.Text = icon .. " " .. string.upper(name) .. " " .. icon
	countdownGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
	countdownNumber.TextColor3 = color
	countdownSub.Text = "INCOMING IN"
	countdown.Visible = true
	countdownScale.Scale = 0.2
	UIKit.tween(countdownScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
	task.spawn(function()
		local last = -1
		while token == countdownToken do
			local left = math.ceil(endsAt - Workspace:GetServerTimeNow())
			if left <= 0 then
				break
			end
			if left ~= last then
				last = left
				countdownNumber.Text = tostring(left)
				UIKit.pop(countdownNumber, 1.5)
				Effects.play("Countdown", if left <= 3 then 1.4 else 1, 0.8)
				if left <= 3 then
					Effects.shake(0.4)
				end
			end
			task.wait(0.05)
		end
		if token ~= countdownToken then
			return
		end
		countdownSub.Text = ""
		countdownNumber.Text = "NOW!"
		UIKit.pop(countdownNumber, 1.8)
		Effects.shake(1.6)
		task.wait(1.4)
		if token == countdownToken then
			local t = UIKit.tween(countdownScale, 0.3, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			t.Completed:Wait()
			if token == countdownToken then
				countdown.Visible = false
			end
		end
	end)
end

function Hud.cancelCountdown()
	countdownToken += 1
	countdown.Visible = false
end

----------------------------------------------------------------------
-- TURBO button (bottom right during a run, key T)
----------------------------------------------------------------------
local turboHolder = new("Frame", {
	Name = "Turbo",
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(150, 150),
	AnchorPoint = Vector2.new(1, 1),
	Parent = root,
})
makeSlider("Turbo", turboHolder, UDim2.new(1, -26, 1, -26), UDim2.new(1, 200, 1, -26))
local turboButton = UIKit.button({
	Size = UDim2.fromOffset(150, 150),
	Color = C.Red,
	DarkColor = C.RedDark,
	Text = "TURBO",
	Key = "T",
	Corner = 75,
	Parent = turboHolder,
	OnClick = function()
		Hud.Callbacks.Turbo()
	end,
})
turboButton.Label.Size = UDim2.new(1, -24, 0, 34)
turboButton.Label.Position = UDim2.new(0.5, 0, 0.62, 0)
turboButton.Label.AnchorPoint = Vector2.new(0.5, 0.5)
turboButton.Label.TextXAlignment = Enum.TextXAlignment.Center
UIKit.label({ Text = "🚀", Size = UDim2.fromOffset(56, 56), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.32, 0), Stroke = 0, Parent = turboButton.Face })
local turboCount = new("Frame", {
	BackgroundColor3 = C.Yellow,
	Size = UDim2.fromOffset(54, 34),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -18, 0, 18),
	ZIndex = 10,
	Parent = turboHolder,
})
UIKit.corner(turboCount, 10)
UIKit.stroke(turboCount, 3)
local turboCountLabel = UIKit.label({ Text = "x0", Size = UDim2.new(1, -8, 1, -6), Position = UDim2.fromOffset(4, 3), Stroke = 2.5, Parent = turboCount })

function Hud.setTurbos(n: number)
	turboCountLabel.Text = if n > 0 then "x" .. n else "+"
	if n > 0 then
		turboButton.SetColors(C.Red, C.RedDark)
		turboButton.SetText("TURBO")
	else
		turboButton.SetColors(C.Grey, C.GreyDark)
		turboButton.SetText("GET")
	end
end

function Hud.turboFired()
	UIKit.pop(turboHolder, 0.8)
end

----------------------------------------------------------------------
-- Modes
----------------------------------------------------------------------
Hud.Mode = "Idle"
function Hud.setMode(mode: string)
	Hud.Mode = mode
	local idle = mode == "Idle"
	slide("Wallet", idle or mode == "Charge" or mode == "Result")
	slide("Menu", idle)
	slide("Tabs", idle)
	slide("Power", mode == "Charge")
	slide("RunCoins", mode == "Rolling")
	slide("Distance", mode == "Rolling" or mode == "Result")
	slide("Speed", mode == "Rolling")
	slide("Hint", mode == "Rolling" and Effects.Settings.Hints)
	slide("Turbo", mode == "Rolling")
	boostList.Visible = mode ~= "Tree"
	if mode ~= "Charge" then
		maxPower.Visible = false
		wasMax = false
	end
	if mode ~= "Rolling" then
		comboTag.Visible = false
	end
end

----------------------------------------------------------------------
-- Per-frame smoothing of counters
----------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
	local a = 1 - math.exp(-dt * 9)
	if math.abs(targetCoins - shownCoins) > 0.5 then
		shownCoins += (targetCoins - shownCoins) * a
		if math.abs(targetCoins - shownCoins) < 1 then
			shownCoins = targetCoins
		end
	else
		shownCoins = targetCoins
	end
	coinsLabel.Text = Config.Commas(shownCoins)

	if math.abs(targetRunCoins - shownRunCoins) > 0.5 then
		shownRunCoins += (targetRunCoins - shownRunCoins) * math.min(1, a * 1.5)
	else
		shownRunCoins = targetRunCoins
	end
	runCoinsLabel.Text = Config.Commas(shownRunCoins)

	if comboTag.Visible and os.clock() > comboHideAt then
		comboTag.Visible = false
	end
end)

Hud.setMode("Idle")

return Hud
