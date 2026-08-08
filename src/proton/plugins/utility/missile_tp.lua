--proton-cache:build
return {
	id = "MissileTP",
	category = "utility",
	settings = {},
	init = function(ctx, plugin) end,
	enable = function(ctx, plugin, host)
		host:disable("MissileTP")
		local u = ctx.bw.util
		if not u.getItem("guided_missile") then return end
		local mouse = ctx.player:GetMouse()
		local target = ctx.entity.nearest({ range = 1000, players = true })
		if not target then return end
		local projectile = ctx.bw.runtimeLib.await(ctx.bw.guidedProjectileController.fireGuidedProjectile:CallServerAsync("guided_missile"))
		if not projectile then
			ctx.notify.push("MissileTP", "Missile on cooldown.", "alert")
			return
		end
		local model = projectile.model
		if not model.PrimaryPart then
			model:GetPropertyChangedSignal("PrimaryPart"):Wait()
		end
		local bodyforce = Instance.new("BodyForce")
		bodyforce.Force = Vector3.new(0, model.PrimaryPart.AssemblyMass * workspace.Gravity, 0)
		bodyforce.Name = "AntiGravity"
		bodyforce.Parent = model.PrimaryPart
		local cam = workspace.CurrentCamera
		repeat
			if target.root and model.Parent then
				model:SetPrimaryPartCFrame(CFrame.lookAlong(target.root.Position, cam.CFrame.LookVector))
			end
			task.wait(0.1)
		until not model or not model.Parent
	end,
	disable = function(ctx, plugin) end,
}
