--!nonstrict
-- Snowball Smash: client entry point. Wires the HUD, menus, shop, admin panel,
-- upgrade tree and the run together and talks to the server.

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local MarketplaceService = game:GetService("MarketplaceService")
local TextChatService = game:GetService("TextChatService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GameState = ReplicatedStorage:WaitForChild("GameState")

local Config = require(Shared:WaitForChild("Config"))
local Monetization = require(Shared:WaitForChild("Monetization"))
local UIKit = require(script:WaitForChild("UIKit"))
local Effects = require(script:WaitForChild("Effects"))
local Hud = require(script:WaitForChild("Hud"))
local Panels = require(script:WaitForChild("Panels"))
local UpgradeTree = require(script:WaitForChild("UpgradeTree"))
local Runner = require(script:WaitForChild("Runner"))
local PetsUI = require(script:WaitForChild("PetsUI"))
local DailyUI = require(script:WaitForChild("DailyUI"))
local CrazyFX = require(script:WaitForChild("CrazyFX"))
local Pets = require(Shared:WaitForChild("Pets"))

local C = UIKit.Colors

local GetData = Remotes:WaitForChild("GetData") :: RemoteFunction
local DataChanged = Remotes:WaitForChild("DataChanged") :: RemoteEvent
local StartRun = Remotes:WaitForChild("StartRun") :: RemoteFunction
local FinishRun = Remotes:WaitForChild("FinishRun") :: RemoteFunction
local BuyUpgrade = Remotes:WaitForChild("BuyUpgrade") :: RemoteFunction
local BuySkin = Remotes:WaitForChild("BuySkin") :: RemoteFunction
local DoRebirth = Remotes:WaitForChild("Rebirth") :: RemoteFunction
local SetSetting = Remotes:WaitForChild("SetSetting") :: RemoteEvent
local UseTurbo = Remotes:WaitForChild("UseTurbo") :: RemoteFunction
local AdminAction = Remotes:WaitForChild("AdminAction") :: RemoteFunction
local Notify = Remotes:WaitForChild("Notify") :: RemoteEvent
local HatchEgg = Remotes:WaitForChild("HatchEgg") :: RemoteFunction
local PetAction = Remotes:WaitForChild("PetAction") :: RemoteFunction
local ClaimDaily = Remotes:WaitForChild("ClaimDaily") :: RemoteFunction
local RedeemCode = Remotes:WaitForChild("RedeemCode") :: RemoteFunction

local function serverNow(): number
	return Workspace:GetServerTimeNow()
end

local function hasPass(key: string): boolean
	return player:GetAttribute("Pass_" .. key) == true
end

local function errorToast(text: string)
	Hud.toast(text, C.Red)
	Effects.play("Error", 1)
end

----------------------------------------------------------------------
-- Player data
----------------------------------------------------------------------
local data = nil
local refreshBoosts = function() end

local function apply(newData)
	if type(newData) ~= "table" then
		return
	end
	local first = data == nil
	data = newData
	for key, value in newData.Settings do
		Effects.Settings[key] = value
	end
	Hud.setCoins(newData.Coins, first)
	Hud.setBest(newData.BestEarn)
	Hud.setTurbos(newData.Turbos or 0)
	Hud.setCandy(newData.Candy or 0)
	Hud.setPresents(newData.Presents or 0)
	PetsUI.refresh(newData)
	DailyUI.refresh(newData)
	Panels.refresh(newData)
	UpgradeTree.refresh(newData)
	Hud.setAlert("Upgrades", UpgradeTree.anyAffordable(newData))
	Hud.setAlert("Shop", Panels.anySkinAffordable(newData))
	Hud.setAlert("Rebirth", Panels.canRebirth(newData))
	Effects.applyMusic()
	refreshBoosts()
end

DataChanged.OnClientEvent:Connect(apply)
task.spawn(function()
	apply(GetData:InvokeServer())
end)

----------------------------------------------------------------------
-- Game passes (owned / given by an admin) come in as player attributes
----------------------------------------------------------------------
local function refreshPasses()
	local owned = {}
	for _, pass in Monetization.Passes do
		owned[pass.Key] = hasPass(pass.Key)
	end
	Panels.setPasses(owned)
	Hud.setAdmin(player:GetAttribute("IsAdmin") == true)
	refreshBoosts()
end
player.AttributeChanged:Connect(function(name)
	if string.sub(name, 1, 5) == "Pass_" or name == "IsAdmin" then
		refreshPasses()
	end
end)

-- real Robux prices from Roblox (falls back to the price in Monetization)
for _, pass in Monetization.Passes do
	if pass.Id ~= 0 then
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(pass.Id, Enum.InfoType.GamePass)
			end)
			if ok and info and info.PriceInRobux then
				Panels.setRobuxPrice(pass.Key, info.PriceInRobux)
			end
		end)
	end
end
for _, product in Monetization.Products do
	if product.Id ~= 0 then
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(product.Id, Enum.InfoType.Product)
			end)
			if ok and info and info.PriceInRobux then
				Panels.setRobuxPrice(product.Key, info.PriceInRobux)
			end
		end)
	end
end

local function buyRobux(kind: string, key: string)
	local item = if kind == "Pass" then Monetization.PassByKey[key] else Monetization.ProductByKey[key]
	if not item then
		return
	end
	if kind == "Pass" and hasPass(key) then
		Hud.toast("You already own " .. item.Name .. "!", C.Purple)
		return
	end
	if item.Id == 0 then
		errorToast("Coming soon! (add its ID in Shared.Monetization)")
		return
	end
	if kind == "Pass" then
		MarketplaceService:PromptGamePassPurchase(player, item.Id)
	else
		MarketplaceService:PromptProductPurchase(player, item.Id)
	end
end
Panels.Callbacks.BuyRobux = buyRobux

----------------------------------------------------------------------
-- Chat tags: [ADMIN] and [VIP]
----------------------------------------------------------------------
TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local props = Instance.new("TextChatMessageProperties")
	local source = message.TextSource
	if source then
		local speaker = Players:GetPlayerByUserId(source.UserId)
		if speaker then
			local tags = ""
			if speaker:GetAttribute("IsAdmin") then
				tags ..= '<font color="#FF5A5A">[ADMIN]</font> '
			end
			if speaker:GetAttribute("Pass_VIP") then
				tags ..= '<font color="#FFD23C">[VIP]</font> '
			end
			if tags ~= "" then
				props.PrefixText = tags .. message.PrefixText
			end
		end
	end
	return props
end

local function systemChat(text: string)
	pcall(function()
		local channels = TextChatService:FindFirstChild("TextChannels")
		local general = channels and channels:FindFirstChild("RBXGeneral")
		if general then
			general:DisplaySystemMessage(text)
		end
	end)
end

----------------------------------------------------------------------
-- Boosts, storms and the side list
----------------------------------------------------------------------
local function activeEvents()
	local list = {}
	local t = serverNow()
	for _, e in Config.Events do
		local ends = GameState:GetAttribute("Event_" .. e.Id)
		if type(ends) == "number" and ends > t then
			table.insert(list, { Def = e, EndsAt = ends })
		end
	end
	return list
end

refreshBoosts = function()
	local entries = {}
	if hasPass("VIP") then
		table.insert(entries, { Key = "VIP", Icon = "👑", Text = "VIP +25%", Color = Color3.fromRGB(255, 200, 40) })
	end
	if hasPass("DoubleCoins") then
		table.insert(entries, { Key = "Double", Icon = "💰", Text = "2x Coins", Color = Color3.fromRGB(90, 220, 70) })
	end
	if data and (data.BoostEnds or 0) > serverNow() then
		table.insert(entries, { Key = "Boost", Icon = "⏱️", Text = "x2 Coins", Color = Color3.fromRGB(150, 96, 245), EndsAt = data.BoostEnds })
	end
	local events = activeEvents()
	for _, ev in events do
		table.insert(entries, { Key = "Event_" .. ev.Def.Id, Icon = ev.Def.Icon, Text = ev.Def.Name, Color = ev.Def.Color, EndsAt = ev.EndsAt })
	end

	local mutations = {}
	local stormColor = nil
	local crazy = nil
	for _, ev in events do
		stormColor = stormColor or ev.Def.Color
		if ev.Def.Crazy then
			crazy = crazy or ev.Def.Id
		end
		for _, id in ev.Def.Mutations or {} do
			if not table.find(mutations, id) then
				table.insert(mutations, id)
			end
		end
	end

	-- countdown to the next random crazy event
	local incoming = GameState:GetAttribute("CrazyIncoming")
	local nextCrazy = GameState:GetAttribute("NextCrazy")
	if type(incoming) == "string" and incoming ~= "" and Config.EventById[incoming] then
		local def = Config.EventById[incoming]
		table.insert(entries, { Key = "Incoming", Icon = def.Icon, Text = def.Name .. " in", Color = def.Color, EndsAt = GameState:GetAttribute("CrazyIncomingAt") })
	elseif not crazy and GameState:GetAttribute("CrazyAuto") == true and type(nextCrazy) == "number" and nextCrazy > serverNow() then
		table.insert(entries, { Key = "NextCrazy", Icon = "🎲", Text = "Crazy event in", Color = C.Slate, EndsAt = nextCrazy })
	end
	Hud.setBoosts(entries)

	Effects.setStorm(#events > 0, stormColor)
	Effects.setEventMusic(#events > 0, crazy)
	CrazyFX.setActive(crazy)
	Runner.setMutations(mutations)
end

GameState.AttributeChanged:Connect(function()
	refreshBoosts()
end)
task.spawn(function()
	while true do
		task.wait(1)
		refreshBoosts()
	end
end)

Notify.OnClientEvent:Connect(function(kind: string, payload)
	payload = payload or {}
	if kind == "Announcement" then
		Hud.announce((if payload.Global then "🌍 " else "📢 ") .. tostring(payload.From), tostring(payload.Text), C.Yellow)
		systemChat("[ANNOUNCEMENT] " .. tostring(payload.Text))
		Effects.play("Notify", 0.9)
	elseif kind == "EventStarted" then
		local def = Config.EventById[payload.Id]
		if def then
			Hud.announce(def.Icon .. " " .. string.upper(def.Name), def.Desc .. "  (" .. tostring(payload.Minutes) .. " min, by " .. tostring(payload.By) .. ")", def.Color)
			systemChat(def.Name .. " started by " .. tostring(payload.By) .. "!")
			Effects.play("Notify", 1.2)
		end
		refreshBoosts()
	elseif kind == "EventEnded" then
		local def = Config.EventById[payload.Id]
		if def then
			Hud.toast(def.Name .. " is over", C.Slate)
		end
		refreshBoosts()
	elseif kind == "Purchased" then
		Hud.toast("Thank you! " .. tostring(payload.Icon or "") .. " " .. tostring(payload.Name) .. " received!", C.Green)
		Effects.play("Purchase", 1.2)
	elseif kind == "Gift" then
		Hud.announce("🎁 GIFT", tostring(payload.Text), C.Green)
		Effects.play("Purchase", 1.3)
	elseif kind == "PetGranted" and type(payload.Pets) == "table" then
		local first = Pets.ById[payload.Pets[1]]
		task.spawn(function()
			PetsUI.Busy = true
			PetsUI.playHatch(if first then first.Egg else "Aurora", payload.Pets, {})
			PetsUI.Busy = false
		end)
	elseif kind == "CrazyIncoming" then
		local def = Config.EventById[payload.Id]
		if def and type(payload.At) == "number" then
			Hud.crazyCountdown(def.Icon, def.Name, def.Color, payload.At)
			systemChat(def.Icon .. " " .. string.upper(def.Name) .. " INCOMING!")
		end
		refreshBoosts()
	elseif kind == "Meteor" and typeof(payload.Pos) == "Vector3" then
		CrazyFX.meteor(payload.Pos, (tonumber(payload.At) or serverNow()) - serverNow(), 7)
	elseif kind == "Shard" then
		Hud.toast("☄️ Meteor shard! +" .. Config.Commas(tonumber(payload.Coins) or 0) .. " coins", Color3.fromRGB(255, 110, 40))
		Effects.play("Shard", 1.4)
	end
end)

----------------------------------------------------------------------
-- Freeze the character while the snowball is out
----------------------------------------------------------------------
local controls = nil
task.spawn(function()
	local ok, result = pcall(function()
		local module = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 10)
		return (require :: any)(module):GetControls()
	end)
	if ok then
		controls = result
	end
end)

local frozen = false
local function freeze(on: boolean)
	frozen = on
	if controls then
		if on then
			controls:Disable()
		else
			controls:Enable()
		end
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		root.Anchored = on
	end
end

player.CharacterAdded:Connect(function(character)
	if frozen then
		local root = character:WaitForChild("HumanoidRootPart", 5)
		if root then
			root.Anchored = true
		end
	end
end)

----------------------------------------------------------------------
-- Game flow: Idle -> Charge -> Rolling -> Result
----------------------------------------------------------------------
local mode = "Idle"
local power = 0
local powerDir = 1
local charging = false

local prompt: ProximityPrompt? = nil
local lobby = Workspace:WaitForChild("Lobby", 10)
local pad = lobby and lobby:FindFirstChild("StartPad", true)
if pad then
	prompt = pad:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local function setMode(newMode: string)
	mode = newMode
	if prompt then
		prompt.Enabled = newMode == "Idle"
	end
end

local function startCharge()
	if mode ~= "Idle" and mode ~= "Result" then
		return
	end
	setMode("Starting")
	Panels.closeAll()
	UpgradeTree.close()
	local stats = StartRun:InvokeServer()
	if not stats or not data then
		setMode("Idle")
		errorToast("Still loading, try again!")
		return
	end
	freeze(true)
	Runner.prepare(stats, data.Skin)
	power = 0
	powerDir = 1
	charging = false
	Hud.setPower(0, false)
	Hud.setMode("Charge")
	setMode("Charge")
end

local function backToLobby()
	Panels.hideResult()
	Runner.stop()
	freeze(false)
	Hud.setMode("Idle")
	setMode("Idle")
end

local function cancelCharge()
	if mode ~= "Charge" then
		return
	end
	backToLobby()
end

local function launch()
	if mode ~= "Charge" then
		return
	end
	charging = false
	Runner.launch(math.max(0.05, power))
	Hud.setMode("Rolling")
	setMode("Rolling")
end

local function turbo()
	if mode ~= "Rolling" or not data then
		return
	end
	if (data.Turbos or 0) <= 0 then
		buyRobux("Product", "Turbo5")
		return
	end
	if not Runner.canTurbo() then
		return
	end
	-- fire straight away so it feels instant; the server takes one off the count
	data.Turbos -= 1
	Hud.setTurbos(data.Turbos)
	Runner.turbo()
	Hud.turboFired()
	task.spawn(function()
		UseTurbo:InvokeServer()
	end)
end
Hud.Callbacks.Turbo = turbo

Runner.OnFinish = function(report)
	setMode("Finishing")
	task.spawn(function()
		task.wait(0.6)
		local result = FinishRun:InvokeServer(report)
		if not result then
			result = { Earned = 0, NewBest = false, Distance = report.Distance, Smashed = report.Smashed, Combo = report.BestCombo }
		end
		if result.NewBest and result.Earned > 0 then
			Effects.play("NewBest", 1)
		end
		if (result.Candy or 0) > 0 then
			Hud.toast("+" .. result.Candy .. " 🍬 candy!", Color3.fromRGB(255, 140, 30))
		end
		if (result.Presents or 0) > 0 then
			Hud.toast("+" .. result.Presents .. " 🎁 presents!", Config.Currencies.Presents.Color)
		end
		Hud.setMode("Result")
		setMode("Result")
		Panels.showResult(result, function()
			Panels.hideResult()
			startCharge()
		end, backToLobby)
	end)
end

----------------------------------------------------------------------
-- HUD / menu callbacks
----------------------------------------------------------------------
Hud.Callbacks.Roll = startCharge
Hud.Callbacks.CancelCharge = cancelCharge
Hud.Callbacks.Upgrade = function()
	if mode == "Idle" then
		Panels.closeAll()
		UpgradeTree.open()
		Hud.setMode("Tree")
	end
end
Hud.Callbacks.Menu = function(name: string)
	if mode ~= "Idle" then
		return
	end
	if name == "Upgrades" then
		Hud.Callbacks.Upgrade()
	else
		Panels.open(name)
	end
end

UpgradeTree.OnClosed = function()
	if mode == "Idle" then
		Hud.setMode("Idle")
	end
end

UpgradeTree.OnBuy = function(nodeId: string)
	local ok, message = BuyUpgrade:InvokeServer(nodeId)
	if ok then
		UpgradeTree.celebrate(nodeId)
		Effects.play("Purchase", 1.5)
	else
		errorToast(message or "Can't buy that yet")
	end
end

Panels.Callbacks.SetSetting = function(key: string, value: boolean)
	Effects.Settings[key] = value
	Panels.refreshSettings()
	SetSetting:FireServer(key, value)
	Effects.applyMusic()
end

Panels.Callbacks.BuySkin = function(id: string)
	local owned = data and data.Skins[id]
	local ok, message = BuySkin:InvokeServer(id)
	if ok then
		Effects.play("Purchase", 1.4)
		Hud.toast(if owned then "Equipped!" else "Unlocked & equipped!", C.Green)
	else
		errorToast(message or "Can't buy that yet")
	end
end

Panels.Callbacks.Rebirth = function()
	local ok, message = DoRebirth:InvokeServer()
	if ok then
		Effects.play("Purchase", 0.8)
		Hud.toast("Reborn! Coins are worth more now.", C.Purple)
		Panels.closeAll()
	else
		errorToast(message or "Not yet!")
	end
end

Panels.Callbacks.Admin = function(action: string, args)
	local ok, message = AdminAction:InvokeServer(action, args)
	if ok then
		if type(message) ~= "table" then
			Hud.toast(message or "Done!", C.Green)
			Effects.play("Click", 1.3)
		end
	else
		errorToast(message or "That didn't work")
	end
	return ok, message
end

if prompt then
	ProximityPromptService.PromptTriggered:Connect(function(triggered)
		if triggered == prompt then
			startCharge()
		end
	end)
end

----------------------------------------------------------------------
-- Pets, eggs, daily rewards, codes
----------------------------------------------------------------------
PetsUI.BallTarget = Runner.getBall

local function newPetsAmong(results, before)
	local fresh = {}
	for _, id in results do
		if not before[id] then
			fresh[id] = true
		end
	end
	return fresh
end

local function snapshotIndex()
	local copy = {}
	if data then
		for id in data.Index do
			copy[id] = true
		end
	end
	return copy
end

PetsUI.Callbacks.Hatch = function(eggId: string, count: number, fast: boolean?): boolean
	if PetsUI.Busy or mode ~= "Idle" then
		return false
	end
	PetsUI.Busy = true
	local before = snapshotIndex()
	local ok, result = HatchEgg:InvokeServer(eggId, count)
	if ok and type(result) == "table" then
		PetsUI.playHatch(eggId, result, newPetsAmong(result, before), fast)
	elseif result then
		errorToast(result)
	end
	PetsUI.Busy = false
	return ok == true
end

PetsUI.Callbacks.Action = function(action: string, uid: string?)
	local ok, message = PetAction:InvokeServer(action, uid)
	if ok then
		Effects.play("Click", 1.3)
	elseif message then
		errorToast(message)
	end
end

PetsUI.Callbacks.BuyPass = function(key: string)
	buyRobux("Pass", key)
end

local function showRewardPet(eggId: string?, petId: string?, before)
	if petId and eggId then
		PetsUI.Busy = true
		PetsUI.playHatch(eggId, { petId }, newPetsAmong({ petId }, before))
		PetsUI.Busy = false
	end
end

DailyUI.Callbacks.Claim = function()
	local before = snapshotIndex()
	local ok, result = ClaimDaily:InvokeServer()
	if ok and type(result) == "table" then
		Effects.play("Purchase", 1.2)
		Hud.toast("Day " .. result.Day .. " reward claimed! 🎁", C.Green)
		local reward = Config.Daily[result.Day]
		if result.Pet then
			Panels.closeAll()
			showRewardPet(reward and reward.Egg, result.Pet, before)
		end
	else
		errorToast(result or "Can't claim yet")
	end
end

DailyUI.Callbacks.Redeem = function(code: string)
	if code == "" then
		return
	end
	local before = snapshotIndex()
	local ok, result = RedeemCode:InvokeServer(code)
	if ok and type(result) == "table" then
		Effects.play("Purchase", 1.3)
		Hud.toast("Code redeemed! 🎉", C.Green)
		if result.Pet then
			Panels.closeAll()
			showRewardPet(result.Reward and result.Reward.Egg, result.Pet, before)
		end
	else
		errorToast(result or "That code doesn't work")
	end
end

-- open the Daily panel once on join if a reward is waiting
task.spawn(function()
	while not data do
		task.wait(0.5)
	end
	task.wait(2.5)
	local _, can = DailyUI.status(data)
	if can and mode == "Idle" and not Panels.anyOpen() then
		Panels.open("Daily")
	end
end)

-- Halloween evening look
if Config.Halloween.Enabled and Config.Halloween.NightLook then
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 17.6
	Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(120, 90, 140)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 120, 170)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Color = Color3.fromRGB(255, 170, 120)
		atmosphere.Decay = Color3.fromRGB(120, 70, 150)
		atmosphere.Density = 0.32
	end
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if cc then
		cc.TintColor = Color3.fromRGB(255, 235, 225)
	end
end

-- Winter: cosy blue evening with warm lights
if Config.Winter.Enabled and Config.Winter.NightLook and not (Config.Halloween.Enabled and Config.Halloween.NightLook) then
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 17.8
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(110, 125, 170)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 165, 210)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Color = Color3.fromRGB(190, 210, 255)
		atmosphere.Decay = Color3.fromRGB(90, 110, 190)
		atmosphere.Density = 0.3
	end
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if cc then
		cc.TintColor = Color3.fromRGB(240, 245, 255)
	end
end
-- remember the seasonal look so crazy events can restore it
CrazyFX.captureBase()

----------------------------------------------------------------------
-- Input
----------------------------------------------------------------------
local function isChargeInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
		or input.KeyCode == Enum.KeyCode.Space
		or input.KeyCode == Enum.KeyCode.ButtonA
end

UserInputService.InputBegan:Connect(function(input, processed)
	if mode == "Charge" and isChargeInput(input) and not processed then
		charging = true
		return
	end
	if processed then
		return
	end
	local key = input.KeyCode
	if mode == "Idle" and not Panels.anyOpen() and not UpgradeTree.IsOpen then
		if key == Enum.KeyCode.E and not PetsUI.NearEgg then
			startCharge()
		elseif key == Enum.KeyCode.U then
			Hud.Callbacks.Upgrade()
		end
	elseif UpgradeTree.IsOpen and key == Enum.KeyCode.U then
		UpgradeTree.close()
	elseif mode == "Rolling" and (key == Enum.KeyCode.T or key == Enum.KeyCode.ButtonY) then
		turbo()
	elseif mode == "Result" then
		if key == Enum.KeyCode.R then
			Panels.hideResult()
			startCharge()
		elseif key == Enum.KeyCode.Q then
			backToLobby()
		end
	elseif mode == "Charge" and key == Enum.KeyCode.X then
		cancelCharge()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if mode == "Charge" and charging and isChargeInput(input) then
		launch()
	end
end)

----------------------------------------------------------------------
-- Frame loop (runs right after the default camera update)
----------------------------------------------------------------------
RunService:BindToRenderStep("SnowballSmash", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if mode == "Charge" then
		if charging then
			if hasPass("PerfectPush") and Effects.Settings.PerfectPush ~= false then
				-- Perfect Push pass: fills fast and stays at MAX
				power = math.min(1, power + dt * 4)
			else
				-- fills in about a second, then swings so timing matters
				power += powerDir * dt * 0.95
				if power >= 1 then
					power = 1
					powerDir = -1
				elseif power <= 0.35 and powerDir < 0 then
					powerDir = 1
				end
			end
		end
		Hud.setPower(power, charging)
	end
	if Runner.State ~= "Idle" then
		Runner.update(dt)
	end
end)

-- Show the course from the start so the lobby looks alive
refreshPasses()
Runner.resetCourse({})
refreshBoosts()
