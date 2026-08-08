--proton-cache:build
return {
	id = "SkinChanger",
	category = "render",
	settings = {
		{ id = "wood_sword", kind = "drop", default = "None", options = { "None" } },
		{ id = "stone_sword", kind = "drop", default = "None", options = { "None" } },
		{ id = "iron_sword", kind = "drop", default = "None", options = { "None" } },
		{ id = "diamond_sword", kind = "drop", default = "None", options = { "None" } },
		{ id = "wood_bow", kind = "drop", default = "None", options = { "None" } },
		{ id = "iron_bow", kind = "drop", default = "None", options = { "None" } },
	},
	init = function(ctx, plugin)
		plugin.state.lookup = {}
		plugin.state.labels = {}
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		local Players = game:GetService("Players")
		local localPlayer = Players.LocalPlayer

		local function prettify(text)
			return (text:gsub("_", " "):gsub("%a+", function(word)
				return word:sub(1, 1):upper() .. word:sub(2)
			end))
		end

		local function labelFor(itemType, skin)
			local token = "_" .. skin .. "_"
			for word in itemType:gmatch("[^_]+") do
				token = token:gsub("_" .. word .. "_", "_")
			end
			token = token:gsub("^_+", ""):gsub("_+$", "")
			if token == "" then
				return prettify(skin)
			end
			return prettify(token)
		end

		local skins = {}
		for _, skin in bw.itemSkinTypes do
			local meta = bw.getItemSkinMeta(skin)
			local item = meta and meta.itemType and bw.itemMeta[meta.itemType]
			if item and not item.block then
				skins[meta.itemType] = skins[meta.itemType] or {}
				skins[meta.itemType][labelFor(meta.itemType, skin)] = skin
			end
		end

		for itemType, map in pairs(skins) do
			plugin.state.lookup[itemType] = map
		end

		local function chosen(itemType)
			local key = itemType:gsub("-", "_")
			local pick = plugin.state[key] or plugin.state[itemType]
			if not pick or pick == "None" then return nil end
			local map = plugin.state.lookup[itemType]
			return map and map[pick] or nil
		end

		local function apply()
			local inv = ctx.store.inventory and ctx.store.inventory.inventory
			if not inv then return end
			for _, item in ipairs(inv.items or {}) do
				item.itemSkin = chosen(item.itemType)
			end
			if inv.hand then
				inv.hand.itemSkin = chosen(inv.hand.itemType)
			end
			if bw.viewmodel and bw.clientStore then
				bw.viewmodel:handleStore(bw.clientStore:getState())
			end
		end

		apply()
		host:track(bw.clientStore.changed:connect(function()
			if plugin.enabled then
				apply()
			end
		end))
		host:track(localPlayer.CharacterAdded:Connect(function()
			task.spawn(function()
				for _ = 1, 8 do
					task.wait(0.35)
					if not plugin.enabled then return end
					apply()
				end
			end)
		end))
	end,
	disable = function(ctx, plugin)
		local bw = ctx.bw
		local inv = ctx.store.inventory and ctx.store.inventory.inventory
		if inv then
			for _, item in ipairs(inv.items or {}) do
				item.itemSkin = nil
			end
			if inv.hand then
				inv.hand.itemSkin = nil
			end
		end
		if bw.viewmodel and bw.clientStore then
			bw.viewmodel:handleStore(bw.clientStore:getState())
		end
	end,
}
