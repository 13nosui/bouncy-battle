-- src/server/LeaderboardManager.server.lua
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local KillsLeaderboard = DataStoreService:GetOrderedDataStore("KillsLeaderboard_v1")
local UPDATE_INTERVAL = 60 -- 60秒ごとに更新

local function updateLeaderboard()
	-- "RankingBoard" という名前のパーツを探す
	local boardPart = Workspace:FindFirstChild("RankingBoard", true)
	if not boardPart then return end

	-- "ListFrame" を探す
	local listFrame = boardPart:FindFirstChild("ListFrame", true)
	if not listFrame then return end

	-- ★あなたがStudioで作った「Template（ひな形）」を探す
	local template = listFrame:FindFirstChild("Template")
	if not template then
		warn("ListFrameの中に 'Template' という名前のFrameが見つかりません！")
		return
	end

	-- クラウドから「トップ5」を取得
	local success, pages = pcall(function()
		return KillsLeaderboard:GetSortedAsync(false, 5)
	end)

	if success and pages then
		-- 前回プログラムが自動生成したクローン行だけを削除する（Templateは残す）
		for _, child in ipairs(listFrame:GetChildren()) do
			if child:IsA("Frame") and child.Name ~= "Template" then
				child:Destroy()
			end
		end

		local rank = 1
		local data = pages:GetCurrentPage()

		for _, entry in ipairs(data) do
			local userId = entry.key
			local kills = entry.value

			-- ユーザーIDから名前を取得
			local name = "Unknown Player"
			local s, n = pcall(function() return Players:GetNameFromUserIdAsync(tonumber(userId)) end)
			if s and n then name = n end

			-- ==========================================
			-- ★テンプレートをコピーして、1行分のUIを生成！
			-- ==========================================
			local row = template:Clone()
			row.Name = "Row_" .. rank
			row.LayoutOrder = rank
			row.Visible = true -- コピーしたものは画面に表示する
			
			-- あなたが作ったTextLabelを探して、データを入れる
			local rankLabel = row:FindFirstChild("Ranking")
			local nameLabel = row:FindFirstChild("Name")
			local killsLabel = row:FindFirstChild("Kills")

			if rankLabel then rankLabel.Text = "#" .. rank end
			if nameLabel then nameLabel.Text = name end
			if killsLabel then killsLabel.Text = kills end -- "Kills"という文字を付けるかはお好みで！

			-- おまけ：1〜3位の順位の色だけ自動でリッチ（金銀銅）にする演出
			if rankLabel then
				if rank == 1 then rankLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
				elseif rank == 2 then rankLabel.TextColor3 = Color3.fromRGB(192, 192, 192)
				elseif rank == 3 then rankLabel.TextColor3 = Color3.fromRGB(205, 127, 50)
				else rankLabel.TextColor3 = Color3.new(1, 1, 1) end
			end

			-- ListFrameの中に入れて表示させる
			row.Parent = listFrame
			rank = rank + 1
		end
	end
end

-- ずっと繰り返し更新するループ
task.spawn(function()
	while true do
		updateLeaderboard()
		task.wait(UPDATE_INTERVAL)
	end
end)