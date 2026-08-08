--proton-cache:build
﻿local util = require(script.Parent.Parent.Parent.game.util)
return {
	id = "AutoTaliyah", category = "minigames",
	settings = { { id = "iron", kind = "toggle", default = true }, { id = "emerald", kind = "toggle", default = true }, { id = "diamond", kind = "toggle", default = true }, { id = "amount", kind = "range", default = 2, min = 1, max = 1000 } },
	init = function(ctx, plugin) plugin.state.alive = false end,
	enable = function(ctx, plugin)
		local bw = ctx.bw
		local TaliyahUtil = require(game:GetService("ReplicatedStorage").TS.games.bedwars.kit.kits.taliyah["taliyah-util"]).TaliyahUtil
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive then
					local pos = util.pos(ctx)
					for _, v in ctx.store.shop or {} do
						if v.Shop and v.RootPart and (v.RootPart.Position - pos).Magnitude <= 20 then
							local chickenData = TaliyahUtil:getPrice()
							local ok = (chickenData.currency == "emerald" and plugin.state.emerald ~= false) or (chickenData.currency == "iron" and plugin.state.iron ~= false) or (chickenData.currency == "diamond" and plugin.state.diamond ~= false)
							if ok and chickenData.price >= (plugin.state.amount or 2) then
								local item = bw.shop.getShopItem("chicken_shop_item", ctx.player)
								bw.handler:Get("BedwarsPurchaseItem"):Fire("CallServerAsync", { shopItem = item, shopId = v.Id })
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
