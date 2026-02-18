local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- === 設定 ===
local WIN_SCORE = 5 -- 勝利に必要なキル数
local RESPAWN_TIME = 3.0 -- リスポーンまでの待機時間（秒）

Players.RespawnTime = RESPAWN_TIME

-- 勝利メッセージ通知用のイベント
local messageEvent = ReplicatedStorage:FindFirstChild("GameMessage")
if not messageEvent then
	messageEvent = Instance.new("RemoteEvent")
	messageEvent.Name = "GameMessage"
	messageEvent.Parent = ReplicatedStorage
end

local isRoundOver = false

-- 全員のスコアをリセットする
local function resetScores()
	isRoundOver = false
	for _, player in ipairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			leaderstats.Kills.Value = 0
		end
		player:LoadCharacter()
	end

	-- Botもリセット（再配置）するためのイベントがあればここで発火
	-- 今回はBot側で自律的に動くのでそのままでOK
end

-- 勝敗判定（スコアが変わるたびに呼ばれる）
local function checkWinCondition(player, currentKills)
	if isRoundOver then
		return
	end

	if currentKills >= WIN_SCORE then
		isRoundOver = true
		local winMsg = player.Name .. " WINS THE MATCH!"
		print(winMsg)

		-- 全員にメッセージ送信
		messageEvent:FireAllClients(winMsg, Color3.fromRGB(255, 255, 100))

		-- 少し待ってからリセット
		task.wait(3)
		resetScores()
	end
end

-- プレイヤー参加時のセットアップ
local function onPlayerAdded(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Value = 0
	kills.Parent = leaderstats

	-- ★変更点: Killsの値が変わったら勝敗チェックをするように変更
	-- これにより、Botを倒してKillsが増えた場合も反応するようになる
	kills.Changed:Connect(function(newValue)
		checkWinCondition(player, newValue)
	end)

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			-- プレイヤー同士のキル処理
			local creatorTag = humanoid:FindFirstChild("creator")
			if creatorTag and creatorTag.Value then
				local killer = creatorTag.Value
				if killer and killer:IsA("Player") and killer ~= player then
					local stats = killer:FindFirstChild("leaderstats")
					if stats then
						stats.Kills.Value = stats.Kills.Value + 1
					end
				end
			end
		end)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
