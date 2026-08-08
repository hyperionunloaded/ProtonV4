--proton-cache:build
return {
	id = "SetSettings",
	category = "utility",
	settings = {},
	init = function(ctx, plugin)
		plugin.state.snapshot = {}
		local settings = ctx.bw.settingsController.settings or {}
		for key, val in settings do
			plugin.state[key] = val
			local meta = ctx.bw.settingsMeta[key]
			if meta and meta.tab ~= "Mobile" then
				local kind = typeof(val) == "boolean" and "toggle" or typeof(val) == "number" and "range" or nil
				if kind then
					plugin.settings[#plugin.settings + 1] = {
						id = key,
						kind = kind,
						label = meta.name or key,
						default = val,
						min = 1,
						max = 360,
						step = kind == "range" and 1 or nil,
					}
				end
			end
		end
	end,
	enable = function(ctx, plugin)
		local ctrl = ctx.bw.settingsController
		plugin.state.snapshot = table.clone(ctrl.settings or {})
		for key, val in plugin.state do
			if key ~= "snapshot" and ctrl.settings[key] ~= nil then
				ctrl:setSetting(key, val)
			end
		end
	end,
	disable = function(ctx, plugin)
		local ctrl = ctx.bw.settingsController
		for key, val in plugin.state.snapshot or {} do
			ctrl:setSetting(key, val)
		end
		table.clear(plugin.state.snapshot)
	end,
}
