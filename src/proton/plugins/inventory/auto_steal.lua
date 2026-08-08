--proton-cache:build
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local util = require(script.Parent.Parent.Parent.game.util)

return {
	id = "AutoSteal",
	category = "inventory",
	settings = {
		{ id = "range", kind = "range", default = 18, min = 1, max = 18 },
		{ id = "delay", kind = "range", default = 0, min = 0, max = 1, step = 0.01 },
		{ id = "guiCheck", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.stash = {}
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		local stash = plugin.state.stash

		local function invRemote(name)
			return bw.client:GetNamespace("Inventory"):Get(name)
		end

		local function stealCrate(crate)
			local value = crate:FindFirstChild("ChestFolderValue")
			local folder = value and value.Value
			if not folder then return end
			invRemote("SetObservedChest"):SendToServer(folder)
			for _, v in folder:GetChildren() do
				if v:IsA("Accessory") then
					local itemType = v.Name
					task.spawn(function()
						local ok, res = pcall(function()
							return invRemote("ChestGetItem"):CallServer(folder, v)
						end)
						if ok and res then
							stash[#stash + 1] = { Type = itemType, Expire = tick() + 5 }
						end
					end)
				end
			end
			invRemote("SetObservedChest"):SendToServer(nil)
		end

		local function depositStash()
			local inv = ReplicatedStorage:FindFirstChild("Inventories")
			inv = inv and inv:FindFirstChild(ctx.player.Name .. "_personal")
			if not inv then return end
			local pending = table.clone(stash)
			table.clear(stash)
			for _, v in pending do
				local item = util.getItem(ctx, v.Type)
				if item then
					task.spawn(function()
						local ok, res = pcall(function()
							return invRemote("ChestGiveItem"):CallServer(inv, item.tool)
						end)
						if not (ok and res) and tick() < v.Expire then
							stash[#stash + 1] = v
						end
					end)
				elseif tick() < v.Expire then
					stash[#stash + 1] = v
				end
			end
		end

		local crates = util.collection(ctx, host, "team-crate")
		local chests = util.collection(ctx, host, "personal-chest")
		plugin.state.alive = true

		task.spawn(function()
			repeat task.wait() until ctx.store.matchState ~= 0 or not plugin.enabled
			if not plugin.enabled then return end
			local nextSteal = 0
			while plugin.enabled and plugin.state.alive do
				if ctx.entity.alive and tick() > nextSteal then
					if not plugin.state.guiCheck or bw.appController:isAppOpen("ChestApp") then
						nextSteal = tick() + (plugin.state.delay or 0)
						local pos = util.pos(ctx)
						local team = ctx.player:GetAttribute("Team")
						for _, v in crates do
							if v:GetAttribute("Team") ~= team and (pos - v.Position).Magnitude <= (plugin.state.range or 18) then
								stealCrate(v)
							end
						end
						if #stash > 0 then
							for _, v in chests do
								if (pos - v.Position).Magnitude <= (plugin.state.range or 18) then
									depositStash()
									break
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
		table.clear(plugin.state.stash)
	end,
}
