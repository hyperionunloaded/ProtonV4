--proton-cache:build
﻿return {
	id = "AutoCyber", category = "minigames", settings = {},
	init = function(ctx, plugin) plugin.state.old = nil end,
	enable = function(ctx, plugin)
		local ctrl = ctx.bw.CyberController or ctx.bw.knit.Controllers.CyberController
		if not ctrl then return end
		if ctrl.startHackMinigame then
			plugin.state.old = ctrl.startHackMinigame
			ctrl.startHackMinigame = function(...) return true end
		elseif ctrl.completeHack then
			plugin.state.old = ctrl.completeHack
			ctrl.completeHack = function(...) return true end
		end
	end,
	disable = function(ctx, plugin)
		local ctrl = ctx.bw.CyberController or ctx.bw.knit.Controllers.CyberController
		if ctrl and plugin.state.old then
			if ctrl.startHackMinigame then ctrl.startHackMinigame = plugin.state.old
			elseif ctrl.completeHack then ctrl.completeHack = plugin.state.old end
			plugin.state.old = nil
		end
	end,
}
