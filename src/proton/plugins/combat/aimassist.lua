--proton-cache:build
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local function lerpAngle(a, b, t)
	local d = ((b - a + math.pi) % (2 * math.pi)) - math.pi
	return a + d * t
end

return {
	id = "AimAssist",
	category = "combat",
	settings = {
		{ id = "speed", kind = "range", default = 6, min = 1, max = 20 },
		{ id = "range", kind = "range", default = 30, min = 1, max = 30 },
		{ id = "fov", kind = "range", default = 70, min = 1, max = 360 },
		{ id = "perspective", kind = "drop", default = "First person", options = { "First person", "Third person", "Dynamic", "Mouse" } },
		{ id = "sort", kind = "drop", default = "Angle", options = { "Angle", "Distance", "Health" } },
	},
	init = function(ctx, plugin)
		plugin.state.last = nil
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin, host)
		local camera = Workspace.CurrentCamera
		plugin.state.alive = true
		host:track(RunService.PostSimulation:Connect(function(dt)
			if not plugin.enabled or not ctx.entity.alive then
				plugin.state.last = nil
				return
			end
			local ent = ctx.entity.nearest({
				range = plugin.state.range or 30,
				players = true,
			})
			if not ent then
				plugin.state.last = nil
				return
			end
			local root = ctx.entity.self.root
			local flatLook = root.CFrame.LookVector * Vector3.new(1, 0, 1)
			local flatDelta = (ent.root.Position - root.Position) * Vector3.new(1, 0, 1)
			if flatDelta.Magnitude > 0 and flatLook.Magnitude > 0 then
				local ang = math.acos(math.clamp(flatLook.Unit:Dot(flatDelta.Unit), -1, 1))
				if ang >= math.rad((plugin.state.fov or 70) / 2) then return end
			end
			local speed = (plugin.state.speed or 6) * dt * 3
			local mode = plugin.state.perspective or "First person"
			local firstPerson = ctx.entity.self.head.LocalTransparencyModifier == 1
			if mode == "Dynamic" then
				mode = firstPerson and "First person" or "Third person"
			end
			if mode == "Mouse" and mousemoverel then
				local pos, vis = camera:WorldToViewportPoint(ent.root.Position)
				if vis then
					local mouse = UserInputService:GetMouseLocation()
					mousemoverel((pos.X - mouse.X) * speed, (pos.Y - mouse.Y) * speed)
				end
			elseif mode == "First person" and firstPerson then
				local look = CFrame.lookAt(camera.CFrame.Position, ent.root.Position)
				camera.CFrame = camera.CFrame:Lerp(look, speed)
			elseif mode == "Third person" and not firstPerson then
				local dir = (ent.root.Position - root.Position) * Vector3.new(1, 0, 1)
				if dir.Magnitude > 0 then
					ctx.entity.self.humanoid.AutoRotate = false
					root.CFrame = CFrame.lookAlong(root.Position, dir.Unit)
					task.delay(0.1, function()
						if ctx.entity.alive then
							ctx.entity.self.humanoid.AutoRotate = true
						end
					end)
				end
			end
			plugin.state.last = ent
		end))
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
		plugin.state.last = nil
		if ctx.entity.alive then
			ctx.entity.self.humanoid.AutoRotate = true
		end
	end,
}
