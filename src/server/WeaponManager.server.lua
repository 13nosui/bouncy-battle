local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local WeaponsFolder = ServerStorage:WaitForChild("Weapons")

-- プライベート(VIP)サーバーかどうかの判定
local IS_VIP_SERVER = game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0

-- === 1. プレイヤーのスポーン時の武器配布 ===
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
		for _, weaponTemplate in ipairs(WeaponsFolder:GetChildren()) do
			if weaponTemplate:IsA("Tool") then
				weaponTemplate:Clone().Parent = backpack
			end
		end
	else
		local defaultGun = WeaponsFolder:FindFirstChild("BouncyGun")
		if defaultGun and backpack then
			defaultGun:Clone().Parent = backpack
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
	end)
end)

-- === 2. 武器ピックアップ台の処理 ===
local function setupWeaponSpawners()
	for _, spawner in ipairs(Workspace:GetDescendants()) do
		if spawner.Name == "WeaponSpawner" and spawner:IsA("Model") then
			local weaponNameValue = spawner:FindFirstChild("WeaponName")

			if weaponNameValue then
				-- ★変更: 古いClickDetectorがあれば削除
				local clickDetector = spawner:FindFirstChildOfClass("ClickDetector")
				if clickDetector then
					clickDetector:Destroy()
				end

				-- ★変更: 代わりにProximityPrompt(近づいてEキー)を作成
				local targetPart = spawner:FindFirstChild("Part") or spawner.PrimaryPart or spawner
				local prompt = Instance.new("ProximityPrompt")
				prompt.ActionText = "Equip"
				prompt.ObjectText = weaponNameValue.Value
				prompt.KeyboardKeyCode = Enum.KeyCode.E
				prompt.RequiresLineOfSight = false
				prompt.MaxActivationDistance = 12 -- 反応する距離
				prompt.Parent = targetPart

				-- Eキーが押された時の処理
				prompt.Triggered:Connect(function(player)
					if IS_VIP_SERVER then
						return
					end

					local targetWeaponName = weaponNameValue.Value
					local newWeaponTemplate = WeaponsFolder:FindFirstChild(targetWeaponName)
					if not newWeaponTemplate then
						return
					end

					local character = player.Character
					local backpack = player:FindFirstChild("Backpack")
					if not character or not backpack then
						return
					end

					if backpack:FindFirstChild(targetWeaponName) or character:FindFirstChild(targetWeaponName) then
						return
					end

					for _, item in ipairs(backpack:GetChildren()) do
						if item.Name:match("Bouncy") then
							item:Destroy()
						end
					end
					for _, item in ipairs(character:GetChildren()) do
						if item:IsA("Tool") and item.Name:match("Bouncy") then
							item:Destroy()
						end
					end

					local clonedWeapon = newWeaponTemplate:Clone()
					clonedWeapon.Parent = backpack

					local humanoid = character:FindFirstChild("Humanoid")
					if humanoid then
						humanoid:EquipTool(clonedWeapon)
					end

					local sound = Instance.new("Sound")
					sound.SoundId = "rbxassetid://6812196620"
					sound.Volume = 0.8
					sound.Parent = character.HumanoidRootPart
					sound:Play()
					game:GetService("Debris"):AddItem(sound, 1)
				end)
			end
		end
	end
end

task.spawn(function()
	task.wait(3)
	setupWeaponSpawners()
end)
