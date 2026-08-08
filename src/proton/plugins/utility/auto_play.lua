--proton-cache:build
return {
	id = "AutoPlay",
	category = "utility",
	settings = {
		{ id = "random", kind = "toggle", default = false },
	},
	init = function(ctx, plugin) end,
	enable = function(ctx, plugin, host)
		local function everyoneDead()
			local party = ctx.bw.store:getState().Party
			return party and #party.members <= 0
		end
		local function joinQueue()
			local state = ctx.bw.store:getState()
			if state.Game.customMatch then return end
			if state.Party.leader.userId ~= ctx.player.UserId then return end
			if state.Party.queueState ~= 0 then return end
			if plugin.state.random then
				local modes = {}
				for id, meta in ctx.bw.queueMeta do
					if not meta.disabled and not meta.voiceChatOnly and not meta.rankCategory then
						modes[#modes + 1] = id
					end
				end
				if #modes > 0 then
					ctx.bw.queueController:joinQueue(modes[math.random(1, #modes)])
				end
			else
				ctx.bw.queueController:joinQueue(ctx.store.queueType)
			end
		end
		host:track(ctx.events.on("EntityDeathEvent", function(deathTable)
			if deathTable.finalKill and deathTable.entityInstance == ctx.player.Character and everyoneDead() and ctx.store.matchState ~= 2 then
				joinQueue()
			end
		end))
		host:track(ctx.events.on("MatchEndEvent", joinQueue))
	end,
	disable = function(ctx, plugin) end,
}
