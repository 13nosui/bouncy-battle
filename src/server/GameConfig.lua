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

return GameConfig
