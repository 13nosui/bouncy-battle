-- src/client/MobileLayoutAdjuster.client.lua
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- ★変更: スキル枠(SkillQAction, SkillZAction)を追加し、右下(AnchorPoint: 1, 1)からの絶対オフセットでアーチ状に配置
local CONTROLS = {
	-- 射撃とリロード (親指のホームポジション近く)
	{ action = "FireAction", label = "FIRE", posX = -120, posY = -120, size = 80 },
	{ action = "ReloadOrRotateAction", label = "RLD", posX = -210, posY = -90, size = 60 },

	-- 移動系 (ジャンプボタンの左から上へ円弧を描く)
	{ action = "CrouchAction", label = "SLIDE", posX = -170, posY = -180, size = 65 },
	{ action = "SprintAction", label = "DASH", posX = -80, posY = -220, size = 65 },

	-- ★追加: スキルボタン (スロット3と4)
	{ action = "SkillQAction", label = "SKILL 1", posX = -260, posY = -130, size = 60 },
	{ action = "SkillZAction", label = "SKILL 2", posX = -260, posY = -210, size = 60 },

	-- 建築系 (射撃ボタン周りに被らないよう、さらに奥へ配置)
	{ action = "DestroyAction", label = "BREAK", posX = -180, posY = -270, size = 60 },
	{ action = "ToggleShapeAction", label = "SHAPE", posX = -250, posY = -270, size = 60 },
	{ action = "ToggleColorAction", label = "COLOR", posX = -320, posY = -270, size = 60 },
	{ action = "ToggleMaterialAction", label = "MAT", posX = -390, posY = -270, size = 60 },

	-- システム系 (画面上部寄り)
	{ action = "SaveAction", label = "SAVE", posX = -320, posY = -90, size = 50 },
	{ action = "LoadAction", label = "LOAD", posX = -380, posY = -90, size = 50 },
	{ action = "PublishAction", label = "PUBLISH", posX = -440, posY = -90, size = 50 },
}

local function updateLayout()
	if not UserInputService.TouchEnabled then
		return
	end

	local isReady = player:GetAttribute("IsReady")
	local char = player.Character
	local hasGun = char and char:FindFirstChild("BouncyGun") ~= nil
	local hasBuild = char and char:FindFirstChild("BuildTool") ~= nil

	for _, ctrl in ipairs(CONTROLS) do
		local btn = ContextActionService:GetButton(ctrl.action)
		if btn then
			-- 位置とサイズの適用
			btn.Position = UDim2.new(1, ctrl.posX, 1, ctrl.posY)
			btn.Size = UDim2.new(0, ctrl.size, 0, ctrl.size)
			btn.AnchorPoint = Vector2.new(0.5, 0.5)

			btn.Style = Enum.ButtonStyle.Custom
			btn.Image = ""
			-- ★変更: ボタンの視認性を高める
			btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			btn.BackgroundTransparency = 0.5

			local corner = btn:FindFirstChildOfClass("UICorner")
			if not corner then
				corner = Instance.new("UICorner")
				corner.Parent = btn
			end
			corner.CornerRadius = UDim.new(0.5, 0)

			-- ★超重要変更: ContextActionServiceのデフォルトタイトルは不安定なため、確実に自前でラベルを被せる
			local customLabelName = "CustomActionTitle"
			local titleLabel = btn:FindFirstChild(customLabelName)
			if not titleLabel then
				titleLabel = Instance.new("TextLabel")
				titleLabel.Name = customLabelName
				titleLabel.Parent = btn
				titleLabel.Font = Enum.Font.GothamBold
				titleLabel.TextColor3 = Color3.new(1, 1, 1)
				titleLabel.TextScaled = true
				-- ボタンの中心に配置
				titleLabel.Size = UDim2.new(0.8, 0, 0.4, 0)
				titleLabel.Position = UDim2.new(0.1, 0, 0.3, 0)
				titleLabel.BackgroundTransparency = 1
				titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
				titleLabel.TextStrokeTransparency = 0.5
				titleLabel.ZIndex = 1001
			end
			titleLabel.Text = ctrl.label

			-- 表示の切り替え
			if not isReady then
				btn.Visible = false
			elseif ctrl.action == "FireAction" or ctrl.action == "ReloadOrRotateAction" then
				btn.Visible = hasGun or hasBuild
			elseif
				ctrl.action == "DestroyAction"
				or ctrl.action == "ToggleShapeAction"
				or ctrl.action == "ToggleColorAction"
				or ctrl.action == "ToggleMaterialAction"
				or ctrl.action == "SaveAction"
				or ctrl.action == "LoadAction"
				or ctrl.action == "PublishAction"
			then
				btn.Visible = hasBuild
			else
				btn.Visible = true
			end

			btn.ZIndex = 1000
		end
	end
end

RunService.RenderStepped:Connect(updateLayout)
