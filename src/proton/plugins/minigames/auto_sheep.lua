--proton-cache:build
﻿return {
	id = "AutoSheep", category = "minigames",
	settings = { { id = "range", kind = "range", default = 20, min = 1, max = 200 }, { id = "infinite", kind = "toggle", default = false }, { id = "delay", kind = "range", default = 0.1, min = 0, max = 1, step = 0.01 } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin)
		local remote = ctx.bw.client:GetNamespace("SheepHerder"):Get("TameSheep")
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				local model = workspace:FindFirstChild("SheepModel")
				if ctx.entity.alive and model then
					local pos = ctx.entity.self.root.Position
					for _, v in model:GetChildren() do
						if v.PrimaryPart and (plugin.state.infinite or (pos - v.PrimaryPart.Position).Magnitude <= (plugin.state.range or 20)) then
							if (plugin.state.delay or 0) > 0 then task.wait(plugin.state.delay) end
							remote:SendToServer(v.SheepData.Value)
						end
					end
				end
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin) plugin.state.alive = false end,
}
