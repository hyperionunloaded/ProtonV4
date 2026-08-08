--proton-cache:build
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

return {
	id = "NoFall",
	category = "blatant",
	settings = {},
	init = function(ctx, plugin)
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin, host)
		plugin.state.alive = true
		host:track(RunService.PostSimulation:Connect(function(dt)
			if not plugin.enabled or not ctx.entity.alive then return end
			if ctx.store.matchState ~= 1 then return end
			local root = ctx.entity.self.root
			local velo = root.Velocity
			if velo.Y < -45 then
				root.Velocity = Vector3.new(0, 2.5 + dt, 0)
				ctx.entity.self.humanoid:ChangeState(Enum.HumanoidStateType.Landed)
				RunService.PreRender:Wait()
				root.Velocity = velo
			end
		end))
		host:track(ctx.entity.events.localAdded:connect(function()
			if plugin.enabled then
				task.wait(0.5)
				if plugin.enabled then
					host:disable("NoFall")
					host:enable("NoFall")
				end
			end
		end))
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
	end,
}
