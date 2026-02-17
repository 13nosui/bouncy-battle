local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local remoteEventName = "FireBullet"
local fireEvent = ReplicatedStorage:WaitForChild(remoteEventName)

-- クリックしたら発射
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end -- UIクリックなどは無視

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- サーバーに「マウスの指している場所」へ撃てと命令
		fireEvent:FireServer(mouse.Hit.Position)
	end
end)

print("Bouncy Battle Client Logic Loaded!")
