--proton-cache:build
return {
	id = "AutoKit",
	category = "utility",
	settings = {
		{ id = "legitRange", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
		plugin.state.kitToggles = {}
		for id, meta in ctx.bw.bedwarsKitMeta do
			plugin.state.kitToggles[id] = true
			plugin.settings[#plugin.settings + 1] = {
				id = "kit_" .. id,
				kind = "toggle",
				label = meta.name or id,
				default = true,
			}
		end
	end,
	enable = function(ctx, plugin)
		local u = ctx.bw.util
		plugin.state.alive = true
		task.spawn(function()
			repeat task.wait() until ctx.store.equippedKit ~= "" and ctx.store.matchState ~= 0 or not plugin.enabled
			if not plugin.enabled then return end
			local kit = ctx.store.equippedKit
			if not plugin.state["kit_" .. kit] and plugin.state.kitToggles[kit] == false then return end
			if kit == "beekeeper" then
				local bees, cleanup = u.collection("bee")
				repeat
					if ctx.entity.alive then
						local pos = ctx.entity.self.root.Position
						for _, bee in bees do
							if (bee.Position - pos).Magnitude <= 18 then
								ctx.bw.fire("PickUpBee", "SendToServer", { beeId = bee:GetAttribute("BeeId") })
							end
						end
					end
					task.wait(0.1)
				until not plugin.enabled
				cleanup()
			elseif kit == "metal_detector" then
				local metals, cleanup = u.collection("hidden-metal")
				repeat
					if ctx.entity.alive then
						local pos = ctx.entity.self.root.Position
						for _, m in metals do
							if (m.Position - pos).Magnitude <= 20 then
								ctx.bw.fire("CollectCollectableEntity", "SendToServer", { id = m:GetAttribute("Id") })
							end
						end
					end
					task.wait(0.1)
				until not plugin.enabled
				cleanup()
			elseif kit == "melody" then
				repeat
					if ctx.entity.alive and u.getItem("guitar") then
						local pos = ctx.entity.self.root.Position
						local best, bestHp, bestMag = nil, math.huge, 30
						for _, ent in ipairs(ctx.entity.list) do
							if ent.player and ent.player:GetAttribute("Team") == ctx.player:GetAttribute("Team") then
								local mag = (pos - ent.root.Position).Magnitude
								if mag <= 30 and ent.health < bestHp and ent.health < ent.maxHealth then
									best, bestHp, bestMag = ent, ent.health, mag
								end
							end
						end
						if best then
							ctx.bw.fire("GuitarHeal", "SendToServer", { healTarget = best.character })
						end
					end
					task.wait(0.1)
				until not plugin.enabled
			elseif kit == "miner" then
				local stones, cleanup = u.collection("petrified-player")
				repeat
					if ctx.entity.alive then
						local pos = ctx.entity.self.root.Position
						for _, stone in stones do
							if (stone.Position - pos).Magnitude <= 6 then
								ctx.bw.fire("DestroyPetrifiedPlayer", "SendToServer", { petrifyId = stone:GetAttribute("PetrifyId") })
							end
						end
					end
					task.wait(0.1)
				until not plugin.enabled
				cleanup()
			elseif kit == "summoner" then
				repeat
					local target = ctx.entity.nearest({ range = 31, players = true })
					if target and ctx.entity.alive then
						local pos = ctx.entity.self.root.Position
						local dir = CFrame.lookAt(pos, target.root.Position).LookVector
						pos = pos + dir * math.max((pos - target.root.Position).Magnitude - 16, 0)
						ctx.bw.fire("SummonerClawAttackRequest", "SendToServer", {
							position = pos,
							direction = dir,
							clientTime = workspace:GetServerTimeNow(),
						})
					end
					task.wait(0.1)
				until not plugin.enabled
			end
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
	end,
}
