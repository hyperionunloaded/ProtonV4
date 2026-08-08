--proton-cache:build
﻿return {
	id = "AutoKrystal", category = "minigames", settings = {},
	init = function(ctx, plugin) plugin.state.old = nil end,
	enable = function(ctx, plugin)
		local ctrl = ctx.bw.GlacialSkaterController
		if not ctrl then return end
		plugin.state.old = ctrl.onJumpInput
		ctrl.onJumpInput = function(...) if plugin.enabled then return true end return plugin.state.old(...) end
	end,
	disable = function(ctx, plugin)
		local ctrl = ctx.bw.GlacialSkaterController
		if ctrl and plugin.state.old then ctrl.onJumpInput = plugin.state.old plugin.state.old = nil end
	end,
}
