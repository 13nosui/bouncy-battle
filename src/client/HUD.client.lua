local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- 標準HPバー無効化
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

-- UI生成
local gui = Instance.new("ScreenGui")
gui.Name = "GameHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local FONT = Enum.Font.FredokaOne

-- HPバー
local healthFrame = Instance.new("Frame")
healthFrame.Name = "HealthFrame"
healthFrame.Size = UDim2.new(0, 300, 0, 30)
healthFrame.Position = UDim2.new(0, 20, 1, -50)
healthFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
healthFrame.BorderSizePixel = 0
healthFrame.Parent = gui
Instance.new("UICorner", healthFrame).CornerRadius = UDim.new(0, 8)

local healthBar = Instance.new("Frame")
healthBar.Name = "Bar"
healthBar.Size = UDim2.new(1, 0, 1, 0)
healthBar.BackgroundColor3 = Color3.fromRGB(85, 255, 127)
healthBar.BorderSizePixel = 0
healthBar.Parent = healthFrame
Instance.new("UICorner", healthBar).CornerRadius = UDim.new(0, 8)

local healthText = Instance.new("TextLabel")
healthText.Size = UDim2.new(1, 0, 1, 0)
healthText.BackgroundTransparency = 1
healthText.Text = "100 / 100"
healthText.TextColor3 = Color3.new(1, 1, 1)
healthText.Font = FONT
healthText.TextSize = 20
healthText.Parent = healthFrame

-- 弾数表示
local ammoFrame = Instance.new("Frame")
ammoFrame.Name = "AmmoFrame"
ammoFrame.Size = UDim2.new(0, 150, 0, 50)
ammoFrame.Position = UDim2.new(1, -170, 1, -60)
ammoFrame.BackgroundColor3 = Color3.new(0, 0, 0)
ammoFrame.BackgroundTransparency = 0.5
ammoFrame.BorderSizePixel = 0
ammoFrame.Parent = gui
Instance.new("UICorner", ammoFrame).CornerRadius = UDim.new(0, 8)

local ammoText = Instance.new("TextLabel")
ammoText.Name = "AmmoText"
ammoText.Size = UDim2.new(1, 0, 1, 0)
ammoText.BackgroundTransparency = 1
ammoText.Text = "-- / --" -- 初期値
ammoText.TextColor3 = Color3.fromRGB(100, 255, 255)
ammoText.Font = FONT
ammoText.TextSize = 32
ammoText.Parent = ammoFrame

-- === 更新ロジック ===

-- HP更新
local function updateHealth()
	if not humanoid then
		return
	end
	local health = math.clamp(humanoid.Health, 0, humanoid.MaxHealth)
	local max = humanoid.MaxHealth
	local ratio = health / max

	healthText.Text = math.floor(health) .. " / " .. math.floor(max)

	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(healthBar, tweenInfo, { Size = UDim2.new(ratio, 0, 1, 0) }):Play()

	if ratio > 0.5 then
		healthBar.BackgroundColor3 = Color3.fromRGB(85, 255, 127)
	elseif ratio > 0.2 then
		healthBar.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
	else
		healthBar.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
	end
end

-- ★弾数更新
local function updateAmmo()
	if not character then
		return
	end

	-- 属性から値を取得（なければデフォルト）
	local current = character:GetAttribute("Ammo") or 10
	local max = character:GetAttribute("MaxAmmo") or 10
	local isReloading = character:GetAttribute("IsReloading")

	if isReloading then
		ammoText.Text = "RELOAD..."
		ammoText.TextColor3 = Color3.fromRGB(255, 255, 100) -- 黄色
	else
		ammoText.Text = current .. " / " .. max
		if current == 0 then
			ammoText.TextColor3 = Color3.fromRGB(255, 85, 85) -- 赤（弾切れ）
		else
			ammoText.TextColor3 = Color3.fromRGB(100, 255, 255) -- 水色
		end
	end
end

-- イベント接続
local function setupCharacter(newChar)
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid")

	humanoid.HealthChanged:Connect(updateHealth)
	updateHealth()

	-- ★属性の変更を監視して表示を変える
	newChar.AttributeChanged:Connect(updateAmmo)
	updateAmmo()
end

player.CharacterAdded:Connect(setupCharacter)

if character then
	setupCharacter(character)
end
