--proton-cache:build
﻿return {
	id = "AutoLani", category = "minigames",
	settings = { { id = "useEnemy", kind = "toggle", default = true }, { id = "delay", kind = "range", default = 0.5, min = 0, max = 5, step = 0.05 } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin)
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive and ctx.bw.abilityController:canUseAbility("lani_swap", { disableBlockedAbilityAlert = true }) then
					ctx.bw.abilityController:useAbility("lani_swap")
					task.wait(plugin.state.delay or 0.5)
				end
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin) plugin.state.alive = false end,
}
