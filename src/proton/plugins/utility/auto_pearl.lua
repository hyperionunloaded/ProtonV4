--proton-cache:build
local HttpService = game:GetService("HttpService")

return {
	id = "AutoPearl",
	category = "utility",
	settings = {
		{ id = "legitSwitch", kind = "toggle", default = true },
		{ id = "switchBack", kind = "toggle", default = true },
		{ id = "onlyLanded", kind = "toggle", default = false },
		{ id = "limitItem", kind = "toggle", default = false },
		{ id = "backMin", kind = "range", default = 0.1, min = 0, max = 2, step = 0.01 },
		{ id = "backMax", kind = "range", default = 0.2, min = 0, max = 2, step = 0.01 },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin)
		local u = ctx.bw.util
		local rayCheck = RaycastParams.new()
		rayCheck.RespectCanCollide = true
		rayCheck.FilterType = Enum.RaycastFilterType.Include
		local function findNearGround(origin)
			for _, dir in { Vector3.xAxis, Vector3.zAxis, -Vector3.xAxis, -Vector3.zAxis } do
				for i = 1, 24 do
					local ray = workspace:Raycast(origin + Vector3.yAxis * 3 + dir * i, Vector3.new(0, -60, 0), rayCheck)
					if ray then return ray.Position end
				end
			end
		end
		local function firePearl(pos, spot, item)
			local hotbar, oldHand = u.getHotbar(item.tool), ctx.store.hand
			u.switchItem(item.tool)
			if plugin.state.legitSwitch and hotbar then u.hotbarSwitch(hotbar) end
			local meta = ctx.bw.projectileMeta.telepearl
			local dir = CFrame.lookAt(pos, spot).LookVector * meta.launchVelocity
			ctx.bw.projectileController:createLocalProjectile(meta, "telepearl", "telepearl", pos, nil, dir, { drawDurationSeconds = 1 })
			ctx.bw.handler:Get("ProjectileFire"):Fire("CallServer",
				item.tool, "telepearl", "telepearl", pos, pos, dir,
				HttpService:GenerateGUID(true),
				{ drawDurationSeconds = 1, shotId = HttpService:GenerateGUID(false) },
				workspace:GetServerTimeNow() - 0.045
			)
			if plugin.state.switchBack and oldHand and oldHand.tool then
				task.wait(u.randRange(plugin.state.backMin or 0.1, plugin.state.backMax or 0.2))
				u.switchItem(oldHand.tool)
				if plugin.state.legitSwitch and u.getHotbar(oldHand.tool) then
					u.hotbarSwitch(u.getHotbar(oldHand.tool))
				end
			end
		end
		plugin.state.alive = true
		local check, lastY
		task.spawn(function()
			repeat
				if ctx.entity.alive and (not plugin.state.limitItem or (ctx.store.hand.tool and ctx.store.hand.tool.Name == "telepearl")) then
					local root = ctx.entity.self.root
					local pearl = u.getItem("telepearl")
					rayCheck.FilterDescendantsInstances = { workspace:FindFirstChild("Map") or workspace }
					if ctx.entity.self.humanoid.FloorMaterial ~= Enum.Material.Air then
						lastY = root.CFrame
					end
					if pearl and root.Velocity.Y < -100 and not workspace:Raycast(root.Position, Vector3.new(0, -200, 0), rayCheck) then
						if not check then
							check = true
							local ground = findNearGround(root.CFrame + Vector3.new(0, 40, 0))
								or (lastY and findNearGround(lastY + Vector3.new(0, 5, 0)))
							if ground then firePearl(root.Position, ground, pearl) end
						end
					else
						check = false
					end
				end
				task.wait(0.1)
			until not plugin.enabled
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
	end,
}
