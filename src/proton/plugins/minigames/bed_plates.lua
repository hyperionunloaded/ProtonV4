--proton-cache:build
﻿local CollectionService = game:GetService("CollectionService")
local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "BedPlates", category = "minigames",
	settings = { { id = "background", kind = "toggle", default = true } },
	init = function(ctx, plugin) plugin.state.refs = {} plugin.state.folder = Instance.new("Folder") end,
	enable = function(ctx, plugin, host)
		local folder = plugin.state.folder
		folder.Parent = ctx.player.PlayerGui
		for _, v in CollectionService:GetTagged("bed") do
			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.fromOffset(36, 36)
			bb.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
			bb.AlwaysOnTop = true
			bb.Adornee = v
			bb.Parent = folder
			plugin.state.refs[v] = bb
		end
		host:track(CollectionService:GetInstanceAddedSignal("bed"):Connect(function(v)
			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.fromOffset(36, 36)
			bb.Adornee = v
			bb.Parent = folder
			plugin.state.refs[v] = bb
		end))
	end,
	disable = function(ctx, plugin)
		plugin.state.folder:ClearAllChildren()
		table.clear(plugin.state.refs)
	end,
}
