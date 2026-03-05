-- src/server/LoadoutManager.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

-- ★追加: 各アイテムの価格設定（0は最初から使えるもの）
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
	["DoubleJump"] = 300, -- ★追加
	["TripleJump"] = 500, -- ★追加
	["QuadJump"] = 800,   -- ★追加
	["Invisibility"] = 300,
	["Teleport"] = 400,
	["TimeSlow"] = 500,
	["Giant"] = 600,
	["Mini"] = 600,
	["XRay"] = 700,
}

-- ==========================================
-- ★追加: アイテムごとの「必要なレベル」を設定
-- （ここに書かれていないアイテムは Lv.1 から買えます）
-- ==========================================
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

local equipItemEvent = ReplicatedStorage:FindFirstChild("EquipItem")
if not equipItemEvent then
	equipItemEvent = Instance.new("RemoteEvent")
	equipItemEvent.Name = "EquipItem"
	equipItemEvent.Parent = ReplicatedStorage
end

local WeaponsFolder = ServerStorage:WaitForChild("Weapons")

local function playSound(character, soundId, pitch)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Volume = 1.0
		sound.Pitch = pitch or 1.0
		sound.Parent = hrp
		sound:Play()
		Debris:AddItem(sound, 1)
	end
end

equipItemEvent.OnServerEvent:Connect(function(player, itemType, itemName)
	-- ==========================================
	-- ★追加: サーバー側でのレベルチェック（不正防止）
	-- ==========================================
	local myLevel = 1
	local stats = player:FindFirstChild("leaderstats")
	if stats and stats:FindFirstChild("Level") then
		myLevel = stats.Level.Value
	end
	local reqLevel = ITEM_UNLOCK_LEVELS[itemName] or 1

	if myLevel < reqLevel then
		-- レベル不足の場合はブー音を鳴らして弾く
		local character = player.Character
		if character then playSound(character, "rbxassetid://127799722113121", 1.0) end
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	local backpack = player:FindFirstChild("Backpack")
	local leaderstats = player:FindFirstChild("leaderstats")

	if not character or not humanoid or not backpack or not leaderstats then
		return
	end

	local coins = leaderstats:FindFirstChild("Coins")
	local price = ITEM_PRICES[itemName] or 0

	if itemType == "Weapon" then
		-- ★追加: アンロック（購入）判定
		local unlockedStr = player:GetAttribute("UnlockedWeapons") or ""
		local isUnlocked = table.find(string.split(unlockedStr, ","), itemName) ~= nil

		if not isUnlocked then
			if coins and coins.Value >= price then
				coins.Value = coins.Value - price
				local newList = unlockedStr == "" and itemName or unlockedStr .. "," .. itemName
				player:SetAttribute("UnlockedWeapons", newList)
				playSound(character, "rbxassetid://106653932643486", 2.0) -- 買った時のチャリン音
			else
				playSound(character, "rbxassetid://127799722113121", 1.0) -- お金が足りない時のブー音
				return
			end
		end

		local weaponTemplate = WeaponsFolder:FindFirstChild(itemName)
		if not weaponTemplate then
			return
		end
		if backpack:FindFirstChild(itemName) or character:FindFirstChild(itemName) then
			return
		end

		local currentWeapons = {}
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Tool") and item.Name:match("Bouncy") then
				table.insert(currentWeapons, item)
			end
		end
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and item.Name:match("Bouncy") then
				table.insert(currentWeapons, item)
			end
		end

		local assignSlot = 1
		if #currentWeapons == 0 then
			assignSlot = 1
		elseif #currentWeapons == 1 then
			assignSlot = currentWeapons[1]:GetAttribute("Slot") == 1 and 2 or 1
		else
			local equippedTool = character:FindFirstChildOfClass("Tool")
			if equippedTool and equippedTool.Name:match("Bouncy") then
				assignSlot = equippedTool:GetAttribute("Slot") or 1
				equippedTool:Destroy()
			else
				assignSlot = currentWeapons[1]:GetAttribute("Slot") or 1
				currentWeapons[1]:Destroy()
			end
		end

		local clonedWeapon = weaponTemplate:Clone()
		clonedWeapon:SetAttribute("Slot", assignSlot)
		clonedWeapon.Parent = backpack
		player:SetAttribute("Slot" .. tostring(assignSlot), itemName)
		playSound(character, "rbxassetid://506273075", 1.0) -- カチャッ
	elseif itemType == "Skill" then
		-- ★追加: アンロック（購入）判定
		local unlockedStr = player:GetAttribute("UnlockedSkills") or ""
		local isUnlocked = table.find(string.split(unlockedStr, ","), itemName) ~= nil

		if not isUnlocked then
			if coins and coins.Value >= price then
				coins.Value = coins.Value - price
				local newList = unlockedStr == "" and itemName or unlockedStr .. "," .. itemName
				player:SetAttribute("UnlockedSkills", newList)
				playSound(character, "rbxassetid://106653932643486", 2.0) -- 買った時のチャリン音
			else
				playSound(character, "rbxassetid://127799722113121", 1.0) -- お金が足りない時のブー音
				return
			end
		end

		local sq = player:GetAttribute("SlotQ") or ""
		local sz = player:GetAttribute("SlotZ") or ""

		if sq == itemName or sz == itemName then
			return
		end
		if sq == "" then
			player:SetAttribute("SlotQ", itemName)
		elseif sz == "" then
			player:SetAttribute("SlotZ", itemName)
		else
			player:SetAttribute("SlotQ", itemName)
		end

		playSound(character, "rbxassetid://86070307558627", 1.2) -- ピシュン
	end
end)
