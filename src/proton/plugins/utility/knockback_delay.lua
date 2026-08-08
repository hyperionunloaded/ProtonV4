--proton-cache:build
return {
	id = "KnockbackDelay",
	category = "utility",
	settings = {
		{ id = "chance", kind = "range", default = 40, min = 1, max = 100 },
		{ id = "airMin", kind = "range", default = 50, min = 0, max = 500 },
		{ id = "airMax", kind = "range", default = 200, min = 0, max = 500 },
		{ id = "groundMin", kind = "range", default = 50, min = 0, max = 500 },
		{ id = "groundMax", kind = "range", default = 200, min = 0, max = 500 },
		{ id = "targetCheck", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.old = nil
	end,
	enable = function(ctx, plugin)
		local bw = ctx.bw
		local rng = Random.new()
		local old = bw.knockbackUtil.applyKnockback
		plugin.state.old = old
		local function apply(kind, env, ...)
			local root, mass, dir, knockback = ...
			knockback = knockback and table.clone(knockback) or {}
			knockback[kind] = env[kind] and knockback[kind] or 0
			return old(root, mass, dir, knockback, select(5, ...))
		end
		bw.knockbackUtil.applyKnockback = function(...)
			if rng:NextNumber(0, 100) > (plugin.state.chance or 40) then
				return old(...)
			end
			if plugin.state.targetCheck then
				if not ctx.entity.nearest({ range = 50, players = true }) then
					return old(...)
				end
			end
			local env = {}
			local airDelay = ctx.bw.util.randRange(plugin.state.airMin or 50, plugin.state.airMax or 200) / 1000
			local groundDelay = ctx.bw.util.randRange(plugin.state.groundMin or 50, plugin.state.groundMax or 200) / 1000
			task.delay(airDelay, apply, "horizontal", env, ...)
			task.delay(groundDelay, apply, "vertical", env, ...)
		end
	end,
	disable = function(ctx, plugin)
		if plugin.state.old and ctx.bw then
			ctx.bw.knockbackUtil.applyKnockback = plugin.state.old
			plugin.state.old = nil
		end
	end,
}
