local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local MenuController = {}

local function makeLabel(parent, name, anchorY, text)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.fromScale(1, 0.2)
	label.Position = UDim2.fromScale(0, anchorY)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(240, 240, 230)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = text
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function makeButton(parent, text, accent, yPos)
	local button = Instance.new("TextButton")
	button.Name = text:gsub(" ", "")
	button.Size = UDim2.new(0.52, 0, 0.16, 0)
	button.Position = UDim2.new(0.24, 0, yPos, 0)
	button.BackgroundColor3 = Color3.fromRGB(35, 40, 48)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(245, 240, 228)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.Parent = parent

	local uic = Instance.new("UICorner")
	uic.CornerRadius = UDim.new(0, 16)
	uic.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = accent
	stroke.Parent = button

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, accent:Lerp(Color3.new(1,1,1), 0.08)),
		ColorSequenceKeypoint.new(1, accent:Lerp(Color3.new(0,0,0), 0.25)),
	})
	grad.Parent = button
	return button
end

function MenuController.new(config, player, menuRemote, playerGui, fxController)
	local self = {}
	self._sessionState = false
	self._callbacks = {}

	function self.onSessionChanged(callback)
		if type(callback) == "function" then
			table.insert(self._callbacks, callback)
		end
	end

	local function emitSessionChanged(active)
		for _, cb in ipairs(self._callbacks) do
			task.spawn(cb, active)
		end
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "AetherMainMenu"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	gui.Parent = playerGui

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(4, 8, 20)
	background.BorderSizePixel = 0
	background.Parent = gui

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(17, 22, 35)),
		ColorSequenceKeypoint.new(0.8, Color3.fromRGB(8, 12, 24)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(2, 6, 11)),
	})
	gradient.Rotation = 90
	gradient.Parent = background

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromScale(0.65, 0.72)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(9, 16, 26)
	panel.BorderColor3 = Color3.fromRGB(255, 180, 95)
	panel.BorderSizePixel = 2
	panel.Parent = background

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 24)
	panelCorner.Parent = panel

	local title = makeLabel(panel, "Title", 0.04, config.Game.Name)
	title.Font = Enum.Font.Bangers
	title.TextScaled = false
	title.TextSize = 48

	local subtitle = makeLabel(panel, "Subtitle", 0.2, config.Game.Subtitle)
	subtitle.TextScaled = false
	subtitle.TextSize = 23

	local tip = makeLabel(panel, "Tip", 0.29, "Press the highlighted actions once ready.")
	tip.TextSize = 16
	tip.TextColor3 = Color3.fromRGB(230, 230, 220)

	local status = makeLabel(panel, "Status", 0.88, "Press Start to enter a session.")
	status.TextSize = 18

	local startButton = makeButton(panel, "Start Session", Color3.fromRGB(255, 126, 73), 0.42)
	local focusButton = makeButton(panel, "Exit to Reclaim", Color3.fromRGB(130, 150, 170), 0.62)

	local function hideMenu()
		local tween = TweenService:Create(
			panel,
			TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Position = UDim2.fromScale(0.5, 1.1), Size = UDim2.fromScale(0.58, 0.62) }
		)
		local bFade = TweenService:Create(background, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			BackgroundColor3 = Color3.fromRGB(4, 8, 12),
		})
		tween:Play()
		bFade:Play()
		tween.Completed:Connect(function()
			gui.Enabled = false
		end)
	end

	local function showMenu()
		gui.Enabled = true
		panel.Position = UDim2.fromScale(0.5, 1.1)
		panel.Size = UDim2.fromScale(0.58, 0.62)
		panel.Visible = true
		TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.65, 0.72),
		}):Play()
		TweenService:Create(background, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
	end

	startButton.MouseEnter:Connect(function()
		if self._sessionState then
			return
		end
		TweenService:Create(startButton, TweenInfo.new(0.15), {Size = UDim2.new(0.56, 0, 0.17, 0)}):Play()
	end)
	startButton.MouseLeave:Connect(function()
		TweenService:Create(startButton, TweenInfo.new(0.15), {Size = UDim2.new(0.52, 0, 0.16, 0)}):Play()
	end)

	startButton.Activated:Connect(function()
		if self._sessionState then
			return
		end
		self._sessionState = true
		menuRemote:FireServer("StartSession")
		emitSessionChanged(true)
		fxController and fxController.queueMessage("Session booted. Charge every strike.", Color3.fromRGB(130, 255, 200))
		hideMenu()
		status.Text = "Session active."
	end)

	focusButton.Activated:Connect(function()
		menuRemote:FireServer("EndSession")
		menuRemote:FireServer("Reset")
		self._sessionState = false
		emitSessionChanged(false)
		showMenu()
		status.Text = "Session ended."
		fxController and fxController.queueMessage("Session reset complete.", Color3.fromRGB(255, 170, 110))
	end)

	return self
end

return MenuController
