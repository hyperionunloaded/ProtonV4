--proton-cache:build
﻿return {
	id = "Ping",
	category = "legit",
	settings = { { id = "opacity", kind = "range", default = 0.5, min = 0, max = 1, step = 0.05 } },
	init = function(ctx, plugin) plugin.state.label = nil plugin.state.alive = false end,
	enable = function(ctx, plugin)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromOffset(100, 41)
		label.BackgroundTransparency = 1 - (plugin.state.opacity or 0.5)
		label.TextSize = 15
		label.Font = Enum.Font.Gotham
		label.Text = "0 ms"
		label.TextColor3 = Color3.new(1, 1, 1)
		label.BackgroundColor3 = Color3.new()
		label.Parent = ctx.player.PlayerGui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = label
		plugin.state.label = label
		plugin.state.alive = true
		task.spawn(function()
			while plugin.enabled and plugin.state.alive do
				local ping = math.floor((ctx.player:GetNetworkPing() or 0) * 1000)
				label.Text = ping .. " ms"
				task.wait(0.1)
			end
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
		if plugin.state.label then plugin.state.label:Destroy() plugin.state.label = nil end
	end,
}
