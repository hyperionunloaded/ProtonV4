--proton-cache:build
return {
	id = "DeviceSpoofer",
	category = "utility",
	settings = {
		{ id = "device", kind = "drop", default = "PC", options = { "Mobile", "PC", "Gamepad" } },
	},
	init = function(ctx, plugin)
		plugin.state.oldFn = nil
		plugin.state.oldDevice = nil
	end,
	enable = function(ctx, plugin)
		local bw = ctx.bw
		plugin.state.oldDevice = bw.userInputController:getUserInputType()
		plugin.state.oldFn = bw.userInputController.getUserInputType
		local device = (plugin.state.device or "PC"):upper()
		bw.userInputController.getUserInputType = function()
			return device
		end
		ctx.bw.fire("SendUserInputType", "SendToServer", { userInputType = device })
	end,
	disable = function(ctx, plugin)
		local bw = ctx.bw
		if plugin.state.oldFn then
			bw.userInputController.getUserInputType = plugin.state.oldFn
		end
		if plugin.state.oldDevice then
			ctx.bw.fire("SendUserInputType", "SendToServer", { userInputType = plugin.state.oldDevice })
		end
		plugin.state.oldFn = nil
		plugin.state.oldDevice = nil
	end,
}
