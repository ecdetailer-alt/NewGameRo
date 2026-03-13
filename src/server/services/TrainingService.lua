local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("GameShared"):WaitForChild("Config"))

local TrainingService = {}
local PlayerService
local ArenaService
local Remotes

local function qualityFromRemainingFraction(qualityFraction)
	if qualityFraction <= 0 then
		return "Shatter"
	elseif qualityFraction <= 0.35 then
		return "Great"
	elseif qualityFraction <= 0.8 then
		return "Perfect"
	else
		return "Clean"
	end
end

local function locateTargetFromRay(player, action)
	local character = player.Character
	if not character then
		return nil, nil
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil, nil
	end

	if action.Range <= 0 then
		return nil, nil
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = true
	local direction = hrp.CFrame.LookVector * action.Range
	local result = workspace:Raycast(hrp.Position + Vector3.new(0, 2, 0), direction, params)
	if not result then
		return nil, nil
	end

	local target = ArenaService.resolveTarget(result.Instance)
	if not target then
		return nil, nil
	end

	return target, result.Position
end

local function buildFeedback(player, success, actionName, payload)
	payload = payload or {}
	return {
		Type = "ActionResult",
		PlayerName = player.Name,
		Success = success,
		Action = actionName,
		Quality = payload.Quality or "Miss",
		Message = payload.Message or "",
		Impact = payload.Impact,
		Zone = payload.Zone or "Punch",
		GainedXp = payload.GainedXp or 0,
		GainedPower = payload.GainedPower or 0,
		LevelUps = payload.LevelUps or 0,
		Combo = payload.Combo or 0,
		BestCombo = payload.BestCombo or 0,
		Power = payload.Power or 0,
		XP = payload.XP or 0,
		NextXP = payload.NextXP or 0,
		Level = payload.Level or 0,
		Stamina = payload.Stamina or 0,
	}
end

function TrainingService.onTrainAction(player, actionName)
	if not Remotes then
		return
	end

	local action = Config.Actions[actionName]
	if not action then
		Remotes.TrainingFeedback:FireClient(player, buildFeedback(player, false, actionName, {
			Message = "Unknown action.",
		}))
		return
	end

	local zoneName = "Punch"
	if ArenaService and ArenaService.getZoneForPlayer then
		zoneName = ArenaService.getZoneForPlayer(player) or "Punch"
	end

	if action.AllowedZones and not action.AllowedZones[zoneName] then
		Remotes.TrainingFeedback:FireClient(player, buildFeedback(player, false, actionName, {
			Quality = "Miss",
			Zone = zoneName,
			Message = ("%s doesn't work in the %s area."):format(action.DisplayName, zoneName),
		}))
		return
	end

	local target, hitPos
	local hit = false
	local quality = "Clean"
	if action.Range > 0 then
		if zoneName == "Punch" then
			local resolvedTarget, resolvedPos = locateTargetFromRay(player, action)
			target = resolvedTarget
			hitPos = resolvedPos
			if target then
				local broke, ratio = ArenaService.applyDamage(target, action.Damage)
				hit = true
				if target:GetAttribute("Disabled") then
					quality = "Shatter"
				else
					quality = qualityFromRemainingFraction(ratio)
				end
				ArenaService.spawnWorldImpact(hitPos, quality)
			else
				hit = false
				quality = "Miss"
			end
		elseif action.Name == "Dash" and zoneName == "Endurance" then
			hit = true
			quality = "Great"
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hitPos = hrp.Position + hrp.CFrame.LookVector * 4
			end
		else
			quality = "Miss"
			hit = false
		end
	end
	else
		-- Mental and endurance-focused actions are internal training.
		hit = true
		quality = zoneName == "Psych" and "Perfect" or "Great"
		hitPos = (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position + player.Character.HumanoidRootPart.CFrame.LookVector * 2)
	end

	if hitPos and (actionName == "Dash" or actionName == "Flurry" or actionName == "UpperCut") then
		ArenaService.spawnWorldImpact(hitPos, quality)
	end

	local result, errorMessage = PlayerService.applyAction(player, actionName, hit, quality, zoneName)
	if not result then
		Remotes.TrainingFeedback:FireClient(player, buildFeedback(player, false, actionName, {
			Zone = zoneName,
			Message = errorMessage,
			Quality = "Miss",
		}))
		return
	end

	if hit then
		result.Message = string.format("%s hit with %s impact!", action.DisplayName, quality)
		result.Zone = zoneName
	else
		result.Message = string.format("%s missed. Chain broken.", action.DisplayName)
	end

	Remotes.TrainingFeedback:FireClient(player, buildFeedback(player, true, actionName, result))
end

function TrainingService.init(remotes, playerService, arenaService)
	Remotes = remotes
	PlayerService = playerService
	ArenaService = arenaService
	remotes.TrainAction.OnServerEvent:Connect(TrainingService.onTrainAction)
end

return TrainingService
