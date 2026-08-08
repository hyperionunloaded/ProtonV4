--proton-cache:build
local util = require(script.Parent.Parent.Parent.game.util)

return {
	id = "ArmorSwitch",
	category = "inventory",
	settings = {
		{ id = "mode", kind = "drop", default = "Toggle", options = { "Toggle", "On Key" } },
		{ id = "range", kind = "range", default = 30, min = 1, max = 30 },
		{ id = "players", kind = "toggle", default = true },
		{ id = "npcs", kind = "toggle", default = true },
		{ id = "walls", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if not ctx.entity.alive then
					task.wait(0.1)
					continue
				end
				local near = util.pickTarget(ctx, {
					range = plugin.state.range or 30,
					players = plugin.state.players ~= false,
					npcs = plugin.state.npcs ~= false,
				})
				local state = near and true or false
				for i = 0, 2 do
					local armor = ctx.store.inventory.inventory.armor[i + 1]
					local empty = armor == "empty" or armor == nil
					if empty ~= state then
						bw.store:dispatch({
							type = "InventorySetArmorItem",
							item = empty and state and util.getBestArmor(ctx, i) or nil,
							armorSlot = i,
						})
						task.wait()
					end
				end
				if plugin.state.mode == "On Key" then break end
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
	end,
}
