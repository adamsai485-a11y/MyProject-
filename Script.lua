local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
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

-- Состояния
local isDashEnabled = false
local isLockOnEnabled = false
local lockedTarget = nil
local currentCharges = 4
local maxCharges = 4
local isCoolingDown = false

-- Кнопка 1: Тумблер Сайд-дэша
local toggleDashBtn = Instance.new("TextButton")
toggleDashBtn.Size = UDim2.new(1, -20, 0, 40)
toggleDashBtn.Position = UDim2.new(0, 10, 0, 40)
toggleDashBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
toggleDashBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleDashBtn.TextSize = 13
toggleDashBtn.Font = Enum.Font.GothamBold
toggleDashBtn.Text = "Сайд-дэш по [3]: ВЫКЛ"
toggleDashBtn.Parent = mainFrame
Instance.new("UICorner", toggleDashBtn).CornerRadius = UDim.new(0, 6)

-- Кнопка 2: Тумблер Лок-она
local toggleLockBtn = Instance.new("TextButton")
toggleLockBtn.Size = UDim2.new(1, -20, 0, 40)
toggleLockBtn.Position = UDim2.new(0, 10, 0, 88)
toggleLockBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
toggleLockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleLockBtn.TextSize = 13
toggleLockBtn.Font = Enum.Font.GothamBold
toggleLockBtn.Text = "Лок-он на врага: ВЫКЛ"
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
infoLabel.Text = "Нужен ВКЛ Сайд-дэш И ВКЛ Лок-он, чтобы [3] делал дэш за спину цели."
infoLabel.Parent = mainFrame

-- Функция поиска ближайшего врага ПЕРЕД игроком
local function getBestTarget()
	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
	local myRoot = character.HumanoidRootPart
	
	local bestTarget = nil
	local shortestDist = 60
	
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") then
			if p.Character.Humanoid.Health > 0 then
				local enemyRoot = p.Character.HumanoidRootPart
				local dist = (myRoot.Position - enemyRoot.Position).Magnitude
				
				local directionToEnemy = (enemyRoot.Position - myRoot.Position).Unit
				local dotProduct = myRoot.LookVector:Dot(directionToEnemy)
				
				if dotProduct > 0 and dist < shortestDist then
					shortestDist = dist
					bestTarget = enemyRoot
				end
			end
		end
	end
	return bestTarget
end

-- Переключение Сайд-дэша
toggleDashBtn.MouseButton1Click:Connect(function()
	isDashEnabled = not isDashEnabled
	if isDashEnabled then
		toggleDashBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
		toggleDashBtn.Text = "Сайд-дэш по [3]: ВКЛ"
	else
		toggleDashBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
		toggleDashBtn.Text = "Сайд-дэш по [3]: ВЫКЛ"
	end
end)

-- Переключение Лок-она
toggleLockBtn.MouseButton1Click:Connect(function()
	isLockOnEnabled = not isLockOnEnabled
	
	if isLockOnEnabled then
		lockedTarget = getBestTarget()
		if lockedTarget then
			toggleLockBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
			toggleLockBtn.Text = "Лок-он на врага: ВКЛ"
		else
			isLockOnEnabled = false
			toggleLockBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
			toggleLockBtn.Text = "Цель не найдена спереди!"
			task.wait(1.5)
			toggleLockBtn.Text = "Лок-он на врага: ВЫКЛ"
		end
	else
		lockedTarget = nil
		toggleLockBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
		toggleLockBtn.Text = "Лок-он на врага: ВЫКЛ"
	end
end)

-- Цикл работы Лок-она
RunService.RenderStepped:Connect(function()
	if isLockOnEnabled and lockedTarget and lockedTarget.Parent then
		local character = LocalPlayer.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local myRoot = character.HumanoidRootPart
			local targetPos = Vector3.new(lockedTarget.Position.X, myRoot.Position.Y, lockedTarget.Position.Z)
			myRoot.CFrame = CFrame.new(myRoot.Position, targetPos)
		end
	else
		if isLockOnEnabled and (not lockedTarget or not lockedTarget.Parent) then
			isLockOnEnabled = false
			lockedTarget = nil
			toggleLockBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
			toggleLockBtn.Text = "Лок-он: Цель потеряна"
		end
	end
end)

-- Логика сайд-дэша (срабатывает ТОЛЬКО если включен И Сайд-дэш И Лок-он)
local function executeSideDash()
	if not isDashEnabled or not isLockOnEnabled then return end
	if isCoolingDown or currentCharges <= 0 then return end
	
	local character = LocalPlayer.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local rootPart = character.HumanoidRootPart
		local target = lockedTarget
		
		if target then
			currentCharges = currentCharges - 1
			
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(50000, 0, 50000)
			
			local enemyCFrame = target.CFrame
			local sideDirection = (math.random(1, 2) == 1) and enemyCFrame.RightVector or -enemyCFrame.RightVector
			local backOfEnemy = -enemyCFrame.LookVector
			
			bodyVelocity.Velocity = (sideDirection * 40) + (backOfEnemy * 25)
			bodyVelocity.Parent = rootPart
			
			task.delay(0.2, function()
				if bodyVelocity then bodyVelocity:Destroy() end
			end)
			
			if currentCharges <= 0 then
				isCoolingDown = true
				toggleDashBtn.Text = "Кулдаун зарядов..."
				toggleDashBtn.BackgroundColor3 = Color3.fromRGB(200, 140, 0)
				
				task.delay(3, function()
					currentCharges = maxCharges
					isCoolingDown = false
					if isDashEnabled then
						toggleDashBtn.Text = "Сайд-дэш по [3]: ВКЛ"
						toggleDashBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
					end
				end)
			end
		end
	end
end

-- Кнопка [3]
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed then
		if input.KeyCode == Enum.KeyCode.Three or input.KeyCode == Enum.KeyCode.KeypadThree then
			executeSideDash()
		end
	end
end)

print("[Xeno] Обновлено: Сайд-дэш работает только при активном Лок-оне!")
