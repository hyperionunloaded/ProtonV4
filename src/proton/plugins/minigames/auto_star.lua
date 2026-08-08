--proton-cache:build
﻿local CollectionService = game:GetService("CollectionService")
local util = require(script.Parent.Parent.Parent.game.util)
local ProximityPromptService = game:GetService("ProximityPromptService")
return {
	id = "AutoStar", category = "minigames",
	settings = { { id = "streamer", kind = "toggle", default = false }, { id = "animation", kind = "toggle", default = true }, { id = "range", kind = "range", default = 12, min = 1, max = 20 }, { id = "delay", kind = "range", default = 0.2, min = 0, max = 1, step = 0.01 } },
	init = function(ctx, plugin) plugin.state.cooldowns = {} plugin.state.alive = false end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		plugin.state.alive = true
		host:track(ProximityPromptService.PromptShown:Connect(function(prompt)
			if plugin.state.streamer and prompt.Name == "stars_ProximityPrompt" then task.wait(0.1) prompt:InputHoldBegin() end
		end))
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if not plugin.state.streamer and ctx.entity.alive then
					local pos = util.pos(ctx)
					for _, v in CollectionService:GetTagged("stars") do
						if tick() > (plugin.state.cooldowns[v] or 0) and v.PrimaryPart and (pos - v.PrimaryPart.Position).Magnitude <= (plugin.state.range or 12) then
							if (plugin.state.delay or 0) > 0 then task.wait(plugin.state.delay) end
							if plugin.state.animation ~= false then
								bw.gameAnimationUtil:playAnimation(ctx.player.Character, bw.animationType.PUNCH)
								bw.ViewmodelController:playAnimation(bw.animationType.FP_USE_ITEM)
							end
							bw.StarCollectorController:collectEntity(ctx.player, v, v.Name)
							plugin.state.cooldowns[v] = tick() + 1
						end
					end
				end
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin) plugin.state.alive = false table.clear(plugin.state.cooldowns) end,
}
