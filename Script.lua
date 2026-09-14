local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Удаляем старое меню, если уже висело
if CoreGui:FindFirstChild("XenoJJSMenu") then
	CoreGui.XenoJJSMenu:Destroy()
end

-- Создаем GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XenoJJSMenu"
screenGui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 215)
mainFrame.Position = UDim2.new(0, 50, 0, 150)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

-- Заголовок
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "JJS Legit Phys-Dash [3]"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- Состояния
local isDashEnabled = false
local isLockOnEnabled = false
local lockedTargetPart = nil
local currentCharges = 4
local maxCharges = 4
local isCoolingDown = false

-- Кнопка 1: Сайд-дэш
local toggleDashBtn = Instance.new("TextButton")
toggleDashBtn.Size = UDim2.new(1, -20, 0, 40)
toggleDashBtn.Position = UDim2.new(0, 10, 0, 40)
toggleDashBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
toggleDashBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleDashBtn.TextSize = 13
toggleDashBtn.Font = Enum.Font.GothamBold
toggleDashBtn.Text = "Леджит дэш по [3]: ВЫКЛ"
toggleDashBtn.Parent = mainFrame
Instance.new("UICorner", toggleDashBtn).CornerRadius = UDim.new(0, 6)

-- Кнопка 2: Лок-он в ядро
local toggleLockBtn = Instance.new("TextButton")
toggleLockBtn.Size = UDim2.new(1, -20, 0, 40)
toggleLockBtn.Position = UDim2.new(0, 10, 0, 88)
toggleLockBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
toggleLockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleLockBtn.TextSize = 13
toggleLockBtn.Font = Enum.Font.GothamBold
toggleLockBtn.Text = "Лок-он в ядро: ВЫКЛ"
toggleLockBtn.Parent = mainFrame
Instance.new("UICorner", toggleLockBtn).CornerRadius = UDim.new(0, 6)

-- Инструкция
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 0, 45)
infoLabel.Position = UDim2.new(0, 10, 0, 136)
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
infoLabel.TextSize = 11
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextWrapped = true
infoLabel.Text = "Мягкий физический дэш за спину без телепортации и палева."
infoLabel.Parent = mainFrame

-- Функция поиска ближайшего игрока
local function getBestTarget()
	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
	local myRoot = character.HumanoidRootPart
	
	local bestTargetPart = nil
	local shortestDist = 90
	
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local enemyRoot = p.Character:FindFirstChild("HumanoidRootPart")
			local enemyHumanoid = p.Character:FindFirstChild("Humanoid")
			
			if enemyRoot and enemyHumanoid and enemyHumanoid.Health > 0 then
				local dist = (myRoot.Position - enemyRoot.Position).Magnitude
				if dist < shortestDist then
					shortestDist = dist
					bestTargetPart = enemyRoot
				end
			end
		end
	end
	return bestTargetPart
end

-- Переключение Сайд-дэша
toggleDashBtn.MouseButton1Click:Connect(function()
	isDashEnabled = not isDashEnabled
	if isDashEnabled then
		toggleDashBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
		toggleDashBtn.Text = "Леджит дэш по [3]: ВКЛ"
	else
		toggleDashBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
		toggleDashBtn.Text = "Леджит дэш по [3]: ВЫКЛ"
	end
end)

-- Переключение Лок-она
toggleLockBtn.MouseButton1Click:Connect(function()
	isLockOnEnabled = not isLockOnEnabled
	
	if isLockOnEnabled then
		lockedTargetPart = getBestTarget()
		if lockedTargetPart then
			toggleLockBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
			toggleLockBtn.Text = "Лок-он в ядро: ВКЛ"
		else
			isLockOnEnabled = false
			lockedTargetPart = nil
			toggleLockBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
			toggleLockBtn.Text = "Рядом нет врагов!"
			task.delay(1.5, function()
				if not isLockOnEnabled then
					toggleLockBtn.Text = "Лок-он в ядро: ВЫКЛ"
				end
			end)
		end
	else
		lockedTargetPart = nil
		toggleLockBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
		toggleLockBtn.Text = "Лок-он в ядро: ВЫКЛ"
	end
end)

-- Рендер: плавная (но не резкая) доводка взгляда в ядро врага
RunService.RenderStepped:Connect(function()
	if isLockOnEnabled then
		if lockedTargetPart and lockedTargetPart.Parent and lockedTargetPart.Parent:FindFirstChild("Humanoid") and lockedTargetPart.Parent.Humanoid.Health > 0 then
			local character = LocalPlayer.Character
			if character and character:FindFirstChild("HumanoidRootPart") then
				local myRoot = character.HumanoidRootPart
				local targetPos = lockedTargetPart.Position
				
				local flatTargetPos = Vector3.new(targetPos.X, myRoot.Position.Y, targetPos.Z)
				-- Плавный поворот через CFrame.lerp, чтобы не было резких дерганий камеры/модели
				local goalCFrame = CFrame.lookAt(myRoot.Position, flatTargetPos)
				myRoot.CFrame = myRoot.CFrame:Lerp(goalCFrame, 0.2)
			end
		else
			isLockOnEnabled = false
			lockedTargetPart = nil
			toggleLockBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
			toggleLockBtn.Text = "Лок-он в ядро: ВЫКЛ"
		end
	end
end)

-- Функция беспалевного физического дэша за спину
local function executeLegitDash()
	if not isDashEnabled or not isLockOnEnabled then return end
	if isCoolingDown or currentCharges <= 0 then return end
	
	local character = LocalPlayer.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local rootPart = character.HumanoidRootPart
		
		if lockedTargetPart and lockedTargetPart.Parent then
			currentCharges = currentCharges - 1
			print("[Xeno] Физический дэш за спину! Зарядов осталось:", currentCharges)
			
			-- Вычисляем вектор направления: от нас к точке за спиной врага
			local enemyCFrame = lockedTargetPart.CFrame
			local targetBackPos = lockedTargetPart.Position + (-enemyCFrame.LookVector * 4.5)
			
			-- Направление рывка именно по физике (скорость задается мягким импульсом)
			local directionToBack = (targetBackPos - rootPart.Position)
			local distance = directionToBack.Magnitude
			directionToBack = directionToBack.Unit
			
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(300000, 0, 300000) -- Тянем только по плоскости XZ, не трогая прыжки
			bodyVelocity.Velocity = directionToBack * math.min(distance * 18, 65) -- Скорость зависит от расстояния, но имеет лимит
			bodyVelocity.Parent = rootPart
			
			-- Быстро отключаем импульс, чтобы персонаж проскользил ровно сколько нужно и остановился сам
			task.delay(0.14, function()
				if bodyVelocity then bodyVelocity:Destroy() end
			end)
			
			-- Кулдаун зарядов
			if currentCharges <= 0 then
				isCoolingDown = true
				toggleDashBtn.Text = "Кулдаун зарядов..."
				toggleDashBtn.BackgroundColor3 = Color3.fromRGB(200, 140, 0)
				
				task.delay(3, function()
					currentCharges = maxCharges
					isCoolingDown = false
					if isDashEnabled then
						toggleDashBtn.Text = "Леджит дэш по [3]: ВКЛ"
						toggleDashBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
					end
					print("[Xeno] Заряды восстановлены.")
				end)
			end
		end
	end
end

-- Кнопка [3]
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed then
		if input.KeyCode == Enum.KeyCode.Three or input.KeyCode == Enum.KeyCode.KeypadThree then
			executeLegitDash()
		end
	end
end)

print("[Xeno] Леджит-скрипт загружен!")
