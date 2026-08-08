--proton-cache:build
﻿return {
	id = "KillEffect",
	category = "legit",
	settings = { { id = "mode", kind = "drop", default = "Bedwars", options = { "Bedwars", "Gravity", "Lightning" } }, { id = "effect", kind = "drop", default = "Default", options = { "Default" } } },
	init = function(ctx, plugin) plugin.state.nameToId = {} end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		local map = plugin.state.nameToId
		for id, v in bw.killEffectMeta do map[v.name] = id end
		host:track(ctx.player:GetAttributeChangedSignal("KillEffectType"):Connect(function()
			if plugin.enabled then
				ctx.player:SetAttribute("KillEffectType", map[plugin.state.effect] or "default")
			end
		end))
		ctx.player:SetAttribute("KillEffectType", map[plugin.state.effect] or "default")
	end,
	disable = function(ctx, plugin)
		ctx.player:SetAttribute("KillEffectType", "default")
	end,
}
