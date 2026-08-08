--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "AutoMelody", category = "minigames",
	settings = { { id = "selfHeal", kind = "toggle", default = true }, { id = "teammateHeal", kind = "toggle", default = true }, { id = "range", kind = "range", default = 20, min = 1, max = 30 } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin)
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive and util.getItem(ctx, "melody_staff") then
					if plugin.state.selfHeal ~= false and ctx.entity.self.health / ctx.entity.self.maxHealth < 0.8 then
						ctx.bw.fire("MelodyHeal", { target = ctx.player })
					end
					if plugin.state.teammateHeal ~= false then
						for _, ent in ipairs(ctx.entity.list) do
							if ent.player and ent.player.Team == ctx.player.Team and ent.health / ent.maxHealth < 0.8 then
								if (util.pos(ctx) - ent.root.Position).Magnitude <= (plugin.state.range or 20) then
									ctx.bw.fire("MelodyHeal", { target = ent.player })
								end
							end
						end
					end
				end
				task.wait(0.3)
			end
		end)
	end,
	disable = function(ctx, plugin) plugin.state.alive = false end,
}
