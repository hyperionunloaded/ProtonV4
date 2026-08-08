--proton-cache:build
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local function motionSpeed(ctx, host)
	local motion = host:getRef("blatant:motion") or {}
	if motion.kbBoost and motion.kbBoost > tick() then
		return 20 + (motion.kbSpeed or 0)
	end
	local multi = 0
	local increase = true
	local sprint = ctx.bw.SprintController
	if sprint then
		local modifiers = sprint:getMovementStatusModifier():getModifiers()
		for _, v in modifiers do
			local val = v.constantSpeedMultiplier or 0
			if val > math.max(multi, 1) then
				increase = false
				multi = val - (0.06 * math.round(val))
			end
		end
		for _, v in modifiers do
			multi += math.max((v.moveSpeedMultiplier or 0) - 1, 0)
		end
	end
	if multi > 0 and increase then
		multi += 0.16 + (0.02 * math.round(multi))
	end
	return 20 * (multi + 1)
end

return {
	id = "Speed",
	category = "blatant",
	settings = {
		{ id = "value", kind = "range", default = 23, min = 1, max = 23 },
		{ id = "wallCheck", kind = "toggle", default = true },
		{ id = "autoJump", kind = "toggle", default = false },
		{ id = "alwaysJump", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		local friction = host:getRef("blatant:friction") or {}
		friction.Speed = true
		host:setRef("blatant:friction", friction)
		pcall(function()
			if bw.WindWalkerController and bw.WindWalkerController.updateSpeed then
				debug.setconstant(bw.WindWalkerController.updateSpeed, 7, "constantSpeedMultiplier")
			end
		end)
		local ray = RaycastParams.new()
		ray.RespectCanCollide = true
		plugin.state.alive = true
		host:track(RunService.PreSimulation:Connect(function(dt)
			if not plugin.enabled or not ctx.entity.alive then return end
			local flyOn = ctx.host and ctx.host.plugins.Fly and ctx.host.plugins.Fly.enabled
			local ljOn = ctx.host and ctx.host.plugins.LongJump and ctx.host.plugins.LongJump.enabled
			if flyOn or ljOn then return end
			if bw.StatefulEntityKnockbackController then
				bw.StatefulEntityKnockbackController.lastImpulseTime = math.huge
			end
			local hum = ctx.entity.self.humanoid
			if hum:GetState() == Enum.HumanoidStateType.Climbing then return end
			local root = ctx.entity.self.root
			local velo = motionSpeed(ctx, host)
			local moveDir = host:getRef("blatant:antiFallDir") or hum.MoveDirection
			local dest = moveDir * math.max((host:get(plugin, "value", 23) - velo), 0) * dt
			if host:get(plugin, "wallCheck", true) then
				ray.FilterDescendantsInstances = { ctx.player.Character, Workspace.CurrentCamera }
				ray.CollisionGroup = root.CollisionGroup
				local hit = Workspace:Raycast(root.Position, dest, ray)
				if hit then
					dest = (hit.Position + hit.Normal) - root.Position
				end
			end
			root.CFrame += dest
			root.AssemblyLinearVelocity = moveDir * velo + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
			local attacking = host:getRef("blatant:attacking")
			if host:get(plugin, "autoJump", false) then
				local st = hum:GetState()
				if (st == Enum.HumanoidStateType.Running or st == Enum.HumanoidStateType.Landed)
					and moveDir ~= Vector3.zero
					and (attacking or host:get(plugin, "alwaysJump", false)) then
					hum:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end
		end))
	end,
	disable = function(ctx, plugin, host)
		plugin.state.alive = false
		local friction = host:getRef("blatant:friction") or {}
		friction.Speed = nil
		host:setRef("blatant:friction", friction)
		pcall(function()
			if ctx.bw.WindWalkerController and ctx.bw.WindWalkerController.updateSpeed then
				debug.setconstant(ctx.bw.WindWalkerController.updateSpeed, 7, "moveSpeedMultiplier")
			end
		end)
	end,
}
