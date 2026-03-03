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
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
	end)
end)
