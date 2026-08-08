--proton-cache:build
local util = require(script.Parent.Parent.Parent.game.util)

return {
	id = "AutoConsume",
	category = "inventory",
	settings = {
		{ id = "health", kind = "range", default = 70, min = 1, max = 99 },
		{ id = "speedPotions", kind = "toggle", default = true },
		{ id = "apple", kind = "toggle", default = true },
		{ id = "shieldPotions", kind = "toggle", default = true },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		local function consumeCheck(attribute)
			if not ctx.entity.alive then return end
			local char = ctx.player.Character
			if not char then return end

			if plugin.state.speedPotions ~= false and (not attribute or attribute == "StatusEffect_speed") then
				local speed = util.getItem(ctx, "speed_potion")
				if speed and not char:GetAttribute("StatusEffect_speed") then
					for _ = 1, 4 do
						if bw.call("ConsumeItem", { item = speed.tool }) then break end
					end
				end
			end

			if plugin.state.apple ~= false and (not attribute or attribute:find("Health")) then
				local hp = char:GetAttribute("Health") / char:GetAttribute("MaxHealth")
				if hp <= (plugin.state.health or 70) / 100 then
					local apple = util.getItem(ctx, "orange")
						or (not char:GetAttribute("StatusEffect_golden_apple") and util.getItem(ctx, "golden_apple"))
						or util.getItem(ctx, "apple")
					if apple then
						bw.handler:Get("ConsumeItem"):Fire("CallServerAsync", { item = apple.tool })
					end
				end
			end

			if plugin.state.shieldPotions ~= false and (not attribute or attribute:find("Shield")) then
				if (char:GetAttribute("Shield_POTION") or 0) == 0 then
					local shield = util.getItem(ctx, "big_shield") or util.getItem(ctx, "mini_shield")
					if shield then
						bw.handler:Get("ConsumeItem"):Fire("CallServerAsync", { item = shield.tool })
					end
				end
			end
		end

		plugin.state.alive = true
		consumeCheck()
		host:track(ctx.events.on and ctx.events.on("inventory:changed", consumeCheck) or { Disconnect = function() end })
		host:track(ctx.player.Character:GetAttributeChangedSignal("Health"):Connect(function()
			consumeCheck("Health")
		end))
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
	end,
}
