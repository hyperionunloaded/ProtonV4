--proton-cache:build
﻿return {
	id = "AutoVanessa", category = "minigames", settings = {},
	init = function(ctx, plugin) plugin.state.old = nil plugin.state.overcharge = nil end,
	enable = function(ctx, plugin)
		local ctrl = ctx.bw.TripleShotProjectileController
		if not ctrl then return end
		plugin.state.old = ctrl.getChargeTime
		plugin.state.overcharge = ctrl.overchargeStartTime
		ctrl.getChargeTime = function() return 0 end
		ctrl.overchargeStartTime = tick()
	end,
	disable = function(ctx, plugin)
		local ctrl = ctx.bw.TripleShotProjectileController
		if ctrl and plugin.state.old then
			ctrl.getChargeTime = plugin.state.old
			ctrl.overchargeStartTime = plugin.state.overcharge
			plugin.state.old = nil
		end
	end,
}
