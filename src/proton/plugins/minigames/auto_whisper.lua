--proton-cache:build
﻿local CollectionService = game:GetService("CollectionService")
local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "AutoWhisper", category = "minigames",
	settings = { { id = "heal", kind = "toggle", default = true }, { id = "threshold", kind = "range", default = 99, min = 1, max = 100 }, { id = "fly", kind = "toggle", default = true } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin)
		plugin.state.alive = true
		task.spawn(function()
			repeat task.wait() until ctx.store.matchState ~= 0 or not plugin.enabled
			while plugin.enabled and plugin.state.alive do
				local liftReady = plugin.state.fly ~= false and workspace:GetServerTimeNow() - (ctx.player:GetAttribute("OwlLiftReadyTime") or 0) > 0
				local healReady = plugin.state.heal ~= false and workspace:GetServerTimeNow() - (ctx.player:GetAttribute("OwlHealReadyTime") or 0) > 0
				if liftReady or healReady then
					for _, v in CollectionService:GetTagged("Owl") do
						if v:GetAttribute("Owner") == ctx.player.UserId then
							local plr = game:GetService("Players"):GetPlayerByUserId(v:GetAttribute("Target"))
							local char = plr and plr.Character
							local root = char and char:FindFirstChild("HumanoidRootPart")
							if root then
								if liftReady and root.Velocity.Y < -10 then ctx.bw.abilityController:useAbility("OWL_LIFT") end
								local hp, max = char:GetAttribute("Health"), char:GetAttribute("MaxHealth")
								if healReady and max and max > 0 and hp / max <= (plugin.state.threshold or 99) / 100 then
									ctx.bw.abilityController:useAbility("OWL_HEAL")
								end
							end
							break
						end
					end
				end
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin) plugin.state.alive = false end,
}
