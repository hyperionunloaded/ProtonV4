--proton-cache:build
﻿return {
	id = "Interface",
	category = "legit",
	settings = {
		{ id = "healthFont", kind = "drop", default = "LuckiestGuy", options = { "LuckiestGuy", "GothamBold", "Arial" } },
		{ id = "healthHue", kind = "range", default = 0.33, min = 0, max = 1, step = 0.01 },
		{ id = "hotbarHue", kind = "range", default = 0, min = 0, max = 1, step = 0.01 },
		{ id = "hotbarOpacity", kind = "range", default = 0.8, min = 0, max = 1, step = 0.05 },
	},
	init = function(ctx, plugin) plugin.state.old = {} plugin.state.new = {} end,
	enable = function(ctx, plugin) end,
	disable = function(ctx, plugin)
		for func, vals in plugin.state.old do
			for idx, val in vals do pcall(debug.setconstant, func, idx, val) end
		end
		table.clear(plugin.state.old)
		table.clear(plugin.state.new)
	end,
}
