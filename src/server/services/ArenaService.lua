local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("GameShared"):WaitForChild("Config"))

local ArenaService = {}
local ArenaRoot
local SpawnPart
local ArenaTargetTag = "TrainingTarget"

local function makePart(className)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.Concrete
	part.CastShadow = false
	return part
end

local function makeSurfaceLabel(target, text, healthRatio)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Status"
	gui.Face = Enum.NormalId.Top
	gui.AlwaysOnTop = true
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.LightInfluence = 0
	gui.Parent = target

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.6, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(250, 245, 230)
	title.Text = text
	title.Parent = gui

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, 0, 0.2, 0)
	barBg.Position = UDim2.new(0, 0, 0.7, 0)
	barBg.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	barBg.BorderSizePixel = 0
	barBg.Parent = gui

	local bar = Instance.new("Frame")
	bar.Name = "HealthBar"
	bar.Size = UDim2.new(healthRatio, 0, 1, 0)
	bar.BackgroundColor3 = Color3.fromRGB(90, 240, 180)
	bar.BorderSizePixel = 0
	bar.Parent = barBg
end

local function updateTargetLook(target, ratio)
	local clamped = math.clamp(ratio, 0, 1)
	target.Color = Color3.fromHSV(0.08 + (1 - clamped) * 0.08, 0.9, 0.95)
	target.Material = clamped > 0 and Enum.Material.Neon or Enum.Material.SmoothPlastic
	target.Transparency = clamped <= 0 and 1 or (0.1 + (1 - clamped) * 0.4)
	local gui = target:FindFirstChild("Status")
	local bar = gui and gui:FindFirstChild("HealthBar", true)
	if bar then
		bar:TweenSize(UDim2.new(clamped, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Cubic, 0.15, true)
		if clamped >= 0.66 then
			bar.BackgroundColor3 = Color3.fromRGB(90, 240, 180)
		elseif clamped >= 0.34 then
			bar.BackgroundColor3 = Color3.fromRGB(240, 200, 90)
		else
			bar.BackgroundColor3 = Color3.fromRGB(245, 110, 110)
		end
	end
end

local function spawnTargetPulse(target)
	if not target or not target.Parent then
		return
	end
	target.Anchored = true
	target.Color = Color3.fromRGB(255, 175, 95)
	local pulse = Instance.new("Part")
	pulse.Shape = Enum.PartType.Ball
	pulse.Anchored = true
	pulse.CanCollide = false
	pulse.Size = Vector3.new(2, 2, 2)
	pulse.Transparency = 0.4
	pulse.Material = Enum.Material.Neon
	pulse.Color = Color3.fromRGB(255, 190, 90)
	pulse.CFrame = target.CFrame
	pulse.Parent = ArenaRoot

	local tween = TweenService:Create(
		pulse,
		TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Size = Vector3.new(7, 7, 7), Transparency = 1 }
	)
	tween:Play()
	tween.Completed:Connect(function()
		pulse:Destroy()
	end)

	local light = Instance.new("PointLight")
	light.Brightness = 4
	light.Color = pulse.Color
	light.Range = 20
	light.Parent = pulse
	Debris:AddItem(pulse, 1.2)
end

function ArenaService.getSpawnCFrame()
	if SpawnPart then
		return SpawnPart.CFrame + Vector3.new(0, 3, 0)
	end
	return CFrame.new(0, 8, 0)
end

function ArenaService.resolveTarget(part)
	local node = part
	while node do
		if CollectionService:HasTag(node, ArenaTargetTag) then
			return node
		end
		if node == workspace then
			return nil
		end
		node = node.Parent
	end
	return nil
end

function ArenaService.applyDamage(target, damage)
	if not target or target:GetAttribute("Disabled") then
		return false, 0, false
	end
	local maxIntegrity = target:GetAttribute("MaxIntegrity") or Config.Targets.MaxIntegrity
	local currentIntegrity = target:GetAttribute("Integrity") or maxIntegrity

	local newIntegrity = currentIntegrity - damage
	local broke = newIntegrity <= 0
	currentIntegrity = broke and 0 or newIntegrity
	target:SetAttribute("Integrity", currentIntegrity)

	if broke then
		target:SetAttribute("Disabled", true)
		target.CanTouch = false
		target.Color = Color3.fromRGB(45, 50, 60)
		target.Transparency = 0.72
		local gui = target:FindFirstChild("Status")
		if gui then
			gui.Enabled = false
		end
		task.delay(Config.Targets.RespawnDelay, function()
			if target.Parent then
				target:SetAttribute("Integrity", maxIntegrity)
				target:SetAttribute("Disabled", false)
				target.CanTouch = true
				local gui = target:FindFirstChild("Status")
				if gui then
					gui.Enabled = true
				end
				updateTargetLook(target, 1)
			end
		end)
	else
		updateTargetLook(target, currentIntegrity / maxIntegrity)
	end

	spawnTargetPulse(target)
	return broke, currentIntegrity / maxIntegrity, broke
end

function ArenaService.spawnWorldImpact(position, quality)
	if typeof(position) ~= "Vector3" then
		return
	end

	local colorMap = {
		Shatter = Color3.fromRGB(255, 90, 115),
		Great = Color3.fromRGB(255, 170, 90),
		Perfect = Color3.fromRGB(255, 245, 150),
		Clean = Color3.fromRGB(110, 220, 255),
		Miss = Color3.fromRGB(95, 120, 170),
	}
	local color = colorMap[quality] or Color3.fromRGB(255, 255, 255)

	local sphere = Instance.new("Part")
	sphere.Name = "ImpactPulse"
	sphere.Shape = Enum.PartType.Ball
	sphere.Anchored = true
	sphere.CanCollide = false
	sphere.Material = Enum.Material.Neon
	sphere.Color = color
	sphere.Size = Vector3.new(1, 1, 1)
	sphere.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
	sphere.Parent = workspace

	local light = Instance.new("PointLight")
	light.Brightness = 5
	light.Color = color
	light.Range = 18
	light.Parent = sphere

	local tween = TweenService:Create(
		sphere,
		TweenInfo.new(0.48, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(12, 12, 12), Transparency = 1 }
	)
	tween:Play()
	tween.Completed:Connect(function()
		sphere:Destroy()
	end)
	Debris:AddItem(sphere, 1)
end

function ArenaService.init()
	if ArenaRoot and ArenaRoot.Parent then
		return
	end

	ArenaRoot = Instance.new("Model")
	ArenaRoot.Name = "AetherTrainingArena"
	ArenaRoot.Parent = workspace

	local floor = makePart()
	floor.Name = "ArenaFloor"
	floor.Size = Vector3.new(Config.Targets.Radius * 2 + 40, 2, Config.Targets.Radius * 2 + 40)
	floor.Position = Vector3.new(0, 0, 0)
	floor.Material = Enum.Material.Slate
	floor.Color = Color3.fromRGB(24, 26, 34)
	floor.CastShadow = false
	floor.Anchored = true
	floor.Parent = ArenaRoot

	local rim = makePart()
	rim.Name = "ArenaRim"
	rim.Size = Vector3.new((Config.Targets.Radius * 2 + 60), 1, (Config.Targets.Radius * 2 + 60))
	rim.Position = Vector3.new(0, 2, 0)
	rim.Color = Color3.fromRGB(72, 82, 112)
	rim.Material = Enum.Material.Metal
	rim.Transparency = 0.15
	rim.Shape = Enum.PartType.Cylinder
	rim.Orientation = Vector3.new(90, 0, 0)
	rim.Parent = ArenaRoot

	SpawnPart = makePart()
	SpawnPart.Name = "TrainingSpawn"
	SpawnPart.Shape = Enum.PartType.Cylinder
	SpawnPart.Size = Vector3.new(1, 14, 14)
	SpawnPart.Orientation = Vector3.new(90, 0, 0)
	SpawnPart.Position = Vector3.new(0, 3.5, 0)
	SpawnPart.Color = Color3.fromRGB(95, 190, 170)
	SpawnPart.Material = Enum.Material.Neon
	SpawnPart.Name = "SpawnPlatform"
	SpawnPart.Parent = ArenaRoot

	local spawnLight = Instance.new("PointLight")
	spawnLight.Brightness = 2
	spawnLight.Range = 28
	spawnLight.Color = Color3.fromRGB(92, 250, 230)
	spawnLight.Parent = SpawnPart

	for i = 1, Config.Targets.Count do
		local angle = (i - 1) / Config.Targets.Count * math.pi * 2
		local x = math.cos(angle) * Config.Targets.DistanceFromCenter
		local z = math.sin(angle) * Config.Targets.DistanceFromCenter
		local target = makePart()
		target.Name = "TrainingTarget_" .. string.format("%02d", i)
		target.Size = Config.Targets and Config.Targets.Size and Vector3.new(7, 2.3, 7) or Vector3.new(7, 2, 7)
		target.Position = Vector3.new(x, Config.Targets.HeightOffset, z)
		target.Color = Color3.fromRGB(255, 145, 90)
		target.Material = Enum.Material.Neon
		target.Transparency = 0.08
		target.TopSurface = Enum.SurfaceType.Smooth
		target.BottomSurface = Enum.SurfaceType.Smooth
		target.Parent = ArenaRoot
		target:SetAttribute("Index", i)
		target:SetAttribute("MaxIntegrity", Config.Targets.MaxIntegrity)
		target:SetAttribute("Integrity", Config.Targets.MaxIntegrity)
		target:SetAttribute("Disabled", false)

		makeSurfaceLabel(target, "TARGET " .. i, 1)
		CollectionService:AddTag(target, ArenaTargetTag)

		updateTargetLook(target, 1)

		local light = Instance.new("PointLight")
		light.Brightness = 2.2
		light.Color = Color3.fromRGB(255, 170, 95)
		light.Range = 14
		light.Parent = target

		local ring = makePart()
		ring.Name = "RangeRing"
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.2, 20, 20)
		ring.CFrame = CFrame.new(Vector3.new(x, Config.Targets.HeightOffset - 1, z)) * CFrame.Angles(math.rad(90), 0, 0)
		ring.Material = Enum.Material.ForceField
		ring.Color = Color3.fromRGB(120, 240, 210)
		ring.Transparency = 0.7
		ring.Parent = ArenaRoot

		local ringTween = TweenService:Create(
			ring,
			TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{Transparency = 0.4}
		)
		ringTween:Play()
	end

	local glow = makePart()
	glow.Name = "CenterLight"
	glow.Size = Vector3.new(2, 30, 2)
	glow.Material = Enum.Material.Neon
	glow.Color = Color3.fromRGB(255, 200, 110)
	glow.Transparency = 0.85
	glow.Position = Vector3.new(0, 15, 0)
	glow.CFrame = CFrame.new(0, 15, 0)
	glow.Anchored = true
	glow.Parent = ArenaRoot

	local aura = Instance.new("PointLight")
	aura.Brightness = 7
	aura.Range = 100
	aura.Color = Color3.fromRGB(255, 200, 110)
	aura.Parent = glow
	Debris:AddItem(aura, math.huge)
end

return ArenaService
