--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "AutoTriton", category = "minigames",
	settings = { { id = "legit", kind = "toggle", default = true }, { id = "back", kind = "toggle", default = false }, { id = "limitItem", kind = "toggle", default = true } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin)
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive and (plugin.state.limitItem == false or (ctx.store.hand.tool and ctx.store.hand.tool.Name == "harpoon")) then
					local target = util.pickTarget(ctx, { range = 40, players = true })
					if target and ctx.bw.abilityController:canUseAbility("triton_harpoon", { disableBlockedAbilityAlert = true }) then
						ctx.bw.abilityController:useAbility("triton_harpoon", nil, { targetPosition = target.root.Position })
					end
				end
				task.wait(0.2)
			end
		end)
	end,
	disable = function(ctx, plugin) plugin.state.alive = false end,
}
