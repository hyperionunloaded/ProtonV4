--proton-cache:build
﻿return {
	id = "WinEffect",
	category = "legit",
	settings = { { id = "effect", kind = "drop", default = "Default", options = { "Default" } } },
	init = function(ctx, plugin) plugin.state.nameToId = {} end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		local map = plugin.state.nameToId
		for id, v in bw.winEffectMeta do map[v.name] = id end
		host:track(ctx.events.on and ctx.events.on("match:end", function()
			local remote = bw.handler:Get("WinEffectTriggered").Remote.instance
			if remote and firesignal then
				for _, conn in getconnections(remote.OnClientEvent) do
					firesignal(remote.OnClientEvent, { effectType = map[plugin.state.effect] or "default" })
					break
				end
			end
		end) or { Disconnect = function() end })
	end,
	disable = function(ctx, plugin) end,
}
