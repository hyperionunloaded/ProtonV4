--proton-cache:build
﻿return {
	id = "HitColor",
	category = "legit",
	settings = { { id = "hue", kind = "range", default = 0, min = 0, max = 1, step = 0.01 }, { id = "opacity", kind = "range", default = 0.4, min = 0, max = 1, step = 0.05 } },
	init = function(ctx, plugin) plugin.state.done = {} plugin.state.alive = false end,
	enable = function(ctx, plugin)
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				for _, ent in ipairs(ctx.entity.list) do
					local hl = ent.character and ent.character:FindFirstChild("_DamageHighlight_")
					if hl then
						if not table.find(plugin.state.done, hl) then plugin.state.done[#plugin.state.done+1] = hl end
						hl.FillColor = Color3.fromHSV(plugin.state.hue or 0, 1, 1)
						hl.FillTransparency = plugin.state.opacity or 0.4
					end
				end
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
		for _, hl in plugin.state.done do
			if hl.Parent then hl.FillColor = Color3.new(1, 0, 0) hl.FillTransparency = 0.4 end
		end
		table.clear(plugin.state.done)
	end,
}
