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
		callback()
	end)
	return button
end

function InputController.new(config, player, actionRemote, menuController, hud)
	local self = {}
	self.Enabled = false
	local defaultInventory = {
		[1] = "Punch",
		[2] = "Sprint",
		[3] = "Focus",
	}

	local function getAbilityInventory()
		return player:FindFirstChild("AbilityInventory")
	end

	local function resolveActionFromSlot(slot)
		if slot < 1 or slot > 3 then
			return nil
		end
		local inventory = getAbilityInventory()
		local slotNode = inventory and inventory:FindFirstChild(("Slot%d"):format(slot))
		if slotNode and config.Actions[slotNode.Value] then
			return slotNode.Value
		end
		return config.Actions[defaultInventory[slot]] and defaultInventory[slot] or nil
	end

	local function fireAction(actionName, slot)
		if not self.Enabled then
			return
		end
		if not actionName then
			return
		end
		actionRemote:FireServer(actionName)
		if hud and hud.showActionMessage then
			local actionConfig = config.Actions[actionName]
			local message = actionConfig and actionConfig.DisplayName or actionName
			if slot then
				message = ("Slot %d -> %s"):format(slot, message)
			end
			hud.showActionMessage(("Executing %s"):format(message), normalizeColorForQuality("Clean"))
		end
	end

	local function buildInventoryMobileButtons()
		if not actionContainer then
			return
		end
		for _, child in ipairs(actionContainer:GetChildren()) do
			if child:IsA("TextButton") or child:IsA("UIGridLayout") then
				child:Destroy()
			end
		end

		local layout = Instance.new("UIGridLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.CellSize = UDim2.new(0.31, 0, 0.78, 0)
		layout.CellPadding = UDim2.new(0.01, 0, 0.08, 0)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = actionContainer

		for slot = 1, 3 do
			local actionName = resolveActionFromSlot(slot)
			local actionCfg = config.Actions[actionName]
			local label = ("[%d] %s"):format(slot, actionCfg and (actionCfg.DisplayName or actionName) or "Unavailable")
			makeMobileButton(actionContainer, ("Slot%d"):format(slot), label, function()
				fireAction(resolveActionFromSlot(slot), slot)
			end)
		end
	end

	local actionMap = {
		Punch = Enum.KeyCode.Q,
		UpperCut = Enum.KeyCode.E,
		Flurry = Enum.KeyCode.F,
		Dash = Enum.KeyCode.R,
		Sprint = Enum.KeyCode.T,
		Focus = Enum.KeyCode.G,
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

	local slotActionMap = {
		{ Slot = 1, Primary = Enum.KeyCode.One, Alt = Enum.KeyCode.KeypadOne },
		{ Slot = 2, Primary = Enum.KeyCode.Two, Alt = Enum.KeyCode.KeypadTwo },
		{ Slot = 3, Primary = Enum.KeyCode.Three, Alt = Enum.KeyCode.KeypadThree },
	}
	for _, slotAction in ipairs(slotActionMap) do
		ContextActionService:BindAction(
			"AetherSlot" .. slotAction.Slot,
			function(_, state)
				if state == Enum.UserInputState.Begin then
					fireAction(resolveActionFromSlot(slotAction.Slot), slotAction.Slot)
				end
				return Enum.ContextActionResult.Sink
			end,
			false,
			slotAction.Primary,
			slotAction.Alt
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
		buildInventoryMobileButtons()
	end

	function self.setSessionEnabled(enabled)
		self.Enabled = enabled
		if actionContainer then
			actionContainer.Visible = enabled
			if enabled then
				buildInventoryMobileButtons()
			end
		end
	end

	menuController.onSessionChanged(function(active)
		self.setSessionEnabled(active)
	end)

	return self
end

return InputController
