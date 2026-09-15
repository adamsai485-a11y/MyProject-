local function executeBackDash()
	print("1. Нажата клавиша дэша")

	--------------------------------------------------
	-- GUARDS
	--------------------------------------------------

	if State.Destroyed then
		print("FAIL: State.Destroyed is true")
		return
	end

	if not State.DashEnabled then
		print("FAIL: State.DashEnabled is false")
		return
	end

	if not State.LockOnEnabled then
		print("FAIL: State.LockOnEnabled is false")
		return
	end

	if State.CoolingDown then
		print("FAIL: State.CoolingDown is true")
		return
	end

	if State.Dashing then
		print("FAIL: State.Dashing is true (уже дэшится)")
		return
	end

	if State.Charges <= 0 then
		print("FAIL: State.Charges <= 0 (нет зарядов)")
		return
	end

	if not isTargetValid() then
		print("FAIL: isTargetValid() вернул false")
		setLockState(false, nil)
		return
	end

	--------------------------------------------------
	-- CHARACTER
	--------------------------------------------------

	local character = LocalPlayer.Character

	if not character then
		print("FAIL: LocalPlayer.Character равен nil")
		return
	end

	local rootPart = getRootPart(character)
	local humanoid = getHumanoid(character)
	local targetRoot = State.Target

	if not rootPart or not humanoid or not targetRoot then
		print("FAIL: Нет rootPart, humanoid или targetRoot", tostring(rootPart), tostring(humanoid), tostring(targetRoot))
		return
	end

	local targetHumanoid = getHumanoid(targetRoot.Parent)

	if not targetHumanoid or targetHumanoid.Health <= 0 then
		print("FAIL: Цель мертва или у нее нет гуманоида")
		setLockState(false, nil)
		return
	end

	print("Успех! Все проверки пройдены, запускаем расчеты...")

	--------------------------------------------------
	-- DASH SETTINGS
	--------------------------------------------------

	local MAX_DASH_SPEED =
		math.max(DASH_SPEED * 2, 110)

	local TARGET_LEAD_TIME = 0.08
	local WALL_PADDING = 1.5
	local STOP_DISTANCE = 0.15
	local STEERING = 20

	--------------------------------------------------
	-- SAVE HUMANOID STATE
	--------------------------------------------------

	local oldAutoRotate = humanoid.AutoRotate
	local oldPlatformStand = humanoid.PlatformStand
	local oldState = humanoid:GetState()

	--------------------------------------------------
	-- CHARGE
	--------------------------------------------------

	State.Charges -= 1
	updateChargesDisplay()

	State.Dashing = true

	humanoid.AutoRotate = false
	humanoid.PlatformStand = true

	--------------------------------------------------
	-- REMOVE POSSIBLE OLD DASH OBJECTS
	--------------------------------------------------

	for _, objectName in ipairs({
		"__JJS_DashAttachment",
		"__JJS_DashVelocity",
		"__JJS_DashOrientation"
	}) do

		local oldObject =
			rootPart:FindFirstChild(objectName)

		if oldObject then
			oldObject:Destroy()
		end
	end

	--------------------------------------------------
	-- ATTACHMENT
	--------------------------------------------------

	local dashAttachment = Instance.new("Attachment")
	dashAttachment.Name = "__JJS_DashAttachment"
	dashAttachment.Parent = rootPart

	--------------------------------------------------
	-- LINEAR VELOCITY
	--------------------------------------------------

	local dashVelocity = Instance.new("LinearVelocity")

	dashVelocity.Name = "__JJS_DashVelocity"
	dashVelocity.Attachment0 = dashAttachment

	dashVelocity.RelativeTo =
		Enum.ActuatorRelativeTo.World

	dashVelocity.VelocityConstraintMode =
		Enum.VelocityConstraintMode.Vector

	dashVelocity.ForceLimitsEnabled = true
	dashVelocity.ForceLimitMode =
		Enum.ForceLimitMode.Magnitude

	dashVelocity.MaxForce =
		math.max(
			rootPart.AssemblyMass * 6000,
			50000
		)

	dashVelocity.ReactionForceEnabled = false

	dashVelocity.Parent = rootPart

	--------------------------------------------------
	-- ORIENTATION
	--------------------------------------------------

	local dashOrientation = Instance.new("AlignOrientation")

	dashOrientation.Name = "__JJS_DashOrientation"
	dashOrientation.Attachment0 = dashAttachment

	dashOrientation.Mode =
		Enum.OrientationAlignmentMode.OneAttachment

	dashOrientation.AlignType =
		Enum.AlignType.AllAxes

	dashOrientation.RigidityEnabled = false

	dashOrientation.Responsiveness = 80

	dashOrientation.MaxAngularVelocity =
		math.rad(1440)

	dashOrientation.MaxTorque =
		math.max(
			rootPart.AssemblyMass * 5000,
			50000
		)

	dashOrientation.ReactionTorqueEnabled = false

	dashOrientation.Parent = rootPart

	--------------------------------------------------
	-- GET POINT BEHIND TARGET
	--------------------------------------------------

	local function getDashDestination(leadTime)
		if not targetRoot
			or not targetRoot.Parent then

			return nil
		end

		local targetForward =
			targetRoot.CFrame.LookVector

		targetForward = Vector3.new(
			targetForward.X,
			0,
			targetForward.Z
		)

		if targetForward.Magnitude <= 0.001 then
			targetForward = Vector3.new(
				0,
				0,
				-1
			)
		else
			targetForward =
				targetForward.Unit
		end

		--------------------------------------------------
		-- PREDICTION
		--------------------------------------------------

		local targetVelocity =
			targetRoot.AssemblyLinearVelocity

		local horizontalTargetVelocity =
			Vector3.new(
				targetVelocity.X,
				0,
				targetVelocity.Z
			)

		local predictedTargetPosition =
			targetRoot.Position
			+ horizontalTargetVelocity * leadTime

		--------------------------------------------------
		-- ТОЧКА ЗА СПИНОЙ
		--------------------------------------------------

		local desiredPosition =
			predictedTargetPosition
			- targetForward * BACK_DISTANCE

		desiredPosition = Vector3.new(
			desiredPosition.X,
			rootPart.Position.Y,
			desiredPosition.Z
		)

		--------------------------------------------------
		-- НАПРАВЛЕНИЕ
		--------------------------------------------------

		local direction =
			desiredPosition - rootPart.Position

		direction = Vector3.new(
			direction.X,
			0,
			direction.Z
		)

		local distance =
			direction.Magnitude

		if distance <= 0.001 then
			return rootPart.Position
		end

		--------------------------------------------------
		-- RAYCAST
		--------------------------------------------------

		raycastParams.FilterDescendantsInstances = {
			character,
			targetRoot.Parent
		}

		raycastParams.RespectCanCollide = true

		local result = workspace:Raycast(
			rootPart.Position,
			direction,
			raycastParams
		)

		if not result then
			return desiredPosition
		end

		--------------------------------------------------
		-- БЕЗОПАСНАЯ ТОЧКА ПЕРЕД СТЕНОЙ
		--------------------------------------------------

		local safeDistance =
			math.max(
				result.Distance - WALL_PADDING,
				0
			)

		if safeDistance <= 0.001 then
			return rootPart.Position
		end

		return rootPart.Position
			+ direction.Unit * safeDistance
	end

	--------------------------------------------------
	-- INITIAL DESTINATION
	--------------------------------------------------

	local initialDestination =
		getDashDestination(
			TARGET_LEAD_TIME
		)

	if not initialDestination then
		print("FAIL: Не удалось получить initialDestination")
		State.Charges += 1
		updateChargesDisplay()

		dashVelocity:Destroy()
		dashOrientation:Destroy()
		dashAttachment:Destroy()

		humanoid.AutoRotate = oldAutoRotate
		humanoid.PlatformStand = oldPlatformStand

		State.Dashing = false

		return
	end

	local initialDirection =
		initialDestination - rootPart.Position

	initialDirection = Vector3.new(
		initialDirection.X,
		0,
		initialDirection.Z
	)

	local initialDistance =
		initialDirection.Magnitude

	if initialDistance <= STOP_DISTANCE then
		print("FAIL: Слишком маленькая начальная дистанция")
		State.Charges += 1
		updateChargesDisplay()

		dashVelocity:Destroy()
		dashOrientation:Destroy()
		dashAttachment:Destroy()

		humanoid.AutoRotate = oldAutoRotate
		humanoid.PlatformStand = oldPlatformStand

		State.Dashing = false

		return
	end

	--------------------------------------------------
	-- DASH TIME
	--------------------------------------------------

	local dashTime = math.clamp(
		initialDistance / DASH_SPEED,
		DASH_TIME_MIN,
		DASH_TIME_MAX
	)

	dashTime = math.max(
		dashTime,
		initialDistance / MAX_DASH_SPEED
	)

	--------------------------------------------------
	-- INITIAL VELOCITY
	--------------------------------------------------

	local initialSpeed =
		math.clamp(
			initialDistance / dashTime,
			DASH_SPEED,
			MAX_DASH_SPEED
		)

	local steeringVelocity =
		initialDirection.Unit * initialSpeed

	dashVelocity.VectorVelocity =
		steeringVelocity

	--------------------------------------------------
	-- INITIAL ORIENTATION
	--------------------------------------------------

	local initialLookDirection =
		targetRoot.Position - rootPart.Position

	initialLookDirection = Vector3.new(
		initialLookDirection.X,
		0,
		initialLookDirection.Z
	)

	if initialLookDirection.Magnitude > 0.001 then
		dashOrientation.CFrame =
			CFrame.lookAlong(
				Vector3.zero,
				initialLookDirection.Unit
			)
	end

	--------------------------------------------------
	-- PHYSICAL DASH
	--------------------------------------------------

	local startTime = os.clock()
	local finishedNormally = false

	while true do

		if State.Destroyed then break end
		if not character.Parent then break end
		if not rootPart.Parent then break end
		if not humanoid.Parent then break end
		if humanoid.Health <= 0 then break end
		if not targetRoot or not targetRoot.Parent then break end

		targetHumanoid = getHumanoid(targetRoot.Parent)
		if not targetHumanoid or targetHumanoid.Health <= 0 then break end

		if not isTargetValid() then break end

		local deltaTime =
			RunService.PreSimulation:Wait()

		local elapsed =
			os.clock() - startTime

		local remainingTime =
			dashTime - elapsed

		if remainingTime <= 0 then
			finishedNormally = true
			break
		end

		local destination =
			getDashDestination(
				math.min(
					remainingTime,
					TARGET_LEAD_TIME
				)
			)

		if not destination then
			break
		end

		local direction =
			destination - rootPart.Position

		direction = Vector3.new(
			direction.X,
			0,
			direction.Z
		)

		local distance =
			direction.Magnitude

		if distance <= STOP_DISTANCE then
			finishedNormally = true
			break
		end

		local requiredSpeed =
			distance
			/ math.max(
				remainingTime,
				0.035
			)

		local desiredSpeed =
			math.clamp(
				requiredSpeed,
				DASH_SPEED * 0.70,
				MAX_DASH_SPEED
			)

		local desiredVelocity =
			direction.Unit * desiredSpeed

		local steeringAlpha =
			math.clamp(
				deltaTime * STEERING,
				0,
				1
			)

		steeringVelocity =
			steeringVelocity:Lerp(
				desiredVelocity,
				steeringAlpha
			)

		steeringVelocity = Vector3.new(
			steeringVelocity.X,
			0,
			steeringVelocity.Z
		)

		dashVelocity.VectorVelocity =
			steeringVelocity

		local lookDirection =
			targetRoot.Position - rootPart.Position

		lookDirection = Vector3.new(
			lookDirection.X,
			0,
			lookDirection.Z
		)

		if lookDirection.Magnitude > 0.001 then
			dashOrientation.CFrame =
				CFrame.lookAlong(
					Vector3.zero,
					lookDirection.Unit
				)
		end
	end

	--------------------------------------------------
	-- STOP PHYSICS
	--------------------------------------------------

	if dashVelocity and dashVelocity.Parent then
		dashVelocity.Enabled = false
	end

	if dashOrientation
		and dashOrientation.Parent then

		dashOrientation.Enabled = false
	end

	if dashVelocity then
		dashVelocity:Destroy()
	end

	if dashOrientation then
		dashOrientation:Destroy()
	end

	if dashAttachment then
		dashAttachment:Destroy()
	end

	--------------------------------------------------
	-- CLEAN VELOCITY
	--------------------------------------------------

	if rootPart and rootPart.Parent then

		local currentVelocity =
			rootPart.AssemblyLinearVelocity

		rootPart.AssemblyLinearVelocity =
			Vector3.new(
				0,
				math.min(
					currentVelocity.Y,
					0
				),
				0
			)

		rootPart.AssemblyAngularVelocity =
			Vector3.zero
	end

	--------------------------------------------------
	-- RESTORE HUMANOID
	--------------------------------------------------

	if humanoid and humanoid.Parent then

		humanoid.AutoRotate =
			oldAutoRotate

		humanoid.PlatformStand =
			oldPlatformStand

		if not oldPlatformStand
			and humanoid.Health > 0
			and humanoid:GetState()
				== Enum.HumanoidStateType.PlatformStanding then

			if oldState
				~= Enum.HumanoidStateType.Dead then

				humanoid:ChangeState(oldState)
			end
		end
	end

	State.Dashing = false

	if State.Charges <= 0
		and not State.CoolingDown
		and not State.Destroyed then

		startChargeCooldown()
	end
end
