local function executeHumanDash()
	if not isDashEnabled then return end
	if isCoolingDown or currentCharges <= 0 then return end

	local character = LocalPlayer.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- ВАЖНО:
	-- каждый раз при нажатии 3 ищем цель заново
	local target = getBestTarget()
	if not target or not target.Parent then
		return
	end

	local targetCharacter = target.Parent
	local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")

	if not targetHumanoid or targetHumanoid.Health <= 0 then
		return
	end

	currentCharges -= 1

	-- ==========================================
	-- СВЕЖИЙ РАСЧЁТ СПИНЫ
	-- ==========================================

	local targetPosition = target.Position
	local targetLook = target.CFrame.LookVector

	-- Сколько studs оставляем за спиной
	local backDistance = 4.5

	-- Точка непосредственно за спиной врага
	local backPosition = targetPosition - targetLook * backDistance

	-- Не учитываем разницу по высоте,
	-- чтобы дэш не пытался лететь вверх/вниз
	backPosition = Vector3.new(
		backPosition.X,
		rootPart.Position.Y,
		backPosition.Z
	)

	local distance = (backPosition - rootPart.Position).Magnitude

	if distance < 0.5 then
		return
	end

	-- ==========================================
	-- ПЛАВНЫЙ ДЭШ
	-- ==========================================

	local dashTime = math.clamp(distance / 35, 0.12, 0.32)

	local startPosition = rootPart.Position
	local startTime = os.clock()

	-- Сохраняем старое состояние AutoRotate
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local oldAutoRotate = humanoid and humanoid.AutoRotate

	if humanoid then
		humanoid.AutoRotate = false
	end

	-- Движение постепенно от текущей позиции к спине
	local connection

	connection = RunService.Heartbeat:Connect(function()
		if not rootPart or not rootPart.Parent then
			connection:Disconnect()
			return
		end

		local elapsed = os.clock() - startTime
		local alpha = math.clamp(elapsed / dashTime, 0, 1)

		-- SmoothStep:
		-- плавный старт + плавная остановка
		local smoothAlpha = alpha * alpha * (3 - 2 * alpha)

		local newPosition = startPosition:Lerp(
			backPosition,
			smoothAlpha
		)

		-- После окончания точно ставим в рассчитанную точку
		if alpha >= 1 then
			newPosition = backPosition
		end

		-- Поворачиваемся в сторону противника,
		-- находясь при этом за его спиной
		local lookAtPosition = Vector3.new(
			targetPosition.X,
			newPosition.Y,
			targetPosition.Z
		)

		if (lookAtPosition - newPosition).Magnitude > 0.01 then
			rootPart.CFrame = CFrame.lookAt(
				newPosition,
				lookAtPosition
			)
		else
			rootPart.CFrame = CFrame.new(newPosition)
		end

		if alpha >= 1 then
			connection:Disconnect()

			if humanoid and humanoid.Parent then
				humanoid.AutoRotate = oldAutoRotate
			end

			-- Небольшой нулевой импульс,
			-- чтобы старое движение не продолжало толкать персонажа
			rootPart.AssemblyLinearVelocity = Vector3.zero
		end
	end)

	print(
		"[Xeno] Дэш за спину:",
		targetCharacter.Name,
		"Зарядов:",
		currentCharges
	)

	-- ==========================================
	-- ВОССТАНОВЛЕНИЕ ЗАРЯДОВ
	-- ==========================================

	if currentCharges <= 0 then
		isCoolingDown = true

		toggleDashBtn.Text = "Кулдаун зарядов..."
		toggleDashBtn.BackgroundColor3 = Color3.fromRGB(200, 140, 0)

		task.delay(3, function()
			currentCharges = maxCharges
			isCoolingDown = false

			if isDashEnabled then
				toggleDashBtn.Text = "Мягкий дэш по [3]: ВКЛ"
				toggleDashBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
			end

			print("[Xeno] Заряды восстановлены.")
		end)
	end
end


-- ==========================================
-- КЛАВИША 3
-- ==========================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Three
		or input.KeyCode == Enum.KeyCode.KeypadThree then

		executeHumanDash()
	end
end)
