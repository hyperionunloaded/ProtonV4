--proton-cache:build
return {
	id = "ChestSteal",
	category = "world",
	settings = {
		{ id = "range", kind = "range", default = 18, min = 0, max = 18 },
		{ id = "guiCheck", kind = "toggle", default = false },
		{ id = "legit", kind = "toggle", default = false },
		{ id = "skywarsOnly", kind = "toggle", default = true },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
		plugin.state.delays = {}
	end,
	enable = function(ctx, plugin)
		local u = ctx.bw.util
		plugin.state.alive = true
		task.spawn(function()
			local chests, cleanup = u.collection("chest")
			repeat task.wait() until ctx.store.queueType ~= "bedwars_test" or not plugin.enabled
			if plugin.state.skywarsOnly and not ctx.store.queueType:find("skywars") then
				cleanup()
				return
			end
			local invNs = ctx.bw.client:GetNamespace("Inventory")
			local function lootChest(folderVal)
				local chest = folderVal and folderVal.Value
				local items = chest and chest:GetChildren() or {}
				if #items <= 1 then return end
				if (plugin.state.delays[chest] or 0) >= tick() then return end
				plugin.state.delays[chest] = tick() + 0.2
				invNs:Get("SetObservedChest"):SendToServer(chest)
				for _, v in items do
					if v:IsA("Accessory") then
						task.spawn(function()
							pcall(function()
								invNs:Get("ChestGetItem"):CallServer(chest, v)
							end)
						end)
						if plugin.state.legit then task.wait(0.2) end
					end
				end
				invNs:Get("SetObservedChest"):SendToServer(nil)
			end
			repeat
				if ctx.entity.alive and ctx.store.matchState ~= 2 then
					if plugin.state.guiCheck then
						if ctx.bw.appController:isAppOpen("ChestApp") then
							local observed = ctx.player.Character and ctx.player.Character:FindFirstChild("ObservedChestFolder")
							lootChest(observed)
						end
					else
						local localPos = ctx.entity.self.root.Position
						for _, v in chests do
							if (localPos - v.Position).Magnitude <= (plugin.state.range or 18) then
								lootChest(v:FindFirstChild("ChestFolderValue"))
							end
						end
					end
				end
				task.wait(0.1)
			until not plugin.enabled
			cleanup()
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
		table.clear(plugin.state.delays)
	end,
}
