--==================================================
-- JJS LOCK-ON + BACK DASH (PRO ARCHITECTURE V2)
--==================================================

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- НАСТРОЙКИ
--==================================================

local LOCK_RANGE = 90
local BACK_DISTANCE = 4.2      -- Чуть увеличили, чтобы не сливаться вплотную с моделью
local DASH_TIME_MIN = 0.12
local DASH_TIME_MAX = 0.28
local LOCK_SMOOTHNESS = 0.12
local TOGGLE_UI_KEY = Enum.KeyCode.K

--==================================================
-- ОЧИСТКА СТАРОГО GUI
--==================================================

for _, gui in ipairs(CoreGui:GetChildren()) do
	if gui.Name == "XenoJJSMenu" then
		gui:Destroy()
	end
end

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

-- Перетаскивание меню
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
-- СОСТОЯНИЯ И МЕНЕДЖЕРЫ (ЦЕНТРАЛИЗАЦИЯ)
--==================================================

local isDashEnabled = false
local isLockOnEnabled = false
local isMenuVisible = true
local lockedTargetPart = nil
local currentCharges = 4
local maxCharges = 4
local isCoolingDown = false
local isDashing = false

-- Элементы интерфейса
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
infoLabel.Text = "Архитектурно чистый JJS скрипт. Нажми K для скрытия меню."
infoLabel.Parent = mainFrame

-- Единые функции управления состоянием (исключают рассинхрон GUI)
local function setLockState(state, target, targetName)
	isLockOnEnabled = state
	lockedTargetPart = target
	if state and target then
		toggleLockBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
		toggleLockBtn.Text = "Лок-он: ВКЛ"
		statusLabel.Text = "Цель: " .. (targetName or "Неизвестно")
	else
		toggleLockBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
		toggleLockBtn.Text = "Лок-он: ВЫКЛ"
		statusLabel.Text = "Цель: нет"
	end
end

local function setDashState(state, customText, customColor)
	isDashEnabled = state
	if customText then
		toggleDashBtn.Text = customText
		toggleDashBtn.BackgroundColor3 = customColor or Color3.fromRGB(150, 40, 40)
	else
		if state then
			toggleDashBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
			toggleDashBtn.Text = "Back Dash [3]: ВКЛ"
		else
			toggleDashBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
			toggleDashBtn.Text = "Back Dash [3]: ВЫКЛ"
		end
	end
end

local function updateChargesDisplay()
	chargesLabel.Text = "Заряды: " .. tostring(currentCharges) .. " / " .. tostring(maxCharges)
end

--==================================================
-- ОПТИМИЗИРОВАННЫЕ ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
--==================================================

local function getRootPart(model)
	if not model or not model:IsA("Model") then return nil end
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then return root end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.RootPart then return humanoid.RootPart end
	return model.PrimaryPart
end

-- Оптимизированный поиск цели (без мусорного перебора всего workspace)
local function getBestTarget()
	local character = LocalPlayer.Character
	if not character then return nil end
	local myRoot = getRootPart(character)
	if not myRoot then return nil end

	local bestTarget = nil
	local shortestDistance = LOCK_RANGE

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local model = player.Character
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local root = getRootPart(model)
			if humanoid and humanoid.Health > 0 and root then
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

--==================================================
-- БЕЗОПАСНЫЙ БЭК-ДЭШ (С RAYCAST ПРОВЕРКОЙ СТЕН)
--==================================================

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function executeBackDash()
	if not isDashEnabled or not isLockOnEnabled or isCoolingDown or isDashing or currentCharges <= 0 then return end
	if not isTargetValid() then
		setLockState(false, nil)
		return
	end

	local character = LocalPlayer.Character
	if not character then return end
	local rootPart = getRootPart(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not rootPart or not humanoid then return end

	currentCharges -= 1
	updateChargesDisplay()

	isDashing = true
	local oldAutoRotate = humanoid.AutoRotate
	humanoid.AutoRotate = false

	local targetRoot = lockedTargetPart
	local targetCFrame = targetRoot.CFrame
	
	-- Желаемая точка за спиной
	local destinationCFrame = targetCFrame * CFrame.new(0, 0, BACK_DISTANCE)
	local targetPos = Vector3.new(destinationCFrame.Position.X, rootPart.Position.Y, destinationCFrame.Position.Z)

	-- РЕЙКАСТ: проверяем, нет ли стены между текущей позицией игрока и точкой позади врага
	raycastParams.FilterDescendantsInstances = {character, targetRoot.Parent}
	local rayResult = workspace:Raycast(rootPart.Position, targetPos - rootPart.Position, raycastParams)
	
|-- Если на пути стена, корректируем конечную точку перед ней, чтобы не застрять
	if rayResult then
		targetPos = rayResult.Position + (rootPart.Position - targetPos).Unit * 1.5
	end

	local finalCFrame = CFrame.lookAt(targetPos, Vector3.new(targetRoot.Position.X, targetPos.Y, targetRoot.Position.Z))

	local distance = (rootPart.Position - targetPos).Magnitude
	local dashTime = math.clamp(distance / 55, DASH_TIME_MIN, DASH_TIME_MAX)

	local tweenInfo = TweenInfo.new(
		dashTime,
		Enum.EasingStyle.Cubic,
		Enum.EasingDirection.Out
	)

	local dashTween = TweenService:Create(rootPart, tweenInfo, {CFrame = finalCFrame})
	
	rootPart.AssemblyLinearVelocity = Vector3.zero
	dashTween:Play()
	dashTween.Completed:Wait()

	rootPart.AssemblyLinearVelocity = Vector3.zero
	humanoid.AutoRotate = oldAutoRotate
	isDashing = false

	if currentCharges <= 0 then
		isCoolingDown = true
		setDashState(false, "Заряды восстанавливаются...", Color3.fromRGB(200, 140, 0))
		task.delay(3, function()
			currentCharges = maxCharges
			isCoolingDown = false
			updateChargesDisplay()
			setDashState(isDashEnabled)
		end)
	end
end

--==================================================
-- ОБРАБОТЧИКИ КНОПОК
--==================================================

toggleLockBtn.MouseButton1Click:Connect(function()
	if not isLockOnEnabled then
		local target = getBestTarget()
		if target then
			setLockState(true, target, target.Parent.Name)
		else
			setLockState(false, nil)
		end
	else
		setLockState(false, nil)
	end
end)

toggleDashBtn.MouseButton1Click:Connect(function()
	if isCoolingDown then return end
	setDashState(not isDashEnabled)
end)

--==================================================
-- РЕНДЕР (ЛОК-ОН СТАБИЛЬНЫЙ)
--==================================================

RunService.RenderStepped:Connect(function()
	if not isLockOnEnabled then return end

	if not isTargetValid() then
		local newTarget = getBestTarget()
		if newTarget then
			setLockState(true, newTarget, newTarget.Parent.Name)
		else
			setLockState(false, nil)
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
-- ГОРЯЧИЕ КЛАВИШИ
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

updateChargesDisplay()
print("[Xeno] Pro Architecture JJS Script Loaded Safely!")
