--proton-cache:build
return {
	id = "NoTextures",
	category = "render",
	settings = {
		{ id = "materials", kind = "toggle", default = true },
		{ id = "decals", kind = "toggle", default = true },
		{ id = "meshes", kind = "toggle", default = true },
	},
	init = function(ctx, plugin)
		plugin.state.saved = {}
	end,
	enable = function(ctx, plugin, host)
		local function remember(obj, key)
			local pack = plugin.state.saved[obj]
			if not pack then
				pack = {}
				plugin.state.saved[obj] = pack
			end
			if pack[key] == nil then
				pack[key] = obj[key]
			end
		end

		local function strip(obj)
			if plugin.state.decals and obj:IsA("Decal") then
				remember(obj, "Transparency")
				obj.Transparency = 1
				return
			end
			if plugin.state.decals and obj:IsA("SurfaceAppearance") then
				remember(obj, "Parent")
				obj.Parent = nil
				return
			end
			if plugin.state.meshes and obj:IsA("SpecialMesh") then
				remember(obj, "TextureId")
				obj.TextureId = ""
				return
			end
			if obj:IsA("BasePart") then
				if plugin.state.meshes and obj:IsA("MeshPart") then
					remember(obj, "TextureID")
					obj.TextureID = ""
				end
				if plugin.state.materials then
					remember(obj, "Material")
					obj.Material = Enum.Material.SmoothPlastic
				end
			end
		end

		local function scan(root)
			if not root then return end
			local list = root:GetDescendants()
			for i, obj in ipairs(list) do
				if plugin.enabled then
					strip(obj)
				end
				if i % 400 == 0 then
					task.wait()
				end
			end
		end

		task.spawn(function()
			repeat task.wait() until ctx.store.map or not plugin.enabled
			if not plugin.enabled then return end
			local map = ctx.store.map
			scan(map)
			host:track(map.DescendantAdded:Connect(function(obj)
				task.defer(strip, obj)
			end))
		end)
	end,
	disable = function(ctx, plugin)
		for obj, pack in pairs(plugin.state.saved) do
			pcall(function()
				for key, value in pairs(pack) do
					if key == "Parent" then
						if value and obj.Parent ~= value then
							obj.Parent = value
						end
					else
						obj[key] = value
					end
				end
			end)
		end
		table.clear(plugin.state.saved)
	end,
}
