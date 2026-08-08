--proton-cache:build
local Workspace = game:GetService("Workspace")

return {
	id = "ProjectileAimbot",
	category = "blatant",
	settings = {
		{ id = "fov", kind = "range", default = 1000, min = 1, max = 1000 },
		{ id = "part", kind = "drop", default = "RootPart", options = { "RootPart", "Head" } },
		{ id = "sort", kind = "drop", default = "Distance", options = { "Distance", "Damage", "Health" } },
		{ id = "autoCharge", kind = "toggle", default = true },
		{ id = "aimChange", kind = "toggle", default = true },
		{ id = "otherProjectiles", kind = "toggle", default = true },
		{ id = "players", kind = "toggle", default = true },
		{ id = "npcs", kind = "toggle", default = true },
	},
	init = function(ctx, plugin)
		plugin.state.old = nil
	end,
	enable = function(ctx, plugin, host)
		local ctrl = ctx.bw.ProjectileController
		if not ctrl then return end
		plugin.state.old = ctrl.calculateImportantLaunchValues
		ctrl.calculateImportantLaunchValues = function(self, projmeta, worldmeta, origin, shootpos, ...)
			local target = ctx.entity.nearest({
				range = host:get(plugin, "fov", 1000),
				players = host:get(plugin, "players", true),
				npcs = host:get(plugin, "npcs", true),
				part = host:get(plugin, "part", "RootPart") == "Head" and "head" or "root",
			})
			if target and projmeta then
				local name = projmeta.projectile or ""
				if not host:get(plugin, "otherProjectiles", true) and not name:find("arrow") then
					return plugin.state.old(self, projmeta, worldmeta, origin, shootpos, ...)
				end
				local pos = shootpos or (self.getLaunchPosition and self:getLaunchPosition(origin))
				if not pos then
					return plugin.state.old(self, projmeta, worldmeta, origin, shootpos, ...)
				end
				local meta = projmeta.getProjectileMeta and projmeta:getProjectileMeta() or ctx.bw.projectileMeta[name] or {}
				local speed = meta.launchVelocity or 100
				local gravity = (meta.gravitationalAcceleration or 196.2) * (projmeta.gravityMultiplier or 1)
				local lifetime = (worldmeta and meta.predictionLifetimeSec) or meta.lifetimeSec or 3
				local node = host:get(plugin, "part", "RootPart") == "Head" and target.head or target.root
				local aim = CFrame.new(pos, node.Position)
				local vel = aim.LookVector * speed
				if host:get(plugin, "aimChange", true) and not host:get(plugin, "autoCharge", true) then
					vel = vel * (projmeta.velocityMultiplier or 1)
				end
				return {
					initialVelocity = vel,
					positionFrom = pos,
					deltaT = lifetime,
					gravitationalAcceleration = gravity,
					drawDurationSeconds = host:get(plugin, "autoCharge", true) and 5 or (projmeta.drawDurationSeconds or 1),
				}
			end
			return plugin.state.old(self, projmeta, worldmeta, origin, shootpos, ...)
		end
	end,
	disable = function(ctx, plugin)
		local ctrl = ctx.bw.ProjectileController
		if ctrl and plugin.state.old then
			ctrl.calculateImportantLaunchValues = plugin.state.old
			plugin.state.old = nil
		end
	end,
}
