--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)

return {
	id = "AutoCaitlyn",
	category = "minigames",
	settings = {
		{ id = "mode", kind = "drop", default = "On Low", options = { "On Hit", "On Low" } },
		{ id = "minHealth", kind = "range", default = 30, min = 1, max = 100 },
		{ id = "range", kind = "range", default = 50, min = 1, max = 50 },
		{ id = "priorities", kind = "toggle", default = false },
	},
	init = function(ctx, plugin) plugin.state.session = nil end,
	enable = function(ctx, plugin)
		local bw = ctx.bw
		local session = { lastHit = nil, pendingId = nil, pendingUntil = 0 }
		plugin.state.session = session
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive and ctx.store.matchState == 1 and ctx.store.equippedKit == "blood_assassin" then
					local kit = bw.store:getState().Kit
					if kit and not kit.activeContract and kit.availableContracts then
						local contract
						if plugin.state.mode == "On Low" then
							local target = util.pickTarget(ctx, { range = plugin.state.range or 50, players = true })
							if target and target.health <= (plugin.state.minHealth or 30) then
								for _, v in kit.availableContracts do
									if v.target == target.player then contract = v break end
								end
							end
						elseif session.lastHit and session.lastHit[2] > tick() then
							for _, v in kit.availableContracts do
								if v.target == session.lastHit[1].player then contract = v break end
							end
						end
						if contract and not (session.pendingId == contract.id and session.pendingUntil > tick()) then
							bw.fire("BloodAssassinSelectContract", { contractId = contract.id })
							session.pendingId = contract.id
							session.pendingUntil = tick() + 1
						end
					end
				end
				task.wait(0.2)
			end
		end)
	end,
	disable = function(ctx, plugin) plugin.state.alive = false plugin.state.session = nil end,
}
