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

	--------------------------------------------------
	-- ЗАРЯД И СОСТОЯНИЕ
	--------------------------------------------------

	State.Charges -= 1
	updateChargesDisplay()

	State.Dashing = true

	local oldAutoRotate = humanoid.AutoRotate
	local oldPlatformStand = humanoid.PlatformStand
	
	humanoid.AutoRotate = false
	humanoid.PlatformStand = true -- Отключаем стандартный контроллер ходьбы для чистого импульса

	--------------------------------------------------
	-- ТОЧКА ЗА СПИНОЙ ЦЕЛИ
	--------------------------------------------------

	local targetPosition =
		targetRoot.Position
		- targetRoot.CFrame.LookVector * BACK_DISTANCE

	targetPosition = Vector3.new(
		targetPosition.X,
		rootPart.Position.Y,
		targetPosition.Z
	)

	--------------------------------------------------
	-- ПРОВЕРКА ПРЕПЯТСТВИЙ
	--------------------------------------------------

	local dashVector =
		targetPosition - rootPart.Position

	local distance = dashVector.Magnitude

	if distance <= 0.05 then
		humanoid.AutoRotate = oldAutoRotate
		humanoid.PlatformStand = oldPlatformStand
		State.Dashing = false
		return
	end

	raycastParams.FilterDescendantsInstances = {
		character,
		targetRoot.Parent
	}

	local rayResult = workspace:Raycast(
		rootPart.Position,
		dashVector,
		raycastParams
	)

	if rayResult then
		local safeDistance = math.max(
			rayResult.Distance - 1.5,
			0
		)

		targetPosition =
			rootPart.Position
			+ dashVector.Unit * safeDistance
	end

	--------------------------------------------------
	-- НАПРАВЛЕНИЕ: ЛИЦОМ К ЦЕЛИ
	--------------------------------------------------

	local lookPosition = Vector3.new(
		targetRoot.Position.X,
		targetPosition.Y,
		targetRoot.Position.Z
	)

	--------------------------------------------------
	-- РАСЧЕТ ВРЕМЕНИ И СКОРОСТИ
	--------------------------------------------------

	local dashDistance =
		(rootPart.Position - targetPosition).Magnitude

	local dashTime = math.clamp(
		dashDistance / DASH_SPEED,
		DASH_TIME_MIN,
		DASH_TIME_MAX
	)

	rootPart.AssemblyLinearVelocity = Vector3.zero

	--------------------------------------------------
	-- ЦИКЛ ФИЗИЧЕСКОГО РЫВКА
	--------------------------------------------------

	local startTime = os.clock()

	while os.clock() - startTime < dashTime do
		if State.Destroyed then
			break
		end

		if not character.Parent or not rootPart.Parent or not humanoid.Parent then
			break
		end

		local remaining =
			targetPosition - rootPart.Position

		if remaining.Magnitude > 0.15 then
			rootPart.AssemblyLinearVelocity =
				remaining.Unit * (remaining.Magnitude / 0.035)
		else
			break
		end

		task.wait()
	end

	--------------------------------------------------
	-- ФИНАЛ И СБРОС СОСТОЯНИЙ (GARBAGE SAFE)
	--------------------------------------------------

	if rootPart.Parent then
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.CFrame = CFrame.lookAt(
			rootPart.Position,
			lookPosition
		)
	end

	if humanoid.Parent then
		humanoid.AutoRotate = oldAutoRotate
		humanoid.PlatformStand = oldPlatformStand
	end

	State.Dashing = false

	if State.Charges <= 0 and not State.CoolingDown then
		startChargeCooldown()
	end
end
