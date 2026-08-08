--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "AutoGrim", category = "minigames",
	settings = { { id = "range", kind = "range", default = 20, min = 1, max = 30 }, { id = "delay", kind = "range", default = 0.2, min = 0, max = 1, step = 0.01 } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin, host)
		local ctrl = ctx.bw.GrimReaperController
		if not ctrl then return end
		local souls = util.collection(ctx, host, ctrl.soulsByPosition)
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive then
					local pos = util.pos(ctx)
					for _, soul in souls do
						if soul.PrimaryPart and (pos - soul.PrimaryPart.Position).Magnitude <= (plugin.state.range or 20) then
							ctx.bw.fire("CollectSoul", { soulId = soul:GetAttribute("SoulId") })
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
