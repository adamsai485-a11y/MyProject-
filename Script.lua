--==================================================
-- JJS LOCK-ON + BACK DASH
-- Players + NPC/Dummy support
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

-- Расстояние за спиной цели
local BACK_DISTANCE = 3.8

-- Время самого перемещения
local DASH_TIME_MIN = 0.12
local DASH_TIME_MAX = 0.28

-- Плавность Lock-on
local LOCK_SMOOTHNESS = 0.10

--==================================================
-- УДАЛЯЕМ СТАРОЕ МЕНЮ
--==================================================

if CoreGui:FindFirstChild("XenoJJSMenu") then
	CoreGui.XenoJJSMenu:Destroy()
end

--==================================================
-- GUI
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

--==================================================
-- TITLE
--==================================================

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "JJS Human Dash [3]"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

--==================================================
-- СОСТОЯНИЯ
--==================================================

local isDashEnabled = false
local isLockOnEnabled = false

local lockedTargetPart = nil

local currentCharges = 4
local maxCharges = 4

local isCoolingDown = false
local isDashing = false

--==================================================
-- КНОПКА BACK DASH
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

local dashCorner = Instance.new("UICorner")
dashCorner.CornerRadius = UDim.new(0, 6)
dashCorner.Parent = toggleDashBtn

--==================================================
-- КНОПКА LOCK-ON
--==================================================

local toggleLockBtn = Instance.new("TextButton")
toggleLockBtn.Size = UDim2.new(1, -20, 0, 40)
toggleLockBtn.Position = UDim2.new(0, 10, 0, 88)

toggleLockBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
toggleLockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

toggleLockBtn.TextSize = 13
toggleLockBtn.Font = Enum.Font.GothamBold
toggleLockBtn.Text = "Лок-он: ВЫКЛ"

toggleLockBtn.Parent = mainFrame

local lockCorner = Instance.new("UICorner")
lockCorner.CornerRadius = UDim.new(0, 6)
lockCorner.Parent = toggleLockBtn

--==================================================
-- СТАТУС ЦЕЛИ
--==================================================

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 22)
statusLabel.Position = UDim2.new(0, 10, 0, 135)

statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)

statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "Цель: нет"

statusLabel.Parent = mainFrame

--==================================================
-- ЗАРЯДЫ
--==================================================

local chargesLabel = Instance.new("TextLabel")
chargesLabel.Size = UDim2.new(1, -20, 0, 20)
chargesLabel.Position = UDim2.new(0, 10, 0, 156)

chargesLabel.BackgroundTransparency = 1
chargesLabel.TextColor3 = Color3.fromRGB(150, 150, 150)

chargesLabel.TextSize = 11
chargesLabel.Font = Enum.Font.Gotham
chargesLabel.Text = "Заряды: 4 / 4"

chargesLabel.Parent = mainFrame

--==================================================
-- ИНФОРМАЦИЯ
--==================================================

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 0, 70)
infoLabel.Position = UDim2.new(0, 10, 0, 182)

infoLabel.BackgroundTransparency = 1

infoLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
infoLabel.TextSize = 11
infoLabel.Font = Enum.Font.Gotham

infoLabel.TextWrapped = true
infoLabel.Text =
	"Lock-on работает на игроков и NPC/Dummy. Back Dash использует текущую цель и каждый раз заново определяет её спину."

infoLabel.Parent = mainFrame

--==================================================
-- ПОЛУЧЕНИЕ ROOT PART
--==================================================

local function getRootPart(model)

	if not model or not model:IsA("Model") then
		return nil
	end

	-- Основной вариант
	local root = model:FindFirstChild("HumanoidRootPart")

	if root and root:IsA("BasePart") then
		return root
	end

	-- Запасной вариант для некоторых NPC
	local humanoid = model:FindFirstChildOfClass("Humanoid")

	if humanoid and humanoid.RootPart then
		return humanoid.RootPart
	end

	-- Ещё один fallback
	if model.PrimaryPart
		and model.PrimaryPart:IsA("BasePart") then

		return model.PrimaryPart
	end

	return nil
end

--==================================================
-- ПРОВЕРКА, ЯВЛЯЕТСЯ ЛИ MODEL ЦЕЛЬЮ
--==================================================

local function getTargetFromModel(model)

	if not model or not model:IsA("Model") then
		return nil
	end

	-- Не выбираем собственного персонажа
	if LocalPlayer.Character == model then
		return nil
	end

	local humanoid =
		model:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return nil
	end

	if humanoid.Health <= 0 then
		return nil
	end

	local root = getRootPart(model)

	if not root then
		return nil
	end

	return root
end

--==================================================
-- ПОИСК БЛИЖАЙШЕЙ ЦЕЛИ
-- Игроки + Dummy/NPC
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

	local checkedModels = {}

	--================================================
	-- СНАЧАЛА ИГРОКИ
	--================================================

	for _, player in ipairs(Players:GetPlayers()) do

		if player ~= LocalPlayer and player.Character then

			local model = player.Character

			if not checkedModels[model] then

				checkedModels[model] = true

				local root = getTargetFromModel(model)

				if root then

					local distance =
						(myRoot.Position - root.Position).Magnitude

					if distance < shortestDistance then

						shortestDistance = distance
						bestTarget = root

					end
				end
			end
		end
	end

	--================================================
	-- ПОИСК NPC / DUMMY
	--================================================

	for _, descendant in ipairs(workspace:GetDescendants()) do

		if descendant:IsA("Humanoid") then

			local model = descendant.Parent

			if model
				and model:IsA("Model")
				and not checkedModels[model] then

				checkedModels[model] = true

				local root = getTargetFromModel(model)

				if root then

					local distance =
						(myRoot.Position - root.Position).Magnitude

					if distance < shortestDistance then

						shortestDistance = distance
						bestTarget = root

					end
				end
			end
		end
	end

	return bestTarget
end

--==================================================
-- ПРОВЕРКА ЦЕЛИ
--==================================================

local function isTargetValid()

	if not lockedTargetPart then
		return false
	end

	if not lockedTargetPart.Parent then
		return false
	end

	local model = lockedTargetPart.Parent

	local humanoid =
		model:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return false
	end

	if humanoid.Health <= 0 then
		return false
	end

	return true
end

--==================================================
-- ОБНОВЛЕНИЕ GUI
--==================================================

local function updateCharges()

	chargesLabel.Text =
		"Заряды: "
		.. tostring(currentCharges)
		.. " / "
		.. tostring(maxCharges)

end

--==================================================
-- LOCK-ON
--==================================================

toggleLockBtn.MouseButton1Click:Connect(function()

	isLockOnEnabled = not isLockOnEnabled

	if isLockOnEnabled then

		local target = getBestTarget()

		if target then

			lockedTargetPart = target

			toggleLockBtn.BackgroundColor3 =
				Color3.fromRGB(40, 160, 60)

			toggleLockBtn.Text =
				"Лок-он: ВКЛ"

			statusLabel.Text =
				"Цель: " .. target.Parent.Name

		else

			isLockOnEnabled = false
			lockedTargetPart = nil

			toggleLockBtn.BackgroundColor3 =
				Color3.fromRGB(150, 40, 40)

			toggleLockBtn.Text =
				"Лок-он: ВЫКЛ"

			statusLabel.Text =
				"Цель: нет"

		end

	else

		lockedTargetPart = nil

		toggleLockBtn.BackgroundColor3 =
			Color3.fromRGB(150, 40, 40)

		toggleLockBtn.Text =
			"Лок-он: ВЫКЛ"

		statusLabel.Text =
			"Цель: нет"

	end
end)

--==================================================
-- BACK DASH TOGGLE
--==================================================

toggleDashBtn.MouseButton1Click:Connect(function()

	isDashEnabled = not isDashEnabled

	if isDashEnabled then

		toggleDashBtn.BackgroundColor3 =
			Color3.fromRGB(40, 160, 60)

		toggleDashBtn.Text =
			"Back Dash [3]: ВКЛ"

	else

		toggleDashBtn.BackgroundColor3 =
			Color3.fromRGB(150, 40, 40)

		toggleDashBtn.Text =
			"Back Dash [3]: ВЫКЛ"

	end
end)

--==================================================
-- BACK DASH
--==================================================

local function executeBackDash()

	if not isDashEnabled then
		return
	end

	if not isLockOnEnabled then
		return
	end

	if isCoolingDown then
		return
	end

	if isDashing then
		return
	end

	if currentCharges <= 0 then
		return
	end

	--================================================
	-- ПРОВЕРЯЕМ LOCK-ON
	--================================================

	if not isTargetValid() then

		lockedTargetPart = nil
		isLockOnEnabled = false

		toggleLockBtn.BackgroundColor3 =
			Color3.fromRGB(150, 40, 40)

		toggleLockBtn.Text =
			"Лок-он: ВЫКЛ"

		statusLabel.Text =
			"Цель: нет"

		return
	end

	local character = LocalPlayer.Character

	if not character then
		return
	end

	local rootPart = getRootPart(character)

	if not rootPart then
		return
	end

	local targetRoot = lockedTargetPart

	--================================================
	-- ЗАПОМИНАЕМ СТАРТОВУЮ ПОЗИЦИЮ
	--================================================

	local startPosition =
		rootPart.Position

	--================================================
	-- ПЕРВОНАЧАЛЬНЫЙ РАСЧЁТ СПИНЫ
	--================================================

	local targetPosition =
		targetRoot.Position

	local targetLook =
		targetRoot.CFrame.LookVector

	local destination =
		targetPosition
		- targetLook * BACK_DISTANCE

	destination = Vector3.new(
		destination.X,
		startPosition.Y,
		destination.Z
	)

	local initialDistance =
		(destination - startPosition).Magnitude

	if initialDistance < 0.5 then
		return
	end

	--================================================
	-- СПИСЫВАЕМ ЗАРЯД
	--================================================

	currentCharges -= 1
	updateCharges()

	--================================================
	-- START
	--================================================

	isDashing = true

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	local oldAutoRotate = nil

	if humanoid then

		oldAutoRotate =
			humanoid.AutoRotate

		humanoid.AutoRotate = false
	end

	-- Длительность зависит от расстояния
	local dashTime =
		math.clamp(
			initialDistance / 45,
			DASH_TIME_MIN,
			DASH_TIME_MAX
		)

	local startTime =
		os.clock()

	local connection

	connection = RunService.Heartbeat:Connect(function()

		--================================================
		-- ЗАЩИТА
		--================================================

		if not rootPart
			or not rootPart.Parent then

			connection:Disconnect()

			isDashing = false

			if humanoid and humanoid.Parent then
				humanoid.AutoRotate =
					oldAutoRotate
			end

			return
		end

		if not isTargetValid() then

			connection:Disconnect()

			isDashing = false

			if humanoid and humanoid.Parent then
				humanoid.AutoRotate =
					oldAutoRotate
			end

			return
		end

		--================================================
		-- ПРОГРЕСС
		--================================================

		local elapsed =
			os.clock() - startTime

		local alpha =
			math.clamp(
				elapsed / dashTime,
				0,
				1
			)

		-- SmoothStep
		local smoothAlpha =
			alpha * alpha * (3 - 2 * alpha)

		--================================================
		-- ОБНОВЛЯЕМ СПИНУ ЦЕЛИ
		--================================================

		local currentTargetPosition =
			targetRoot.Position

		local currentTargetLook =
			targetRoot.CFrame.LookVector

		-- Текущая точка за текущей спиной
		local currentBackPosition =
			currentTargetPosition
			- currentTargetLook * BACK_DISTANCE

		-- Сохраняем высоту игрока
		currentBackPosition =
			Vector3.new(
				currentBackPosition.X,
				startPosition.Y,
				currentBackPosition.Z
			)

		--================================================
		-- ДВИЖЕНИЕ
		--================================================

		local newPosition =
			startPosition:Lerp(
				currentBackPosition,
				smoothAlpha
			)

		--================================================
		-- ПОВОРОТ К ЦЕЛИ
		--================================================

		local lookPosition =
			Vector3.new(
				currentTargetPosition.X,
				newPosition.Y,
				currentTargetPosition.Z
			)

		if
			(lookPosition - newPosition).Magnitude
			> 0.01
		then

			rootPart.CFrame =
				CFrame.lookAt(
					newPosition,
					lookPosition
				)

		else

			rootPart.CFrame =
				CFrame.new(newPosition)

		end

		--================================================
		-- ФИНИШ
		--================================================

		if alpha >= 1 then

			-- Последний точный расчёт
			local finalTargetPosition =
				targetRoot.Position

			local finalLook =
				targetRoot.CFrame.LookVector

			local finalPosition =
				finalTargetPosition
				- finalLook * BACK_DISTANCE

			finalPosition =
				Vector3.new(
					finalPosition.X,
					startPosition.Y,
					finalPosition.Z
				)

			local finalLookAt =
				Vector3.new(
					finalTargetPosition.X,
					finalPosition.Y,
					finalTargetPosition.Z
				)

			rootPart.CFrame =
				CFrame.lookAt(
					finalPosition,
					finalLookAt
				)

			rootPart.AssemblyLinearVelocity =
				Vector3.zero

			connection:Disconnect()

			isDashing = false

			if humanoid and humanoid.Parent then
				humanoid.AutoRotate =
					oldAutoRotate
			end

		end
	end)

	--==================================================
	-- ВОССТАНОВЛЕНИЕ ЗАРЯДОВ
	--==================================================

	if currentCharges <= 0 then

		isCoolingDown = true

		toggleDashBtn.Text =
			"Заряды восстанавливаются..."

		toggleDashBtn.BackgroundColor3 =
			Color3.fromRGB(200, 140, 0)

		task.delay(3, function()

			currentCharges =
				maxCharges

			isCoolingDown = false

			updateCharges()

			if isDashEnabled then

				toggleDashBtn.Text =
					"Back Dash [3]: ВКЛ"

				toggleDashBtn.BackgroundColor3 =
					Color3.fromRGB(40, 160, 60)

			else

				toggleDashBtn.Text =
					"Back Dash [3]: ВЫКЛ"

				toggleDashBtn.BackgroundColor3 =
					Color3.fromRGB(150, 40, 40)

			end
		end)
	end
end

--==================================================
-- LOCK-ON ПОВОРОТ
--==================================================

RunService.RenderStepped:Connect(function()

	if not isLockOnEnabled then
		return
	end

	if isDashing then
		return
	end

	if not isTargetValid() then

		isLockOnEnabled = false
		lockedTargetPart = nil

		toggleLockBtn.BackgroundColor3 =
			Color3.fromRGB(150, 40, 40)

		toggleLockBtn.Text =
			"Лок-он: ВЫКЛ"

		statusLabel.Text =
			"Цель: нет"

		return
	end

	local character = LocalPlayer.Character

	if not character then
		return
	end

	local myRoot = getRootPart(character)

	if not myRoot then
		return
	end

	local targetPosition =
		lockedTargetPart.Position

	local flatTarget =
		Vector3.new(
			targetPosition.X,
			myRoot.Position.Y,
			targetPosition.Z
		)

	local direction =
		flatTarget - myRoot.Position

	if direction.Magnitude > 0.1 then

		local goalCFrame =
			CFrame.lookAt(
				myRoot.Position,
				flatTarget
			)

		myRoot.CFrame =
			myRoot.CFrame:Lerp(
				goalCFrame,
				LOCK_SMOOTHNESS
			)

	end

	statusLabel.Text =
		"Цель: "
		.. lockedTargetPart.Parent.Name

end)

--==================================================
-- КЛАВИША 3
--==================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)

	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Three
		or input.KeyCode == Enum.KeyCode.KeypadThree then

		executeBackDash()

	end

end)

--==================================================
-- ГОТОВО
--==================================================

updateCharges()

print("[Xeno] JJS Lock-on + Back Dash loaded!")
print("[Xeno] Players + NPC/Dummy support enabled.")
