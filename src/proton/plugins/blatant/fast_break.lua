--proton-cache:build
return {
	id = "FastBreak",
	category = "blatant",
	settings = {
		{ id = "time", kind = "range", default = 0.25, min = 0, max = 0.3, step = 0.01 },
		{ id = "bedCheck", kind = "toggle", default = false },
		{ id = "blacklist", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.old = nil
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		plugin.state.alive = true
		local breaker = bw.BlockBreakController and bw.BlockBreakController.blockBreaker
		if not breaker then return end

		local function findName(name)
			if name:find("iron") then return "iron_ore_mesh_block" end
			return name
		end

		if bw.BlockBreaker and bw.BlockBreaker.hitBlock then
			plugin.state.old = bw.BlockBreaker.hitBlock
			bw.BlockBreaker.hitBlock = function(self, ...)
				local args = { ... }
				pcall(function()
					local params = args[2]
					local info = self.clientManager:getBlockSelector():getMouseInfo(1, { ray = params })
					local block = info and info.target and info.target.blockInstance
					if block then
						local skip = host:get(plugin, "blacklist", false)
						local bedSkip = host:get(plugin, "bedCheck", false)
						if bedSkip and block.Name == "bed" then return plugin.state.old(self, ...) end
						if skip then
							local n = findName(block.Name)
							if n == block.Name and block.Name:find("iron") then
								breaker:setCooldown(host:get(plugin, "time", 0.25))
							end
						else
							breaker:setCooldown(host:get(plugin, "time", 0.25))
						end
					end
				end)
				return plugin.state.old(self, ...)
			end
		end

		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				if (tick() - (ctx.store.lastHit or 0)) > 0.3 then
					breaker:setCooldown(host:get(plugin, "time", 0.25))
				end
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
		local bw = ctx.bw
		if bw and plugin.state.old and bw.BlockBreaker then
			bw.BlockBreaker.hitBlock = plugin.state.old
			plugin.state.old = nil
		end
		local breaker = bw and bw.BlockBreakController and bw.BlockBreakController.blockBreaker
		if breaker then
			breaker:setCooldown(0.3)
		end
	end,
}
