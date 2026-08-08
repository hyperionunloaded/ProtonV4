--proton-cache:build
local util = require(script.Parent.Parent.Parent.game.util)

return {
	id = "AutoDavey",
	category = "minigames",
	settings = {
		{ id = "break", kind = "toggle", default = true },
		{ id = "jump", kind = "toggle", default = false },
		{ id = "legitSwitch", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.old = nil
	end,
	enable = function(ctx, plugin)
		local ctrl = ctx.bw.CannonHandController
		if not ctrl then return end
		plugin.state.old = ctrl.launchSelf
		local old = plugin.state.old
		ctrl.launchSelf = function(self, block, ...)
			local ret = old(self, block, ...)
			if plugin.state.break ~= false and block and block.Parent and ctx.entity.alive then
				if (util.pos(ctx) - block.Position).Magnitude <= 30 then
					task.delay(0.02, function()
						if plugin.enabled and block.Parent then
							for _ = 1, 2 do
								task.spawn(ctx.bw.breakBlock, block, true, true, nil, plugin.state.legitSwitch)
							end
						end
					end)
				end
			end
			if plugin.state.jump and ctx.entity.alive then
				ctx.entity.self.humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
			return ret
		end
	end,
	disable = function(ctx, plugin)
		local ctrl = ctx.bw.CannonHandController
		if ctrl and plugin.state.old then
			ctrl.launchSelf = plugin.state.old
			plugin.state.old = nil
		end
	end,
}
