--proton-cache:build
local Players = game:GetService("Players")

return {
	id = "StaffDetector",
	category = "utility",
	settings = {
		{ id = "mode", kind = "drop", default = "Notify", options = { "Uninject", "Profile", "Requeue", "AutoConfig", "Notify" } },
		{ id = "blacklistClans", kind = "toggle", default = true },
		{ id = "leaveParty", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.joined = {}
		plugin.state.blacklistedClans = { "gg", "gg2", "DV", "DV2" }
		plugin.state.blacklistedUsers = { 1502104539, 3826146717, 4531785383, 1049767300, 4926350670, 653085195, 184655415, 2752307430, 5087196317, 5744061325, 1536265275 }
	end,
	enable = function(ctx, plugin, host)
		local function getRole(plr, groupId)
			local ok, rank = pcall(function() return plr:GetRankInGroup(groupId) end)
			return ok and rank or 0
		end
		local function staffAction(plr, reason)
			ctx.notify.push("StaffDetector", "Staff Detected (" .. reason .. "): " .. plr.Name .. " (" .. plr.UserId .. ")", "alert")
			if plugin.state.leaveParty then
				ctx.bw.partyController:leaveParty()
			end
			if plugin.state.mode == "Requeue" then
				ctx.bw.queueController:joinQueue(ctx.store.queueType)
			elseif plugin.state.mode == "AutoConfig" then
				local safe = { AutoClicker = true, Reach = true, Sprint = true, StaffDetector = true }
				for id, p in pairs(ctx.plugins) do
					if not safe[id] and p.category ~= "render" and p.enabled and ctx.host then
						ctx.host:disable(id)
					end
				end
			end
		end
		local function checkJoin(plr, conn)
			if plr:GetAttribute("Team") or not plr:GetAttribute("Spectator") then return end
			if ctx.bw.store:getState().Game.customMatch then return end
			conn:Disconnect()
			staffAction(plr, "impossible_join")
			return true
		end
		local function onPlayer(plr)
			plugin.state.joined[plr.UserId] = plr.Name
			if plr == ctx.player then return end
			if table.find(plugin.state.blacklistedUsers, plr.UserId) then
				staffAction(plr, "blacklisted_user")
				return
			end
			if getRole(plr, 5774246) >= 100 then
				staffAction(plr, "staff_role")
				return
			end
			local conn = plr:GetAttributeChangedSignal("Spectator"):Connect(function()
				checkJoin(plr, conn)
			end)
			host:track(conn)
			if checkJoin(plr, conn) then return end
			task.spawn(function()
				if not plr:GetAttribute("ClanTag") then
					plr:GetAttributeChangedSignal("ClanTag"):Wait()
				end
				if plugin.state.blacklistClans and table.find(plugin.state.blacklistedClans, plr:GetAttribute("ClanTag")) then
					conn:Disconnect()
					staffAction(plr, "blacklisted_clan_" .. tostring(plr:GetAttribute("ClanTag")):lower())
				end
			end)
		end
		host:track(Players.PlayerAdded:Connect(onPlayer))
		for _, plr in Players:GetPlayers() do
			task.spawn(onPlayer, plr)
		end
	end,
	disable = function(ctx, plugin)
		table.clear(plugin.state.joined)
	end,
}
