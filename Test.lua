-- Исправленная версия — кидает ТОЛЬКО при КАСАНИИ (радиус 5)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local THROW_DISTANCE = 10000
local ACTIVATION_RADIUS = 5  -- Уменьшено до 5 (почти касание)
local isActive = false

local thrownPlayers = {}

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NetErrorGUI"

local success, err = pcall(function()
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end)

if not success then
    screenGui.Parent = game:GetService("CoreGui")
end

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

local dragArea = Instance.new("Frame")
dragArea.Name = "DragArea"
dragArea.Size = UDim2.new(0, 200, 0, 70)
dragArea.Position = button.Position - UDim2.new(0, 25, 0, 10)
dragArea.BackgroundTransparency = 1
dragArea.Parent = screenGui

button.Parent = dragArea
button.Size = UDim2.new(0, 150, 0, 50)
button.Position = UDim2.new(0.5, -75, 0.5, -25)

-- ПЕРЕМЕЩЕНИЕ
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

-- ФУНКЦИЯ ВЫБРОСА (без PlatformStand, только ускорение)
local function ThrowPlayer(targetPlayer)
    local targetChar = targetPlayer.Character
    if not targetChar then return end

    local rootPart = targetChar:FindFirstChild("HumanoidRootPart")
    local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then return end

    if thrownPlayers[targetPlayer] then return end

    -- Убираем PlatformStand — он вызывает невидимость
    -- Просто даём резкий импульс в сторону конца карты
    local direction = Vector3.new(0, 0, 1) -- Ось Z
    local force = 200 -- Сила рывка
    
    -- Телепортируем + даём скорость, чтобы игрок улетел
    rootPart.CFrame = CFrame.new(Vector3.new(
        rootPart.Position.X,
        rootPart.Position.Y,
        THROW_DISTANCE
    ))
    
    -- Добавляем взрыв для эффекта (без урона)
    local explosion = Instance.new("Explosion")
    explosion.Position = rootPart.Position
    explosion.BlastRadius = 10
    explosion.BlastPressure = 0
    explosion.Parent = workspace

    thrownPlayers[targetPlayer] = true

    -- Удаляем из списка через 1.5 секунды (можно кидать снова)
    task.wait(1.5)
    thrownPlayers[targetPlayer] = nil
end

-- ОСНОВНАЯ ЛОГИКА С КАСАНИЕМ
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
        
        -- Кидаем ТОЛЬКО если расстояние МЕНЕЕ 5 (почти касание)
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
        print("[NETERRROR] Активирован. Кидаем при касании (радиус 5)!")
    else
        button.Text = "OFF"
        button.TextColor3 = Color3.fromRGB(255, 0, 0)
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        print("[NETERRROR] Деактивирован.")
    end
end)

print("[NETERRROR] Скрипт загружен! Кидает только при касании (радиус 5).")
