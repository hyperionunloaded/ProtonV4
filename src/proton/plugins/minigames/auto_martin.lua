--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "AutoMartin", category = "minigames",
	settings = { { id = "range", kind = "range", default = 25, min = 1, max = 40 }, { id = "players", kind = "toggle", default = true } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin)
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive and ctx.bw.abilityController:canUseAbility("martin_shield", { disableBlockedAbilityAlert = true }) then
					local target = util.pickTarget(ctx, { range = plugin.state.range or 25, players = plugin.state.players ~= false })
					if target then ctx.bw.abilityController:useAbility("martin_shield", nil, { target = target.player }) end
				end
				task.wait(0.2)
			end
		end)
	end,
	disable = function(ctx, plugin) plugin.state.alive = false end,
}
