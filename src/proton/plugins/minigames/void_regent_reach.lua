--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "VoidRegentReach", category = "minigames",
	settings = { { id = "multiplier", kind = "range", default = 2, min = 1, max = 5, step = 0.1 } },
	init = function(ctx, plugin) plugin.state.old = nil end,
	enable = function(ctx, plugin)
		local ctrl = ctx.bw.VoidAxeController
		if not ctrl then return end
		plugin.state.old = ctrl.useVoidAxe
		ctrl.useVoidAxe = function(self)
			local dashed = ctx.bw.abilityController:canUseAbility("void_axe_jump", { disableBlockedAbilityAlert = true })
			local ret = plugin.state.old(self)
			if dashed and ctx.store.equippedKit == "regent" and ctx.entity.alive then
				local root = ctx.entity.self.root
				root:ApplyImpulse(root.CFrame.LookVector * Vector3.new(1, 0, 1) * root.AssemblyMass * ((plugin.state.multiplier or 2) - 1) * 70)
			end
			return ret
		end
	end,
	disable = function(ctx, plugin)
		local ctrl = ctx.bw.VoidAxeController
		if ctrl and plugin.state.old then ctrl.useVoidAxe = plugin.state.old plugin.state.old = nil end
	end,
}
