--proton-cache:build
﻿return {
	id = "AutoNyx", category = "minigames",
	settings = { { id = "players", kind = "toggle", default = true } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin, host)
		plugin.state.alive = true
		host:track(ctx.events.on and ctx.events.on("entity:damage", function(data)
			if data.fromEntity == ctx.player.Character and data.entityInstance then
				ctx.bw.fire("NyxMark", { target = data.entityInstance })
			end
		end) or { Disconnect = function() end })
	end,
	disable = function(ctx, plugin) plugin.state.alive = false end,
}
