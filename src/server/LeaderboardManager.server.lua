-- src/server/LeaderboardManager.server.lua
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local UPDATE_INTERVAL = 30 -- 30秒ごとに更新

-- ランキングのUI行を作る関数
local function createRow(template, listFrame, rank, name, score)
	local row = template:Clone()
	row.Name = "Row_" .. rank
	row.LayoutOrder = rank
	row.Visible = true
	
	local rankLabel = row:FindFirstChild("Ranking")
	local nameLabel = row:FindFirstChild("Name")
	local killsLabel = row:FindFirstChild("Kills")

	if rankLabel then rankLabel.Text = "#" .. rank end
	if nameLabel then nameLabel.Text = name end
	if killsLabel then killsLabel.Text = tostring(score) end

	-- リッチな色付け
	if rankLabel then
		if rank == 1 then rankLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		elseif rank == 2 then rankLabel.TextColor3 = Color3.fromRGB(192, 192, 192)
		elseif rank == 3 then rankLabel.TextColor3 = Color3.fromRGB(205, 127, 50)
		else rankLabel.TextColor3 = Color3.new(1, 1, 1) end
	end
	row.Parent = listFrame
end

-- グローバル＆週間ランキングの更新
local function updateDataStoreBoard(boardName, dataStoreName)
	local boardPart = Workspace:FindFirstChild(boardName, true)
	if not boardPart then return end
	local listFrame = boardPart:FindFirstChild("ListFrame", true)
	if not listFrame then return end
	local template = listFrame:FindFirstChild("Template")
	if not template then return end

	local store = DataStoreService:GetOrderedDataStore(dataStoreName)
	local success, pages = pcall(function() return store:GetSortedAsync(false, 5) end)

	if success and pages then
		for _, child in ipairs(listFrame:GetChildren()) do
			if child:IsA("Frame") and child.Name ~= "Template" then child:Destroy() end
		end

		local rank = 1
		for _, entry in ipairs(pages:GetCurrentPage()) do
			local name = "Unknown"
			pcall(function() name = Players:GetNameFromUserIdAsync(tonumber(entry.key)) end)
			createRow(template, listFrame, rank, name, entry.value)
			rank = rank + 1
		end
	end
end

-- リアルタイム（今のサーバー）ランキングの更新
local function updateRealtimeBoard()
	local boardPart = Workspace:FindFirstChild("RealtimeBoard", true)
	if not boardPart then return end
	local listFrame = boardPart:FindFirstChild("ListFrame", true)
	if not listFrame then return end
	local template = listFrame:FindFirstChild("Template")
	if not template then return end

	-- サーバーにいる全員のキル数を取得して並び替え
	local playersInfo = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local stats = p:FindFirstChild("leaderstats")
		if stats and stats:FindFirstChild("Kills") then
			table.insert(playersInfo, {name = p.Name, kills = stats.Kills.Value})
		end
	end
	table.sort(playersInfo, function(a, b) return a.kills > b.kills end)

	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "Template" then child:Destroy() end
	end

	for rank = 1, math.min(5, #playersInfo) do
		createRow(template, listFrame, rank, playersInfo[rank].name, playersInfo[rank].kills)
	end
end

-- ループ処理
task.spawn(function()
	while true do
		local currentWeek = os.date("%Y_W%W")
		updateDataStoreBoard("RankingBoard", "KillsLeaderboard_v1")
		updateDataStoreBoard("WeeklyBoard", "KillsWeekly_" .. currentWeek)
		updateRealtimeBoard()
		task.wait(UPDATE_INTERVAL)
	end
end)