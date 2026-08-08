--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "AutoMarina", category = "minigames",
	settings = { { id = "range", kind = "range", default = 20, min = 1, max = 30 } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin, host)
		local jellies = util.collection(ctx, host, "jellyfish", function(tab, obj)
			if obj.PrimaryPart then tab[#tab+1] = obj end
		end)
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive then
					local pos = util.pos(ctx)
					for _, v in jellies do
						if v.PrimaryPart and (pos - v.PrimaryPart.Position).Magnitude <= (plugin.state.range or 20) then
							ctx.bw.fire("CatchJellyfish", { jellyfish = v })
						end
					end
				end
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin) plugin.state.alive = false end,
}
