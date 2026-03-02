local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local WeaponsFolder = ServerStorage:WaitForChild("Weapons")

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
		for i, weaponTemplate in ipairs(WeaponsFolder:GetChildren()) do
			if weaponTemplate:IsA("Tool") then
				local clone = weaponTemplate:Clone()
				clone:SetAttribute("Slot", i) -- VIP用
				clone.Parent = backpack
			end
		end
	else
		local defaultGun = WeaponsFolder:FindFirstChild("BouncyGun")
		if defaultGun and backpack then
			local clone = defaultGun:Clone()
			-- ★最初の武器には「スロット1」の目印をつける
			clone:SetAttribute("Slot", 1)
			clone.Parent = backpack
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
				local clickDetector = spawner:FindFirstChildOfClass("ClickDetector")
				if clickDetector then
					clickDetector:Destroy()
				end

				local targetPart = spawner:FindFirstChild("Part") or spawner.PrimaryPart or spawner
				local prompt = Instance.new("ProximityPrompt")
				prompt.ActionText = "Equip"
				prompt.ObjectText = weaponNameValue.Value
				prompt.KeyboardKeyCode = Enum.KeyCode.E
				prompt.RequiresLineOfSight = false
				prompt.MaxActivationDistance = 12
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
					local humanoid = character and character:FindFirstChild("Humanoid")
					if not character or not backpack or not humanoid then
						return
					end

					-- すでに持っているなら無視
					if backpack:FindFirstChild(targetWeaponName) or character:FindFirstChild(targetWeaponName) then
						return
					end

					-- ★変更: 現在持っている武器をリストアップし、2枠の管理をする
					local currentWeapons = {}
					for _, item in ipairs(character:GetChildren()) do
						if item:IsA("Tool") then
							table.insert(currentWeapons, item)
						end
					end
					for _, item in ipairs(backpack:GetChildren()) do
						if item:IsA("Tool") then
							table.insert(currentWeapons, item)
						end
					end

					local assignSlot = 1
					if #currentWeapons == 0 then
						assignSlot = 1
					elseif #currentWeapons == 1 then
						-- 1つ持っている場合は、空いている方のスロットにする
						assignSlot = currentWeapons[1]:GetAttribute("Slot") == 1 and 2 or 1
					else
						-- 2つ持っている場合は「今手に持っている武器」を捨てる
						local equippedTool = character:FindFirstChildOfClass("Tool")
						if equippedTool then
							assignSlot = equippedTool:GetAttribute("Slot") or 1
							equippedTool:Destroy()
						else
							-- 手に持っていなければ適当なものを捨てる
							assignSlot = currentWeapons[1]:GetAttribute("Slot") or 1
							currentWeapons[1]:Destroy()
						end
					end

					-- 新しい武器を追加して装備
					local clonedWeapon = newWeaponTemplate:Clone()
					clonedWeapon:SetAttribute("Slot", assignSlot) -- スロット番号を記憶！
					clonedWeapon.Parent = backpack
					humanoid:EquipTool(clonedWeapon)

					local sound = Instance.new("Sound")
					sound.SoundId = "rbxassetid://2868285516"
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
