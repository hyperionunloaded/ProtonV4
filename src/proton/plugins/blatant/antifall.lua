--proton-cache:build
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local function lowestBlockY(bw)
	local store = bw.BlockController:getStore()
	local best = math.huge
	for _, pos in store:getAllBlockPositions() do
		local world = pos * 3
		if world.Y < best then
			best = world.Y
		end
	end
	return best
end

return {
	id = "AntiFall",
	category = "blatant",
	settings = {
		{ id = "mode", kind = "drop", default = "Normal", options = { "Normal", "Collide", "Velocity" } },
	},
	init = function(ctx, plugin)
		plugin.state.part = nil
		plugin.state.alive = false
		plugin.state.guide = nil
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		plugin.state.alive = true
		task.spawn(function()
			repeat task.wait() until ctx.store.matchState ~= 0 or not plugin.enabled
			if not plugin.enabled then return end
			local y = lowestBlockY(bw)
			if y == math.huge then return end
			local part = Instance.new("Part")
			part.Size = Vector3.new(10000, 1, 10000)
			part.Transparency = 0.5
			part.Material = Enum.Material.ForceField
			part.Position = Vector3.new(0, y - 2, 0)
			part.CanCollide = host:get(plugin, "mode", "Normal") == "Collide"
			part.Anchored = true
			part.CanQuery = false
			part.Parent = Workspace
			plugin.state.part = part
			host:setRef("blatant:antiFallPart", part)
			local debounce = 0
			host:track(part.Touched:Connect(function(hit)
				if hit.Parent ~= ctx.player.Character or not ctx.entity.alive then return end
				if tick() < debounce then return end
				debounce = tick() + 0.1
				local mode = host:get(plugin, "mode", "Normal")
				if mode == "Velocity" then
					local root = ctx.entity.self.root
					root.Velocity = Vector3.new(root.Velocity.X, 100, root.Velocity.Z)
					return
				end
				if mode == "Normal" then
					local root = ctx.entity.self.root
					plugin.state.guide = Vector3.new(root.Position.X, y, root.Position.Z)
				end
			end))
		end)
		local ray = RaycastParams.new()
		ray.RespectCanCollide = true
		host:track(RunService.PreSimulation:Connect(function()
			if not plugin.state.guide or not ctx.entity.alive then return end
			local flyOn = ctx.host and ctx.host.plugins.Fly and ctx.host.plugins.Fly.enabled
			local ljOn = ctx.host and ctx.host.plugins.LongJump and ctx.host.plugins.LongJump.enabled
			if flyOn or ljOn then
				plugin.state.guide = nil
				host:setRef("blatant:antiFallDir", nil)
				return
			end
			local root = ctx.entity.self.root
			local top = plugin.state.guide
			local delta = (top - root.Position) * Vector3.new(1, 0, 1)
			local dir = delta.Magnitude > 0 and delta.Unit or Vector3.zero
			host:setRef("blatant:antiFallDir", dir)
			root.CFrame += Vector3.new(0, top.Y - root.Position.Y, 0)
			ray.FilterDescendantsInstances = { Workspace.CurrentCamera, ctx.player.Character }
			ray.CollisionGroup = root.CollisionGroup
			local friction = host:getRef("blatant:friction") or {}
			if not friction.Speed and dir.Magnitude > 0 then
				root.AssemblyLinearVelocity = dir * 20 + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
			end
			if delta.Magnitude < 1 then
				plugin.state.guide = nil
				host:setRef("blatant:antiFallDir", nil)
			end
		end))
	end,
	disable = function(ctx, plugin, host)
		plugin.state.alive = false
		plugin.state.guide = nil
		if plugin.state.part then
			plugin.state.part:Destroy()
			plugin.state.part = nil
		end
		host:setRef("blatant:antiFallPart", nil)
		host:setRef("blatant:antiFallDir", nil)
	end,
}
