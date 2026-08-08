--proton-cache:build
﻿return {
	id = "AutoHephaestus", category = "minigames", settings = {},
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin, host)
		local ctrl = ctx.bw.HephaestusController
		if not ctrl then return end
		plugin.state.alive = true
		host:track(game:GetService("RunService").Heartbeat:Connect(function()
			if plugin.enabled and ctx.entity.alive and ctrl.autoForge then pcall(ctrl.autoForge, ctrl) end
		end))
	end,
	disable = function(ctx, plugin) plugin.state.alive = false end,
}
