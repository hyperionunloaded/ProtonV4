--proton-cache:build
local TweenService = game:GetService("TweenService")

return {
	id = "FastConsume",
	category = "inventory",
	settings = {
		{ id = "multiplier", kind = "range", default = 50, min = 0, max = 100 },
	},
	init = function(ctx, plugin)
		plugin.state.oldClick = nil
		plugin.state.oldProgress = nil
	end,
	enable = function(ctx, plugin)
		local bw = ctx.bw
		local clickHold = bw.clickHold
		if not clickHold then return end
		local mult = (plugin.state.multiplier or 50) / 100
		plugin.state.oldClick = clickHold.startClick
		plugin.state.oldProgress = clickHold.showProgress
		local oldClick = plugin.state.oldClick
		local oldProgress = plugin.state.oldProgress

		clickHold.startClick = function(self)
			self.startedClickTime = tick()
			local handle = self:showProgress()
			local clicktime = self.startedClickTime
			bw.runtimeLib.Promise.defer(function()
				task.wait(self.durationSeconds * mult)
				if handle == self.handle and clicktime == self.startedClickTime and self.closeOnComplete then
					self:hideProgress()
					if self.onComplete then self.onComplete() end
					if self.onPartialComplete then self.onPartialComplete(1) end
					self.startedClickTime = -1
				end
			end)
		end

		clickHold.showProgress = function(self)
			local roact = debug.getupvalue(oldProgress, 1)
			local countdown = roact.mount(roact.createElement("ScreenGui", {}, { roact.createElement("Frame", {
				[roact.Ref] = self.wrapperRef,
				Size = UDim2.new(),
				Position = UDim2.fromScale(0.5, 0.55),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.8,
			}, { roact.createElement("Frame", {
				[roact.Ref] = self.progressRef,
				Size = UDim2.fromScale(0, 1),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
			}) }) }), ctx.player:FindFirstChild("PlayerGui"))
			self.handle = countdown
			local sizetween = TweenService:Create(self.wrapperRef:getValue(), TweenInfo.new(0.1), {
				Size = UDim2.fromScale(0.11, 0.005),
			})
			local countdowntween = TweenService:Create(self.progressRef:getValue(), TweenInfo.new(self.durationSeconds * mult, Enum.EasingStyle.Linear), {
				Size = UDim2.fromScale(1, 1),
			})
			sizetween:Play()
			countdowntween:Play()
			table.insert(self.tweens, countdowntween)
			table.insert(self.tweens, sizetween)
			return countdown
		end
	end,
	disable = function(ctx, plugin)
		local clickHold = ctx.bw and ctx.bw.clickHold
		if clickHold and plugin.state.oldClick then
			clickHold.startClick = plugin.state.oldClick
			clickHold.showProgress = plugin.state.oldProgress
		end
		plugin.state.oldClick = nil
		plugin.state.oldProgress = nil
	end,
}
