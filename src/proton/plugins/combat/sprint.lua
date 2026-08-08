--proton-cache:build
return {
	id = "Sprint",
	category = "combat",
	settings = {},
	init = function(ctx, plugin)
		plugin.state._old = nil
	end,
	enable = function(ctx, plugin, host)
		local sprint = ctx.bw.sprintController
		local old = sprint.stopSprinting
		plugin.state._old = old
		sprint.stopSprinting = function(...)
			local ret = old(...)
			sprint:startSprinting()
			return ret
		end
		host:track(ctx.entity.events.localAdded:connect(function()
			task.delay(0.1, function()
				sprint:stopSprinting()
			end)
		end))
		sprint:stopSprinting()
	end,
	disable = function(ctx, plugin)
		local sprint = ctx.bw.sprintController
		if plugin.state._old then
			sprint.stopSprinting = plugin.state._old
			plugin.state._old = nil
		end
		sprint:stopSprinting()
	end,
}
