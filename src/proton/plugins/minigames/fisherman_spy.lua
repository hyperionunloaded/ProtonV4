--proton-cache:build
﻿return {
	id = "FishermanSpy", category = "minigames",
	settings = { { id = "ignoreTeammates", kind = "toggle", default = true } },
	init = function(ctx, plugin) end,
	enable = function(ctx, plugin, host)
		host:track(ctx.bw.handler:Get("FishCaught").Remote:Connect(function(data)
			if not data.dropData or not data.catchingPlayer then return end
			if plugin.state.ignoreTeammates ~= false and data.catchingPlayer.Team == ctx.player.Team then return end
			local parts = {}
			for _, v in data.dropData.drops do
				local meta = ctx.bw.itemMeta[v.itemType]
				parts[#parts+1] = v.amount .. " " .. (meta and meta.displayName or v.itemType):lower()
			end
			if #parts > 0 and ctx.notify then ctx.notify("FishermanSpy", data.catchingPlayer.Name .. " caught " .. table.concat(parts, ", "), 10) end
		end))
	end,
	disable = function(ctx, plugin) end,
}
