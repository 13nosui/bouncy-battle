local Players = game:GetService("Players")

local function onPlayerAdded(player)
	player.CharacterAppearanceLoaded:Connect(function(character)
		-- ヒューマノイドが見つかるまで少し待つ（タイムアウト付き）
		local humanoid = character:WaitForChild("Humanoid", 5)
		if not humanoid then
			return
		end

		-- タイミングの問題を避けるため、1フレーム待機
		task.wait()

		-- 安全に実行するために pcall (保護モード) で囲む
		local success, err = pcall(function()
			-- キャラクターがまだWorkspaceに存在するか確認
			if not character:IsDescendantOf(workspace) then
				return
			end

			-- 現在のアバター設定を取得
			local description = humanoid:GetAppliedDescription()

			-- 体のパーツIDだけを「0 (デフォルトのブロック形状)」に変更
			description.Head = 0
			description.Torso = 0
			description.LeftArm = 0
			description.RightArm = 0
			description.LeftLeg = 0
			description.RightLeg = 0

			-- 変更を適用
			humanoid:ApplyDescription(description)
		end)

		if not success then
			warn("Failed to force blocky avatar: " .. tostring(err))
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
