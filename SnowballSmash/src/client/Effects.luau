--!nonstrict
-- Snowball Smash: sounds, camera shake, speed lines, floating world text and snow bursts.

local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Sounds = require(Shared:WaitForChild("Sounds"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))

local Effects = {}

Effects.Settings = { Music = true, SFX = true, Shake = true, SpeedLines = true, Hints = true, PerfectPush = true }

----------------------------------------------------------------------
-- Sound effects (ids come from ReplicatedStorage.Shared.Sounds)
----------------------------------------------------------------------
local soundFolder = Instance.new("Folder")
soundFolder.Name = "SnowballSounds"
soundFolder.Parent = SoundService

local templates = {}
local function addTemplates(list, volume: number)
	for name, id in list do
		if type(id) == "string" and id ~= "" then
			local s = Instance.new("Sound")
			s.Name = name
			s.SoundId = id
			s.Volume = volume
			s.Parent = soundFolder
			templates[name] = s
		end
	end
end
addTemplates(Sounds.UI, Sounds.UIVolume)
addTemplates(Sounds.Game, Sounds.SfxVolume)

-- name: a key from Sounds.UI or Sounds.Game; volume: 0-1 multiplier
function Effects.play(name: string, pitch: number?, volume: number?)
	if not Effects.Settings.SFX then
		return
	end
	local t = templates[name]
	if not t then
		return
	end
	local s = t:Clone()
	s.PlaybackSpeed = pitch or 1
	s.Volume = t.Volume * (volume or 1)
	s.Parent = soundFolder
	s:Play()
	Debris:AddItem(s, 4)
end
UIKit.PlaySound = Effects.play

----------------------------------------------------------------------
-- Background music playlist (+ optional event music)
----------------------------------------------------------------------
local playlist = {}
for _, id in Sounds.Music do
	if type(id) == "string" and id ~= "" then
		table.insert(playlist, id)
	end
end

local music = Instance.new("Sound")
music.Name = "Music"
music.Volume = Sounds.MusicVolume
music.Parent = soundFolder
local track = 0
local eventMusicOn = false
local eventMusicId = ""

local function playNext()
	if eventMusicOn and eventMusicId ~= "" then
		music.SoundId = eventMusicId
		music.Looped = true
	elseif #playlist > 0 then
		track = track % #playlist + 1
		music.SoundId = playlist[track]
		music.Looped = #playlist == 1
	else
		music:Stop()
		return
	end
	music.TimePosition = 0
	music:Play()
end

music.Ended:Connect(function()
	if Effects.Settings.Music then
		playNext()
	end
end)

function Effects.applyMusic()
	if Effects.Settings.Music then
		if not music.IsPlaying then
			playNext()
		end
	else
		music:Stop()
	end
end

-- switch to/from event music while a storm is running
-- (crazyId: a running crazy event, uses Sounds.CrazyMusic[crazyId] when set)
function Effects.setEventMusic(on: boolean, crazyId: string?)
	local id = ""
	if on then
		local crazy = crazyId and Sounds.CrazyMusic and Sounds.CrazyMusic[crazyId]
		id = if crazy and crazy ~= "" then crazy else Sounds.EventMusic
	end
	if on == eventMusicOn and id == eventMusicId then
		return
	end
	local changed = id ~= eventMusicId or (id ~= "" and on ~= eventMusicOn)
	eventMusicOn = on
	eventMusicId = id
	if changed and Effects.Settings.Music then
		music:Stop()
		playNext()
	end
end

----------------------------------------------------------------------
-- Camera shake (returns an offset CFrame you multiply into the camera)
----------------------------------------------------------------------
local shakeAmount = 0
function Effects.shake(amount: number)
	if Effects.Settings.Shake then
		shakeAmount = math.min(2.5, shakeAmount + amount)
	end
end

function Effects.shakeOffset(dt: number): CFrame
	if shakeAmount <= 0.001 then
		shakeAmount = 0
		return CFrame.identity
	end
	local a = shakeAmount
	shakeAmount = shakeAmount * math.exp(-dt * 7)
	local rx = (math.random() - 0.5) * a * 0.05
	local ry = (math.random() - 0.5) * a * 0.05
	return CFrame.new((math.random() - 0.5) * a, (math.random() - 0.5) * a, 0) * CFrame.Angles(rx, ry, 0)
end

----------------------------------------------------------------------
-- Speed lines: thin white streaks flying out from the centre of the screen
----------------------------------------------------------------------
local linesLayer: Frame? = nil
local lineTimer = 0

function Effects.setSpeedLayer(layer: Frame)
	linesLayer = layer
end

function Effects.speedLines(dt: number, speed: number)
	local layer = linesLayer
	if not layer or not Effects.Settings.SpeedLines or speed < 45 then
		return
	end
	lineTimer += dt * math.clamp((speed - 40) / 6, 0, 22)
	while lineTimer >= 1 do
		lineTimer -= 1
		local angle = math.random() * math.pi * 2
		local dir = Vector2.new(math.cos(angle), math.sin(angle))
		local startR = 0.28 + math.random() * 0.1
		local line = UIKit.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(math.random(60, 160), math.random(2, 4)),
			Position = UDim2.fromScale(0.5 + dir.X * startR, 0.5 + dir.Y * startR),
			Rotation = math.deg(angle),
			Parent = layer,
		})
		local endR = 0.8
		UIKit.tween(line, 0.35, {
			Position = UDim2.fromScale(0.5 + dir.X * endR, 0.5 + dir.Y * endR),
			BackgroundTransparency = 1,
		}, Enum.EasingStyle.Linear)
		Debris:AddItem(line, 0.4)
	end
end

----------------------------------------------------------------------
-- Floating text in the world ("+120", "CRITICAL!")
----------------------------------------------------------------------
function Effects.worldText(position: Vector3, text: string, color: Color3, size: number?)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.2
	anchor.Position = position
	anchor.Parent = Workspace

	local px = size or 60
	local gui = UIKit.new("BillboardGui", {
		Size = UDim2.fromOffset(px * 4, px),
		AlwaysOnTop = true,
		LightInfluence = 0,
		StudsOffset = Vector3.new(0, 0, 0),
		Parent = anchor,
	})
	local label = UIKit.label({
		Text = text,
		Size = UDim2.fromScale(1, 1),
		TextColor3 = color,
		Stroke = 3,
		Parent = gui,
	})
	UIKit.pop(label, 0.3)
	UIKit.tween(gui, 1.1, { StudsOffset = Vector3.new(0, 6, 0) }, Enum.EasingStyle.Quad)
	task.delay(0.6, function()
		UIKit.tween(label, 0.5, { TextTransparency = 1 })
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke then
			UIKit.tween(stroke, 0.5, { Transparency = 1 })
		end
	end)
	Debris:AddItem(anchor, 1.3)
end

----------------------------------------------------------------------
-- Snow puff particles
----------------------------------------------------------------------
function Effects.burst(position: Vector3, color: Color3, count: number, size: number?)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.one
	holder.Position = position
	holder.Parent = Workspace

	local s = size or 1.5
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.2
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, s),
		NumberSequenceKeypoint.new(1, s * 0.2),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.Speed = NumberRange.new(14, 32)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -40, 0)
	emitter.Drag = 2
	emitter.Rate = 0
	emitter.Parent = holder
	emitter:Emit(count)
	Debris:AddItem(holder, 1.5)
end

----------------------------------------------------------------------
-- Storm weather: heavy snowfall around the camera while a storm is active
----------------------------------------------------------------------
local stormPart: Part? = nil
local stormEmitter: ParticleEmitter? = nil

function Effects.setStorm(on: boolean, color: Color3?)
	if on and not stormPart then
		local p = Instance.new("Part")
		p.Name = "StormSnow"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		p.Size = Vector3.new(160, 1, 160)
		p.Parent = Workspace
		local e = Instance.new("ParticleEmitter")
		e.Rate = 260
		e.Lifetime = NumberRange.new(2.5, 4)
		e.Speed = NumberRange.new(25, 40)
		e.EmissionDirection = Enum.NormalId.Bottom
		e.SpreadAngle = Vector2.new(15, 15)
		e.Acceleration = Vector3.new(14, 0, 6)
		e.Size = NumberSequence.new(0.35)
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.6) })
		e.LightEmission = 0.4
		e.Parent = p
		stormPart = p
		stormEmitter = e
	end
	if stormEmitter and color then
		stormEmitter.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
	end
	if not on and stormPart then
		stormPart:Destroy()
		stormPart = nil
		stormEmitter = nil
	end
end

game:GetService("RunService").RenderStepped:Connect(function()
	local p = stormPart
	local camera = Workspace.CurrentCamera
	if p and camera then
		p.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 45, 0) + camera.CFrame.LookVector * 40)
	end
end)

return Effects
