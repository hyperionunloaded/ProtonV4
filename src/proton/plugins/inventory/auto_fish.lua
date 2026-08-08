--proton-cache:build
local util = require(script.Parent.Parent.Parent.game.util)

return {
	id = "AutoFish",
	category = "inventory",
	settings = {
		{ id = "autoCast", kind = "toggle", default = true },
		{ id = "autoMinigame", kind = "toggle", default = true },
		{ id = "showLoot", kind = "toggle", default = false },
		{ id = "castDelayMin", kind = "range", default = 0.3, min = 0, max = 5, step = 0.05 },
		{ id = "castDelayMax", kind = "range", default = 1.2, min = 0, max = 5, step = 0.05 },
		{ id = "completeDelayMin", kind = "range", default = 0.1, min = 0, max = 2.5, step = 0.05 },
		{ id = "completeDelayMax", kind = "range", default = 0.9, min = 0, max = 2.5, step = 0.05 },
	},
	init = function(ctx, plugin)
		plugin.state.oldMinigame = nil
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		local rng = Random.new()
		local rod = bw.FishingRodController
		local mini = bw.FishingMinigameController
		if not rod or not mini then return end

		local function getBait()
			for _, v in workspace:GetChildren() do
				if v.Name == "fisherman_bobber" and v:GetAttribute("ProjectileShooter") == ctx.player.UserId then
					return v
				end
			end
		end

		local function castRod()
			local item = rod:getHandItem()
			if item and not rod.projectileHandler and rod:canLaunch() then
				rod:beginHolding(item, nil, rod.aimingMaid, false)
				task.wait()
				rod:releaseChargeInput(rod.aimingMaid, function() return true end, nil)
			end
		end

		if plugin.state.autoMinigame ~= false then
			plugin.state.oldMinigame = mini.startMinigame
			mini.startMinigame = function(...)
				if plugin.enabled then
					local min = plugin.state.completeDelayMin or 0.1
					local max = plugin.state.completeDelayMax or 0.9
					task.wait(rng:NextNumber(min, max))
					return select(3, ...)({ win = true })
				end
				return plugin.state.oldMinigame(...)
			end
		end

		host:track(bw.handler:Get("FishFound").Remote:Connect(function(data)
			if plugin.state.showLoot and data.dropData and data.dropData.drops then
				for _, v in data.dropData.drops do
					local meta = bw.itemMeta[v.itemType]
					local name = meta and meta.displayName or v.itemType
					if ctx.notify then
						ctx.notify("AutoFish", v.amount .. " " .. name:lower(), 5)
					end
				end
			end
		end))

		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive and plugin.state.autoCast ~= false then
					local hand = ctx.store.hand.tool
					if hand and hand.Name == "fishing_rod" then
						if not getBait() then
							local head = ctx.entity.self.head
							local ray = ctx.player:GetMouse().UnitRay
							if workspace:Raycast(head.Position + ray.Direction * 6, Vector3.new(0, -20, 0)) then
								local min = plugin.state.castDelayMin or 0.3
								local max = plugin.state.castDelayMax or 1.2
								task.wait(rng:NextNumber(min, max))
								if plugin.enabled then castRod() end
								task.wait(0.1)
							end
						end
					end
				end
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
		local mini = ctx.bw and ctx.bw.FishingMinigameController
		if mini and plugin.state.oldMinigame then
			mini.startMinigame = plugin.state.oldMinigame
			plugin.state.oldMinigame = nil
		end
	end,
}
