--proton-cache:build
return {
	id = "AutoCounter",
	category = "utility",
	settings = {
		{ id = "range", kind = "range", default = 30, min = 1, max = 60 },
		{ id = "limitItem", kind = "toggle", default = false },
		{ id = "autoSwitch", kind = "toggle", default = true },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
		plugin.state.tnts = {}
		plugin.state.placed = {}
	end,
	enable = function(ctx, plugin)
		local u = ctx.bw.util
		plugin.state.alive = true
		plugin.state.tnts = {}
		plugin.state.placed = {}
		local tntConn = workspace.ChildAdded:Connect(function(v)
			if v.Name ~= "tnt" then return end
			table.insert(plugin.state.tnts, v)
			v.Destroying:Once(function()
				local i = table.find(plugin.state.tnts, v)
				if i then table.remove(plugin.state.tnts, i) end
			end)
		end)
		plugin.state.tntConn = tntConn
		task.spawn(function()
			repeat
				for pos, expiry in pairs(plugin.state.placed) do
					if expiry <= tick() then
						plugin.state.placed[pos] = nil
					end
				end
				if ctx.entity.alive then
					local item
					if plugin.state.limitItem then
						local tool = ctx.store.hand.tool
						item = tool and tool.Name == "tnt" and tool or nil
					else
						local inv = u.getItem("tnt")
						item = inv and inv.tool
					end
					if item then
						local localPos = ctx.entity.self.root.Position
						for _, v in plugin.state.tnts do
							local rounded = Vector3.new(math.round(v.Position.X), math.round(v.Position.Y), math.round(v.Position.Z))
							if v.Velocity.Y >= 0 and not plugin.state.placed[rounded] and (localPos - v.Position).Magnitude <= (plugin.state.range or 30) then
								if not plugin.state.limitItem and plugin.state.autoSwitch then
									local hotbar = u.getHotbar(item)
									u.switchItem(item)
									if hotbar then u.hotbarSwitch(hotbar) end
								end
								plugin.state.placed[rounded] = tick() + 3
								task.spawn(u.placeBlock, v.Position, typeof(item) == "Instance" and item.Name or "tnt")
								task.wait(0.12)
							end
						end
					end
				end
				task.wait(0.1)
			until not plugin.enabled
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
		if plugin.state.tntConn then
			plugin.state.tntConn:Disconnect()
			plugin.state.tntConn = nil
		end
		table.clear(plugin.state.tnts)
		table.clear(plugin.state.placed)
	end,
}
