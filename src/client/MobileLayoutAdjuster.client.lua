local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local BTN_SIZE = 65
local SPACING = 85
local BASE_OFFSET_X = -180
local BASE_OFFSET_Y = -140

-- ★変更: ボタンが重ならないように座標(relX, relY)を綺麗に並べ替えました
local CONTROLS = {
	{ action = "SprintAction", label = "DASH", relX = 0, relY = 0 },
	{ action = "CrouchAction", label = "SLIDE", relX = 1, relY = 0 },

	-- 射撃／建築系（右下寄り）
	{ action = "FireAction", label = "FIRE", relX = 0, relY = -1 },
	{ action = "ReloadOrRotateAction", label = "RLD", relX = -1, relY = -1 },
	{ action = "DestroyAction", label = "BREAK", relX = -2, relY = -1 },

	-- 切り替え系（中央寄り）
	{ action = "ToggleShapeAction", label = "SHAPE", relX = 0, relY = -2 },
	{ action = "ToggleColorAction", label = "COLOR", relX = -1, relY = -2 },
	{ action = "ToggleMaterialAction", label = "MAT", relX = -2, relY = -2 },

	-- システム系（右上寄り）
	{ action = "SaveAction", label = "SAVE", relX = 1, relY = -1 },
	{ action = "LoadAction", label = "LOAD", relX = 1, relY = -2 },
	{ action = "PublishAction", label = "PUBLISH", relX = 1, relY = -3 },

	-- ★追加: 超能力ボタン（左下寄り）
	{ action = "AbilityAction", label = "ABILITY", relX = -1, relY = 0 },
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
			local x = BASE_OFFSET_X + (ctrl.relX * SPACING)
			local y = BASE_OFFSET_Y + (ctrl.relY * SPACING)

			btn.Position = UDim2.new(1, x, 1, y)
			btn.Size = UDim2.new(0, BTN_SIZE, 0, BTN_SIZE)
			btn.AnchorPoint = Vector2.new(0.5, 0.5)
			btn.Style = Enum.ButtonStyle.Custom
			btn.Image = ""
			btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			btn.BackgroundTransparency = 0.4

			local corner = btn:FindFirstChildOfClass("UICorner")
			if not corner then
				corner = Instance.new("UICorner")
				corner.Parent = btn
			end
			corner.CornerRadius = UDim.new(0.5, 0)

			ContextActionService:SetTitle(ctrl.action, ctrl.label)
			local titleLabel = btn:FindFirstChild("ActionTitle")
			if titleLabel then
				titleLabel.Font = Enum.Font.GothamBold
				titleLabel.TextColor3 = Color3.new(1, 1, 1)
				titleLabel.TextScaled = true
				titleLabel.Size = UDim2.new(0.7, 0, 0.35, 0)
				titleLabel.Position = UDim2.new(0.15, 0, 0.325, 0)
				titleLabel.TextTransparency = 0
				titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
				titleLabel.TextStrokeTransparency = 0.5
				titleLabel.ZIndex = 1001
			end

			-- ★変更: ガンとビルドツールでの表示切り替えを最適化
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
