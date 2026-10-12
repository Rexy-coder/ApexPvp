--!nonstrict
-- Snowball Smash: hexagon upgrade tree. Drag to pan, scroll / pinch to zoom,
-- click a hex to see its card and buy it.

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Hud = require(script.Parent:WaitForChild("Hud"))

local C = UIKit.Colors
local new = UIKit.new

local UpgradeTree = {}
UpgradeTree.IsOpen = false
UpgradeTree.OnBuy = function(_nodeId: string) end
UpgradeTree.OnClosed = function() end
-- defined further down
UpgradeTree.select = function(_id: string?) end
UpgradeTree.close = function() end

local SQ3 = math.sqrt(3)
local R = 48 -- hex radius in px
local LAYOUT = R + 9 -- spacing radius

local COLORS = {
	Outline = Color3.fromRGB(26, 16, 44),
	Owned = Color3.fromRGB(160, 100, 250),
	OwnedInner = Color3.fromRGB(128, 72, 226),
	Available = Color3.fromRGB(64, 152, 255),
	AvailableInner = Color3.fromRGB(42, 112, 232),
	Locked = Color3.fromRGB(72, 58, 104),
	LockedInner = Color3.fromRGB(56, 44, 84),
	Start = Color3.fromRGB(70, 214, 214),
	StartInner = Color3.fromRGB(40, 170, 186),
	Glow = Color3.fromRGB(255, 214, 60),
}

----------------------------------------------------------------------
-- Hexagon from three rotated rectangles
----------------------------------------------------------------------
local function hex(parent: Instance, radius: number, color: Color3): (Frame, { Frame })
	local holder = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(radius * 2, radius * 2),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	local rects = {}
	for i = 0, 2 do
		rects[i + 1] = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(radius, radius * SQ3),
			Rotation = i * 60,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = holder,
		})
	end
	return holder, rects
end

local function paint(rects: { Frame }, color: Color3, transparency: number?)
	for _, r in rects do
		r.BackgroundColor3 = color
		if transparency then
			r.BackgroundTransparency = transparency
		end
	end
end

local function axialToPixel(q: number, r: number): Vector2
	return Vector2.new(LAYOUT * 1.5 * q, LAYOUT * SQ3 * (r + q / 2))
end

----------------------------------------------------------------------
-- Build
----------------------------------------------------------------------
type NodeView = {
	Id: string,
	Holder: Frame,
	Scale: UIScale,
	Glow: { Frame },
	Main: { Frame },
	Inner: { Frame },
	Icon: TextLabel,
	State: string,
}

local overlay = new("Frame", {
	Name = "UpgradeTree",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Visible = false,
	ZIndex = 30,
	Parent = Hud.Root,
})
local dim = new("Frame", {
	BackgroundColor3 = Color3.fromRGB(14, 10, 30),
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 1,
	Parent = overlay,
})
local capture = new("TextButton", {
	Name = "Capture",
	BackgroundTransparency = 1,
	Text = "",
	AutoButtonColor = false,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 2,
	Parent = overlay,
})
local canvas = new("Frame", {
	Name = "Canvas",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(0, 0),
	ZIndex = 3,
	Parent = overlay,
})
local zoomScale = new("UIScale", { Parent = canvas })

local views: { [string]: NodeView } = {}
local selected: string? = nil
local data: any = nil

local function makeNode(id: string, q: number, r: number, icon: string, title: string, tier: number?): NodeView
	local pos = axialToPixel(q, r)
	local holder = new("Frame", {
		Name = id,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(pos.X, pos.Y),
		Size = UDim2.fromOffset(R * 2 + 16, R * 2 + 16),
		BackgroundTransparency = 1,
		Parent = canvas,
	})
	local scale = new("UIScale", { Parent = holder })
	local _, glow = hex(holder, R + 7, COLORS.Glow)
	local _, outline = hex(holder, R + 3, COLORS.Outline)
	local _, main = hex(holder, R - 1, COLORS.Locked)
	local _, inner = hex(holder, R - 9, COLORS.LockedInner)
	local _ = outline

	local iconLabel = UIKit.label({
		Text = icon,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.54),
		Size = UDim2.fromOffset(R * 1.05, R * 1.05),
		Stroke = 0,
		Parent = holder,
	})
	UIKit.label({
		Text = title,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, -R * 0.66),
		Size = UDim2.fromOffset(R * 1.35, 13),
		Stroke = 1.5,
		Parent = holder,
	})
	if tier then
		UIKit.label({
			Text = tostring(tier),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, R * 0.5, 0.5, R * 0.48),
			Size = UDim2.fromOffset(22, 22),
			Stroke = 2.5,
			Parent = holder,
		})
	end

	local hit = new("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(R * 1.7, R * 1.7),
		Parent = holder,
	})

	local view: NodeView = {
		Id = id,
		Holder = holder,
		Scale = scale,
		Glow = glow,
		Main = main,
		Inner = inner,
		Icon = iconLabel,
		State = "Locked",
	}

	hit.MouseEnter:Connect(function()
		UIKit.tween(scale, 0.2, { Scale = 1.1 }, Enum.EasingStyle.Back)
	end)
	hit.MouseLeave:Connect(function()
		UIKit.tween(scale, 0.2, { Scale = 1 })
	end)
	hit.Activated:Connect(function()
		UIKit.PlaySound("Click", 1.3)
		UIKit.pop(holder, 0.85)
		if id ~= "Start" then
			UpgradeTree.select(id)
		end
	end)

	views[id] = view
	return view
end

local startView = makeNode("Start", 0, 0, "⛄", "Start", nil)
paint(startView.Main, COLORS.Start)
paint(startView.Inner, COLORS.StartInner)
paint(startView.Glow, COLORS.Glow, 1)

for _, node in Config.NodeList do
	makeNode(node.Id, node.Q, node.R, node.Branch.Icon, node.Title, node.Tier)
end

----------------------------------------------------------------------
-- Side coin box, close + recenter buttons, hint
----------------------------------------------------------------------
local coinBox = new("Frame", {
	BackgroundColor3 = C.Slate,
	BackgroundTransparency = 0.25,
	Size = UDim2.fromOffset(190, 60),
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 20, 0.5, 0),
	ZIndex = 4,
	Parent = overlay,
})
UIKit.corner(coinBox, 12)
UIKit.stroke(coinBox, 3)
UIKit.coin(coinBox, 42, UDim2.new(0, 10, 0.5, 0), Vector2.new(0, 0.5))
local coinBoxLabel = UIKit.label({
	Text = "0",
	TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.new(1, -72, 0, 32),
	Position = UDim2.new(0, 62, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	Stroke = 3,
	Parent = coinBox,
})

UIKit.label({
	Text = if UserInputService.TouchEnabled then "DRAG TO MOVE  ·  PINCH TO ZOOM" else "DRAG TO MOVE  ·  SCROLL TO ZOOM",
	TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.fromOffset(330, 16),
	Position = UDim2.new(0, 20, 1, -28),
	Stroke = 2,
	ZIndex = 4,
	Parent = overlay,
})

local closeButton = UIKit.button({
	Size = UDim2.fromOffset(190, 62),
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -16),
	Color = C.Red,
	DarkColor = C.RedDark,
	Text = "Close",
	Studs = true,
	ZIndex = 5,
	Parent = overlay,
	OnClick = function()
		UpgradeTree.close()
	end,
})
closeButton.Label.TextXAlignment = Enum.TextXAlignment.Center

local panTarget = Vector2.zero
local pan = Vector2.zero
local zoomTarget = 1
local zoom = 1

local recenter = UIKit.button({
	Size = UDim2.fromOffset(62, 62),
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0.5, 108, 1, -16),
	Color = C.Slate,
	DarkColor = Color3.fromRGB(18, 22, 32),
	Text = "🔍",
	ZIndex = 5,
	Parent = overlay,
	OnClick = function()
		panTarget = Vector2.zero
		zoomTarget = 1
	end,
})
recenter.Label.Size = UDim2.new(1, -14, 0.7, 0)

----------------------------------------------------------------------
-- Tooltip card
----------------------------------------------------------------------
local tip = new("Frame", {
	Name = "Tooltip",
	BackgroundColor3 = C.Wood,
	Size = UDim2.fromOffset(300, 196),
	AnchorPoint = Vector2.new(0, 0.5),
	Visible = false,
	ZIndex = 40,
	Parent = overlay,
})
UIKit.corner(tip, 12)
UIKit.stroke(tip, 3.5)
local tipScale = new("UIScale", { Parent = tip })
local tipHeader = new("Frame", {
	BackgroundColor3 = C.Purple,
	Size = UDim2.new(1, 8, 0, 34),
	Position = UDim2.fromOffset(-4, -6),
	Parent = tip,
})
UIKit.corner(tipHeader, 10)
UIKit.stroke(tipHeader, 3)
UIKit.gradient(tipHeader, { Color3.fromRGB(190, 140, 255), C.Purple }, 90)
local tipTitle = UIKit.label({ Text = "", Size = UDim2.new(1, -20, 0, 22), Position = UDim2.fromOffset(10, 6), Stroke = 2.5, Parent = tipHeader })

local tipIconBox = new("Frame", {
	BackgroundColor3 = C.Purple,
	Size = UDim2.fromOffset(62, 62),
	Position = UDim2.fromOffset(12, 40),
	Parent = tip,
})
UIKit.corner(tipIconBox, 12)
UIKit.stroke(tipIconBox, 3)
local tipIcon = UIKit.label({ Text = "", Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), Stroke = 0, Parent = tipIconBox })
local tipDesc = UIKit.label({
	Text = "",
	TextScaled = false,
	TextSize = 16,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Size = UDim2.fromOffset(204, 62),
	Position = UDim2.fromOffset(84, 42),
	Stroke = 1.5,
	Parent = tip,
})
local tipStat = UIKit.label({
	Text = "",
	RichText = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.fromOffset(276, 20),
	Position = UDim2.fromOffset(12, 108),
	Stroke = 2,
	Parent = tip,
})
local tipStatus = UIKit.label({
	Text = "",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(255, 90, 90),
	Size = UDim2.fromOffset(276, 16),
	Position = UDim2.fromOffset(12, 130),
	Stroke = 2,
	Parent = tip,
})
local buyButton = UIKit.button({
	Size = UDim2.fromOffset(276, 44),
	Position = UDim2.fromOffset(12, 148),
	Color = C.Grey,
	DarkColor = C.GreyDark,
	Text = "0",
	Parent = tip,
	OnClick = function()
		if selected then
			UpgradeTree.OnBuy(selected)
		end
	end,
})
buyButton.Label.TextXAlignment = Enum.TextXAlignment.Center
UIKit.coin(buyButton.Face, 28, UDim2.new(0, 12, 0.5, 0), Vector2.new(0, 0.5))

local function nodeState(id: string): string
	if not data then
		return "Locked"
	end
	if data.Owned[id] then
		return "Owned"
	end
	local node = Config.Nodes[id]
	if node.Requires == "Start" or data.Owned[node.Requires] then
		return if data.Coins >= node.Cost then "Affordable" else "Available"
	end
	return "Locked"
end

local function refreshTooltip()
	local id = selected
	if not id or not data then
		return
	end
	local node = Config.Nodes[id]
	local branch = node.Branch
	local state = nodeState(id)
	local level = Config.BranchLevel(data.Owned, branch.Id)

	tipTitle.Text = node.Title
	tipIcon.Text = branch.Icon
	tipDesc.Text = branch.Desc
	local before = Config.StatText(branch, node.Tier - 1)
	local after = Config.StatText(branch, node.Tier)
	tipStat.Text = string.format('%s: %s → <font color="#7CFF5A">%s</font>', branch.Stat, before, after)
	tipIconBox.BackgroundColor3 = if state == "Owned" then COLORS.Owned elseif state == "Locked" then COLORS.Locked else COLORS.Available

	buyButton.SetText(Config.Commas(node.Cost))
	if state == "Owned" then
		tipStatus.Text = "✔ OWNED"
		tipStatus.TextColor3 = Color3.fromRGB(130, 255, 110)
		buyButton.SetColors(C.Purple, C.PurpleDark)
		buyButton.SetText("Owned")
	elseif state == "Locked" then
		tipStatus.Text = "Requires " .. Config.Nodes[node.Requires].Title
		tipStatus.TextColor3 = Color3.fromRGB(255, 120, 120)
		buyButton.SetColors(C.Grey, C.GreyDark)
	elseif state == "Available" then
		tipStatus.Text = "Need " .. Config.Commas(node.Cost - data.Coins) .. " more coins"
		tipStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
		buyButton.SetColors(C.Grey, C.GreyDark)
	else
		tipStatus.Text = if level >= node.Tier - 1 then "Ready to buy!" else ""
		tipStatus.TextColor3 = Color3.fromRGB(130, 255, 110)
		buyButton.SetColors(C.Green, C.GreenDark)
	end
end

local function placeTooltip()
	local id = selected
	if not id then
		return
	end
	local view = views[id]
	local s = Hud.UIScale
	local abs = view.Holder.AbsolutePosition + view.Holder.AbsoluteSize / 2
	local p = abs / s
	local screen = Hud.Root.AbsoluteSize / s
	local offset = R * zoom + 18
	if p.X + offset + 300 > screen.X - 10 then
		tip.AnchorPoint = Vector2.new(1, 0.5)
		tip.Position = UDim2.fromOffset(p.X - offset, math.clamp(p.Y, 110, screen.Y - 110))
	else
		tip.AnchorPoint = Vector2.new(0, 0.5)
		tip.Position = UDim2.fromOffset(p.X + offset, math.clamp(p.Y, 110, screen.Y - 110))
	end
end

UpgradeTree.select = function(id: string?)
	selected = id
	if id then
		refreshTooltip()
		placeTooltip()
		tip.Visible = true
		tipScale.Scale = 0.6
		UIKit.tween(tipScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	else
		tip.Visible = false
	end
end

----------------------------------------------------------------------
-- Refresh node colours from player data
----------------------------------------------------------------------
function UpgradeTree.refresh(newData: any)
	data = newData
	if not data then
		return
	end
	coinBoxLabel.Text = Config.Short(data.Coins)
	for id, view in views do
		if id ~= "Start" then
			local state = nodeState(id)
			view.State = state
			if state == "Owned" then
				paint(view.Main, COLORS.Owned)
				paint(view.Inner, COLORS.OwnedInner)
				view.Icon.TextTransparency = 0
			elseif state == "Available" or state == "Affordable" then
				paint(view.Main, COLORS.Available)
				paint(view.Inner, COLORS.AvailableInner)
				view.Icon.TextTransparency = 0
			else
				paint(view.Main, COLORS.Locked)
				paint(view.Inner, COLORS.LockedInner)
				view.Icon.TextTransparency = 0.45
			end
		end
	end
	refreshTooltip()
end

-- Is there anything the player can buy right now? (drives the "!" badge)
function UpgradeTree.anyAffordable(d: any): boolean
	if not d then
		return false
	end
	for _, node in Config.NodeList do
		if not d.Owned[node.Id] and (node.Requires == "Start" or d.Owned[node.Requires]) and d.Coins >= node.Cost then
			return true
		end
	end
	return false
end

-- Celebrate a purchase: bounce the hex and throw out some sparkles
function UpgradeTree.celebrate(id: string)
	local view = views[id]
	if not view then
		return
	end
	UIKit.pop(view.Holder, 1.45)
	for i = 1, 12 do
		local a = (i / 12) * math.pi * 2
		local spark = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = view.Holder.Position,
			Size = UDim2.fromOffset(12, 12),
			BackgroundColor3 = if i % 2 == 0 then COLORS.Glow else C.White,
			Rotation = 45,
			Parent = canvas,
		})
		UIKit.stroke(spark, 2)
		local dist = 90 + math.random() * 40
		UIKit.tween(spark, 0.6, {
			Position = view.Holder.Position + UDim2.fromOffset(math.cos(a) * dist, math.sin(a) * dist),
			Size = UDim2.fromOffset(2, 2),
			Rotation = 225,
		}, Enum.EasingStyle.Quint)
		Debris:AddItem(spark, 0.65)
	end
end

----------------------------------------------------------------------
-- Pan / zoom input
----------------------------------------------------------------------
local dragging = false
local dragStart = Vector2.zero
local panStart = Vector2.zero
local moved = false

capture.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		moved = false
		dragStart = Vector2.new(input.Position.X, input.Position.Y)
		panStart = panTarget
	end
end)

capture.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		zoomTarget = math.clamp(zoomTarget * (1.15 ^ input.Position.Z), 0.45, 1.7)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local delta = (Vector2.new(input.Position.X, input.Position.Y) - dragStart) / Hud.UIScale
		if delta.Magnitude > 6 then
			moved = true
		end
		panTarget = panStart + delta
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if dragging and not moved then
			UpgradeTree.select(nil)
		end
		dragging = false
	end
end)

UserInputService.TouchPinch:Connect(function(_positions, scale, _velocity, state)
	if not UpgradeTree.IsOpen then
		return
	end
	if state == Enum.UserInputState.Change then
		zoomTarget = math.clamp(zoomTarget * (1 + (scale - 1) * 0.08), 0.45, 1.7)
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if not UpgradeTree.IsOpen then
		return
	end
	local a = 1 - math.exp(-dt * 12)
	pan = pan:Lerp(panTarget, a)
	zoom += (zoomTarget - zoom) * a
	canvas.Position = UDim2.new(0.5, pan.X, 0.5, pan.Y)
	zoomScale.Scale = zoom

	-- pulse the glow on hexes you can afford
	local pulse = 0.25 + 0.35 * (0.5 + 0.5 * math.sin(os.clock() * 5))
	for id, view in views do
		if id ~= "Start" then
			paint(view.Glow, COLORS.Glow, if view.State == "Affordable" then pulse else 1)
		end
	end
	if tip.Visible then
		placeTooltip()
	end
end)

----------------------------------------------------------------------
-- Open / close
----------------------------------------------------------------------
function UpgradeTree.open()
	if UpgradeTree.IsOpen then
		return
	end
	UpgradeTree.IsOpen = true
	overlay.Visible = true
	UpgradeTree.select(nil)
	UIKit.setBlur(true)
	UIKit.tween(dim, 0.3, { BackgroundTransparency = 0.45 })
	zoom = 0.4
	zoomScale.Scale = zoom
	zoomTarget = 1
	pan = Vector2.new(0, 40)
	panTarget = Vector2.zero
	canvas.Position = UDim2.new(0.5, pan.X, 0.5, pan.Y)
	-- stagger the hexes popping in, from the centre outwards
	for id, view in views do
		local node = Config.Nodes[id]
		local ring = if node then math.max(math.abs(node.Q), math.abs(node.R), math.abs(node.Q + node.R)) else 0
		view.Scale.Scale = 0
		task.delay(ring * 0.04, function()
			UIKit.tween(view.Scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
		end)
	end
	UIKit.PlaySound("Click", 0.9)
end

UpgradeTree.close = function()
	if not UpgradeTree.IsOpen then
		return
	end
	UpgradeTree.IsOpen = false
	UpgradeTree.select(nil)
	UIKit.setBlur(false)
	UIKit.tween(dim, 0.25, { BackgroundTransparency = 1 })
	local t = UIKit.tween(zoomScale, 0.25, { Scale = 0.3 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	t.Completed:Connect(function()
		if not UpgradeTree.IsOpen then
			overlay.Visible = false
		end
	end)
	UpgradeTree.OnClosed()
end

return UpgradeTree
