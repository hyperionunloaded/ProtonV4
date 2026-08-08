--proton-cache:build
local util = require(script.Parent.Parent.Parent.game.util)

local swords = { "wood_sword", "stone_sword", "iron_sword", "diamond_sword", "emerald_sword" }
local armors = { "none", "leather_chestplate", "iron_chestplate", "diamond_chestplate", "emerald_chestplate" }
local axes = { "none", "wood_axe", "stone_axe", "iron_axe", "diamond_axe" }
local pickaxes = { "none", "wood_pickaxe", "stone_pickaxe", "iron_pickaxe", "diamond_pickaxe" }

return {
	id = "AutoBuy",
	category = "inventory",
	settings = {
		{ id = "buySword", kind = "toggle", default = false },
		{ id = "buyArmor", kind = "toggle", default = true },
		{ id = "buyAxe", kind = "toggle", default = false },
		{ id = "buyPickaxe", kind = "toggle", default = false },
		{ id = "buyUpgrades", kind = "toggle", default = true },
		{ id = "onlyBedwars", kind = "toggle", default = true },
		{ id = "guiCheck", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
		plugin.state.shopId = nil
		plugin.state.npctick = tick()
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		plugin.state.alive = true

		local function getShopNPC()
			local shop, items, upgrades, newid = nil, false, false, nil
			if ctx.entity.alive then
				local pos = util.pos(ctx)
				for _, v in ctx.store.shop or {} do
					if v.RootPart and (v.RootPart.Position - pos).Magnitude <= 20 then
						shop = v.Upgrades or v.Shop
						upgrades = upgrades or v.Upgrades
						items = items or v.Shop
						newid = v.Shop and v.Id or newid
					end
				end
			end
			return shop, items, upgrades, newid
		end

		local function canBuy(item, currencytable, amount)
			amount = amount or 1
			if not currencytable[item.currency] then
				local currency = util.getItem(ctx, item.currency)
				currencytable[item.currency] = currency and currency.amount or 0
			end
			return currencytable[item.currency] >= (item.price * amount)
		end

		local function buyItem(item, currencytable)
			if not plugin.state.shopId then return end
			bw.handler:Get("BedwarsPurchaseItem"):Fire("CallServerAsync", {
				shopItem = item,
				shopId = plugin.state.shopId,
			})
			currencytable[item.currency] -= item.price
		end

		local function buyTool(current, tools, currencytable, shop)
			if not shop then return false end
			local idx = current and table.find(tools, current.itemType)
			idx = idx and idx + 1 or math.huge
			local buyable
			for i = idx, #tools do
				local v = bw.shop.getShopItem(tools[i], ctx.player)
				if canBuy(v, currencytable) then buyable = v end
			end
			if buyable then buyItem(buyable, currencytable) return true end
			return false
		end

		task.spawn(function()
			repeat task.wait() until ctx.store.queueType ~= "bedwars_test" or not plugin.enabled
			while plugin.enabled and plugin.state.alive do
				if plugin.state.onlyBedwars ~= false and not ctx.store.queueType:find("bedwars") then
					task.wait(0.5)
					continue
				end
				local _, shop, _, newid = getShopNPC()
				plugin.state.shopId = newid
				if plugin.state.guiCheck then
					if not (bw.appController:isAppOpen("BedwarsItemShopApp") or bw.appController:isAppOpen("TeamUpgradeApp")) then
						shop = nil
					end
				end
				if shop and plugin.state.npctick <= tick() and ctx.store.matchState ~= 2 then
					local currency = {}
					if plugin.state.buyArmor then
						local armor = ctx.store.inventory.inventory.armor[2]
						armor = armor and armor ~= "empty" and armor or util.getBestArmor(ctx, 1)
						local typeName = armor and armor.itemType or "none"
						buyTool({ itemType = typeName }, armors, currency, shop)
					end
					if plugin.state.buySword then
						buyTool(ctx.store.tools.sword, swords, currency, shop)
					end
					if plugin.state.buyAxe then
						buyTool(ctx.store.tools.wood or { itemType = "none" }, axes, currency, shop)
					end
					if plugin.state.buyPickaxe then
						buyTool(ctx.store.tools.stone, pickaxes, currency, shop)
					end
					plugin.state.npctick = tick() + 0.4
				end
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
		plugin.state.npctick = tick()
	end,
}
