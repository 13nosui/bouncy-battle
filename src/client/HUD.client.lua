-- src/client/HUD.client.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

-- === RIVALS風 ロードアウトUIの作成 ===
local loadoutGui = Instance.new("ScreenGui")
loadoutGui.Name = "LoadoutGui"
loadoutGui.ResetOnSpawn = false
loadoutGui.IgnoreGuiInset = true
loadoutGui.Parent = playerGui

-- 画面下部中央のコンテナ
local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0, 400, 0, 80)
container.Position = UDim2.new(0.5, -200, 1, -100) -- 下から少し浮かせた位置
container.BackgroundTransparency = 1
container.Parent = loadoutGui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 12) -- スロット間の隙間
layout.Parent = container

-- スロットを生成する関数
local function createSlot(slotName, keybindStr, layoutOrder)
	local slot = Instance.new("Frame")
	slot.Name = slotName
	slot.Size = UDim2.new(0, 80, 0, 80)
	slot.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- 暗い背景
	slot.BackgroundTransparency = 0.4 -- 半透明でモダンに
	slot.LayoutOrder = layoutOrder
	slot.Parent = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = slot

	-- 選択枠（ハイライト用）
	local stroke = Instance.new("UIStroke")
	stroke.Name = "Highlight"
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.8 -- 初期状態は薄い
	stroke.Thickness = 2
	stroke.Parent = slot

	-- キーバインド表示（左上）
	local keyBg = Instance.new("Frame")
	keyBg.Size = UDim2.new(0, 24, 0, 24)
	keyBg.Position = UDim2.new(0, -6, 0, -6)
	keyBg.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
	keyBg.Parent = slot
	local keyCorner = Instance.new("UICorner")
	keyCorner.CornerRadius = UDim.new(0, 4)
	keyCorner.Parent = keyBg

	local keyLabel = Instance.new("TextLabel")
	keyLabel.Size = UDim2.new(1, 0, 1, 0)
	keyLabel.BackgroundTransparency = 1
	keyLabel.TextColor3 = Color3.fromRGB(30, 30, 30)
	keyLabel.Font = Enum.Font.GothamBold
	keyLabel.Text = keybindStr
	keyLabel.TextSize = 14
	keyLabel.Parent = keyBg

	-- 装備の名前表示（中央）
	local itemLabel = Instance.new("TextLabel")
	itemLabel.Name = "ItemName"
	itemLabel.Size = UDim2.new(1, -10, 1, -10)
	itemLabel.Position = UDim2.new(0, 5, 0, 5)
	itemLabel.BackgroundTransparency = 1
	itemLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	itemLabel.Font = Enum.Font.GothamMedium
	itemLabel.Text = "Empty"
	itemLabel.TextSize = 12
	itemLabel.TextWrapped = true
	itemLabel.Parent = slot

	return slot
end

-- 4つのスロットを生成
local slotWeapon0 = createSlot("Slot_Weapon0", "0", 0) -- ★追加: スロット0を作る
slotWeapon0.Visible = false -- ★追加: 最初は隠しておく（持っている時だけ表示する）

local slotWeapon1 = createSlot("Slot_Weapon1", "1", 1)
local slotWeapon2 = createSlot("Slot_Weapon2", "2", 2)
local slotAbilityQ = createSlot("Slot_AbilityQ", "Q", 3)
local slotAbilityZ = createSlot("Slot_AbilityZ", "Z", 4)

-- スロットの文字を最新の状態に書き換える関数
local function updateSlots()
	local tool0, tool1, tool2
	local backpack = player:FindFirstChild("Backpack")
	local char = player.Character

	-- スロット番号の目印を見て、どちらの枠に入る武器か判定する
	local function checkTools(parent)
		if not parent then
			return
		end
		for _, item in ipairs(parent:GetChildren()) do
			if item:IsA("Tool") then
				if item:GetAttribute("Slot") == 0 then
					tool0 = item
				end
				if item:GetAttribute("Slot") == 1 then
					tool1 = item
				end
				if item:GetAttribute("Slot") == 2 then
					tool2 = item
				end
			end
		end
	end

	checkTools(backpack)
	checkTools(char)

	-- 1. 武器スロットの名前更新
	slotWeapon0.ItemName.Text = tool0 and tool0.Name or "Empty"
	slotWeapon0.Visible = (tool0 ~= nil)

	slotWeapon1.ItemName.Text = tool1 and tool1.Name or "Empty"
	slotWeapon2.ItemName.Text = tool2 and tool2.Name or "Empty"

	-- ★今手に持っている武器のスロットを水色に光らせる
	local equippedTool = char and char:FindFirstChildOfClass("Tool")

	local function setHighlight(slot, tool)
		if tool and equippedTool == tool then
			slot.Highlight.Transparency = 0
			slot.Highlight.Color = Color3.fromRGB(0, 255, 255) -- アクティブな色（水色）
		else
			slot.Highlight.Transparency = 0.8
			slot.Highlight.Color = Color3.fromRGB(255, 255, 255) -- 待機中の色（白）
		end
	end

	setHighlight(slotWeapon0, tool0)
	setHighlight(slotWeapon1, tool1)
	setHighlight(slotWeapon2, tool2)

	-- 2. Q枠（スロットA）の更新
	local sq = player:GetAttribute("SlotQ")
	slotAbilityQ.ItemName.Text = (sq and sq ~= "") and sq or "Empty"

	-- 3. Z枠（スロットB）の更新
	local sz = player:GetAttribute("SlotZ")
	slotAbilityZ.ItemName.Text = (sz and sz ~= "") and sz or "Empty"
end

-- データの変化を監視して自動更新
player:GetAttributeChangedSignal("SlotQ"):Connect(updateSlots)
player:GetAttributeChangedSignal("SlotZ"):Connect(updateSlots)

player.CharacterAdded:Connect(function(char)
	updateSlots()
	char.ChildAdded:Connect(updateSlots)
	char.ChildRemoved:Connect(updateSlots)

	local backpack = player:WaitForChild("Backpack")
	backpack.ChildAdded:Connect(updateSlots)
	backpack.ChildRemoved:Connect(updateSlots)
end)

task.spawn(function()
	task.wait(1)
	updateSlots()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	local char = player.Character
	local humanoid = char and char:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	local backpack = player:FindFirstChild("Backpack")

	-- スロット番号から武器を探す便利関数
	local function getToolBySlot(slotNum)
		if char then
			for _, item in ipairs(char:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("Slot") == slotNum then
					return item
				end
			end
		end
		if backpack then
			for _, item in ipairs(backpack:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("Slot") == slotNum then
					return item
				end
			end
		end
		return nil
	end

	-- ★修正: 装備と収納を切り替える（トグルする）処理に賢く変更！
	local function toggleTool(slotNum)
		local tool = getToolBySlot(slotNum)
		if tool then
			if tool.Parent == char then
				-- すでに手に持っている（キャラクターの中にある）場合はしまう
				humanoid:UnequipTools()
			else
				-- そうでなければ装備する
				humanoid:EquipTool(tool)
			end
		end
	end

	-- キー判定
	if input.KeyCode == Enum.KeyCode.Zero then -- ★追加
		toggleTool(0)
	elseif input.KeyCode == Enum.KeyCode.One then
		toggleTool(1)
	elseif input.KeyCode == Enum.KeyCode.Two then
		toggleTool(2)
	end
end)

-- ==========================================
-- ★追加: ロードアウト端末の全画面UIシステム
-- ==========================================
local openLoadoutEvent = ReplicatedStorage:WaitForChild("OpenLoadout", 10)

local loadoutScreen = Instance.new("ScreenGui")
loadoutScreen.Name = "LoadoutScreenGui"
loadoutScreen.ResetOnSpawn = false
loadoutScreen.IgnoreGuiInset = true
loadoutScreen.DisplayOrder = 100
loadoutScreen.Enabled = false
loadoutScreen.Parent = playerGui

local loadoutBg = Instance.new("Frame")
loadoutBg.Size = UDim2.new(1, 0, 1, 0)
loadoutBg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
loadoutBg.BackgroundTransparency = 0.1
loadoutBg.Parent = loadoutScreen

local loadoutTitle = Instance.new("TextLabel")
loadoutTitle.Text = "TERMINAL - SELECT YOUR LOADOUT"
loadoutTitle.Size = UDim2.new(1, 0, 0, 50)
loadoutTitle.Position = UDim2.new(0, 0, 0, 30)
loadoutTitle.BackgroundTransparency = 1
loadoutTitle.TextColor3 = Color3.fromRGB(0, 255, 255)
loadoutTitle.Font = Enum.Font.GothamBlack
loadoutTitle.TextSize = 36
loadoutTitle.Parent = loadoutBg

local closeBtn = Instance.new("TextButton")
closeBtn.Text = "CLOSE"
closeBtn.Size = UDim2.new(0, 200, 0, 50)
closeBtn.Position = UDim2.new(0.5, -100, 1, -180)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.Parent = loadoutBg

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

-- ★追加: HUD側にも表示用の価格表を持たせる
local ITEM_PRICES = {
	["BouncyGun"] = 0,
	["BouncyShotgun"] = 0,
	["BouncySMG"] = 0,
	["BouncyGrenade"] = 500,
	["Energy Shield"] = 0,
	["SpeedBoost"] = 0,
	["HighJump"] = 200,
	["Invisibility"] = 300,
	["Teleport"] = 400,
	["TimeSlow"] = 500,
	["Giant"] = 600,
	["Mini"] = 600,
	["XRay"] = 700,
}

local equipItemEvent = ReplicatedStorage:WaitForChild("EquipItem", 5)

-- リストを作る関数（値段と鍵マーク対応版）
local function createItemList(parent, titleText, posX, items, itemType)
	local title = Instance.new("TextLabel")
	title.Text = titleText
	title.Size = UDim2.new(0.4, 0, 0, 30)
	title.Position = UDim2.new(posX, 0, 0.2, 0)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.Parent = parent

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(0.4, 0, 0.6, 0)
	scroll.Position = UDim2.new(posX, 0, 0.25, 0)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.Parent = parent

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.48, 0, 0, 60)
	grid.CellPadding = UDim2.new(0.04, 0, 0, 15)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = scroll

	for i, itemName in ipairs(items) do
		local btn = Instance.new("TextButton")
		btn.Name = itemName
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		btn.LayoutOrder = i
		btn.Text = ""
		btn.Parent = scroll

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = btn

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(100, 100, 100)
		stroke.Thickness = 1
		stroke.Parent = btn

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
		nameLabel.Position = UDim2.new(0, 0, 0.1, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamMedium
		nameLabel.TextSize = 16
		nameLabel.Text = itemName
		nameLabel.Parent = btn

		local statusLabel = Instance.new("TextLabel")
		statusLabel.Size = UDim2.new(1, 0, 0.4, 0)
		statusLabel.Position = UDim2.new(0, 0, 0.6, 0)
		statusLabel.BackgroundTransparency = 1
		statusLabel.Font = Enum.Font.GothamBold
		statusLabel.TextSize = 12
		statusLabel.Parent = btn

		local price = ITEM_PRICES[itemName] or 0

		-- 状態を更新する関数
		local function updateButtonState()
			local unlockedStr = ""
			if itemType == "Weapon" then
				unlockedStr = player:GetAttribute("UnlockedWeapons") or ""
			else
				unlockedStr = player:GetAttribute("UnlockedSkills") or ""
			end

			local isUnlocked = table.find(string.split(unlockedStr, ","), itemName) ~= nil

			if isUnlocked then
				statusLabel.Text = "UNLOCKED"
				statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
				nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			else
				statusLabel.Text = "🔒 " .. price .. " Coins"
				statusLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
				nameLabel.TextColor3 = Color3.fromRGB(100, 100, 100) -- 未解放は暗くする
			end
		end

		updateButtonState()

		-- アンロック状況が変わったら自動で見た目を更新する
		if itemType == "Weapon" then
			player:GetAttributeChangedSignal("UnlockedWeapons"):Connect(updateButtonState)
		else
			player:GetAttributeChangedSignal("UnlockedSkills"):Connect(updateButtonState)
		end

		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			stroke.Color = Color3.fromRGB(0, 255, 255)
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
			stroke.Color = Color3.fromRGB(100, 100, 100)
		end)

		btn.MouseButton1Click:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(80, 240, 255)
			task.delay(0.1, function()
				btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			end)
			if equipItemEvent then
				equipItemEvent:FireServer(itemType, itemName)
			end
		end)
	end
end

local weapons = { "BouncyGun", "BouncyShotgun", "BouncySMG", "BouncyGrenade" }
createItemList(loadoutBg, "WEAPONS (Slot 1 & 2)", 0.08, weapons, "Weapon")

local skills =
	{ "Energy Shield", "HighJump", "SpeedBoost", "Invisibility", "Teleport", "TimeSlow", "Giant", "Mini", "XRay" }
createItemList(loadoutBg, "ABILITIES (Slot Q & Z)", 0.52, skills, "Skill")

if openLoadoutEvent then
	openLoadoutEvent.OnClientEvent:Connect(function()
		loadoutScreen.Enabled = true
		local char = player.Character
		local hum = char and char:FindFirstChild("Humanoid")
		if hum then
			hum:UnequipTools()
		end
	end)
end

closeBtn.MouseButton1Click:Connect(function()
	loadoutScreen.Enabled = false
end)

-- ==========================================
-- ゲームの進行メッセージ（カウントダウン等）
-- ==========================================
local gameMessageEvent = ReplicatedStorage:WaitForChild("GameMessage", 5)

local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "GameMessageLabel"
messageLabel.Size = UDim2.new(1, 0, 0, 80)
messageLabel.Position = UDim2.new(0, 0, 0.15, 0)
messageLabel.BackgroundTransparency = 1
messageLabel.Font = Enum.Font.GothamBlack
messageLabel.TextSize = 40
messageLabel.Text = ""
messageLabel.TextColor3 = Color3.new(1, 1, 1)
messageLabel.TextStrokeTransparency = 0
messageLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
messageLabel.Parent = loadoutGui

if gameMessageEvent then
	gameMessageEvent.OnClientEvent:Connect(function(text, color)
		messageLabel.Text = text
		if color then
			messageLabel.TextColor3 = color
		end

		messageLabel.TextSize = 50
		local TweenService = game:GetService("TweenService")
		TweenService:Create(messageLabel, TweenInfo.new(0.3, Enum.EasingStyle.Bounce), { TextSize = 40 }):Play()
	end)
end

-- ==========================================
-- ★追加: 失われたHUD（コイン、ラウンド情報、体力、弾薬）の完全復活
-- ==========================================
local RunService = game:GetService("RunService")

-- 1. コイン表示（右上）
local coinFrame = Instance.new("Frame")
coinFrame.Size = UDim2.new(0, 150, 0, 40)
coinFrame.Position = UDim2.new(1, -170, 0, 20)
coinFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
coinFrame.BackgroundTransparency = 0.5
coinFrame.Parent = loadoutGui

local coinCorner = Instance.new("UICorner")
coinCorner.CornerRadius = UDim.new(0, 8)
coinCorner.Parent = coinFrame

local coinStroke = Instance.new("UIStroke")
coinStroke.Color = Color3.fromRGB(255, 200, 50)
coinStroke.Thickness = 2
coinStroke.Parent = coinFrame

local coinLabel = Instance.new("TextLabel")
coinLabel.Size = UDim2.new(1, 0, 1, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.Text = "💰 0"
coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinLabel.Font = Enum.Font.GothamBold
coinLabel.TextSize = 20
coinLabel.Parent = coinFrame

task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if leaderstats then
		local coins = leaderstats:WaitForChild("Coins", 5)
		if coins then
			coinLabel.Text = "💰 " .. tostring(coins.Value)
			coins.Changed:Connect(function(val)
				coinLabel.Text = "💰 " .. tostring(val)
				local TweenService = game:GetService("TweenService")
				coinLabel.TextSize = 30
				TweenService:Create(coinLabel, TweenInfo.new(0.3, Enum.EasingStyle.Bounce), { TextSize = 20 }):Play()
			end)
		end
	end
end)

-- 2. ラウンド情報とスコア（上部中央）
local roundLabel = Instance.new("TextLabel")
roundLabel.Size = UDim2.new(0, 300, 0, 40)
roundLabel.Position = UDim2.new(0.5, -150, 0, 20)
roundLabel.BackgroundTransparency = 1
roundLabel.Text = ""
roundLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
roundLabel.Font = Enum.Font.GothamBlack
roundLabel.TextSize = 24
roundLabel.TextStrokeTransparency = 0
roundLabel.Parent = loadoutGui

-- ★追加: 5回勝利（キル）の進捗スコア表示
local scoreLabel = Instance.new("TextLabel")
scoreLabel.Size = UDim2.new(0, 300, 0, 30)
scoreLabel.Position = UDim2.new(0.5, -150, 0, 60) -- タイマーのすぐ下に配置
scoreLabel.BackgroundTransparency = 1
scoreLabel.Text = ""
scoreLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
scoreLabel.Font = Enum.Font.GothamBold
scoreLabel.TextSize = 20
scoreLabel.TextStrokeTransparency = 0
scoreLabel.Parent = loadoutGui

local roundStatus = ReplicatedStorage:WaitForChild("RoundStatus", 5)
if roundStatus then
	local function updateVisibility(val)
		if val == "LOBBY" or val == "" then
			roundLabel.Text = ""
			scoreLabel.Visible = false -- ロビーではスコアを隠す
		else
			roundLabel.Text = val
			scoreLabel.Visible = true -- 試合中はスコアを表示
		end
	end

	updateVisibility(roundStatus.Value)
	roundStatus.Changed:Connect(updateVisibility)
end

-- キル数（スコア）を監視して表示を更新する
task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if leaderstats then
		local kills = leaderstats:WaitForChild("Kills", 5)
		if kills then
			scoreLabel.Text = "SCORE: " .. kills.Value .. " / 5"
			kills.Changed:Connect(function(val)
				scoreLabel.Text = "SCORE: " .. val .. " / 5"
			end)
		end
	end
end)

-- 3. 体力ゲージ（左下）
local healthFrame = Instance.new("Frame")
healthFrame.Size = UDim2.new(0, 300, 0, 25)
healthFrame.Position = UDim2.new(0, 40, 1, -60)
healthFrame.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
healthFrame.BackgroundTransparency = 0.2
healthFrame.Parent = loadoutGui

local healthCorner = Instance.new("UICorner")
healthCorner.CornerRadius = UDim.new(0, 6)
healthCorner.Parent = healthFrame

local healthBar = Instance.new("Frame")
healthBar.Size = UDim2.new(1, 0, 1, 0)
healthBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
healthBar.Parent = healthFrame

local healthBarCorner = Instance.new("UICorner")
healthBarCorner.CornerRadius = UDim.new(0, 6)
healthBarCorner.Parent = healthBar

local healthLabel = Instance.new("TextLabel")
healthLabel.Size = UDim2.new(1, 0, 1, 0)
healthLabel.BackgroundTransparency = 1
healthLabel.Text = "HP: 100 / 100"
healthLabel.TextColor3 = Color3.new(1, 1, 1)
healthLabel.Font = Enum.Font.GothamBold
healthLabel.TextSize = 16
healthLabel.TextStrokeTransparency = 0
healthLabel.Parent = healthFrame

-- 4. 弾薬表示（右下）
local ammoLabel = Instance.new("TextLabel")
ammoLabel.Size = UDim2.new(0, 150, 0, 50)
ammoLabel.Position = UDim2.new(1, -190, 1, -80)
ammoLabel.BackgroundTransparency = 1
ammoLabel.Text = ""
ammoLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
ammoLabel.Font = Enum.Font.GothamBlack
ammoLabel.TextSize = 36
ammoLabel.TextXAlignment = Enum.TextXAlignment.Right
ammoLabel.TextStrokeTransparency = 0
ammoLabel.Parent = loadoutGui

-- 毎フレームの更新処理（体力と弾薬）
RunService.RenderStepped:Connect(function()
	local char = player.Character
	local humanoid = char and char:FindFirstChild("Humanoid")

	-- 体力の更新
	if humanoid then
		local hp = humanoid.Health
		local maxHp = humanoid.MaxHealth
		healthLabel.Text = "HP: " .. math.floor(hp) .. " / " .. math.floor(maxHp)
		healthBar.Size = UDim2.new(math.clamp(hp / maxHp, 0, 1), 0, 1, 0)

		if hp / maxHp <= 0.3 then
			healthBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		else
			healthBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
		end
		healthFrame.Visible = true
	else
		healthFrame.Visible = false
	end

	-- 弾薬の更新
	local equippedTool = char and char:FindFirstChildOfClass("Tool")
	-- ★修正: 武器（Bouncy〜）を持っている時だけ、キャラクター(char)の「Ammo」を見るように変更！
	if equippedTool and equippedTool.Name:match("Bouncy") then
		local current = char:GetAttribute("Ammo")
		local maxAmmo = char:GetAttribute("MaxAmmo")

		if current and maxAmmo then
			ammoLabel.Text = current .. " / " .. maxAmmo
			if current <= maxAmmo * 0.2 then
				ammoLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- 残り20%で赤くなる
			else
				ammoLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
			end
		else
			ammoLabel.Text = ""
		end
	else
		ammoLabel.Text = ""
	end
end)
