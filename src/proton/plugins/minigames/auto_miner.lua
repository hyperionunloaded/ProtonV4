--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "AutoMiner", category = "minigames",
	settings = { { id = "range", kind = "range", default = 15, min = 1, max = 25 }, { id = "delay", kind = "range", default = 0.2, min = 0, max = 1, step = 0.01 } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin, host)
		local petrified = util.collection(ctx, host, "petrified-player")
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive then
					local pos = util.pos(ctx)
					for _, v in petrified do
						if v.PrimaryPart and (pos - v.PrimaryPart.Position).Magnitude <= (plugin.state.range or 15) then
							ctx.bw.fire("FreePetrifiedPlayer", { target = v })
							if (plugin.state.delay or 0) > 0 then task.wait(plugin.state.delay) end
						end
					end
				end
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin) plugin.state.alive = false end,
}
