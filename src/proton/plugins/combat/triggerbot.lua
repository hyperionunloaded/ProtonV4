--proton-cache:build
local UserInputService = game:GetService("UserInputService")

return {
	id = "TriggerBot",
	category = "combat",
	settings = {
		{ id = "cpsMin", kind = "range", default = 7, min = 1, max = 9 },
		{ id = "cpsMax", kind = "range", default = 7, min = 1, max = 9 },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin)
		local ray = RaycastParams.new()
		plugin.state.alive = true
		task.spawn(function()
			local rng = Random.new()
			while plugin.enabled and plugin.state.alive do
				local attacked = false
				local bw = ctx.bw
				if not bw.appController:isLayerOpen(bw.uiLayers.MAIN) and ctx.entity.alive then
					local hand = ctx.store.hand
					if hand.toolType == "sword" and bw.DaoController.chargingMaid == nil then
						local meta = bw.itemMeta[hand.tool.Name]
						local attackRange = meta and meta.sword and meta.sword.attackRange or 14.4
						ray.FilterDescendantsInstances = { ctx.player.Character }
						local unit = ctx.player:GetMouse().UnitRay
						local origin = ctx.entity.self.root.Position
						local hit = bw.query:raycast(unit.Origin, unit.Direction * 200, ray)
						local target = false
						if hit and (origin - hit.Instance.Position).Magnitude <= attackRange then
							for _, ent in ipairs(ctx.entity.list) do
								if ent.targetable and hit.Instance:IsDescendantOf(ent.character) then
									if (origin - ent.root.Position).Magnitude <= attackRange then
										target = true
										break
									end
								end
							end
						end
						target = target or bw.swordController:getTargetInRegion(attackRange, 0)
						if target then
							bw.swordController:swingSwordAtMouse()
							attacked = true
						end
					end
				end
				local minCps = plugin.state.cpsMin or 7
				local maxCps = plugin.state.cpsMax or 7
				local delay = attacked and (1 / rng:NextNumber(minCps, maxCps)) or 0.016
				task.wait(delay)
			end
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
	end,
}
