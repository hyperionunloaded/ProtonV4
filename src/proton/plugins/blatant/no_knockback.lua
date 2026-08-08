--proton-cache:build
return {
	id = "NoKnockback",
	category = "blatant",
	settings = {},
	init = function(ctx, plugin)
		plugin.state.old = nil
	end,
	enable = function(ctx, plugin)
		local kb = ctx.bw.knockbackUtil
		if not kb then return end
		plugin.state.old = kb.applyKnockback
		kb.applyKnockback = function(root, ...)
			if ctx.entity.alive and root == ctx.entity.self.root then
				return
			end
			return plugin.state.old(root, ...)
		end
	end,
	disable = function(ctx, plugin)
		if plugin.state.old and ctx.bw then
			ctx.bw.knockbackUtil.applyKnockback = plugin.state.old
			plugin.state.old = nil
		end
	end,
}
