-- MM2: Убийца = красный (ДАЖЕ КОГДА НОЖ СПРЯТАН), Невиновный = зелёный, Шериф без ника
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

local COLORS = {
    Innocent = Color3.fromRGB(0, 255, 0),
    Murderer = Color3.fromRGB(255, 0, 0)
}

-- Функция определения роли с сохранением
local function updateRole(player)
    local char = player.Character
    if not char then 
        -- Если персонаж умер, но роль была убийцей — оставляем
        if player:GetAttribute("Role") == "Murderer" then
            return "Murderer"
        end
        return "Innocent" 
    end
    
    -- Проверяем, шериф ли это (если есть Sheriff-объект — вообще без ника)
    if char:FindFirstChild("Sheriff") or (char:FindFirstChild("Hat") and char.Hat:FindFirstChild("SheriffHat")) then
        player:SetAttribute("Role", "Sheriff")
        return "Sheriff"
    end
    
    -- Проверяем на убийцу (по ножу ИЛИ по сохранённой роли)
    local isMurderer = char:FindFirstChild("Knife") or char:FindFirstChild("Murderer") or char:FindFirstChild("Gun")
    if isMurderer then
        player:SetAttribute("Role", "Murderer")
        return "Murderer"
    end
    
    -- Если ножа нет, но до этого был убийцей — оставляем метку
    if player:GetAttribute("Role") == "Murderer" then
        return "Murderer"
    end
    
    -- Если шериф жив — не показываем
    if player:GetAttribute("Role") == "Sheriff" then
        return "Sheriff"
    end
    
    -- Всё остальное — невиновный
    player:SetAttribute("Role", "Innocent")
    return "Innocent"
end

-- Создаём билборд
local function createBillboard(player)
    if player == lp then return end
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    local role = updateRole(player)
    
    -- Шерифа игнорируем
    if role == "Sheriff" then
        local old = head:FindFirstChild("MyNameBillboard")
        if old then old:Destroy() end
        return
    end

    local old = head:FindFirstChild("MyNameBillboard")
    if old then old:Destroy() end

    local bill = Instance.new("BillboardGui")
    bill.Name = "MyNameBillboard"
    bill.Adornee = head
    bill.Size = UDim2.new(0, 100, 0, 25)
    bill.StudsOffset = Vector3.new(0, 2.5, 0)
    bill.AlwaysOnTop = true
    bill.MaxDistance = 300

    local label = Instance.new("TextLabel")
    label.Name = "NameLabel"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = player.Name
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.3
    label.TextScaled = false

    label.TextColor3 = COLORS[role] or COLORS.Innocent
    label.Parent = bill
    bill.Parent = head
end

-- Обновление всех
local function refreshAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp then
            createBillboard(player)
        end
    end
end

-- События
local function setupPlayer(player)
    if player == lp then return end
    player.CharacterAdded:Connect(function()
        task.wait(0.3)
        -- При респавне сбрасываем роль, если это не убийца
        if player:GetAttribute("Role") ~= "Murderer" then
            player:SetAttribute("Role", nil)
        end
        createBillboard(player)
    end)
    createBillboard(player)
end

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)

-- Обновляем каждый кадр
RunService.RenderStepped:Connect(refreshAll)

print("✅ Убийца = красный (даже без ножа), Невиновный = зелёный, Шериф без ника")
