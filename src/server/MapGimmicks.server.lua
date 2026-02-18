local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local TAG_KILL = "KillBlock"

local function setupKillBlock(part)
	part.Touched:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid and humanoid.Health > 0 then
			-- 即死させる
			humanoid.Health = 0
		end
	end)
end

-- 既存のパーツに適用
for _, part in ipairs(CollectionService:GetTagged(TAG_KILL)) do
	setupKillBlock(part)
end

-- 後から追加されたパーツにも適用
CollectionService:GetInstanceAddedSignal(TAG_KILL):Connect(setupKillBlock)

print("Server MapGimmicks Loaded")
