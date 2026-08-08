--proton-cache:build
return {
	id = "BedPatcher",
	category = "world",
	settings = {
		{ id = "mode", kind = "drop", default = "Toggle", options = { "Toggle", "On Key" } },
		{ id = "placeRange", kind = "range", default = 15, min = 1, max = 60 },
		{ id = "autoSwitch", kind = "toggle", default = false },
		{ id = "limitItem", kind = "toggle", default = false },
		{ id = "whitelist", kind = "textlist", default = { "wool", "obsidian" } },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin)
		local u = ctx.bw.util
		plugin.state.alive = true
		local function getBlock()
			if plugin.state.limitItem and ctx.store.hand.toolType == "block" then
				local name = ctx.store.hand.tool.Name
				local key = name:find("wool") and "wool" or name
				if u.listMatch(plugin.state.whitelist or {}, key) then
					return ctx.store.hand.tool.Name, ctx.store.hand.tool
				end
				return
			end
			local blocks = {}
			for _, item in ctx.store.inventory.inventory.items do
				local block = ctx.bw.itemMeta[item.itemType].block
				if block then
					local key = item.itemType:find("wool") and "wool" or item.itemType
					if u.listMatch(plugin.state.whitelist or {}, key) then
						blocks[#blocks + 1] = { item.itemType, block.health, item.tool }
					end
				end
			end
			if #blocks > 1 then
				table.sort(blocks, function(a, b) return a[2] > b[2] end)
			end
			local first = blocks[1]
			return first and first[1], first and first[3]
		end
		task.spawn(function()
			repeat
				local bed = u.getTeamBed(14)
				if bed and ctx.entity.alive then
					for i = 0, 6 do
						local y = Vector3.yAxis * (3 * i)
						if u.getPlacedBlock(bed.Position + y) or u.getPlacedBlock((bed.CFrame + y) * CFrame.new(0, 0, 3).Position) then
							for _, pos in u.pyramid(i, 3) do
								local itemType, tool = getBlock()
								if not itemType then break end
								local worldPos = (bed.CFrame * CFrame.new(pos)).Position
								if u.getPlacedBlock(worldPos) then continue end
								if (ctx.entity.self.root.Position - worldPos).Magnitude > (plugin.state.placeRange or 15) then continue end
								if plugin.state.autoSwitch and tool and u.getHotbar(tool) and u.hotbarSwitch(u.getHotbar(tool)) then
									task.wait()
								end
								task.spawn(u.placeBlock, worldPos, itemType)
								task.wait(0.1)
							end
						end
					end
				elseif plugin.state.mode == "On Key" then
					ctx.notify.push("BedPatcher", "Unable to locate bed", "alert")
					plugin.enabled = false
					break
				end
				task.wait(0.5)
				if plugin.state.mode == "On Key" then
					plugin.enabled = false
					break
				end
			until not plugin.enabled
			plugin.state.alive = false
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
	end,
}
