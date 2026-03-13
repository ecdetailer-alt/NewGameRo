local HUDController = {}

local function makePanel(parent, name, size, pos)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.Size = size
	panel.Position = pos
	panel.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
	panel.BorderSizePixel = 0
	panel.BackgroundTransparency = 0.18
	panel.Visible = false
	panel.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(250, 190, 100)
	stroke.Thickness = 2
	stroke.Parent = panel
	return panel
end

local function makeTextLabel(parent, text, size, pos, font, textScale)
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = pos
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(240, 238, 225)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = font or Enum.Font.GothamBold
	label.TextScaled = false
	label.TextSize = textScale or 20
	label.Parent = parent
	return label
end

function HUDController.new(config, player, playerGui)
	local self = {}
	self.SessionActive = false
	self.ActionContainer = nil

	local gui = Instance.new("ScreenGui")
	gui.Name = "PowerTrainingHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	gui.Parent = playerGui

	local leftPanel = makePanel(gui, "LeftPanel", UDim2.new(0.33, 0, 0.22, 0), UDim2.new(0.02, 0, 0.02, 0))
	local topPanel = makePanel(gui, "TopPanel", UDim2.new(0.55, 0, 0.1, 0), UDim2.new(0.22, 0, 0.02, 0))
	local centerPanel = makePanel(gui, "CenterPanel", UDim2.new(0.38, 0, 0.1, 0), UDim2.new(0.31, 0, 0.14, 0))
	local bottomPanel = makePanel(gui, "BottomPanel", UDim2.new(1, 0, 0.2, 0), UDim2.new(0, 0, 0.79, 0))
	bottomPanel.BackgroundTransparency = 0.36

	self.ActionContainer = makePanel(gui, "ActionContainer", UDim2.new(0.34, 0, 0.1, 0), UDim2.new(0.33, 0, 0.88, 0))
	self.ActionContainer.Visible = false

	makeTextLabel(leftPanel, "POWER", UDim2.new(1, -16, 0, 28), UDim2.new(0.08, 0, 0.02, 0), Enum.Font.FredokaOne, 22)
	local txtPower = makeTextLabel(leftPanel, "Power: 0", UDim2.new(1, -16, 0, 26), UDim2.new(0.08, 0, 0.32, 0))
	local txtLevel = makeTextLabel(leftPanel, "Level: 0", UDim2.new(1, -16, 0, 22), UDim2.new(0.08, 0, 0.57, 0), Enum.Font.Gotham, 20)
	local txtStamina = makeTextLabel(leftPanel, "Stamina: 0", UDim2.new(1, -16, 0, 22), UDim2.new(0.08, 0, 0.77, 0), Enum.Font.Gotham, 20)

	makeTextLabel(topPanel, "XP", UDim2.new(1, -16, 0, 24), UDim2.new(0.08, 0, 0.02, 0), Enum.Font.FredokaOne, 22)
	local xpBarBg = Instance.new("Frame")
	xpBarBg.Name = "XPBackground"
	xpBarBg.Size = UDim2.new(0.92, 0, 0.46, 0)
	xpBarBg.Position = UDim2.new(0.04, 0, 0.45, 0)
	xpBarBg.BackgroundColor3 = Color3.fromRGB(24, 32, 45)
	xpBarBg.BorderSizePixel = 0
	xpBarBg.Parent = topPanel
	Instance.new("UICorner", xpBarBg).CornerRadius = UDim.new(0, 8)
	local xpBar = Instance.new("Frame")
	xpBar.Name = "Fill"
	xpBar.Size = UDim2.new(0.2, 0, 1, 0)
	xpBar.BackgroundColor3 = Color3.fromRGB(140, 240, 180)
	xpBar.BorderSizePixel = 0
	xpBar.Parent = xpBarBg
	Instance.new("UICorner", xpBar).CornerRadius = UDim.new(0, 8)
	local txtXP = makeTextLabel(topPanel, "XP: 0 / 0", UDim2.new(1, -16, 0, 18), UDim2.new(0.08, 0, 0.08, 0), Enum.Font.Gotham, 16)
	local txtZone = makeTextLabel(topPanel, "Zone: --", UDim2.new(1, -16, 0, 18), UDim2.new(0.08, 0, 0.72, 0), Enum.Font.Gotham, 15)

	local txtCombo = makeTextLabel(centerPanel, "Combo: 0", UDim2.new(0.6, 0, 1, 0), UDim2.new(0.03, 0, 0.08, 0), Enum.Font.FredokaOne, 30)
	local txtMessage = makeTextLabel(centerPanel, "Start your session from the menu.", UDim2.new(0.97, 0, 0.6, 0), UDim2.new(0.03, 0, 0.2, 0), Enum.Font.Gotham, 18)
	txtMessage.TextWrapped = true
	txtMessage.TextXAlignment = Enum.TextXAlignment.Left
	txtMessage.TextYAlignment = Enum.TextYAlignment.Top

	local feedbackFrame = makePanel(bottomPanel, "Feedback", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0))
	local feedbackText = makeTextLabel(feedbackFrame, "Welcome, warrior.", UDim2.new(1, -12, 1, -8), UDim2.new(0.012, 0, 0.07, 0), Enum.Font.GothamBold, 20)
	feedbackText.TextWrapped = true
	feedbackText.TextYAlignment = Enum.TextYAlignment.Top

	local statRoot = player:WaitForChild("leaderstats")
	local trainingData = player:WaitForChild("PowerTrainingData")

	local function syncStats()
		txtPower.Text = ("Power: %d"):format(statRoot.Power.Value)
		txtLevel.Text = ("Level: %d"):format(statRoot.Level.Value)
		txtStamina.Text = ("Stamina: %d"):format(statRoot.Stamina.Value)
		txtCombo.Text = ("Combo: %d"):format(trainingData.Combo.Value)
		local xpRatio = 0
		if trainingData.NextXP.Value > 0 then
			xpRatio = math.clamp(trainingData.Experience.Value / trainingData.NextXP.Value, 0, 1)
		end
		xpBar.Size = UDim2.new(xpRatio, 0, 1, 0)
		txtXP.Text = ("XP: %d / %d"):format(trainingData.Experience.Value, trainingData.NextXP.Value)
	end

	statRoot.Level.Changed:Connect(syncStats)
	statRoot.Power.Changed:Connect(syncStats)
	statRoot.Stamina.Changed:Connect(syncStats)
	trainingData.Experience.Changed:Connect(syncStats)
	trainingData.NextXP.Changed:Connect(syncStats)
	trainingData.Combo.Changed:Connect(syncStats)

	syncStats()

	local function getInventoryActionDisplay(slot)
		local inventory = player:FindFirstChild("AbilityInventory")
		local slotNode = inventory and inventory:FindFirstChild(("Slot%d"):format(slot))
		local actionName = slotNode and slotNode.Value or ""
		local actionCfg = config.Actions[actionName]
		return actionCfg and (actionCfg.DisplayName or actionName) or ("Slot %d"):format(slot)
	end

	function self.setSessionActive(active)
		self.SessionActive = active
		leftPanel.Visible = active
		topPanel.Visible = active
		centerPanel.Visible = active
		bottomPanel.Visible = active
		self.ActionContainer.Visible = active
		if active then
			feedbackText.Text = ("Session running. Use slots: [1] %s | [2] %s | [3] %s"):format(
				getInventoryActionDisplay(1),
				getInventoryActionDisplay(2),
				getInventoryActionDisplay(3)
			)
		else
			feedbackText.Text = "Pause complete. Return to menu to restart."
		end
		syncStats()
	end

	function self.showActionMessage(msg, color)
		feedbackText.TextColor3 = color or Color3.fromRGB(240, 238, 225)
		feedbackText.Text = msg
		delay(1.5, function()
			if feedbackText and feedbackText.Parent then
				feedbackText.TextColor3 = Color3.fromRGB(240, 238, 225)
			end
		end)
	end

	function self.showFloatingActionResult(text, color)
		local fly = Instance.new("TextLabel")
		fly.Name = "FloatingAction"
		fly.Size = UDim2.fromScale(0.4, 0.06)
		fly.Position = UDim2.new(0.3, 0, 0.33, 0)
		fly.BackgroundTransparency = 1
		fly.Text = text
		fly.TextColor3 = color or Color3.fromRGB(245, 240, 240)
		fly.Font = Enum.Font.GothamBold
		fly.TextScaled = true
		fly.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		fly.TextStrokeTransparency = 0
		fly.ZIndex = 6
		fly.Parent = gui

		local fade = Instance.new("UIGradient")
		fade.Rotation = 90
		fade.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color or Color3.fromRGB(245, 240, 240)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 240, 240)),
		})
		fade.Parent = fly

		local tween = game:GetService("TweenService"):Create(
			fly,
			TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0.3, 0, 0.26, 0), TextTransparency = 1 }
		)
		tween:Play()
		tween.Completed:Connect(function()
			fly:Destroy()
		end)
	end

	function self.getActionContainer()
		return self.ActionContainer
	end

	function self.processFeedback(payload)
		if payload and payload.Zone then
			txtZone.Text = ("Zone: %s"):format(payload.Zone)
		end
		if not payload or not payload.Success then
			self.showActionMessage(payload.Message or "Missed action.", Color3.fromRGB(255, 150, 140))
			return
		end
		self.showActionMessage(payload.Message or "Action registered.", Color3.fromRGB(185, 255, 210))
		local comboText = ("Combo x%s"):format(payload.Combo)
		self.showFloatingActionResult(comboText, Color3.fromRGB(180, 255, 225))
		if payload.LevelUps and payload.LevelUps > 0 then
			self.showActionMessage("LEVEL UP!", Color3.fromRGB(255, 220, 90))
			self.showFloatingActionResult("LEVEL UP", Color3.fromRGB(255, 220, 90))
		end
		syncStats()
	end

	self.setSessionActive(false)
	return self
end

return HUDController
