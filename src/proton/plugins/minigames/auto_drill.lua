--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "AutoDrill",
	category = "minigames",
	settings = {
		{ id = "autoCollect", kind = "toggle", default = true },
		{ id = "autoAttack", kind = "toggle", default = true },
		{ id = "range", kind = "range", default = 10, min = 1, max = 10 },
		{ id = "legitRange", kind = "toggle", default = true },
		{ id = "attackDelay", kind = "range", default = 0.3, min = 0.1, max = 1, step = 0.01 },
		{ id = "collectDelay", kind = "range", default = 0.5, min = 0.1, max = 3, step = 0.01 },
		{ id = "players", kind = "toggle", default = true },
	},
	init = function(ctx, plugin)
		plugin.state.attackDebounce = {}
		plugin.state.collectDebounce = {}
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		local drills = util.collection(ctx, host, "Drill")
		plugin.state.alive = true
		task.spawn(function()
			repeat task.wait() until ctx.store.matchState ~= 0 and ctx.store.equippedKit == "drill" or not plugin.enabled
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive and ctx.store.equippedKit == "drill" then
					local now = tick()
					for _, drill in drills do
						local part = drill.PrimaryPart or drill:FindFirstChildWhichIsA("BasePart")
						if part then
							if plugin.state.autoCollect ~= false and now > (plugin.state.collectDebounce[drill] or 0) then
								local total = (drill:GetAttribute("diamond") or 0) + (drill:GetAttribute("emerald") or 0)
								if total > 0 then
									bw.fire("ExtractFromDrill", { drill = drill })
									plugin.state.collectDebounce[drill] = now + (plugin.state.collectDelay or 0.5)
								end
							end
							if plugin.state.autoAttack ~= false and now > (plugin.state.attackDebounce[drill] or 0) then
								local range = plugin.state.legitRange and 10 or (plugin.state.range or 10)
								local target = util.pickTarget(ctx, { origin = part.Position, range = range, players = plugin.state.players ~= false })
								if target then
									bw.fire("DrillAttack", { targetPosition = target.root.Position })
									plugin.state.attackDebounce[drill] = now + (plugin.state.attackDelay or 0.3)
								end
							end
						end
					end
				end
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
		table.clear(plugin.state.attackDebounce)
		table.clear(plugin.state.collectDebounce)
	end,
}
