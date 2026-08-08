--proton-cache:build
local UserInputService = game:GetService("UserInputService")

return {
	id = "AutoClicker",
	category = "combat",
	settings = {
		{ id = "mode", kind = "drop", default = "Tool", options = { "Tool", "Click", "RightClick" } },
		{ id = "cpsMin", kind = "range", default = 8, min = 1, max = 20 },
		{ id = "cpsMax", kind = "range", default = 12, min = 1, max = 20 },
	},
	init = function(ctx, plugin)
		plugin.state.alive = false
	end,
	enable = function(ctx, plugin)
		plugin.state.alive = true
		task.spawn(function()
			local rng = Random.new()
			while plugin.enabled and plugin.state.alive do
				local mode = plugin.state.mode or "Tool"
				if mode == "Tool" then
					local char = ctx.player.Character
					local tool = char and char:FindFirstChildWhichIsA("Tool")
					if tool and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
						tool:Activate()
					end
				else
					if mouse1click and (isrbxactive or iswindowactive)() then
						if mode == "Click" then
							mouse1click()
						else
							mouse2click()
						end
					end
				end
				local minCps = plugin.state.cpsMin or 8
				local maxCps = plugin.state.cpsMax or 12
				task.wait(1 / rng:NextNumber(minCps, maxCps))
			end
		end)
	end,
	disable = function(ctx, plugin)
		plugin.state.alive = false
	end,
}
