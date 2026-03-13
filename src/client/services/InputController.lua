local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local InputController = {}

local function normalizeColorForQuality(quality)
	if quality == "Shatter" then
		return Color3.fromRGB(255, 105, 105)
	elseif quality == "Perfect" then
		return Color3.fromRGB(255, 245, 160)
	elseif quality == "Great" then
		return Color3.fromRGB(255, 210, 100)
	else
		return Color3.fromRGB(185, 255, 195)
	end
end

local function makeMobileButton(parent, actionName, caption, callback)
	local button = Instance.new("TextButton")
	button.Name = actionName .. "MobileButton"
	button.Text = caption
	button.Size = UDim2.new(0.31, 0, 0.75, 0)
	button.BackgroundColor3 = Color3.fromRGB(28, 34, 46)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 18
	button.TextColor3 = Color3.fromRGB(240, 236, 220)
	button.Parent = parent
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 12)
	Instance.new("UIStroke", button).Color = Color3.fromRGB(255, 170, 110)
	button.MouseButton1Click:Connect(function()
		callback(actionName)
	end)
	return button
end

function InputController.new(config, player, actionRemote, menuController, hud)
	local self = {}
	self.Enabled = false

	local function fireAction(actionName)
		if not self.Enabled then
			return
		end
		actionRemote:FireServer(actionName)
		if hud and hud.showActionMessage then
			local actionConfig = config.Actions[actionName]
			local message = actionConfig and actionConfig.DisplayName or actionName
			hud.showActionMessage(("Executing %s"):format(message), normalizeColorForQuality("Clean"))
		end
	end

	local actionMap = {
		Punch = Enum.KeyCode.Q,
		Focus = Enum.KeyCode.E,
		Dash = Enum.KeyCode.R,
	}
	for actionName, key in pairs(actionMap) do
		ContextActionService:BindAction(
			"Aether" .. actionName,
			function(_, state)
				if state == Enum.UserInputState.Begin then
					fireAction(actionName)
				end
				return Enum.ContextActionResult.Sink
			end,
			false,
			key
		)
	end

	ContextActionService:BindAction(
		"AetherShift",
		function(_, state)
			if state == Enum.UserInputState.Begin and UserInputService.KeyboardEnabled then
				fireAction("Dash")
			end
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.KeyCode.Space
	)

	local actionContainer = hud and hud.getActionContainer and hud.getActionContainer()
	if actionContainer then
		actionContainer:ClearAllChildren()
		actionContainer.Visible = self.Enabled
		local list = Instance.new("UIListLayout")
		list.Padding = UDim.new(0, 8)
		list.FillDirection = Enum.FillDirection.Horizontal
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.Parent = actionContainer

		makeMobileButton(actionContainer, "Punch", "POWER [Q]", fireAction)
		makeMobileButton(actionContainer, "Focus", "FOCUS [E]", fireAction)
		makeMobileButton(actionContainer, "Dash", "DASH [R]", fireAction)
	end

	function self.setSessionEnabled(enabled)
		self.Enabled = enabled
		if actionContainer then
			actionContainer.Visible = enabled
		end
	end

	menuController.onSessionChanged(function(active)
		self.setSessionEnabled(active)
	end)

	return self
end

return InputController
