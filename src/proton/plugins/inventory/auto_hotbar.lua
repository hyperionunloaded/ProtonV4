--proton-cache:build
local util = require(script.Parent.Parent.Parent.game.util)

local defaultLayout = {
	["1"] = "wood_sword",
	["2"] = "wool_white",
	["3"] = "wood_pickaxe",
	["4"] = "wood_axe",
	["5"] = "apple",
}

return {
	id = "AutoHotbar",
	category = "inventory",
	settings = {
		{ id = "clearHotbar", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.active = false
		plugin.state.layout = table.clone(defaultLayout)
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw

		local function findInHotbar(item)
			for i, v in ctx.store.inventory.hotbar do
				if v.item and v.item.itemType == item.itemType then
					return i - 1, v.item
				end
			end
		end

		local function findInInventory(item)
			for _, v in ctx.store.inventory.inventory.items do
				if v.itemType == item.itemType then return v end
			end
		end

		local function dispatch(data)
			bw.store:dispatch(data)
			task.wait()
		end

		local function sortCallback()
			if plugin.state.active then return end
			plugin.state.active = true
			local layout = plugin.state.layout
			for _, v in ctx.store.inventory.inventory.items do
				local slot = nil
				for s, name in layout do
					if v.itemType == name or name == "wool_white" and v.itemType:find("wool") then
						slot = tonumber(s)
						break
					end
				end
				if slot then
					local olditem = ctx.store.inventory.hotbar[slot]
					if olditem and olditem.item and olditem.item.itemType == v.itemType then continue end
					if olditem and olditem.item then
						dispatch({ type = "InventoryRemoveFromHotbar", slot = slot - 1 })
					end
					local newslot = findInHotbar(v)
					if newslot then
						dispatch({ type = "InventoryRemoveFromHotbar", slot = newslot })
						if olditem and olditem.item then
							dispatch({ type = "InventoryAddToHotbar", item = findInInventory(olditem.item), slot = newslot })
						end
					end
					dispatch({ type = "InventoryAddToHotbar", item = findInInventory(v), slot = slot - 1 })
				elseif plugin.state.clearHotbar then
					local newslot = findInHotbar(v)
					if newslot then
						dispatch({ type = "InventoryRemoveFromHotbar", slot = newslot })
					end
				end
			end
			plugin.state.active = false
		end

		task.spawn(sortCallback)
		host:track(bw.store.changed:connect(function()
			if plugin.enabled then sortCallback() end
		end))
	end,
	disable = function(ctx, plugin) end,
}
