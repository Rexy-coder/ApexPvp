--!nonstrict
-- Snowball Smash: world effects for the crazy events.
--   Meteor Shower: red sky, burning meteors raining down (the ones the server
--                  aims at the lobby leave shards you can grab).
--   Galaxy Event:  night sky full of stars, planets, purple glow, low gravity.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Effects = require(script.Parent:WaitForChild("Effects"))

local CrazyFX = {}

local active: string? = nil
local base = nil -- lighting before any crazy event

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- remember the normal (seasonal) look so it can be restored afterwards
function CrazyFX.captureBase()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	local sky = Lighting:FindFirstChildOfClass("Sky")
	base = {
		Lighting = {
			ClockTime = Lighting.ClockTime,
			Brightness = Lighting.Brightness,
			Ambient = Lighting.Ambient,
			OutdoorAmbient = Lighting.OutdoorAmbient,
		},
		Atmosphere = atmosphere and { Color = atmosphere.Color, Decay = atmosphere.Decay, Density = atmosphere.Density, Haze = atmosphere.Haze },
		CC = cc and { TintColor = cc.TintColor, Saturation = cc.Saturation },
		StarCount = sky and sky.StarCount,
	}
end

local LOOKS = {
	Meteor = {
		Lighting = { ClockTime = 18.3, Brightness = 2, Ambient = rgb(150, 70, 60), OutdoorAmbient = rgb(190, 90, 70) },
		Atmosphere = { Color = rgb(255, 110, 60), Decay = rgb(130, 30, 20), Density = 0.42, Haze = 2 },
		CC = { TintColor = rgb(255, 205, 185), Saturation = 0.35 },
		StarCount = nil,
	},
	PetParty = {
		Lighting = { ClockTime = 15.2, Brightness = 3, Ambient = rgb(170, 130, 190), OutdoorAmbient = rgb(210, 170, 230) },
		Atmosphere = { Color = rgb(255, 170, 225), Decay = rgb(200, 110, 200), Density = 0.3, Haze = 1 },
		CC = { TintColor = rgb(255, 225, 245), Saturation = 0.5 },
		StarCount = nil,
	},
	Galaxy = {
		Lighting = { ClockTime = 0, Brightness = 2.4, Ambient = rgb(110, 80, 170), OutdoorAmbient = rgb(140, 110, 210) },
		Atmosphere = { Color = rgb(130, 90, 255), Decay = rgb(40, 20, 100), Density = 0.22, Haze = 1.4 },
		CC = { TintColor = rgb(225, 210, 255), Saturation = 0.45 },
		StarCount = 6000,
	},
}

local function tweenTo(look)
	local info = TweenInfo.new(2.5, Enum.EasingStyle.Sine)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	local sky = Lighting:FindFirstChildOfClass("Sky")
	-- ClockTime jumps (tweening across midnight looks odd)
	local lightProps = table.clone(look.Lighting)
	Lighting.ClockTime = lightProps.ClockTime
	lightProps.ClockTime = nil
	TweenService:Create(Lighting, info, lightProps):Play()
	if atmosphere and look.Atmosphere then
		TweenService:Create(atmosphere, info, look.Atmosphere):Play()
	end
	if cc and look.CC then
		TweenService:Create(cc, info, look.CC):Play()
	end
	if sky and look.StarCount then
		sky.StarCount = look.StarCount
	end
end

----------------------------------------------------------------------
-- Galaxy decorations: planets in the sky + twinkling stars around you
----------------------------------------------------------------------
local galaxyFolder: Folder? = nil

local function planet(parent: Instance, pos: Vector3, radius: number, color: Color3, ring: boolean)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = Vector3.one * radius * 2
	p.Position = pos
	p.Parent = parent
	if ring then
		local r = Instance.new("Part")
		r.Shape = Enum.PartType.Cylinder
		r.Anchored = true
		r.CanCollide = false
		r.CanQuery = false
		r.CanTouch = false
		r.CastShadow = false
		r.Material = Enum.Material.Neon
		r.Color = Color3.new(1, 1, 1):Lerp(color, 0.4)
		r.Transparency = 0.45
		r.Size = Vector3.new(radius * 0.08, radius * 3.6, radius * 3.6)
		r.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(70)) * CFrame.Angles(math.rad(20), 0, 0)
		r.Parent = parent
	end
	return p
end

local starPart: Part? = nil

local function galaxyOn()
	if galaxyFolder then
		return
	end
	local f = Instance.new("Folder")
	f.Name = "GalaxySky"
	planet(f, Vector3.new(420, 950, -900), 150, rgb(170, 90, 255), true)
	planet(f, Vector3.new(-650, 820, -1500), 90, rgb(60, 220, 255), false)
	planet(f, Vector3.new(-250, 1150, -300), 55, rgb(255, 120, 200), false)
	planet(f, Vector3.new(900, 700, -2200), 120, rgb(255, 190, 80), true)
	f.Parent = Workspace
	galaxyFolder = f

	local sp = Instance.new("Part")
	sp.Name = "GalaxyStars"
	sp.Anchored = true
	sp.CanCollide = false
	sp.CanQuery = false
	sp.CanTouch = false
	sp.Transparency = 1
	sp.Size = Vector3.new(200, 80, 200)
	sp.Parent = Workspace
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(rgb(255, 255, 255), rgb(190, 150, 255))
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(2, 4)
	e.Rate = 70
	e.Speed = NumberRange.new(0.5, 2)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Parent = sp
	starPart = sp
end

local function galaxyOff()
	if galaxyFolder then
		galaxyFolder:Destroy()
		galaxyFolder = nil
	end
	if starPart then
		starPart:Destroy()
		starPart = nil
	end
end

----------------------------------------------------------------------
-- Pet Party confetti
----------------------------------------------------------------------
local confettiPart: Part? = nil

local function partyOn()
	if confettiPart then
		return
	end
	local sp = Instance.new("Part")
	sp.Name = "PartyConfetti"
	sp.Anchored = true
	sp.CanCollide = false
	sp.CanQuery = false
	sp.CanTouch = false
	sp.Transparency = 1
	sp.Size = Vector3.new(150, 2, 150)
	sp.Parent = Workspace
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rgb(255, 90, 140)),
		ColorSequenceKeypoint.new(0.2, rgb(255, 225, 80)),
		ColorSequenceKeypoint.new(0.4, rgb(100, 255, 160)),
		ColorSequenceKeypoint.new(0.6, rgb(90, 190, 255)),
		ColorSequenceKeypoint.new(0.8, rgb(210, 120, 255)),
		ColorSequenceKeypoint.new(1, rgb(255, 150, 60)),
	})
	e.LightEmission = 0.3
	e.Size = NumberSequence.new(0.55)
	e.Rate = 150
	e.Lifetime = NumberRange.new(3, 5)
	e.Speed = NumberRange.new(8, 16)
	e.EmissionDirection = Enum.NormalId.Bottom
	e.SpreadAngle = Vector2.new(20, 20)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-240, 240)
	e.Acceleration = Vector3.new(0, -4, 0)
	e.Parent = sp
	confettiPart = sp
end

local function partyOff()
	if confettiPart then
		confettiPart:Destroy()
		confettiPart = nil
	end
end

----------------------------------------------------------------------
-- Meteors
----------------------------------------------------------------------
local function meteorModel(size: number): BasePart
	local rock = Instance.new("Part")
	rock.Name = "Meteor"
	rock.Shape = Enum.PartType.Ball
	rock.Anchored = true
	rock.CanCollide = false
	rock.CanQuery = false
	rock.CanTouch = false
	rock.Material = Enum.Material.CrackedLava
	rock.Color = rgb(90, 40, 30)
	rock.Size = Vector3.one * size
	local fire = Instance.new("ParticleEmitter")
	fire.Color = ColorSequence.new(rgb(255, 230, 120), rgb(255, 60, 20))
	fire.LightEmission = 1
	fire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.9), NumberSequenceKeypoint.new(1, 0) })
	fire.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	fire.Lifetime = NumberRange.new(0.4, 0.8)
	fire.Rate = 120
	fire.Speed = NumberRange.new(2, 6)
	fire.SpreadAngle = Vector2.new(20, 20)
	fire.Parent = rock
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 140, 50)
	light.Range = size * 6
	light.Brightness = 4
	light.Parent = rock
	return rock
end

-- a meteor that lands at `target` after `fall` seconds
function CrazyFX.meteor(target: Vector3, fall: number, size: number?)
	fall = math.max(0.3, fall)
	local s = size or 5
	local from = target + Vector3.new(math.random(-60, 60), 260, math.random(60, 160))
	local rock = meteorModel(s)
	rock.Position = from
	rock.Parent = Workspace
	local t = TweenService:Create(rock, TweenInfo.new(fall, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = target + Vector3.new(0, s * 0.4, 0) })
	t:Play()
	t.Completed:Connect(function()
		Effects.burst(target + Vector3.new(0, 1, 0), rgb(255, 120, 40), 30, 2.5)
		Effects.burst(target + Vector3.new(0, 1, 0), rgb(60, 50, 50), 16, 3)
		local camera = Workspace.CurrentCamera
		local d = if camera then (camera.CFrame.Position - target).Magnitude else 999
		if d < 180 then
			Effects.shake(math.clamp(2.2 - d / 90, 0.3, 2))
			Effects.play("MeteorImpact", 0.45, math.clamp(1.4 - d / 150, 0.2, 1))
		end
		-- glowing crater ring that fades out
		local ring = Instance.new("Part")
		ring.Shape = Enum.PartType.Cylinder
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanQuery = false
		ring.CanTouch = false
		ring.Material = Enum.Material.Neon
		ring.Color = rgb(255, 110, 30)
		ring.Size = Vector3.new(0.3, s * 2, s * 2)
		ring.CFrame = CFrame.new(target + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		ring.Parent = Workspace
		TweenService:Create(ring, TweenInfo.new(1.6), { Size = Vector3.new(0.3, s * 5, s * 5), Transparency = 1 }):Play()
		Debris:AddItem(ring, 1.7)
		rock:Destroy()
	end)
	Debris:AddItem(rock, fall + 1)
end

-- extra meteors for the show, raining around the camera
local ambientT = 0
RunService.Heartbeat:Connect(function(dt)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	if starPart then
		starPart.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 30, 0))
	end
	if confettiPart then
		confettiPart.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 45, 0))
	end
	if active == "Meteor" then
		ambientT += dt
		if ambientT > 0.9 then
			ambientT = 0
			local look = camera.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			flat = if flat.Magnitude > 0.01 then flat.Unit else Vector3.new(0, 0, -1)
			local ahead = camera.CFrame.Position + flat * math.random(60, 220) + Vector3.new(math.random(-120, 120), 0, math.random(-40, 40))
			-- find the ground under that point
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { camera }
			local hit = Workspace:Raycast(ahead + Vector3.new(0, 400, 0), Vector3.new(0, -1200, 0), params)
			if hit then
				CrazyFX.meteor(hit.Position, 1.6, math.random(3, 7))
			end
		end
	end
end)

----------------------------------------------------------------------
-- Switch looks
----------------------------------------------------------------------
function CrazyFX.setActive(id: string?)
	if id == active then
		return
	end
	if not base then
		CrazyFX.captureBase()
	end
	active = id
	if id == "Galaxy" then
		galaxyOn()
	else
		galaxyOff()
	end
	if id == "PetParty" then
		partyOn()
	else
		partyOff()
	end
	local look = id and LOOKS[id]
	if look then
		tweenTo(look)
	elseif base then
		tweenTo(base)
	end
end

function CrazyFX.active(): string?
	return active
end

return CrazyFX
