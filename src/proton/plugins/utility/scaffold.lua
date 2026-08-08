--proton-cache:build
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local adjacent = {}
for x = -3, 3, 3 do
	for y = -3, 3, 3 do
		for z = -3, 3, 3 do
			local vec = Vector3.new(x, y, z)
			if vec ~= Vector3.zero then adjacent[#adjacent + 1] = vec end
		end
	end
end

return {
	id = "Scaffold",
	category = "utility",
	settings = {
		{ id = "expand", kind = "range", default = 1, min = 1, max = 6 },
		{ id = "tower", kind = "toggle", default = true },
		{ id = "downwards", kind = "toggle", default = true },
		{ id = "diagonal", kind = "toggle", default = true },
		{ id = "limitItem", kind = "toggle", default = false },
		{ id = "requireMouse", kind = "toggle", default = false },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
		plugin.state.lastPos = Vector3.zero
	end,
	enable = function(ctx, plugin)
		local u = ctx.bw.util
		local function nearCorner(poscheck, pos)
			local startpos = poscheck - Vector3.new(3, 3, 3)
			local endpos = poscheck + Vector3.new(3, 3, 3)
			local check = poscheck + (pos - poscheck).Unit * 100
			return Vector3.new(
				math.clamp(check.X, startpos.X, endpos.X),
				math.clamp(check.Y, startpos.Y, endpos.Y),
				math.clamp(check.Z, startpos.Z, endpos.Z)
			)
		end
		local function blockProximity(pos)
			local mag, returned = 60
			local tab = u.getBlocksInPoints(
				ctx.bw.blockController:getBlockPosition(pos - Vector3.new(21, 21, 21)),
				ctx.bw.blockController:getBlockPosition(pos + Vector3.new(21, 21, 21))
			)
			for _, v in tab do
				local blockpos = nearCorner(v, pos)
				local newmag = (pos - blockpos).Magnitude
				if newmag < mag then mag, returned = newmag, blockpos end
			end
			return returned
		end
		local function checkAdjacent(pos)
			for _, v in adjacent do
				if u.getPlacedBlock(pos + v) then return true end
			end
		end
		local function getBlock()
			if ctx.store.hand.toolType == "block" then
				return ctx.store.hand.tool.Name, ctx.store.hand.amount
			end
			if not plugin.state.limitItem then
				local wool, amount = u.getWool()
				if wool then return wool, amount end
				for _, item in ctx.store.inventory.inventory.items do
					if ctx.bw.itemMeta[item.itemType].block then
						return item.itemType, item.amount
					end
				end
			end
		end
		plugin.state.alive = true
		task.spawn(function()
			repeat
				if ctx.entity.alive then
					local wool, _ = getBlock()
					if plugin.state.requireMouse and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
						wool = nil
					end
					if wool then
						local root = ctx.entity.self.root
						local hum = ctx.entity.self.humanoid
						if plugin.state.tower and UserInputService:IsKeyDown(Enum.KeyCode.Space) and not UserInputService:GetFocusedTextBox() then
							root.Velocity = Vector3.new(root.Velocity.X, 38, root.Velocity.Z)
						end
						for i = plugin.state.expand or 1, 1, -1 do
							local down = plugin.state.downwards and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 4.5 or 1.5
							local current = u.roundPos(root.Position - Vector3.new(0, root.Size.Y / 2 + down, 0) + hum.MoveDirection * (i * 3))
							if plugin.state.diagonal and hum.MoveDirection.Magnitude > 0 then
								local dt = plugin.state.lastPos - current
								if ((dt.X == 0 and dt.Z ~= 0) or (dt.X ~= 0 and dt.Z == 0)) and ((plugin.state.lastPos - root.Position) * Vector3.new(1, 0, 1)).Magnitude < 2.5 then
									current = plugin.state.lastPos
								end
							end
							local _, blockpos = u.getPlacedBlock(current)
							if not blockpos then
								local placePos = checkAdjacent(current) and current or blockProximity(current)
								if placePos then task.defer(u.placeBlock, placePos, wool) end
							end
							plugin.state.lastPos = current
						end
					end
				end
				task.wait(0.03)
			until not plugin.enabled
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
	end,
}
