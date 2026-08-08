--proton-cache:build
﻿return {
	id = "DamageIndicator",
	category = "legit",
	settings = {
		{ id = "font", kind = "drop", default = "GothamBold", options = { "GothamBold", "Arial", "Arcade" } },
		{ id = "size", kind = "range", default = 32, min = 1, max = 32 },
		{ id = "anchor", kind = "range", default = 0, min = 0, max = 1, step = 0.1 },
		{ id = "stroke", kind = "toggle", default = true },
		{ id = "hue", kind = "range", default = 0, min = 0, max = 1, step = 0.01 },
	},
	init = function(ctx, plugin)
		local ok, tab = pcall(function() return debug.getupvalue(ctx.bw.DamageIndicatorController.spawnDamageIndicator or ctx.bw.DamageIndicator, 2) end)
		plugin.state.tab = ok and tab or {}
		plugin.state.old = {}
	end,
	enable = function(ctx, plugin)
		local fn = ctx.bw.DamageIndicatorController and ctx.bw.DamageIndicatorController.spawnDamageIndicator
		if not fn then return end
		local tab = plugin.state.tab
		plugin.state.old = table.clone(tab)
		tab.textSize = plugin.state.size or 32
		tab.blowUpSize = plugin.state.size or 32
		tab.blowUpDuration = 0
		tab.blowUpCompleteDuration = 0
		tab.anchoredDuration = plugin.state.anchor or 0
		tab.baseColor = Color3.fromHSV(plugin.state.hue or 0, 1, 1)
		tab.strokeThickness = plugin.state.stroke ~= false and 1 or false
	end,
	disable = function(ctx, plugin)
		for k, v in plugin.state.old do plugin.state.tab[k] = v end
	end,
}
