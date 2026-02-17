local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- === 設定値 ===
local BULLET_SIZE = 1.5
local BULLET_SPEED = 80
local BULLET_LIFE = 15
local BOUNCINESS = 1.0
local DAMAGE = 20
local FIRE_COOLDOWN = 0.5

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
		return
	end
	cooldowns[player.UserId] = now

	-- 2. 発射位置の決定（銃を持っているかチェック）
	local tool = character:FindFirstChildOfClass("Tool")
	local muzzle = nil

	-- ツール > Handle > Muzzle があるか探す
	if tool and tool:FindFirstChild("Handle") then
		muzzle = tool.Handle:FindFirstChild("Muzzle")
	end

	local spawnPos
	local spawnDirection

	if muzzle then
		-- A. 銃を持っている場合: 銃口(Muzzle)の位置を使う
		spawnPos = muzzle.WorldPosition
		spawnDirection = (mousePosition - spawnPos).Unit
	else
		-- B. 銃を持っていない場合（予備）: 体から出す
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			return
		end

		spawnDirection = (mousePosition - rootPart.Position).Unit
		spawnPos = rootPart.Position + spawnDirection * 5
	end

	-- 3. 弾の生成
	local bullet = Instance.new("Part")
	bullet.Name = "RubberBullet"
	bullet.Shape = Enum.PartType.Ball
	bullet.Size = Vector3.new(BULLET_SIZE, BULLET_SIZE, BULLET_SIZE)
	bullet.Color = Color3.fromHSV(math.random(), 1, 1)
	bullet.Material = Enum.Material.Neon
	bullet.Position = spawnPos -- ここでエラーが出ていましたが、修正後は必ず値が入ります
	bullet.CanCollide = true

	-- 物理プロパティ
	local physicalProperties = PhysicalProperties.new(0.1, 0.1, BOUNCINESS, 1.0, 1.0)
	bullet.CustomPhysicalProperties = physicalProperties

	-- 4. トレイル（軌跡）
	local trail = Instance.new("Trail")
	local att0 = Instance.new("Attachment", bullet)
	att0.Position = Vector3.new(0, 0.5, 0)
	local att1 = Instance.new("Attachment", bullet)
	att1.Position = Vector3.new(0, -0.5, 0)
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Lifetime = 0.3
	trail.Color = ColorSequence.new(bullet.Color)
	trail.Parent = bullet

	bullet.Parent = workspace
	bullet.Velocity = spawnDirection * BULLET_SPEED

	-- ネットワークオーナーシップ（ラグ対策）
	bullet:SetNetworkOwner(player)

	-- 5. ダメージ判定
	local hasHit = false

	bullet.Touched:Connect(function(hit)
		if hasHit then
			return
		end

		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			humanoid:TakeDamage(DAMAGE)
			hasHit = true
			bullet:Destroy()
			print(player.Name .. " hit " .. hit.Parent.Name)
		end
	end)

	-- 時間経過で削除
	Debris:AddItem(bullet, BULLET_LIFE)
end)

print("Bouncy Battle: Server Logic Fixed & Loaded")
