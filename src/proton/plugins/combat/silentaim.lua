--proton-cache:build
local Players = game:GetService("Players")

return {
	id = "SilentAim",
	category = "combat",
	settings = {
		{ id = "range", kind = "range", default = 18, min = 1, max = 30 },
		{ id = "fov", kind = "range", default = 90, min = 1, max = 360 },
	},
	init = function(ctx, plugin)
		plugin.state.old = nil
	end,
	enable = function(ctx, plugin)
		local bw = ctx.bw
		local oldGet = bw.client.Get
		plugin.state.old = oldGet
		bw.client.Get = function(self, remoteName)
			local remote = oldGet(self, remoteName)
			if remoteName ~= "ProjectileFire" then
				return remote
			end
			local oldSend = remote.SendToServer
			remote.SendToServer = function(_, packet, ...)
				if ctx.entity.alive and type(packet) == "table" and packet.validate then
					local target = ctx.entity.nearest({
						range = plugin.state.range or 18,
						players = true,
					})
					if target then
						packet.validate.targetPosition = {
							value = target.root.Position,
						}
					end
				end
				return oldSend(remote, packet, ...)
			end
			return remote
		end
	end,
	disable = function(ctx, plugin)
		if plugin.state.old and ctx.bw then
			ctx.bw.client.Get = plugin.state.old
			plugin.state.old = nil
		end
	end,
}
