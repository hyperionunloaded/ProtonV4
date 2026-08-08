--proton-cache:build
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

return {
	id = "ShopQuickBuy",
	category = "utility",
	settings = {
		{ id = "holdDelay", kind = "range", default = 0.15, min = 0, max = 1, step = 0.01 },
		{ id = "cps", kind = "range", default = 20, min = 1, max = 20 },
	},
	init = function(ctx, plugin)
		plugin.state.holding = false
		plugin.state.clickThread = nil
	end,
	enable = function(ctx, plugin, host)
		local u = ctx.bw.util
		local function getShopId()
			if not ctx.entity.alive then return end
			local pos = ctx.entity.self.root.Position
			for _, v in ctx.store.shop or {} do
				if v.Shop and (v.RootPart.Position - pos).Magnitude <= 20 then
					return v.Id
				end
			end
		end
		local function getHoveredItem()
			local mousepos = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
			for _, v in ctx.player.PlayerGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
				local obj = v
				while obj and obj ~= ctx.player.PlayerGui do
					local itemType = obj.Name:match("^(.+)_ShopItemCard$")
					if itemType then return itemType end
					obj = obj.Parent
				end
			end
		end
		local Shop = require(game:GetService("ReplicatedStorage").TS.games.bedwars.shop["bedwars-shop"]).Shop
		local function purchase(itemType, shopId)
			local item = Shop.getShopItem(itemType, ctx.player, { shopId = shopId })
			if not item then return end
			ctx.bw.handler:Get("BedwarsPurchaseItem"):Fire("CallServerAsync", { shopItem = item, shopId = shopId })
		end
		local function startClicking(itemType)
			if plugin.state.clickThread then task.cancel(plugin.state.clickThread) end
			plugin.state.clickThread = task.spawn(function()
				repeat
					local shopId = ctx.bw.appController:isAppOpen("BedwarsItemShopApp") and getShopId()
					if shopId then purchase(itemType, shopId) end
					task.wait(1 / (plugin.state.cps or 20))
				until not plugin.state.holding
				plugin.state.clickThread = nil
			end)
		end
		host:track(UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			if not ctx.bw.appController:isAppOpen("BedwarsItemShopApp") then return end
			local itemType = getHoveredItem()
			if not itemType then return end
			plugin.state.holding = true
			task.delay(plugin.state.holdDelay or 0.15, function()
				if plugin.state.holding and getHoveredItem() == itemType then
					startClicking(itemType)
				end
			end)
		end))
		host:track(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				plugin.state.holding = false
			end
		end))
	end,
	disable = function(ctx, plugin)
		plugin.state.holding = false
		if plugin.state.clickThread then
			task.cancel(plugin.state.clickThread)
			plugin.state.clickThread = nil
		end
	end,
}
