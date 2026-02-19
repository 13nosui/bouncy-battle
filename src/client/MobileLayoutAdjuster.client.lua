local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- === 設定：右下基準の固定レイアウト ===
local BTN_SIZE = 65
local SPACING = 85
local BASE_OFFSET_X = -180
local BASE_OFFSET_Y = -140

local CONTROLS = {
	{ action = "SprintAction", label = "DASH", relX = 0, relY = 0 },
	{ action = "FireAction", label = "FIRE", relX = 0, relY = -1 },
	{ action = "ReloadAction", label = "RLD", relX = -1, relY = 0 },
	{ action = "CrouchAction", label = "SLIDE", relX = 1, relY = 0 },
}

local function updateLayout()
	if not UserInputService.TouchEnabled then
		return
	end

	-- 状態の取得
	local isReady = player:GetAttribute("IsReady")
	local hasGun = false
	if player.Character and player.Character:FindFirstChild("BouncyGun") then
		hasGun = true
	end

	for _, ctrl in ipairs(CONTROLS) do
		local btn = ContextActionService:GetButton(ctrl.action)

		if btn then
			-- 座標とサイズ
			local x = BASE_OFFSET_X + (ctrl.relX * SPACING)
			local y = BASE_OFFSET_Y + (ctrl.relY * SPACING)

			btn.Position = UDim2.new(1, x, 1, y)
			btn.Size = UDim2.new(0, BTN_SIZE, 0, BTN_SIZE)
			btn.AnchorPoint = Vector2.new(0.5, 0.5)

			-- デザインのモダン化
			btn.Style = Enum.ButtonStyle.Custom
			btn.Image = ""
			btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			btn.BackgroundTransparency = 0.4

			-- 丸くする
			local corner = btn:FindFirstChildOfClass("UICorner")
			if not corner then
				corner = Instance.new("UICorner")
				corner.Parent = btn
			end
			corner.CornerRadius = UDim.new(0.5, 0)

			-- タイトル設定
			ContextActionService:SetTitle(ctrl.action, ctrl.label)
			local titleLabel = btn:FindFirstChild("ActionTitle")
			if titleLabel then
				titleLabel.Font = Enum.Font.GothamBold
				titleLabel.TextColor3 = Color3.new(1, 1, 1)
				titleLabel.TextScaled = true
				titleLabel.Size = UDim2.new(0.7, 0, 0.35, 0)
				titleLabel.Position = UDim2.new(0.15, 0, 0.325, 0)

				-- ★追加: 文字をくっきりさせる設定
				titleLabel.TextTransparency = 0 -- 文字自体は全く透かさない
				titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0) -- 黒い縁取り
				titleLabel.TextStrokeTransparency = 0.5 -- 縁取りを少しつける
				titleLabel.ZIndex = 1001 -- 背景(1000)より手前に
			end

			-- 表示/非表示のコントロール
			if not isReady then
				btn.Visible = false
			elseif ctrl.action == "FireAction" or ctrl.action == "ReloadAction" then
				btn.Visible = hasGun
			else
				btn.Visible = true
			end

			btn.ZIndex = 1000
		end
	end
end

RunService.RenderStepped:Connect(updateLayout)

print("Client: Mobile Layout Adjuster Loaded (Final Polish)")
