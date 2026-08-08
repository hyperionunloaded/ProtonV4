--proton-cache:build
return {
	id = "BlockIn",
	category = "world",
	settings = {
		{ id = "delayMin", kind = "range", default = 30, min = 1, max = 250 },
		{ id = "delayMax", kind = "range", default = 50, min = 1, max = 250 },
		{ id = "priority", kind = "drop", default = "Lowest cost", options = { "Lowest cost", "Hardest" } },
		{ id = "returnSlot", kind = "toggle", default = true },
		{ id = "woolOnly", kind = "toggle", default = false },
		{ id = "blacklist", kind = "textlist", default = { "cannon", "siege_tnt", "tnt" } },
	},
	init = function(ctx, plugin) end,
	enable = function(ctx, plugin, host)
		host:disable("BlockIn")
		local u = ctx.bw.util
		if not ctx.entity.alive then return end
		local dirs = {
			Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
			Vector3.new(0, 0, 1), Vector3.new(0, 0, -1),
		}
		local scan = 30
		local function roundGrid(p)
			return Vector3.new(
				math.floor(p.X / 3 + 0.5) * 3,
				math.floor(p.Y / 3 + 0.5) * 3,
				math.floor(p.Z / 3 + 0.5) * 3
			)
		end
		local function getOrigin()
			local pos = ctx.entity.self.root.Position
			local ray = ctx.bw.query:raycast(pos, Vector3.new(0, -scan, 0))
			return u.roundPos(ray and Vector3.new(pos.X, ray.Position.Y + 1.5, pos.Z) or pos)
		end
		local function findCol(root, dir)
			local out = {}
			local col = root + dir * 3
			local topY = root.Y + 6
			local y = topY - 6
			while y <= topY do
				out[#out + 1] = Vector3.new(dir.X * 3, y - root.Y, dir.Z * 3)
				y += 3
			end
			return out
		end
		local origin = getOrigin()
		local pattern = {}
		local cols = {}
		for _, dir in dirs do
			cols[#cols + 1] = { dir = dir, out = findCol(origin, dir), cost = #findCol(origin, dir) }
		end
		table.sort(cols, function(a, b) return a.cost < b.cost end)
		for _, o in cols[1].out do pattern[#pattern + 1] = o end
		local capY = 0
		for _, c in cols do
			for _, o in c.out do
				if o.Y > capY then capY = o.Y end
			end
		end
		pattern[#pattern + 1] = Vector3.new(0, capY, 0)
		for i = 2, #cols do
			for _, o in cols[i].out do
				if o.Y ~= capY then pattern[#pattern + 1] = o end
			end
		end
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
		if plugin.state.priority == "Lowest cost" then
			table.sort(blocks, function(a, b) return a[2] < b[2] end)
		else
			table.sort(blocks, function(a, b) return a[2] > b[2] end)
		end
		local oldHotbar = ctx.store.hand.tool and u.getHotbar(ctx.store.hand.tool)
		for _, v in blocks do
			local slot = u.getHotbar(v[3])
			if not slot then continue end
			u.hotbarSwitch(slot)
			for _, pos in pattern do
				if not ctx.entity.alive then break end
				if u.getPlacedBlock(origin + pos) then continue end
				task.spawn(u.placeBlock, origin + pos, v[1])
				local delay = u.randRange(plugin.state.delayMin or 30, plugin.state.delayMax or 50) / 1000
				if delay > 0 then task.wait(delay) end
			end
		end
		if plugin.state.returnSlot and oldHotbar then
			u.hotbarSwitch(oldHotbar)
		end
	end,
	disable = function(ctx, plugin) end,
}
