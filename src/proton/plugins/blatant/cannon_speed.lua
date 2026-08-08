--proton-cache:build
return {
	id = "CannonSpeed",
	category = "blatant",
	settings = {
		{ id = "speed", kind = "range", default = 200, min = 1, max = 400 },
	},
	init = function(ctx, plugin)
		plugin.state.legit = 200
	end,
	enable = function(ctx, plugin, host)
		local ctrl = ctx.bw.CannonHandController
		if not ctrl or not ctrl.launchSelf then return end
		debug.setconstant(ctrl.launchSelf, 15, host:get(plugin, "speed", 200))
	end,
	disable = function(ctx, plugin)
		local ctrl = ctx.bw.CannonHandController
		if ctrl and ctrl.launchSelf then
			debug.setconstant(ctrl.launchSelf, 15, plugin.state.legit)
		end
	end,
}
