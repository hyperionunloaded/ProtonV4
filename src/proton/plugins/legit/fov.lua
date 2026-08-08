--proton-cache:build
﻿return {
	id = "FOV",
	category = "legit",
	settings = { { id = "value", kind = "range", default = 70, min = 30, max = 120 } },
	init = function(ctx, plugin) plugin.state.old = nil plugin.state.old2 = nil end,
	enable = function(ctx, plugin)
		local ctrl = ctx.bw.FovController
		if not ctrl then return end
		plugin.state.old = ctrl.setFOV
		plugin.state.old2 = ctrl.getFOV
		local val = plugin.state.value or 70
		ctrl.setFOV = function(self) return plugin.state.old(self, val) end
		ctrl.getFOV = function() return val end
		ctrl:setFOV(ctx.bw.store:getState().Settings.fov)
	end,
	disable = function(ctx, plugin)
		local ctrl = ctx.bw.FovController
		if ctrl and plugin.state.old then
			ctrl.setFOV = plugin.state.old
			ctrl.getFOV = plugin.state.old2
			plugin.state.old = nil
		end
	end,
}
