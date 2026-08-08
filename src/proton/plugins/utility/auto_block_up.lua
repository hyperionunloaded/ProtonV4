--proton-cache:build
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

return {
	id = "AutoBlockUp",
	category = "utility",
	settings = {
		{ id = "limitItem", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.up = false
		plugin.state.lastPlace = 0
	end,
	enable = function(ctx, plugin, host)
		local u = ctx.bw.util
		local function blockItem()
			if ctx.store.hand.toolType == "block" then
				return ctx.store.hand.tool and ctx.store.hand.tool.Name
			end
			if not plugin.state.limitItem then
				for _, item in ctx.store.inventory.inventory.items do
					local meta = ctx.bw.itemMeta[item.itemType]
					if meta and meta.block then
						return item.itemType
					end
				end
			end
		end
		host:track(RunService.Heartbeat:Connect(function()
			if not plugin.enabled or not plugin.state.up or not ctx.entity.alive then return end
			local item = blockItem()
			if not item then return end
			local root = ctx.entity.self.root
			local pos = u.roundPos(root.Position - Vector3.new(0, root.Size.Y / 2 + 1.5, 0))
			if tick() >= plugin.state.lastPlace and not u.getPlacedBlock(pos) then
				plugin.state.lastPlace = tick() + 0.15
				u.placeBlock(pos, item)
			end
			root.Velocity = Vector3.new(root.Velocity.X, 35, root.Velocity.Z)
		end))
		host:track(UserInputService.InputBegan:Connect(function(input)
			if UserInputService:GetFocusedTextBox() then return end
			if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
				plugin.state.up = true
			end
		end))
		host:track(UserInputService.InputEnded:Connect(function(input)
			if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
				plugin.state.up = false
				if ctx.entity.alive then
					local root = ctx.entity.self.root
					root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
				end
			end
		end))
		local touchGui = UserInputService.TouchEnabled and ctx.player.PlayerGui:FindFirstChild("TouchGui")
		local jumpButton = touchGui and touchGui:FindFirstChild("JumpButton", true)
		if jumpButton then
			host:track(jumpButton:GetPropertyChangedSignal("ImageRectOffset"):Connect(function()
				plugin.state.up = jumpButton.ImageRectOffset.X == 146
			end))
		end
	end,
	disable = function(ctx, plugin)
		plugin.state.up = false
	end,
}
