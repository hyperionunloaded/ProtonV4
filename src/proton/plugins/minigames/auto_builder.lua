--proton-cache:build
local CollectionService = game:GetService("CollectionService")
local util = require(script.Parent.Parent.Parent.game.util)

return {
	id = "AutoBuilder",
	category = "minigames",
	settings = {
		{ id = "bedCheck", kind = "toggle", default = false },
		{ id = "animation", kind = "toggle", default = true },
		{ id = "limitItem", kind = "toggle", default = true },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		plugin.state.alive = true

		local function getBed(pos)
			local bed, last = nil, math.huge
			for _, v in CollectionService:GetTagged("bed") do
				local mag = (pos - v.Position).Magnitude
				if mag < last and v:GetAttribute("Team" .. (ctx.player:GetAttribute("Team") or -1) .. "NoBreak") then
					bed, last = v, mag
				end
			end
			return bed
		end

		local blocks = util.collection(ctx, host, "block", function(tab, obj)
			task.defer(function()
				if not obj:GetAttribute("NoBreak") and obj:GetAttribute("PlacedByUserId") then
					tab[#tab + 1] = obj
				end
			end)
		end)

		task.spawn(function()
			repeat task.wait() until ctx.store.matchState ~= 0 and ctx.store.equippedKit == "builder" or not plugin.enabled
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive then
					local hasHammer = plugin.state.limitItem == false and util.getItem(ctx, "hammer")
						or (ctx.store.hand.tool and ctx.store.hand.tool.Name == "hammer")
					if hasHammer then
						local bed = getBed(util.pos(ctx))
						for _, block in blocks do
							if not plugin.state.bedCheck or (bed and (bed.Position - block.Position).Magnitude <= 30) then
								if not block:FindFirstChild("BuilderFortify") then
									local _, pos = bw.getPlacedBlock(block.Position)
									bw.fire("FortifyBlock", pos)
									if plugin.state.animation ~= false then
										bw.gameAnimationUtil:playAnimation(ctx.player, bw.gameAnimationUtil:getAssetId(bw.animationType.BUILDER_HAMMER_HIT), { fadeInTime = 0.02 })
										bw.soundManager:playSound(bw.soundList.FORTIFY_BLOCK, { position = util.pos(ctx) })
									end
								end
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
	end,
}
