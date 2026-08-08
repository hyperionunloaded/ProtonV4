--proton-cache:build
﻿return {
	id = "FPSBoost",
	category = "legit",
	settings = { { id = "killEffects", kind = "toggle", default = true }, { id = "visualizer", kind = "toggle", default = true } },
	init = function(ctx, plugin) plugin.state.effects = {} plugin.state.util = {} end,
	enable = function(ctx, plugin)
		local bw = ctx.bw
		if plugin.state.killEffects ~= false then
			for i, v in bw.KillEffectController.killEffects do
				if not i:find("Custom") then
					plugin.state.effects[i] = v
					bw.KillEffectController.killEffects[i] = { new = function()
						return { onKill = function() end, isPlayDefaultKillEffect = function() return true end }
					end }
				end
			end
		end
		if plugin.state.visualizer ~= false then
			for i, v in bw.visualizerUtils do
				plugin.state.util[i] = v
				bw.visualizerUtils[i] = function() end
			end
		end
		if bw.NametagController then bw.NametagController.addGameNametag = function() end end
	end,
	disable = function(ctx, plugin)
		local bw = ctx.bw
		for i, v in plugin.state.effects do bw.KillEffectController.killEffects[i] = v end
		for i, v in plugin.state.util do bw.visualizerUtils[i] = v end
		table.clear(plugin.state.effects)
		table.clear(plugin.state.util)
	end,
}
