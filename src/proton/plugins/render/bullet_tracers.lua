--proton-cache:build
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local style = require(script.Parent._style)

return {
	id = "BulletTracers",
	category = "render",
	settings = {
		{ id = "lifetime", kind = "range", default = 2, min = 0.5, max = 5, step = 0.1 },
		{ id = "thickness", kind = "range", default = 0.08, min = 0.02, max = 0.4, step = 0.02 },
		{ id = "fade", kind = "toggle", default = true },
		{ id = "curve", kind = "range", default = 40, min = 1, max = 100, step = 1 },
	},
	init = function(ctx, plugin)
		plugin.state.folder = nil
	end,
	enable = function(ctx, plugin, host)
		local holder = style.root("BulletTracers")
		plugin.state.holder = holder
		local bw = ctx.bw
		local localPlayer = Players.LocalPlayer

		local ray = RaycastParams.new()
		ray.FilterType = Enum.RaycastFilterType.Exclude

		local function arc(origin, velocity, gravity, travelTime)
			local thick = plugin.state.thickness or 0.08
			local life = plugin.state.lifetime or 2
			local segments = math.clamp(math.floor((plugin.state.curve or 40) / 2), 8, 48)
			local dt = travelTime / segments
			local pos = origin
			local vel = velocity
			local last = pos
			local folder = Instance.new("Folder")
			folder.Parent = holder
			for _ = 1, segments do
				vel = vel + Vector3.new(0, -gravity, 0) * dt
				pos = pos + vel * dt
				local beam = Instance.new("Part")
				beam.Anchored = true
				beam.CanCollide = false
				beam.CanQuery = false
				beam.CanTouch = false
				beam.Material = Enum.Material.Neon
				beam.Color = style.accent
				beam.Transparency = 0.2
				local delta = pos - last
				local len = delta.Magnitude
				if len > 0.01 then
					beam.Size = Vector3.new(thick, thick, len)
					beam.CFrame = CFrame.lookAt(last + delta / 2, pos)
					beam.Parent = folder
				end
				last = pos
			end
			task.delay(life, function()
				if plugin.state.fade then
					for _, part in folder:GetChildren() do
						if part:IsA("BasePart") then
							for t = 1, 10 do
								part.Transparency = 0.2 + t * 0.08
								task.wait(life / 10)
							end
						end
					end
				end
				folder:Destroy()
			end)
		end

		host:track(Workspace.ChildAdded:Connect(function(projectile)
			task.defer(function()
				if not plugin.enabled or not projectile.Parent then return end
				if projectile:GetAttribute("ProjectileShooter") ~= localPlayer.UserId then return end
				local root = projectile:IsA("BasePart") and projectile or projectile.PrimaryPart
				local meta = bw.projectileMeta[projectile.Name]
				if not root or not meta then return end
				local filter = { projectile }
				if localPlayer.Character then
					filter[#filter + 1] = localPlayer.Character
				end
				ray.FilterDescendantsInstances = filter
				local origin = root.Position
				local velocity = root.AssemblyLinearVelocity
				local speed = velocity.Magnitude
				if speed <= 0 then return end
				local unit = velocity / speed
				local gravity = meta.gravitationalAcceleration or Workspace.Gravity
				local hit = Workspace:Raycast(origin, unit * 2000, ray)
				local endpoint = hit and hit.Position or (origin + unit * 2000)
				local travelTime = (endpoint - origin).Magnitude / speed
				arc(origin, velocity, gravity, travelTime)
			end)
		end))
	end,
	disable = function(ctx, plugin)
		if plugin.state.holder then
			style.wipe(plugin.state.holder)
		end
	end,
}
