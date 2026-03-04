-- src/server/Monetization.server.lua
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ★★★ 自分の作ったIDに書き換えること！！！ ★★★
local VIP_PASS_ID = 1737228731 -- ここを Game PassのID にする
local COIN_PRODUCT_ID = 3549354609 -- ここを Developer ProductのID にする

-- クライアントへの通信イベント
local purchaseEvent = Instance.new("RemoteEvent")
purchaseEvent.Name = "PurchaseEvent"
purchaseEvent.Parent = ReplicatedStorage

-- ①：VIPパスを持っているかどうかの確認（入室時と購入時に実行）
local function checkVIP(player)
	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_PASS_ID)
	end)

	if success and hasPass then
		-- 持っていたら、VIP専用のマークと機能を付ける
		player:SetAttribute("IsVIP", true)
		print(player.Name .. " は VIPプレイヤーです！")
	end
end

-- ②：アイテム（コイン）が購入された時の処理
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- 買われた商品が「コイン購入」だったら
	if receiptInfo.ProductId == COIN_PRODUCT_ID then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats and leaderstats:FindFirstChild("Coins") then
			leaderstats.Coins.Value = leaderstats.Coins.Value + 500 -- 500コイン付与！
			print(player.Name .. " が 500 Coins を購入しました！")
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

Players.PlayerAdded:Connect(function(player)
	checkVIP(player)
end)

-- ③：UIから「買いたい！」とリクエストが来た時の処理
purchaseEvent.OnServerEvent:Connect(function(player, itemType)
	if itemType == "VIP" then
		MarketplaceService:PromptGamePassPurchase(player, VIP_PASS_ID)
	elseif itemType == "Coin" then
		MarketplaceService:PromptProductPurchase(player, COIN_PRODUCT_ID)
	end
end)

-- ④：VIPパスを今買った瞬間にVIPを有効化する
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if passId == VIP_PASS_ID and wasPurchased then
		checkVIP(player)
	end
end)