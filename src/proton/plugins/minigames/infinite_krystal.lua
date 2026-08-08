--proton-cache:build
﻿return {
	id = "InfiniteKrystal", category = "minigames", settings = {},
	init = function(ctx, plugin) plugin.state.old = nil end,
	enable = function(ctx, plugin)
		local ctrl = ctx.bw.GlacialSkaterController
		if not ctrl then return end
		plugin.state.old = ctrl.updateMomentum
		ctrl.updateMomentum = function(self, ...)
			self.momentum = 1000
			self.lastMomentumReport = workspace:GetServerTimeNow()
			return plugin.state.old(self, ...)
		end
	end,
	disable = function(ctx, plugin)
		local ctrl = ctx.bw.GlacialSkaterController
		if ctrl and plugin.state.old then ctrl.updateMomentum = plugin.state.old plugin.state.old = nil end
	end,
}
