--proton-cache:build
﻿local ProximityPromptService = game:GetService("ProximityPromptService")
local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "AutoMetal", category = "minigames",
	settings = { { id = "range", kind = "range", default = 12, min = 1, max = 20 }, { id = "duration", kind = "range", default = 0.5, min = 0, max = 2, step = 0.05 }, { id = "limitItem", kind = "toggle", default = false } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		plugin.state.alive = true
		host:track(ProximityPromptService.PromptShown:Connect(function(prompt)
			if prompt.Name == "metalDetector" and ctx.entity.alive then task.delay(0.1, prompt.InputHoldBegin, prompt) end
		end))
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive and (plugin.state.limitItem == false or (ctx.store.hand.tool and ctx.store.hand.tool.Name:find("metal"))) then
					local pos = util.pos(ctx)
					for _, v in CollectionService:GetTagged("metalDetector") do
						if v.PrimaryPart and (pos - v.PrimaryPart.Position).Magnitude <= (plugin.state.range or 12) then
							local prompt = v:FindFirstChildWhichIsA("ProximityPrompt")
							if prompt then fireproximityprompt(prompt) task.wait(plugin.state.duration or 0.5) end
						end
					end
				end
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin) plugin.state.alive = false end,
}
