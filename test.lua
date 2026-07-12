-- ИГРОКИ УЛЕТАЮТ В ПУСТОТУ И УМИРАЮТ (радиус 2.5)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local ACTIVATION_RADIUS = 2.5
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

-- ФУНКЦИЯ ВЫБРОСА В ПУСТОТУ
local function ThrowToVoid(targetPlayer)
    local targetChar = targetPlayer.Character
    if not targetChar then return end

    local rootPart = targetChar:FindFirstChild("HumanoidRootPart")
    local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then return end

    if thrownPlayers[targetPlayer] then return end

    -- 1. Отключаем гравитацию и ставим PlatformStand
    humanoid.PlatformStand = true
    rootPart.CanCollide = false

    -- 2. Отключаем все джойнты (чтобы тело разлетелось)
    for _, joint in ipairs(targetChar:GetDescendants()) do
        if joint:IsA("Motor6D") or joint:IsA("Weld") then
            joint:Destroy()
        end
    end

    -- 3. Телепортируем очень далеко вниз (в пустоту)
    local voidPosition = Vector3.new(
        rootPart.Position.X + math.random(-500, 500),  -- Случайный разброс по X
        -10000,  -- Очень глубоко (пустота)
        rootPart.Position.Z + math.random(-500, 500)   -- Случайный разброс по Z
    )
    rootPart.CFrame = CFrame.new(voidPosition)

    -- 4. Даём мощный импульс вниз (чтобы упал в пустоту)
    rootPart.Velocity = Vector3.new(
        math.random(-200, 200),
        -500,  -- Вниз с огромной скоростью
        math.random(-200, 200)
    )

    -- 5. Добавляем взрыв (для эффекта)
    local explosion = Instance.new("Explosion")
    explosion.Position = rootPart.Position
    explosion.BlastRadius = 30
    explosion.BlastPressure = 1000  -- Разбрасывает части тела
    explosion.Parent = workspace

    -- 6. Разбрасываем все части тела в разные стороны
    for _, part in ipairs(targetChar:GetDescendants()) do
        if part:IsA("BasePart") and part ~= rootPart then
            part.Velocity = Vector3.new(
                math.random(-300, 300),
                math.random(-300, -100),
                math.random(-300, 300)
            )
        end
    end

    -- 7. Убиваем Humanoid (чтобы точно умер)
    humanoid.Health = 0

    -- 8. Отмечаем как кинутого
    thrownPlayers[targetPlayer] = true

    -- 9. Через 3 секунды сбрасываем блокировку (можно кидать снова)
    task.wait(3)
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
            ThrowToVoid(player)
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
        print("[NETERRROR] Активирован! Игроки улетают в пустоту и умирают.")
    else
        button.Text = "OFF"
        button.TextColor3 = Color3.fromRGB(255, 0, 0)
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        print("[NETERRROR] Деактивирован.")
    end
end)

print("[NETERRROR] Скрипт загружен! Игроки улетают в пустоту и умирают (радиус 2.5).")
