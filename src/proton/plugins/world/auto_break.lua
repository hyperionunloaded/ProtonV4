--proton-cache:build
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

return {
	id = "AutoBreak",
	category = "world",
	settings = {
		{ id = "range", kind = "range", default = 30, min = 1, max = 30 },
		{ id = "speed", kind = "range", default = 0.25, min = 0, max = 0.3, step = 0.01 },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin)
		local bw = ctx.bw
		plugin.state.alive = true
		task.spawn(function()
			repeat
				if ctx.entity.alive and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
					local selector = bw.blockBreaker.clientManager:getBlockSelector()
					local mouse = ctx.player:GetMouse()
					local ray = RaycastParams.new()
					ray.FilterDescendantsInstances = { ctx.player.Character }
					local info = selector:getMouseInfo(1, { ray = ray })
					local block = info and info.target and info.target.blockInstance
					if block then
						local dist = (ctx.entity.self.root.Position - block.Position).Magnitude
						if dist <= (plugin.state.range or 30) then
							ContextActionService:CallFunction("block-break", Enum.UserInputState.Begin, newproxy(true))
						end
					end
				end
				task.wait(plugin.state.speed or 0.25)
			until not plugin.enabled
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
	end,
}
