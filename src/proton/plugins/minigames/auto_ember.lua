--proton-cache:build
local util = require(script.Parent.Parent.Parent.game.util)

return {
	id = "AutoEmber",
	category = "minigames",
	settings = {
		{ id = "range", kind = "range", default = 20, min = 1, max = 30 },
		{ id = "delay", kind = "range", default = 0.5, min = 0, max = 5, step = 0.05 },
		{ id = "players", kind = "toggle", default = true },
		{ id = "npcs", kind = "toggle", default = false },
		{ id = "limitItem", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.clock = 0
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin)
		plugin.state.alive = true
		plugin.state.clock = os.clock()
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				local tool = ctx.entity.alive and util.getItem(ctx, "infernal_saber")
				if tool and (plugin.state.limitItem == false or ctx.store.hand.tool == tool.tool) then
					local target = util.pickTarget(ctx, {
						range = plugin.state.range or 20,
						players = plugin.state.players ~= false,
						npcs = plugin.state.npcs ~= false,
					})
					if target and (plugin.state.delay or 0) <= os.clock() - plugin.state.clock then
						ctx.bw.fire("HellBladeRelease", { chargeTime = 1, weapon = tool, player = ctx.player })
						plugin.state.clock = os.clock()
					end
				end
				task.wait()
			end
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
	end,
}
