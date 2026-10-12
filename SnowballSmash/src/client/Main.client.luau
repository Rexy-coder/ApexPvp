--!nonstrict
-- Snowball Smash: client entry point. Wires the HUD, menus, upgrade tree and
-- the run together and talks to the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Workspace = game:GetService("Workspace")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local UIKit = require(script:WaitForChild("UIKit"))
local Effects = require(script:WaitForChild("Effects"))
local Hud = require(script:WaitForChild("Hud"))
local Panels = require(script:WaitForChild("Panels"))
local UpgradeTree = require(script:WaitForChild("UpgradeTree"))
local Runner = require(script:WaitForChild("Runner"))

local C = UIKit.Colors

local GetData = Remotes:WaitForChild("GetData") :: RemoteFunction
local DataChanged = Remotes:WaitForChild("DataChanged") :: RemoteEvent
local StartRun = Remotes:WaitForChild("StartRun") :: RemoteFunction
local FinishRun = Remotes:WaitForChild("FinishRun") :: RemoteFunction
local BuyUpgrade = Remotes:WaitForChild("BuyUpgrade") :: RemoteFunction
local BuySkin = Remotes:WaitForChild("BuySkin") :: RemoteFunction
local DoRebirth = Remotes:WaitForChild("Rebirth") :: RemoteFunction
local SetSetting = Remotes:WaitForChild("SetSetting") :: RemoteEvent

----------------------------------------------------------------------
-- Player data
----------------------------------------------------------------------
local data: any = nil

local function apply(newData: any)
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
	Panels.refresh(newData)
	UpgradeTree.refresh(newData)
	Hud.setAlert("Upgrades", UpgradeTree.anyAffordable(newData))
	Hud.setAlert("Shop", Panels.anySkinAffordable(newData))
	Hud.setAlert("Rebirth", Panels.canRebirth(newData))
	Effects.applyMusic()
end

DataChanged.OnClientEvent:Connect(apply)
task.spawn(function()
	apply(GetData:InvokeServer())
end)

----------------------------------------------------------------------
-- Freeze the character while the snowball is out
----------------------------------------------------------------------
local controls: any = nil
task.spawn(function()
	local ok, result = pcall(function()
		local module = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 10)
		return (require(module :: ModuleScript) :: any):GetControls()
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
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.Anchored = on
	end
end

player.CharacterAdded:Connect(function(character)
	if frozen then
		local root = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
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
local course = Workspace:WaitForChild("Course")
local pad = course:FindFirstChild("StartPad", true)
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
		Hud.toast("Still loading, try again!")
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

Runner.OnFinish = function(report)
	setMode("Finishing")
	task.spawn(function()
		task.wait(0.6)
		local result = FinishRun:InvokeServer(report)
		if not result then
			result = { Earned = 0, NewBest = false, Distance = report.Distance, Smashed = report.Smashed, Combo = report.BestCombo }
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
	elseif name == "Index" then
		Hud.toast("Coming soon!", C.Blue)
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
		Effects.play("Buy", 1.5, 0.7)
	else
		Hud.toast(message or "Can't buy that yet")
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
		Effects.play("Buy", 1.4, 0.7)
		Hud.toast(if owned then "Equipped!" else "Unlocked & equipped!", C.Green)
	else
		Hud.toast(message or "Can't buy that yet")
	end
end

Panels.Callbacks.Rebirth = function()
	local ok, message = DoRebirth:InvokeServer()
	if ok then
		Effects.play("Buy", 0.8, 0.8)
		Hud.toast("Reborn! Coins are worth more now.", C.Purple)
		Panels.closeAll()
	else
		Hud.toast(message or "Not yet!")
	end
end

if prompt then
	ProximityPromptService.PromptTriggered:Connect(function(triggered)
		if triggered == prompt then
			startCharge()
		end
	end)
end

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
		if key == Enum.KeyCode.E then
			startCharge()
		elseif key == Enum.KeyCode.U then
			Hud.Callbacks.Upgrade()
		end
	elseif UpgradeTree.IsOpen and key == Enum.KeyCode.U then
		UpgradeTree.close()
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
			-- fills in about a second, then swings so timing matters
			power += powerDir * dt * 0.95
			if power >= 1 then
				power = 1
				powerDir = -1
			elseif power <= 0.35 and powerDir < 0 then
				powerDir = 1
			end
		end
		Hud.setPower(power, charging)
	end
	if Runner.State ~= "Idle" then
		Runner.update(dt)
	end
end)

-- Show the course from the start so the lobby looks alive
Runner.resetCourse()
