local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("GameShared"):WaitForChild("Config"))

local PlayerService = {}
local Profiles = {}
local ArenaProvider

local function xpForNextLevel(level)
	return math.floor(Config.Player.XPBase * (Config.Player.XPMultiplier ^ (level - 1)))
end

local function createFolder(parent, name)
	local folder = parent:FindFirstChild(name)
	if folder and folder.ClassName == "Folder" then
		return folder
	end
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function createValue(parent, valueClass, name, value)
	local obj = parent:FindFirstChild(name)
	if obj and obj.ClassName == valueClass then
		obj.Value = value
		return obj
	end
	if obj then
		obj:Destroy()
	end
	local v = Instance.new(valueClass)
	v.Name = name
	v.Value = value
	v.Parent = parent
	return v
end

local function buildProfile(player)
	local leaderstats = createFolder(player, "leaderstats")
	local hidden = createFolder(player, "PowerTrainingData")

	local values = {
		Power = createValue(leaderstats, "IntValue", "Power", Config.Player.StartPower),
		Level = createValue(leaderstats, "IntValue", "Level", Config.Player.StartLevel),
		Stamina = createValue(leaderstats, "IntValue", "Stamina", Config.Player.StartStamina),
		Experience = createValue(hidden, "IntValue", "Experience", 0),
		NextXP = createValue(hidden, "IntValue", "NextXP", xpForNextLevel(Config.Player.StartLevel)),
		Combo = createValue(hidden, "IntValue", "Combo", 0),
		BestCombo = createValue(hidden, "IntValue", "BestCombo", 0),
	}

	local profile = {
		Player = player,
		Values = values,
		Combo = 0,
		LastHitAt = 0,
		LastActions = {},
		LastProfileTick = 0,
		InSession = false,
	}
	Profiles[player] = profile

	task.spawn(function()
		while player.Parent do
			local regenRate = profile.InSession and Config.Player.StaminaRegenActive or Config.Player.StaminaRegenIdle
			if values.Stamina.Value < Config.Player.MaxStamina then
				values.Stamina.Value = math.min(Config.Player.MaxStamina, values.Stamina.Value + regenRate)
			end
			task.wait(1)
		end
	end)

	return profile
end

local function levelUp(profile, xpGain)
	local levelUps = 0
	while profile.Values.Experience.Value >= profile.Values.NextXP.Value do
		profile.Values.Experience.Value -= profile.Values.NextXP.Value
		profile.Values.Level.Value += 1
		profile.Values.Power.Value += Config.Player.LevelPowerBonus
		levelUps += 1
		profile.Values.NextXP.Value = xpForNextLevel(profile.Values.Level.Value)
	end
	return levelUps
end

function PlayerService.init()
	Players.PlayerAdded:Connect(function(player)
		local profile = buildProfile(player)

		player.CharacterAdded:Connect(function(character)
			local hrp = character:WaitForChild("HumanoidRootPart", 12)
			if not hrp then
				return
			end
			if profile.InSession and ArenaProvider and ArenaProvider.getSpawnCFrame then
				local spawnCFrame = ArenaProvider.getSpawnCFrame()
				if spawnCFrame then
					hrp.CFrame = spawnCFrame + Vector3.new(0, 3, 0)
				end
			end
		end)

		player:SetAttribute("InSession", false)
	end)

	Players.PlayerRemoving:Connect(function(player)
		Profiles[player] = nil
	end)
end

function PlayerService.bindArenaProvider(arenaModule)
	ArenaProvider = arenaModule
end

function PlayerService.getProfile(player)
	return Profiles[player]
end

function PlayerService.setSession(player, active)
	local profile = Profiles[player]
	if not profile then
		return false
	end

	profile.InSession = active
	profile.Combo = 0
	profile.LastHitAt = 0
	profile.Values.Combo.Value = 0
	player:SetAttribute("InSession", active)

	if active and player.Character and player.Character.Parent then
		local hrp = player.Character:FindFirstChild("HumanoidRootPart")
		if hrp and ArenaProvider and ArenaProvider.getSpawnCFrame then
			hrp.CFrame = (ArenaProvider.getSpawnCFrame() or hrp.CFrame) + Vector3.new(0, 3, 0)
		end
	end
	return true
end

function PlayerService.applyAction(player, actionName, wasHit, quality)
	local profile = Profiles[player]
	if not profile then
		return nil, "Player profile not found."
	end
	if not profile.InSession then
		return nil, "Session has not started."
	end

	local action = Config.Actions[actionName]
	if not action then
		return nil, "Unknown training action."
	end

	local now = os.clock()
	local last = profile.LastActions[actionName] or 0
	if now - last < action.Cooldown then
		return nil, "Action on cooldown."
	end

	local staminaCost = wasHit and action.StaminaCost or math.floor(action.StaminaCost * Config.Player.MissStaminaPenalty + 0.5)
	if profile.Values.Stamina.Value < staminaCost then
		return nil, "Not enough stamina."
	end

	profile.LastActions[actionName] = now
	profile.Values.Stamina.Value = math.clamp(profile.Values.Stamina.Value - staminaCost, 0, Config.Player.MaxStamina)

	if wasHit then
		if now - profile.LastHitAt <= Config.Player.ComboWindow then
			profile.Combo = math.min(profile.Combo + 1, Config.Player.MaxCombo)
		else
			profile.Combo = 1
		end
		profile.LastHitAt = now
	else
		profile.Combo = 0
	end

	local comboBonus = 1 + ((profile.Combo - 1) * Config.Player.ComboBonusPerHit)
	local qualityMul = 1
	if quality == "Perfect" then
		qualityMul = action.PerfectMultiplier
	elseif quality == "Great" then
		qualityMul = action.HitMultiplier
	elseif quality == "Shatter" then
		qualityMul = action.PerfectMultiplier + 0.15
	elseif quality == "Miss" then
		qualityMul = 0.2
	end
	if not wasHit then
		qualityMul = qualityMul * Config.Player.MissXpMultiplier
	end

	local gainedXp = math.floor(action.XPGain * comboBonus * qualityMul + 0.5)
	local gainedPower = math.floor(action.PowerGain * comboBonus * qualityMul + 0.5)

	profile.Values.Experience.Value += gainedXp
	profile.Values.Power.Value += gainedPower
	profile.Values.Combo.Value = profile.Combo
	profile.Values.BestCombo.Value = math.max(profile.Values.BestCombo.Value, profile.Combo)

	local levelUps = levelUp(profile, gainedXp)

	return {
		Success = true,
		Action = actionName,
		GainedXp = gainedXp,
		GainedPower = gainedPower,
		LevelUps = levelUps,
		Combo = profile.Combo,
		BestCombo = profile.Values.BestCombo.Value,
		Power = profile.Values.Power.Value,
		Xp = profile.Values.Experience.Value,
		NextXp = profile.Values.NextXP.Value,
		Level = profile.Values.Level.Value,
		Stamina = profile.Values.Stamina.Value,
	}, nil
end

function PlayerService.resetProfileForPlayer(player)
	local profile = Profiles[player]
	if not profile then
		return
	end
	profile.Values.Power.Value = Config.Player.StartPower
	profile.Values.Level.Value = Config.Player.StartLevel
	profile.Values.Stamina.Value = Config.Player.StartStamina
	profile.Values.Experience.Value = 0
	profile.Values.NextXP.Value = xpForNextLevel(Config.Player.StartLevel)
	profile.Values.Combo.Value = 0
	profile.Values.BestCombo.Value = 0
	profile.Combo = 0
	profile.LastHitAt = 0
	profile.LastActions = {}
end

return PlayerService
