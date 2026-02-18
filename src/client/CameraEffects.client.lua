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
