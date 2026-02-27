local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local cameraEvent = ReplicatedStorage:WaitForChild("CameraEvent", 5)
if not cameraEvent then
	-- エラー回避のためのダミー
	cameraEvent = Instance.new("RemoteEvent")
end

local DEFAULT_FOV = 70

if cameraEvent then
	cameraEvent.OnClientEvent:Connect(function(mode, targetChar)
		if not targetChar then
			return
		end
		local targetHum = targetChar:FindFirstChild("Humanoid")
		if not targetHum then
			return
		end

		if mode == "Kill" then
			-- === キルカメラ ===
			local originalSubject = camera.CameraSubject
			camera.CameraSubject = targetHum

			local tweenIn = TweenService:Create(camera, TweenInfo.new(0.5), { FieldOfView = 60 })
			tweenIn:Play()

			task.wait(1.5)

			if camera.CameraSubject == targetHum then
				if player.Character and player.Character:FindFirstChild("Humanoid") then
					camera.CameraSubject = player.Character.Humanoid
				end
				local tweenOut = TweenService:Create(camera, TweenInfo.new(0.5), { FieldOfView = DEFAULT_FOV })
				tweenOut:Play()
			end
		elseif mode == "Win" then
			-- === 勝利カメラ ===

			-- ★追加: 勝者が自分自身なら演出をスキップして終了
			if targetChar == player.Character then
				return
			end

			-- 他人が勝った場合はカメラを向ける
			camera.CameraSubject = targetHum

			local tween = TweenService:Create(
				camera,
				TweenInfo.new(3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
				{ FieldOfView = 40 }
			)
			tween:Play()
		end
	end)
end

-- === 1人称 / 3人称の切り替え処理 ===
local function updateCameraMode()
	local inMatch = player:GetAttribute("InMatch")
	local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")

	if inMatch then
		-- 試合中: 強制1人称
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		camera.CameraType = Enum.CameraType.Custom -- ★試合中は通常(Custom)に戻す

		-- カメラ位置とFOVを元に戻す
		if humanoid then
			humanoid.CameraOffset = Vector3.new(0, 0, 0)
		end
		TweenService:Create(camera, TweenInfo.new(0.5), { FieldOfView = 70 }):Play()
	else
		-- ロビー: 3人称
		player.CameraMode = Enum.CameraMode.Classic
		camera.CameraType = Enum.CameraType.Follow -- ★移動時にカメラが自動で背中を追うモード

		player.CameraMinZoomDistance = 10
		player.CameraMaxZoomDistance = 15

		-- カメラの注視点を「頭の上（Y軸に+2.5）」にズラす
		if humanoid then
			humanoid.CameraOffset = Vector3.new(0, 2.5, 0)
		end
		-- FOVを広げて空間を広く見せる
		TweenService:Create(camera, TweenInfo.new(0.5), { FieldOfView = 85 }):Play()
	end
end

-- InMatch属性が変更されたらカメラを切り替える
player:GetAttributeChangedSignal("InMatch"):Connect(updateCameraMode)

-- キャラクターがリスポーンした時にも適用する
player.CharacterAdded:Connect(function(char)
	task.wait(0.1) -- Humanoidのロード待ち
	updateCameraMode()
end)

-- 初期化
updateCameraMode()
