--[=[ XENO SCRIPT: Переключатель режима Дэша на клавишу 3 ]=]--

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Удаляем старое меню, если оно уже висело
if CoreGui:FindFirstChild("XenoJJSMenu") then
	CoreGui.XenoJJSMenu:Destroy()
end

-- Создаем GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XenoJJSMenu"
screenGui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 210)
mainFrame.Position = UDim2.new(0, 50, 0, 150)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

-- Заголовок
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "JJS Black Flash / Dash [3]"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- Переменные
local maxDashes = 4
local currentDashes = 4
local isEnabled = false -- Включен ли режим

-- Текст лимита дэшей
local dashLabel = Instance.new("TextLabel")
dashLabel.Size = UDim2.new(1, -20, 0, 25)
dashLabel.Position = UDim2.new(0, 10, 0, 45)
dashLabel.BackgroundTransparency = 1
dashLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
dashLabel.TextSize = 14
dashLabel.Font = Enum.Font.Gotham
dashLabel.TextXAlignment = Enum.TextXAlignment.Left
dashLabel.Text = "Лимит дэшей: 4/4"
dashLabel.Parent = mainFrame

-- Кнопки лимита (+ / -)
local dashPlus = Instance.new("TextButton")
dashPlus.Size = UDim2.new(0, 30, 0, 25)
dashPlus.Position = UDim2.new(1, -40, 0, 45)
dashPlus.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dashPlus.TextColor3 = Color3.fromRGB(255, 255, 255)
dashPlus.Text = "+"
dashPlus.Parent = mainFrame
Instance.new("UICorner", dashPlus).CornerRadius = UDim.new(0, 4)

local dashMinus = Instance.new("TextButton")
dashMinus.Size = UDim2.new(0, 30, 0, 25)
dashMinus.Position = UDim2.new(1, -75, 0, 45)
dashMinus.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dashMinus.TextColor3 = Color3.fromRGB(255, 255, 255)
dashMinus.Text = "-"
dashMinus.Parent = mainFrame
Instance.new("UICorner", dashMinus).CornerRadius = UDim.new(0, 4)

-- Кнопка-тумблер активации режима
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -20, 0, 45)
toggleBtn.Position = UDim2.new(0, 10, 0, 85)
toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40) -- Красный (выключено)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Text = "Режим дэша по [3]: ВЫКЛ"
toggleBtn.Parent = mainFrame
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

-- Инструкция снизу
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 0, 40)
infoLabel.Position = UDim2.new(0, 10, 0, 145)
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
infoLabel.TextSize = 12
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextWrapped = true
infoLabel.Text = "При включении: нажатие на '3' телепортирует за спину врага."
infoLabel.Parent = mainFrame

local function updateUI()
	dashLabel.Text = "Лимит дэшей: " .. currentDashes .. "/" .. maxDashes
end

-- Логика кнопок лимитов
dashPlus.MouseButton1Click:Connect(function()
	if maxDashes < 4 then
		maxDashes = maxDashes + 1
		currentDashes = math.min(currentDashes + 1, maxDashes)
		updateUI()
	end
end)

dashMinus.MouseButton1Click:Connect(function()
	if maxDashes > 1 then
		maxDashes = maxDashes - 1
		currentDashes = math.min(currentDashes, maxDashes)
		updateUI()
	end
end)

-- Переключение тумблера вкл/выкл
toggleBtn.MouseButton1Click:Connect(function()
	isEnabled = not isEnabled
	if isEnabled then
		toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60) -- Зеленый
		toggleBtn.Text = "Режим дэша по [3]: ВКЛ"
	else
		toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40) -- Красный
		toggleBtn.Text = "Режим дэша по [3]: ВЫКЛ"
	end
end)

-- Функция самого дэша за спину
local function executeDash()
	if currentDashes > 0 then
		currentDashes = currentDashes - 1
		updateUI()
		
		local character = LocalPlayer.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local myRoot = character.HumanoidRootPart
			
			local targetRoot = nil
			local shortestDist = 45
			
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
					local enemyRoot = p.Character.HumanoidRootPart
					local dist = (myRoot.Position - enemyRoot.Position).Magnitude
					if dist < shortestDist then
						shortestDist = dist
						targetRoot = enemyRoot
					end
				end
			end
			
			if targetRoot then
				-- Телепорт за спину (на 4 стада назад и разворот лицом к врагу)
				myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 4) * CFrame.Angles(0, math.rad(180), 0)
			end
		end
	else
		-- Когда лимит кончился, автоматически вырубаем режим
		isEnabled = false
		toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
		toggleBtn.Text = "Лимит исчерпан (0/4)"
	end
end

-- Отслеживание нажатия клавиши "3"
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- Если режим включен и игрок нажал клавишу 3 (на основной клавиатуре или NumPad)
	if isEnabled and not gameProcessed then
		if input.KeyCode == Enum.KeyCode.Three or input.KeyCode == Enum.KeyCode.KeypadThree then
			executeDash()
		end
	end
end)

updateUI()
print("[Xeno] Скрипт успешно заинжекчен!")
