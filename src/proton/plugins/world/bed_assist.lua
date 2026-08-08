--proton-cache:build
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

return {
	id = "BedAssist",
	category = "world",
	settings = {
		{ id = "aimMode", kind = "drop", default = "Simple", options = { "Simple", "Adaptive" } },
		{ id = "mode", kind = "drop", default = "Camera", options = { "Camera", "Mouse" } },
		{ id = "speed", kind = "range", default = 7, min = 1, max = 20 },
		{ id = "range", kind = "range", default = 20, min = 1, max = 30 },
		{ id = "shake", kind = "range", default = 3, min = 1, max = 100 },
		{ id = "limitItem", kind = "toggle", default = true },
	},
	init = function(ctx, plugin)
		plugin.state.started = 0
		plugin.state.lastBed = nil
	end,
	enable = function(ctx, plugin, host)
		local u = ctx.bw.util
		local rng = Random.new()
		local function ease(t)
			return t < 0.5 and 4 * t * t * t or 1 - (-2 * t + 2) ^ 3 / 2
		end
		local function aimSimple(cf, pos, fps)
			local shake = plugin.state.shake or 3
			local speed = plugin.state.speed or 7
			local offset = Vector3.new(
				(rng:NextNumber() - 0.5) * shake * fps,
				(rng:NextNumber() - 0.5) * shake * fps,
				(rng:NextNumber() - 0.5) * shake * fps
			)
			return cf:Lerp(CFrame.lookAt(cf.Position, pos + offset), speed * fps), speed
		end
		local function aimAdaptive(cf, pos, fps)
			local prog = ease(math.min((tick() - plugin.state.started) / (1 / ((plugin.state.speed or 7) * 0.5)), 1))
			local shake = plugin.state.shake or 3
			local offset = Vector3.new(
				(rng:NextNumber() - 0.5) * shake * fps,
				(rng:NextNumber() - 0.5) * shake * fps,
				(rng:NextNumber() - 0.5) * shake * fps
			)
			return cf:Lerp(CFrame.lookAt(cf.Position, pos + offset), prog * (plugin.state.speed or 7) * fps), prog * (plugin.state.speed or 7)
		end
		task.spawn(function()
			repeat task.wait() until ctx.store.matchState ~= 0 or not plugin.enabled
			if not plugin.enabled then return end
			local beds, cleanup = u.collection("bed", function(tab, obj)
				task.defer(function()
					if not obj:GetAttribute("Team" .. (ctx.player:GetAttribute("Team") or -1) .. "NoBreak") then
						tab[#tab + 1] = obj
					end
				end)
			end)
			host:track(RunService.PostSimulation:Connect(function(dt)
				if not plugin.enabled or not ctx.entity.alive then return end
				if plugin.state.limitItem then
					local tool = ctx.store.hand.tool
					local meta = tool and ctx.bw.itemMeta[tool.Name]
					if not meta or not meta.breakBlock then return end
				end
				local localPos = ctx.entity.self.root.Position
				for _, bed in beds do
					if (localPos - bed.Position).Magnitude <= (plugin.state.range or 20) then
						if plugin.state.lastBed ~= bed then
							plugin.state.started = tick()
							plugin.state.lastBed = bed
						end
						local pos = bed.Position
						local cam = Workspace.CurrentCamera
						local aimFn = plugin.state.aimMode == "Adaptive" and aimAdaptive or aimSimple
						local pred, speed = aimFn(cam.CFrame, pos, dt)
						if plugin.state.mode == "Mouse" and mousemoverel then
							local campos, vis = cam:WorldToViewportPoint(pos)
							if vis then
								local delta = (Vector2.new(campos.X, campos.Y) - game:GetService("UserInputService"):GetMouseLocation()) * (speed * dt)
								mousemoverel(delta.X, delta.Y)
							end
						else
							cam.CFrame = pred
						end
						break
					end
				end
			end))
			plugin.state.cleanup = cleanup
		end)
	end,
	disable = function(ctx, plugin)
		if plugin.state.cleanup then
			plugin.state.cleanup()
			plugin.state.cleanup = nil
		end
		plugin.state.lastBed = nil
	end,
}
