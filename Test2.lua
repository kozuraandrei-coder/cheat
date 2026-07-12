-- Исправленная версия — ИГРОКИ УЛЕТАЮТ И НЕ ВОЗВРАЩАЮТСЯ
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local THROW_DISTANCE = 10000
local ACTIVATION_RADIUS = 5
local isActive = false
local thrownPlayers = {}

-- GUI (без изменений)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NetErrorGUI"

local success, err = pcall(function()
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end)

if not success then
    screenGui.Parent = game:GetService("CoreGui")
end

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

local dragArea = Instance.new("Frame")
dragArea.Name = "DragArea"
dragArea.Size = UDim2.new(0, 200, 0, 70)
dragArea.Position = button.Position - UDim2.new(0, 25, 0, 10)
dragArea.BackgroundTransparency = 1
dragArea.Parent = screenGui

button.Parent = dragArea
button.Size = UDim2.new(0, 150, 0, 50)
button.Position = UDim2.new(0.5, -75, 0.5, -25)

local dragging = false
local dragStart = nil
local startPos = nil

dragArea.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = dragArea.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        dragArea.Position = UDim2.new(
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

-- ГЛАВНАЯ ФУНКЦИЯ ВЫБРОСА (с фиксацией позиции)
local function ThrowPlayer(targetPlayer)
    local targetChar = targetPlayer.Character
    if not targetChar then return end

    local rootPart = targetChar:FindFirstChild("HumanoidRootPart")
    local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then return end

    if thrownPlayers[targetPlayer] then return end

    -- 1. Ставим PlatformStand (чтобы сервер не трогал)
    humanoid.PlatformStand = true

    -- 2. Отключаем коллизии (чтобы не застревал)
    rootPart.CanCollide = false

    -- 3. Телепортируем в конец карты
    rootPart.CFrame = CFrame.new(Vector3.new(
        rootPart.Position.X,
        rootPart.Position.Y,
        THROW_DISTANCE
    ))

    -- 4. Даём мощный импульс в сторону конца карты (чтобы улетел)
    rootPart.Velocity = Vector3.new(0, 50, 1000) -- Вверх + вперёд по Z

    -- 5. Добавляем взрыв (для эффекта)
    local explosion = Instance.new("Explosion")
    explosion.Position = rootPart.Position
    explosion.BlastRadius = 15
    explosion.BlastPressure = 0
    explosion.Parent = workspace

    -- 6. Закрепляем результат — каждые 0.1 секунду возвращаем в конец карты
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not rootPart or not rootPart.Parent then
            connection:Disconnect()
            return
        end
        -- Если игрок пытается вернуться — телепортируем обратно
        if (rootPart.Position.Z < THROW_DISTANCE - 100) then
            rootPart.CFrame = CFrame.new(Vector3.new(
                rootPart.Position.X,
                rootPart.Position.Y,
                THROW_DISTANCE
            ))
            rootPart.Velocity = Vector3.new(0, 50, 1000)
        end
    end)

    -- 7. Отмечаем игрока как кинутого
    thrownPlayers[targetPlayer] = true

    -- 8. Через 5 секунд отпускаем (можно кидать снова)
    task.wait(5)
    connection:Disconnect()
    humanoid.PlatformStand = false
    rootPart.CanCollide = true
    thrownPlayers[targetPlayer] = nil
end

-- ОСНОВНАЯ ЛОГИКА
local function CheckPlayers()
    if not isActive then return end

    if not Character or not Character.Parent then
        Character = LocalPlayer.Character
        if not Character then return end
        HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        if not HumanoidRootPart then return end
    end

    local myPos = HumanoidRootPart.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local targetChar = player.Character
        if not targetChar then continue end

        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        if not targetRoot then continue end

        local dist = (myPos - targetRoot.Position).Magnitude
        
        if dist <= ACTIVATION_RADIUS and not thrownPlayers[player] then
            ThrowPlayer(player)
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
        print("[NETERRROR] Активирован! Кидаем с фиксацией позиции.")
    else
        button.Text = "OFF"
        button.TextColor3 = Color3.fromRGB(255, 0, 0)
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        print("[NETERRROR] Деактивирован.")
    end
end)

print("[NETERRROR] Скрипт загружен! Игроки теперь реально улетают и не возвращаются.")
