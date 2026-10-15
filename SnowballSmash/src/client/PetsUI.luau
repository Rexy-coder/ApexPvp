--!nonstrict
-- Snowball Smash: pets on the client. Egg panel (walk up to an egg),
-- hatch animation, Pets inventory, Index book and the pets that follow
-- every player around (and your snowball during a run).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Pets = require(Shared:WaitForChild("Pets"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local PetModels = require(script.Parent:WaitForChild("PetModels"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Panels = require(script.Parent:WaitForChild("Panels"))
local Effects = require(script.Parent:WaitForChild("Effects"))

local C = UIKit.Colors
local new = UIKit.new
local player = Players.LocalPlayer

local PetsUI = {}
PetsUI.Callbacks = {
	Hatch = function(_eggId: string, _count: number, _fast: boolean?): boolean return false end, -- returns when the hatch (and animation) is done
	Action = function(_action: string, _uid: string?) end,
	BuyPass = function(_key: string) end,
}
PetsUI.NearEgg = nil :: string?
PetsUI.Busy = false
-- returns (position, radius) of the snowball during a run, or nil
PetsUI.BallTarget = function(): (Vector3?, number?) return nil, nil end

local data = nil

local function hasPass(key: string): boolean
	return player:GetAttribute("Pass_" .. key) == true
end

local function rarityColor(r: string): Color3
	return Pets.Rarities[r].Color
end

local function eggVisible(egg): boolean
	return (not egg.Halloween or Config.Halloween.Enabled) and (not egg.Winter or Config.Winter.Enabled)
end

----------------------------------------------------------------------
-- Small widgets
----------------------------------------------------------------------
-- A pet tile: rarity background, emoji, optional name/bonus line
local function petTile(parent: Instance, petId: string, size: Vector2, showName: boolean, discovered: boolean?): Frame
	local pet = Pets.ById[petId]
	local known = discovered ~= false
	local tile = new("Frame", {
		BackgroundColor3 = if known then rarityColor(pet.Rarity) else Color3.fromRGB(50, 50, 62),
		Size = UDim2.fromOffset(size.X, size.Y),
		Parent = parent,
	})
	UIKit.corner(tile, 12)
	UIKit.stroke(tile, 3)
	UIKit.gradient(tile, { Color3.new(1, 1, 1), Color3.new(0.6, 0.6, 0.65) }, 90)
	local iconHeight = size.Y * (if showName then 0.56 else 0.78)
	if known then
		-- the real 3D pet
		PetModels.viewport(petId, tile, UDim2.new(0, iconHeight * 1.15, 0, iconHeight), UDim2.new(0.5, 0, 0, size.Y * 0.03), Vector2.new(0.5, 0))
	else
		UIKit.label({
			Text = "?",
			Size = UDim2.new(0.8, 0, 0, iconHeight),
			Position = UDim2.new(0.5, 0, 0, size.Y * 0.06),
			AnchorPoint = Vector2.new(0.5, 0),
			Stroke = 3,
			TextColor3 = Color3.fromRGB(150, 150, 165),
			Parent = tile,
		})
	end
	if showName then
		UIKit.label({
			Text = if known then pet.Name else "???",
			Size = UDim2.new(1, -10, 0, size.Y * 0.17),
			Position = UDim2.new(0.5, 0, 0, size.Y * 0.6),
			AnchorPoint = Vector2.new(0.5, 0),
			Stroke = 2,
			Parent = tile,
		})
		UIKit.label({
			Text = if known then "+" .. pet.Coins .. "%" else pet.Rarity,
			TextColor3 = if known then Color3.fromRGB(255, 230, 90) else Color3.fromRGB(200, 200, 210),
			Size = UDim2.new(1, -10, 0, size.Y * 0.15),
			Position = UDim2.new(0.5, 0, 0, size.Y * 0.79),
			AnchorPoint = Vector2.new(0.5, 0),
			Stroke = 2,
			Parent = tile,
		})
	end
	return tile
end

local function eggSprite(parent: Instance, color: Color3, size: number, position: UDim2): Frame
	local egg = new("Frame", {
		BackgroundColor3 = color,
		Size = UDim2.fromOffset(size * 0.8, size),
		Position = position,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Parent = parent,
	})
	UIKit.round(egg)
	UIKit.stroke(egg, math.max(3, size / 28))
	UIKit.gradient(egg, { Color3.new(1, 1, 1), Color3.new(0.65, 0.65, 0.75) }, 60)
	for _, spot in { { 0.3, 0.3, 0.16 }, { 0.62, 0.22, 0.1 }, { 0.65, 0.58, 0.14 }, { 0.32, 0.68, 0.1 } } do
		local s = new("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.25,
			Size = UDim2.fromScale(spot[3], spot[3] * 0.8),
			Position = UDim2.fromScale(spot[1], spot[2]),
			Parent = egg,
		})
		UIKit.round(s)
	end
	new("UIScale", { Parent = egg })
	return egg
end

----------------------------------------------------------------------
-- Egg panel (shows when you stand next to an egg in the lobby)
----------------------------------------------------------------------
local eggPanel = new("Frame", {
	Name = "EggPanel",
	BackgroundColor3 = C.Wood,
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 300),
	Size = UDim2.fromOffset(560, 270),
	Visible = false,
	ZIndex = 15,
	Parent = Hud.Root,
})
UIKit.corner(eggPanel, 18)
UIKit.stroke(eggPanel, 4)
local eggHeader = new("Frame", {
	BackgroundColor3 = C.Yellow,
	Size = UDim2.new(1, 16, 0, 56),
	Position = UDim2.fromOffset(-8, -22),
	Parent = eggPanel,
})
UIKit.corner(eggHeader, 14)
UIKit.stroke(eggHeader, 4)
local eggTitle = UIKit.label({ Text = "Frosty Egg", TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.6, 0, 0, 36), Position = UDim2.fromOffset(18, 10), Stroke = 3, Parent = eggHeader })
local eggPrice = UIKit.label({ Text = "", TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0.4, -24, 0, 32), Position = UDim2.new(0.6, 0, 0, 12), Stroke = 3, TextColor3 = Color3.fromRGB(255, 225, 70), Parent = eggHeader })
local oddsRow = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 112), Position = UDim2.fromOffset(12, 44), Parent = eggPanel })
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), Parent = oddsRow })

local function eggButton(text: string, x: number, color: Color3, dark: Color3, key: string, onClick: () -> ()): UIKit.Button
	local b = UIKit.button({ Size = UDim2.fromOffset(166, 62), Position = UDim2.fromOffset(x, 186), Color = color, DarkColor = dark, Text = text, Key = key, Studs = true, Parent = eggPanel, OnClick = onClick })
	b.Label.TextXAlignment = Enum.TextXAlignment.Center
	return b
end

local autoOn = false
local shownEgg: string? = nil
PetsUI.toggleAuto = function() end -- defined below

local function hatch(count: number)
	if not shownEgg or PetsUI.Busy then
		return
	end
	if count == 3 and not hasPass("TripleHatch") then
		PetsUI.Callbacks.BuyPass("TripleHatch")
		return
	end
	PetsUI.Callbacks.Hatch(shownEgg, count)
end

local _hatch1 = eggButton("Hatch", 14, C.Green, C.GreenDark, "E", function()
	hatch(1)
end)
local hatch3 = eggButton("Hatch x3", 197, C.Blue, C.BlueDark, "R", function()
	hatch(3)
end)
local autoButton = eggButton("Auto", 380, C.Purple, C.PurpleDark, "T", function()
	PetsUI.toggleAuto()
end)

PetsUI.toggleAuto = function()
	if not hasPass("AutoHatch") then
		PetsUI.Callbacks.BuyPass("AutoHatch")
		return
	end
	autoOn = not autoOn
	autoButton.SetText(if autoOn then "Auto: ON" else "Auto")
	autoButton.SetColors(if autoOn then C.Green else C.Purple, if autoOn then C.GreenDark else C.PurpleDark)
end

local function fillEggPanel(eggId: string)
	local egg = Pets.EggById[eggId]
	eggTitle.Text = "🥚 " .. egg.Name
	local price = if data then Config.EggPrice(data.Owned, egg.Price) else egg.Price
	local currency = Config.Currencies[egg.Currency] or Config.Currencies.Coins
	eggPrice.Text = currency.Icon .. " " .. Config.Commas(price) .. (if price < egg.Price then " 🏷️" else "")
	eggPrice.TextColor3 = currency.Color
	for _, c in oddsRow:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local luck = (if hasPass("LuckyEggs") then 1.5 else 1) * (if data then Config.HatchLuckMult(data.Owned) else 1)
	local odds = Pets.Odds(eggId, luck)
	for i, pet in egg.Pets do
		local known = data ~= nil and data.Index[pet.Id] == true
		local tile = petTile(oddsRow, pet.Id, Vector2.new(78, 84), false, known or pet.Rarity ~= "Secret")
		tile.LayoutOrder = i
		local chance = odds[pet.Id]
		UIKit.label({
			Text = if chance < 1 then string.format("%.1f%%", chance) else string.format("%d%%", math.floor(chance + 0.5)),
			Size = UDim2.new(1, -6, 0, 22),
			Position = UDim2.new(0.5, 0, 1, -4),
			AnchorPoint = Vector2.new(0.5, 1),
			Stroke = 2.5,
			Parent = tile,
		})
	end
	hatch3.SetText(if hasPass("TripleHatch") then "Hatch x3" else "x3 🔒")
	autoButton.SetText(if not hasPass("AutoHatch") then "Auto 🔒" elseif autoOn then "Auto: ON" else "Auto")
end

local eggModels = {}
task.spawn(function()
	local lobby = Workspace:WaitForChild("Lobby", 30)
	if not lobby then
		return
	end
	local function scan()
		for _, d in lobby:GetDescendants() do
			local id = string.match(d.Name, "^Egg_(.+)$")
			if id and Pets.EggById[id] and d:IsA("Model") then
				eggModels[id] = d
			end
		end
	end
	scan()
	lobby.DescendantAdded:Connect(function()
		task.defer(scan)
	end)
end)

local panelShown = false
local function showEggPanel(eggId: string?)
	if eggId == shownEgg and (eggId ~= nil) == panelShown then
		return
	end
	shownEgg = eggId
	if eggId then
		fillEggPanel(eggId)
		if not panelShown then
			panelShown = true
			eggPanel.Visible = true
			eggPanel.Position = UDim2.new(0.5, 0, 1, 300)
			UIKit.tween(eggPanel, 0.4, { Position = UDim2.new(0.5, 0, 1, -130) }, Enum.EasingStyle.Back)
		end
	elseif panelShown then
		panelShown = false
		autoOn = false
		local t = UIKit.tween(eggPanel, 0.25, { Position = UDim2.new(0.5, 0, 1, 300) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		t.Completed:Connect(function()
			if not panelShown then
				eggPanel.Visible = false
			end
		end)
	end
end

RunService.Heartbeat:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local nearest, best = nil, 14
	if root and Hud.Mode == "Idle" and not Panels.anyOpen() then
		for id, m in eggModels do
			local egg = Pets.EggById[id]
			if m.Parent and eggVisible(egg) then
				local d = (m:GetPivot().Position - root.Position) * Vector3.new(1, 0, 1)
				if d.Magnitude < best then
					nearest, best = id, d.Magnitude
				end
			end
		end
	end
	PetsUI.NearEgg = nearest
	showEggPanel(nearest)
end)

-- auto hatch loop
task.spawn(function()
	while true do
		task.wait(0.2)
		if autoOn and shownEgg and not PetsUI.Busy then
			if not hasPass("AutoHatch") then
				autoOn = false
			else
				local ok = PetsUI.Callbacks.Hatch(shownEgg, if hasPass("TripleHatch") then 3 else 1, true)
				if not ok then
					autoOn = false
					autoButton.SetText("Auto")
					autoButton.SetColors(C.Purple, C.PurpleDark)
				end
			end
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not shownEgg then
		return
	end
	if input.KeyCode == Enum.KeyCode.E then
		hatch(1)
	elseif input.KeyCode == Enum.KeyCode.R then
		hatch(3)
	elseif input.KeyCode == Enum.KeyCode.T then
		PetsUI.toggleAuto()
	end
end)

----------------------------------------------------------------------
-- Hatch animation
----------------------------------------------------------------------
local overlay = new("Frame", {
	Name = "Hatch",
	BackgroundColor3 = Color3.fromRGB(10, 14, 30),
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Visible = false,
	ZIndex = 60,
	Parent = Hud.Root,
})
local flash = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 70, Parent = overlay })

-- plays the hatch animation for `results` (list of pet ids); yields until done
function PetsUI.playHatch(eggId: string, results: { string }, newPets: { [string]: boolean }, fast: boolean?)
	local egg = Pets.EggById[eggId]
	local speed = if fast then 0.55 else 1
	overlay.Visible = true
	overlay.BackgroundTransparency = 1
	UIKit.tween(overlay, 0.25 * speed, { BackgroundTransparency = 0.35 })
	local holders = {}
	local n = #results
	for i = 1, n do
		local x = 0.5 + (i - (n + 1) / 2) * 0.26
		local holder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(300, 380), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 0.5), ZIndex = 62, Parent = overlay })
		local sprite = eggSprite(holder, egg.Color, if n == 1 then 230 else 170, UDim2.fromScale(0.5, 0.45))
		local scale = sprite:FindFirstChildOfClass("UIScale")
		scale.Scale = 0
		UIKit.tween(scale, 0.35 * speed, { Scale = 1 }, Enum.EasingStyle.Back)
		holders[i] = { Holder = holder, Sprite = sprite }
	end
	task.wait(0.35 * speed)
	-- wobble harder and harder
	local wobbles = if fast then 4 else 7
	for w = 1, wobbles do
		local angle = (if w % 2 == 0 then 1 else -1) * (6 + w * 3)
		for _, h in holders do
			UIKit.tween(h.Sprite, 0.09 * speed, { Rotation = angle })
		end
		Effects.play("Click", 0.8 + w * 0.08, 0.5)
		task.wait(0.1 * speed + (wobbles - w) * 0.012)
	end
	flash.BackgroundTransparency = 0
	UIKit.tween(flash, 0.5 * speed, { BackgroundTransparency = 1 })
	Effects.play("Smash", 1.4)
	local bestOrder = 0
	for i, h in holders do
		h.Sprite:Destroy()
		local pet = Pets.ById[results[i]]
		bestOrder = math.max(bestOrder, Pets.Rarities[pet.Rarity].Order)
		local rays = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(340, 340), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), ZIndex = 62, Parent = h.Holder })
		for r = 1, 8 do
			local ray = new("Frame", {
				BackgroundColor3 = rarityColor(pet.Rarity),
				BackgroundTransparency = 0.55,
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(34, 340),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Rotation = r * 22.5,
				ZIndex = 62,
				Parent = rays,
			})
			UIKit.corner(ray, 17)
		end
		task.spawn(function()
			while rays.Parent do
				rays.Rotation += 1.2
				RunService.RenderStepped:Wait()
			end
		end)
		local icon, petModel = PetModels.viewport(pet.Id, h.Holder, UDim2.fromOffset(250, 250), UDim2.fromScale(0.5, 0.42), Vector2.new(0.5, 0.5))
		icon.ZIndex = 64
		UIKit.pop(icon, 0.2)
		task.spawn(function()
			local spin = math.rad(-25)
			while icon.Parent do
				local dt = RunService.RenderStepped:Wait()
				spin += dt * 1.6
				petModel:PivotTo(CFrame.new(0, math.sin(os.clock() * 3) * 0.12, 0) * CFrame.Angles(0, spin, 0))
			end
		end)
		local name = UIKit.label({ Text = pet.Name, Size = UDim2.fromOffset(300, 44), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.72), Stroke = 3.5, ZIndex = 64, Parent = h.Holder })
		local rarity = UIKit.label({ Text = string.upper(pet.Rarity), TextColor3 = rarityColor(pet.Rarity), Size = UDim2.fromOffset(300, 36), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.84), Stroke = 3, ZIndex = 64, Parent = h.Holder })
		if pet.Rarity == "Secret" then
			UIKit.gradient(rarity, { Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 220, 60), Color3.fromRGB(80, 220, 255), Color3.fromRGB(200, 90, 255) }, 0)
		end
		UIKit.pop(name, 0.4)
		if newPets[results[i]] then
			local tag = new("Frame", { BackgroundColor3 = C.Pink, Size = UDim2.fromOffset(90, 40), Position = UDim2.new(0.5, 70, 0.12, 0), Rotation = 12, ZIndex = 66, Parent = h.Holder })
			UIKit.corner(tag, 10)
			UIKit.stroke(tag, 3)
			UIKit.label({ Text = "NEW!", Size = UDim2.new(1, -10, 1, -8), Position = UDim2.fromOffset(5, 4), Stroke = 2.5, ZIndex = 67, Parent = tag })
			UIKit.pop(tag, 1.8)
		end
	end
	if bestOrder >= 4 then
		Effects.play("NewBest", 1)
		Effects.shake(1.5)
	else
		Effects.play("Coin", 1.3)
	end
	task.wait((if bestOrder >= 4 then 1.9 else 1.3) * speed)
	UIKit.tween(overlay, 0.25 * speed, { BackgroundTransparency = 1 })
	for _, h in holders do
		local s = new("UIScale", { Parent = h.Holder })
		UIKit.tween(s, 0.25 * speed, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	end
	task.wait(0.27 * speed)
	for _, h in holders do
		h.Holder:Destroy()
	end
	overlay.Visible = false
end

----------------------------------------------------------------------
-- Pets inventory panel
----------------------------------------------------------------------
local petsPanel = UIKit.panel(Hud.Root, "Pets", "🐾", 860, 600)
Panels.register("Pets", petsPanel)

local countLabel = UIKit.label({ Text = "", TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(330, 30), Position = UDim2.fromOffset(4, 6), Stroke = 2.5, Parent = petsPanel.Content })
local equipBest = UIKit.button({ Size = UDim2.fromOffset(190, 48), Position = UDim2.new(1, -404, 0, 0), Color = C.Green, DarkColor = C.GreenDark, Text = "Equip Best", Parent = petsPanel.Content, OnClick = function()
	PetsUI.Callbacks.Action("EquipBest", nil)
end })
equipBest.Label.TextXAlignment = Enum.TextXAlignment.Center
local confirmDelete = 0
local deleteAll
deleteAll = UIKit.button({ Size = UDim2.fromOffset(200, 48), Position = UDim2.new(1, -204, 0, 0), Color = C.Red, DarkColor = C.RedDark, Text = "Delete Unlocked", Parent = petsPanel.Content, OnClick = function()
	if os.clock() - confirmDelete < 3 then
		confirmDelete = 0
		deleteAll.SetText("Delete Unlocked")
		PetsUI.Callbacks.Action("DeleteUnlocked", nil)
	else
		confirmDelete = os.clock()
		deleteAll.SetText("Sure? Click again")
		task.delay(3, function()
			deleteAll.SetText("Delete Unlocked")
		end)
	end
end })
deleteAll.Label.TextXAlignment = Enum.TextXAlignment.Center

local grid = new("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 1, -150),
	Position = UDim2.fromOffset(0, 60),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 8,
	ScrollBarImageColor3 = C.Yellow,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	Parent = petsPanel.Content,
})
new("UIGridLayout", { CellSize = UDim2.fromOffset(118, 140), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), Parent = grid })

-- bottom bar for the selected pet
local selectedUid: string? = nil
local bar = new("Frame", { BackgroundColor3 = C.WoodDark, Size = UDim2.new(1, 0, 0, 78), Position = UDim2.new(0, 0, 1, -78), Parent = petsPanel.Content })
UIKit.corner(bar, 12)
UIKit.stroke(bar, 3)
local barInfo = UIKit.label({ Text = "Click a pet to select it", TextXAlignment = Enum.TextXAlignment.Left, TextScaled = false, TextSize = 20, TextWrapped = true, Size = UDim2.new(1, -470, 1, -12), Position = UDim2.fromOffset(14, 6), Stroke = 2, RichText = true, Parent = bar })
local function barButton(text: string, x: number, color: Color3, dark: Color3, action: string): UIKit.Button
	local b = UIKit.button({ Size = UDim2.fromOffset(140, 52), Position = UDim2.new(1, x, 0.5, -26), Color = color, DarkColor = dark, Text = text, Parent = bar, Corner = 10, OnClick = function()
		if selectedUid then
			PetsUI.Callbacks.Action(action, selectedUid)
		end
	end })
	b.Label.TextXAlignment = Enum.TextXAlignment.Center
	return b
end
local equipButton = barButton("Equip", -456, C.Green, C.GreenDark, "Equip")
local lockButton = barButton("Lock", -306, C.Blue, C.BlueDark, "ToggleLock")
barButton("Delete", -156, C.Red, C.RedDark, "Delete")

local function slots(): number
	return Pets.BaseEquipSlots + (if hasPass("ExtraPets") then Pets.ExtraSlotsPass else 0)
end

local function refreshBar()
	local owned = selectedUid and data and data.Pets[selectedUid]
	if not owned then
		selectedUid = nil
		barInfo.Text = "Click a pet to select it"
		return
	end
	local pet = Pets.ById[owned.P]
	local hex = rarityColor(pet.Rarity):ToHex()
	barInfo.Text = string.format('%s <b>%s</b>  <font color="#%s">%s</font>\n%s', pet.Icon, pet.Name, hex, pet.Rarity, Pets.BonusText(owned.P))
	local equipped = table.find(data.Equipped, selectedUid) ~= nil
	equipButton.SetText(if equipped then "Unequip" else "Equip")
	equipButton.SetColors(if equipped then C.Grey else C.Green, if equipped then C.GreyDark else C.GreenDark)
	lockButton.SetText(if owned.L then "Unlock" else "Lock")
end

-- the Equip button toggles
equipButton.Clicked = function()
	if selectedUid and data then
		local equipped = table.find(data.Equipped, selectedUid) ~= nil
		PetsUI.Callbacks.Action(if equipped then "Unequip" else "Equip", selectedUid)
	end
end

local function refreshInventory()
	for _, c in grid:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	if not data then
		return
	end
	local list = {}
	local count = 0
	for uid, owned in data.Pets do
		count += 1
		table.insert(list, { Uid = uid, Pet = owned.P, Locked = owned.L, Equipped = table.find(data.Equipped, uid) ~= nil })
	end
	table.sort(list, function(a, b)
		if a.Equipped ~= b.Equipped then
			return a.Equipped
		end
		return Pets.Score(a.Pet) > Pets.Score(b.Pet)
	end)
	countLabel.Text = string.format("Equipped %d/%d  ·  Pets %d/%d", #data.Equipped, slots(), count, Pets.MaxInventory + Config.PetStorageBonus(data.Owned))
	for i, item in list do
		local tile = petTile(grid, item.Pet, Vector2.new(118, 140), true)
		tile.LayoutOrder = i
		if item.Equipped then
			local check = new("Frame", { BackgroundColor3 = C.Green, Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(-6, -6), Parent = tile })
			UIKit.round(check)
			UIKit.stroke(check, 2.5)
			UIKit.label({ Text = "✔", Size = UDim2.fromScale(0.75, 0.75), Position = UDim2.fromScale(0.125, 0.125), Stroke = 0, Parent = check })
		end
		if item.Locked then
			UIKit.label({ Text = "🔒", Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -28, 0, 2), Stroke = 0, Parent = tile })
		end
		if item.Uid == selectedUid then
			local outline = tile:FindFirstChildOfClass("UIStroke")
			if outline then
				outline.Color = C.Yellow
				outline.Thickness = 5
			end
		end
		local hit = new("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), Parent = tile })
		hit.Activated:Connect(function()
			selectedUid = item.Uid
			Effects.play("Click", 1.2)
			refreshInventory()
		end)
	end
	refreshBar()
end

----------------------------------------------------------------------
-- Index panel
----------------------------------------------------------------------
local indexPanel = UIKit.panel(Hud.Root, "Index", "📘", 860, 600)
Panels.register("Index", indexPanel)
local indexBonus = UIKit.label({ Text = "", TextColor3 = Color3.fromRGB(140, 255, 110), Size = UDim2.new(1, 0, 0, 30), Stroke = 2.5, Parent = indexPanel.Content })
local indexScroll = new("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 1, -40),
	Position = UDim2.fromOffset(0, 40),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 8,
	ScrollBarImageColor3 = C.Yellow,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	Parent = indexPanel.Content,
})
new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = indexScroll })
new("UIPadding", { PaddingRight = UDim.new(0, 14), Parent = indexScroll })

local function refreshIndex()
	for _, c in indexScroll:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	if not data then
		return
	end
	local completed = Pets.CompletedEggs(data.Index)
	indexBonus.Text = string.format("Complete an egg = +%d%% coins forever  ·  Your Index bonus: +%d%%", Pets.IndexBonus, #completed * Pets.IndexBonus)
	for i, egg in Pets.Eggs do
		if eggVisible(egg) or table.find(completed, egg.Id) then
			local found = 0
			for _, p in egg.Pets do
				if data.Index[p.Id] then
					found += 1
				end
			end
			local done = table.find(completed, egg.Id) ~= nil
			local section = new("Frame", { BackgroundColor3 = C.WoodLight, Size = UDim2.new(1, 0, 0, 170), LayoutOrder = i, Parent = indexScroll })
			UIKit.corner(section, 12)
			UIKit.stroke(section, 3, if done then C.Yellow else C.Outline)
			UIKit.label({ Text = "🥚 " .. egg.Name .. "   " .. found .. "/" .. #egg.Pets, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.6, 0, 0, 30), Position = UDim2.fromOffset(14, 8), Stroke = 2.5, Parent = section })
			UIKit.label({
				Text = if done then "✔ +" .. Pets.IndexBonus .. "% coins" else "Reward: +" .. Pets.IndexBonus .. "% coins",
				TextColor3 = if done then Color3.fromRGB(140, 255, 110) else Color3.fromRGB(255, 225, 120),
				TextXAlignment = Enum.TextXAlignment.Right,
				Size = UDim2.new(0.4, -20, 0, 26),
				Position = UDim2.new(0.6, 0, 0, 10),
				Stroke = 2,
				Parent = section,
			})
			local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 118), Position = UDim2.fromOffset(12, 44), Parent = section })
			new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), Parent = row })
			for j, p in egg.Pets do
				local tile = petTile(row, p.Id, Vector2.new(112, 116), true, data.Index[p.Id] == true)
				tile.LayoutOrder = j
			end
		end
	end
end

----------------------------------------------------------------------
-- Pets following players (and your snowball during a run)
----------------------------------------------------------------------
local followFolder = Instance.new("Folder")
followFolder.Name = "PetFollowers"
followFolder.Parent = Workspace

type Follower = { Model: Model, Pos: Vector3, Dir: Vector3, PetId: string }
local followers: { [Player]: { Follower } } = {}

local function makeFollower(petId: string): Follower
	local model = PetModels.build(petId)
	model.Parent = followFolder
	return { Model = model, Pos = Vector3.zero, Dir = Vector3.new(0, 0, -1), PetId = petId }
end

local function syncFollowers(p: Player)
	local ids = string.split(tostring(p:GetAttribute("EquippedPets") or ""), ",")
	local list = followers[p] or {}
	local want = {}
	for _, id in ids do
		if Pets.ById[id] then
			table.insert(want, id)
		end
	end
	-- rebuild only when the set changed
	local same = #want == #list
	if same then
		for i, f in list do
			if f.PetId ~= want[i] then
				same = false
			end
		end
	end
	if same then
		return
	end
	for _, f in list do
		f.Model:Destroy()
	end
	list = {}
	for _, id in want do
		table.insert(list, makeFollower(id))
	end
	followers[p] = list
end

local function watch(p: Player)
	syncFollowers(p)
	p:GetAttributeChangedSignal("EquippedPets"):Connect(function()
		syncFollowers(p)
	end)
end
for _, p in Players:GetPlayers() do
	watch(p)
end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(function(p)
	local list = followers[p]
	if list then
		for _, f in list do
			f.Model:Destroy()
		end
	end
	followers[p] = nil
end)

RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	for p, list in followers do
		local center, look, spread, flying = nil, nil, 4, false
		if p == player then
			local ballPos, radius = PetsUI.BallTarget()
			if ballPos then
				center = ballPos + Vector3.new(0, (radius or 3) + 3, 0)
				look = Vector3.new(0, 0, -1)
				spread = 4 + (radius or 3) * 0.8
				flying = true
			end
		end
		if not center then
			local character = p.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				center = root.Position - Vector3.new(0, 1.55, 0) -- standing on the ground next to you
				look = root.CFrame.LookVector
			end
		end
		if center and look then
			local flat = Vector3.new(look.X, 0, look.Z)
			flat = if flat.Magnitude > 0.01 then flat.Unit else Vector3.new(0, 0, -1)
			local right = flat:Cross(Vector3.yAxis)
			for i, f in list do
				local side = (i - (#list + 1) / 2)
				local want = center - flat * (spread * 0.9 + math.abs(side) * 0.8) + right * side * spread * 0.7
				if f.Pos == Vector3.zero or (f.Pos - want).Magnitude > 80 then
					f.Pos = want
				end
				local before = f.Pos
				f.Pos = f.Pos:Lerp(want, 1 - math.exp(-dt * 7))
				local move = (f.Pos - before) / math.max(dt, 1 / 240)
				local moveFlat = Vector3.new(move.X, 0, move.Z)
				local speed = moveFlat.Magnitude
				-- face where we're walking, or the same way as the owner when standing still
				local wantDir = if speed > 1.5 then moveFlat.Unit else flat
				f.Dir = f.Dir:Lerp(wantDir, 1 - math.exp(-dt * 8))
				if f.Dir.Magnitude < 0.05 then
					f.Dir = wantDir
				end
				-- little hops while walking, a gentle float while flying or idle
				local hop = if flying then math.sin(t * 3 + i) * 0.5
					else math.abs(math.sin(t * 11 + i * 1.7)) * 0.8 * math.clamp(speed / 6, 0, 1) + math.sin(t * 2.5 + i) * 0.08
				local tilt = if flying then 0 else math.clamp(speed / 30, 0, 0.25)
				local pos = f.Pos + Vector3.new(0, hop, 0)
				f.Model:PivotTo(CFrame.lookAt(pos, pos + f.Dir.Unit) * CFrame.Angles(-tilt, 0, math.sin(t * 11 + i) * tilt * 0.6))
			end
		end
	end
end)

----------------------------------------------------------------------
-- Refresh from player data
----------------------------------------------------------------------
function PetsUI.refresh(newData)
	data = newData
	if petsPanel.IsOpen then
		refreshInventory()
	end
	if indexPanel.IsOpen then
		refreshIndex()
	end
	if shownEgg then
		fillEggPanel(shownEgg)
	end
end

-- rebuild lists when the panels open
petsPanel.Root:GetPropertyChangedSignal("Visible"):Connect(function()
	if petsPanel.Root.Visible then
		refreshInventory()
	end
end)
indexPanel.Root:GetPropertyChangedSignal("Visible"):Connect(function()
	if indexPanel.Root.Visible then
		refreshIndex()
	end
end)
player.AttributeChanged:Connect(function(name)
	if string.sub(name, 1, 5) == "Pass_" then
		PetsUI.refresh(data)
	end
end)

return PetsUI
