--proton-cache:build
﻿return {
	id = "Crosshair",
	category = "legit",
	settings = { { id = "image", kind = "text", default = "" } },
	init = function(ctx, plugin) plugin.state.old = nil end,
	enable = function(ctx, plugin)
		local ctrl = ctx.bw.ViewmodelController
		if not ctrl or not ctrl.showCrosshair then return end
		plugin.state.old = debug.getconstant(ctrl.showCrosshair, 25)
		local img = plugin.state.image or plugin.state.old
		debug.setconstant(ctrl.showCrosshair, 25, img)
		debug.setconstant(ctrl.showCrosshair, 37, img)
		if ctrl.crosshair then ctrl:hideCrosshair() ctrl:showCrosshair() end
	end,
	disable = function(ctx, plugin)
		local ctrl = ctx.bw.ViewmodelController
		if ctrl and plugin.state.old then
			debug.setconstant(ctrl.showCrosshair, 25, plugin.state.old)
			debug.setconstant(ctrl.showCrosshair, 37, plugin.state.old)
			plugin.state.old = nil
		end
	end,
}
