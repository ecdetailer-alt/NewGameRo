local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local shared = ReplicatedStorage:WaitForChild("GameShared")
local Config = require(shared:WaitForChild("Config"))

local PlayerService = require(script:WaitForChild("services"):WaitForChild("PlayerService"))
local ArenaService = require(script:WaitForChild("services"):WaitForChild("ArenaService"))
local TrainingService = require(script:WaitForChild("services"):WaitForChild("TrainingService"))

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local remotes = {}
for _, remoteName in ipairs(Config.RemoteEventOrder) do
	local event = remotesFolder:FindFirstChild(remoteName)
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = remoteName
		event.Parent = remotesFolder
	end
	remotes[remoteName] = event
end

local function applyLighting()
	Lighting.ClockTime = 16
	Lighting.Brightness = 2
	Lighting.ExposureCompensation = 0.02
	Lighting.Ambient = Config.Visual.Ambient
	Lighting.OutdoorAmbient = Config.Visual.GroundColor
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.35
	Lighting.Technology = Enum.Technology.Future

	local function ensure(className)
		local effect = Lighting:FindFirstChildOfClass(className)
		if not effect then
			effect = Instance.new(className)
			effect.Parent = Lighting
		end
		return effect
	end

	local bloom = ensure("BloomEffect")
	bloom.Intensity = Config.Visual.Bloom
	bloom.Size = 70
	bloom.Threshold = 0.35

	local color = ensure("ColorCorrectionEffect")
	color.TintColor = Config.Visual.Tint
	color.Contrast = Config.Visual.Contrast
	color.Saturation = Config.Visual.Saturation

	local atmos = ensure("Atmosphere")
	atmos.Density = 0.28
	atmos.Offset = 0.22
	atmos.Glare = 0.55
	atmos.Haze = 0.4
end

ArenaService.init()
PlayerService.bindArenaProvider(ArenaService)
PlayerService.init()
TrainingService.init(remotes, PlayerService, ArenaService)
applyLighting()

remotes.MenuAction.OnServerEvent:Connect(function(player, action)
	if action == "StartSession" then
		local changed = PlayerService.setSession(player, true)
		if changed and remotes.TrainingFeedback then
			remotes.TrainingFeedback:FireClient(player, {
				Type = "Session",
				Active = true,
				Message = "Session active. Train to break targets and climb levels.",
			})
		end
	elseif action == "EndSession" then
		PlayerService.setSession(player, false)
		remotes.TrainingFeedback:FireClient(player, {
			Type = "Session",
			Active = false,
			Message = "Session stopped.",
		})
	elseif action == "Reset" then
		PlayerService.resetProfileForPlayer(player)
		remotes.TrainingFeedback:FireClient(player, {
			Type = "Session",
			Active = PlayerService.getProfile(player) and PlayerService.getProfile(player).InSession or false,
			Message = "Stats reset.",
		})
	end
end)
