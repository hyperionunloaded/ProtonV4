--proton-cache:build
return {
	id = "EquipKit",
	category = "utility",
	settings = {
		{ id = "kit", kind = "drop", default = "None", options = { "None" } },
	},
	init = function(ctx, plugin)
		plugin.state.kitMap = {}
		local list = { "None" }
		for id, meta in ctx.bw.bedwarsKitMeta do
			if meta.name then
				plugin.state.kitMap[meta.name] = id
				list[#list + 1] = meta.name
			end
		end
		table.sort(list, function(a, b)
			if a == "None" then return true end
			if b == "None" then return false end
			return a < b
		end)
		for i, def in ipairs(plugin.settings) do
			if def.id == "kit" then
				plugin.settings[i].options = list
			end
		end
	end,
	enable = function(ctx, plugin, host)
		local kitName = plugin.state.kit or "None"
		local kitId = plugin.state.kitMap[kitName]
		if not kitId then
			host:disable("EquipKit")
			return
		end
		local ok = ctx.bw.call("BedwarsActivateKit", { kit = kitId })
		ctx.notify.push("EquipKit", ok and ("Equipped " .. kitName) or ("Failed to equip " .. kitName), ok and "info" or "alert")
		host:disable("EquipKit")
	end,
	disable = function(ctx, plugin) end,
}
