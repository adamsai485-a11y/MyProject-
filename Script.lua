--==================================================
-- JJS LOCK-ON + BACK DASH (NO ESP / CLEAN VERSION)
--==================================================

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- НАСТРОЙКИ
--==================================================

local LOCK_RANGE = 90
local BACK_DISTANCE = 3.8
local DASH_TIME_MIN = 0.12
local DASH_TIME_MAX = 0.28
local LOCK_SMOOTHNESS = 0.10
local TOGGLE_UI_KEY = Enum.KeyCode.K

--==================================================
-- ОЧИСТКА СТАРОГО
--==================================================

if CoreGui:FindFirstChild("XenoJJSMenu") then CoreGui.XenoJJSMenu:Destroy() end

--==================================================
-- GUI МЕНЮ
--==================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XenoJJSMenu"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

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

-- Перетаскивание
local dragging, dragInput, dragStart, startPos
title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)

title.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

--==================================================
-- СОСТОЯНИЯ
--==================================================

local isDashEnabled = false
local isLockOnEnabled = false
local isMenuVisible = true
local lockedTargetPart = nil
local currentCharges = 4
local maxCharges = 4
local isCoolingDown = false
local isDashing = false

--==================================================
-- КНОПКИ
--==================================================

local toggleDashBtn = Instance.new("TextButton")
toggleDashBtn.Size = UDim2.new(1, -20, 0, 40)
toggleDashBtn.Position = UDim2.new(0, 10, 0, 40)
toggleDashBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
toggleDashBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleDashBtn.TextSize = 13
toggleDashBtn.Font = Enum.Font.GothamBold
toggleDashBtn.Text = "Back Dash [3]: ВЫКЛ"
toggleDashBtn.Parent = mainFrame
Instance.new("UICorner", toggleDashBtn).CornerRadius = UDim.new(0, 6)

local toggleLockBtn = Instance.new("TextButton")
toggleLockBtn.Size = UDim2.new(1, -20, 0, 40)
toggleLockBtn.Position = UDim2.new(0, 10, 0, 88)
toggleLockBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
toggleLockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleLockBtn.TextSize = 13
toggleLockBtn.Font = Enum.Font.GothamBold
toggleLockBtn.Text = "Лок-он: ВЫКЛ"
toggleLockBtn.Parent = mainFrame
Instance.new("UICorner", toggleLockBtn).CornerRadius = UDim.new(0, 6)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 22)
statusLabel.Position = UDim2.new(0, 10, 0, 135)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "Цель: нет"
statusLabel.Parent = mainFrame

local chargesLabel = Instance.new("TextLabel")
chargesLabel.Size = UDim2.new(1, -20, 0, 20)
chargesLabel.Position = UDim2.new(0, 10, 0, 156)
chargesLabel.BackgroundTransparency = 1
chargesLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
chargesLabel.TextSize = 11
chargesLabel.Font = Enum.Font.Gotham
chargesLabel.Text = "Заряды: 4 / 4"
chargesLabel.Parent = mainFrame

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 0, 70)
infoLabel.Position = UDim2.new(0, 10, 0, 182)
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
infoLabel.TextSize = 11
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextWrapped = true
infoLabel.Text = "ESP полностью удален (чистый FPS). Нажми K чтобы скрыть меню."
infoLabel.Parent = mainFrame

--==================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
--==================================================

local function getRootPart(model)
	if not model or not model:IsA("Model") then return nil end
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then return root end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.RootPart then return humanoid.RootPart end
	if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then return model.PrimaryPart end
	return nil
end

local function getTargetFromModel(model)
	if not model or not model:IsA("Model") then return nil end
	if LocalPlayer.Character == model then return nil end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return nil end
	local root = getRootPart(model)
	if not root then return nil end
	return root
end

local function getBestTarget()
	local character = LocalPlayer.Character
	if not character then return nil end
	local myRoot = getRootPart(character)
	if not myRoot then return nil end

	local bestTarget = nil
	local shortestDistance = LOCK_RANGE
	local checkedModels = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local model = player.Character
			checkedModels[model] = true
			local root = getTargetFromModel(model)
			if root then
				local distance = (myRoot.Position - root.Position).Magnitude
				if distance < shortestDistance then
					shortestDistance = distance
					bestTarget = root
				end
			end
		end
	end

	for _, child in ipairs(workspace:GetChildren()) do
		if child:IsA("Model") and child ~= character and not checkedModels[child] then
			local root = getTargetFromModel(child)
			if root then
				local distance = (myRoot.Position - root.Position).Magnitude
				if distance < shortestDistance then
					shortestDistance = distance
					bestTarget = root
				end
			end
		end
	end

	return bestTarget
end

local function isTargetValid()
	if not lockedTargetPart or not lockedTargetPart.Parent then return false end
	local model = lockedTargetPart.Parent
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	
	local character = LocalPlayer.Character
	if character then
		local myRoot = getRootPart(character)
		if myRoot and (myRoot.Position - lockedTargetPart.Position).Magnitude > LOCK_RANGE * 1.3 then
			return false
		end
	end
	return true
end

local function updateCharges()
	chargesLabel.Text = "Заряды: " .. tostring(currentCharges) .. " / " .. tostring(maxCharges)
end

--==================================================
-- КНОПКИ УПРАВЛЕНИЯ
--==================================================

toggleLockBtn.MouseButton1Click:Connect(function()
	isLockOnEnabled = not isLockOnEnabled
	if isLockOnEnabled then
		local target = getBestTarget()
		if target then
			lockedTargetPart = target
			toggleLockBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
			toggleLockBtn.Text = "Лок-он: ВКЛ"
			statusLabel.Text = "Цель: " .. target.Parent.Name
		else
			isLockOnEnabled = false
			lockedTargetPart = nil
			toggleLockBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
			toggleLockBtn.Text = "Лок-он: ВЫКЛ"
			statusLabel.Text = "Цель: нет"
		end
	else
		lockedTargetPart = nil
		toggleLockBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
		toggleLockBtn.Text = "Лок-он: ВЫКЛ"
		statusLabel.Text = "Цель: нет"
	end
end)

toggleDashBtn.MouseButton1Click:Connect(function()
	isDashEnabled = not isDashEnabled
	if isDashEnabled then
		toggleDashBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
		toggleDashBtn.Text = "Back Dash [3]: ВКЛ"
	else
		toggleDashBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
		toggleDashBtn.Text = "Back Dash [3]: ВЫКЛ"
	end
end)

--==================================================
-- BACK DASH
--==================================================

local function executeBackDash()
	if not isDashEnabled or not isLockOnEnabled or isCoolingDown or isDashing or currentCharges <= 0 then return end
	if not isTargetValid() then
		lockedTargetPart = nil
		isLockOnEnabled = false
		toggleLockBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
		toggleLockBtn.Text = "Лок-он: ВЫКЛ"
		statusLabel.Text = "Цель: нет"
		return
	end

	local character = LocalPlayer.Character
	if not character then return end
	local rootPart = getRootPart(character)
	if not rootPart then return end

	local targetRoot = lockedTargetPart
	local startPosition = rootPart.Position

	local targetVelocity = targetRoot.AssemblyLinearVelocity or Vector3.zero
	local predictedPosition = targetRoot.Position + (targetVelocity * 0.12)
	local targetLook = targetRoot.CFrame.LookVector
	local destination = predictedPosition - targetLook * BACK_DISTANCE
	destination = Vector3.new(destination.X, startPosition.Y, destination.Z)

	local initialDistance = (destination - startPosition).Magnitude
	if initialDistance < 0.5 then return end

	currentCharges -= 1
	updateCharges()

	isDashing = true
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local oldAutoRotate = nil
	if humanoid then
		oldAutoRotate = humanoid.AutoRotate
		humanoid.AutoRotate = false
	end

	local dashTime = math.clamp(initialDistance / 45, DASH_TIME_MIN, DASH_TIME_MAX)
	local startTime = os.clock()
	local connection

	connection = RunService.Heartbeat:Connect(function()
		if not rootPart or not rootPart.Parent or not isTargetValid() then
			connection:Disconnect()
			isDashing = false
			if humanoid and humanoid.Parent then humanoid.AutoRotate = oldAutoRotate end
			return
		end

		local elapsed = os.clock() - startTime
		local alpha = math.clamp(elapsed / dashTime, 0, 1)
		local smoothAlpha = alpha * alpha * (3 - 2 * alpha)

		local curVel = targetRoot.AssemblyLinearVelocity or Vector3.zero
		local curPredPos = targetRoot.Position + (curVel * 0.1)
		local curLook = targetRoot.CFrame.LookVector
		local currentBackPosition = curPredPos - curLook * BACK_DISTANCE
		currentBackPosition = Vector3.new(currentBackPosition.X, startPosition.Y, currentBackPosition.Z)

		local newPosition = startPosition:Lerp(currentBackPosition, smoothAlpha)
		local lookPosition = Vector3.new(curPredPos.X, newPosition.Y, curPredPos.Z)

		if (lookPosition - newPosition).Magnitude > 0.01 then
			rootPart.CFrame = CFrame.lookAt(newPosition, lookPosition)
		else
			rootPart.CFrame = CFrame.new(newPosition)
		end

		if alpha >= 1 then
			local finalPredPos = targetRoot.Position + ((targetRoot.AssemblyLinearVelocity or Vector3.zero) * 0.05)
			local finalLook = targetRoot.CFrame.LookVector
			local finalPosition = finalPredPos - finalLook * BACK_DISTANCE
			finalPosition = Vector3.new(finalPosition.X, startPosition.Y, finalPosition.Z)
			local finalLookAt = Vector3.new(finalPredPos.X, finalPosition.Y, finalPosition.Z)

			rootPart.CFrame = CFrame.lookAt(finalPosition, finalLookAt)
			rootPart.AssemblyLinearVelocity = Vector3.zero

			connection:Disconnect()
			isDashing = false
			if humanoid and humanoid.Parent then humanoid.AutoRotate = oldAutoRotate end
		end
	end)

	if currentCharges <= 0 then
		isCoolingDown = true
		toggleDashBtn.Text = "Заряды восстанавливаются..."
		toggleDashBtn.BackgroundColor3 = Color3.fromRGB(200, 140, 0)
		task.delay(3, function()
			currentCharges = maxCharges
			isCoolingDown = false
			updateCharges()
			if isDashEnabled then
				toggleDashBtn.Text = "Back Dash [3]: ВКЛ"
				toggleDashBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
			else
				toggleDashBtn.Text = "Back Dash [3]: ВЫКЛ"
				toggleDashBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
			end
		end)
	end
end

--==================================================
-- РЕНДЕР (LOCK-ON)
--==================================================

RunService.RenderStepped:Connect(function()
	if not isLockOnEnabled then return end

	if not isTargetValid() then
		local newTarget = getBestTarget()
		if newTarget then
			lockedTargetPart = newTarget
		else
			isLockOnEnabled = false
			lockedTargetPart = nil
			toggleLockBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
			toggleLockBtn.Text = "Лок-он: ВЫКЛ"
			statusLabel.Text = "Цель: нет"
			return
		end
	end

	if isDashing then return end

	local character = LocalPlayer.Character
	if not character then return end
	local myRoot = getRootPart(character)
	if not myRoot then return end

	local targetPosition = lockedTargetPart.Position
	local flatTarget = Vector3.new(targetPosition.X, myRoot.Position.Y, targetPosition.Z)
	local direction = flatTarget - myRoot.Position

	if direction.Magnitude > 0.1 then
		local goalCFrame = CFrame.lookAt(myRoot.Position, flatTarget)
		myRoot.CFrame = myRoot.CFrame:Lerp(goalCFrame, LOCK_SMOOTHNESS)
	end

	statusLabel.Text = "Цель: " .. lockedTargetPart.Parent.Name
end)

--==================================================
-- КЛАВИШИ
--==================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.Three or input.KeyCode == Enum.KeyCode.KeypadThree then
		if not gameProcessed then executeBackDash() end
	end
	if input.KeyCode == TOGGLE_UI_KEY then
		isMenuVisible = not isMenuVisible
		mainFrame.Visible = isMenuVisible
	end
end)

updateCharges()
print("[Xeno] Clean JJS Script loaded without ESP!")
