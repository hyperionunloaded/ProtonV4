--proton-cache:build
local CollectionService = game:GetService("CollectionService")
local util = require(script.Parent.Parent.Parent.game.util)

return {
	id = "AutoBeekeeper",
	category = "minigames",
	settings = {
		{ id = "collect", kind = "toggle", default = true },
		{ id = "collectRange", kind = "range", default = 20, min = 1, max = 22 },
		{ id = "collectDelay", kind = "range", default = 0.1, min = 0, max = 2, step = 0.01 },
		{ id = "deposit", kind = "toggle", default = true },
		{ id = "depositRange", kind = "range", default = 14, min = 1, max = 14 },
		{ id = "depositDelay", kind = "range", default = 0.1, min = 0, max = 2, step = 0.01 },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		local hives = util.collection(ctx, host, "beehive")
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive then
					local pos = util.pos(ctx)
					if plugin.state.collect ~= false then
						for _, bee in CollectionService:GetTagged("bee") do
							if bee.PrimaryPart and (pos - bee.PrimaryPart.Position).Magnitude <= (plugin.state.collectRange or 20) then
								bw.fire("PickUpBee", { beeId = bee:GetAttribute("BeeId") })
								if (plugin.state.collectDelay or 0) > 0 then task.wait(plugin.state.collectDelay) end
							end
						end
					end
					if plugin.state.deposit ~= false and util.getItem(ctx, "bee") then
						for _, hive in hives do
							if not util.getItem(ctx, "bee") then break end
							local prompt = hive:FindFirstChildWhichIsA("ProximityPrompt")
							if prompt and (hive:GetAttribute("Level") or 0) < 10
								and hive:GetAttribute("PlacedByUserId") == ctx.player.UserId
								and (pos - hive.Position).Magnitude <= (plugin.state.depositRange or 14) then
								fireproximityprompt(prompt)
								if (plugin.state.depositDelay or 0) > 0 then task.wait(plugin.state.depositDelay) end
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
	end,
}
