--proton-cache:build
local ContextActionService = game:GetService("ContextActionService")

return {
	id = "AutoTool",
	category = "world",
	settings = {},
	init = function(ctx, plugin)
		plugin.state.oldHit = nil
		plugin.state.event = nil
	end,
	enable = function(ctx, plugin, host)
		local u = ctx.bw.util
		local bw = ctx.bw
		local event = Instance.new("BindableEvent")
		plugin.state.event = event
		host:track(event.Event:Connect(function()
			ContextActionService:CallFunction("block-break", Enum.UserInputState.Begin, newproxy(true))
		end))
		local old = bw.blockBreaker.hitBlock
		plugin.state.oldHit = old
		bw.blockBreaker.hitBlock = function(self, maid, raycastparams, ...)
			local info = self.clientManager:getBlockSelector():getMouseInfo(1, { ray = raycastparams })
			local block = info and info.target and info.target.blockInstance
			if block and not block:GetAttribute("NoBreak") and not block:GetAttribute("Team" .. (ctx.player:GetAttribute("Team") or 0) .. "NoBreak") then
				local breakType = bw.itemMeta[block.Name].block.breakType
				local tool = ctx.store.tools[breakType]
				if tool then
					local slot
					for i, v in ctx.store.inventory.hotbar or {} do
						if v.item and v.item.itemType == tool.itemType then
							slot = i - 1
							break
						end
					end
					if u.hotbarSwitch(slot) then
						if game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
							event:Fire()
						end
						return
					end
				end
			end
			return old(self, maid, raycastparams, ...)
		end
	end,
	disable = function(ctx, plugin)
		if plugin.state.oldHit and ctx.bw then
			ctx.bw.blockBreaker.hitBlock = plugin.state.oldHit
		end
		if plugin.state.event then
			plugin.state.event:Destroy()
			plugin.state.event = nil
		end
		plugin.state.oldHit = nil
	end,
}
