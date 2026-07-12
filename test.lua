-- РЕАЛЬНОЕ ОТКИДЫВАНИЕ (ФИЗИКА) — ИГРОКИ УЛЕТАЮТ, НО НЕ ИСЧЕЗАЮТ
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local myName = LocalPlayer.Name

local ACTIVATION_RADIUS = 2.5   -- Радиус срабатывания
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

-- ПЕРЕТАСКИВАНИЕ
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

-- ГЛАВНАЯ ФУНКЦИЯ ОТКИДЫВАНИЯ (ЧИСТАЯ ФИЗИКА)
local function LaunchPlayer(targetPlayer)
    if targetPlayer.Name == myName then return end

    local targetChar = targetPlayer.Character
    if not targetChar then return end

    local rootPart = targetChar:FindFirstChild("HumanoidRootPart")
    local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then return end

    if thrownPlayers[targetPlayer] then return end

    -- 1. Даём ОГРОМНЫЙ импульс, чтобы игрок реально улетел
    rootPart.Velocity = Vector3.new(
        math.random(-500, 500),   -- Случайный разброс по X (в стороны)
        400 + math.random(0, 300), -- Высоко вверх (400-700)
        800 + math.random(0, 500)  -- Далеко вперёд (800-1300)
    )

    -- 2. Добавляем вращение (чтобы эффект был зрелищным)
    rootPart.RotVelocity = Vector3.new(
        math.random(-50, 50),
        math.random(-50, 50),
        math.random(-50, 50)
    )

    -- 3. Отключаем PlatformStand, чтобы сервер не блокировал полёт
    humanoid.PlatformStand = false

    -- 4. Взрыв для эффекта (без урона)
    local explosion = Instance.new("Explosion")
    explosion.Position = rootPart.Position
    explosion.BlastRadius = 15
    explosion.BlastPressure = 0
    explosion.Parent = workspace

    -- 5. Отмечаем как кинутого (защита от повторного срабатывания)
    thrownPlayers[targetPlayer] = true

    -- 6. Через 2 секунды снимаем блокировку (можно кинуть снова)
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
    
    if isActive then
        button.Text = "ON"
        button.TextColor3 = Color3.fromRGB(0, 255, 0)
        button.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        print("[NETERRROR] Активирован! Реальное откидывание.")
    else
        button.Text = "OFF"
        button.TextColor3 = Color3.fromRGB(255, 0, 0)
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        print("[NETERRROR] Деактивирован.")
    end
end)

print("[NETERRROR] Скрипт загружен! Игроки улетают, но остаются видимыми.")
