-- ФИНАЛЬНАЯ ВЕРСИЯ 2.0 — БЕЗ ДУБЛИРОВАНИЯ КНОПОК И С ЖЁСТКОЙ ФИКСАЦИЕЙ
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local THROW_DISTANCE = 10000
local ACTIVATION_RADIUS = 2.5  -- Почти касание
local isActive = false
local thrownPlayers = {}
local fixConnections = {} -- Храним все потоки фиксации

-- УДАЛЯЕМ СТАРЫЙ GUI, ЕСЛИ ОН ЕСТЬ (чтобы не было дубликатов)
local oldGui = LocalPlayer.PlayerGui:FindFirstChild("NetErrorGUI")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NetErrorGUI"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- СОЗДАЁМ ТОЛЬКО ОДНУ КНОПКУ
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

-- ПЕРЕТАСКИВАНИЕ (только за кнопку, без лишних фреймов)
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

-- ЖЁСТКАЯ ФИКСАЦИЯ ИГРОКА В КОНЦЕ КАРТЫ
local function fixPlayer(rootPart, humanoid)
    -- Если уже есть активная фиксация — отключаем её
    if fixConnections[rootPart] then
        fixConnections[rootPart]:Disconnect()
        fixConnections[rootPart] = nil
    end

    humanoid.PlatformStand = true
    rootPart.CanCollide = false

    -- Телепортируем
    rootPart.CFrame = CFrame.new(Vector3.new(
        rootPart.Position.X,
        rootPart.Position.Y,
        THROW_DISTANCE
    ))
    rootPart.Velocity = Vector3.new(0, 50, 1000)

    -- Взрыв для эффекта
    local explosion = Instance.new("Explosion")
    explosion.Position = rootPart.Position
    explosion.BlastRadius = 15
    explosion.BlastPressure = 0
    explosion.Parent = workspace

    -- Постоянная фиксация (каждый кадр)
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not rootPart or not rootPart.Parent then
            connection:Disconnect()
            fixConnections[rootPart] = nil
            return
        end
        -- Если игрок пытается вернуться — возвращаем его
        if (rootPart.Position.Z < THROW_DISTANCE - 50) then
            rootPart.CFrame = CFrame.new(Vector3.new(
                rootPart.Position.X,
                rootPart.Position.Y,
                THROW_DISTANCE
            ))
            rootPart.Velocity = Vector3.new(0, 50, 1000)
        end
    end)

    fixConnections[rootPart] = connection
end

-- ФУНКЦИЯ ВЫБРОСА
local function ThrowPlayer(targetPlayer)
    local targetChar = targetPlayer.Character
    if not targetChar then return end

    local rootPart = targetChar:FindFirstChild("HumanoidRootPart")
    local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then return end

    if thrownPlayers[targetPlayer] then return end

    -- Фиксируем игрока
    fixPlayer(rootPart, humanoid)
    thrownPlayers[targetPlayer] = true

    -- Освобождаем через 8 секунд (можно кидать снова)
    task.wait(8)
    if fixConnections[rootPart] then
        fixConnections[rootPart]:Disconnect()
        fixConnections[rootPart] = nil
    end
    humanoid.PlatformStand = false
    rootPart.CanCollide = true
    thrownPlayers[targetPlayer] = nil
end

-- ОСНОВНАЯ ЛОГИКА ПРОВЕРКИ
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
        -- Очищаем все фиксации
        for rootPart, connection in pairs(fixConnections) do
            connection:Disconnect()
        end
        fixConnections = {}
        thrownPlayers = {}
    end

    if isActive then
        button.Text = "ON"
        button.TextColor3 = Color3.fromRGB(0, 255, 0)
        button.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        print("[NETERRROR] Активирован! Радиус 2.5 (вплотную).")
    else
        button.Text = "OFF"
        button.TextColor3 = Color3.fromRGB(255, 0, 0)
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        print("[NETERRROR] Деактивирован.")
    end
end)

print("[NETERRROR] Скрипт загружен! Кнопка одна, дубликатов нет.")
