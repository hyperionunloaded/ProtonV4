--proton-cache:build
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local function getAmmo(ctx, check)
	for _, item in ctx.bw.getInventory(ctx.player).items do
		if check.ammoItemTypes and table.find(check.ammoItemTypes, item.itemType) then
			return item.itemType
		end
	end
end

local function collectProjectiles(ctx, list)
	local out = {}
	for _, item in ctx.bw.getInventory(ctx.player).items do
		local src = ctx.bw.itemMeta[item.itemType] and ctx.bw.itemMeta[item.itemType].projectileSource
		if src then
			local ammo = getAmmo(ctx, src)
			if ammo and table.find(list, ammo) then
				out[#out + 1] = {
					item = item,
					ammo = ammo,
					projectile = src.projectileType(ammo),
					meta = src,
				}
			end
		end
	end
	return out
end

local function switchHand(bw, tool)
	bw.handler:Get("SetInvItem"):Fire("CallServerAsync", { hand = tool })
end

return {
	id = "ProjectileAura",
	category = "blatant",
	settings = {
		{ id = "range", kind = "range", default = 50, min = 1, max = 50 },
		{ id = "fireMin", kind = "range", default = 0.05, min = 0, max = 1, step = 0.01 },
		{ id = "fireMax", kind = "range", default = 0.12, min = 0, max = 1, step = 0.01 },
		{ id = "players", kind = "toggle", default = true },
		{ id = "npcs", kind = "toggle", default = true },
	},
	init = function(ctx, plugin)
		plugin.state.delays = {}
		plugin.state.alive = false
		plugin.state.projectiles = { "arrow", "snowball" }
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		plugin.state.alive = true
		local rng = Random.new()
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive then
					local last = bw.swordController and bw.swordController.lastAttack or 0
					if (Workspace:GetServerTimeNow() - last) > 0.3 then
						local ent = ctx.entity.nearest({
							range = host:get(plugin, "range", 50),
							players = host:get(plugin, "players", true),
							npcs = host:get(plugin, "npcs", true),
						})
						if ent then
							local pos = ctx.entity.self.root.Position
							for _, data in collectProjectiles(ctx, plugin.state.projectiles) do
								local item = data.item
								if (plugin.state.delays[item.itemType] or 0) < tick() then
									local meta = bw.projectileMeta[data.projectile]
									if meta then
										local speed = meta.launchVelocity or 100
										local aim = CFrame.lookAt(pos, ent.root.Position).LookVector * speed
										switchHand(bw, item.tool)
										local slot = bw.handler:Get("ProjectileFire")
										if slot.ok and slot.remote then
											local inst = slot.remote.instance or slot.remote
											local shootPos = (CFrame.new(pos, ent.root.Position) * CFrame.new(-0.5, -1, -0.5)).Position
											local id = HttpService:GenerateGUID(true)
											local ok = inst:InvokeServer(
												item.tool, data.ammo, data.projectile,
												shootPos, pos, aim, id,
												{ drawDurationSeconds = 1, shotId = HttpService:GenerateGUID(false) },
												Workspace:GetServerTimeNow() - 0.045
											)
											if not ok then
												plugin.state.delays[item.itemType] = tick()
											end
										end
										local delay = data.meta.fireDelaySec or 0.5
										plugin.state.delays[item.itemType] = tick() + delay
										task.wait(rng:NextNumber(
											host:get(plugin, "fireMin", 0.05),
											host:get(plugin, "fireMax", 0.12)
										))
									end
								end
							end
						end
					end
				end
				task.wait(0.03)
			end
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
		table.clear(plugin.state.delays)
	end,
}
