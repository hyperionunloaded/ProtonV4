--proton-cache:build
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local function pickTarget(ctx, host, plugin, origin, swingRange)
	local best, bestScore
	local maxAngle = math.rad((host:get(plugin, "maxAngle", 360) or 360) / 2)
	local facing = ctx.entity.self.root.CFrame.LookVector * Vector3.new(1, 0, 1)
	local sortMode = host:get(plugin, "sort", "Distance")
	local maxTargets = host:get(plugin, "maxTargets", 5)
	local list = {}
	for _, ent in ipairs(ctx.entity.list) do
		if not ent.targetable then continue end
		if host:get(plugin, "players", true) == false and ent.player then continue end
		if host:get(plugin, "npcs", true) == false and ent.npc then continue end
		if not ctx.entity.isVulnerable(ent) then continue end
		local delta = ent.root.Position - origin
		local flat = delta * Vector3.new(1, 0, 1)
		if flat.Magnitude > 0 then
			local ang = math.acos(math.clamp(facing.Unit:Dot(flat.Unit), -1, 1))
			if ang > maxAngle then continue end
		end
		if delta.Magnitude > swingRange then continue end
		list[#list + 1] = ent
	end
	table.sort(list, function(a, b)
		if sortMode == "Health" then
			return a.health < b.health
		end
		local da = (a.root.Position - origin).Magnitude
		local db = (b.root.Position - origin).Magnitude
		return da < db
	end)
	local out = {}
	for i = 1, math.min(#list, maxTargets) do
		out[i] = list[i]
	end
	return out
end

return {
	id = "OwlAura",
	category = "blatant",
	settings = {
		{ id = "range", kind = "range", default = 50, min = 1, max = 50 },
		{ id = "sort", kind = "drop", default = "Distance", options = { "Distance", "Damage", "Health" } },
		{ id = "players", kind = "toggle", default = true },
		{ id = "npcs", kind = "toggle", default = true },
		{ id = "walls", kind = "toggle", default = true },
	},
	init = function(ctx, plugin)
		plugin.state.owls = {}
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin, host)
		plugin.state.alive = true
		local function trackOwl(obj)
			task.delay(1, function()
				if obj and obj.Parent and obj:GetAttribute("Owner") == ctx.player.UserId then
					plugin.state.owls[#plugin.state.owls + 1] = obj
				end
			end)
		end
		for _, obj in CollectionService:GetTagged("Owl") do
			trackOwl(obj)
		end
		host:track(CollectionService:GetInstanceAddedSignal("Owl"):Connect(trackOwl))
		host:track(CollectionService:GetInstanceRemovedSignal("Owl"):Connect(function(obj)
			local idx = table.find(plugin.state.owls, obj)
			if idx then table.remove(plugin.state.owls, idx) end
		end))
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.store.equippedKit ~= "owl" then
					task.wait(1)
					continue
				end
				if ctx.entity.alive and #plugin.state.owls > 0 then
					local owl = plugin.state.owls[1]
					local part = owl:FindFirstChild("Part")
					if part then
						local origin = part.Position
						local target = ctx.entity.nearest({
							origin = origin,
							range = host:get(plugin, "range", 50),
							players = host:get(plugin, "players", true),
							npcs = host:get(plugin, "npcs", true),
						})
						if target then
							local meta = ctx.bw.projectileMeta.owl_projectile
							local dir = (target.root.Position - origin).Unit * (meta.launchVelocity or 100)
							ctx.bw.fire("OwlAiming", { owl = part, starting = true })
							ctx.bw.fire("OwlFireProjectile", {
								ProjectileRefId = HttpService:GenerateGUID(true),
								direction = dir,
								fromPosition = origin,
								initialVelocity = dir,
							})
							task.wait(ctx.store.ping and ctx.store.ping.total or 0.05)
						end
					end
				end
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
		table.clear(plugin.state.owls)
		ctx.bw.fire("OwlAiming", { starting = false })
	end,
}
