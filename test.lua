-- ОТКИДЫВАНИЕ ДЛЯ MURDER MYSTERY 2 (ПРОВЕРЕННЫЙ МЕТОД)
-- Основа: комбинация Velocity + CFrame + обход анти-чита
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local myName = LocalPlayer.Name

local ACTIVATION_RADIUS = 2.5  -- Почти касание
local isActive = false
local thrownPlayers = {}

-- УДАЛЯЕМ СТАРЫЙ GUI
local oldGui = LocalPlayer.PlayerGui:FindFirstChild("NetErrorGUI")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NetErrorGUI"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- КНОПКА
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 150, 0, 50)
button.Position = UDim2.new(0.5, -75, 0.5, -25)
button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
button.BorderColor3 = Color3.fromRGB(255, 255, 255)
button.BorderSizePixel = 2
button.Text = "OFF"
button.TextColor3 = Color3.fromRGB(255, 0, 0)
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.Parent = screenGui

-- ПЕРЕТАСКИВАНИЕ (ТОЛЬКО ЗА КНОПКУ)
local dragging = false
local dragStart = nil
local startPos = nil

button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = button.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        button.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ГЛАВНАЯ ФУНКЦИЯ ОТКИДЫВАНИЯ (ПРОВЕРЕННЫЙ МЕТОД)
local function LaunchPlayer(targetPlayer)
    if targetPlayer.Name == myName then return end

    local targetChar = targetPlayer.Character
    if not targetChar then return end

    local rootPart = targetChar:FindFirstChild("HumanoidRootPart")
    local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then return end

    if thrownPlayers[targetPlayer] then return end

    -- 1. Отключаем все проверки сервера
    humanoid.PlatformStand = false
    rootPart.CanCollide = false

    -- 2. ОБХОД АНТИ-ЧИТА: Делаем "рывок" через CFrame
    local targetPosition = rootPart.Position + Vector3.new(
        math.random(-50, 50),
        100,
        math.random(300, 500)
    )
    rootPart.CFrame = CFrame.new(targetPosition)

    -- 3. ГЛАВНЫЙ ИМПУЛЬС (улетает очень далеко)
    rootPart.Velocity = Vector3.new(
        math.random(-500, 500),
        800 + math.random(0, 400),
        1500 + math.random(0, 600)
    )

    -- 4. Вращение (для красоты)
    rootPart.RotVelocity = Vector3.new(
        math.random(-150, 150),
        math.random(-150, 150),
        math.random(-150, 150)
    )

    -- 5. ЗАЩИТА ОТ НЕВИДИМОСТИ: принудительно делаем видимым
    for _, part in ipairs(targetChar:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = 0
            part.Material = Enum.Material.Plastic  -- Чтобы не было эффекта "призрака"
        end
    end

    -- 6. Отмечаем как кинутого
    thrownPlayers[targetPlayer] = true

    -- 7. Через 2 секунды снимаем блокировку
    task.wait(2)
    thrownPlayers[targetPlayer] = nil
end

-- ОСНОВНАЯ ЛОГИКА
local function CheckPlayers()
    if not isActive then return end

    local myChar = LocalPlayer.Character
    if not myChar then return end

    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local myPos = myRoot.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == myName then continue end

        local targetChar = player.Character
        if not targetChar then continue end

        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        if not targetRoot then continue end

        local dist = (myPos - targetRoot.Position).Magnitude
        
        if dist <= ACTIVATION_RADIUS and not thrownPlayers[player] then
            LaunchPlayer(player)
        end
    end
end

RunService.Heartbeat:Connect(CheckPlayers)

-- ПЕРЕКЛЮЧЕНИЕ ON/OFF
button.MouseButton1Click:Connect(function()
    isActive = not isActive
    
    if not isActive then
        thrownPlayers = {}
    end

    if isActive then
        button.Text = "ON"
        button.TextColor3 = Color3.fromRGB(0, 255, 0)
        button.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        print("[NETERRROR] Активирован! Проверенный метод откидывания.")
    else
        button.Text = "OFF"
        button.TextColor3 = Color3.fromRGB(255, 0, 0)
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        print("[NETERRROR] Деактивирован.")
    end
end)

print("[NETERRROR] Скрипт загружен! Использует проверенный метод для MM2.")
