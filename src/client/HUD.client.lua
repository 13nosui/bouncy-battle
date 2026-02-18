local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
gui.IgnoreGuiInset = true -- 画面の端まで使う

local FONT = Enum.Font.FredokaOne

-- ▼▼ メッセージ表示用ラベル (画面中央) ▼▼
local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "MessageLabel"
messageLabel.Size = UDim2.new(1, 0, 0, 100)
messageLabel.Position = UDim2.new(0, 0, 0.4, 0)
messageLabel.BackgroundTransparency = 1
messageLabel.Text = ""
messageLabel.TextColor3 = Color3.new(1, 1, 1)
messageLabel.TextStrokeTransparency = 0
messageLabel.Font = FONT
messageLabel.TextSize = 60
messageLabel.Parent = gui

-- ▼▼ スコア表示 (画面上部) ▼▼
local scoreFrame = Instance.new("Frame")
scoreFrame.Size = UDim2.new(0, 200, 0, 40)
scoreFrame.Position = UDim2.new(0.5, -100, 0, 10) -- 上中央
scoreFrame.BackgroundColor3 = Color3.new(0, 0, 0)
scoreFrame.BackgroundTransparency = 0.5
scoreFrame.Parent = gui
Instance.new("UICorner", scoreFrame).CornerRadius = UDim.new(1, 0)

local scoreText = Instance.new("TextLabel")
scoreText.Size = UDim2.new(1, 0, 1, 0)
scoreText.BackgroundTransparency = 1
scoreText.Text = "SCORE: 0 / 5"
scoreText.TextColor3 = Color3.new(1, 1, 1)
scoreText.Font = FONT
scoreText.TextSize = 24
scoreText.Parent = scoreFrame

-- ▼▼ HPバー (左下) ▼▼
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

-- ▼▼ 弾数表示 (右下) ▼▼
local ammoFrame = Instance.new("Frame")
ammoFrame.Name = "AmmoFrame"
ammoFrame.Size = UDim2.new(0, 150, 0, 50)
ammoFrame.Position = UDim2.new(1, -170, 1, -60)
ammoFrame.BackgroundColor3 = Color3.new(0, 0, 0)
ammoFrame.BackgroundTransparency = 0.5
ammoFrame.Parent = gui
Instance.new("UICorner", ammoFrame).CornerRadius = UDim.new(0, 8)

local ammoText = Instance.new("TextLabel")
ammoText.Name = "AmmoText"
ammoText.Size = UDim2.new(1, 0, 1, 0)
ammoText.BackgroundTransparency = 1
ammoText.Text = "-- / --"
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
	TweenService:Create(healthBar, TweenInfo.new(0.3), { Size = UDim2.new(ratio, 0, 1, 0) }):Play()

	if ratio > 0.5 then
		healthBar.BackgroundColor3 = Color3.fromRGB(85, 255, 127)
	elseif ratio > 0.2 then
		healthBar.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
	else
		healthBar.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
	end
end

-- 弾数更新
local function updateAmmo()
	if not character then
		return
	end
	local current = character:GetAttribute("Ammo") or 10
	local max = character:GetAttribute("MaxAmmo") or 10
	local isReloading = character:GetAttribute("IsReloading")

	if isReloading then
		ammoText.Text = "RELOAD..."
		ammoText.TextColor3 = Color3.fromRGB(255, 255, 100)
	else
		ammoText.Text = current .. " / " .. max
		if current == 0 then
			ammoText.TextColor3 = Color3.fromRGB(255, 85, 85)
		else
			ammoText.TextColor3 = Color3.fromRGB(100, 255, 255)
		end
	end
end

-- ★スコア更新
local function updateScore()
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local kills = leaderstats:FindFirstChild("Kills")
		if kills then
			scoreText.Text = "SCORE: " .. kills.Value .. " / 5"
		end
	end
end

-- メッセージ受信（勝利通知など）
local messageEvent = ReplicatedStorage:WaitForChild("GameMessage", 5)
if messageEvent then
	messageEvent.OnClientEvent:Connect(function(text, color)
		messageLabel.Text = text
		messageLabel.TextColor3 = color or Color3.new(1, 1, 1)

		-- アニメーション（拡大してフェードアウト）
		messageLabel.TextTransparency = 0
		messageLabel.TextStrokeTransparency = 0
		messageLabel.Size = UDim2.new(1, 0, 0, 100)

		local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(messageLabel, tweenInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
end

-- イベント接続
local function setupCharacter(newChar)
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid")

	humanoid.HealthChanged:Connect(updateHealth)
	updateHealth()

	newChar.AttributeChanged:Connect(updateAmmo)
	updateAmmo()
end

player.CharacterAdded:Connect(setupCharacter)
if character then
	setupCharacter(character)
end

-- スコア監視（leaderstats内の値が変わったら更新）
local function setupLeaderstats()
	local leaderstats = player:WaitForChild("leaderstats", 5)
	if leaderstats then
		local kills = leaderstats:WaitForChild("Kills", 5)
		if kills then
			kills.Changed:Connect(updateScore)
			updateScore()
		end
	end
end
setupLeaderstats()
