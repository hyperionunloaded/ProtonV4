--proton-cache:build
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return {
	id = "InfiniteBlock",
	category = "blatant",
	settings = {},
	init = function(ctx, plugin)
		plugin.state.old = nil
	end,
	enable = function(ctx, plugin)
		local ok, BlockPlacer = pcall(function()
			return require(ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["block-engine"].out.client.placement["block-placer"]).BlockPlacer
		end)
		if not ok or not BlockPlacer then return end
		plugin.state.old = BlockPlacer.placeBlock
		BlockPlacer.placeBlock = function(self, blockPos, ...)
			local blockType = self.blockType
			local saved
			local inv = ctx.bw.getInventory(ctx.player)
			for _, item in inv.items do
				if item.itemType == blockType then
					saved = item.amount
					break
				end
			end
			local result = plugin.state.old(self, blockPos, ...)
			if saved then
				for _, item in inv.items do
					if item.itemType == blockType and item.amount < saved then
						item.amount = saved
						break
					end
				end
			end
			return result
		end
	end,
	disable = function(ctx, plugin)
		if not plugin.state.old then return end
		local ok, BlockPlacer = pcall(function()
			return require(ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["block-engine"].out.client.placement["block-placer"]).BlockPlacer
		end)
		if ok and BlockPlacer then
			BlockPlacer.placeBlock = plugin.state.old
		end
		plugin.state.old = nil
	end,
}
