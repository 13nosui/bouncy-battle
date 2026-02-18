local Players = game:GetService("Players")

local function onPlayerAdded(player)
	player.CharacterAppearanceLoaded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		-- 現在のアバター設定（服やアクセサリの情報）を取得
		local description = humanoid:GetAppliedDescription()

		-- 体のパーツIDだけを「0 (デフォルトのブロック形状)」に変更
		-- これで「服」や「髪」は維持されたまま、体が四角くなります
		description.Head = 0
		description.Torso = 0
		description.LeftArm = 0
		description.RightArm = 0
		description.LeftLeg = 0
		description.RightLeg = 0

		-- 変更を適用
		humanoid:ApplyDescription(description)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
