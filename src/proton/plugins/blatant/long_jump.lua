--proton-cache:build
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local function switchHand(bw, tool)
	bw.handler:Get("SetInvItem"):Fire("CallServerAsync", { hand = tool })
end

local function findItem(ctx, name)
	for _, item in ctx.bw.getInventory(ctx.player).items do
		if item.itemType == name or (item.tool and item.tool.Name == name) then
			return item
		end
	end
end

return {
	id = "LongJump",
	category = "blatant",
	settings = {
		{ id = "value", kind = "range", default = 37, min = 1, max = 37 },
		{ id = "cameraDir", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.jumpTick = 0
		plugin.state.jumpSpeed = 0
		plugin.state.direction = nil
		plugin.state.start = nil
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		local friction = host:getRef("blatant:friction") or {}
		friction.LongJump = true
		host:setRef("blatant:friction", friction)
		local ok, zap = pcall(function()
			return require(ctx.player.PlayerScripts.TS.lib.network)
		end)
		if ok and zap and zap.EntityDamageEventZap then
			host:track(zap.EntityDamageEventZap.On(function(entityInstance, _, _, fromPosition, fromEntity, knockbackMultiplier)
				if entityInstance ~= ctx.player.Character or fromEntity ~= ctx.player.Character then return end
				if knockbackMultiplier and knockbackMultiplier.disabled then return end
				local horizontal = knockbackMultiplier and knockbackMultiplier.horizontal or 1
				local boost = bw.knockbackUtil.calculateKnockbackVelocity(Vector3.one, 1, {
					vertical = 0,
					horizontal = horizontal,
				}).Magnitude * 1.1
				if boost >= plugin.state.jumpSpeed then
					local pos = fromPosition
					if typeof(pos) == "Vector3" then
						local vec = ctx.entity.self.root.Position - pos
						plugin.state.jumpSpeed = boost
						plugin.state.jumpTick = tick() + 2.5
						plugin.state.direction = Vector3.new(vec.X, 0, vec.Z).Unit
					end
				end
			end))
		end
		plugin.state.start = ctx.entity.alive and ctx.entity.self.root.Position or nil
		host:track(RunService.PreSimulation:Connect(function(dt)
			if not plugin.enabled or not ctx.entity.alive then return end
			local root = ctx.entity.self.root
			if plugin.state.jumpTick > tick() and plugin.state.direction then
				local extra = (plugin.state.jumpTick - tick()) > 1.1 and plugin.state.jumpSpeed or 0
				root.AssemblyLinearVelocity = plugin.state.direction * (20 + extra)
					+ Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
				if ctx.entity.self.humanoid.FloorMaterial == Enum.Material.Air and not plugin.state.start then
					root.AssemblyLinearVelocity += Vector3.new(0, dt * (Workspace.Gravity - 23), 0)
				else
					root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 15, root.AssemblyLinearVelocity.Z)
				end
				plugin.state.start = nil
			elseif plugin.state.start then
				root.CFrame = CFrame.lookAlong(plugin.state.start, root.CFrame.LookVector)
				root.AssemblyLinearVelocity = Vector3.zero
				plugin.state.jumpSpeed = 0
			end
		end))
		task.spawn(function()
			if not ctx.entity.alive then return end
			local cam = host:get(plugin, "cameraDir", false)
			local look = cam and Workspace.CurrentCamera.CFrame.LookVector or ctx.entity.self.root.CFrame.LookVector
			local hand = ctx.store.hand
			local itemType = hand.tool and hand.tool.Name
			if itemType == "fireball" then
				local item = findItem(ctx, "fireball")
				if item then
					switchHand(bw, item.tool)
					task.wait(0.1)
					local pos = ctx.entity.self.root.Position - look * 0.1
					local shoot = (CFrame.lookAlong(pos, Vector3.new(0, -60, 0)) * CFrame.new(-0.5, -1, -0.5)).Position
					local slot = bw.handler:Get("ProjectileFire")
					if slot.ok and slot.remote then
						local inst = slot.remote.instance or slot.remote
						inst:InvokeServer(item.tool, "fireball", "fireball", shoot, pos, look * 60, HttpService:GenerateGUID(true), { drawDurationSeconds = 1 }, Workspace:GetServerTimeNow() - 0.045)
					end
					plugin.state.jumpSpeed = 4 * host:get(plugin, "value", 37)
					plugin.state.jumpTick = tick() + 2.5
					plugin.state.direction = Vector3.new(look.X, 0, look.Z).Unit
				end
			elseif itemType and itemType:find("_dao") then
				bw.swordController.lastAttack = Workspace:GetServerTimeNow()
				switchHand(bw, hand.tool)
				local rs = game:GetService("ReplicatedStorage")
				local ev = rs:FindFirstChild("events-@easy-games/game-core:shared/game-core-networking@getEvents.Events")
				if ev and ev:FindFirstChild("useAbility") then
					ev.useAbility:FireServer("dash", {
						direction = look,
						origin = ctx.entity.self.root.Position,
						weapon = itemType,
					})
				end
				plugin.state.jumpSpeed = 4.5 * host:get(plugin, "value", 37)
				plugin.state.jumpTick = tick() + 2.4
				plugin.state.direction = Vector3.new(look.X, 0, look.Z).Unit
			end
		end)
	end,
	disable = function(ctx, plugin, host)
		local friction = host:getRef("blatant:friction") or {}
		friction.LongJump = nil
		host:setRef("blatant:friction", friction)
		plugin.state.jumpTick = tick()
		plugin.state.direction = nil
		plugin.state.jumpSpeed = 0
		plugin.state.start = nil
	end,
}
