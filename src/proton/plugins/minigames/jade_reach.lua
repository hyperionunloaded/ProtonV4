--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "JadeReach", category = "minigames",
	settings = { { id = "multiplier", kind = "range", default = 2, min = 1, max = 5, step = 0.1 } },
	init = function(ctx, plugin) plugin.state.old = nil end,
	enable = function(ctx, plugin)
		local ctrl = ctx.bw.JadeHammerController
		if not ctrl then return end
		plugin.state.old = ctrl.useJadeHammer
		ctrl.useJadeHammer = function(self)
			local jumped = ctx.bw.abilityController:canUseAbility("jade_hammer_jump", { disableBlockedAbilityAlert = true })
			local ret = plugin.state.old(self)
			if jumped and ctx.store.equippedKit == "jade" and ctx.entity.alive then
				local root = ctx.entity.self.root
				root:ApplyImpulse(Vector3.new(0, root.AssemblyMass * ((plugin.state.multiplier or 2) - 1) * 20.5, 0))
			end
			return ret
		end
	end,
	disable = function(ctx, plugin)
		local ctrl = ctx.bw.JadeHammerController
		if ctrl and plugin.state.old then ctrl.useJadeHammer = plugin.state.old plugin.state.old = nil end
	end,
}
