-- Murder Mystery 2 - Цветные ники + Wallhack + Уменьшенный размер
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

local COLORS = {
    Sheriff = Color3.fromRGB(0, 0.5, 1),
    Innocent = Color3.fromRGB(0, 1, 0),
    Murderer = Color3.fromRGB(1, 0, 0)
}

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

local function forceColor(player)
    if player == lp then return end
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    local nameDisplay = head:FindFirstChild("NameDisplay") or head:FindFirstChild("NameBillboard")
    if nameDisplay then
        -- ВКЛЮЧАЕМ ВИДИМОСТЬ ЧЕРЕЗ СТЕНЫ
        nameDisplay.AlwaysOnTop = true
        
        local label = nameDisplay:FindFirstChild("Name") or nameDisplay:FindFirstChild("TextLabel")
        if label and label:IsA("TextLabel") then
            local role = getRole(player)
            label.TextColor3 = COLORS[role] or COLORS.Innocent
            
            -- УМЕНЬШАЕМ РАЗМЕР НИКА (было 20, стало 14)
            label.TextSize = 14
            label.TextScaled = false
        end
        
        -- УМЕНЬШАЕМ САМ БИЛБОРД
        nameDisplay.Size = UDim2.new(0, 120, 0, 30) -- было 200x50, теперь меньше
        nameDisplay.StudsOffset = Vector3.new(0, 2, 0)
    end
end

-- БЕСКОНЕЧНЫЙ ЦИКЛ
RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        forceColor(player)
    end
end)

local function onCharacterAdded(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.1)
        forceColor(player)
    end)
    forceColor(player)
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= lp then
        onCharacterAdded(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= lp then
        onCharacterAdded(player)
    end
end)

print("✅ Цветные ники + Wallhack + Уменьшенный размер ЗАГРУЖЕНЫ!")
