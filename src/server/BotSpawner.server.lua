local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

-- 設定
local BOT_TEMPLATE_NAME = "Dummy" -- ServerStorageに入れたモデル名
local RESPAWN_TIME = 3.0 -- Botが復活する時間
local SPAWN_POSITION = Vector3.new(0, 5, 0) -- Botの出現位置（必要に応じて変えてください）

-- ServerStorageから原本を探す
local botTemplate = ServerStorage:WaitForChild(BOT_TEMPLATE_NAME)

local function spawnBot()
	-- 1. Botをコピーして配置
	local bot = botTemplate:Clone()
	bot.Parent = Workspace
	-- 位置調整（モデルの中心を動かす）
	bot:PivotTo(CFrame.new(SPAWN_POSITION))

	local humanoid = bot:WaitForChild("Humanoid")

	-- 2. 死亡時の処理
	humanoid.Died:Connect(function()
		-- 誰が倒したかチェック
		local creatorTag = humanoid:FindFirstChild("creator")
		if creatorTag and creatorTag.Value then
			local killerPlayer = creatorTag.Value

			-- プレイヤーのスコアを加算
			-- (GameLoop側でChangedイベントを監視しているので、値を増やすだけで勝敗判定が動く)
			local stats = killerPlayer:FindFirstChild("leaderstats")
			if stats then
				stats.Kills.Value = stats.Kills.Value + 1
			end
		end

		-- 死体を片付ける（少し待ってから消す）
		task.delay(2, function()
			bot:Destroy()
		end)

		-- 新しいBotを出現させる（リスポーン）
		task.delay(RESPAWN_TIME, function()
			spawnBot()
		end)
	end)
end

-- ゲーム開始時に最初の1体を出す
spawnBot()
