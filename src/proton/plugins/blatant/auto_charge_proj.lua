--proton-cache:build
return {
	id = "AutoChargeProj",
	category = "blatant",
	settings = {
		{ id = "percentage", kind = "range", default = 50, min = 0, max = 100 },
	},
	init = function(ctx, plugin)
		plugin.state.old = nil
	end,
	enable = function(ctx, plugin)
		local ctrl = ctx.bw.ProjectileController
		if not ctrl then return end
		local pct = (plugin.state.percentage or 50) / 100
		plugin.state.old = ctrl.calculateImportantLaunchValues
		ctrl.calculateImportantLaunchValues = function(...)
			local args = { ... }
			local worldMeta = args[2]
			if worldMeta and args[2] then
				local projName = worldMeta.projectile
				local meta = ctx.bw.projectileMeta[projName]
				if meta then
					worldMeta.drawDurationSeconds = math.max(
						worldMeta.drawDurationSeconds or 0,
						(meta.predictionLifetimeSec or meta.lifetimeSec or 1) * pct
					)
					worldMeta.velocityMultiplier = math.max(worldMeta.velocityMultiplier or 0, pct)
				end
			end
			return plugin.state.old(...)
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
