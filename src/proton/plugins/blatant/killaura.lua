--proton-cache:build
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local function switchHand(bw, tool)
	bw.handler:Get("SetInvItem"):Fire("CallServerAsync", { hand = tool })
end

local function swordData(ctx, host, plugin)
	if host:get(plugin, "requireMouse", false) and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
		return nil
	end
	if host:get(plugin, "guiCheck", false) then
		if ctx.bw.appController:isLayerOpen(ctx.bw.uiLayers.MAIN) then
			return nil
		end
	end
	local hand = ctx.store.hand
	if host:get(plugin, "limitItems", false) then
		if not hand.tool or hand.toolType ~= "sword" then return nil end
		if ctx.bw.DaoController and ctx.bw.DaoController.chargingMaid then return nil end
	end
	if not hand.tool then
		for _, item in ctx.bw.getInventory(ctx.player).items do
			local meta = ctx.bw.itemMeta[item.itemType]
			if meta and meta.sword then
				hand = { tool = item.tool, toolType = "sword" }
				break
			end
		end
	end
	if not hand.tool then return nil end
	local meta = ctx.bw.itemMeta[hand.tool.Name]
	if not meta or not meta.sword then return nil end
	if host:get(plugin, "swingOnly", false) then
		local last = ctx.bw.swordController and ctx.bw.swordController.lastSwing or 0
		if (tick() - last) > 0.2 then return nil end
	end
	return hand, meta
end

local function gather(ctx, host, plugin, origin, swingRange, attackRange)
	local maxAngle = math.rad(host:get(plugin, "maxAngle", 360) / 2)
	local facing = ctx.entity.self.root.CFrame.LookVector * Vector3.new(1, 0, 1)
	local cap = host:get(plugin, "maxTargets", 5)
	local rows = {}
	for _, ent in ipairs(ctx.entity.list) do
		if not ent.targetable then continue end
		if host:get(plugin, "players", true) == false and ent.player then continue end
		if host:get(plugin, "npcs", true) == false and ent.npc then continue end
		if not ctx.entity.isVulnerable(ent) then continue end
		local delta = ent.root.Position - origin
		if delta.Magnitude > swingRange then continue end
		local flat = delta * Vector3.new(1, 0, 1)
		if flat.Magnitude > 0 then
			local ang = math.acos(math.clamp(facing.Unit:Dot(flat.Unit), -1, 1))
			if ang > maxAngle then continue end
		end
		rows[#rows + 1] = { ent = ent, delta = delta, attack = delta.Magnitude <= attackRange }
	end
	table.sort(rows, function(a, b)
		return a.delta.Magnitude < b.delta.Magnitude
	end)
	local out = {}
	for i = 1, math.min(#rows, cap) do
		out[i] = rows[i]
	end
	return out
end

return {
	id = "Killaura",
	category = "blatant",
	settings = {
		{ id = "swingRange", kind = "range", default = 28, min = 1, max = 28 },
		{ id = "attackRange", kind = "range", default = 28, min = 1, max = 28 },
		{ id = "maxAngle", kind = "range", default = 360, min = 1, max = 360 },
		{ id = "updateRate", kind = "range", default = 60, min = 1, max = 120 },
		{ id = "maxTargets", kind = "range", default = 5, min = 1, max = 5 },
		{ id = "players", kind = "toggle", default = true },
		{ id = "npcs", kind = "toggle", default = true },
		{ id = "requireMouse", kind = "toggle", default = false },
		{ id = "noSwing", kind = "toggle", default = false },
		{ id = "guiCheck", kind = "toggle", default = false },
		{ id = "faceTarget", kind = "toggle", default = false },
		{ id = "limitItems", kind = "toggle", default = false },
		{ id = "swingOnly", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
		plugin.state.animDelay = 0
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				host:setRef("blatant:attacking", false)
				ctx.store.KillauraTarget = nil
				local hand, meta = swordData(ctx, host, plugin)
				local attacked = {}
				if hand and ctx.entity.alive then
					switchHand(bw, hand.tool)
					local origin = ctx.entity.self.root.Position
					local swingRange = host:get(plugin, "swingRange", 28)
					local attackRange = host:get(plugin, "attackRange", 28)
					local rows = gather(ctx, host, plugin, origin, swingRange, attackRange)
					for _, row in ipairs(rows) do
						local ent = row.ent
						attacked[#attacked + 1] = ent
						if not host:getRef("blatant:attacking") then
							host:setRef("blatant:attacking", true)
							ctx.store.KillauraTarget = ent
							if not host:get(plugin, "noSwing", false) and plugin.state.animDelay < tick() and not host:get(plugin, "swingOnly", false) then
								plugin.state.animDelay = tick() + (meta.sword.respectAttackSpeedForEffects and meta.sword.attackSpeed or 0.11)
								bw.swordController:playSwordEffect(meta, false)
							end
						end
						if row.attack then
							local actual = ent.character.PrimaryPart
							if actual then
								local delta = row.delta
								local dir = CFrame.lookAt(origin, actual.Position).LookVector
								local pos = origin + dir * math.max(delta.Magnitude - 14.399, 0)
								bw.swordController.lastAttack = Workspace:GetServerTimeNow()
								ctx.store.attackReach = math.floor(delta.Magnitude * 100) / 100
								ctx.store.attackReachUpdate = tick() + 1
								ctx.bw.fire("AttackEntity", {
									weapon = hand.tool,
									chargedAttack = { chargeRatio = 0 },
									entityInstance = ent.character,
									validate = {
										raycast = {
											cameraPosition = { value = pos },
											cursorDirection = { value = dir },
										},
										targetPosition = { value = actual.Position },
										selfPosition = { value = pos },
									},
								})
							end
						end
					end
					if host:get(plugin, "faceTarget", false) and rows[1] then
						local flat = rows[1].ent.root.Position * Vector3.new(1, 0, 1)
						local root = ctx.entity.self.root
						root.CFrame = CFrame.lookAt(root.Position, Vector3.new(flat.X, root.Position.Y + 0.001, flat.Z))
					end
				end
				local waitTime = #attacked > 0 and (#attacked * 0.02) or (1 / host:get(plugin, "updateRate", 60))
				task.wait(waitTime)
			end
		end)
	end,
	disable = function(ctx, plugin, host)
		plugin.state.alive = false
		ctx.store.KillauraTarget = nil
		host:setRef("blatant:attacking", false)
	end,
}
