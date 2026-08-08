--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "AutoZeno", category = "minigames",
	settings = {
		{ id = "targetMode", kind = "drop", default = "Distance", options = { "Distance", "Health", "Damage" } },
		{ id = "limitItem", kind = "toggle", default = true },
		{ id = "useStrike", kind = "toggle", default = true },
		{ id = "useStorm", kind = "toggle", default = false },
		{ id = "autoShockwave", kind = "toggle", default = true },
		{ id = "shockwaveRange", kind = "range", default = 12, min = 1, max = 12 },
		{ id = "range", kind = "range", default = 35, min = 1, max = 60 },
		{ id = "delay", kind = "range", default = 0.5, min = 0, max = 10, step = 0.05 },
		{ id = "players", kind = "toggle", default = true },
		{ id = "npcs", kind = "toggle", default = false },
	},
	init = function(ctx, plugin) plugin.state.attempts = {} plugin.state.alive = false end,
	enable = function(ctx, plugin)
		local bw = ctx.bw
		local wu = bw.wizardUtil
		plugin.state.alive = true
		local function getStaff()
			if plugin.state.limitItem ~= false then
				local tool = ctx.store.hand.tool
				if tool and wu:isWizardStaff(tool.Name) then return tool, tool.Name end
				return nil
			end
			for _, item in ctx.store.inventory.inventory.items do
				if wu:isWizardStaff(item.itemType) and item.tool then return item.tool, item.itemType end
			end
		end
		local function canUse(ability, itemType)
			if not wu:hasAbility(itemType, ability) then return false end
			local ok, allowed = pcall(bw.WizardStaffController.canCastAbility, bw.WizardStaffController, ability)
			if not ok or not allowed then return false end
			ok, allowed = pcall(bw.abilityController.canUseAbility, bw.abilityController, ability, { disableBlockedAbilityAlert = true })
			return ok and allowed
		end
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive then
					local staff, itemType = getStaff()
					if staff then
						local pos = util.pos(ctx)
						local castRange = math.min(plugin.state.range or 35, wu:getCastRange(itemType))
						local shockwave = plugin.state.autoShockwave ~= false and wu:hasAbility(itemType, "SHOCKWAVE")
						local ent = util.pickTarget(ctx, { origin = pos, range = math.max(castRange, shockwave and (plugin.state.shockwaveRange or 12) or 0), players = plugin.state.players ~= false, npcs = plugin.state.npcs == true, sort = plugin.state.targetMode or "Distance" })
						if ent then
							local dist = (pos - ent.root.Position).Magnitude
							local target = ent.root.Position + (ent.humanoid.MoveDirection * (1 + ctx.player:GetNetworkPing()))
							local abilities = {
								{ "LIGHTNING_STORM", plugin.state.useStorm, castRange },
								{ "SHOCKWAVE", shockwave, plugin.state.shockwaveRange or 12 },
								{ "LIGHTNING_STRIKE", plugin.state.useStrike ~= false, castRange },
							}
							for _, ab in abilities do
								if ab[2] and dist <= ab[3] and (plugin.state.attempts[ab[1]] or 0) <= tick() and canUse(ab[1], itemType) then
									plugin.state.attempts[ab[1]] = tick() + math.max(plugin.state.delay or 0.5, 0.25)
									pcall(bw.abilityController.useAbility, bw.abilityController, ab[1], newproxy(true), { target = ab[1] == "SHOCKWAVE" and Vector3.zero or target })
									task.wait(plugin.state.delay or 0.5)
									break
								end
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
