--proton-cache:build
return {
	id = "HitBoxes",
	category = "blatant",
	settings = {
		{ id = "mode", kind = "drop", default = "Sword", options = { "Sword", "Player" } },
		{ id = "expand", kind = "range", default = 14.4, min = 0, max = 14.4, step = 0.1 },
	},
	init = function(ctx, plugin)
		plugin.state.parts = {}
		plugin.state.swordHooked = false
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		local mode = host:get(plugin, "mode", "Sword")
		local expand = host:get(plugin, "expand", 14.4)
		if mode == "Sword" then
			if bw.swordController and bw.swordController.swingSwordInRegion then
				debug.setconstant(bw.swordController.swingSwordInRegion, 6, expand / 3)
				plugin.state.swordHooked = true
			end
			return
		end
		local function attach(ent)
			if not ent.player or not ent.targetable then return end
			local box = Instance.new("Part")
			box.Size = Vector3.new(3, 6, 3) + Vector3.one * (expand / 5)
			box.CanCollide = false
			box.Massless = true
			box.Transparency = 1
			box.Parent = ent.character
			local weld = Instance.new("Motor6D")
			weld.Part0 = box
			weld.Part1 = ent.root
			weld.Parent = box
			plugin.state.parts[ent] = box
		end
		for _, ent in ipairs(ctx.entity.list) do
			attach(ent)
		end
		host:track(ctx.entity.events.added:connect(attach))
		host:track(ctx.entity.events.removed:connect(function(ent)
			local box = plugin.state.parts[ent]
			if box then
				box:Destroy()
				plugin.state.parts[ent] = nil
			end
		end))
	end,
	disable = function(ctx, plugin, host)
		if plugin.state.swordHooked and ctx.bw.swordController then
			debug.setconstant(ctx.bw.swordController.swingSwordInRegion, 6, 3.8)
			plugin.state.swordHooked = false
		end
		for _, box in pairs(plugin.state.parts) do
			box:Destroy()
		end
		table.clear(plugin.state.parts)
	end,
}
