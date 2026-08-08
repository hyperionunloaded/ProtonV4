--proton-cache:build
local util = require(script.Parent.Parent.Parent.game.util)

return {
	id = "AutoAdetunde",
	category = "minigames",
	settings = {
		{ id = "guiCheck", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin)
		local bw = ctx.bw
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if not plugin.state.guiCheck or bw.appController:isAppOpen("FrostyHammerApp") then
					for upgrade, level in bw.adetundeUtil.getUpgradesFromHammer(ctx.player) do
						local crystal = util.getItem(ctx, "frost_crystal")
						if not crystal then break end
						local nextTier = bw.adetundeUpgradeMeta[upgrade].tiers[level + 1]
						if nextTier and crystal.amount >= nextTier.price then
							bw.call("UpgradeFrostyHammer", upgrade)
							task.wait(0.1)
						end
					end
				end
				task.wait(0.5)
			end
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
	end,
}
