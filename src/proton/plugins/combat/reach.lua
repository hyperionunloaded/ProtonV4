--proton-cache:build
local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Include

return {
	id = "Reach",
	category = "combat",
	settings = {
		{ id = "mode", kind = "drop", default = "Resize", options = { "TouchInterest", "Resize" } },
		{ id = "range", kind = "range", default = 0.5, min = 0, max = 2, step = 0.1 },
		{ id = "chance", kind = "range", default = 100, min = 0, max = 100 },
		{ id = "players", kind = "toggle", default = true },
		{ id = "npcs", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.sizes = {}
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin)
		local rng = Random.new()
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				local char = ctx.player.Character
				local tool = char and char:FindFirstChildWhichIsA("Tool")
				local touch = tool and tool:FindFirstChildWhichIsA("TouchTransmitter", true)
				if touch then
					local mode = plugin.state.mode or "Resize"
					local extra = plugin.state.range or 0.5
					if mode == "TouchInterest" then
						local chars = {}
						for _, ent in ipairs(ctx.entity.list) do
							if ent.targetable then
								if plugin.state.players ~= false or not ent.player then
									if plugin.state.npcs ~= false or not ent.npc then
										chars[#chars + 1] = ent.character
									end
								end
							end
						end
						overlap.FilterDescendantsInstances = chars
						local parts = workspace:GetPartBoundsInBox(
							touch.Parent.CFrame * CFrame.new(0, 0, extra / 2),
							touch.Parent.Size + Vector3.new(0, 0, extra),
							overlap
						)
						for _, part in ipairs(parts) do
							if rng:NextNumber(0, 100) > (plugin.state.chance or 100) then
								break
							end
							firetouchinterest(touch.Parent, part, 1)
							firetouchinterest(touch.Parent, part, 0)
						end
					else
						if not plugin.state.sizes[touch.Parent] then
							plugin.state.sizes[touch.Parent] = touch.Parent.Size
						end
						touch.Parent.Size = plugin.state.sizes[touch.Parent] + Vector3.new(0, 0, extra)
						touch.Parent.Massless = true
					end
				end
				task.wait()
			end
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
		for part, size in pairs(plugin.state.sizes) do
			if part.Parent then
				part.Size = size
				part.Massless = false
			end
		end
		table.clear(plugin.state.sizes)
	end,
}
