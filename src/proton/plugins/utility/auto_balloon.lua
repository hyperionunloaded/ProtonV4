--proton-cache:build
return {
	id = "AutoBalloon",
	category = "utility",
	settings = {},
	init = function(ctx, plugin)
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin)
		local u = ctx.bw.util
		plugin.state.alive = true
		task.spawn(function()
			repeat task.wait() until ctx.store.matchState ~= 0 or not plugin.enabled
			if not plugin.enabled then return end
			local blocks, cleanup = u.collection("block")
			local lowest = u.lowestVoidPoint(blocks)
			repeat
				if ctx.entity.alive then
					local root = ctx.entity.self.root
					local inflated = ctx.player.Character:GetAttribute("InflatedBalloons") or 0
					if root.Position.Y < lowest and inflated < 3 and u.getItem("balloon") then
						for _ = 1, 3 do
							ctx.bw.balloonController:inflateBalloon()
						end
						task.wait(0.1)
					end
				end
				task.wait(0.1)
			until not plugin.enabled
			cleanup()
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
	end,
}
