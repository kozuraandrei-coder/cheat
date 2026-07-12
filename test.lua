-- MM2: Цветные ники + всегда видно + маленькие (свои билборды)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

local COLORS = {
    Sheriff = Color3.fromRGB(0, 80, 255),   -- Синий
    Innocent = Color3.fromRGB(0, 255, 0),   -- Зелёный
    Murderer = Color3.fromRGB(255, 0, 0)    -- Красный
}

-- Функция получения роли
local function getRole(player)
    local char = player.Character
    if not char then return "Innocent" end
    if char:FindFirstChild("Sheriff") or (char:FindFirstChild("Hat") and char.Hat:FindFirstChild("SheriffHat")) then
        return "Sheriff"
    elseif char:FindFirstChild("Murderer") or char:FindFirstChild("Knife") or char:FindFirstChild("Gun") then
        return "Murderer"
    end
    return "Innocent"
end

-- Создаём новый билборд (убиваем старый)
local function createMyBillboard(player)
    if player == lp then return end
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    -- Удаляем старый билборд, если есть
    local old = head:FindFirstChild("MyNameBillboard")
    if old then old:Destroy() end

    -- Создаём свой
    local bill = Instance.new("BillboardGui")
    bill.Name = "MyNameBillboard"
    bill.Adornee = head
    bill.Size = UDim2.new(0, 100, 0, 25)    -- Маленький
    bill.StudsOffset = Vector3.new(0, 2.5, 0)
    bill.AlwaysOnTop = true                  -- ВИДНО ЧЕРЕЗ СТЕНЫ
    bill.MaxDistance = 300
    bill.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local label = Instance.new("TextLabel")
    label.Name = "NameLabel"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = player.Name
    label.TextColor3 = Color3.fromRGB(255, 255, 255) -- Временный цвет
    label.TextSize = 14                             -- Маленький шрифт
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.3
    label.TextScaled = false
    label.Parent = bill

    bill.Parent = head
    return bill
end

-- Обновляем цвет
local function updatePlayer(player)
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    local bill = head:FindFirstChild("MyNameBillboard")
    if not bill then
        bill = createMyBillboard(player)
        if not bill then return end
    end

    local label = bill:FindFirstChild("NameLabel")
    if label then
        local role = getRole(player)
        label.TextColor3 = COLORS[role] or COLORS.Innocent
    end
end

-- Принудительное обновление всех
local function refreshAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp then
            updatePlayer(player)
        end
    end
end

-- События
local function setupPlayer(player)
    if player == lp then return end
    player.CharacterAdded:Connect(function()
        task.wait(0.2)
        updatePlayer(player)
    end)
    updatePlayer(player)
end

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)

-- Обновляем каждый кадр
RunService.RenderStepped:Connect(refreshAll)

print("✅ ГОТОВО! Ники цветные, видны через стены, маленькие.")
