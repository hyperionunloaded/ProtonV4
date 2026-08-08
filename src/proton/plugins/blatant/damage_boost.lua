--proton-cache:build
return {
	id = "DamageBoost",
	category = "blatant",
	settings = {},
	init = function(ctx, plugin)
		plugin.state.stack = 0
		plugin.state.kbSpeed = 0
		plugin.state.kbBoost = 0
	end,
	enable = function(ctx, plugin, host)
		local ok, zap = pcall(function()
			return require(ctx.player.PlayerScripts.TS.lib.network)
		end)
		if not ok or not zap or not zap.EntityDamageEventZap then return end
		host:track(zap.EntityDamageEventZap.On(function(entityInstance, _, _, _, fromEntity, knockbackMultiplier)
			if not ctx.entity.alive then return end
			if entityInstance ~= ctx.player.Character then return end
			if tick() <= plugin.state.stack then return end
			local longJump = ctx.host and ctx.host.plugins.LongJump
			if longJump and longJump.enabled then return end
			local horizontal = knockbackMultiplier and knockbackMultiplier.horizontal or 0
			local mag = ctx.bw.knockbackUtil.calculateKnockbackVelocity(Vector3.one, 1, {
				vertical = 0,
				horizontal = horizontal,
			}).Magnitude * (0.9 + (ctx.store.ping and ctx.store.ping.total or 0))
			plugin.state.kbSpeed = mag
			plugin.state.stack = tick() + (mag / 45)
			plugin.state.kbBoost = tick() + (horizontal / 3.5)
			local motion = host:getRef("blatant:motion") or {}
			motion.kbSpeed = plugin.state.kbSpeed
			motion.kbBoost = plugin.state.kbBoost
			host:setRef("blatant:motion", motion)
		end))
	end,
	disable = function(ctx, plugin, host)
		plugin.state.stack = 0
		plugin.state.kbSpeed = 0
		plugin.state.kbBoost = 0
		local motion = host:getRef("blatant:motion") or {}
		motion.kbSpeed = 0
		motion.kbBoost = 0
		host:setRef("blatant:motion", motion)
	end,
}
