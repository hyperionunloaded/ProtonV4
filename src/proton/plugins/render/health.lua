--proton-cache:build
local style = require(script.Parent._style)

return {
	id = "Health",
	category = "render",
	settings = {},
	init = function(ctx, plugin)
		plugin.state.label = nil
	end,
	enable = function(ctx, plugin, host)
		local holder = style.root("Health")
		plugin.state.holder = holder

		local anchor, label = style.screenTag(holder)
		anchor.AnchorPoint = Vector2.new(0.5, 0)
		anchor.Position = UDim2.new(0.5, 0, 0.5, 36)
		anchor.Visible = true
		plugin.state.anchor = anchor
		plugin.state.label = label

		local function refresh()
			if not ctx.entity.alive then
				label.Text = ""
				anchor.Visible = false
				return
			end
			anchor.Visible = true
			local char = ctx.entity.self.character
			local hp = math.round(char:GetAttribute("Health") or ctx.entity.self.health or 0)
			local max = char:GetAttribute("MaxHealth") or ctx.entity.self.maxHealth or 100
			label.Text = tostring(hp) .. " HP"
			label.TextColor3 = style.healthTone(hp / max)
		end

		refresh()
		if ctx.entity.self and ctx.entity.self.character then
			host:track(ctx.entity.self.character:GetAttributeChangedSignal("Health"):Connect(refresh))
			host:track(ctx.entity.self.character:GetAttributeChangedSignal("MaxHealth"):Connect(refresh))
		end
		host:track(ctx.entity.events.localAdded:connect(refresh))
		host:track(ctx.entity.events.localRemoved:connect(refresh))
		host:track(ctx.entity.events.updated:connect(function(ent)
			if ent == ctx.entity.self then
				refresh()
			end
		end))
	end,
	disable = function(ctx, plugin)
		if plugin.state.holder then
			style.wipe(plugin.state.holder)
		end
		plugin.state.label = nil
		plugin.state.anchor = nil
	end,
}
