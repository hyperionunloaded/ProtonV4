--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "VulcanAimbot", category = "minigames",
	settings = { { id = "range", kind = "range", default = 500, min = 1, max = 1000 }, { id = "sort", kind = "drop", default = "Distance", options = { "Distance", "Damage", "Health" } }, { id = "players", kind = "toggle", default = true } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin)
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				local turret = ctx.entity.alive and ctx.bw.store:getState().Game.selectedTurret
				if turret then
					local origin = turret.Rotate.Position
					local ent = util.pickTarget(ctx, { origin = origin, range = plugin.state.range or 500, players = plugin.state.players ~= false, sort = plugin.state.sort or "Distance" })
					if ent then
						local delta = ent.root.Position - origin
						ctx.bw.TurretCameraController.angleX = math.atan2(-delta.X, -delta.Z)
						ctx.bw.TurretCameraController.angleY = math.clamp(math.atan2(delta.Y, math.sqrt(delta.X ^ 2 + delta.Z ^ 2)), -0.8, 0.8)
					end
				end
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin) plugin.state.alive = false end,
}
