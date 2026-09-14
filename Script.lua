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
title.Text = "JJS Lock-on & Side Dash [3]"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- Состояние
local isEnabled = false
local isLockedOn = false
local lockedTarget = nil
local currentCharges = 4
local maxCharges = 4
local isCoolingDown = false

-- Кнопка 1: Тумблер Сайд-дэша
local toggleDashBtn = Instance.new("TextButton")
toggleDashBtn.Size = UDim2.new(1, -20, 0, 40)
toggleDashBtn.Position = UDim2.new(0, 10, 0, 40)
toggleDashBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40) -- Красный (выкл)
toggleDashBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleDashBtn.TextSize = 13
toggleDashBtn.Font = Enum.Font.GothamBold
toggleDashBtn.Text = "Сайд-дэш по [3]: ВЫКЛ"
toggleDashBtn.Parent = mainFrame
Instance.new("UICorner", toggleDashBtn).CornerRadius = UDim.new(0, 6)

-- Кнопка 2: Фиксация взгляда на враге (Lock-on)
local lockBtn = Instance.new("TextButton")
lockBtn.Size = UDim2.new(1, -20, 0, 40)
lockBtn.Position = UDim2.new(0, 10, 0, 88)
lockBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 150) -- Синий (выкл)
lockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
lockBtn.TextSize = 13
lockBtn.Font = Enum.Font.GothamBold
lockBtn.Text = "Фокус на враге: ВЫКЛ"
lockBtn.Parent = mainFrame
Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 6)

-- Инструкция
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 0, 45)
infoLabel.Position = UDim2.new(0, 10, 0, 136)
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
infoLabel.TextSize = 11
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextWrapped = true
infoLabel.Text = "Включи фокус (смотрит на врага перед тобой) и жми [3] для дэша за его спину (4 раза + КД)."
infoLabel.Parent = mainFrame

-- Функция поиска ближайшего врага ПЕРЕД игроком
local function getBestTarget()
	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
	local myRoot = character.HumanoidRootPart
	
	local bestTarget = nil
	local shortestDist = 60 -- Максимальная дистанция поиска
	
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") then
			if p.Character.Humanoid.Health > 0 then
				local enemyRoot = p.Character.HumanoidRootPart
				local dist = (myRoot.Position - enemyRoot.Position).Magnitude
				
				-- Проверяем, что враг находится перед нами (через вектор LookVector)
				local directionToEnemy = (enemyRoot.Position - myRoot.Position).Unit
				local dotProduct = myRoot.LookVector:Dot(directionToEnemy)
				
				-- dotProduct > 0 означает, что враг впереди (в поле зрения)
				if dotProduct > 0 and dist < shortestDist then
					shortestDist = dist
					bestTarget = enemyRoot
				end
			end
		end
	end
	return bestTarget
end

-- Переключение тумблера Сайд-дэша
toggleDashBtn.MouseButton1Click:Connect(function()
	isEnabled = not isEnabled
	if isEnabled then
		toggleDashBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
		toggleDashBtn.Text = "Сайд-дэш по [3]: ВКЛ"
	else
		toggleDashBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
		toggleDashBtn.Text = "Сайд-дэш по [3]: ВЫКЛ"
	end
end)

-- Переключение тумблера Фокуса на враге (Lock-on)
lockBtn.MouseButton1Click:Connect(function()
	isLockedOn = not isLockedOn
	if isLockedOn then
		lockedTarget = getBestTarget()
		if lockedTarget then
			lockBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
			lockBtn.Text = "Фокус на враге: ВКЛ (Цель найдена)"
		else
			isLockedOn = false
			lockBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
			lockBtn.Text = "Враг не найден спереди!"
			task.wait(1.5)
			lockBtn.Text = "Фокус на враге: ВЫКЛ"
		end
	else
		lockedTarget = nil
		lockBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 150)
		lockBtn.Text = "Фокус на враге: ВЫКЛ"
	end
end)

-- Постоянный цикл удержания взгляда на выбранном враге, пока включен Lock-on
RunService.RenderStepped:Connect(function()
	if isLockedOn and lockedTarget and lockedTarget.Parent then
		local character = LocalPlayer.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local myRoot = character.HumanoidRootPart
			-- Мгновенно поворачиваем персонажа и камеру лицом к цели
			local targetPos = Vector3.new(lockedTarget.Position.X, myRoot.Position.Y, lockedTarget.Position.Z)
			myRoot.CFrame = CFrame.new(myRoot.Position, targetPos)
		end
	else
		if isLockedOn and (not lockedTarget or not lockedTarget.Parent) then
			-- Если враг вышел из игры или умер, выключаем фокус
			isLockedOn = false
			lockedTarget = nil
			lockBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 150)
			lockBtn.Text = "Цель потеряна"
		end
	end
end)

-- Логика точного сайд-дэша за спину конкретного врага
local function executeSideDash()
	if isCoolingDown or currentCharges <= 0 then return end
	
	local character = LocalPlayer.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local rootPart = character.HumanoidRootPart
		
		-- Если у нас выбран фокус, используем его, иначе ищем ближайшего перед нами
		local target = lockedTarget
		if not target then
			target = getBestTarget()
		end
		
		if target then
			currentCharges = currentCharges - 1
			
			-- Делаем мощный импульс строго вбок-назад относительно выбранного врага
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(50000, 0, 50000)
			
			-- Вычисляем вектор за спину врага
			local enemyCFrame = target.CFrame
			local sideDirection = (math.random(1, 2) == 1) and enemyCFrame.RightVector or -enemyCFrame.RightVector
			local backOfEnemy = -enemyCFrame.LookVector
			
			-- Рывок к позиции за спиной цели
			bodyVelocity.Velocity = (sideDirection * 40) + (backOfEnemy * 25)
			bodyVelocity.Parent = rootPart
			
			task.delay(0.2, function()
				if bodyVelocity then bodyVelocity:Destroy() end
			end)
			
			-- Система кулдауна после 4 использований
			if currentCharges <= 0 then
				isCoolingDown = true
				toggleDashBtn.Text = "Кулдаун зарядов..."
				toggleDashBtn.BackgroundColor3 = Color3.fromRGB(200, 140, 0)
				
				task.delay(3, function() -- Кулдаун 3 секунды
					currentCharges = maxCharges
					isCoolingDown = false
					if isEnabled then
						toggleDashBtn.Text = "Сайд-дэш по [3]: ВКЛ"
						toggleDashBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
					end
				end)
			end
		end
	end
end

-- Нажатие клавиши "3"
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if isEnabled and not gameProcessed then
		if input.KeyCode == Enum.KeyCode.Three or input.KeyCode == Enum.KeyCode.KeypadThree then
			executeSideDash()
		end
	end
end)

print("[Xeno] Скрипт с Lock-on и привязкой к цели успешно загружен!")
