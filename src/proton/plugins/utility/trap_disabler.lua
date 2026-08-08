--proton-cache:build
return {
	id = "TrapDisabler",
	category = "utility",
	settings = {},
	init = function(ctx, plugin)
		plugin.state.oldGet = nil
	end,
	enable = function(ctx, plugin)
		local bw = ctx.bw
		local oldGet = bw.client.Get
		plugin.state.oldGet = oldGet
		bw.client.Get = function(self, remoteName)
			if remoteName == "StepOnSnapTrap" then
				return { SendToServer = function() end }
			end
			return oldGet(self, remoteName)
		end
	end,
	disable = function(ctx, plugin)
		if plugin.state.oldGet and ctx.bw then
			ctx.bw.client.Get = plugin.state.oldGet
			plugin.state.oldGet = nil
		end
	end,
}
