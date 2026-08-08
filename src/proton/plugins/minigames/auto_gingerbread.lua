--proton-cache:build
return {
	id = "AutoGingerbread",
	category = "minigames",
	settings = {
		{ id = "break", kind = "toggle", default = true },
		{ id = "jump", kind = "toggle", default = false },
		{ id = "legitSwitch", kind = "toggle", default = false },
		{ id = "ownOnly", kind = "toggle", default = true },
		{ id = "range", kind = "range", default = 30, min = 1, max = 50 },
	},
	init = function(ctx, plugin)
		plugin.state.old = nil
	end,
	enable = function(ctx, plugin)
		local ctrl = ctx.bw.GingerbreadController or ctx.bw.CannonHandController
		if not ctrl or not ctrl.launchSelf then return end
		plugin.state.old = ctrl.launchSelf
		local old = plugin.state.old
		ctrl.launchSelf = function(self, block, ...)
			local ret = old(self, block, ...)
			if plugin.state.break ~= false and block and block.Parent and ctx.entity.alive then
				local root = ctx.entity.self.root
				if (root.Position - block.Position).Magnitude <= (plugin.state.range or 30) then
					if not plugin.state.ownOnly or block:GetAttribute("PlacedByUserId") == ctx.player.UserId then
						task.delay(0.02, function()
							if plugin.enabled then
								task.spawn(ctx.bw.breakBlock, block, true, true, nil, plugin.state.legitSwitch)
							end
						end)
					end
				end
			end
			if plugin.state.jump and ctx.entity.alive then
				ctx.entity.self.humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
			return ret
		end
	end,
	disable = function(ctx, plugin)
		local ctrl = ctx.bw.GingerbreadController or ctx.bw.CannonHandController
		if ctrl and plugin.state.old then
			ctrl.launchSelf = plugin.state.old
			plugin.state.old = nil
		end
	end,
}
