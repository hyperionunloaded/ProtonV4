--proton-cache:build
﻿local StarterGui = game:GetService("StarterGui")
return {
	id = "UICleanup",
	category = "legit",
	settings = {
		{ id = "oldPlayerList", kind = "toggle", default = true },
		{ id = "noKillFeed", kind = "toggle", default = true },
		{ id = "noInventoryButton", kind = "toggle", default = true },
	},
	init = function(ctx, plugin) plugin.state.oldKillFeed = nil plugin.state.oldInv = nil end,
	enable = function(ctx, plugin)
		local bw = ctx.bw
		if plugin.state.noKillFeed ~= false and bw.KillFeedController then
			plugin.state.oldKillFeed = bw.KillFeedController.addToKillFeed
			bw.KillFeedController.addToKillFeed = function() end
		end
		if plugin.state.oldPlayerList ~= false then
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
		end
	end,
	disable = function(ctx, plugin)
		local bw = ctx.bw
		if plugin.state.oldKillFeed and bw.KillFeedController then
			bw.KillFeedController.addToKillFeed = plugin.state.oldKillFeed
			plugin.state.oldKillFeed = nil
		end
		if plugin.state.oldPlayerList ~= false then
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		end
	end,
}
