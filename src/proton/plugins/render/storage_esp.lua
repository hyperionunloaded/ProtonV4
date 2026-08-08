--proton-cache:build
local CollectionService = game:GetService("CollectionService")

local style = require(script.Parent._style)

return {
	id = "StorageESP",
	category = "render",
	settings = {
		{ id = "background", kind = "toggle", default = true },
	},
	init = function(ctx, plugin)
		plugin.state.boards = {}
		plugin.state.watch = {}
		plugin.state.items = { "diamond", "emerald", "iron", "gold", "telepearl" }
	end,
	enable = function(ctx, plugin, host)
		local holder = style.root("StorageESP")
		plugin.state.holder = holder
		local bw = ctx.bw

		local function matches(name)
			if table.find(plugin.state.items, name) then return true end
			for _, token in ipairs(plugin.state.items) do
				if name:find(token, 1, true) then return true end
			end
			return false
		end

		local function refreshBoard(bb)
			local adornee = bb.Adornee
			if not adornee then
				bb.Enabled = false
				return
			end
			local chestVal = adornee:FindFirstChild("ChestFolderValue")
			local chest = chestVal and chestVal.Value
			if not chest then
				bb.Enabled = false
				return
			end
			for _, child in bb.Frame.Row:GetChildren() do
				if child:IsA("ImageLabel") then
					child:Destroy()
				end
			end
			local seen = {}
			local any = false
			for _, item in chest:GetChildren() do
				if not seen[item.Name] and matches(item.Name) then
					seen[item.Name] = true
					any = true
					local icon = Instance.new("ImageLabel")
					icon.Size = UDim2.fromOffset(28, 28)
					icon.BackgroundTransparency = 1
					icon.Image = bw.getIcon({ itemType = item.Name }, true)
					icon.Parent = bb.Frame.Row
				end
			end
			bb.Enabled = any
		end

		local function attach(part)
			if plugin.state.boards[part] then return end
			local chestVal = part:WaitForChild("ChestFolderValue", 3)
			if not chestVal or not plugin.enabled then return end
			local chest = chestVal.Value
			if not chest then return end
			local bb = style.plateBoard(holder, part, Vector3.new(0, 3, 0))
			bb.Frame.BackgroundTransparency = plugin.state.background and 0.35 or 1
			plugin.state.boards[part] = bb
			local pack = {}
			pack[#pack + 1] = chest.ChildAdded:Connect(function(item)
				if matches(item.Name) then
					refreshBoard(bb)
				end
			end)
			pack[#pack + 1] = chest.ChildRemoved:Connect(function(item)
				if matches(item.Name) then
					refreshBoard(bb)
				end
			end)
			plugin.state.watch[part] = pack
			task.spawn(refreshBoard, bb)
		end

		local function detach(part)
			local pack = plugin.state.watch[part]
			if pack then
				for _, conn in ipairs(pack) do
					conn:Disconnect()
				end
				plugin.state.watch[part] = nil
			end
			local bb = plugin.state.boards[part]
			if bb then
				bb:Destroy()
				plugin.state.boards[part] = nil
			end
		end

		host:track(CollectionService:GetInstanceAddedSignal("chest"):Connect(function(part)
			task.spawn(attach, part)
		end))
		for _, part in CollectionService:GetTagged("chest") do
			task.spawn(attach, part)
		end
		host:track(CollectionService:GetInstanceRemovedSignal("chest"):Connect(detach))
	end,
	disable = function(ctx, plugin)
		for part in pairs(plugin.state.watch) do
			local pack = plugin.state.watch[part]
			for _, conn in ipairs(pack) do
				conn:Disconnect()
			end
		end
		table.clear(plugin.state.watch)
		if plugin.state.holder then
			style.wipe(plugin.state.holder)
		end
		table.clear(plugin.state.boards)
	end,
}
