--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "AutoRamil", category = "minigames",
	settings = { { id = "range", kind = "range", default = 25, min = 1, max = 25 }, { id = "useTornado", kind = "toggle", default = true }, { id = "tornadoRange", kind = "range", default = 25, min = 1, max = 35 }, { id = "players", kind = "toggle", default = true } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin)
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive and ctx.store.equippedKit == "airbender" then
					local ent = util.pickTarget(ctx, { range = math.max(plugin.state.range or 25, plugin.state.tornadoRange or 25), players = plugin.state.players ~= false })
					if ent then
						local mag = (util.pos(ctx) - ent.root.Position).Magnitude
						if mag <= (plugin.state.range or 25) and ctx.bw.abilityController:canUseAbility("airbender_tornado", { disableBlockedAbilityAlert = true }) then
							ctx.bw.abilityController:useAbility("airbender_tornado")
						elseif plugin.state.useTornado and mag <= (plugin.state.tornadoRange or 25) and ctx.bw.abilityController:canUseAbility("airbender_moving_tornado", { disableBlockedAbilityAlert = true }) then
							ctx.bw.abilityController:useAbility("airbender_moving_tornado")
						end
					end
				end
				task.wait()
			end
		end)
	end,
	disable = function(ctx, plugin) plugin.state.alive = false end,
}
