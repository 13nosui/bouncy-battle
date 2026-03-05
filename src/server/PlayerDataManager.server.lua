-- src/server/PlayerDataManager.server.lua
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local PlayerDataStore = DataStoreService:GetDataStore("BouncyBattleData_v1")

local DEFAULT_DATA = {
	Coins = 0,
	TotalKills = 0,
	WeeklyKills = 0, -- ★追加: 週間キル数
	LastSavedWeek = "", -- ★追加: 最後に遊んだ「週」の記録
	UnlockedWeapons = { "BouncyGun", "BouncyShotgun", "BouncySMG" },
	UnlockedSkills = { "Energy Shield", "SpeedBoost" },
	Slot1 = "BouncyGun",
	Slot2 = "",
	SlotQ = "Energy Shield",
	SlotZ = "",
}

local function onPlayerAdded(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Value = 0
	kills.Parent = leaderstats

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = leaderstats

	player:SetAttribute("InMatch", false)

	local data = nil
	local success, err = pcall(function()
		data = PlayerDataStore:GetAsync(tostring(player.UserId))
	end)

	-- ★今が「今年の第何週か」を取得（例: "2024_W45"）
	local currentWeek = os.date("%Y_W%W")

	if success and data then
		coins.Value = data.Coins or DEFAULT_DATA.Coins
		player:SetAttribute("TotalKills", data.TotalKills or DEFAULT_DATA.TotalKills)
		
		-- ★追加: もし記録されている週が今週と違ったら、週間キルを0にリセット！
		if data.LastSavedWeek ~= currentWeek then
			player:SetAttribute("WeeklyKills", 0)
		else
			player:SetAttribute("WeeklyKills", data.WeeklyKills or 0)
		end

		local weaponsStr = table.concat(data.UnlockedWeapons or DEFAULT_DATA.UnlockedWeapons, ",")
		local skillsStr = table.concat(data.UnlockedSkills or DEFAULT_DATA.UnlockedSkills, ",")
		player:SetAttribute("UnlockedWeapons", weaponsStr)
		player:SetAttribute("UnlockedSkills", skillsStr)

		player:SetAttribute("Slot1", data.Slot1 or DEFAULT_DATA.Slot1)
		player:SetAttribute("Slot2", data.Slot2 or DEFAULT_DATA.Slot2)
		player:SetAttribute("SlotQ", data.SlotQ or DEFAULT_DATA.SlotQ)
		player:SetAttribute("SlotZ", data.SlotZ or DEFAULT_DATA.SlotZ)
	else
		coins.Value = DEFAULT_DATA.Coins
		player:SetAttribute("TotalKills", DEFAULT_DATA.TotalKills)
		player:SetAttribute("WeeklyKills", DEFAULT_DATA.WeeklyKills)

		local weaponsStr = table.concat(DEFAULT_DATA.UnlockedWeapons, ",")
		local skillsStr = table.concat(DEFAULT_DATA.UnlockedSkills, ",")
		player:SetAttribute("UnlockedWeapons", weaponsStr)
		player:SetAttribute("UnlockedSkills", skillsStr)

		player:SetAttribute("Slot1", DEFAULT_DATA.Slot1)
		player:SetAttribute("Slot2", DEFAULT_DATA.Slot2)
		player:SetAttribute("SlotQ", DEFAULT_DATA.SlotQ)
		player:SetAttribute("SlotZ", DEFAULT_DATA.SlotZ)
	end
end

local function onPlayerRemoving(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local weaponsStr = player:GetAttribute("UnlockedWeapons") or ""
	local skillsStr = player:GetAttribute("UnlockedSkills") or ""
	local currentWeek = os.date("%Y_W%W")

	local dataToSave = {
		Coins = leaderstats.Coins.Value,
		TotalKills = player:GetAttribute("TotalKills") or 0,
		WeeklyKills = player:GetAttribute("WeeklyKills") or 0,
		LastSavedWeek = currentWeek,
		UnlockedWeapons = string.split(weaponsStr, ","),
		UnlockedSkills = string.split(skillsStr, ","),
		Slot1 = player:GetAttribute("Slot1") or "",
		Slot2 = player:GetAttribute("Slot2") or "",
		SlotQ = player:GetAttribute("SlotQ") or "",
		SlotZ = player:GetAttribute("SlotZ") or "",
	}

	pcall(function() PlayerDataStore:SetAsync(tostring(player.UserId), dataToSave) end)

	-- グローバルランキングに保存
	local KillsLeaderboard = DataStoreService:GetOrderedDataStore("KillsLeaderboard_v1")
	pcall(function() KillsLeaderboard:SetAsync(tostring(player.UserId), dataToSave.TotalKills) end)

	-- 週間ランキングに保存（週ごとに独立したデータストアになる）
	local WeeklyLeaderboard = DataStoreService:GetOrderedDataStore("KillsWeekly_" .. currentWeek)
	pcall(function() WeeklyLeaderboard:SetAsync(tostring(player.UserId), dataToSave.WeeklyKills) end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function() onPlayerRemoving(player) end)
	end
	task.wait(2)
end)