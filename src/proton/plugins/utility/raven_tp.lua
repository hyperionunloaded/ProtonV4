--proton-cache:build
return {
	id = "RavenTP",
	category = "utility",
	settings = {},
	init = function(ctx, plugin) end,
	enable = function(ctx, plugin, host)
		host:disable("RavenTP")
		local u = ctx.bw.util
		if not u.getItem("raven") then return end
		local target = ctx.entity.nearest({ range = 1000, players = true })
		if not target then return end
		local slot = ctx.bw.handler:Get("SpawnRaven")
		local promise = slot:Fire("CallServerAsync")
		if promise and typeof(promise) == "table" and promise.andThen then
			promise:andThen(function(projectile)
				if not projectile or not projectile.PrimaryPart then return end
				local bodyforce = Instance.new("BodyForce")
				bodyforce.Force = Vector3.new(0, projectile.PrimaryPart.AssemblyMass * workspace.Gravity, 0)
				bodyforce.Parent = projectile.PrimaryPart
				local cam = workspace.CurrentCamera
				task.spawn(function()
					for _ = 1, 20 do
						if target.root and projectile.Parent then
							projectile:SetPrimaryPartCFrame(CFrame.lookAlong(target.root.Position, cam.CFrame.LookVector))
						end
						task.wait(0.05)
					end
				end)
				task.wait(0.3)
				ctx.bw.ravenController:detonateRaven()
			end)
		end
	end,
	disable = function(ctx, plugin) end,
}
