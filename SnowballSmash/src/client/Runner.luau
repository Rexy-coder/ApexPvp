--!nonstrict
-- Snowball Smash: the run itself. The snowball is simulated on the client
-- along the mountain slope (no physics jitter), grows as it rolls, smashes
-- everything in its way and the camera chases it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local Hud = require(script.Parent:WaitForChild("Hud"))

local P = Config.Physics
local player = Players.LocalPlayer

local Runner = {}
Runner.State = "Idle" -- Idle | Charge | Rolling | Done
Runner.OnFinish = function(_report: { [string]: number }) end

----------------------------------------------------------------------
-- Slope geometry (read from the Course folder's attributes)
----------------------------------------------------------------------
local course = Workspace:WaitForChild("Course")
local P0 = course:GetAttribute("SlopeOrigin") :: Vector3
local ANGLE = math.rad(course:GetAttribute("SlopeAngle") :: number)
local LENGTH = course:GetAttribute("SlopeLength") :: number
local WIDTH = course:GetAttribute("SlopeWidth") :: number
local START_S = (course:GetAttribute("StartOffset") :: number?) or -16

local RIGHT = Vector3.new(1, 0, 0)
local DOWN = Vector3.new(0, -math.sin(ANGLE), -math.cos(ANGLE)) -- forward, down the slope
local NORMAL = Vector3.new(0, math.cos(ANGLE), -math.sin(ANGLE))
local FLAT = Vector3.new(0, 0, -1)
local SLOPE_CF = CFrame.fromMatrix(P0, RIGHT, NORMAL)

local function surface(s: number, x: number): (Vector3, Vector3, Vector3)
	if s < 0 then
		return P0 + FLAT * s + RIGHT * x, Vector3.yAxis, FLAT
	end
	return P0 + DOWN * s + RIGHT * x, NORMAL, DOWN
end

local function toSlope(p: Vector3): (number, number, number)
	local l = SLOPE_CF:PointToObjectSpace(p)
	return -l.Z, l.X, l.Y -- s, x, height
end

----------------------------------------------------------------------
-- Course records (measured once from the template)
----------------------------------------------------------------------
local template = ReplicatedStorage:WaitForChild("CourseTemplate")
local smashTemplate = template:WaitForChild("Smashables")
local pickupTemplate = template:FindFirstChild("Pickups")

type Obstacle = {
	S0: number,
	S1: number,
	X0: number,
	X1: number,
	Top: number,
	Toughness: number,
	Coins: number,
	Kind: string,
	Template: Instance,
	Model: Instance?,
	Smashed: boolean,
}
type Pickup = { S: number, X: number, Template: BasePart, Part: BasePart?, Base: CFrame, Taken: boolean }
type Pad = { S0: number, S1: number, X0: number, X1: number, Top: number, Kind: string, Part: BasePart }

local function partsOf(inst: Instance): { BasePart }
	local list = {}
	if inst:IsA("BasePart") then
		table.insert(list, inst)
	end
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end

local function measure(inst: Instance): (number, number, number, number, number)
	local s0, s1, x0, x1, top = math.huge, -math.huge, math.huge, -math.huge, -math.huge
	for _, part in partsOf(inst) do
		local half = part.Size / 2
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local corner = part.CFrame:PointToWorldSpace(Vector3.new(half.X * sx, half.Y * sy, half.Z * sz))
					local s, x, h = toSlope(corner)
					s0 = math.min(s0, s)
					s1 = math.max(s1, s)
					x0 = math.min(x0, x)
					x1 = math.max(x1, x)
					top = math.max(top, h)
				end
			end
		end
	end
	return s0, s1, x0, x1, top
end

local obstacles: { Obstacle } = {}
for _, child in smashTemplate:GetChildren() do
	local s0, s1, x0, x1, top = measure(child)
	if s0 < math.huge then
		table.insert(obstacles, {
			S0 = s0,
			S1 = s1,
			X0 = x0,
			X1 = x1,
			Top = top,
			Toughness = (child:GetAttribute("Toughness") :: number?) or 1,
			Coins = (child:GetAttribute("Coins") :: number?) or 10,
			Kind = (child:GetAttribute("Kind") :: string?) or child.Name,
			Template = child,
			Model = nil,
			Smashed = false,
		})
	end
end
table.sort(obstacles, function(a, b)
	return a.S0 < b.S0
end)

local pickups: { Pickup } = {}
if pickupTemplate then
	for _, child in pickupTemplate:GetChildren() do
		if child:IsA("BasePart") then
			local s, x = toSlope(child.Position)
			table.insert(pickups, { S = s, X = x, Template = child, Part = nil, Base = child.CFrame, Taken = false })
		end
	end
	table.sort(pickups, function(a, b)
		return a.S < b.S
	end)
end

local pads: { Pad } = {}
local padFolder = course:FindFirstChild("Pads")
if padFolder then
	for _, child in padFolder:GetDescendants() do
		if child:IsA("BasePart") and child:GetAttribute("PadType") then
			local s0, s1, x0, x1, top = measure(child)
			table.insert(pads, { S0 = s0, S1 = s1, X0 = x0, X1 = x1, Top = top, Kind = child:GetAttribute("PadType") :: string, Part = child })
		end
	end
end

----------------------------------------------------------------------
-- Local copy of the course (each player smashes their own copy)
----------------------------------------------------------------------
local localCourse: Folder? = nil
local courseDirty = true

function Runner.resetCourse()
	if localCourse then
		localCourse:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "LocalCourse"
	for _, o in obstacles do
		local clone = o.Template:Clone()
		clone.Parent = folder
		o.Model = clone
		o.Smashed = false
	end
	for _, p in pickups do
		local clone = p.Template:Clone()
		clone.Parent = folder
		p.Part = clone
		p.Taken = false
	end
	folder.Parent = Workspace
	localCourse = folder
	courseDirty = false
end

----------------------------------------------------------------------
-- Snowball visual
----------------------------------------------------------------------
local CLUMP_DIRS = {
	Vector3.new(1, 0.3, 0.2).Unit,
	Vector3.new(-0.6, 0.7, 0.4).Unit,
	Vector3.new(0.1, -0.8, 0.6).Unit,
	Vector3.new(-0.3, 0.2, -1).Unit,
	Vector3.new(0.7, -0.4, -0.6).Unit,
	Vector3.new(-0.9, -0.5, -0.1).Unit,
	Vector3.new(0.2, 1, -0.3).Unit,
}

type Ball = {
	Model: Model,
	Body: Part,
	Clumps: { Part },
	Carrier: Part,
	Spray: ParticleEmitter,
	Trail: Trail,
}

local ball: Ball? = nil

local function makeBall(skin: Config.Skin): Ball
	local model = Instance.new("Model")
	model.Name = "Snowball"

	local function basePart(name: string): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Shape = Enum.PartType.Ball
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end

	local body = basePart("Body")
	body.Color = skin.Color
	body.Material = skin.Material
	body.Transparency = skin.Transparency
	body.Size = Vector3.one * P.StartRadius * 2

	local clumps = {}
	for i = 1, #CLUMP_DIRS do
		local c = basePart("Clump" .. i)
		c.Color = skin.Clump
		c.Material = if skin.Material == Enum.Material.Neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
		c.CastShadow = false
		table.insert(clumps, c)
	end

	local carrier = Instance.new("Part")
	carrier.Name = "Carrier"
	carrier.Anchored = true
	carrier.CanCollide = false
	carrier.CanQuery = false
	carrier.CanTouch = false
	carrier.Transparency = 1
	carrier.Size = Vector3.one
	carrier.Parent = model

	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(-1, 0, 0)
	a0.Parent = carrier
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(1, 0, 0)
	a1.Parent = carrier
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(skin.Trail)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Lifetime = 0.6
	trail.FaceCamera = true
	trail.LightEmission = 0.3
	trail.Parent = carrier

	local spray = Instance.new("ParticleEmitter")
	spray.Color = ColorSequence.new(skin.Trail)
	spray.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0.1) })
	spray.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	spray.Lifetime = NumberRange.new(0.4, 0.8)
	spray.Speed = NumberRange.new(6, 14)
	spray.SpreadAngle = Vector2.new(70, 70)
	spray.Acceleration = Vector3.new(0, -30, 0)
	spray.EmissionDirection = Enum.NormalId.Top
	spray.Rate = 0
	spray.Parent = a0

	model.PrimaryPart = body
	model.Parent = Workspace
	return { Model = model, Body = body, Clumps = clumps, Carrier = carrier, Spray = spray, Trail = trail }
end

----------------------------------------------------------------------
-- Run state
----------------------------------------------------------------------
type RunState = {
	S: number,
	X: number,
	VX: number,
	H: number,
	VH: number,
	RampH: number,
	V: number,
	R: number,
	Roll: number,
	Combo: number,
	LastSmash: number,
	BestCombo: number,
	Smashed: number,
	Coins: number,
	PadsUsed: { [Pad]: boolean },
	Stats: Config.Stats,
	Time: number,
	Stopped: number,
	FirstObstacle: number,
	FirstPickup: number,
}

local run: RunState? = nil
local camPos: Vector3? = nil
local camLook: Vector3? = nil

local function newRun(stats: Config.Stats): RunState
	return {
		S = START_S,
		X = 0,
		VX = 0,
		H = 0,
		VH = 0,
		RampH = 0,
		V = 0,
		R = P.StartRadius,
		Roll = 0,
		Combo = 0,
		LastSmash = -100,
		BestCombo = 0,
		Smashed = 0,
		Coins = 0,
		PadsUsed = {},
		Stats = stats,
		Time = 0,
		Stopped = 0,
		FirstObstacle = 1,
		FirstPickup = 1,
	}
end

----------------------------------------------------------------------
-- Steering input: keyboard, gamepad stick, or touching either side
----------------------------------------------------------------------
local stickX = 0
local touches: { [InputObject]: number } = {}

UserInputService.InputChanged:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Thumbstick1 then
		stickX = if math.abs(input.Position.X) > 0.2 then input.Position.X else 0
	end
end)
UserInputService.TouchStarted:Connect(function(input, processed)
	if not processed then
		touches[input] = input.Position.X
	end
end)
UserInputService.TouchMoved:Connect(function(input)
	if touches[input] then
		touches[input] = input.Position.X
	end
end)
UserInputService.TouchEnded:Connect(function(input)
	touches[input] = nil
end)

local function steerInput(): number
	local v = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		v -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		v += 1
	end
	v += stickX
	local camera = Workspace.CurrentCamera
	if camera then
		local half = camera.ViewportSize.X / 2
		for _, x in touches do
			v += if x < half then -1 else 1
		end
	end
	return math.clamp(v, -1, 1)
end

----------------------------------------------------------------------
-- Smashing
----------------------------------------------------------------------
local function breakApart(o: Obstacle, st: RunState, center: Vector3)
	local model = o.Model
	if not model then
		return
	end
	local parts = partsOf(model)
	for _, part in parts do
		part.Anchored = false
		part.CanCollide = true
		part.CanQuery = false
		part.CanTouch = false
		local away = (part.Position - center)
		away = Vector3.new(away.X, 0, away.Z)
		if away.Magnitude > 0.01 then
			away = away.Unit
		end
		part.AssemblyLinearVelocity = DOWN * (st.V * 0.8 + 12)
			+ Vector3.yAxis * (22 + math.random() * 26)
			+ away * (10 + math.random() * 20)
		part.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 18
	end
	task.delay(1.3, function()
		for _, part in parts do
			if part.Parent then
				TweenService:Create(part, TweenInfo.new(0.6), { Transparency = 1 }):Play()
			end
		end
	end)
	Debris:AddItem(model, 2.1)
	o.Model = nil
end

local function smash(o: Obstacle, st: RunState, center: Vector3)
	o.Smashed = true
	local stats = st.Stats
	local power = (st.R / P.StartRadius) * stats.Smash
	local loss = o.Toughness * P.SmashLoss / power
	st.V = math.max(0, st.V - loss)

	if st.Time - st.LastSmash <= stats.ComboTime then
		st.Combo += 1
	else
		st.Combo = 1
	end
	st.LastSmash = st.Time
	st.BestCombo = math.max(st.BestCombo, st.Combo)

	local crit = math.random() < stats.Crit
	local mult = math.min(st.Combo, P.MaxCombo)
	local sizeBonus = 1 + (st.R - P.StartRadius) / P.SizeBonusDiv
	local coins = o.Coins * mult * sizeBonus * stats.CoinMult * (if crit then 2 else 1)
	coins = math.floor(coins + 0.5)
	st.Coins += coins
	st.Smashed += 1
	st.R = math.min(stats.MaxRadius, st.R + 0.12)

	-- feedback
	local midS = (o.S0 + o.S1) / 2
	local midX = (o.X0 + o.X1) / 2
	local base = surface(midS, midX)
	local popPos = base + NORMAL * (o.Top + 2)
	Effects.worldText(popPos, "+" .. Config.Commas(coins), if crit then Color3.fromRGB(255, 170, 40) else Color3.fromRGB(255, 225, 70), if crit then 80 else 60)
	Effects.burst(base + NORMAL * math.min(o.Top, 6), Color3.fromRGB(240, 248, 255), 14 + math.floor(o.Toughness * 3), 1.6)
	Effects.play("Smash", 0.9 + math.random() * 0.3, 0.6)
	Effects.shake(0.35 + o.Toughness * 0.12)
	Hud.setRunCoins(st.Coins)
	Hud.combo(math.min(st.Combo, P.MaxCombo), stats.ComboTime)
	if crit then
		Hud.critical()
	end
	breakApart(o, st, center)
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------
local stats0: Config.Stats? = nil

-- Put a fresh snowball on the start pad and point the camera down the hill.
function Runner.prepare(stats: Config.Stats, skinId: string)
	if courseDirty then
		Runner.resetCourse()
	end
	if ball then
		ball.Model:Destroy()
	end
	stats0 = stats
	ball = makeBall(Config.SkinById[skinId] or Config.SkinById.Classic)
	run = newRun(stats)
	camPos = nil
	camLook = nil
	Runner.State = "Charge"
	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Scriptable
	end
	Hud.setRunCoins(0, true)
	Hud.setDistance(0)
	Hud.setSpeed(0)
end

function Runner.launch(power: number)
	local st = run
	if not st or Runner.State ~= "Charge" then
		return
	end
	courseDirty = true
	st.V = math.max(8, st.Stats.Launch * power)
	Runner.State = "Rolling"
	Effects.play("Launch", 1, 0.8)
	Effects.shake(0.6)
end

function Runner.stop()
	if ball then
		ball.Model:Destroy()
		ball = nil
	end
	run = nil
	Runner.State = "Idle"
	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
		TweenService:Create(camera, TweenInfo.new(0.4), { FieldOfView = 70 }):Play()
	end
	Hud.setSpeed(0)
end

local function finish(st: RunState)
	Runner.State = "Done"
	Runner.OnFinish({
		Distance = math.max(0, math.floor(st.S)),
		Smashed = st.Smashed,
		BestCombo = st.BestCombo,
		SmashCoins = st.Coins,
	})
end

----------------------------------------------------------------------
-- Per-frame update (called from Main, bound after the camera)
----------------------------------------------------------------------
local spinT = 0

function Runner.update(dt: number)
	local st = run
	local b = ball
	if not st or not b then
		return
	end
	dt = math.min(dt, 1 / 20)
	local stats = st.Stats

	if Runner.State == "Rolling" then
		st.Time += dt

		-- steering
		local steer = steerInput()
		local steerSpeed = stats.Steer * (if st.H > 0 then 0.7 else 1)
		st.VX += (steer * steerSpeed - st.VX) * (1 - math.exp(-dt * 8))
		local halfW = WIDTH / 2 - st.R - 1
		st.X = math.clamp(st.X + st.VX * dt, -halfW, halfW)

		-- forward motion
		local airborne = st.H > 0 or st.VH > 0
		if airborne then
			st.VH -= P.Gravity * dt
			st.H += st.VH * dt
			if st.H <= 0 then
				st.H = 0
				st.VH = 0
				Effects.play("Land", 0.8, 0.7)
				Effects.shake(0.8)
				local p = surface(st.S, st.X)
				Effects.burst(p, Color3.fromRGB(240, 248, 255), 26, 2)
			end
		else
			st.V -= stats.Friction * dt
		end
		st.V = math.clamp(st.V, 0, P.MaxSpeed)
		local ds = st.V * dt
		st.S += ds
		if not airborne then
			st.R = math.min(stats.MaxRadius, st.R + stats.Growth * ds)
		end
		st.Roll += ds / st.R

		-- boost pads and ramps
		st.RampH = 0
		for _, pad in pads do
			local inLane = st.X + st.R * 0.5 >= pad.X0 and st.X - st.R * 0.5 <= pad.X1
			if not st.PadsUsed[pad] and st.H <= 0 and inLane and st.S >= pad.S0 and st.S <= pad.S1 then
				if pad.Kind == "Boost" then
					st.PadsUsed[pad] = true
					st.V = math.min(P.MaxSpeed, st.V + stats.Boost)
					Effects.play("Boost", 1.1, 0.8)
					Effects.shake(0.5)
				elseif pad.Kind == "Ramp" then
					-- ride up the ramp, then fly off the lip
					local frac = (st.S - pad.S0) / math.max(1, pad.S1 - pad.S0)
					st.RampH = frac * pad.Top
					if frac >= 0.92 then
						st.PadsUsed[pad] = true
						st.H = math.max(0.01, st.RampH)
						st.RampH = 0
						st.VH = P.RampLift * stats.Air + st.V * 0.1
						Effects.play("Launch", 1.2, 0.7)
					end
				end
			end
		end

		local point, up = surface(st.S, st.X)
		local center = point + up * (st.R + st.H + st.RampH)

		-- smash obstacles
		while st.FirstObstacle <= #obstacles and obstacles[st.FirstObstacle].S1 < st.S - 60 do
			st.FirstObstacle += 1
		end
		for i = st.FirstObstacle, #obstacles do
			local o = obstacles[i]
			if o.S0 > st.S + st.R then
				break
			end
			if not o.Smashed and o.S1 > st.S - st.R and st.X + st.R * 0.85 > o.X0 and st.X - st.R * 0.85 < o.X1 and st.H < o.Top then
				smash(o, st, center)
			end
		end

		-- coins
		while st.FirstPickup <= #pickups and pickups[st.FirstPickup].S < st.S - 30 do
			st.FirstPickup += 1
		end
		for i = st.FirstPickup, #pickups do
			local p = pickups[i]
			if p.S > st.S + 220 then
				break
			end
			local part = p.Part
			if not p.Taken and part then
				if math.abs(p.S - st.S) < st.R + 1.5 and math.abs(p.X - st.X) < st.R + 1.5 and part.Position.Y < center.Y + st.R + 3 then
					p.Taken = true
					local value = math.floor(P.PickupValue * stats.CoinMult + 0.5)
					st.Coins += value
					Hud.setRunCoins(st.Coins)
					Effects.play("Coin", 1.3 + math.random() * 0.3, 0.4)
					TweenService:Create(part, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
						Size = Vector3.new(0.1, 0.1, 0.1),
						CFrame = part.CFrame + Vector3.yAxis * 4,
					}):Play()
					Debris:AddItem(part, 0.3)
					p.Part = nil
				end
			end
		end

		-- end of the run
		if st.S >= LENGTH - st.R - 2 then
			st.S = LENGTH - st.R - 2
			st.V = 0
		end
		if st.V <= P.StopSpeed and st.H <= 0 then
			st.Stopped += dt
			st.V = 0
			if st.Stopped > 0.35 then
				finish(st)
			end
		elseif st.Time > P.MaxRunTime then
			finish(st)
		end

		Hud.setDistance(math.max(0, st.S))
		Hud.setSpeed(st.V / 120)
		Effects.speedLines(dt, st.V)
	end

	-- spin nearby coins
	spinT += dt
	for i = st.FirstPickup, math.min(#pickups, st.FirstPickup + 40) do
		local p = pickups[i]
		if p.Part and not p.Taken then
			p.Part.CFrame = p.Base * CFrame.Angles(0, spinT * 3, 0)
		end
	end

	-- place the snowball
	local point, up, forward = surface(st.S, st.X)
	local center = point + up * (st.R + st.H + st.RampH)
	local rot = CFrame.fromAxisAngle(-RIGHT, st.Roll) * CFrame.fromAxisAngle(forward, -st.X * 0.05)
	local ballCF = CFrame.new(center) * rot
	b.Body.Size = Vector3.one * st.R * 2
	b.Body.CFrame = ballCF
	for i, c in b.Clumps do
		c.Size = Vector3.one * st.R * 0.55
		c.CFrame = ballCF * CFrame.new(CLUMP_DIRS[i] * st.R * 0.82)
	end
	b.Carrier.CFrame = CFrame.lookAt(point + up * 0.3, point + up * 0.3 + forward)
	for _, a in b.Carrier:GetChildren() do
		if a:IsA("Attachment") then
			a.Position = Vector3.new(math.sign(a.Position.X) * st.R * 0.7, 0, 0)
		end
	end
	b.Spray.Rate = if Runner.State == "Rolling" and st.H <= 0 then math.clamp(st.V * 0.8, 0, 90) else 0
	b.Trail.Enabled = Runner.State == "Rolling" and st.H <= 0.5

	-- camera
	local camera = Workspace.CurrentCamera
	if camera then
		local flatForward = Vector3.new(forward.X, 0, forward.Z).Unit
		local back = 20 + st.R * 2.4
		local height = 9 + st.R * 1.5
		local wantPos = center - flatForward * back + Vector3.yAxis * height
		local wantLook = center + forward * (10 + st.R)
		if not camPos or not camLook then
			camPos = wantPos
			camLook = wantLook
		end
		local cp = (camPos :: Vector3):Lerp(wantPos, 1 - math.exp(-dt * 6))
		local cl = (camLook :: Vector3):Lerp(wantLook, 1 - math.exp(-dt * 10))
		camPos = cp
		camLook = cl
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.lookAt(cp, cl) * Effects.shakeOffset(dt)
		local fov = 70 + math.clamp((st.V - 40) * 0.18, 0, 24)
		camera.FieldOfView += (fov - camera.FieldOfView) * (1 - math.exp(-dt * 4))
	end
end

function Runner.getStats(): Config.Stats?
	return stats0
end

return Runner
