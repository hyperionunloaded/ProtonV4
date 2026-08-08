--proton-cache:build
return {
	id = "AntiLasso",
	category = "utility",
	settings = {
		{ id = "chance", kind = "range", default = 100, min = 0, max = 100 },
		{ id = "onlyTarget", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.conns = {}
	end,
	enable = function(ctx, plugin, host)
		local rng = Random.new()
		local function onAdded(char)
			local conn = char.ChildAdded:Connect(function(v)
				if not plugin.enabled then return end
				if not v:IsA("Accessory") or not v:FindFirstChild("Rope") then return end
				if rng:NextNumber(1, 100) > (plugin.state.chance or 100) then return end
				if plugin.state.onlyTarget then
					local target = ctx.entity.nearest({ range = 50, players = true })
					if not target then return end
				end
				local root = char.PrimaryPart
				if not root then return end
				root.Anchored = true
				v.Destroying:Once(function()
					task.wait(0.5)
					if root.Parent then
						root.Anchored = false
					end
				end)
			end)
			plugin.state.conns[#plugin.state.conns + 1] = conn
		end
		host:track(ctx.entity.events.localAdded:connect(function()
			task.delay(1, function()
				if ctx.player.Character then
					onAdded(ctx.player.Character)
				end
			end)
		end))
		if ctx.entity.alive and ctx.player.Character then
			onAdded(ctx.player.Character)
		end
	end,
	disable = function(ctx, plugin)
		for _, conn in ipairs(plugin.state.conns) do
			conn:Disconnect()
		end
		table.clear(plugin.state.conns)
	end,
}
