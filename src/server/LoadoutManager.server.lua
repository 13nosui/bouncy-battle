-- src/server/LoadoutManager.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

-- クライアントから「これを装備したい」とリクエストを受け取るイベント
local equipItemEvent = ReplicatedStorage:FindFirstChild("EquipItem")
if not equipItemEvent then
	equipItemEvent = Instance.new("RemoteEvent")
	equipItemEvent.Name = "EquipItem"
	equipItemEvent.Parent = ReplicatedStorage
end

local WeaponsFolder = ServerStorage:WaitForChild("Weapons")

-- 音を鳴らす関数
local function playEquipSound(character, soundId, pitch)
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
	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	local backpack = player:FindFirstChild("Backpack")

	if not character or not humanoid or not backpack then
		return
	end

	if itemType == "Weapon" then
		local weaponTemplate = WeaponsFolder:FindFirstChild(itemName)
		if not weaponTemplate then
			return
		end

		-- すでに持っている場合は無視
		if backpack:FindFirstChild(itemName) or character:FindFirstChild(itemName) then
			return
		end

		-- 今持っている武器を調べて、スロット1か2の空いている方（または手に持っている方）を上書き
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

		playEquipSound(character, "rbxassetid://2620461915", 1.0) -- カチャッという武器の音
	elseif itemType == "Skill" then
		local sq = player:GetAttribute("SlotQ") or ""
		local sz = player:GetAttribute("SlotZ") or ""

		-- すでに同じものを持っている場合は無視
		if sq == itemName or sz == itemName then
			return
		end

		if sq == "" then
			player:SetAttribute("SlotQ", itemName)
		elseif sz == "" then
			player:SetAttribute("SlotZ", itemName)
		else
			-- 両方埋まっている場合はQ枠を上書き
			player:SetAttribute("SlotQ", itemName)
		end

		playEquipSound(character, "rbxassetid://86070307558627", 1.2) -- ピシュン！というスキルの音
	end
end)
