-- ПОЛНОЕ УНИЧТОЖЕНИЕ + ПЕРЕСОЗДАНИЕ + ЗАЩИТА ОТ АНТИ-ЧИТА (ДЛЯ MM2)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local myName = LocalPlayer.Name

local ACTIVATION_RADIUS = 2.5
local THROW_DISTANCE = 100000  -- Очень далеко
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

-- ФУНКЦИЯ — УНИЧТОЖАЕМ И СОЗДАЁМ НОВОГО ПЕРСОНАЖА В КОНЦЕ КАРТЫ
local function DeleteAndFixPlayer(targetPlayer)
    if targetPlayer.Name == myName then
        return
    end

    local targetChar = targetPlayer.Character
    if not targetChar then return end

    local rootPart = targetChar:FindFirstChild("HumanoidRootPart")
    local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then return end

    if thrownPlayers[targetPlayer] then return end

    -- 1. Сохраняем имя игрока
    local playerName = targetPlayer.Name

    -- 2. УНИЧТОЖАЕМ старого персонажа (сервер не сможет его вернуть)
    targetChar:Destroy()

    -- 3. Создаём НОВОГО персонажа в конце карты
    local newChar = Instance.new("Model")
    newChar.Name = playerName
    newChar.Parent = workspace

    -- Создаём новый Humanoid
    local newHumanoid = Instance.new("Humanoid")
    newHumanoid.Name = "Humanoid"
    newHumanoid.Parent = newChar
    newHumanoid.MaxHealth = 100
    newHumanoid.Health = 100

    -- Создаём новый RootPart (закреплённый на месте)
    local newRoot = Instance.new("Part")
    newRoot.Name = "HumanoidRootPart"
    newRoot.Size = Vector3.new(2, 1, 1)
    newRoot.Anchored = true  -- Полностью закреплён
    newRoot.CanCollide = false
    newRoot.Position = Vector3.new(
        rootPart.Position.X + math.random(-100, 100),  -- Случайный разброс по X
        -5000,  -- Очень глубоко (вне карты)
        THROW_DISTANCE
    )
    newRoot.Parent = newChar

    -- Привязываем Humanoid к RootPart
    newHumanoid:SetPrimaryPartCFrame(newRoot.CFrame)

    -- Добавляем части тела, чтобы игрок выглядел нормально (опционально)
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 1, 1)
    torso.Anchored = true
    torso.CanCollide = false
    torso.Position = newRoot.Position + Vector3.new(0, 0, 0)
    torso.Parent = newChar

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1, 1, 1)
    head.Anchored = true
    head.CanCollide = false
    head.Position = newRoot.Position + Vector3.new(0, 1.5, 0)
    head.Parent = newChar

    -- 4. Устанавливаем нового персонажа игроку
    targetPlayer.Character = newChar

    -- 5. Добавляем взрыв на месте старого персонажа (для эффекта)
    local explosion = Instance.new("Explosion")
    explosion.Position = rootPart.Position
    explosion.BlastRadius = 20
    explosion.BlastPressure = 0
    explosion.Parent = workspace

    -- 6. Отмечаем как кинутого
    thrownPlayers[targetPlayer] = true

    -- 7. ✅ ЗАЩИТА ОТ АНТИ-ЧИТА: Постоянно меняем позицию (дрожание)
    task.spawn(function()
        while newChar and newChar.Parent do
            -- Двигаем RootPart на 1 студию вперёд-назад по Z
            newRoot.Position = newRoot.Position + Vector3.new(0, 0, 1)
            task.wait(0.3)  -- Каждые 0.3 секунды
            newRoot.Position = newRoot.Position - Vector3.new(0, 0, 1)
            task.wait(0.3)
        end
    end)

    -- НЕ ОСВОБОЖДАЕМ (игрок остаётся в конце карты навсегда)
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
        if player.Name == myName then
            continue
        end

        local targetChar = player.Character
        if not targetChar then continue end

        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        if not targetRoot then continue end

        local dist = (myPos - targetRoot.Position).Magnitude
        
        if dist <= ACTIVATION_RADIUS and not thrownPlayers[player] then
            DeleteAndFixPlayer(player)
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
        print("[NETERRROR] ✅ Активирован! Игроки уничтожаются + защита от анти-чита.")
    else
        button.Text = "OFF"
        button.TextColor3 = Color3.fromRGB(255, 0, 0)
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        print("[NETERRROR] Деактивирован. Но уже кинутые игроки НЕ ВЕРНУТСЯ.")
    end
end)

print("[NETERRROR] 🚀 Скрипт загружен! Игроки уничтожаются + защита от анти-чита MM2.")
