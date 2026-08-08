--proton-cache:build
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local style = require(script.Parent._style)

return {
	id = "ItemESP",
	category = "render",
	settings = {
		{ id = "distance", kind = "toggle", default = true },
		{ id = "scale", kind = "range", default = 1, min = 0.5, max = 1.5, step = 0.1 },
		{ id = "whitelistOnly", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.tags = {}
		plugin.state.allowed = { "diamond", "emerald", "iron", "gold", "telepearl" }
	end,
	enable = function(ctx, plugin, host)
		local holder = style.root("ItemESP")
		plugin.state.holder = holder
		local camera = Workspace.CurrentCamera
		local bw = ctx.bw

		local function displayName(ent)
			local meta = bw.itemMeta[ent.Name]
			return meta and meta.displayName or ent.Name
		end

		local function allowed(name)
			if not plugin.state.whitelistOnly then return true end
			return table.find(plugin.state.allowed, name:lower()) ~= nil
		end

		local function attach(ent)
			if plugin.state.tags[ent] then return end
			local name = displayName(ent)
			if not allowed(name) then return end
			local bb, label = style.worldBillboard(holder, Vector3.new(0, 1, 0))
			bb.Adornee = ent
			label.Text = name
			label.TextSize = 13 * (plugin.state.scale or 1)
			plugin.state.tags[ent] = { bb = bb, label = label, name = name }
		end

		local function detach(ent)
			local row = plugin.state.tags[ent]
			if row then
				row.bb:Destroy()
				plugin.state.tags[ent] = nil
			end
		end

		for _, ent in CollectionService:GetTagged("ItemDrop") do
			attach(ent)
		end
		host:track(CollectionService:GetInstanceAddedSignal("ItemDrop"):Connect(attach))
		host:track(CollectionService:GetInstanceRemovedSignal("ItemDrop"):Connect(detach))
		host:track(RunService.PreRender:Connect(function()
			for ent, row in pairs(plugin.state.tags) do
				if not ent.Parent or ent.Position.Y <= -200 then
					row.bb.Enabled = false
					continue
				end
				local _, vis = camera:WorldToViewportPoint(ent.Position + Vector3.new(0, 1, 0))
				row.bb.Enabled = vis
				if not vis then continue end
				local amount = ent:GetAttribute("Amount") or 1
				local line = row.name
				if amount >= 2 then
					line = line .. " x" .. tostring(amount)
				end
				if plugin.state.distance and ctx.entity.alive then
					local mag = math.floor((ctx.entity.self.root.Position - ent.Position).Magnitude)
					line = mag .. "m · " .. line
				end
				row.label.Text = line
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
