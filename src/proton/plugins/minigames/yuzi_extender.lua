--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "YuziExtender", category = "minigames",
	settings = { { id = "multiplier", kind = "range", default = 2, min = 1, max = 5, step = 0.1 } },
	init = function(ctx, plugin) plugin.state.old = nil end,
	enable = function(ctx, plugin)
		local ctrl = ctx.bw.DaoController
		if not ctrl then return end
		plugin.state.old = ctrl.dashForward
		ctrl.dashForward = function(self, direction)
			local ret = plugin.state.old(self, direction)
			local horizontal = direction and direction * Vector3.new(1, 0, 1) or Vector3.zero
			if ctx.store.equippedKit == "dasher" and ctx.entity.alive and horizontal.Magnitude > 0 then
				local root = ctx.entity.self.root
				root:ApplyImpulse(horizontal.Unit * root.AssemblyMass * ((plugin.state.multiplier or 2) - 1) * 70)
			end
			return ret
		end
	end,
	disable = function(ctx, plugin)
		local ctrl = ctx.bw.DaoController
		if ctrl and plugin.state.old then ctrl.dashForward = plugin.state.old plugin.state.old = nil end
	end,
}
