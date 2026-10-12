--!nonstrict
-- Snowball Smash: server. Owns player data (coins, upgrades, skins, settings),
-- validates run results and saves everything to a DataStore.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local GetData = Remotes:WaitForChild("GetData") :: RemoteFunction
local DataChanged = Remotes:WaitForChild("DataChanged") :: RemoteEvent
local StartRun = Remotes:WaitForChild("StartRun") :: RemoteFunction
local FinishRun = Remotes:WaitForChild("FinishRun") :: RemoteFunction
local BuyUpgrade = Remotes:WaitForChild("BuyUpgrade") :: RemoteFunction
local BuySkin = Remotes:WaitForChild("BuySkin") :: RemoteFunction
local DoRebirth = Remotes:WaitForChild("Rebirth") :: RemoteFunction
local SetSetting = Remotes:WaitForChild("SetSetting") :: RemoteEvent

----------------------------------------------------------------------
-- Course template: the smashable objects and coins are moved out of the
-- Workspace so every client can spawn its own private copy per run.
----------------------------------------------------------------------
local course = workspace:WaitForChild("Course")
local template = Instance.new("Folder")
template.Name = "CourseTemplate"
for _, name in { "Smashables", "Pickups" } do
	local folder = course:FindFirstChild(name)
	if folder then
		folder.Parent = template
	end
end
template.Parent = ReplicatedStorage

-- Most coins a single run could possibly be worth (used to reject cheated results)
local courseValue = 0
local courseCount = 0
for _, obj in (template:FindFirstChild("Smashables") :: Folder):GetChildren() do
	courseValue += (obj:GetAttribute("Coins") :: number?) or 10
	courseCount += 1
end
local pickups = template:FindFirstChild("Pickups")
local pickupCount = if pickups then #pickups:GetChildren() else 0
local courseLength = (course:GetAttribute("SlopeLength") :: number?) or 2000

----------------------------------------------------------------------
-- Data
----------------------------------------------------------------------
type Data = {
	Coins: number,
	BestEarn: number,
	BestDistance: number,
	BestCombo: number,
	Runs: number,
	TotalSmashed: number,
	TotalEarned: number,
	Rebirths: number,
	Owned: { [string]: boolean },
	Skins: { [string]: boolean },
	Skin: string,
	Settings: { [string]: boolean },
}

local function defaultData(): Data
	return {
		Coins = 0,
		BestEarn = 0,
		BestDistance = 0,
		BestCombo = 0,
		Runs = 0,
		TotalSmashed = 0,
		TotalEarned = 0,
		Rebirths = 0,
		Owned = {},
		Skins = { Classic = true },
		Skin = "Classic",
		Settings = { Music = true, SFX = true, Shake = true, SpeedLines = true, Hints = true },
	}
end

local SETTING_KEYS = { Music = true, SFX = true, Shake = true, SpeedLines = true, Hints = true }

local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("SnowballSmash_v1")
	end)
	if ok then
		store = result
	else
		warn("[SnowballSmash] DataStore unavailable, progress will not save:", result)
	end
end

local profiles: { [Player]: Data } = {}
local loaded: { [Player]: boolean } = {}
local activeRuns: { [Player]: { Started: number } } = {}

local function merge(saved: any): Data
	local data = defaultData()
	if type(saved) ~= "table" then
		return data
	end
	for key, value in saved do
		if (data :: any)[key] ~= nil and type(value) == type((data :: any)[key]) then
			if type(value) == "table" then
				for k, v in value do
					(data :: any)[key][k] = v
				end
			else
				(data :: any)[key] = value
			end
		end
	end
	return data
end

local function save(player: Player)
	local data = profiles[player]
	if not data or not store or not loaded[player] then
		return
	end
	local ok, err = pcall(function()
		(store :: DataStore):SetAsync("p_" .. player.UserId, data)
	end)
	if not ok then
		warn("[SnowballSmash] Save failed for", player.Name, err)
	end
end

local function updateLeaderstats(player: Player)
	local data = profiles[player]
	local stats = player:FindFirstChild("leaderstats")
	if not data or not stats then
		return
	end
	(stats:FindFirstChild("Coins") :: IntValue).Value = math.floor(data.Coins);
	(stats:FindFirstChild("Best") :: IntValue).Value = math.floor(data.BestEarn)
end

local function push(player: Player)
	local data = profiles[player]
	if data then
		DataChanged:FireClient(player, data)
		updateLeaderstats(player)
	end
end

local function statsFor(data: Data)
	return Config.ComputeStats(data.Owned, data.Rebirths, data.Skin)
end

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats
	local best = Instance.new("IntValue")
	best.Name = "Best"
	best.Parent = leaderstats
	leaderstats.Parent = player

	local saved = nil
	if store then
		local ok, result = pcall(function()
			return (store :: DataStore):GetAsync("p_" .. player.UserId)
		end)
		if ok then
			saved = result
			loaded[player] = true
		else
			warn("[SnowballSmash] Load failed for", player.Name, result)
		end
	end
	if player.Parent == nil then
		return
	end
	profiles[player] = merge(saved)
	push(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	profiles[player] = nil
	loaded[player] = nil
	activeRuns[player] = nil
end)

game:BindToClose(function()
	if RunService:IsStudio() then
		task.wait(1)
	end
	for _, player in Players:GetPlayers() do
		task.spawn(save, player)
	end
	task.wait(2)
end)

task.spawn(function()
	while true do
		task.wait(90)
		for _, player in Players:GetPlayers() do
			task.spawn(save, player)
		end
	end
end)

local function waitForData(player: Player): Data?
	local t = 0
	while not profiles[player] and t < 15 and player.Parent do
		t += task.wait(0.1)
	end
	return profiles[player]
end

----------------------------------------------------------------------
-- Remotes
----------------------------------------------------------------------
GetData.OnServerInvoke = function(player)
	return waitForData(player)
end

StartRun.OnServerInvoke = function(player)
	local data = profiles[player]
	if not data then
		return nil
	end
	activeRuns[player] = { Started = os.clock() }
	return statsFor(data)
end

FinishRun.OnServerInvoke = function(player, report: any)
	local data = profiles[player]
	local run = activeRuns[player]
	activeRuns[player] = nil
	if not data or not run or type(report) ~= "table" then
		return nil
	end

	local elapsed = os.clock() - run.Started
	local stats = statsFor(data)
	local P = Config.Physics

	local distance = math.clamp(tonumber(report.Distance) or 0, 0, courseLength)
	distance = math.min(distance, elapsed * P.MaxSpeed * 1.25 + 40)
	local smashed = math.clamp(math.floor(tonumber(report.Smashed) or 0), 0, courseCount)
	local combo = math.clamp(math.floor(tonumber(report.BestCombo) or 0), 0, 999)

	-- Generous upper bound: every object smashed at max combo, max size, always critical.
	local sizeBonusMax = 1 + (stats.MaxRadius - P.StartRadius) / P.SizeBonusDiv
	local cap = (courseValue * P.MaxCombo * sizeBonusMax * 2 + pickupCount * P.PickupValue) * stats.CoinMult
	local smashCoins = math.clamp(tonumber(report.SmashCoins) or 0, 0, cap)
	if smashCoins ~= smashCoins then -- NaN
		smashCoins = 0
	end
	local distanceCoins = distance * P.DistanceCoinRate * stats.CoinMult
	local earned = math.floor(smashCoins + distanceCoins)

	local newBest = earned > data.BestEarn
	data.Coins += earned
	data.TotalEarned += earned
	data.Runs += 1
	data.TotalSmashed += smashed
	data.BestEarn = math.max(data.BestEarn, earned)
	data.BestDistance = math.max(data.BestDistance, math.floor(distance))
	data.BestCombo = math.max(data.BestCombo, combo)
	push(player)

	return {
		Earned = earned,
		NewBest = newBest,
		Distance = math.floor(distance),
		Smashed = smashed,
		Combo = combo,
	}
end

BuyUpgrade.OnServerInvoke = function(player, nodeId: any)
	local data = profiles[player]
	if not data or type(nodeId) ~= "string" then
		return false, "Not ready"
	end
	local ok, reason = Config.CanBuy(data.Owned, nodeId)
	if not ok then
		return false, reason
	end
	local node = Config.Nodes[nodeId]
	if data.Coins < node.Cost then
		return false, "Not enough coins!"
	end
	data.Coins -= node.Cost
	data.Owned[nodeId] = true
	push(player)
	return true, nil
end

BuySkin.OnServerInvoke = function(player, skinId: any)
	local data = profiles[player]
	local skin = if type(skinId) == "string" then Config.SkinById[skinId] else nil
	if not data or not skin then
		return false, "Not ready"
	end
	if not data.Skins[skin.Id] then
		if data.Coins < skin.Price then
			return false, "Not enough coins!"
		end
		data.Coins -= skin.Price
		data.Skins[skin.Id] = true
	end
	data.Skin = skin.Id
	push(player)
	return true, nil
end

DoRebirth.OnServerInvoke = function(player)
	local data = profiles[player]
	if not data then
		return false, "Not ready"
	end
	local cost = Config.RebirthCost(data.Rebirths)
	if data.Coins < cost then
		return false, "You need " .. Config.Commas(cost) .. " coins to rebirth!"
	end
	data.Coins = 0
	data.Owned = {}
	data.Rebirths += 1
	push(player)
	return true, nil
end

SetSetting.OnServerEvent:Connect(function(player, key: any, value: any)
	local data = profiles[player]
	if data and type(key) == "string" and SETTING_KEYS[key] and type(value) == "boolean" then
		data.Settings[key] = value
	end
end)
