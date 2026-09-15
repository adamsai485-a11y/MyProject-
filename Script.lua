--==================================================
-- JJS LOCK-ON + BACK DASH (STABLE TWEEN VERSION)
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- НАСТРОЙКИ
--==================================================

local LOCK_RANGE = 90
local LOCK_VALID_RANGE = LOCK_RANGE * 1.3

local BACK_DISTANCE = 4.2

local DASH_TIME_MIN = 0.12
local DASH_TIME_MAX = 0.28
local DASH_SPEED = 55

local LOCK_SMOOTHNESS = 0.12

local MAX_CHARGES = 4
local CHARGE_COOLDOWN = 3

local TOGGLE_UI_KEY = Enum.KeyCode.K
local DASH_KEY = Enum.KeyCode.Three

--==================================================
-- ОЧИСТКА СТАРОГО GUI (ПРИ ПЕРЕЗАПУСКЕ)
--==================================================

for _, gui in ipairs(PlayerGui:GetChildren()) do
	if gui.Name == "JJSAbilityMenu" then
		gui:Destroy()
	end
end

--==================================================
-- СОСТОЯНИЯ
--==================================================

local State = {
	DashEnabled = false,
	LockOnEnabled = false,
	MenuVisible = true,

	Target = nil,

	Charges = MAX_CHARGES,
	MaxCharges = MAX_CHARGES,

	CoolingDown = false,
	Dashing = false,

	Destroyed = false,
}

--==================================================
-- GUI
--==================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "JJSAbilityMenu"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 270)
mainFrame.Position = UDim2.new(0, 50, 0, 150)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "JJS Dash + Lock [3] (K - меню)"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

--==================================================
-- DRAG MENU
--==================================================

local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

title.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then

		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart

		mainFrame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

--==================================================
-- UI ELEMENTS
--==================================================

local toggleDashBtn = Instance.new("TextButton")
toggleDashBtn.Size = UDim2.new(1, -20, 0, 40)
toggleDashBtn.Position = UDim2.new(0, 10, 0, 40)
toggleDashBtn.Parent = mainFrame

Instance.new("UICorner", toggleDashBtn).CornerRadius = UDim.new(0, 6)

toggleDashBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleDashBtn.TextSize = 13
toggleDashBtn.Font = Enum.Font.GothamBold

local toggleLockBtn = Instance.new("TextButton")
toggleLockBtn.Size = UDim2.new(1, -20, 0, 40)
toggleLockBtn.Position = UDim2.new(0, 10, 0, 88)
toggleLockBtn.Parent = mainFrame

Instance.new("UICorner", toggleLockBtn).CornerRadius = UDim.new(0, 6)

toggleLockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleLockBtn.TextSize = 13
toggleLockBtn.Font = Enum.Font.GothamBold

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 22)
statusLabel.Position = UDim2.new(0, 10, 0, 135)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = mainFrame

local chargesLabel = Instance.new("TextLabel")
chargesLabel.Size = UDim2.new(1, -20, 0, 20)
chargesLabel.Position = UDim2.new(0, 10, 0, 156)
chargesLabel.BackgroundTransparency = 1
chargesLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
chargesLabel.TextSize = 11
chargesLabel.Font = Enum.Font.Gotham
chargesLabel.Parent = mainFrame

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 0, 70)
infoLabel.Position = UDim2.new(0, 10, 0, 182)
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
infoLabel.TextSize = 11
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextWrapped = true
infoLabel.Text = "JJS Lock-On + Back Dash System."
infoLabel.Parent = mainFrame

--==================================================
-- UI STATE
--==================================================

local function updateChargesDisplay()
	chargesLabel.Text =
		"Заряды: "
		.. tostring(State.Charges)
		.. " / "
		.. tostring(State.MaxCharges)
end

local function updateDashButtonVisual()
	if State.CoolingDown then
		toggleDashBtn.Text = "Заряды восстанавливаются..."
		toggleDashBtn.BackgroundColor3 = Color3.fromRGB(200, 140, 0)

	elseif State.DashEnabled then
		toggleDashBtn.Text = "Back Dash [3]: ВКЛ"
		toggleDashBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)

	else
		toggleDashBtn.Text = "Back Dash [3]: ВЫКЛ"
		toggleDashBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
	end
end

local function setLockState(enabled, target)
	State.LockOnEnabled = enabled
	State.Target = target

	if enabled and target then
		toggleLockBtn.Text = "Лок-он: ВКЛ"
		toggleLockBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)

		statusLabel.Text = "Цель: " .. target.Parent.Name
	else
		toggleLockBtn.Text = "Лок-он: ВЫКЛ"
		toggleLockBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)

		statusLabel.Text = "Цель: нет"
	end
end

--==================================================
-- CHARACTER HELPERS
--==================================================

local function getRootPart(model)
	if not model or not model:IsA("Model") then
		return nil
	end

	local root = model:FindFirstChild("HumanoidRootPart")

	if root and root:IsA("BasePart") then
		return root
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")

	if humanoid and humanoid.RootPart then
		return humanoid.RootPart
	end

	local primary = model.PrimaryPart

	if primary and primary:IsA("BasePart") then
		return primary
	end

	return nil
end

local function getHumanoid(model)
	if not model or not model:IsA("Model") then
		return nil
	end

	return model:FindFirstChildOfClass("Humanoid")
end

--==================================================
-- TARGET SEARCH
--==================================================

local function getBestTarget()
	local character = LocalPlayer.Character

	if not character then
		return nil
	end

	local myRoot = getRootPart(character)

	if not myRoot then
		return nil
	end

	local bestTarget = nil
	local shortestDistance = LOCK_RANGE

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then

			local model = player.Character
			local humanoid = getHumanoid(model)
			local root = getRootPart(model)

			if humanoid
				and humanoid.Health > 0
				and root then

				local distance =
					(myRoot.Position - root.Position).Magnitude

				if distance < shortestDistance then
					shortestDistance = distance
					bestTarget = root
				end
			end
		end
	end

	return bestTarget
end

--==================================================
-- TARGET VALIDATION
--==================================================

local function isTargetValid()
	local target = State.Target

	if not target then
		return false
	end

	if not target.Parent then
		return false
	end

	if not target:IsA("BasePart") then
		return false
	end

	local model = target.Parent
	local humanoid = getHumanoid(model)

	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	local character = LocalPlayer.Character

	if not character then
		return false
	end

	local myRoot = getRootPart(character)

	if not myRoot then
		return false
	end

	local distance =
		(myRoot.Position - target.Position).Magnitude

	if distance > LOCK_VALID_RANGE then
		return false
	end

	return true
end

--==================================================
-- RAYCAST
--==================================================

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function calculateSafeDestination(rootPart, targetRoot)
	local targetCFrame = targetRoot.CFrame

	local desiredCFrame =
		targetCFrame * CFrame.new(0, 0, BACK_DISTANCE)

	local desiredPosition = Vector3.new(
		desiredCFrame.Position.X,
		rootPart.Position.Y,
		desiredCFrame.Position.Z
	)

	local dashVector = desiredPosition - rootPart.Position
	local distance = dashVector.Magnitude

	if distance <= 0.05 then
		return desiredPosition
	end

	raycastParams.FilterDescendantsInstances = {
		LocalPlayer.Character,
		targetRoot.Parent
	}

	local result = workspace:Raycast(
		rootPart.Position,
		dashVector,
		raycastParams
	)

	if not result then
		return desiredPosition
	end

	local safeDistance = math.max(
		result.Distance - 1.5,
		0
	)

	local direction = dashVector.Unit

	return rootPart.Position + direction * safeDistance
end

--==================================================
-- DASH CLEANUP
--==================================================

local activeTween = nil

local function stopDash()
	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end

	State.Dashing = false

	local character = LocalPlayer.Character

	if character then
		local humanoid = getHumanoid(character)
		local root = getRootPart(character)

		if humanoid then
			humanoid.AutoRotate = true
		end

		if root then
			local curVel = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(0, math.min(curVel.Y, 0), 0)
		end
	end
end

--==================================================
-- CHARGE REGEN
--==================================================

local function startChargeCooldown()
	if State.CoolingDown then
		return
	end

	State.CoolingDown = true
	updateDashButtonVisual()

	task.delay(CHARGE_COOLDOWN, function()

		if State.Destroyed then
			return
		end

		State.Charges = State.MaxCharges
		State.CoolingDown = false

		updateChargesDisplay()
		updateDashButtonVisual()
	end)
end

--==================================================
-- BACK DASH (OPTIMIZED TWEEN)
--==================================================

local function executeBackDash()
	if State.Destroyed then
		return
	end

	if not State.DashEnabled then
		return
	end

	if not State.LockOnEnabled then
		return
	end

	if State.CoolingDown then
		return
	end

	if State.Dashing then
		return
	end

	if State.Charges <= 0 then
		return
	end

	if not isTargetValid() then
		setLockState(false, nil)
		return
	end

	local character = LocalPlayer.Character

	if not character then
		return
	end

	local rootPart = getRootPart(character)
	local humanoid = getHumanoid(character)
	local targetRoot = State.Target

	if not rootPart or not humanoid or not targetRoot then
		return
	end

	local oldAutoRotate = humanoid.AutoRotate

	State.Charges -= 1
	updateChargesDisplay()

	State.Dashing = true
	humanoid.AutoRotate = false

	local targetPosition = calculateSafeDestination(
		rootPart,
		targetRoot
	)

	local lookPosition = Vector3.new(
		targetRoot.Position.X,
		targetPosition.Y,
		targetPosition.Z
	)

	local finalCFrame =
		CFrame.lookAt(targetPosition, lookPosition)

	local distance =
		(rootPart.Position - targetPosition).Magnitude

	if distance <= 0.05 then
		humanoid.AutoRotate = oldAutoRotate
		State.Dashing = false

		if State.Charges <= 0 then
			startChargeCooldown()
		end

		return
	end

	local dashTime = math.clamp(
		distance / DASH_SPEED,
		DASH_TIME_MIN,
		DASH_TIME_MAX
	)

	local tweenInfo = TweenInfo.new(
		dashTime,
		Enum.EasingStyle.Cubic,
		Enum.EasingDirection.Out
	)

	rootPart.AssemblyLinearVelocity = Vector3.zero

	activeTween = TweenService:Create(
		rootPart,
		tweenInfo,
		{
			CFrame = finalCFrame
		}
	)

	activeTween:Play()

	local completed = false

	local connection
	connection = activeTween.Completed:Connect(function()
		completed = true

		if connection then
			connection:Disconnect()
			connection = nil
		end
	end)

	while not completed do
		if State.Destroyed then
			break
		end

		if not character.Parent then
			break
		end

		if not rootPart.Parent then
			break
		end

		-- Аварийное прерывание, если цель исчезла прямо во время рывка
		if not targetRoot or not targetRoot.Parent then
			if activeTween then
				activeTween:Cancel()
			end
			break
		end

		task.wait()
	end

	if connection then
		connection:Disconnect()
	end

	activeTween = nil

	if rootPart.Parent then
		local curVel = rootPart.AssemblyLinearVelocity
		rootPart.AssemblyLinearVelocity = Vector3.new(0, math.min(curVel.Y, 0), 0)
	end

	if humanoid.Parent then
		humanoid.AutoRotate = oldAutoRotate
	end

	State.Dashing = false

	if State.Charges <= 0 and not State.CoolingDown then
		startChargeCooldown()
	end
end

--==================================================
-- BUTTONS
--==================================================

toggleLockBtn.MouseButton1Click:Connect(function()
	if State.Dashing then
		return
	end

	if not State.LockOnEnabled then
		local target = getBestTarget()

		if target then
			setLockState(true, target)
		else
			setLockState(false, nil)
		end
	else
		setLockState(false, nil)
	end
end)

toggleDashBtn.MouseButton1Click:Connect(function()
	if State.CoolingDown then
		return
	end

	State.DashEnabled = not State.DashEnabled

	updateDashButtonVisual()
end)

--==================================================
-- LOCK-ON RENDER
--==================================================

RunService.RenderStepped:Connect(function()
	if State.Destroyed then
		return
	end

	if not State.LockOnEnabled then
		return
	end

	if not isTargetValid() then
		local newTarget = getBestTarget()

		if newTarget then
			setLockState(true, newTarget)
		else
			setLockState(false, nil)
			return
		end
	end

	if State.Dashing then
		return
	end

	local character = LocalPlayer.Character

	if not character then
		setLockState(false, nil)
		return
	end

	local myRoot = getRootPart(character)

	if not myRoot then
		setLockState(false, nil)
		return
	end

	local target = State.Target

	if not target or not target.Parent then
		setLockState(false, nil)
		return
	end

	local targetPosition = target.Position

	local flatTarget = Vector3.new(
		targetPosition.X,
		myRoot.Position.Y,
		targetPosition.Z
	)

	local direction = flatTarget - myRoot.Position

	if direction.Magnitude > 0.1 then
		local goalCFrame =
			CFrame.lookAt(myRoot.Position, flatTarget)

		myRoot.CFrame =
			myRoot.CFrame:Lerp(
				goalCFrame,
				LOCK_SMOOTHNESS
			)
	end

	statusLabel.Text =
		"Цель: " .. target.Parent.Name
end)

--==================================================
-- CHARACTER RESPAWN
--==================================================

LocalPlayer.CharacterAdded:Connect(function()
	stopDash()
	setLockState(false, nil)
end)

--==================================================
-- INPUT
--==================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == DASH_KEY
		or input.KeyCode == Enum.KeyCode.KeypadThree then

		executeBackDash()
	end

	if input.KeyCode == TOGGLE_UI_KEY then
		State.MenuVisible = not State.MenuVisible
		mainFrame.Visible = State.MenuVisible
	end
end)

--==================================================
-- INITIAL UI
--==================================================

updateChargesDisplay()
updateDashButtonVisual()
setLockState(false, nil)

print("[Game] JJS Ability Script Successfully Initialized!")
