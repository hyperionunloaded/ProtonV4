--proton-cache:build
﻿return {
	id = "AutoNoelle", category = "minigames",
	settings = { { id = "notify", kind = "toggle", default = true }, { id = "limitItem", kind = "toggle", default = false } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin)
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive and (plugin.state.limitItem == false or (ctx.store.hand.tool and ctx.store.hand.tool.Name:find("slime"))) then
					local ctrl = ctx.bw.NoelleController
					if ctrl and ctrl.directSlimes then pcall(ctrl.directSlimes, ctrl) end
				end
				task.wait(0.3)
			end
		end)
	end,
	disable = function(ctx, plugin) plugin.state.alive = false end,
}
