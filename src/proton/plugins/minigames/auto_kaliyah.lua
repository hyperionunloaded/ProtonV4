--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "AutoKaliyah", category = "minigames",
	settings = { { id = "range", kind = "range", default = 12, min = 1, max = 20 }, { id = "delay", kind = "range", default = 0.2, min = 0, max = 1, step = 0.01 } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin, host)
		local objs = util.collection(ctx, host, "KaliyahPunchInteraction")
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive then
					local pos = util.pos(ctx)
					for _, obj in objs do
						if obj.PrimaryPart and (pos - obj.PrimaryPart.Position).Magnitude <= (plugin.state.range or 12) then
							local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt")
							if prompt then fireproximityprompt(prompt) end
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
