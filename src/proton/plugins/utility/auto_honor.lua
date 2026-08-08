--proton-cache:build
return {
	id = "AutoHonor",
	category = "utility",
	settings = {
		{ id = "delay", kind = "range", default = 0.1, min = 0, max = 2, step = 0.01 },
	},
	init = function(ctx, plugin)
		plugin.state.honored = {}
	end,
	enable = function(ctx, plugin, host)
		local function honor()
			if #plugin.state.honored > 1 then return end
			local team = ctx.player:GetAttribute("Team")
			local list = {}
			for _, ent in ipairs(ctx.entity.list) do
				if ent.player then
					list[#list + 1] = ent
				end
			end
			table.sort(list, function(a, b)
				local at = a.player:GetAttribute("Team") == team
				local bt = b.player:GetAttribute("Team") == team
				if at == bt then return false end
				return at
			end)
			for _, ent in list do
				if #plugin.state.honored > 1 then break end
				if not table.find(plugin.state.honored, ent.player) then
					ctx.bw.fire("HonorPlayer", "SendToServer", { userId = ent.player.UserId })
					table.insert(plugin.state.honored, ent.player)
					task.wait(plugin.state.delay or 0.1)
				end
			end
		end
		host:track(ctx.events.on("EntityDeathEvent", function(deathTable)
			if not deathTable.finalKill then return end
			if deathTable.entityInstance ~= ctx.player.Character then return end
			local party = ctx.bw.store and ctx.bw.store:getState().Party
			if party and #party.members > 0 then return end
			if ctx.store.matchState == 2 then return end
			honor()
		end))
		host:track(ctx.events.on("MatchEndEvent", honor))
	end,
	disable = function(ctx, plugin)
		table.clear(plugin.state.honored)
	end,
}
