-- src/server/PlayerDataManager.server.lua
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage") -- ★追加

local PlayerDataStore = DataStoreService:GetDataStore("BouncyBattleData_v1")

local DEFAULT_DATA = {
	Coins = 0,
	TotalKills = 0,
	WeeklyKills = 0,
	LastSavedWeek = "",
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

	-- ==========================================
	-- ★追加: リーダーボード（Tab画面）の一番左にLevelを表示！
	-- ==========================================
	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = 1
	level.Parent = leaderstats

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

	local currentWeek = os.date("%Y_W%W")

	if success and data then
		coins.Value = data.Coins or DEFAULT_DATA.Coins
		player:SetAttribute("TotalKills", data.TotalKills or DEFAULT_DATA.TotalKills)
		
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

	-- ==========================================
	-- ★超重要: 累計キル数からレベルを自動計算するシステム
	-- ==========================================
	local messageEvent = ReplicatedStorage:WaitForChild("GameMessage", 5)

	local function updateLevel()
		local totalKills = player:GetAttribute("TotalKills") or 0

		-- RIVALS風の計算式（平方根を利用して、後になるほど上がりにくくする）
		local newLevel = math.floor(math.sqrt(totalKills / 2)) + 1

		-- レベルアップした瞬間のド派手な演出！
		if level.Value > 0 and newLevel > level.Value then
			-- 1. サーバー全体にお祝いメッセージを流して優越感を出す！
			if messageEvent then
				messageEvent:FireAllClients("🌟 " .. player.Name .. " reached LEVEL " .. newLevel .. "!", Color3.fromRGB(255, 215, 0))
			end

			-- 2. 自分にチャリン！と気持ちいい音を鳴らす
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local sound = Instance.new("Sound")
				sound.SoundId = "rbxassetid://106653932643486" 
				sound.Volume = 2.0
				sound.Parent = player.Character.HumanoidRootPart
				sound:Play()
				game:GetService("Debris"):AddItem(sound, 2)
			end
		end

		level.Value = newLevel
	end

	-- ゲーム開始時（ロード直後）に一度レベルを計算する
	updateLevel()

	-- 敵を倒して TotalKills が増えるたびに、自動でレベルアップ判定を行う
	player:GetAttributeChangedSignal("TotalKills"):Connect(updateLevel)
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

	local KillsLeaderboard = DataStoreService:GetOrderedDataStore("KillsLeaderboard_v1")
	pcall(function() KillsLeaderboard:SetAsync(tostring(player.UserId), dataToSave.TotalKills) end)

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