--proton-cache:build
return {
	id = "BedProtector",
	category = "world",
	settings = {
		{ id = "mode", kind = "drop", default = "Toggle", options = { "Toggle", "On Key" } },
		{ id = "placeRange", kind = "range", default = 15, min = 1, max = 30 },
		{ id = "woolOnly", kind = "toggle", default = false },
		{ id = "autoSwitch", kind = "toggle", default = false },
		{ id = "blacklist", kind = "textlist", default = { "siege_tnt", "tnt" } },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin)
		local u = ctx.bw.util
		plugin.state.alive = true
		local function getBlocks()
			local blocks = {}
			for _, item in ctx.store.inventory.inventory.items do
				local block = ctx.bw.itemMeta[item.itemType].block
				if not block then continue end
				local key = item.itemType:find("wool") and "wool" or item.itemType
				if plugin.state.woolOnly then
					if item.itemType:find("wool") then
						blocks[#blocks + 1] = { item.itemType, block.health, item.tool }
					end
				elseif not u.listMatch(plugin.state.blacklist or {}, key) then
					blocks[#blocks + 1] = { item.itemType, block.health, item.tool }
				end
			end
			if #blocks > 1 then
				table.sort(blocks, function(a, b) return a[2] > b[2] end)
			end
			return blocks
		end
		task.spawn(function()
			repeat
				local bed = u.getTeamBed(14)
				if bed and ctx.entity.alive then
					for i, block in getBlocks() do
						local oldSlot = plugin.state.autoSwitch and ctx.store.hand.tool and u.getHotbar(ctx.store.hand.tool)
						local hotbar = plugin.state.autoSwitch and u.getHotbar(block[3])
						for _, pos in u.pyramid(i, 3) do
							if not plugin.enabled then break end
							local worldPos = (bed.CFrame * CFrame.new(pos)).Position
							if u.getPlacedBlock(worldPos) then continue end
							if (ctx.entity.self.root.Position - worldPos).Magnitude > (plugin.state.placeRange or 15) then continue end
							if hotbar and u.hotbarSwitch(hotbar) then task.wait() end
							task.spawn(u.placeBlock, worldPos, block[1])
							task.wait(0.1)
						end
						if plugin.state.autoSwitch and oldSlot and u.hotbarSwitch(oldSlot) then task.wait() end
					end
				elseif plugin.state.mode == "On Key" then
					ctx.notify.push("BedProtector", "Unable to locate bed", "alert")
					break
				end
				task.wait(0.5)
				if plugin.state.mode == "On Key" then break end
			until not plugin.enabled
			plugin.state.alive = false
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
	end,
}
