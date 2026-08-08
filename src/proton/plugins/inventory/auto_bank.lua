--proton-cache:build
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local util = require(script.Parent.Parent.Parent.game.util)

return {
	id = "AutoBank",
	category = "inventory",
	settings = {
		{ id = "range", kind = "range", default = 14, min = 1, max = 18 },
		{ id = "delay", kind = "range", default = 0.2, min = 0, max = 2, step = 0.05 },
		{ id = "iron", kind = "toggle", default = true },
		{ id = "diamond", kind = "toggle", default = true },
		{ id = "emerald", kind = "toggle", default = true },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		local chests = util.collection(ctx, host, "personal-chest")
		plugin.state.alive = true

		local function invRemote(name)
			return bw.client:GetNamespace("Inventory"):Get(name)
		end

		local function shouldBank(itemType)
			if itemType:find("iron") then return plugin.state.iron ~= false end
			if itemType:find("diamond") then return plugin.state.diamond ~= false end
			if itemType:find("emerald") then return plugin.state.emerald ~= false end
			return false
		end

		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive then
					local pos = util.pos(ctx)
					local nearChest = false
					for _, chest in chests do
						if (pos - chest.Position).Magnitude <= (plugin.state.range or 14) then
							nearChest = true
							break
						end
					end
					if nearChest then
						local inv = ReplicatedStorage:FindFirstChild("Inventories")
						inv = inv and inv:FindFirstChild(ctx.player.Name .. "_personal")
						if inv then
							for _, item in ctx.store.inventory.inventory.items do
								if shouldBank(item.itemType) and item.tool then
									pcall(function()
										invRemote("ChestGiveItem"):CallServer(inv, item.tool)
									end)
								end
							end
						end
					end
				end
				task.wait(plugin.state.delay or 0.2)
			end
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
	end,
}
