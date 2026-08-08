--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "AutoHannah", category = "minigames",
	settings = { { id = "range", kind = "range", default = 15, min = 1, max = 25 }, { id = "players", kind = "toggle", default = true } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin, host)
		local objs = util.collection(ctx, host, "HannahExecuteInteraction")
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive then
					local pos = util.pos(ctx)
					for _, obj in objs do
						if obj.PrimaryPart and (pos - obj.PrimaryPart.Position).Magnitude <= (plugin.state.range or 15) then
							local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt")
							if prompt then fireproximityprompt(prompt) end
						end
					end
				end
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin) plugin.state.alive = false end,
}
