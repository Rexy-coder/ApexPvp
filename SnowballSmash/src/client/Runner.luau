--!nonstrict
-- Snowball Smash: the run itself. The snowball is simulated on the client
-- along the endless slope (no physics jitter), grows as it rolls, smashes
-- everything in its way and the camera chases it. Course chunks are built
-- ahead of the ball and removed behind it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CourseGen = require(Shared:WaitForChild("CourseGen"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local CourseBuilder = require(script.Parent:WaitForChild("CourseBuilder"))

local P = Config.Physics
local player = Players.LocalPlayer

local Runner = {}
Runner.State = "Idle" -- Idle | Charge | Rolling | Done
Runner.OnFinish = function(_report) end

local WIDTH = CourseGen.Width
local CHUNK = CourseGen.ChunkLength
local START_S = CourseGen.StartOffset
local RIGHT = CourseGen.Right
local surface = CourseGen.Surface

local AHEAD = 650 -- studs of course kept built in front of the ball
local BEHIND = 120

----------------------------------------------------------------------
-- Course chunks (each player smashes their own copy)
----------------------------------------------------------------------
local courseFolder = Instance.new("Folder")
courseFolder.Name = "LocalCourse"
courseFolder.Parent = Workspace

local chunks = {} -- [index] = CourseBuilder.Built
local mutationOn = false
local courseDirty = true

local function buildChunk(i: number)
	if chunks[i] or i < 0 then
		return
	end
	chunks[i] = CourseBuilder.Build(i, courseFolder, mutationOn)
end

local function dropChunk(i: number)
	local c = chunks[i]
	if c then
		c.Folder:Destroy()
		chunks[i] = nil
	end
end

-- keep chunks around `s` built; build at most `budget` new ones this call
local function streamAround(s: number, budget: number)
	local first = math.max(0, math.floor((s - BEHIND) / CHUNK))
	local last = math.floor((s + AHEAD) / CHUNK)
	for i in chunks do
		if i < first then
			dropChunk(i)
		end
	end
	local built = 0
	for i = first, last do
		if not chunks[i] then
			buildChunk(i)
			built += 1
			if built >= budget then
				return
			end
		end
	end
end

function Runner.resetCourse(mutation: boolean?)
	for i in chunks do
		dropChunk(i)
	end
	mutationOn = mutation == true
	streamAround(0, 99)
	courseDirty = false
end

-- e.g. a Mutation Storm started while standing in the lobby
function Runner.setMutation(on: boolean)
	if on ~= mutationOn and Runner.State == "Idle" then
		Runner.resetCourse(on)
	end
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

local ball = nil

local function makeBall(skin)
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

	-- flames that show while a Turbo is active
	local flames = Instance.new("ParticleEmitter")
	flames.Color = ColorSequence.new(Color3.fromRGB(255, 220, 60), Color3.fromRGB(255, 60, 30))
	flames.LightEmission = 1
	flames.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(1, 0) })
	flames.Lifetime = NumberRange.new(0.25, 0.45)
	flames.Speed = NumberRange.new(10, 20)
	flames.SpreadAngle = Vector2.new(25, 25)
	flames.EmissionDirection = Enum.NormalId.Back
	flames.Rate = 0
	flames.Parent = carrier

	model.PrimaryPart = body
	model.Parent = Workspace
	return { Model = model, Body = body, Clumps = clumps, Carrier = carrier, Spray = spray, Trail = trail, Flames = flames, Skin = skin }
end

----------------------------------------------------------------------
-- Run state
----------------------------------------------------------------------
local run = nil
local camPos: Vector3? = nil
local camLook: Vector3? = nil

local function newRun(stats)
	return {
		S = START_S,
		X = 0,
		VX = 0,
		H = 0,
		VH = 0,
		RampH = 0,
		V = 0,
		R = stats.StartRadius or P.StartRadius,
		Roll = 0,
		Combo = 0,
		LastSmash = -100,
		BestCombo = 0,
		Smashed = 0,
		Coins = 0,
		Stats = stats,
		Time = 0,
		Stopped = 0,
		TurboUntil = -1,
	}
end

----------------------------------------------------------------------
-- Steering input: keyboard, gamepad stick, or touching either side
----------------------------------------------------------------------
local stickX = 0
local touches = {}

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
local function partsOf(inst: Instance)
	local list = {}
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end

local function breakApart(o, st, center: Vector3)
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
		local away = part.Position - center
		away = Vector3.new(away.X, 0, away.Z)
		if away.Magnitude > 0.01 then
			away = away.Unit
		end
		part.AssemblyLinearVelocity = CourseGen.Down * (st.V * 0.8 + 12)
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

local function smash(o, st, center: Vector3)
	o.Smashed = true
	local stats = st.Stats
	local turbo = st.Time < st.TurboUntil
	if not turbo then
		local power = (st.R / P.StartRadius) * stats.Smash
		st.V = math.max(0, st.V - o.Toughness * P.SmashLoss / power)
	end

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
	local coins = o.Coins * mult * sizeBonus * stats.CoinMult * o.Mult * (if crit then 2 else 1)
	coins = math.floor(coins + 0.5)
	st.Coins += coins
	st.Smashed += 1
	st.R = math.min(stats.MaxRadius, st.R + 0.12)

	-- feedback
	local midS = (o.S0 + o.S1) / 2
	local midX = (o.X0 + o.X1) / 2
	local base = surface(midS, midX)
	local popPos = base + Vector3.yAxis * (math.min(o.Top, 25) + 2)
	local color = if o.Mult >= 8 then Color3.fromRGB(120, 235, 255)
		elseif o.Mult >= 3 then Color3.fromRGB(255, 200, 40)
		elseif crit then Color3.fromRGB(255, 170, 40)
		else Color3.fromRGB(255, 225, 70)
	Effects.worldText(popPos, "+" .. Config.Commas(coins), color, if crit or o.Mult > 1 then 80 else 60)
	Effects.burst(base + Vector3.yAxis * math.min(o.Top, 6), Color3.fromRGB(240, 248, 255), 14 + math.floor(math.min(o.Toughness, 10) * 3), 1.6)
	Effects.play("Smash", 0.9 + math.random() * 0.3)
	if o.Mult > 1 then
		Effects.play("Mutation", 1.4)
	end
	Effects.shake(0.35 + math.min(o.Toughness, 12) * 0.12)
	Hud.setRunCoins(st.Coins)
	Hud.combo(mult, stats.ComboTime)
	if crit then
		Hud.critical()
		Effects.play("Critical", 1.2)
	end
	breakApart(o, st, center)
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------
-- Put a fresh snowball on the start pad and point the camera down the hill.
function Runner.prepare(stats, skinId: string)
	if courseDirty or (stats.Mutation == true) ~= mutationOn then
		Runner.resetCourse(stats.Mutation)
	end
	if ball then
		ball.Model:Destroy()
	end
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
	Effects.play("Launch", 1)
	Effects.shake(0.6)
end

function Runner.canTurbo(): boolean
	return run ~= nil and Runner.State == "Rolling" and run.Time >= run.TurboUntil
end

function Runner.turbo()
	local st = run
	if not st or Runner.State ~= "Rolling" then
		return
	end
	st.TurboUntil = st.Time + Config.Turbo.Duration
	st.V = math.min(P.MaxSpeed + Config.Turbo.SpeedAdd, st.V + Config.Turbo.SpeedAdd)
	st.Stopped = 0
	Effects.play("Boost", 0.8)
	Effects.play("Launch", 1.3)
	Effects.shake(1.5)
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
	-- show a fresh course in the lobby again
	Runner.resetCourse(mutationOn)
end

local function finish(st)
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
	local turbo = st.Time < st.TurboUntil

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
				Effects.play("Land", 0.8)
				Effects.shake(0.8)
				Effects.burst(surface(st.S, st.X), Color3.fromRGB(240, 248, 255), 26, 2)
			end
		elseif not turbo then
			st.V -= stats.Friction * dt
		end
		local maxSpeed = if turbo then P.MaxSpeed + Config.Turbo.SpeedAdd else P.MaxSpeed
		st.V = math.clamp(st.V, 0, math.max(maxSpeed, st.V - 60 * dt))
		local ds = st.V * dt
		st.S += ds
		if not airborne then
			st.R = math.min(stats.MaxRadius, st.R + stats.Growth * ds)
		end
		st.Roll += ds / st.R

		streamAround(st.S, 1)

		local ci0 = math.max(0, math.floor((st.S - 30) / CHUNK))
		local ci1 = math.floor((st.S + 30) / CHUNK)

		-- boost pads and ramps
		st.RampH = 0
		for ci = ci0, ci1 do
			local chunk = chunks[ci]
			if chunk then
				for _, pad in chunk.Pads do
					local inLane = st.X + st.R * 0.5 >= pad.X0 and st.X - st.R * 0.5 <= pad.X1
					if not pad.Used and st.H <= 0 and inLane and st.S >= pad.S0 and st.S <= pad.S1 then
						if pad.Kind == "Boost" then
							pad.Used = true
							st.V = math.min(maxSpeed, st.V + stats.Boost)
							Effects.play("Boost", 1.1)
							Effects.shake(0.5)
						elseif pad.Kind == "Ramp" then
							-- ride up the ramp, then fly off the lip
							local frac = (st.S - pad.S0) / math.max(1, pad.S1 - pad.S0)
							st.RampH = frac * pad.Top
							if frac >= 0.92 then
								pad.Used = true
								st.H = math.max(0.01, st.RampH)
								st.RampH = 0
								st.VH = P.RampLift * stats.Air + st.V * 0.1
								Effects.play("Launch", 1.2)
							end
						end
					end
				end
			end
		end

		local point, up = surface(st.S, st.X)
		local center = point + up * (st.R + st.H + st.RampH)

		-- smash obstacles and grab coins
		for ci = math.max(0, math.floor((st.S - st.R - 20) / CHUNK)), math.floor((st.S + st.R + 20) / CHUNK) do
			local chunk = chunks[ci]
			if chunk then
				for _, o in chunk.Obstacles do
					if o.S0 > st.S + st.R then
						break
					end
					if not o.Smashed and o.S1 > st.S - st.R and st.X + st.R * 0.85 > o.X0 and st.X - st.R * 0.85 < o.X1 and st.H < o.Top then
						smash(o, st, center)
					end
				end
				for _, p in chunk.Pickups do
					local part = p.Part
					if not p.Taken and part and math.abs(p.S - st.S) < st.R + 1.5 and math.abs(p.X - st.X) < st.R + 1.5 and part.Position.Y < center.Y + st.R + 3 then
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
		end

		-- end of the run (the mountain never ends, you just run out of speed)
		if st.V <= P.StopSpeed and st.H <= 0 and not turbo then
			st.Stopped += dt
			st.V = 0
			if st.Stopped > 0.35 then
				finish(st)
			end
		elseif st.Time > P.MaxRunTime then
			finish(st)
		else
			st.Stopped = 0
		end

		Hud.setDistance(math.max(0, st.S))
		Hud.setSpeed(st.V / 120)
		Effects.speedLines(dt, st.V)
	end

	-- spin nearby coins
	spinT += dt
	local ci = math.max(0, math.floor(st.S / CHUNK))
	for i = ci, ci + 1 do
		local chunk = chunks[i]
		if chunk then
			for _, p in chunk.Pickups do
				if p.Part and not p.Taken then
					p.Part.CFrame = p.Base * CFrame.Angles(0, spinT * 3, 0)
				end
			end
		end
	end

	-- place the snowball
	local point, up, forward = surface(st.S, st.X)
	local center = point + up * (st.R + st.H + st.RampH)
	local rot = CFrame.fromAxisAngle(-RIGHT, st.Roll) * CFrame.fromAxisAngle(forward, -st.X * 0.05)
	local ballCF = CFrame.new(center) * rot
	b.Body.Size = Vector3.one * st.R * 2
	b.Body.CFrame = ballCF
	if b.Skin.Rainbow then
		b.Body.Color = Color3.fromHSV((os.clock() * 0.25) % 1, 0.75, 1)
		b.Trail.Color = ColorSequence.new(b.Body.Color)
	end
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
	b.Flames.Rate = if turbo and Runner.State == "Rolling" then 120 else 0

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
		local fov = 70 + math.clamp((st.V - 40) * 0.18, 0, 30)
		camera.FieldOfView += (fov - camera.FieldOfView) * (1 - math.exp(-dt * 4))
	end
end

return Runner
