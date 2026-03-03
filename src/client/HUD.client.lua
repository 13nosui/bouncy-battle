-- src/client/HUD.client.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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
local slotWeapon1 = createSlot("Slot_Weapon1", "1", 1)
local slotWeapon2 = createSlot("Slot_Weapon2", "2", 2)
local slotAbilityQ = createSlot("Slot_AbilityQ", "Q", 3)
local slotAbilityZ = createSlot("Slot_AbilityZ", "Z", 4)

-- スロットの文字を最新の状態に書き換える関数
local function updateSlots()
	local tool1, tool2
	local backpack = player:FindFirstChild("Backpack")
	local char = player.Character

	-- スロット番号の目印を見て、どちらの枠に入る武器か判定する
	local function checkTools(parent)
		if not parent then
			return
		end
		for _, item in ipairs(parent:GetChildren()) do
			if item:IsA("Tool") then
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

	-- キー判定
	if input.KeyCode == Enum.KeyCode.One then
		local tool = getToolBySlot(1)
		if tool then
			humanoid:EquipTool(tool)
		end
	elseif input.KeyCode == Enum.KeyCode.Two then
		local tool = getToolBySlot(2)
		if tool then
			humanoid:EquipTool(tool)
		end
	end
end)

-- ==========================================
-- ★追加: ロードアウト端末の全画面UIシステム
-- ==========================================
local openLoadoutEvent = ReplicatedStorage:WaitForChild("OpenLoadout", 10)

-- 全画面UIの土台
local loadoutScreen = Instance.new("ScreenGui")
loadoutScreen.Name = "LoadoutScreenGui"
loadoutScreen.ResetOnSpawn = false
loadoutScreen.IgnoreGuiInset = true
loadoutScreen.DisplayOrder = 100 -- ★他のUIより絶対に上に表示させる
loadoutScreen.Enabled = false -- 最初は隠す
loadoutScreen.Parent = playerGui

-- 黒い半透明の背景
local loadoutBg = Instance.new("Frame")
loadoutBg.Size = UDim2.new(1, 0, 1, 0)
loadoutBg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
loadoutBg.BackgroundTransparency = 0.1
loadoutBg.Parent = loadoutScreen

-- タイトル文字
local loadoutTitle = Instance.new("TextLabel")
loadoutTitle.Text = "TERMINAL - SELECT YOUR LOADOUT"
loadoutTitle.Size = UDim2.new(1, 0, 0, 50)
loadoutTitle.Position = UDim2.new(0, 0, 0, 30)
loadoutTitle.BackgroundTransparency = 1
loadoutTitle.TextColor3 = Color3.fromRGB(0, 255, 255)
loadoutTitle.Font = Enum.Font.GothamBlack
loadoutTitle.TextSize = 36
loadoutTitle.Parent = loadoutBg

-- 閉じるボタン
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

-- ==========================================
-- ★追加: 武器とスキルの選択リストを作成
-- ==========================================
local equipItemEvent = ReplicatedStorage:WaitForChild("EquipItem", 5)
if not equipItemEvent then
	equipItemEvent = Instance.new("RemoteEvent")
	equipItemEvent.Name = "EquipItem"
	equipItemEvent.Parent = ReplicatedStorage
end

-- リストを作るための便利関数
local function createItemList(parent, titleText, posX, items, itemType)
	-- タイトル
	local title = Instance.new("TextLabel")
	title.Text = titleText
	title.Size = UDim2.new(0.4, 0, 0, 30)
	title.Position = UDim2.new(posX, 0, 0.2, 0)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.Parent = parent

	-- リストの枠（スクロール可能にする）
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(0.4, 0, 0.6, 0)
	scroll.Position = UDim2.new(posX, 0, 0.25, 0)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.Parent = parent

	-- グリッドレイアウト（綺麗に並べる）
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.48, 0, 0, 60)
	grid.CellPadding = UDim2.new(0.04, 0, 0, 15)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = scroll

	-- 各アイテムのボタンを生成
	for i, itemName in ipairs(items) do
		local btn = Instance.new("TextButton")
		btn.Name = itemName
		btn.Text = itemName
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		btn.TextColor3 = Color3.fromRGB(200, 200, 200)
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 16
		btn.LayoutOrder = i
		btn.Parent = scroll

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = btn

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(100, 100, 100)
		stroke.Thickness = 1
		stroke.Parent = btn

		-- マウスを乗せた時のエフェクト
		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			stroke.Color = Color3.fromRGB(0, 255, 255)
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
			stroke.Color = Color3.fromRGB(100, 100, 100)
		end)

		-- ★クリックされたらサーバーに「装備して！」とリクエストを送る
		btn.MouseButton1Click:Connect(function()
			-- クリックエフェクト
			btn.BackgroundColor3 = Color3.fromRGB(80, 240, 255)
			btn.TextColor3 = Color3.new(0, 0, 0)
			task.delay(0.1, function()
				btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
				btn.TextColor3 = Color3.fromRGB(200, 200, 200)
			end)

			if equipItemEvent then
				equipItemEvent:FireServer(itemType, itemName)
			end
		end)
	end
end

-- 左側に武器リストを配置 (X座標: 0.08)
local weapons = { "BouncyGun", "BouncyShotgun", "BouncySMG", "BouncyGrenade" }
createItemList(loadoutBg, "WEAPONS (Slot 1 & 2)", 0.08, weapons, "Weapon")

-- 右側にスキルリストを配置 (X座標: 0.52)
local skills =
	{ "Energy Shield", "HighJump", "SpeedBoost", "Invisibility", "Teleport", "TimeSlow", "Giant", "Mini", "XRay" }
createItemList(loadoutBg, "ABILITIES (Slot Q & Z)", 0.52, skills, "Skill")

-- サーバーから「開け」と命令が来たら表示
local openLoadoutEvent = ReplicatedStorage:WaitForChild("OpenLoadout", 5)
if openLoadoutEvent then
	openLoadoutEvent.OnClientEvent:Connect(function()
		loadoutScreen.Enabled = true

		-- ★追加: 端末を開いた瞬間、強制的に武器をしまってマウスのロックを解除する
		local char = player.Character
		local hum = char and char:FindFirstChild("Humanoid")
		if hum then
			hum:UnequipTools()
		end
	end)
end

-- 閉じるボタンを押した時の処理
closeBtn.MouseButton1Click:Connect(function()
	loadoutScreen.Enabled = false
end)
