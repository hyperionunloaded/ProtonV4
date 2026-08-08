--proton-cache:build
local Players = game:GetService("Players")

return {
	id = "CheatDetector",
	category = "utility",
	settings = {
		{ id = "tempTarget", kind = "toggle", default = true },
	},
	init = function(ctx, plugin)
		plugin.state.flags = {}
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin)
		plugin.state.alive = true
		local whitelist = {
			[Enum.HumanoidStateType.Running] = true,
			[Enum.HumanoidStateType.Jumping] = true,
			[Enum.HumanoidStateType.Freefall] = true,
			[Enum.HumanoidStateType.Landed] = true,
			[Enum.HumanoidStateType.FallingDown] = true,
			[Enum.HumanoidStateType.GettingUp] = true,
			[Enum.HumanoidStateType.Climbing] = true,
			[Enum.HumanoidStateType.Seated] = true,
			[Enum.HumanoidStateType.Ragdoll] = true,
			[Enum.HumanoidStateType.Dead] = true,
			[Enum.HumanoidStateType.None] = true,
		}
		local function flag(plr, reason, weight)
			local key = plr.UserId
			plugin.state.flags[key] = plugin.state.flags[key] or { score = 0, reasons = {} }
			local entry = plugin.state.flags[key]
			entry.score += weight
			entry.reasons[reason] = (entry.reasons[reason] or 0) + 1
			if entry.score >= 20 then
				ctx.notify.push("CheatDetector", "This player may be cheating! (" .. reason .. "): " .. plr.Name, "warning")
				ctx.events.emit("CheatFlagged", plr, reason)
				if plugin.state.tempTarget then
					for _, ent in ipairs(ctx.entity.list) do
						if ent.player == plr then
							ent.flagged = true
							ctx.entity.events.updated:fire(ent)
						end
					end
				end
				entry.score = 0
			end
		end
		task.spawn(function()
			repeat
				for _, ent in ipairs(ctx.entity.list) do
					if ent.health > 0 and ent.player and ent.head and ent.humanoid then
						local ray = ctx.bw.query:raycast(ent.head.Position, ent.head.CFrame.LookVector * 2)
						if not ray then
							flag(ent.player, "phase/noclip", 1)
						end
						if not whitelist[ent.humanoid:GetState()] then
							flag(ent.player, "invalid state " .. ent.humanoid:GetState().Name, 1)
						end
						local velo = ent.root.AssemblyLinearVelocity
						if not ent.humanoid.SeatPart then
							if (velo * Vector3.new(1, 0, 1)).Magnitude > 26 then
								flag(ent.player, "speed", 1)
							end
							if velo.Y > 50 then
								flag(ent.player, "highjump", 1)
							end
						end
					end
				end
				task.wait(0.05)
			until not plugin.enabled
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
		table.clear(plugin.state.flags)
	end,
}
