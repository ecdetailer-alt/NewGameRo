local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("GameShared")
local Config = require(shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local MenuController = require(script:WaitForChild("services"):WaitForChild("MenuController"))
local HUDController = require(script:WaitForChild("services"):WaitForChild("HUDController"))
local InputController = require(script:WaitForChild("services"):WaitForChild("InputController"))
local FXController = require(script:WaitForChild("services"):WaitForChild("FXController"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local hud = HUDController.new(Config, player, playerGui)
local fx = FXController.new(Config, player, playerGui, Remotes:WaitForChild(Config.RemoteEvents.TrainingFeedback), hud)
local menu = MenuController.new(Config, player, Remotes:WaitForChild(Config.RemoteEvents.MenuAction), playerGui, fx)

local input = InputController.new(Config, player, Remotes:WaitForChild(Config.RemoteEvents.TrainAction), menu, hud)
input.setSessionEnabled(false)

menu.onSessionChanged(function(active)
	input.setSessionEnabled(active)
	hud.setSessionActive(active)
	fx.setActive(active)
end)
