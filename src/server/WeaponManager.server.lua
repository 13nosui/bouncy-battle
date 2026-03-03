local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local WeaponsFolder = ServerStorage:WaitForChild("Weapons")

local IS_VIP_SERVER = game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0

-- === プレイヤーのスポーン時の武器配布 ===
local function onCharacterAdded(player, character)
	task.wait(0.1)

	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and item.Name:match("Bouncy") then
				item:Destroy()
			end
		end
	end

	if IS_VIP_SERVER then
		for i, weaponTemplate in ipairs(WeaponsFolder:GetChildren()) do
			if weaponTemplate:IsA("Tool") then
				local clone = weaponTemplate:Clone()
				clone:SetAttribute("Slot", i) -- VIP用
				clone.Parent = backpack
			end
		end
	else
		-- ★追加: 通常サーバーの場合、プレイヤーの記憶（メモ）を読み取って武器を復元する！
		local slot1Name = player:GetAttribute("Slot1")
		if slot1Name then
			local w1 = WeaponsFolder:FindFirstChild(slot1Name)
			if w1 then
				local clone1 = w1:Clone()
				clone1:SetAttribute("Slot", 1)
				clone1.Parent = backpack
			end
		end

		local slot2Name = player:GetAttribute("Slot2")
		if slot2Name then
			local w2 = WeaponsFolder:FindFirstChild(slot2Name)
			if w2 then
				local clone2 = w2:Clone()
				clone2:SetAttribute("Slot", 2)
				clone2.Parent = backpack
			end
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
	end)
end)
