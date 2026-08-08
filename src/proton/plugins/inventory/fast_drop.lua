--proton-cache:build
local UserInputService = game:GetService("UserInputService")

return {
	id = "FastDrop",
	category = "inventory",
	settings = {},
	init = function(ctx, plugin)
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin)
		local drop = ctx.bw.ItemDropController
		if not drop then return end
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive and not ctx.store.inventory.opened then
					if (UserInputService:IsKeyDown(Enum.KeyCode.H) or UserInputService:IsKeyDown(Enum.KeyCode.Backspace))
						and UserInputService:GetFocusedTextBox() == nil then
						task.spawn(drop.dropItemInHand, drop)
						task.wait()
					else
						task.wait(0.1)
					end
				else
					task.wait(0.1)
				end
			end
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
	end,
}
