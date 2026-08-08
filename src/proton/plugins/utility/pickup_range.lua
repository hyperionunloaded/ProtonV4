--proton-cache:build
return {
	id = "PickupRange",
	category = "utility",
	settings = {
		{ id = "range", kind = "range", default = 10, min = 1, max = 10 },
		{ id = "network", kind = "toggle", default = true },
		{ id = "feetCheck", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
		plugin.state.picked = {}
	end,
	enable = function(ctx, plugin)
		local u = ctx.bw.util
		plugin.state.alive = true
		plugin.state.picked = {}
		task.spawn(function()
			local items, cleanup = u.collection("ItemDrop")
			repeat
				if ctx.entity.alive then
					local localPos = ctx.entity.self.root.Position
					for _, v in items do
						if tick() - (v:GetAttribute("ClientDropTime") or 0) < 2 then continue end
						if table.find(plugin.state.picked, v) then continue end
						if plugin.state.network and isnetworkowner and isnetworkowner(v) and ctx.entity.self.health > 0 then
							v.CFrame = CFrame.new(localPos - Vector3.new(0, 3, 0))
						end
						if (localPos - v.Position).Magnitude <= (plugin.state.range or 10) then
							if plugin.state.feetCheck and (localPos.Y - v.Position.Y) < 2 then continue end
							local idx = #plugin.state.picked + 1
							plugin.state.picked[idx] = v
							task.spawn(function()
								local slot = ctx.bw.handler:Get("PickupItemDrop")
								local suc = slot:Fire("CallServerAsync", { itemDrop = v })
								if suc and typeof(suc) == "table" and suc.andThen then
									suc:andThen(function(result)
										table.remove(plugin.state.picked, table.find(plugin.state.picked, v) or idx)
									end)
								else
									table.remove(plugin.state.picked, table.find(plugin.state.picked, v) or idx)
								end
							end)
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
		table.clear(plugin.state.picked)
	end,
}
