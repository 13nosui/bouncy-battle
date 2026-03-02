-- src/client/HUD.client.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
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
