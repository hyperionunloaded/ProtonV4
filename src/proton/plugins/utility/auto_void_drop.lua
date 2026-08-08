--proton-cache:build
return {
	id = "AutoVoidDrop",
	category = "utility",
	settings = {
		{ id = "owlCheck", kind = "toggle", default = true },
	},
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
					if root.Position.Y < lowest and inflated <= 0 and not u.getItem("balloon") then
						if not plugin.state.owlCheck or not root:FindFirstChild("OwlLiftForce") then
							for _, name in { "iron", "diamond", "emerald", "gold" } do
								local item = u.getItem(name)
								if item then
									local dropped = ctx.bw.call("DropItem", { item = item.tool, amount = item.amount })
									if dropped and typeof(dropped) == "Instance" then
										dropped:SetAttribute("ClientDropTime", tick() + 100)
									end
								end
							end
						end
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
