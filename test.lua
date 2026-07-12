-- MM2: Шериф = СИНИЙ, Убийца = КРАСНЫЙ, Невиновный = ЗЕЛЁНЫЙ + Wallhack + Маленькие
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

local COLORS = {
    Sheriff = Color3.fromRGB(0, 80, 255),   -- СИНИЙ
    Innocent = Color3.fromRGB(0, 255, 0),   -- ЗЕЛЁНЫЙ
    Murderer = Color3.fromRGB(255, 0, 0)    -- КРАСНЫЙ
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

local function createMyBillboard(player)
    if player == lp then return end
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

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

    -- Цвет по роли
    local role = getRole(player)
    label.TextColor3 = COLORS[role] or COLORS.Innocent

    label.Parent = bill
    bill.Parent = head
end

local function refreshAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp then
            createMyBillboard(player)
        end
    end
end

local function setupPlayer(player)
    if player == lp then return end
    player.CharacterAdded:Connect(function()
        task.wait(0.2)
        createMyBillboard(player)
    end)
    createMyBillboard(player)
end

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)
RunService.RenderStepped:Connect(refreshAll)

print("✅ Шериф = СИНИЙ, Убийца = КРАСНЫЙ, Невиновный = ЗЕЛЁНЫЙ")
