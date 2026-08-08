--proton-cache:build
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local function baseSpeed(ctx, host)
	local motion = host:getRef("blatant:motion") or {}
	if motion.kbBoost and motion.kbBoost > tick() then
		return 20 + (motion.kbSpeed or 0)
	end
	return 20
end

return {
	id = "Fly",
	category = "blatant",
	settings = {
		{ id = "value", kind = "range", default = 23, min = 1, max = 23 },
		{ id = "vertical", kind = "range", default = 50, min = 1, max = 150 },
		{ id = "wallCheck", kind = "toggle", default = true },
		{ id = "popBalloons", kind = "toggle", default = true },
		{ id = "tpDown", kind = "toggle", default = true },
	},
	init = function(ctx, plugin)
		plugin.state.up = 0
		plugin.state.down = 0
		plugin.state.oldDeflate = nil
		plugin.state.tpToggle = true
		plugin.state.oldY = nil
		plugin.state.tpTick = 0
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		local friction = host:getRef("blatant:friction") or {}
		friction.Fly = true
		host:setRef("blatant:friction", friction)
		local balloon = bw.BalloonController
		if not balloon then return end
		plugin.state.oldDeflate = balloon.deflateBalloon
		balloon.deflateBalloon = function() end
		local char = ctx.player.Character
		if char and (char:GetAttribute("InflatedBalloons") or 0) == 0 then
			for _, item in ctx.bw.getInventory(ctx.player).items do
				if item.itemType == "balloon" then
					balloon:inflateBalloon()
					break
				end
			end
		end
		local ray = RaycastParams.new()
		ray.RespectCanCollide = true
		host:track(ctx.player:GetAttributeChangedSignal("InflatedBalloons"):Connect(function()
			if (ctx.player.Character:GetAttribute("InflatedBalloons") or 0) == 0 then
				for _, item in ctx.bw.getInventory(ctx.player).items do
					if item.itemType == "balloon" then
						balloon:inflateBalloon()
						break
					end
				end
			end
		end))
		host:track(RunService.PreSimulation:Connect(function(dt)
			if not plugin.enabled or not ctx.entity.alive then return end
			local root = ctx.entity.self.root
			local charNow = ctx.player.Character
			local allowed = (charNow:GetAttribute("InflatedBalloons") or 0) > 0 or ctx.store.matchState == 2
			local lift = (-0.02 + (allowed and 6 or 0) * (tick() % 0.4 < 0.2 and -1 or 1))
				+ ((plugin.state.up + plugin.state.down) * host:get(plugin, "vertical", 50))
			local moveDir = ctx.entity.self.humanoid.MoveDirection
			local velo = baseSpeed(ctx, host)
			local dest = moveDir * math.max(host:get(plugin, "value", 23) - velo, 0) * dt
			local antiPart = host:getRef("blatant:antiFallPart")
			ray.FilterDescendantsInstances = { ctx.player.Character, Workspace.CurrentCamera, antiPart }
			ray.CollisionGroup = root.CollisionGroup
			if host:get(plugin, "wallCheck", true) then
				local hit = Workspace:Raycast(root.Position, dest, ray)
				if hit then
					dest = (hit.Position + hit.Normal) - root.Position
				end
			end
			if not allowed then
				if plugin.state.tpToggle then
					local airTime = ctx.entity.self.character:GetAttribute("AirTime") or tick()
					if (tick() - airTime) > 2 and not plugin.state.oldY then
						local down = Workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), ray)
						if down and host:get(plugin, "tpDown", true) then
							plugin.state.tpToggle = false
							plugin.state.oldY = root.Position.Y
							plugin.state.tpTick = tick() + 0.11
							root.CFrame = CFrame.lookAlong(
								Vector3.new(root.Position.X, down.Position.Y + ctx.entity.self.humanoid.HipHeight, root.Position.Z),
								root.CFrame.LookVector
							)
						end
					end
				elseif plugin.state.oldY then
					if tick() > plugin.state.tpTick then
						root.CFrame = CFrame.lookAlong(
							Vector3.new(root.Position.X, plugin.state.oldY, root.Position.Z),
							root.CFrame.LookVector
						)
						plugin.state.tpToggle = true
						plugin.state.oldY = nil
					else
						lift = 0
					end
				end
			end
			root.CFrame += dest
			root.AssemblyLinearVelocity = moveDir * velo + Vector3.new(0, lift, 0)
		end))
		host:track(UserInputService.InputBegan:Connect(function(input)
			if UserInputService:GetFocusedTextBox() then return end
			if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
				plugin.state.up = 1
			elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
				plugin.state.down = -1
			end
		end))
		host:track(UserInputService.InputEnded:Connect(function(input)
			if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
				plugin.state.up = 0
			elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
				plugin.state.down = 0
			end
		end))
	end,
	disable = function(ctx, plugin, host)
		local friction = host:getRef("blatant:friction") or {}
		friction.Fly = nil
		host:setRef("blatant:friction", friction)
		local balloon = ctx.bw.BalloonController
		if balloon and plugin.state.oldDeflate then
			balloon.deflateBalloon = plugin.state.oldDeflate
		end
		if host:get(plugin, "popBalloons", true) and ctx.entity.alive then
			local n = ctx.player.Character:GetAttribute("InflatedBalloons") or 0
			for _ = 1, n do
				balloon:deflateBalloon()
			end
		end
		plugin.state.up = 0
		plugin.state.down = 0
	end,
}
