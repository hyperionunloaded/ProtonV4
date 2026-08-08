--proton-cache:build
return {
	id = "SilentAura",
	category = "combat",
	settings = {
		{ id = "range", kind = "range", default = 18, min = 1, max = 30 },
		{ id = "cpsMin", kind = "range", default = 8, min = 1, max = 20 },
		{ id = "cpsMax", kind = "range", default = 12, min = 1, max = 20 },
		{ id = "maxAngle", kind = "range", default = 360, min = 1, max = 360 },
		{ id = "swingDelay", kind = "range", default = 0.1, min = 0, max = 1, step = 0.05 },
		{ id = "aimSpeed", kind = "range", default = 8, min = 1, max = 20 },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
		plugin.state.lastSwing = 0
	end,
	enable = function(ctx, plugin, host)
		local rng = Random.new()
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive and not ctx.bw.appController:isLayerOpen(ctx.bw.uiLayers.MAIN) then
					local target = ctx.entity.nearest({
						range = plugin.state.range or 18,
						players = true,
					})
					if target then
						local root = ctx.entity.self.root
						local look = (target.root.Position - root.Position) * Vector3.new(1, 0, 1)
						if look.Magnitude > 0 then
							root.CFrame = CFrame.lookAlong(root.Position, look.Unit)
						end
						local hand = ctx.store.hand
						if hand.tool and hand.toolType == "sword" then
							local now = tick()
							if now - (plugin.state.lastSwing or 0) >= (plugin.state.swingDelay or 0.1) then
								ctx.bw.fire("AttackEntity", "SendToServer", {
									weapon = hand.tool.Name,
									targetEntityId = target.character:GetAttribute("EntityId"),
									validate = {
										selfPosition = { value = root.Position },
										targetPosition = { value = target.root.Position },
									},
								})
								plugin.state.lastSwing = now
							end
						end
					end
				end
				local minCps = plugin.state.cpsMin or 8
				local maxCps = plugin.state.cpsMax or 12
				task.wait(1 / rng:NextNumber(minCps, maxCps))
			end
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
	end,
}
