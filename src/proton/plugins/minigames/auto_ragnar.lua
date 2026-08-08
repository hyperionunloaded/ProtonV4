--proton-cache:build
﻿local CollectionService = game:GetService("CollectionService")
local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "AutoRagnar", category = "minigames", settings = {},
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin)
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive and ctx.store.equippedKit == "berserker" then
					for _, v in CollectionService:GetTagged("bed") do
						if not v:GetAttribute("Team" .. (ctx.player:GetAttribute("Team") or -1) .. "NoBreak") then
							if (util.pos(ctx) - v.Position).Magnitude <= 22 then
								if ctx.bw.abilityController:canUseAbility("berserker_rage", { disableBlockedAbilityAlert = true }) then
									ctx.bw.abilityController:useAbility("berserker_rage")
								end
								break
							end
						end
					end
				end
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin) plugin.state.alive = false end,
}
