--proton-cache:build
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return {
	id = "AntiDeath",
	category = "blatant",
	settings = {
		{ id = "mode", kind = "drop", default = "Invincibility", options = { "Teleport", "Invincibility" } },
		{ id = "threshold", kind = "range", default = 30, min = 1, max = 100 },
		{ id = "stopThreshold", kind = "range", default = 30, min = 1, max = 100 },
		{ id = "delay", kind = "range", default = 5, min = 1, max = 20 },
		{ id = "notify", kind = "toggle", default = true },
	},
	init = function(ctx, plugin)
		plugin.state.oldRoot = nil
		plugin.state.clone = nil
		plugin.state.hip = 2.7
		plugin.state.paused = 0
		plugin.state.activated = 0
		plugin.state.floatTime = 0
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		local ent = ctx.entity
		plugin.state.alive = true
		plugin.state.floatTime = tick()

		local function createClone()
			if ctx.store.rootpart then return false end
			if not ent.alive or ent.self.health <= 0 then return false end
			local oldRoot = ent.self.root
			if oldRoot and not oldRoot.Parent then return false end
			plugin.state.hip = ent.self.humanoid.HipHeight
			plugin.state.oldRoot = oldRoot
			local char = ctx.player.Character
			if not char or not char.Parent then return false end
			char.Parent = ReplicatedStorage
			local clone = oldRoot:Clone()
			clone.Parent = char
			oldRoot.Transparency = 1
			oldRoot.Parent = workspace
			ctx.store.rootpart = oldRoot
			char.PrimaryPart = clone
			char.Parent = workspace
			bw.query:setQueryIgnored(clone, true)
			bw.query:setQueryIgnored(oldRoot, true)
			plugin.state.clone = clone
			return true
		end

		local function destroyClone()
			local char = ctx.player.Character
			local oldRoot = plugin.state.oldRoot
			if oldRoot and oldRoot.Parent and char then
				char.Parent = ReplicatedStorage
				oldRoot.Parent = char
				if plugin.state.clone then
					plugin.state.clone:Destroy()
					plugin.state.clone = nil
				end
				char.PrimaryPart = oldRoot
				char.Parent = workspace
				oldRoot.CanCollide = true
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.HipHeight = plugin.state.hip or 2.6
				end
				oldRoot.Transparency = 1
				plugin.state.oldRoot = nil
				ctx.store.rootpart = nil
				return true
			end
			if plugin.state.clone then
				plugin.state.clone:Destroy()
				plugin.state.clone = nil
			end
			plugin.state.oldRoot = nil
			ctx.store.rootpart = nil
			return false
		end

		host:track(RunService.PreSimulation:Connect(function()
			local oldRoot = plugin.state.oldRoot
			local clone = plugin.state.clone
			if oldRoot and oldRoot.Parent and clone then
				local airTime = ent.self.character:GetAttribute("AirTime") or tick()
				if (tick() - airTime) > 1.7 then
					plugin.state.floatTime = tick() + 0.2
				end
				oldRoot.Velocity = Vector3.new(0, 1, 0)
				local drop = tick() > plugin.state.floatTime and Vector3.new(0, 200, 0) or Vector3.zero
				oldRoot.CFrame = clone.CFrame - drop
			end
		end))

		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				local threshold = host:get(plugin, "threshold", 30) / 100
				local stopAt = host:get(plugin, "stopThreshold", 30) / 100
				local delaySec = host:get(plugin, "delay", 5)
				local mode = host:get(plugin, "mode", "Invincibility")

				if tick() > plugin.state.paused and ent.alive then
					local pct = ent.self.health / math.max(ent.self.maxHealth, 1)
					if pct <= threshold and (tick() - plugin.state.activated) >= delaySec then
						plugin.state.activated = tick()
						if host:get(plugin, "notify", true) and ctx.notify then
							ctx.notify.push("AntiDeath", "Health below threshold", 12, "warning")
						end
						if mode == "Teleport" then
							ent.self.root.CFrame += Vector3.new(0, 100, 0)
							plugin.state.paused = tick() + 5
						elseif mode == "Invincibility" then
							if createClone() then
								plugin.state.paused = tick() + 5
								task.spawn(function()
									local saved = plugin.state.clone and plugin.state.clone.CFrame
									repeat task.wait() until not plugin.enabled or not ent.alive or (ent.self.health / math.max(ent.self.maxHealth, 1)) >= stopAt
									if destroyClone() and saved and ent.alive then
										ent.self.root.CFrame = saved
									end
									plugin.state.paused = tick() + 5
									if plugin.enabled and host:get(plugin, "notify", true) and ctx.notify then
										ctx.notify.push("AntiDeath", "You are visible again", 12, "info")
									end
								end)
							end
						end
					end
				end
				task.wait()
			end
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
		local char = ctx.player.Character
		local oldRoot = plugin.state.oldRoot
		if oldRoot and oldRoot.Parent and char then
			char.Parent = ReplicatedStorage
			oldRoot.Parent = char
			if plugin.state.clone then
				plugin.state.clone:Destroy()
			end
			char.PrimaryPart = oldRoot
			char.Parent = workspace
			oldRoot.CanCollide = true
		end
		plugin.state.clone = nil
		plugin.state.oldRoot = nil
		ctx.store.rootpart = nil
	end,
}
