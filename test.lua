local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

-- Цвета
local COLORS = {
    Sheriff = Color3.fromRGB(0, 0.5, 1),   -- Синий
    Innocent = Color3.fromRGB(0, 1, 0),    -- Зелёный
    Murderer = Color3.fromRGB(1, 0, 0)     -- Красный
}

-- Функция обновления цвета ника
local function updateNameColor(player)
    if not player or not player.Character or not player.Character:FindFirstChild("Head") then return end
    
    local head = player.Character.Head
    local billboard = head:FindFirstChild("NameBillboard")
    if not billboard then return end
    
    -- Определяем роль (замени на свои значения из реальной игры)
    local role = player:GetAttribute("Role") or "Innocent" -- или через Folders, смотри как у тебя хранятся роли
    
    if role == "Sheriff" then
        billboard.NameColor = COLORS.Sheriff
    elseif role == "Murderer" then
        billboard.NameColor = COLORS.Murderer
    else
        billboard.NameColor = COLORS.Innocent
    end
end

-- Обновляем всех игроков при изменении их роли
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= localPlayer then
        player:GetAttributeChangedSignal("Role"):Connect(function()
            updateNameColor(player)
        end)
        updateNameColor(player)
    end
end

-- Для новых игроков
Players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then
        player:GetAttributeChangedSignal("Role"):Connect(function()
            updateNameColor(player)
        end)
        updateNameColor(player)
    end
end)

-- Постоянное обновление (на случай, если билборд пересоздаётся)
RunService.Heartbeat:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            updateNameColor(player)
        end
    end
end)
