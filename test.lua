-- https://github.com/yourmom
-- Murder Mystery 2 - Цветные ники (Sheriff = синий, Innocent = зелёный, Murderer = красный)
-- Кидай ВЕСЬ этот код в инжектор

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

local COLORS = {
    Sheriff = Color3.fromRGB(0, 0.5, 1),
    Innocent = Color3.fromRGB(0, 1, 0),
    Murderer = Color3.fromRGB(1, 0, 0)
}

local function createBillboard(player)
    if not player or player == localPlayer then return end
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    local bill = head:FindFirstChild("NameBillboard")
    if not bill then
        bill = Instance.new("BillboardGui")
        bill.Name = "NameBillboard"
        bill.Adornee = head
        bill.Size = UDim2.new(0, 200, 0, 50)
        bill.StudsOffset = Vector3.new(0, 2.5, 0)
        bill.MaxDistance = 100
        
        local label = Instance.new("TextLabel")
        label.Name = "NameLabel"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = player.Name
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0.3
        label.Parent = bill
        
        bill.Parent = head
    end
    return bill
end

local function getRole(player)
    local char = player.Character
    if not char then return "Innocent" end
    
    -- MM2 роли (ищем по объектам)
    if char:FindFirstChild("Sheriff") or (char:FindFirstChild("Hat") and char.Hat:FindFirstChild("SheriffHat")) then
        return "Sheriff"
    elseif char:FindFirstChild("Murderer") or char:FindFirstChild("Knife") or char:FindFirstChild("Gun") then
        return "Murderer"
    end
    return "Innocent"
end

local function updatePlayerColor(player)
    local bill = createBillboard(player)
    if not bill then return end
    local label = bill:FindFirstChild("NameLabel")
    if not label then return end
    
    local role = getRole(player)
    local color = COLORS[role] or COLORS.Innocent
    label.TextColor3 = color
end

local function refreshAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            updatePlayerColor(player)
        end
    end
end

-- Обработка новых игроков и респавна
local function setupPlayer(player)
    if player == localPlayer then return end
    player.CharacterAdded:Connect(function()
        wait(0.3)
        updatePlayerColor(player)
    end)
    updatePlayerColor(player)
end

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)

-- Постоянное обновление
RunService.Heartbeat:Connect(refreshAll)

print("✅ Цветные ники загружены! Sheriff = синий, Innocent = зелёный, Murderer = красный")
