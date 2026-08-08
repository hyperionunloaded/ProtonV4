--proton-cache:build
﻿return {
	id = "Viewmodel",
	category = "legit",
	settings = {
		{ id = "depth", kind = "range", default = 0.8, min = 0, max = 2, step = 0.1 },
		{ id = "horizontal", kind = "range", default = 0.8, min = 0, max = 2, step = 0.1 },
		{ id = "vertical", kind = "range", default = -0.2, min = -0.2, max = 2, step = 0.1 },
		{ id = "noBob", kind = "toggle", default = true },
	},
	init = function(ctx, plugin) plugin.state.oldAnim = nil end,
	enable = function(ctx, plugin)
		local ctrl = ctx.player.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]
		local vm = ctx.bw.ViewmodelController
		ctrl:SetAttribute("ConstantManager_DEPTH_OFFSET", -(plugin.state.depth or 0.8))
		ctrl:SetAttribute("ConstantManager_HORIZONTAL_OFFSET", plugin.state.horizontal or 0.8)
		ctrl:SetAttribute("ConstantManager_VERTICAL_OFFSET", plugin.state.vertical or -0.2)
		if plugin.state.noBob ~= false and vm then
			plugin.state.oldAnim = vm.playAnimation
			vm.playAnimation = function(self, animtype, ...)
				if ctx.bw.animationType and animtype == ctx.bw.animationType.FP_WALK then return end
				return plugin.state.oldAnim(self, animtype, ...)
			end
		end
		ctx.bw.InventoryViewmodelController:handleStore(ctx.bw.store:getState())
	end,
	disable = function(ctx, plugin)
		local ctrl = ctx.player.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]
		ctrl:SetAttribute("ConstantManager_DEPTH_OFFSET", 0)
		ctrl:SetAttribute("ConstantManager_HORIZONTAL_OFFSET", 0)
		ctrl:SetAttribute("ConstantManager_VERTICAL_OFFSET", 0)
		if plugin.state.oldAnim then
			ctx.bw.ViewmodelController.playAnimation = plugin.state.oldAnim
			plugin.state.oldAnim = nil
		end
		ctx.bw.InventoryViewmodelController:handleStore(ctx.bw.store:getState())
	end,
}
