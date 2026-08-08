--proton-cache:build
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local style = require(script.Parent._style)

return {
	id = "HiveESP",
	category = "render",
	settings = {
		{ id = "scale", kind = "range", default = 1, min = 0.5, max = 1.5, step = 0.1 },
		{ id = "fade", kind = "range", default = 0.35, min = 0, max = 1, step = 0.05 },
	},
	init = function(ctx, plugin)
		plugin.state.tags = {}
	end,
	enable = function(ctx, plugin, host)
		local holder = style.root("HiveESP")
		plugin.state.holder = holder
		local camera = Workspace.CurrentCamera

		local function format(ent)
			local level = ent:GetAttribute("Level") or 0
			local bees = tostring(level)
			local suffix = level == 1 and " bee" or " bees"
			return bees .. suffix
		end

		local function attach(ent)
			if plugin.state.tags[ent] then return end
			local uid = ent:GetAttribute("PlacedByUserId")
			local owner = "unknown"
			if uid then
				local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, uid)
				if ok and name then owner = name end
			end
			local bb, label = style.worldBillboard(holder, Vector3.new(0, 1.5, 0))
			bb.Adornee = ent
			label.Text = owner .. " · " .. format(ent)
			label.TextSize = 13 * (plugin.state.scale or 1)
			bb.Parent = holder
			plugin.state.tags[ent] = { bb = bb, label = label, owner = owner }
		end

		local function detach(ent)
			local row = plugin.state.tags[ent]
			if row then
				row.bb:Destroy()
				plugin.state.tags[ent] = nil
			end
		end

		for _, ent in CollectionService:GetTagged("beehive") do
			attach(ent)
		end
		host:track(CollectionService:GetInstanceAddedSignal("beehive"):Connect(attach))
		host:track(CollectionService:GetInstanceRemovedSignal("beehive"):Connect(detach))
		host:track(RunService.PreRender:Connect(function()
			for ent, row in pairs(plugin.state.tags) do
				if not ent.Parent then
					detach(ent)
					continue
				end
				local pos, vis = camera:WorldToViewportPoint(ent.Position + Vector3.new(0, 1.5, 0))
				row.bb.Enabled = vis
				if vis then
					row.label.Text = row.owner .. " · " .. format(ent)
					row.label.TextSize = 13 * (plugin.state.scale or 1)
					local shell = row.label.Parent
					if shell then
						shell.BackgroundTransparency = plugin.state.fade or 0.35
					end
				end
			end
		end))
	end,
	disable = function(ctx, plugin)
		if plugin.state.holder then
			style.wipe(plugin.state.holder)
		end
		table.clear(plugin.state.tags)
	end,
}
