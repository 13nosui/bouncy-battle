-- src/server/GameConfig.lua
local GameConfig = {}

-- === 武器ごとのパラメータ設定 ===
GameConfig.Weapons = {
	["BouncyGun"] = {
		BulletSize = 1.5, -- 弾の大きさ（スタッド）
		BulletSpeed = 150, -- 弾の飛ぶ速さ
		BulletGravity = 0.1, -- 弾にかかる重力（0で無重力、1で通常の重力）
		BulletLife = 15, -- 弾が自然消滅するまでの時間（秒）
		Bounciness = 1.0, -- 弾の跳ね返りやすさ（1.0でよく跳ねる）
		Damage = 20, -- 1発あたりのダメージ
		FireCooldown = 0.5, -- 次の弾を撃つまでの待ち時間（秒）
		MaxAmmo = 10, -- マガジンの最大弾数
		ReloadTime = 2.0, -- リロードにかかる時間（秒）
		BulletsPerShot = 1, -- 1回のクリックで同時に発射される弾の数
		SpreadAngle = 0, -- 弾のばらつき角度（0で真っ直ぐ飛ぶ）

		-- ★見た目の設定
		UseRandomColor = true, -- ランダムな虹色にするかどうか
		BulletColor = Color3.fromRGB(255, 255, 0), -- UseRandomColorがfalseの場合の弾の色
		TrailDuration = 0.3, -- 弾の軌跡（尻尾）が消えるまでの長さ
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
		SpreadAngle = 15, -- 15度に拡散する

		UseRandomColor = false,
		BulletColor = Color3.fromRGB(255, 80, 80), -- ショットガンは「赤色」
		TrailDuration = 0.2,
	},
	["BouncySMG"] = {
		BulletSize = 0.8,
		BulletSpeed = 180,
		BulletGravity = 0.05,
		BulletLife = 8,
		Bounciness = 1.2,
		Damage = 8,
		FireCooldown = 0.12, -- 高速連射
		MaxAmmo = 30,
		ReloadTime = 1.5,
		BulletsPerShot = 1,
		SpreadAngle = 5,

		UseRandomColor = false,
		BulletColor = Color3.fromRGB(50, 200, 255), -- SMGは「水色」
		TrailDuration = 0.1,
	},
	["BouncyGrenade"] = {
		BulletSize = 2.5, -- かなり大きい弾
		BulletSpeed = 80, -- 弾の飛ぶスピードは遅め
		BulletGravity = 0.8, -- 重力を強くして山なりに飛ばす
		BulletLife = 5,
		Bounciness = 0.3, -- あまり跳ねない（重い感じ）
		Damage = 60, -- 爆発の中心ダメージ（特大！）
		FireCooldown = 1.5, -- 連射はできない
		MaxAmmo = 3, -- マガジンには3発だけ
		ReloadTime = 3.0, -- リロードが遅い
		BulletsPerShot = 1,
		SpreadAngle = 0,

		UseRandomColor = false,
		BulletColor = Color3.fromRGB(40, 40, 40), -- 爆弾っぽく「黒・ダークグレー」
		TrailDuration = 0.5,

		-- ★爆発専用の特別設定
		IsExplosive = true, -- 着弾時に爆発するかどうか
		ExplosionRadius = 15, -- 爆風が届く範囲（スタッド）
	},
	["BouncySniper"] = {
		BulletSize = 1.0, -- 弾の大きさ
		BulletSpeed = 300, -- スナイパーなので超高速！
		BulletGravity = 0.05, -- ほとんど重力の影響を受けず真っ直ぐ飛ぶ
		BulletLife = 10,
		Bounciness = 0.8, -- 少し跳ねる
		Damage = 75, -- 高火力（ヘッドショットなどの概念があれば一撃必殺も！）
		FireCooldown = 1.5, -- 連射できない
		MaxAmmo = 5, -- マガジンサイズ
		ReloadTime = 2.5, -- リロードは遅め
		BulletsPerShot = 1,
		SpreadAngle = 0, -- まったくブレない（精度100%）

		UseRandomColor = false,
		BulletColor = Color3.fromRGB(0, 255, 255), -- 例：シアンのレーザー弾
		TrailDuration = 0.8, -- 軌跡を長めに残すとかっこいい
	},
	["BouncyAssaultRifle"] = {
		BulletSize = 1.0, -- 標準的な弾のサイズ
		BulletSpeed = 200, -- SMGより速く、スナイパーより遅い弾速
		BulletGravity = 0.1, -- 通常の重力
		BulletLife = 5,
		Bounciness = 0.6, -- 少しだけ跳ねる
		Damage = 15, -- 連射力が高いので1発のダメージは少し控えめ
		FireCooldown = 0.12, -- アサルトライフルらしい高速連射！
		MaxAmmo = 30, -- 定番の30発マガジン
		ReloadTime = 2.0, -- リロードにかかる時間
		BulletsPerShot = 1,
		SpreadAngle = 3, -- ほんの少しだけ弾がブレる（反動の表現）

		UseRandomColor = false,
		BulletColor = Color3.fromRGB(255, 150, 50), -- 例：オレンジ色の曳光弾
		TrailDuration = 0.4, -- 軌跡の長さ
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
