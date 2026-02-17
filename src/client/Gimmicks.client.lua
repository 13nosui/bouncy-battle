local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- === 設定値 ===
local WIND_FORCE_BULLET = 10.0
local WIND_FORCE_PLAYER = 10.0
local ZONE_TAG = "WindZone"

RunService.Heartbeat:Connect(function(deltaTime)
	-- タグが付いているすべてのWindZoneを取得
	local windZones = CollectionService:GetTagged(ZONE_TAG)

	for _, zone in ipairs(windZones) do
		-- ゾーンの体積内にあるパーツをすべて検出
		local partsInZone = Workspace:GetPartsInPart(zone)
		local windDirection = zone.CFrame.LookVector

		for _, part in ipairs(partsInZone) do
			-- ■ 自分の弾、または自分が所有権を持つ弾にだけ影響を与える
			-- Robloxの物理エンジンは、自分が所有していないパーツへの速度変更を自動的に無視してくれるため、
			-- 実は単純に「全ての弾」に対して処理を書いてしまっても、自分の弾だけが動くようになります。

			if part.Name == "RubberBullet" then
				part.AssemblyLinearVelocity += windDirection * WIND_FORCE_BULLET

			-- ■ 自分自身（キャラクター）への風
			elseif part.Parent == player.Character and part.Name == "HumanoidRootPart" then
				part.AssemblyLinearVelocity += windDirection * WIND_FORCE_PLAYER
			end
		end
	end
end)

print("Client Gimmick System Loaded: Wind active")
