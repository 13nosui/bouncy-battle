local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local WeaponsFolder = ServerStorage:WaitForChild("Weapons")

-- プライベート(VIP)サーバーかどうかの判定
local IS_VIP_SERVER = game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
-- (※Studioでのテストプレイ時は必ず false になります)

-- === 1. プレイヤーのスポーン時の武器配布 ===
local function onCharacterAdded(player, character)
	task.wait(0.1) -- ロード待ち

	-- 古い武器を一旦すべて消す
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and item.Name:match("Bouncy") then
				item:Destroy()
			end
		end
	end

	if IS_VIP_SERVER then
		-- ★VIPサーバー: 全種類の武器をプレゼント！
		for _, weaponTemplate in ipairs(WeaponsFolder:GetChildren()) do
			if weaponTemplate:IsA("Tool") then
				weaponTemplate:Clone().Parent = backpack
			end
		end
	else
		-- ★通常サーバー: デフォルトの銃を1つだけ渡す
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

-- === 2. 武器ピックアップ台の処理 (通常サーバー用) ===
local function setupWeaponSpawners()
	-- Workspace内にある「WeaponSpawner」という名前のモデルを探す
	for _, spawner in ipairs(Workspace:GetDescendants()) do
		if spawner.Name == "WeaponSpawner" and spawner:IsA("Model") then
			local clickDetector = spawner:FindFirstChildOfClass("ClickDetector")
			local weaponNameValue = spawner:FindFirstChild("WeaponName") -- 中に入れたStringValue

			if clickDetector and weaponNameValue then
				clickDetector.MouseClick:Connect(function(player)
					-- VIPサーバーならそもそも交換不要なので無視
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

					-- すでに同じ武器を持っていたら何もしない
					if backpack:FindFirstChild(targetWeaponName) or character:FindFirstChild(targetWeaponName) then
						return
					end

					-- いま持っている武器(Bouncy系)を捨てる
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

					-- 新しい武器を渡す
					local clonedWeapon = newWeaponTemplate:Clone()
					clonedWeapon.Parent = backpack

					-- 強制的に装備させる
					local humanoid = character:FindFirstChild("Humanoid")
					if humanoid then
						humanoid:EquipTool(clonedWeapon)
					end

					-- 効果音
					local sound = Instance.new("Sound")
					sound.SoundId = "rbxassetid://6812196620" -- カチャッという装備音
					sound.Volume = 0.8
					sound.Parent = character.HumanoidRootPart
					sound:Play()
					game:GetService("Debris"):AddItem(sound, 1)
				end)
			end
		end
	end
end

-- ロビーやマップがロードされるのを少し待ってから台をセットアップ
task.spawn(function()
	task.wait(3)
	setupWeaponSpawners()
end)
