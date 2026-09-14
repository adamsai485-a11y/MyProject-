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
title.Text = "JJS Camera Lock & Side Dash [3]"
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

-- Кнопка 1: Сайд-дэш
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

-- Кнопка 2: Лок-он по центру камеры
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
infoLabel.Text = "Лок-он целит персонажа на врага по центру экрана. [3] делает сайд-дэш за спину."
infoLabel.Parent = mainFrame

-- Функция поиска игрока, который ближе всего к центру экрана (на кого смотрит камера)
local function getTargetByCameraCenter()
	local bestTarget = nil
	local closestDistance = math.huge
	local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") then
			if p.Character.Humanoid.Health > 0 then
				local enemyRoot = p.Character.HumanoidRootPart
				
				-- Проецируем позицию врага на экран монитора
				local screenPos, onScreen = Camera:WorldToViewportPoint(enemyRoot.Position)
				
				if onScreen then
					local screenPos2D = Vector2.new(screenPos.X, screenPos.Y)
					local distFromCenter = (screenPos2D - screenCenter).Magnitude
					
					-- Ищем того, кто ближе всего к перекрестью/центру экрана (в пределах 150 пикселей)
					if distFromCenter < 150 and distFromCenter < closestDistance then
						closestDistance = distFromCenter
						bestTarget = enemyRoot
					end
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
		lockedTarget = getTargetByCameraCenter()
		if lockedTarget then
			toggleLockBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
			toggleLockBtn.Text = "Лок-он на врага: ВКЛ"
		else
			isLockOnEnabled = false
			toggleLockBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
			toggleLockBtn.Text = "Никого нет по центру!"
			task.delay(1.2, function()
				if not isLockOnEnabled then
					toggleLockBtn.Text = "Лок-он на врага: ВЫКЛ"
				end
			end)
		end
	else
		lockedTarget = nil
		toggleLockBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
		toggleLockBtn.Text = "Лок-он на врага: ВЫКЛ"
	end
end)

-- Цикл фиксации взгляда на выбранном враге
RunService.RenderStepped:Connect(function()
	if isLockOnEnabled then
		if lockedTarget and lockedTarget.Parent and lockedTarget.Parent:FindFirstChild("Humanoid") and lockedTarget.Parent.Humanoid.Health > 0 then
			local character = LocalPlayer.Character
			if character and character:FindFirstChild("HumanoidRootPart") then
				local myRoot = character.HumanoidRootPart
				-- Держим персонажа развернутым лицом к залоченной цели
				local targetPos = Vector3.new(lockedTarget.Position.X, myRoot.Position.Y, lockedTarget.Position.Z)
				myRoot.CFrame = CFrame.new(myRoot.Position, targetPos)
			end
		else
			-- Если цель умерла или вышла, плавно сбрасываем лок-он без спама текста
			isLockOnEnabled = false
			lockedTarget = nil
			toggleLockBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
			toggleLockBtn.Text = "Лок-он на врага: ВЫКЛ"
		end
	end
end)

-- Логика сайд-дэша за спину жестко привязанная к текущей цели
local function executeSideDash()
	if not isDashEnabled or not isLockOnEnabled then return end
	if isCoolingDown or currentCharges <= 0 then return end
	
	local character = LocalPlayer.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local rootPart = character.HumanoidRootPart
		
		if lockedTarget then
			currentCharges = currentCharges - 1
			
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(50000, 0, 50000)
			
			local enemyCFrame = lockedTarget.CFrame
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

print("[Xeno] Обновлен лок-он по центру экрана!")
