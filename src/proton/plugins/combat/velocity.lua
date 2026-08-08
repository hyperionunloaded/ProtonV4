--proton-cache:build
return {
	id = "Velocity",
	category = "combat",
	settings = {
		{ id = "horizontal", kind = "range", default = 0, min = 0, max = 100 },
		{ id = "vertical", kind = "range", default = 0, min = 0, max = 100 },
		{ id = "chance", kind = "range", default = 100, min = 0, max = 100 },
		{ id = "onlyTarget", kind = "toggle", default = false },
	},
	init = function(ctx, plugin, host)
		plugin.state._old = nil
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		local rng = Random.new()
		local old = bw.knockbackUtil.applyKnockback
		plugin.state._old = old
		bw.knockbackUtil.applyKnockback = function(root, mass, dir, knockback, ...)
			if rng:NextNumber(0, 100) > host:get(plugin, "chance", 100) then
				return
			end
			if host:get(plugin, "onlyTarget", false) then
				local target = ctx.entity.nearest({ range = 50, players = true })
				if not target then return end
			end
			knockback = knockback or {}
			local h = host:get(plugin, "horizontal", 0)
			local v = host:get(plugin, "vertical", 0)
			if h == 0 and v == 0 then return end
			knockback.horizontal = (knockback.horizontal or 1) * (h / 100)
			knockback.vertical = (knockback.vertical or 1) * (v / 100)
			return old(root, mass, dir, knockback, ...)
		end
	end,
	disable = function(ctx, plugin)
		if plugin.state._old and ctx.bw then
			ctx.bw.knockbackUtil.applyKnockback = plugin.state._old
			plugin.state._old = nil
		end
	end,
}
