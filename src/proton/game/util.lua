--proton-cache:build
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local util = {}

function util.attach(ctx, bw)
	util.ctx = ctx
	util.bw = bw
	util.store = ctx.store
	util.plr = ctx.player
	util.session = require(script.Parent.Parent.core.session).bind(ctx)

	local ok, storeMod = pcall(function()
		return require(ctx.player.PlayerScripts.TS.ui.store).ClientStore
	end)
	if ok and storeMod then
		bw.store = storeMod
		util.syncStore(storeMod:getState(), {})
		storeMod.changed:connect(function(new, old)
			util.syncStore(new, old)
		end)
	end

	local okPlacer, BlockPlacer = pcall(function()
		return require(ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["block-engine"].out.client.placement["block-placer"]).BlockPlacer
	end)
	if okPlacer and BlockPlacer then
		ctx.store.blockPlacer = BlockPlacer.new(bw.blockController, "wool_white")
	end

	util.refreshTools()

	ctx.store.shop = select(1, util.collection({ "BedwarsItemShop", "TeamUpgradeShopkeeper" }, function(tab, obj)
		tab[#tab + 1] = {
			Id = obj.Name,
			RootPart = obj,
			Shop = obj:HasTag("BedwarsItemShop"),
			Upgrades = obj:HasTag("TeamUpgradeShopkeeper"),
		}
	end, function(tab, obj)
		for i, v in tab do
			if v.RootPart == obj then
				table.remove(tab, i)
				break
			end
		end
	end))

	task.spawn(function()
		local client = bw.client
		if not client or not client.WaitFor then return end
		for _, name in { "MatchEndEvent", "EntityDeathEvent", "BedwarsBedBreak" } do
			local ok, conn = pcall(function()
				return client:WaitFor(name):expect()
			end)
			if ok and conn and conn.Connect then
				conn:Connect(function(...)
					ctx.events.emit(name, ...)
				end)
			end
		end
	end)
end

function util.syncStore(new, old)
	old = old or {}
	local store = util.store
	if new.Bedwars and new.Bedwars ~= old.Bedwars then
		store.equippedKit = new.Bedwars.kit ~= "none" and new.Bedwars.kit or ""
	end
	if new.Game and new.Game ~= old.Game then
		store.matchState = new.Game.matchState or 0
		store.queueType = new.Game.queueType or "bedwars_test"
		if util.session then
			util.session.onStoreChange(new, old)
		end
	end
	if new.Inventory and new.Inventory ~= old.Inventory then
		local inv = new.Inventory.observedInventory or { inventory = { items = {}, armor = {} }, hotbar = {} }
		local prev = old.Inventory and old.Inventory.observedInventory
		store.inventory = inv
		if not prev or inv.inventory.hand ~= prev.inventory.hand then
			util.syncHand(inv.inventory.hand)
		end
		if not prev or inv.inventory.items ~= prev.inventory.items then
			util.refreshTools()
		end
	end
end

function util.syncHand(currentHand)
	local meta = currentHand and util.bw.itemMeta[currentHand.itemType] or {}
	local toolType = ""
	if currentHand then
		toolType = meta.sword and "sword" or meta.block and "block" or (currentHand.itemType:find("bow") and "bow") or ""
	end
	util.store.hand = {
		tool = currentHand and currentHand.tool,
		amount = currentHand and currentHand.amount or 0,
		toolType = toolType,
	}
end

function util.refreshTools()
	util.store.tools = util.store.tools or {}
	for _, t in { "stone", "wood", "wool" } do
		util.store.tools[t] = util.getTool(t)
	end
end

function util.getItem(itemName, inv)
	inv = inv or util.store.inventory.inventory.items
	for slot, item in inv do
		if item.itemType == itemName then
			return item, slot
		end
	end
end

function util.getTool(breakType)
	local best, bestDmg
	for _, item in util.store.inventory.inventory.items do
		local tb = util.bw.itemMeta[item.itemType] and util.bw.itemMeta[item.itemType].breakBlock
		if tb then
			local dmg = tb[breakType] or 0
			if not best or dmg > bestDmg then
				best, bestDmg = item, dmg
			end
		end
	end
	return best
end

function util.getHotbar(tool)
	for i, v in util.store.inventory.hotbar or {} do
		if v.item and v.item.tool == tool then
			return i - 1
		end
	end
end

function util.hotbarSwitch(slot)
	if slot ~= nil and util.bw.store and util.store.inventory.hotbarSlot ~= slot then
		util.bw.store:dispatch({ type = "InventorySelectHotbarSlot", slot = slot })
		task.wait()
		return true
	end
	return false
end

function util.switchItem(tool, delayTime)
	delayTime = delayTime or 0.05
	local char = util.plr.Character
	local check = char and char:FindFirstChild("HandInvItem")
	if check and tool and check.Value ~= tool and tool.Parent then
		task.spawn(function()
			util.bw.handler:Get("SetInvItem"):Fire("CallServerAsync", { hand = tool })
		end)
		check.Value = tool
		if delayTime > 0 then
			task.wait(delayTime)
		end
		return true
	end
end

function util.roundPos(vec)
	return Vector3.new(
		math.round(vec.X / 3) * 3,
		math.round(vec.Y / 3) * 3,
		math.round(vec.Z / 3) * 3
	)
end

function util.getPlacedBlock(pos)
	if not pos then return end
	local bc = util.bw.blockController
	local rounded = bc:getBlockPosition(pos)
	return bc:getStore():getBlockAt(rounded), rounded
end

function util.canPlace()
	local ctrl = util.bw.BlockPlacementController
	return not ctrl or not ctrl.disabled
end

function util.placeBlock(pos, item)
	if not util.canPlace() or not util.getItem(item) then return end
	if util.store.blockPlacer then
		util.store.blockPlacer.blockType = item
		return util.store.blockPlacer:placeBlock(util.bw.blockController:getBlockPosition(pos))
	end
end

function util.getWool()
	for _, wool in util.store.inventory.inventory.items do
		if wool.itemType:find("wool") then
			return wool.itemType, wool.amount
		end
	end
end

function util.listMatch(list, name)
	if not list or not name then return false end
	name = name:lower()
	for _, entry in list do
		local needle = tostring(entry):lower()
		if name == needle or name:find(needle, 1, true) then
			return true
		end
	end
	return false
end

function util.getBlocksInPoints(s, e)
	local blocks = util.bw.blockController:getStore()
	local list = {}
	for x = s.X, e.X do
		for y = s.Y, e.Y do
			for z = s.Z, e.Z do
				local vec = Vector3.new(x, y, z)
				if blocks:getBlockAt(vec) then
					list[#list + 1] = vec * 3
				end
			end
		end
	end
	return list
end

function util.collection(tags, customAdd, customRemove)
	tags = typeof(tags) == "table" and tags or { tags }
	local objs, conns = {}, {}
	for _, tag in tags do
		conns[#conns + 1] = CollectionService:GetInstanceAddedSignal(tag):Connect(function(v)
			if customAdd then
				customAdd(objs, v, tag)
			else
				objs[#objs + 1] = v
			end
		end)
		conns[#conns + 1] = CollectionService:GetInstanceRemovedSignal(tag):Connect(function(v)
			if customRemove then
				customRemove(objs, v, tag)
			else
				local i = table.find(objs, v)
				if i then table.remove(objs, i) end
			end
		end)
		for _, v in CollectionService:GetTagged(tag) do
			if customAdd then
				customAdd(objs, v, tag)
			else
				objs[#objs + 1] = v
			end
		end
	end
	return objs, function()
		for _, c in conns do
			c:Disconnect()
		end
		table.clear(conns)
		table.clear(objs)
	end
end

function util.pyramid(size, grid)
	local positions = {}
	for h = size, 0, -1 do
		for w = h, 0, -1 do
			positions[#positions + 1] = Vector3.new(w, size - h, (h + 1) - w) * grid
			positions[#positions + 1] = Vector3.new(w * -1, size - h, (h + 1) - w) * grid
			positions[#positions + 1] = Vector3.new(w, size - h, (h - w) * -1) * grid
			positions[#positions + 1] = Vector3.new(w * -1, size - h, (h - w) * -1) * grid
		end
	end
	return positions
end

function util.getTeamBed(range)
	local team = util.plr:GetAttribute("Team") or -1
	local origin = util.ctx.entity.alive and util.ctx.entity.self.root.Position or Vector3.zero
	for _, v in CollectionService:GetTagged("bed") do
		if (origin - v.Position).Magnitude < (range or 14) and v:GetAttribute("Team" .. team .. "NoBreak") then
			return v
		end
	end
end

function util.lowestVoidPoint(blocks)
	local lowest = math.huge
	for _, v in blocks or {} do
		local point = (v.Position.Y - v.Size.Y / 2) - 50
		if point < lowest then
			lowest = point
		end
	end
	return lowest
end

function util.randRange(minVal, maxVal)
	if minVal == maxVal then return minVal end
	return minVal + math.random() * (maxVal - minVal)
end

return util
