--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "AutoUma", category = "minigames",
	settings = { { id = "range", kind = "range", default = 20, min = 1, max = 30 }, { id = "autoSummon", kind = "toggle", default = true }, { id = "healSpirit", kind = "toggle", default = true }, { id = "attackSpirit", kind = "toggle", default = true } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin, host)
		local drops = util.collection(ctx, host, "ItemDrop")
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive then
					local pos = util.pos(ctx)
					if plugin.state.autoSummon ~= false and ctx.bw.abilityController:canUseAbility("uma_summon", { disableBlockedAbilityAlert = true }) then
						ctx.bw.abilityController:useAbility("uma_summon")
					end
					for _, drop in drops do
						if drop.PrimaryPart and (pos - drop.PrimaryPart.Position).Magnitude <= (plugin.state.range or 20) then
							ctx.bw.fire("CollectSpiritItem", { itemDrop = drop })
						end
					end
				end
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin) plugin.state.alive = false end,
}
