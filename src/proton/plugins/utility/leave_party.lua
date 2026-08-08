--proton-cache:build
return {
	id = "LeaveParty",
	category = "utility",
	settings = {},
	init = function(ctx, plugin) end,
	enable = function(ctx, plugin, host)
		ctx.bw.partyController:leaveParty()
		host:disable("LeaveParty")
	end,
	disable = function(ctx, plugin) end,
}
