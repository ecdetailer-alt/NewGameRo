local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local FXController = {}

local function qualityColor(quality)
	if quality == "Shatter" then
		return Color3.fromRGB(255, 110, 130)
	elseif quality == "Great" then
		return Color3.fromRGB(255, 190, 120)
	elseif quality == "Perfect" then
		return Color3.fromRGB(255, 245, 170)
	end
	return Color3.fromRGB(130, 180, 255)
end

function FXController.new(config, player, playerGui, feedbackRemote, hud)
	local self = {}
	self.Active = true
	self._lastShake = tick()

	local overlay = Instance.new("ScreenGui")
	overlay.Name = "AetherFXOverlay"
	overlay.IgnoreGuiInset = true
	overlay.ResetOnSpawn = false
	overlay.ZIndexBehavior = Enum.ZIndexBehavior.Global
	overlay.Parent = playerGui

	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BorderSizePixel = 0
	flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flash.BackgroundTransparency = 1
	flash.Parent = overlay
	flash.ZIndex = 20

	local messageFeed = Instance.new("TextLabel")
	messageFeed.Name = "MessageFeed"
	messageFeed.Size = UDim2.fromScale(1, 0.05)
	messageFeed.Position = UDim2.new(0, 0, 0.68, 0)
	messageFeed.BackgroundTransparency = 1
	messageFeed.Text = ""
	messageFeed.TextColor3 = Color3.fromRGB(240, 238, 225)
	messageFeed.TextSize = 20
	messageFeed.Font = Enum.Font.GothamBold
	messageFeed.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	messageFeed.TextStrokeTransparency = 0.6
	messageFeed.ZIndex = 15
	messageFeed.Parent = overlay

	function self.queueMessage(text, color)
		if not self.Active then
			return
		end
		messageFeed.Text = text
		messageFeed.TextColor3 = color or Color3.fromRGB(240, 238, 225)
		TweenService:Create(
			messageFeed,
			TweenInfo.new(0.18),
			{TextTransparency = 0}
		):Play()
		delay(1.15, function()
			if messageFeed and messageFeed.Parent then
				TweenService:Create(messageFeed, TweenInfo.new(0.45), {TextTransparency = 1}):Play()
			end
		end)
	end

	local function flashHit(quality)
		if not self.Active then
			return
		end
		flash.BackgroundColor3 = qualityColor(quality)
		flash.BackgroundTransparency = 0.8
		local tween = TweenService:Create(
			flash,
			TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }
		)
		tween:Play()
	end

	local function emitText(payload)
		if not payload or not payload.Success then
			return
		end
		local msg = ("%s +%d XP +%d Power"):format(payload.Action, payload.GainedXp or 0, payload.GainedPower or 0)
		self.queueMessage(msg, qualityColor(payload.Quality))
	end

	local function cameraJolt()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local base = camera.CFrame
		for i = 1, 4 do
			camera.CFrame = base * CFrame.Angles(0, 0, math.rad((i % 2 == 0 and 1 or -1) * 0.25))
			task.wait(0.01)
		end
		camera.CFrame = base
	end

	feedbackRemote.OnClientEvent:Connect(function(payload)
		if not payload then
			return
		end

		if payload.Type == "Session" then
			if payload.Active then
				self.queueMessage(payload.Message or "Session started.", Color3.fromRGB(145, 255, 190))
			else
				self.queueMessage(payload.Message or "Session ended.", Color3.fromRGB(255, 190, 130))
			end
			if hud and hud.processFeedback then
				hud.processFeedback(payload)
			end
			return
		end

		if payload.Type ~= "ActionResult" then
			return
		end

		if hud and hud.processFeedback then
			hud.processFeedback(payload)
		end

		if payload.Success then
			flashHit(payload.Quality or "Clean")
			emitText(payload)
			if tick() - self._lastShake > 0.08 then
				self._lastShake = tick()
				task.spawn(cameraJolt)
			end
		else
			self.queueMessage(payload.Message or "Action blocked.", Color3.fromRGB(255, 150, 130))
		end
	end)

	function self.setActive(value)
		self.Active = value
	end

	return self
end

return FXController
