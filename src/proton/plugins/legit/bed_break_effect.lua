--proton-cache:build
﻿return {
	id = "BedBreakEffect",
	category = "legit",
	settings = { { id = "effect", kind = "drop", default = "Default", options = { "Default" } } },
	init = function(ctx, plugin) plugin.state.nameToId = {} end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		local names, map = {}, plugin.state.nameToId
		for id, v in bw.bedBreakEffectMeta do names[#names+1] = v.name map[v.name] = id end
		table.sort(names)
		if names[1] then plugin.state.effect = names[1] end
		host:track(ctx.events.on and ctx.events.on("bed:break", function(data)
			local remote = bw.handler:Get("BedBreakEffectTriggered").Remote.instance
			if remote and firesignal then
				firesignal(remote.OnClientEvent, {
					player = data.player,
					position = data.bedBlockPosition * 3,
					effectType = map[plugin.state.effect] or map[names[1]],
					teamId = data.brokenBedTeam and data.brokenBedTeam.id,
					centerBedPosition = data.bedBlockPosition * 3,
				})
			end
		end) or { Disconnect = function() end })
	end,
	disable = function(ctx, plugin) end,
}
