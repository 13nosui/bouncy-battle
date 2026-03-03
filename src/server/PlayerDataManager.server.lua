-- src/server/PlayerDataManager.server.lua
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- "BouncyBattleData_v1" という名前のセーブデータ領域を作成
local PlayerDataStore = DataStoreService:GetDataStore("BouncyBattleData_v1")

-- プレイヤーが最初から持っている初期データ
local DEFAULT_DATA = {
	Coins = 0,
	TotalKills = 0,
	-- 最初から使える武器とスキル
	UnlockedWeapons = { "BouncyGun", "BouncyShotgun", "BouncySMG" },
	UnlockedSkills = { "Energy Shield", "SpeedBoost" },
}

-- プレイヤーが入ってきた時の処理（データのロード）
local function onPlayerAdded(player)
	-- === 1. leaderstats（画面右上のスコアボード用）の作成 ===
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local kills = Instance.new("IntValue")
	kills.Name = "Kills" -- これは「現在の試合でのキル数」
	kills.Value = 0
	kills.Parent = leaderstats

	local coins = Instance.new("IntValue")
	coins.Name = "Coins" -- 追加：所持コイン
	coins.Value = 0
	coins.Parent = leaderstats

	-- セーブしない一時的なデータ（現在のキル数など）はリセットする
	player:SetAttribute("InMatch", false)

	-- === 2. クラウドからデータを読み込む ===
	local data = nil
	local success, err = pcall(function()
		data = PlayerDataStore:GetAsync(tostring(player.UserId))
	end)

	if success and data then
		-- データがあれば反映
		coins.Value = data.Coins or DEFAULT_DATA.Coins
		player:SetAttribute("TotalKills", data.TotalKills or DEFAULT_DATA.TotalKills)

		-- アンロック済みのアイテムをカンマ区切りの文字列で保存しておく
		local weaponsStr = table.concat(data.UnlockedWeapons or DEFAULT_DATA.UnlockedWeapons, ",")
		local skillsStr = table.concat(data.UnlockedSkills or DEFAULT_DATA.UnlockedSkills, ",")
		player:SetAttribute("UnlockedWeapons", weaponsStr)
		player:SetAttribute("UnlockedSkills", skillsStr)
	else
		if not success then
			warn("データの読み込みに失敗しました:", err)
		end
		-- 初心者（データなし）の場合は初期データを入れる
		coins.Value = DEFAULT_DATA.Coins
		player:SetAttribute("TotalKills", DEFAULT_DATA.TotalKills)

		local weaponsStr = table.concat(DEFAULT_DATA.UnlockedWeapons, ",")
		local skillsStr = table.concat(DEFAULT_DATA.UnlockedSkills, ",")
		player:SetAttribute("UnlockedWeapons", weaponsStr)
		player:SetAttribute("UnlockedSkills", skillsStr)
	end
end

-- プレイヤーが出ていく時の処理（データのセーブ）
local function onPlayerRemoving(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	-- 保存するデータをまとめる
	local weaponsStr = player:GetAttribute("UnlockedWeapons") or ""
	local skillsStr = player:GetAttribute("UnlockedSkills") or ""

	local dataToSave = {
		Coins = leaderstats.Coins.Value,
		TotalKills = player:GetAttribute("TotalKills") or 0,
		UnlockedWeapons = string.split(weaponsStr, ","),
		UnlockedSkills = string.split(skillsStr, ","),
	}

	-- クラウドに保存
	local success, err = pcall(function()
		PlayerDataStore:SetAsync(tostring(player.UserId), dataToSave)
	end)

	if not success then
		warn("データの保存に失敗しました:", err)
	else
		print(player.Name .. " のデータをセーブしました！")
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Studioでテスト中に「Stop」を押した時にも確実に保存するための安全対策
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			onPlayerRemoving(player)
		end)
	end
	task.wait(2) -- 保存が終わるまで少し待つ
end)
