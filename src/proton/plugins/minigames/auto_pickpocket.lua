--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "AutoPickpocket", category = "minigames",
	settings = { { id = "range", kind = "range", default = 25, min = 1, max = 30 }, { id = "players", kind = "toggle", default = true } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin)
		local remote = ctx.bw.handler:Get("MimicBlockPickPocketPlayer")
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive then
					for _, ent in util.allTargets(ctx, { range = plugin.state.range or 25, players = plugin.state.players ~= false }) do
						if ent.player then remote:Fire("CallServer", ent.player) end
					end
				end
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin) plugin.state.alive = false end,
}
