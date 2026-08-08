--proton-cache:build
return {
	id = "FastPlace",
	category = "world",
	settings = {
		{ id = "cps", kind = "range", default = 13, min = 1, max = 100 },
	},
	init = function(ctx, plugin)
		plugin.state.oldCps = nil
	end,
	enable = function(ctx, plugin)
		local sc = ctx.bw.sharedConstants
		plugin.state.oldCps = sc.BLOCK_PLACE_CPS
		sc.BLOCK_PLACE_CPS = plugin.state.cps or 13
	end,
	disable = function(ctx, plugin)
		if plugin.state.oldCps and ctx.bw then
			ctx.bw.sharedConstants.BLOCK_PLACE_CPS = plugin.state.oldCps
			plugin.state.oldCps = nil
		end
	end,
}
