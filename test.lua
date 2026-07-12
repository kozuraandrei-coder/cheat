-- ПОДСВЕТКА РОЛЕЙ В MURDER MYSTERY 2 (Шериф — синий, Невиновные — зелёный)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local isActive = false
local highlightConnections = {}  -- Храним подсветки для каждого игрока

-- УДАЛЯЕМ СТАРЫЙ GUI
local oldGui = LocalPlayer.PlayerGui:FindFirstChild("RoleHighlightGUI")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RoleHighlightGUI"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- КНОПКА ON/OFF
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(0.5, -100, 0.5, -25)
button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
button.BorderColor3 = Color3.fromRGB(255, 255, 255)
button.BorderSizePixel = 2
button.Text = "OFF"
button.TextColor3 = Color3.fromRGB(255, 0, 0)
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.Parent = screenGui

-- ФУНКЦИЯ ПОЛУЧЕНИЯ РОЛИ ИГРОКА (для MM2)
local function GetPlayerRole(player)
    local character = player.Character
    if not character then return "Unknown" end

    -- Проверяем наличие оружия (убийца — нож, шериф — пистолет)
    local hasKnife = false
    local hasGun = false

    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            if tool.Name:lower():find("knife") or tool.Name:lower():find("dagger") then
                hasKnife = true
            end
            if tool.Name:lower():find("gun") or tool.Name:lower():find("pistol") then
                hasGun = true
            end
        end
    end

    -- Проверяем, что держит в руках
    if character:FindFirstChild("Tool") then
        local tool = character.Tool
        if tool.Name:lower():find("knife") or tool.Name:lower():find("dagger") then
            hasKnife = true
        end
        if tool.Name:lower():find("gun") or tool.Name:lower():find("pistol") then
            hasGun = true
        end
    end

    -- Определяем роль
    if hasKnife then
        return "Murderer"
    elseif hasGun then
        return "Sheriff"
    else
        return "Innocent"
    end
end

-- ФУНКЦИЯ СОЗДАНИЯ ПОДСВЕТКИ
local function CreateHighlight(player)
    -- Удаляем старую подсветку
    if highlightConnections[player] then
        highlightConnections[player]:Disconnect()
        highlightConnections[player] = nil
    end

    local character = player.Character
    if not character then return end

    local role = GetPlayerRole(player)
    local color = Color3.fromRGB(0, 255, 0)  -- Зелёный по умолчанию

    if role == "Sheriff" then
        color = Color3.fromRGB(0, 0, 255)    -- Синий
    elseif role == "Murderer" then
        color = Color3.fromRGB(255, 0, 0)    -- Красный (опционально)
    end

    -- Создаём Highlight для каждой части тела
    local connections = {}
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            local highlight = Instance.new("Highlight")
            highlight.Parent = part
            highlight.Adornee = part
            highlight.FillColor = color
            highlight.FillTransparency = 0.3
            highlight.OutlineColor = color
            highlight.OutlineTransparency = 0

            -- Сохраняем связь, чтобы потом удалить
            table.insert(connections, highlight)
        end
    end

    -- Сохраняем все подсветки для игрока
    highlightConnections[player] = connections
end

-- ФУНКЦИЯ УДАЛЕНИЯ ПОДСВЕТКИ
local function RemoveHighlight(player)
    if highlightConnections[player] then
        for _, highlight in ipairs(highlightConnections[player]) do
            highlight:Destroy()
        end
        highlightConnections[player] = nil
    end
end

-- ОСНОВНАЯ ЛОГИКА (обновление подсветки при изменении персонажа)
local function UpdateHighlights()
    if not isActive then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        -- Если у игрока нет персонажа — удаляем подсветку
        if not player.Character then
            RemoveHighlight(player)
            continue
        end

        -- Обновляем подсветку
        CreateHighlight(player)
    end
end

-- Подписываемся на изменения персонажа у всех игроков
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        UpdateHighlights()
    end)
end)

-- Запускаем обновление каждые 2 секунды (для надёжности)
RunService.Heartbeat:Connect(UpdateHighlights)

-- ПЕРЕКЛЮЧЕНИЕ ON/OFF
button.MouseButton1Click:Connect(function()
    isActive = not isActive

    if isActive then
        button.Text = "ON"
        button.TextColor3 = Color3.fromRGB(0, 255, 0)
        button.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        UpdateHighlights()  -- Включаем подсветку
        print("[NETERRROR] Подсветка ролей активирована!")
    else
        button.Text = "OFF"
        button.TextColor3 = Color3.fromRGB(255, 0, 0)
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

        -- Удаляем все подсветки
        for player in pairs(highlightConnections) do
            RemoveHighlight(player)
        end
        print("[NETERRROR] Подсветка ролей деактивирована.")
    end
end)

print("[NETERRROR] Скрипт загружен! Нажми ON для подсветки ролей.")
