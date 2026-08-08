--proton-cache:build
local HttpService = game:GetService("HttpService")

return {
	id = "AutoShoot",
	category = "utility",
	settings = {
		{ id = "targetCheck", kind = "toggle", default = true },
		{ id = "players", kind = "toggle", default = true },
		{ id = "fireMin", kind = "range", default = 0.05, min = 0, max = 1, step = 0.01 },
		{ id = "fireMax", kind = "range", default = 0.12, min = 0, max = 1, step = 0.01 },
		{ id = "switchDelay", kind = "range", default = 0.02, min = 0, max = 1, step = 0.01 },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
		plugin.state.fireDelays = {}
	end,
	enable = function(ctx, plugin)
		local u = ctx.bw.util
		plugin.state.alive = true
		task.spawn(function()
			repeat
				if ctx.entity.alive and ctx.store.hand.toolType == "sword" and (tick() - ctx.bw.swordController.lastSwing) < 0.2 then
					local hotbar = ctx.store.hand.tool and u.getHotbar(ctx.store.hand.tool)
					for _, item in ctx.store.inventory.inventory.items do
						local meta = ctx.bw.itemMeta[item.itemType]
						local proj = meta and meta.projectileSource
						if proj then
							local ammo = proj.ammoItemTypes and proj.ammoItemTypes[1] or item.itemType
							local projectile = proj.projectileType(ammo)
							local pmeta = ctx.bw.projectileMeta[projectile]
							if pmeta and (plugin.state.fireDelays[item.itemType] or 0) < tick() then
								local ent = ctx.entity.nearest({ range = 22, players = plugin.state.players ~= false })
								if not plugin.state.targetCheck or ent then
									if ent and u.hotbarSwitch(u.getHotbar(item.tool)) then
										local origin = ctx.entity.self.root.Position
										local shootPos = (CFrame.new(origin, ent.root.Position) * CFrame.new(
											-ctx.bw.bowConstantsTable.RelX,
											-ctx.bw.bowConstantsTable.RelY,
											-ctx.bw.bowConstantsTable.RelZ
										)).Position
										local dir = CFrame.lookAt(shootPos, ent.root.Position).LookVector
										local speed = pmeta.launchVelocity
										local id = HttpService:GenerateGUID(true)
										ctx.bw.projectileController:createLocalProjectile(pmeta, ammo, projectile, shootPos, id, dir * speed, { drawDurationSeconds = 1 })
										ctx.bw.handler:Get("ProjectileFire"):Fire("CallServerAsync",
											item.tool, ammo, projectile, shootPos, origin, dir * speed, id,
											{ drawDurationSeconds = 1, shotId = HttpService:GenerateGUID(false) },
											workspace:GetServerTimeNow() - 0.045
										)
										plugin.state.fireDelays[item.itemType] = tick() + u.randRange(plugin.state.fireMin or 0.05, plugin.state.fireMax or 0.12) + (pmeta.fireDelaySec or 0)
										task.wait(plugin.state.switchDelay or 0.02)
									end
								end
							end
						end
					end
					if hotbar then u.hotbarSwitch(hotbar) end
				end
				task.wait(0.1)
			until not plugin.enabled
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
		table.clear(plugin.state.fireDelays)
	end,
}
