--proton-cache:build
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

return {
	id = "AutoToxic",
	category = "utility",
	settings = {
		{ id = "autoGG", kind = "toggle", default = true },
		{ id = "kill", kind = "toggle", default = false },
		{ id = "death", kind = "toggle", default = false },
		{ id = "bed", kind = "toggle", default = false },
		{ id = "bedDestroyed", kind = "toggle", default = false },
		{ id = "win", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.said = {}
		plugin.state.dead = false
	end,
	enable = function(ctx, plugin, host)
		local function send(kind, obj, fallback)
			local msg = fallback
			if not msg then return end
			msg = msg:gsub("<obj>", obj or "")
			if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
				TextChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(msg)
			else
				ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
			end
			plugin.state.said[kind] = msg
		end
		host:track(ctx.events.on("BedwarsBedBreak", function(data)
			if plugin.state.bedDestroyed and data.brokenBedTeam.id == ctx.player:GetAttribute("Team") then
				send("bedDestroyed", data.player and (data.player.DisplayName or data.player.Name), "how dare you >:( | <obj>")
			elseif plugin.state.bed and data.player and data.player.UserId == ctx.player.UserId then
				send("bed", data.brokenBedTeam.id, "nice bed lul | <obj>")
			end
		end))
		host:track(ctx.events.on("EntityDeathEvent", function(data)
			if not data.finalKill then return end
			local killer = Players:GetPlayerFromCharacter(data.fromEntity)
			local killed = Players:GetPlayerFromCharacter(data.entityInstance)
			if not killed or not killer then return end
			if killed == ctx.player then
				if not plugin.state.dead and killer ~= ctx.player and plugin.state.death then
					plugin.state.dead = true
					send("death", killer.DisplayName or killer.Name, "my gaming chair subscription expired :( | <obj>")
				end
			elseif killer == ctx.player and plugin.state.kill then
				send("kill", killed.DisplayName or killed.Name, "vxp on top | <obj>")
			end
		end))
		host:track(ctx.events.on("MatchEndEvent", function(win)
			if plugin.state.autoGG then
				if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
					TextChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync("gg")
				else
					ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("gg", "All")
				end
			end
			if plugin.state.win then
				local myTeam = ctx.bw.store:getState().Game.myTeam
				if myTeam and (myTeam.id == win.winningTeamId or ctx.player.Neutral) then
					send("win", nil, "yall garbage")
				end
			end
			plugin.state.dead = false
		end))
	end,
	disable = function(ctx, plugin)
		table.clear(plugin.state.said)
		plugin.state.dead = false
	end,
}
