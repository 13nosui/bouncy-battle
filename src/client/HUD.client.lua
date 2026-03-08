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

local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0, 400, 0, 80)
container.BackgroundTransparency = 1
container.Parent = loadoutGui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = container

-- ★ スマホ対応: タッチデバイスなら右上（コインの左隣）、PCなら下部中央に配置
if UserInputService.TouchEnabled then
	-- コイン表示（幅150）と被らないよう、右から少し離した位置に配置
	container.Position = UDim2.new(1, -200, 0, 15)
	container.AnchorPoint = Vector2.new(1, 0)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Padding = UDim.new(0, 8)
else
	container.Position = UDim2.new(0.5, -200, 1, -100)
	container.AnchorPoint = Vector2.new(0, 0)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 12)
end

-- ==========================================
-- 武器を切り替える共通関数
-- ==========================================
local function toggleTool(slotNum)
	local char = player.Character
	local humanoid = char and char:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	local backpack = player:FindFirstChild("Backpack")

	local function getToolBySlot(sNum)
		if char then
			for _, item in ipairs(char:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("Slot") == sNum then
					return item
				end
			end
		end
		if backpack then
			for _, item in ipairs(backpack:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("Slot") == sNum then
					return item
				end
			end
		end
		return nil
	end

	local tool = getToolBySlot(slotNum)
	if tool then
		if tool.Parent == char then
			humanoid:UnequipTools()
		else
			humanoid:EquipTool(tool)
		end
	end
end

-- スロットを生成する関数
local function createSlot(slotName, keybindStr, layoutOrder)
	local slot = Instance.new("TextButton")
	slot.Name = slotName
	local slotSize = UserInputService.TouchEnabled and 65 or 80
	slot.Size = UDim2.new(0, slotSize, 0, slotSize)
	slot.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	slot.BackgroundTransparency = 0.4
	slot.Text = ""
	slot.AutoButtonColor = false
	slot.LayoutOrder = layoutOrder
	slot.Parent = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = slot

	local stroke = Instance.new("UIStroke")
	stroke.Name = "Highlight"
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.8
	stroke.Thickness = 2
	stroke.Parent = slot

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

	local itemLabel = Instance.new("TextLabel")
	itemLabel.Name = "ItemName"
	itemLabel.Size = UDim2.new(1, -10, 1, -10)
	itemLabel.Position = UDim2.new(0, 5, 0, 5)
	itemLabel.BackgroundTransparency = 1
	itemLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	itemLabel.Font = Enum.Font.GothamMedium
	itemLabel.Text = "Empty"
	itemLabel.TextSize = UserInputService.TouchEnabled and 10 or 12
	itemLabel.TextWrapped = true
	itemLabel.Parent = slot

	-- スマホでタップされた時の処理（武器スロットのみ）
	if layoutOrder <= 2 then
		slot.MouseButton1Click:Connect(function()
			toggleTool(layoutOrder)
		end)
	end

	return slot
end

local slotWeapon0 = createSlot("Slot_Weapon0", "0", 0)
slotWeapon0.Visible = false

local slotWeapon1 = createSlot("Slot_Weapon1", "1", 1)
local slotWeapon2 = createSlot("Slot_Weapon2", "2", 2)
local slotAbilityQ = createSlot("Slot_AbilityQ", "3", 3)
local slotAbilityZ = createSlot("Slot_AbilityZ", "4", 4)

local function updateSlots()
	local tool0, tool1, tool2
	local backpack = player:FindFirstChild("Backpack")
	local char = player.Character

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

	slotWeapon0.ItemName.Text = tool0 and tool0.Name or "Empty"
	slotWeapon0.Visible = (tool0 ~= nil)

	slotWeapon1.ItemName.Text = tool1 and tool1.Name or "Empty"
	slotWeapon2.ItemName.Text = tool2 and tool2.Name or "Empty"

	local equippedTool = char and char:FindFirstChildOfClass("Tool")

	local function setHighlight(slot, tool)
		if tool and equippedTool == tool then
			slot.Highlight.Transparency = 0
			slot.Highlight.Color = Color3.fromRGB(0, 255, 255)
		else
			slot.Highlight.Transparency = 0.8
			slot.Highlight.Color = Color3.fromRGB(255, 255, 255)
		end
	end

	setHighlight(slotWeapon0, tool0)
	setHighlight(slotWeapon1, tool1)
	setHighlight(slotWeapon2, tool2)

	local sq = player:GetAttribute("SlotQ")
	slotAbilityQ.ItemName.Text = (sq and sq ~= "") and sq or "Empty"

	local sz = player:GetAttribute("SlotZ")
	slotAbilityZ.ItemName.Text = (sz and sz ~= "") and sz or "Empty"
end

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

-- PCのキーボード用切り替え
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Zero then
		toggleTool(0)
	elseif input.KeyCode == Enum.KeyCode.One then
		toggleTool(1)
	elseif input.KeyCode == Enum.KeyCode.Two then
		toggleTool(2)
	end
end)

-- ==========================================
-- ロードアウト端末の全画面UIシステム
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
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

local shopFrame = Instance.new("Frame")
shopFrame.Size = UDim2.new(1, 0, 0, 60)
shopFrame.Position = UDim2.new(0, 0, 1, -80)
shopFrame.BackgroundTransparency = 1
shopFrame.Parent = loadoutBg

local buyVipBtn = Instance.new("TextButton")
buyVipBtn.Text = "🌟 BUY VIP PASS (x2 COINS)"
buyVipBtn.Size = UDim2.new(0, 300, 1, 0)
buyVipBtn.Position = UDim2.new(0.5, -350, 0, 0)
buyVipBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
buyVipBtn.TextColor3 = Color3.new(0, 0, 0)
buyVipBtn.Font = Enum.Font.GothamBold
buyVipBtn.TextSize = 18
buyVipBtn.Parent = shopFrame
Instance.new("UICorner", buyVipBtn).CornerRadius = UDim.new(0, 8)

local buyCoinBtn = Instance.new("TextButton")
buyCoinBtn.Text = "💰 BUY 500 COINS"
buyCoinBtn.Size = UDim2.new(0, 300, 1, 0)
buyCoinBtn.Position = UDim2.new(0.5, 50, 0, 0)
buyCoinBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
buyCoinBtn.TextColor3 = Color3.new(0, 0, 0)
buyCoinBtn.Font = Enum.Font.GothamBold
buyCoinBtn.TextSize = 18
buyCoinBtn.Parent = shopFrame
Instance.new("UICorner", buyCoinBtn).CornerRadius = UDim.new(0, 8)

local purchaseEvent = ReplicatedStorage:WaitForChild("PurchaseEvent", 5)
buyVipBtn.MouseButton1Click:Connect(function()
	if purchaseEvent then
		purchaseEvent:FireServer("VIP")
	end
end)
buyCoinBtn.MouseButton1Click:Connect(function()
	if purchaseEvent then
		purchaseEvent:FireServer("Coin")
	end
end)

local ITEM_PRICES = {
	["BouncyGun"] = 0,
	["BouncyShotgun"] = 0,
	["BouncySMG"] = 0,
	["BouncyGrenade"] = 500,
	["BouncySniper"] = 800,
	["BouncyAssaultRifle"] = 600,
	["Energy Shield"] = 0,
	["SpeedBoost"] = 0,
	["HighJump"] = 200,
	["DoubleJump"] = 300,
	["TripleJump"] = 500,
	["QuadJump"] = 800,
	["Invisibility"] = 300,
	["Teleport"] = 400,
	["TimeSlow"] = 500,
	["Giant"] = 600,
	["Mini"] = 600,
	["XRay"] = 700,
}

local ITEM_UNLOCK_LEVELS = {
	["BouncyAssaultRifle"] = 2,
	["DoubleJump"] = 2,
	["BouncySniper"] = 3,
	["TripleJump"] = 5,
	["Giant"] = 7,
	["Mini"] = 7,
	["QuadJump"] = 10,
	["XRay"] = 15,
}

local equipItemEvent = ReplicatedStorage:WaitForChild("EquipItem", 5)

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

		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

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

		local function updateButtonState()
			local unlockedStr = itemType == "Weapon" and (player:GetAttribute("UnlockedWeapons") or "")
				or (player:GetAttribute("UnlockedSkills") or "")
			local isUnlocked = table.find(string.split(unlockedStr, ","), itemName) ~= nil

			local stats = player:FindFirstChild("leaderstats")
			local myLevel = stats and stats:FindFirstChild("Level") and stats.Level.Value or 1
			local reqLevel = ITEM_UNLOCK_LEVELS[itemName] or 1

			if myLevel < reqLevel then
				statusLabel.Text = "🔒 Lv." .. reqLevel .. " REQUIRED"
				statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
				nameLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
			else
				if isUnlocked then
					statusLabel.Text = "UNLOCKED"
					statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
					nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
				else
					statusLabel.Text = "🔒 " .. price .. " Coins"
					statusLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
					nameLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
				end
			end
		end

		updateButtonState()

		if itemType == "Weapon" then
			player:GetAttributeChangedSignal("UnlockedWeapons"):Connect(updateButtonState)
		else
			player:GetAttributeChangedSignal("UnlockedSkills"):Connect(updateButtonState)
		end

		task.spawn(function()
			local stats = player:WaitForChild("leaderstats", 10)
			if stats then
				local levelObj = stats:WaitForChild("Level", 5)
				if levelObj then
					levelObj.Changed:Connect(updateButtonState)
				end
			end
		end)

		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			stroke.Color = Color3.fromRGB(0, 255, 255)
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
			stroke.Color = Color3.fromRGB(100, 100, 100)
		end)

		btn.MouseButton1Click:Connect(function()
			local stats = player:FindFirstChild("leaderstats")
			local myLevel = stats and stats:FindFirstChild("Level") and stats.Level.Value or 1
			local reqLevel = ITEM_UNLOCK_LEVELS[itemName] or 1

			if myLevel < reqLevel then
				return
			end

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

local weapons = { "BouncyGun", "BouncyShotgun", "BouncySMG", "BouncyGrenade", "BouncySniper", "BouncyAssaultRifle" }
createItemList(loadoutBg, "WEAPONS (Slot 1 & 2)", 0.08, weapons, "Weapon")

local skills = {
	"Energy Shield",
	"HighJump",
	"DoubleJump",
	"TripleJump",
	"QuadJump",
	"SpeedBoost",
	"Invisibility",
	"Teleport",
	"TimeSlow",
	"Giant",
	"Mini",
	"XRay",
}
createItemList(loadoutBg, "ABILITIES (Slot 3 & 4)", 0.52, skills, "Skill")

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
-- ゲームの進行メッセージ
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
-- HUDの各要素
-- ==========================================
local RunService = game:GetService("RunService")

-- ★修正: 1. コイン表示（画面右上へ）
local coinFrame = Instance.new("Frame")
coinFrame.Size = UDim2.new(0, 150, 0, 40)
coinFrame.AnchorPoint = Vector2.new(1, 0) -- 右上を基準にする
coinFrame.Position = UDim2.new(1, -20, 0, 20) -- 右から20px、上から20pxに配置
coinFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
coinFrame.BackgroundTransparency = 0.5
coinFrame.Parent = loadoutGui
Instance.new("UICorner", coinFrame).CornerRadius = UDim.new(0, 8)

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

-- 2. RIVALS風 対戦スコアボード（画面上部中央）
local topScoreContainer = Instance.new("Frame")
topScoreContainer.Size = UDim2.new(1, 0, 0, 80)
topScoreContainer.Position = UDim2.new(0, 0, 0, 15)
topScoreContainer.BackgroundTransparency = 1
topScoreContainer.Visible = false
topScoreContainer.Parent = loadoutGui

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(0, 100, 0, 36)
timerLabel.Position = UDim2.new(0.5, 0, 0, 10)
timerLabel.AnchorPoint = Vector2.new(0.5, 0)
timerLabel.BackgroundTransparency = 0.3
timerLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.Font = Enum.Font.GothamBlack
timerLabel.TextSize = 20
timerLabel.Parent = topScoreContainer
Instance.new("UICorner", timerLabel).CornerRadius = UDim.new(0, 8)
local timerStroke = Instance.new("UIStroke", timerLabel)
timerStroke.Color = Color3.fromRGB(80, 80, 80)

local function createPlayerCard(isLeft)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 200, 0, 56)
	card.AnchorPoint = isLeft and Vector2.new(1, 0) or Vector2.new(0, 0)
	card.Position = UDim2.new(0.5, isLeft and -70 or 70, 0, 0)
	card.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	card.BackgroundTransparency = 0.2
	card.Parent = topScoreContainer
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 28)

	local stroke = Instance.new("UIStroke", card)
	stroke.Color = isLeft and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(255, 50, 50)
	stroke.Thickness = 2

	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(0, 48, 0, 48)
	avatar.AnchorPoint = isLeft and Vector2.new(0, 0.5) or Vector2.new(1, 0.5)
	avatar.Position = UDim2.new(isLeft and 0 or 1, isLeft and 4 or -4, 0.5, 0)
	avatar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	avatar.Parent = card
	Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(0, 60, 0, 24)
	infoLabel.AnchorPoint = isLeft and Vector2.new(0, 0.5) or Vector2.new(1, 0.5)
	infoLabel.Position = UDim2.new(isLeft and 0 or 1, isLeft and 60 or -60, 0.5, 0)
	infoLabel.BackgroundTransparency = 1
	infoLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	infoLabel.Font = Enum.Font.GothamBold
	infoLabel.TextSize = 16
	infoLabel.TextXAlignment = isLeft and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
	infoLabel.Parent = card

	local scoreLabel = Instance.new("TextLabel")
	scoreLabel.Size = UDim2.new(0, 60, 0, 36)
	scoreLabel.AnchorPoint = isLeft and Vector2.new(1, 0.5) or Vector2.new(0, 0.5)
	scoreLabel.Position = UDim2.new(isLeft and 1 or 0, isLeft and -20 or 20, 0.5, 0)
	scoreLabel.BackgroundTransparency = 1
	scoreLabel.TextColor3 = Color3.new(1, 1, 1)
	scoreLabel.Font = Enum.Font.GothamBlack
	scoreLabel.TextSize = 36
	scoreLabel.Text = "0"
	scoreLabel.TextStrokeTransparency = 0
	scoreLabel.TextXAlignment = isLeft and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
	scoreLabel.Parent = card

	return { Card = card, Avatar = avatar, Info = infoLabel, Score = scoreLabel }
end

local myCard = createPlayerCard(true)
local rivalCard = createPlayerCard(false)

local roundStatus = ReplicatedStorage:WaitForChild("RoundStatus", 5)
local lastRivalId = nil

local function updateMatchScoreUI()
	if not roundStatus then
		return
	end
	local status = roundStatus.Value

	if status == "LOBBY" or status == "" or string.match(status, "BUILD") then
		topScoreContainer.Visible = false
		return
	end

	topScoreContainer.Visible = true

	local timeStr = status:match("%d+:%d+")
	timerLabel.Text = timeStr or "VS"

	local myStats = player:FindFirstChild("leaderstats")
	local myKills = myStats and myStats:FindFirstChild("Kills") and myStats.Kills.Value or 0
	local myLevel = myStats and myStats:FindFirstChild("Level") and myStats.Level.Value or 1

	myCard.Info.Text = "Lv." .. myLevel
	myCard.Score.Text = tostring(myKills)

	local success, myContent = pcall(function()
		return Players:GetUserThumbnailAsync(
			player.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailResolution.Size150x150
		)
	end)
	myCard.Avatar.Image = success and myContent or "rbxasset://textures/ui/GuiImagePlaceholder.png"

	local myTeam = player.Team
	local bestRival = nil
	local maxKills = -1

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			if not myTeam or p.Team ~= myTeam then
				local stats = p:FindFirstChild("leaderstats")
				if stats then
					local kills = stats:FindFirstChild("Kills")
					if kills and kills.Value > maxKills then
						maxKills = kills.Value
						bestRival = p
					end
				end
			end
		end
	end

	local isBot = false
	if not bestRival then
		for _, child in ipairs(workspace:GetChildren()) do
			if child:IsA("Model") and child:FindFirstChild("Humanoid") and child.Name == "Dummy" then
				bestRival = child
				isBot = true
				break
			end
		end
	end

	if bestRival then
		if isBot then
			rivalCard.Info.Text = "Lv.1"
			rivalCard.Score.Text = "0"
			rivalCard.Avatar.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
		else
			local rStats = bestRival:FindFirstChild("leaderstats")
			local rKills = rStats and rStats:FindFirstChild("Kills") and rStats.Kills.Value or 0
			local rLevel = rStats and rStats:FindFirstChild("Level") and rStats.Level.Value or 1

			rivalCard.Info.Text = "Lv." .. rLevel
			rivalCard.Score.Text = tostring(rKills)

			if lastRivalId ~= bestRival.UserId then
				lastRivalId = bestRival.UserId
				local rSuccess, rContent = pcall(function()
					return Players:GetUserThumbnailAsync(
						bestRival.UserId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailResolution.Size150x150
					)
				end)
				rivalCard.Avatar.Image = rSuccess and rContent or "rbxasset://textures/ui/GuiImagePlaceholder.png"
			end
		end
		rivalCard.Card.Visible = true
	else
		rivalCard.Card.Visible = false
	end
end

task.spawn(function()
	while true do
		pcall(updateMatchScoreUI)
		task.wait(0.5)
	end
end)

-- 3. 体力ゲージ（左下）
local healthFrame = Instance.new("Frame")
healthFrame.Size = UDim2.new(0, 300, 0, 25)
healthFrame.Position = UDim2.new(0, 40, 1, -60)
healthFrame.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
healthFrame.BackgroundTransparency = 0.2
healthFrame.Parent = loadoutGui
Instance.new("UICorner", healthFrame).CornerRadius = UDim.new(0, 6)

local healthBar = Instance.new("Frame")
healthBar.Size = UDim2.new(1, 0, 1, 0)
healthBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
healthBar.Parent = healthFrame
Instance.new("UICorner", healthBar).CornerRadius = UDim.new(0, 6)

local healthLabel = Instance.new("TextLabel")
healthLabel.Size = UDim2.new(1, 0, 1, 0)
healthLabel.BackgroundTransparency = 1
healthLabel.Text = "HP: 100 / 100"
healthLabel.TextColor3 = Color3.new(1, 1, 1)
healthLabel.Font = Enum.Font.GothamBold
healthLabel.TextSize = 16
healthLabel.TextStrokeTransparency = 0
healthLabel.Parent = healthFrame

-- 4. 弾薬表示（スマホの場合は右上武器スロットの下、PCは右下）
local ammoLabel = Instance.new("TextLabel")
ammoLabel.Size = UDim2.new(0, 150, 0, 50)
if UserInputService.TouchEnabled then
	ammoLabel.Position = UDim2.new(1, -190, 0, 100)
else
	ammoLabel.Position = UDim2.new(1, -190, 1, -80)
end
ammoLabel.BackgroundTransparency = 1
ammoLabel.Text = ""
ammoLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
ammoLabel.Font = Enum.Font.GothamBlack
ammoLabel.TextSize = 36
ammoLabel.TextXAlignment = Enum.TextXAlignment.Right
ammoLabel.TextStrokeTransparency = 0
ammoLabel.Parent = loadoutGui

RunService.RenderStepped:Connect(function()
	local char = player.Character
	local humanoid = char and char:FindFirstChild("Humanoid")

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

	local equippedTool = char and char:FindFirstChildOfClass("Tool")
	if equippedTool and equippedTool.Name:match("Bouncy") then
		local current = char:GetAttribute("Ammo")
		local maxAmmo = char:GetAttribute("MaxAmmo")

		if current and maxAmmo then
			ammoLabel.Text = current .. " / " .. maxAmmo
			if current <= maxAmmo * 0.2 then
				ammoLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
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

if loadoutGui then
	loadoutGui.Enabled = player:GetAttribute("IsReady") == true
	player:GetAttributeChangedSignal("IsReady"):Connect(function()
		loadoutGui.Enabled = player:GetAttribute("IsReady") == true
	end)
end

local killEffectEvent = ReplicatedStorage:WaitForChild("KillEffectEvent", 5)
local killLabel = Instance.new("TextLabel")
killLabel.Size = UDim2.new(0, 300, 0, 100)
killLabel.Position = UDim2.new(0.5, 0, 0.6, 0)
killLabel.AnchorPoint = Vector2.new(0.5, 0.5)
killLabel.BackgroundTransparency = 1
killLabel.Text = "💀 KILL!"
killLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
killLabel.Font = Enum.Font.GothamBlack
killLabel.TextSize = 0
killLabel.TextStrokeTransparency = 0
killLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
killLabel.Visible = false
killLabel.Parent = loadoutGui

if killEffectEvent then
	killEffectEvent.OnClientEvent:Connect(function()
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://106653932643486"
		sound.Volume = 2.0
		sound.Pitch = 1.5
		sound.Parent = workspace
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 2)

		killLabel.Visible = true
		killLabel.TextSize = 80
		killLabel.Position = UDim2.new(0.5, 0, 0.6, 0)
		killLabel.TextTransparency = 0
		killLabel.TextStrokeTransparency = 0

		local TweenService = game:GetService("TweenService")
		local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local goal = {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
			TextSize = 40,
		}

		local tween = TweenService:Create(killLabel, tweenInfo, goal)
		tween:Play()
		tween.Completed:Connect(function()
			killLabel.Visible = false
		end)
	end)
end

-- ==========================================
-- マップ投票UI
-- ==========================================
local mapVoteEvent = ReplicatedStorage:WaitForChild("MapVoteEvent", 5)

if mapVoteEvent then
	local voteGui = Instance.new("ScreenGui")
	voteGui.Name = "MapVoteGui"
	voteGui.ResetOnSpawn = false
	voteGui.IgnoreGuiInset = true
	voteGui.Parent = playerGui

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	bg.BackgroundTransparency = 0.2
	bg.Visible = false
	bg.Parent = voteGui

	local blur = Instance.new("BlurEffect")
	blur.Size = 0
	blur.Parent = game.Lighting

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 80)
	title.Position = UDim2.new(0, 0, 0.1, 0)
	title.BackgroundTransparency = 1
	title.Text = "VOTE FOR NEXT MAP"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 50
	title.Parent = bg

	local container = Instance.new("ScrollingFrame")
	container.Size = UDim2.new(0.8, 0, 0.6, 0)
	container.Position = UDim2.new(0.1, 0, 0.25, 0)
	container.BackgroundTransparency = 1
	container.ScrollBarThickness = 12
	container.ScrollBarImageColor3 = Color3.fromRGB(80, 240, 255)
	container.AutomaticCanvasSize = Enum.AutomaticSize.Y
	container.CanvasSize = UDim2.new(0, 0, 0, 0)
	container.Parent = bg

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 30)
	padding.Parent = container

	local layout2 = Instance.new("UIGridLayout")
	layout2.CellSize = UDim2.new(0, 260, 0, 340)
	layout2.CellPadding = UDim2.new(0, 30, 0, 30)
	layout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout2.SortOrder = Enum.SortOrder.LayoutOrder
	layout2.Parent = container

	local optionBtns = {}

	mapVoteEvent.OnClientEvent:Connect(function(action, data)
		if action == "Start" then
			for _, btn in ipairs(optionBtns) do
				btn:Destroy()
			end
			table.clear(optionBtns)

			blur.Size = 20
			bg.Visible = true

			for i, mapInfo in ipairs(data) do
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(0, 260, 0, 340)
				btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
				btn.BorderSizePixel = 4
				btn.BorderColor3 = Color3.fromRGB(60, 60, 70)
				btn.Text = ""
				btn.AutoButtonColor = false
				btn.Parent = container

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(1, -20, 0.6, 0)
				nameLabel.Position = UDim2.new(0, 10, 0, 20)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Text = string.upper(mapInfo.name)
				nameLabel.TextColor3 = mapInfo.type == "Community" and Color3.fromRGB(255, 200, 50)
					or Color3.fromRGB(80, 240, 255)
				nameLabel.TextScaled = true
				nameLabel.Font = Enum.Font.GothamBold
				nameLabel.Parent = btn

				local creatorLabel = Instance.new("TextLabel")
				creatorLabel.Size = UDim2.new(1, -20, 0.2, 0)
				creatorLabel.Position = UDim2.new(0, 10, 0.7, 0)
				creatorLabel.BackgroundTransparency = 1
				creatorLabel.Text = mapInfo.creator and ("By: " .. mapInfo.creator) or "Official Map"
				creatorLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
				creatorLabel.TextScaled = true
				creatorLabel.Font = Enum.Font.Gotham
				creatorLabel.Parent = btn

				btn.MouseButton1Click:Connect(function()
					for _, b in ipairs(optionBtns) do
						b.BorderColor3 = Color3.fromRGB(60, 60, 70)
					end
					btn.BorderColor3 = Color3.fromRGB(100, 255, 100)

					local sound = Instance.new("Sound")
					sound.SoundId = "rbxassetid://138470560522298"
					sound.Volume = 1
					sound.Parent = workspace
					sound:Play()
					game:GetService("Debris"):AddItem(sound, 1)

					mapVoteEvent:FireServer(i)
				end)

				table.insert(optionBtns, btn)
			end
		elseif action == "End" then
			local winningIndex = data
			for i, btn in ipairs(optionBtns) do
				if i == winningIndex then
					btn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
					btn.BorderColor3 = Color3.fromRGB(100, 255, 100)
				else
					btn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
					btn.BorderColor3 = Color3.fromRGB(40, 40, 50)
					for _, child in ipairs(btn:GetChildren()) do
						if child:IsA("TextLabel") then
							child.TextTransparency = 0.6
						end
					end
				end
			end
		elseif action == "Hide" then
			bg.Visible = false
			blur.Size = 0
		end
	end)
end
