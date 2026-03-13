local Config = {}

Config.Game = {
	Name = "Aether Core: Power Ascendant",
	Subtitle = "Build raw power through rhythm, timing, and pure cinematic execution.",
	Version = "0.1.0",
}

Config.Player = {
	StartPower = 12,
	StartLevel = 1,
	StartStamina = 100,
	MaxStamina = 100,
	StaminaRegenActive = 5,
	StaminaRegenIdle = 3,
	XPBase = 120,
	XPMultiplier = 1.35,
	LevelPowerBonus = 3,
	ComboWindow = 2.25,
	ComboBonusPerHit = 0.08,
	MaxCombo = 24,
	MissStaminaPenalty = 0.52,
	MissXpMultiplier = 0.33,
}

Config.Actions = {
	Punch = {
		Name = "Punch",
		DisplayName = "Power Punch",
		Cooldown = 0.35,
		PowerGain = 9,
		XPGain = 18,
		StaminaCost = 11,
		Range = 24,
		Damage = 16,
		KeyHint = "Q",
		HitMultiplier = 1.35,
		PerfectMultiplier = 1.55,
	},
	Focus = {
		Name = "Focus",
		DisplayName = "Core Focus",
		Cooldown = 1.1,
		PowerGain = 8,
		XPGain = 24,
		StaminaCost = 7,
		Range = 0,
		Damage = 0,
		KeyHint = "E",
		HitMultiplier = 1.18,
		PerfectMultiplier = 1.35,
	},
	Dash = {
		Name = "Dash",
		DisplayName = "Surge Dash",
		Cooldown = 0.8,
		PowerGain = 7,
		XPGain = 15,
		StaminaCost = 12,
		Range = 20,
		Damage = 10,
		KeyHint = "R",
		HitMultiplier = 1.24,
		PerfectMultiplier = 1.45,
	},
}

Config.Targets = {
	Count = 8,
	MaxIntegrity = 90,
	RespawnDelay = 4,
	DistanceFromCenter = 32,
	HeightOffset = 4.5,
	Radius = 70,
}

Config.RemoteEvents = {
	MenuAction = "MenuAction",
	TrainAction = "TrainAction",
	TrainingFeedback = "TrainingFeedback",
}

Config.RemoteEventOrder = {
	"MenuAction",
	"TrainAction",
	"TrainingFeedback",
}

Config.Visual = {
	Bloom = 0.9,
	Saturation = -0.08,
	Contrast = 0.16,
	Tint = Color3.fromRGB(45, 34, 24),
	Ambient = Color3.fromRGB(15, 14, 20),
	GroundColor = Color3.fromRGB(15, 20, 26),
}

return Config
