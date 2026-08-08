--proton-cache:build
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local style = require(script.Parent._style)

return {
	id = "NameTags",
	category = "render",
	settings = {
		{ id = "players", kind = "toggle", default = true },
		{ id = "npcs", kind = "toggle", default = true },
		{ id = "health", kind = "toggle", default = true },
		{ id = "distance", kind = "toggle", default = false },
		{ id = "displayName", kind = "toggle", default = true },
		{ id = "priorityOnly", kind = "toggle", default = true },
		{ id = "scale", kind = "range", default = 1, min = 0.5, max = 1.5, step = 0.1 },
		{ id = "rangeMin", kind = "range", default = 0, min = 0, max = 256, step = 1 },
		{ id = "rangeMax", kind = "range", default = 128, min = 0, max = 512, step = 1 },
	},
	init = function(ctx, plugin)
		plugin.state.tags = {}
	end,
	enable = function(ctx, plugin, host)
		local holder = style.root("NameTags")
		plugin.state.holder = holder
		local camera = Workspace.CurrentCamera

		local function allowed(ent)
			if ent.player and not plugin.state.players then return false end
			if ent.npc and not plugin.state.npcs then return false end
			if plugin.state.priorityOnly and not ent.targetable and not ent.npc then return false end
			return true
		end

		local function title(ent)
			if ent.player then
				if plugin.state.displayName then
					return ent.player.DisplayName
				end
				return ent.player.Name
			end
			return ent.character.Name
		end

		local function line(ent)
			local text = title(ent)
			if plugin.state.health then
				text = text .. " · " .. tostring(math.round(ent.health or 0))
			end
			if plugin.state.distance and ctx.entity.alive then
				local mag = math.floor((ctx.entity.self.root.Position - ent.root.Position).Magnitude)
				text = mag .. "m · " .. text
			end
			return text
		end

		local function tone(ent)
			if ent.targetable then
				return style.accent
			end
			return style.muted
		end

		local function attach(ent)
			if plugin.state.tags[ent] or not allowed(ent) then return end
			local anchor, label = style.screenTag(holder)
			label.Text = line(ent)
			label.TextSize = 13 * (plugin.state.scale or 1)
			label.TextColor3 = tone(ent)
			plugin.state.tags[ent] = { anchor = anchor, label = label }
		end

		local function detach(ent)
			local row = plugin.state.tags[ent]
			if row then
				row.anchor:Destroy()
				plugin.state.tags[ent] = nil
			end
		end

		local function refresh(ent)
			local row = plugin.state.tags[ent]
			if not row then return end
			row.label.Text = line(ent)
			row.label.TextColor3 = tone(ent)
		end

		for _, ent in ipairs(ctx.entity.list) do
			attach(ent)
		end
		host:track(ctx.entity.events.added:connect(attach))
		host:track(ctx.entity.events.removed:connect(detach))
		host:track(ctx.entity.events.updated:connect(refresh))
		host:track(RunService.RenderStepped:Connect(function()
			for ent, row in pairs(plugin.state.tags) do
				if not ent.root or not ent.root.Parent then
					detach(ent)
					continue
				end
				if ctx.entity.alive then
					local mag = (ctx.entity.self.root.Position - ent.root.Position).Magnitude
					if mag < (plugin.state.rangeMin or 0) or mag > (plugin.state.rangeMax or 512) then
						row.anchor.Visible = false
						continue
					end
				end
				local headPos, vis = camera:WorldToViewportPoint(ent.root.Position + Vector3.new(0, 2.5, 0))
				row.anchor.Visible = vis
				if vis then
					row.anchor.Position = UDim2.fromOffset(headPos.X, headPos.Y)
					if plugin.state.distance then
						row.label.Text = line(ent)
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
