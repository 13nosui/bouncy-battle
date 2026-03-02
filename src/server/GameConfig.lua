-- src/server/GameConfig.lua
local GameConfig = {}

-- === 武器ごとのパラメータ設定 ===
GameConfig.Weapons = {
	["BouncyGun"] = {
		BulletSize = 1.5,
		BulletSpeed = 150,
		BulletGravity = 0.1,
		BulletLife = 15,
		Bounciness = 1.0,
		Damage = 20,
		FireCooldown = 0.5,
		MaxAmmo = 10,
		ReloadTime = 2.0,
		BulletsPerShot = 1,
		SpreadAngle = 0,

		-- ★見た目の設定
		UseRandomColor = true, -- 今まで通りランダムな虹色にする
		BulletColor = Color3.fromRGB(255, 255, 0), -- UseRandomColorがfalseの場合の色
		TrailDuration = 0.3, -- 軌跡（尻尾）の長さ
	},
	["BouncyShotgun"] = {
		BulletSize = 1.0,
		BulletSpeed = 120,
		BulletGravity = 0.3,
		BulletLife = 5,
		Bounciness = 0.8,
		Damage = 10,
		FireCooldown = 1.0,
		MaxAmmo = 5,
		ReloadTime = 2.5,
		BulletsPerShot = 5,
		SpreadAngle = 15,

		UseRandomColor = false,
		BulletColor = Color3.fromRGB(255, 80, 80), -- ショットガンは「赤」固定
		TrailDuration = 0.2,
	},
	["BouncySMG"] = {
		BulletSize = 0.8,
		BulletSpeed = 180,
		BulletGravity = 0.05,
		BulletLife = 8,
		Bounciness = 1.2,
		Damage = 8,
		FireCooldown = 0.12,
		MaxAmmo = 30,
		ReloadTime = 1.5,
		BulletsPerShot = 1,
		SpreadAngle = 5,

		UseRandomColor = false,
		BulletColor = Color3.fromRGB(50, 200, 255), -- SMGは「シアン（水色）」固定
		TrailDuration = 0.1,
	},
}

-- === シールド（ガード）の設定 ===
GameConfig.Shield = {
	Duration = 1.5, -- シールドの展開時間（秒）
	Cooldown = 5.0, -- 次に使えるまでの待ち時間（秒）
	BounceMultiplier = 1.5, -- 敵の弾を弾き返す時のスピード倍率（1.5倍でカウンター！）
}

-- === 超能力の設定 ===
GameConfig.Abilities = {
	["HighJump"] = {
		JumpVelocity = 120, -- 上に跳ね上がる力（数字が大きいほど高く飛ぶ）
		Cooldown = 4.0, -- 次に使えるまでの待ち時間（秒）
	},
	["SpeedBoost"] = {
		SpeedMultiplier = 2.5, -- 移動速度の倍率
		Duration = 5.0, -- 持続時間（秒）
		Cooldown = 10.0, -- 次に使えるまでの待ち時間
	},
	["Invisibility"] = {
		Transparency = 0.9, -- 透明度（1.0で完全に見えなくなる）
		Duration = 7.0, -- 持続時間（秒）
		Cooldown = 15.0, -- 次に使えるまでの待ち時間
	},
	["Teleport"] = {
		Distance = 50, -- ワープする距離（スタッド）
		Cooldown = 6.0,
	},
	["TimeSlow"] = {
		Radius = 25, -- 弾が遅くなるドームの半径
		Duration = 6.0, -- 持続時間（秒）
		SpeedMultiplier = 0.1, -- 弾の速度を10%に落とす
		Cooldown = 15.0,
	},
	["Giant"] = {
		Scale = 2.0, -- 大きさ（2倍）
		DamageMultiplier = 2.0, -- 攻撃力（2倍）
		Duration = 10.0, -- 持続時間（秒）
		Cooldown = 20.0,
	},
	["Mini"] = {
		Scale = 0.4, -- 大きさ（0.4倍）
		DamageMultiplier = 0.5, -- 攻撃力（半分）
		Duration = 10.0,
		Cooldown = 15.0,
	},
	["XRay"] = {
		Duration = 8.0, -- 透視できる時間（秒）
		Cooldown = 20.0, -- 次に使えるまでの時間
	},
}

return GameConfig
