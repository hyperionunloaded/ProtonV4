--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "AutoPyro", category = "minigames",
	settings = { { id = "buyRange", kind = "toggle", default = true }, { id = "buyHeat", kind = "toggle", default = true }, { id = "buyPower", kind = "toggle", default = true } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin)
		local bw = ctx.bw
		local list = { range = "buyRange", heat = "buyHeat", power = "buyPower" }
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				local flamethrower = util.getItem(ctx, "flamethrower")
				if flamethrower and flamethrower.tool then
					for upgrade, toggle in list do
						if plugin.state[toggle] ~= false then
							local value = flamethrower.tool:GetAttribute(upgrade) or -1
							local nextTier = bw.pyroUpgradeMeta[upgrade].tiers[value + 2]
							if value < 3 and nextTier then
								local currency = util.getItem(ctx, nextTier.currency)
								if currency and currency.amount >= nextTier.price then
									bw.call("UpgradeFlamethrower", upgrade)
									task.wait(0.1)
								end
							end
						end
					end
				end
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin) plugin.state.alive = false end,
}
