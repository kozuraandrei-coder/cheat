-- MM2: Убийца = красный, Невиновный = зелёный, Шериф без ника, пистолет шерифа = синий маяк
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

local COLORS = {
    Innocent = Color3.fromRGB(0, 255, 0),
    Murderer = Color3.fromRGB(255, 0, 0)
}

local function getRole(player)
    local char = player.Character
    if not char then return "Innocent" end
    
    if char:FindFirstChild("Murderer") or char:FindFirstChild("Knife") or char:FindFirstChild("Gun") then
        return "Murderer"
    end
    return "Innocent"
end

-- Создаём ник только для убийцы и невиновного (шерифа игнорим)
local function createBillboard(player)
    if player == lp then return end
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    -- Проверяем, шериф ли это (если есть Sheriff-объект — не показываем)
    if char:FindFirstChild("Sheriff") or (char:FindFirstChild("Hat") and char.Hat:FindFirstChild("SheriffHat")) then
        -- Удаляем билборд если был
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

    local role = getRole(player)
    label.TextColor3 = COLORS[role] or COLORS.Innocent
    label.Parent = bill
    bill.Parent = head
end

-- Подсветка пистолета шерифа (синий маяк через стены)
local function highlightSheriffGun()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == lp then continue end
        local char = player.Character
        if not char then continue end
        
        -- Проверяем, жив ли шериф
        if char:FindFirstChild("Sheriff") or (char:FindFirstChild("Hat") and char.Hat:FindFirstChild("SheriffHat")) then
            -- Ищем пистолет (Gun или Tool)
            local gun = char:FindFirstChild("Gun") or char:FindFirstChild("Tool")
            if gun and gun:IsA("Tool") then
                -- Добавляем синий подсвет
                local highlight = gun:FindFirstChild("GunHighlight")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "GunHighlight"
                    highlight.FillColor = Color3.fromRGB(0, 80, 255)
                    highlight.FillTransparency = 0.3
                    highlight.OutlineColor = Color3.fromRGB(0, 150, 255)
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Видно через стены
                    highlight.Parent = gun
                end
            end
        else
            -- Если шериф умер или сменил роль — удаляем подсветку
            local gun = char:FindFirstChild("Gun") or char:FindFirstChild("Tool")
            if gun then
                local highlight = gun:FindFirstChild("GunHighlight")
                if highlight then highlight:Destroy() end
            end
        end
    end
end

-- Обновление ников
local function refreshAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp then
            createBillboard(player)
        end
    end
    highlightSheriffGun()
end

-- События
local function setupPlayer(player)
    if player == lp then return end
    player.CharacterAdded:Connect(function()
        task.wait(0.3)
        createBillboard(player)
        highlightSheriffGun()
    end)
    createBillboard(player)
end

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)

-- Обновляем каждый кадр (для мгновенной реакции)
RunService.RenderStepped:Connect(refreshAll)

print("✅ Убийца = красный, Невиновный = зелёный, Шериф без ника, пистолет шерифа = синий маяк")
