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
		AllowedZones = {
			Punch = true,
			Endurance = true,
			Psych = false,
		},
		ZoneMultiplier = {
			Punch = 1.35,
			Endurance = 0.95,
			Psych = 0.65,
		},
	},
	UpperCut = {
		Name = "UpperCut",
		DisplayName = "Sky Uppercut",
		Cooldown = 0.7,
		PowerGain = 13,
		XPGain = 26,
		StaminaCost = 17,
		Range = 28,
		Damage = 26,
		KeyHint = "E",
		HitMultiplier = 1.18,
		PerfectMultiplier = 1.45,
		AllowedZones = {
			Punch = true,
			Endurance = false,
			Psych = false,
		},
		ZoneMultiplier = {
			Punch = 1.45,
			Endurance = 0.55,
			Psych = 0.45,
		},
	},
	Flurry = {
		Name = "Flurry",
		DisplayName = "Rapid Flurry",
		Cooldown = 0.18,
		PowerGain = 6,
		XPGain = 14,
		StaminaCost = 14,
		Range = 18,
		Damage = 10,
		KeyHint = "F",
		HitMultiplier = 1.18,
		PerfectMultiplier = 1.32,
		AllowedZones = {
			Punch = true,
			Endurance = false,
			Psych = false,
		},
		ZoneMultiplier = {
			Punch = 1.2,
			Endurance = 0.65,
			Psych = 0.4,
		},
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
		AllowedZones = {
			Punch = true,
			Endurance = true,
			Psych = false,
		},
		ZoneMultiplier = {
			Punch = 1.0,
			Endurance = 1.3,
			Psych = 0.45,
		},
	},
	Sprint = {
		Name = "Sprint",
		DisplayName = "Endurance Sprint",
		Cooldown = 0.5,
		PowerGain = 8,
		XPGain = 17,
		StaminaCost = 18,
		Range = 0,
		Damage = 0,
		KeyHint = "T",
		HitMultiplier = 1.05,
		PerfectMultiplier = 1.16,
		AllowedZones = {
			Punch = false,
			Endurance = true,
			Psych = false,
		},
		ZoneMultiplier = {
			Punch = 0.3,
			Endurance = 1.5,
			Psych = 0.55,
		},
	},
	Focus = {
		Name = "Focus",
		DisplayName = "Psych Focus",
		Cooldown = 1.1,
		PowerGain = 9,
		XPGain = 30,
		StaminaCost = 8,
		Range = 0,
		Damage = 0,
		KeyHint = "G",
		HitMultiplier = 1.18,
		PerfectMultiplier = 1.6,
		AllowedZones = {
			Punch = false,
			Endurance = false,
			Psych = true,
		},
		ZoneMultiplier = {
			Punch = 0.6,
			Endurance = 0.6,
			Psych = 1.55,
		},
	},
}

Config.InventorySlots = {
	{
		Name = "Punch",
		DisplayName = "Punch",
		Action = "Punch",
		KeyHint = "1",
		Description = "Core punch combo power.",
	},
	{
		Name = "Endurance",
		DisplayName = "Endurance",
		Action = "Sprint",
		KeyHint = "2",
		Description = "Surge training and stamina burn.",
	},
	{
		Name = "Psychic",
		DisplayName = "Psychic",
		Action = "Focus",
		KeyHint = "3",
		Description = "Focus and aura gain.",
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
