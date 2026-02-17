local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- === 設定値 ===
local BULLET_SIZE = 1.5
local BULLET_SPEED = 80 -- 少し遅くして避けやすくする
local BULLET_LIFE = 15
local BOUNCINESS = 1.0
local DAMAGE = 20 -- 100で即死
local FIRE_COOLDOWN = 0.5 -- 0.5秒に1発

-- プレイヤーごとのクールダウン管理用テーブル
local cooldowns = {}

-- RemoteEventの準備
local remoteEventName = "FireBullet"
local fireEvent = ReplicatedStorage:FindFirstChild(remoteEventName)
if not fireEvent then
	fireEvent = Instance.new("RemoteEvent")
	fireEvent.Name = remoteEventName
	fireEvent.Parent = ReplicatedStorage
end

fireEvent.OnServerEvent:Connect(function(player, mousePosition)
	local character = player.Character
	if not character then
		return
	end

	-- 1. クールダウン判定
	local now = tick()
	if cooldowns[player.UserId] and (now - cooldowns[player.UserId] < FIRE_COOLDOWN) then
		return -- まだ撃てない
	end
	cooldowns[player.UserId] = now -- 撃った時間を記録

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	-- 発射位置（自爆を防ぐため、体の少し前から出す）
	local spawnDirection = (mousePosition - rootPart.Position).Unit
	local spawnPos = rootPart.Position + spawnDirection * 5

	-- 2. 弾の生成
	local bullet = Instance.new("Part")
	bullet.Name = "RubberBullet"
	bullet.Shape = Enum.PartType.Ball
	bullet.Size = Vector3.new(BULLET_SIZE, BULLET_SIZE, BULLET_SIZE)
	bullet.Color = Color3.fromHSV(math.random(), 1, 1) -- 色をランダムにして誰の弾か分かりやすく
	bullet.Material = Enum.Material.Neon
	bullet.Position = spawnPos
	bullet.CanCollide = true

	-- 物理プロパティ
	local physicalProperties = PhysicalProperties.new(0.1, 0.1, BOUNCINESS, 1.0, 1.0)
	bullet.CustomPhysicalProperties = physicalProperties

	-- 3. トレイル（軌跡）の追加
	local trail = Instance.new("Trail")
	local att0 = Instance.new("Attachment", bullet)
	att0.Position = Vector3.new(0, 0.5, 0)
	local att1 = Instance.new("Attachment", bullet)
	att1.Position = Vector3.new(0, -0.5, 0)
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Lifetime = 0.3 -- 軌跡が残る時間
	trail.Color = ColorSequence.new(bullet.Color)
	trail.Parent = bullet

	bullet.Parent = workspace
	bullet.Velocity = spawnDirection * BULLET_SPEED

	-- ネットワークオーナーシップ（ラグ対策）
	bullet:SetNetworkOwner(player)

	-- 4. ダメージ判定 (重要！)
	local hasHit = false -- 二重ヒット防止

	bullet.Touched:Connect(function(hit)
		if hasHit then
			return
		end

		-- 人間に当たったかチェック
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			-- 自分自身に当たった場合の処理
			-- ゲームコンセプト通り「自爆あり」ならこのまま。
			-- もし「発射直後の自爆」だけ防ぎたいなら、ここで距離チェックなどを入れますが、
			-- 今回は「カオス」がテーマなので、跳ね返ってきた弾は自分にも当たるようにします。

			humanoid:TakeDamage(DAMAGE)
			hasHit = true

			-- 当たったら弾を消す（貫通させない場合）
			bullet:Destroy()

			-- キルログなどを出すならここに処理を追加
			print(player.Name .. " hit " .. hit.Parent.Name)
		end
	end)

	-- 時間経過で削除
	Debris:AddItem(bullet, BULLET_LIFE)
end)

print("Bouncy Battle: Damage & Cooldown Loaded")
