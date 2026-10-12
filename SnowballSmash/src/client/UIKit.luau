--!nonstrict
-- Snowball Smash: small UI toolkit. Chunky cartoon buttons, wooden panels
-- with stud-pattern headers, and smooth tween helpers.

local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local UIKit = {}

UIKit.Font = Enum.Font.FredokaOne

UIKit.Colors = {
	White = Color3.fromRGB(255, 255, 255),
	Black = Color3.fromRGB(0, 0, 0),
	Outline = Color3.fromRGB(28, 18, 12),
	Wood = Color3.fromRGB(98, 60, 38),
	WoodDark = Color3.fromRGB(70, 42, 26),
	WoodLight = Color3.fromRGB(128, 82, 52),
	Yellow = Color3.fromRGB(255, 200, 40),
	YellowDark = Color3.fromRGB(214, 140, 12),
	Green = Color3.fromRGB(88, 220, 64),
	GreenDark = Color3.fromRGB(40, 150, 32),
	Blue = Color3.fromRGB(60, 150, 255),
	BlueDark = Color3.fromRGB(28, 88, 205),
	Red = Color3.fromRGB(240, 64, 64),
	RedDark = Color3.fromRGB(160, 26, 32),
	Purple = Color3.fromRGB(156, 96, 245),
	PurpleDark = Color3.fromRGB(92, 48, 172),
	Pink = Color3.fromRGB(255, 92, 196),
	Grey = Color3.fromRGB(120, 120, 130),
	GreyDark = Color3.fromRGB(70, 70, 80),
	Slate = Color3.fromRGB(34, 40, 56),
	Gold = Color3.fromRGB(255, 214, 60),
}
local C = UIKit.Colors

----------------------------------------------------------------------
-- Instance helpers
----------------------------------------------------------------------
function UIKit.new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className) :: any
	local parent = nil
	if props then
		for key, value in props do
			if key == "Parent" then
				parent = value
			else
				inst[key] = value
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end
local new = UIKit.new

function UIKit.corner(parent: Instance, radius: number?): UICorner
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 12), Parent = parent })
end

function UIKit.round(parent: Instance): UICorner
	return new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = parent })
end

function UIKit.stroke(parent: Instance, thickness: number?, color: Color3?, transparency: number?): UIStroke
	return new("UIStroke", {
		Thickness = thickness or 3,
		Color = color or C.Outline,
		Transparency = transparency or 0,
		ApplyStrokeMode = if parent:IsA("TextLabel") or parent:IsA("TextButton")
			then Enum.ApplyStrokeMode.Border
			else Enum.ApplyStrokeMode.Contextual,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = parent,
	})
end

function UIKit.gradient(parent: Instance, colors: { Color3 }, rotation: number?): UIGradient
	local keypoints = {}
	for i, color in colors do
		table.insert(keypoints, ColorSequenceKeypoint.new((i - 1) / math.max(1, #colors - 1), color))
	end
	return new("UIGradient", { Color = ColorSequence.new(keypoints), Rotation = rotation or 90, Parent = parent })
end

-- Cartoon text: white fill, thick dark outline, scales with its box.
function UIKit.label(props: { [string]: any }): TextLabel
	local strokeThickness = props.Stroke
	local maxSize = props.MaxTextSize
	props.Stroke = nil
	props.MaxTextSize = nil
	local base = {
		BackgroundTransparency = 1,
		Font = UIKit.Font,
		TextColor3 = C.White,
		TextScaled = true,
		Text = "",
	}
	for k, v in props do
		base[k] = v
	end
	local label = new("TextLabel", base)
	if strokeThickness ~= 0 then
		new("UIStroke", {
			Thickness = strokeThickness or 2.5,
			Color = C.Outline,
			LineJoinMode = Enum.LineJoinMode.Round,
			Parent = label,
		})
	end
	if maxSize then
		new("UITextSizeConstraint", { MaxTextSize = maxSize, Parent = label })
	end
	return label
end

-- Lego-like stud pattern overlay (purely decorative)
function UIKit.studs(parent: GuiObject, width: number, height: number, cell: number?, transparency: number?)
	local size = cell or 16
	local holder = new("Frame", {
		Name = "Studs",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
		ZIndex = parent.ZIndex,
		Parent = parent,
	})
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(size, size),
		CellPadding = UDim2.fromOffset(0, 0),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = holder,
	})
	local cols = math.ceil(width / size)
	local rows = math.ceil(height / size)
	for _ = 1, math.min(cols * rows, 260) do
		local cellFrame = new("Frame", { BackgroundTransparency = 1, ZIndex = parent.ZIndex, Parent = holder })
		local dot = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = C.White,
			BackgroundTransparency = transparency or 0.82,
			ZIndex = parent.ZIndex,
			Parent = cellFrame,
		})
		UIKit.corner(dot, 3)
	end
	return holder
end

----------------------------------------------------------------------
-- Tweens
----------------------------------------------------------------------
function UIKit.tween(inst: Instance, time: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
	local tween = TweenService:Create(
		inst,
		TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
	tween:Play()
	return tween
end

-- Quick "pop" bounce on any GuiObject that has (or gets) a UIScale
function UIKit.pop(gui: GuiObject, amount: number?)
	local scale = gui:FindFirstChildOfClass("UIScale") or new("UIScale", { Parent = gui })
	scale.Scale = amount or 1.25
	UIKit.tween(scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
end

----------------------------------------------------------------------
-- Sound hook (set by Effects so UI clicks can play sounds)
----------------------------------------------------------------------
UIKit.PlaySound = function(_name: string, _pitch: number?) end

----------------------------------------------------------------------
-- Chunky 3D button: dark base, coloured face that sinks when pressed.
----------------------------------------------------------------------
export type ButtonOptions = {
	Size: UDim2,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Color: Color3?,
	DarkColor: Color3?,
	Text: string?,
	Icon: string?,
	TextSize: number?,
	Key: string?,
	Studs: boolean?,
	Parent: Instance?,
	ZIndex: number?,
	Corner: number?,
	OnClick: (() -> ())?,
}

export type Button = {
	Holder: Frame,
	Face: Frame,
	Label: TextLabel,
	IconLabel: TextLabel?,
	Hitbox: TextButton,
	SetColors: (Color3, Color3) -> (),
	SetText: (string) -> (),
	Clicked: (() -> ())?,
}

function UIKit.button(opts: ButtonOptions): Button
	local color = opts.Color or C.Green
	local dark = opts.DarkColor or C.GreenDark
	local z = opts.ZIndex or 1
	local radius = opts.Corner or 14

	local holder = new("Frame", {
		Name = "Button",
		BackgroundTransparency = 1,
		Size = opts.Size,
		Position = opts.Position or UDim2.new(),
		AnchorPoint = opts.AnchorPoint or Vector2.zero,
		ZIndex = z,
		Parent = opts.Parent,
	})
	local scale = new("UIScale", { Parent = holder })

	local base = new("Frame", {
		Name = "Base",
		BackgroundColor3 = dark,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = z,
		Parent = holder,
	})
	UIKit.corner(base, radius)
	UIKit.stroke(base, 3)

	local face = new("Frame", {
		Name = "Face",
		BackgroundColor3 = color,
		Size = UDim2.new(1, 0, 1, -6),
		Position = UDim2.fromOffset(0, 0),
		ZIndex = z + 1,
		ClipsDescendants = false,
		Parent = holder,
	})
	UIKit.corner(face, radius)
	-- soft top highlight
	local shine = new("Frame", {
		Name = "Shine",
		BackgroundColor3 = C.White,
		BackgroundTransparency = 0.78,
		Size = UDim2.new(1, -12, 0.42, 0),
		Position = UDim2.fromOffset(6, 4),
		ZIndex = z + 1,
		Parent = face,
	})
	UIKit.corner(shine, radius - 4)

	local pxW = opts.Size.X.Offset
	local pxH = opts.Size.Y.Offset
	if opts.Studs and pxW > 0 and pxH > 0 then
		local studs = UIKit.studs(face, pxW, pxH, 14, 0.85)
		studs.ZIndex = z + 1
		UIKit.corner(studs, radius)
	end

	local textLeft = 0
	local iconLabel: TextLabel? = nil
	if opts.Icon then
		iconLabel = UIKit.label({
			Name = "Icon",
			Text = opts.Icon,
			Size = UDim2.new(0, pxH * 0.78, 0.86, 0),
			Position = UDim2.new(0, 10, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			ZIndex = z + 2,
			Stroke = 0,
			Parent = face,
		})
		textLeft = pxH * 0.78 + 8
	end

	local label = UIKit.label({
		Name = "Label",
		Text = opts.Text or "",
		Size = UDim2.new(1, -(textLeft + 16), 0.62, 0),
		Position = UDim2.new(0, textLeft + 8, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ZIndex = z + 2,
		Stroke = 3,
		MaxTextSize = opts.TextSize,
		Parent = face,
	})

	if opts.Key then
		UIKit.label({
			Name = "Key",
			Text = opts.Key,
			Size = UDim2.fromOffset(14, 14),
			Position = UDim2.new(1, -4, 1, -2),
			AnchorPoint = Vector2.new(1, 1),
			ZIndex = z + 2,
			Stroke = 1.5,
			TextColor3 = C.White,
			Parent = face,
		})
	end

	local hitbox = new("TextButton", {
		Name = "Hitbox",
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = z + 3,
		AutoButtonColor = false,
		Parent = holder,
	})

	local button: Button = {
		Holder = holder,
		Face = face,
		Label = label,
		IconLabel = iconLabel,
		Hitbox = hitbox,
		SetColors = function(_c: Color3, _d: Color3) end,
		SetText = function(_t: string) end,
		Clicked = opts.OnClick,
	}

	button.SetColors = function(c: Color3, d: Color3)
		face.BackgroundColor3 = c
		base.BackgroundColor3 = d
	end
	button.SetText = function(t: string)
		label.Text = t
	end

	local hovering = false
	hitbox.MouseEnter:Connect(function()
		hovering = true
		UIKit.tween(scale, 0.18, { Scale = 1.06 }, Enum.EasingStyle.Back)
	end)
	hitbox.MouseLeave:Connect(function()
		hovering = false
		UIKit.tween(scale, 0.18, { Scale = 1 })
		UIKit.tween(face, 0.1, { Position = UDim2.fromOffset(0, 0) })
	end)
	hitbox.MouseButton1Down:Connect(function()
		UIKit.tween(scale, 0.08, { Scale = 0.95 })
		UIKit.tween(face, 0.08, { Position = UDim2.fromOffset(0, 4) })
	end)
	hitbox.MouseButton1Up:Connect(function()
		UIKit.tween(scale, 0.25, { Scale = if hovering then 1.06 else 1 }, Enum.EasingStyle.Back)
		UIKit.tween(face, 0.12, { Position = UDim2.fromOffset(0, 0) })
	end)
	hitbox.Activated:Connect(function()
		UIKit.PlaySound("Click", 1.2)
		if button.Clicked then
			button.Clicked()
		end
	end)

	return button
end

----------------------------------------------------------------------
-- Red square close button (X)
----------------------------------------------------------------------
function UIKit.closeButton(parent: Instance, position: UDim2, z: number?, onClick: () -> ()): Button
	local b = UIKit.button({
		Size = UDim2.fromOffset(58, 58),
		Position = position,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = C.Red,
		DarkColor = C.RedDark,
		Text = "✕",
		Parent = parent,
		ZIndex = z,
		Corner = 12,
		OnClick = onClick,
	})
	b.Label.Size = UDim2.new(1, -10, 0.8, 0)
	b.Label.Position = UDim2.new(0.5, 0, 0.5, 0)
	b.Label.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Label.TextXAlignment = Enum.TextXAlignment.Center
	return b
end

----------------------------------------------------------------------
-- Coin icon built from frames (no image assets needed)
----------------------------------------------------------------------
function UIKit.coin(parent: Instance, size: number, position: UDim2?, anchor: Vector2?, z: number?): Frame
	local zi = z or 1
	local coin = new("Frame", {
		Name = "Coin",
		Size = UDim2.fromOffset(size, size),
		Position = position or UDim2.new(),
		AnchorPoint = anchor or Vector2.zero,
		BackgroundColor3 = Color3.fromRGB(255, 196, 30),
		ZIndex = zi,
		Parent = parent,
	})
	UIKit.round(coin)
	UIKit.stroke(coin, math.max(2, size / 14))
	UIKit.gradient(coin, { Color3.fromRGB(255, 232, 110), Color3.fromRGB(240, 160, 20) }, 90)
	local inner = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.68, 0.68),
		BackgroundColor3 = Color3.fromRGB(230, 150, 20),
		ZIndex = zi,
		Parent = coin,
	})
	UIKit.round(inner)
	UIKit.label({
		Text = "★",
		Size = UDim2.fromScale(0.95, 0.95),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		TextColor3 = Color3.fromRGB(60, 34, 10),
		Stroke = 0,
		ZIndex = zi,
		Parent = inner,
	})
	return coin
end

----------------------------------------------------------------------
-- Wooden panel with a yellow studded header and a red close button
----------------------------------------------------------------------
export type Panel = {
	Root: Frame,
	Content: Frame,
	Header: Frame,
	Title: TextLabel,
	Scale: UIScale,
	IsOpen: boolean,
	OnClose: (() -> ())?,
}

function UIKit.panel(parent: Instance, title: string, icon: string, width: number, height: number, showClose: boolean?): Panel
	local root = new("Frame", {
		Name = title .. "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromOffset(width, height),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 20,
		Parent = parent,
	})
	local scale = new("UIScale", { Parent = root })

	local body = new("Frame", {
		Name = "Body",
		BackgroundColor3 = C.Wood,
		Size = UDim2.new(1, 0, 1, -34),
		Position = UDim2.fromOffset(0, 34),
		ZIndex = 20,
		Parent = root,
	})
	UIKit.corner(body, 18)
	UIKit.stroke(body, 4)
	local inner = new("Frame", {
		Name = "Inner",
		BackgroundColor3 = C.WoodDark,
		BackgroundTransparency = 0.35,
		Size = UDim2.new(1, -16, 1, -16),
		Position = UDim2.fromOffset(8, 8),
		ZIndex = 20,
		Parent = body,
	})
	UIKit.corner(inner, 14)
	UIKit.stroke(inner, 2, C.WoodLight, 0.2)

	local header = new("Frame", {
		Name = "Header",
		BackgroundColor3 = C.Yellow,
		Size = UDim2.new(1, 16, 0, 72),
		Position = UDim2.fromOffset(-8, 0),
		ZIndex = 22,
		Parent = root,
	})
	UIKit.corner(header, 14)
	UIKit.stroke(header, 4)
	UIKit.gradient(header, { Color3.fromRGB(255, 222, 80), C.Yellow, C.YellowDark }, 90)
	local studs = UIKit.studs(header, width + 16, 72, 16, 0.8)
	UIKit.corner(studs, 14)

	UIKit.label({
		Name = "Icon",
		Text = icon,
		Size = UDim2.fromOffset(58, 58),
		Position = UDim2.new(0, 14, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ZIndex = 23,
		Stroke = 0,
		Parent = header,
	})
	local titleLabel = UIKit.label({
		Name = "Title",
		Text = title,
		Size = UDim2.new(1, -150, 0, 44),
		Position = UDim2.new(0, 82, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 23,
		Stroke = 3.5,
		Parent = header,
	})

	local content = new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -44, 1, -126),
		Position = UDim2.fromOffset(22, 100),
		ZIndex = 21,
		Parent = root,
	})

	local panel: Panel = {
		Root = root,
		Content = content,
		Header = header,
		Title = titleLabel,
		Scale = scale,
		IsOpen = false,
		OnClose = nil,
	}

	if showClose ~= false then
		UIKit.closeButton(root, UDim2.new(1, 4, 0, 6), 30, function()
			if panel.OnClose then
				panel.OnClose()
			end
		end)
	end

	return panel
end

----------------------------------------------------------------------
-- Background blur shared by every menu
----------------------------------------------------------------------
local blur: BlurEffect = Lighting:FindFirstChild("MenuBlur") :: BlurEffect
	or new("BlurEffect", { Name = "MenuBlur", Size = 0, Parent = Lighting })
local blurUsers = 0

function UIKit.setBlur(on: boolean)
	blurUsers = math.max(0, blurUsers + (if on then 1 else -1))
	UIKit.tween(blur, 0.3, { Size = if blurUsers > 0 then 18 else 0 })
end

function UIKit.openPanel(panel: Panel)
	if panel.IsOpen then
		return
	end
	panel.IsOpen = true
	panel.Root.Visible = true
	panel.Scale.Scale = 0.55
	panel.Root.Position = UDim2.fromScale(0.5, 0.58)
	UIKit.tween(panel.Scale, 0.38, { Scale = 1 }, Enum.EasingStyle.Back)
	UIKit.tween(panel.Root, 0.3, { Position = UDim2.fromScale(0.5, 0.52) }, Enum.EasingStyle.Quint)
	UIKit.setBlur(true)
	UIKit.PlaySound("Click", 0.9)
end

function UIKit.closePanel(panel: Panel)
	if not panel.IsOpen then
		return
	end
	panel.IsOpen = false
	UIKit.setBlur(false)
	local t = UIKit.tween(panel.Scale, 0.2, { Scale = 0.6 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	t.Completed:Connect(function()
		if not panel.IsOpen then
			panel.Root.Visible = false
		end
	end)
end

-- Gently widen the camera's field of view while menus are open
function UIKit.cameraZoom(on: boolean)
	local camera = Workspace.CurrentCamera
	if camera and camera.CameraType ~= Enum.CameraType.Scriptable then
		UIKit.tween(camera, 0.35, { FieldOfView = if on then 62 else 70 })
	end
end

return UIKit
