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
	-- СОХРАНЯЕМ СОСТОЯНИЕ
	--------------------------------------------------

	local oldAutoRotate = humanoid.AutoRotate
	local oldPlatformStand = humanoid.PlatformStand

	State.Charges -= 1
	updateChargesDisplay()

	State.Dashing = true

	humanoid.AutoRotate = false
	humanoid.PlatformStand = true

	--------------------------------------------------
	-- CLEANUP
	--------------------------------------------------

	local function cleanup()
		if rootPart and rootPart.Parent then
			local currentVelocity = rootPart.AssemblyLinearVelocity
			
			-- Полностью гасим горизонтальный импульс, 
			-- оставляя адекватную вертикальную составляющую для гравитации
			rootPart.AssemblyLinearVelocity = Vector3.new(
				0,
				math.min(currentVelocity.Y, 0), -- гасим паразитный взлет вверх при завершении
				0
			)
		end

		if humanoid and humanoid.Parent then
			humanoid.AutoRotate = oldAutoRotate
			humanoid.PlatformStand = oldPlatformStand
		end

		State.Dashing = false
	end

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
	-- НАПРАВЛЕНИЕ И РАССТОЯНИЕ
	--------------------------------------------------

	local dashVector = targetPosition - rootPart.Position
	dashVector = Vector3.new(dashVector.X, 0, dashVector.Z)

	local distance = dashVector.Magnitude

	if distance <= 0.05 then
		State.Charges += 1
		updateChargesDisplay()
		cleanup()
		return
	end

	--------------------------------------------------
	-- ПРОВЕРКА СТЕНЫ (RAYCAST)
	--------------------------------------------------

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
		local safeDistance = math.max(rayResult.Distance - 1.5, 0)
		targetPosition = rootPart.Position + dashVector.Unit * safeDistance
		
		dashVector = targetPosition - rootPart.Position
		dashVector = Vector3.new(dashVector.X, 0, dashVector.Z)
		distance = dashVector.Magnitude

		if distance <= 0.05 then
			State.Charges += 1
			updateChargesDisplay()
			cleanup()
			return
		end
	end

	--------------------------------------------------
	-- РАСЧЕТ СКОРОСТИ
	--------------------------------------------------

	local dashTime = math.clamp(
		distance / DASH_SPEED,
		DASH_TIME_MIN,
		DASH_TIME_MAX
	)

	local dashDirection = dashVector.Unit
	local actualDashSpeed = distance / dashTime
	local horizontalVelocity = dashDirection * actualDashSpeed

	rootPart.AssemblyLinearVelocity = Vector3.new(
		horizontalVelocity.X,
		rootPart.AssemblyLinearVelocity.Y,
		horizontalVelocity.Z
	)

	--------------------------------------------------
	-- ФИЗИЧЕСКИЙ DASH С ПРЕРЫВАНИЕМ НА ЛЕТУ
	--------------------------------------------------

	local startTime = os.clock()

	while os.clock() - startTime < dashTime do
		if State.Destroyed then
			break
		end

		if not character.Parent or not rootPart.Parent or not humanoid.Parent then
			break
		end

		-- Аварийное прерывание, если цель исчезла/умерла прямо во время рывка
		if not targetRoot or not targetRoot.Parent then
			break
		end

		local currentY = rootPart.AssemblyLinearVelocity.Y
		rootPart.AssemblyLinearVelocity = Vector3.new(
			horizontalVelocity.X,
			currentY,
			horizontalVelocity.Z
		)

		RunService.Heartbeat:Wait()
	end

	--------------------------------------------------
	-- ФИНАЛ
	--------------------------------------------------

	if rootPart.Parent and targetRoot and targetRoot.Parent then
		local lookDirection = targetRoot.Position - rootPart.Position
		lookDirection = Vector3.new(lookDirection.X, 0, lookDirection.Z)

		if lookDirection.Magnitude > 0.05 then
			rootPart.CFrame = CFrame.lookAt(
				rootPart.Position,
				rootPart.Position + lookDirection
			)
		end
	end

	cleanup()

	--------------------------------------------------
	-- ВОССТАНОВЛЕНИЕ ЗАРЯДОВ
	--------------------------------------------------

	if State.Charges <= 0
		and not State.CoolingDown
		and not State.Destroyed then

		startChargeCooldown()
	end
end
