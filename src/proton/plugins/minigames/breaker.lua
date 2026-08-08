--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "Breaker", category = "minigames",
	settings = { { id = "range", kind = "range", default = 20, min = 1, max = 40 }, { id = "bed", kind = "toggle", default = true }, { id = "autoTool", kind = "toggle", default = true } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin)
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive then
					local pos = util.pos(ctx)
					local store = ctx.bw.blockController:getStore()
					for x = -1, 1 do for y = -1, 1 do for z = -1, 1 do
						local blockPos = ctx.bw.blockController:getBlockPosition(pos) + Vector3.new(x, y, z)
						local block = store:getBlockAt(blockPos)
						if block and (not plugin.state.bed or block.Name == "bed") then
							if (blockPos * 3 - pos).Magnitude <= (plugin.state.range or 20) then
								task.spawn(ctx.bw.breakBlock, blockPos * 3, nil, nil, plugin.state.autoTool)
							end
						end
					end end end
				end
				task.wait(0.15)
			end
		end)
	end,
	disable = function(ctx, plugin) plugin.state.alive = false end,
}
