--proton-cache:build
local CollectionService = game:GetService("CollectionService")

local style = require(script.Parent._style)

local sides = {}
for _, face in Enum.NormalId:GetEnumItems() do
	sides[#sides + 1] = Vector3.FromNormalId(face) * 3
end

return {
	id = "ItemPlates",
	category = "render",
	settings = {
		{ id = "background", kind = "toggle", default = true },
	},
	init = function(ctx, plugin)
		plugin.state.boards = {}
		plugin.state.whitelist = { "beehive", "bed", "chest" }
	end,
	enable = function(ctx, plugin, host)
		local holder = style.root("ItemPlates")
		plugin.state.holder = holder
		local bw = ctx.bw

		local function scanSide(adornee, start, tab)
			for _, side in ipairs(sides) do
				for i = 1, 15 do
					local block = bw.getPlacedBlock(start + side * i)
					block = block and select(1, block) or block
					if not block or block == adornee then break end
					if not block:GetAttribute("NoBreak") and not table.find(tab, block.Name) then
						tab[#tab + 1] = block.Name
					end
				end
			end
		end

		local function refreshBoard(board)
			local adornee = board.Adornee
			if not adornee then
				board.Enabled = false
				return
			end
			local start = adornee.Position
			local names = {}
			scanSide(adornee, start, names)
			scanSide(adornee, start + Vector3.new(0, 0, 3), names)
			table.sort(names, function(a, b)
				local ha = bw.itemMeta[a] and bw.itemMeta[a].block and bw.itemMeta[a].block.health or 0
				local hb = bw.itemMeta[b] and bw.itemMeta[b].block and bw.itemMeta[b].block.health or 0
				return ha > hb
			end)
			for _, child in board.Frame.Row:GetChildren() do
				if child:IsA("ImageLabel") then
					child:Destroy()
				end
			end
			board.Enabled = #names > 0
			for _, blockName in ipairs(names) do
				local icon = Instance.new("ImageLabel")
				icon.Size = UDim2.fromOffset(28, 28)
				icon.BackgroundTransparency = 1
				icon.Image = bw.getIcon({ itemType = blockName }, true)
				icon.Parent = board.Frame.Row
			end
		end

		local function attach(part)
			if plugin.state.boards[part] then return end
			if not table.find(plugin.state.whitelist, part.Name) then return end
			local bb = style.plateBoard(holder, part)
			bb.Frame.BackgroundTransparency = plugin.state.background and 0.35 or 1
			plugin.state.boards[part] = bb
			refreshBoard(bb)
		end

		local function detach(part)
			local bb = plugin.state.boards[part]
			if bb then
				bb:Destroy()
				plugin.state.boards[part] = nil
			end
		end

		local function refreshNear(data)
			if not data or not data.blockRef or not data.blockRef.blockPosition then return end
			local pos = data.blockRef.blockPosition * 3
			for adornee, board in pairs(plugin.state.boards) do
				if (pos - adornee.Position).Magnitude <= 30 then
					refreshBoard(board)
				end
			end
		end

		for _, part in CollectionService:GetTagged("block") do
			task.spawn(attach, part)
		end
		host:track(CollectionService:GetInstanceAddedSignal("block"):Connect(attach))
		host:track(CollectionService:GetInstanceRemovedSignal("block"):Connect(detach))
		if ctx.events then
			host:track(ctx.events.on("bw:placeBlock", refreshNear))
			host:track(ctx.events.on("bw:breakBlock", refreshNear))
		end
	end,
	disable = function(ctx, plugin)
		if plugin.state.holder then
			style.wipe(plugin.state.holder)
		end
		table.clear(plugin.state.boards)
	end,
}
