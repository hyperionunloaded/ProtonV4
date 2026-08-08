--proton-cache:build
local loader = {}

local registry = require(script.Parent.registry)



local categories = {

	"combat", "blatant", "render", "utility",

	"world", "inventory", "minigames", "legit",

}



local function loadFromTree(featureHost)

	local count = 0

	local root = script.Parent.Parent.plugins

	for _, cat in ipairs(categories) do

		local folder = root:FindFirstChild(cat)

		if folder then

			for _, mod in folder:GetChildren() do

				if mod:IsA("ModuleScript") and mod.Name:sub(1, 1) ~= "_" then

					local ok, plugin = pcall(require, mod)

					if ok and type(plugin) == "table" and plugin.id then

						featureHost:load(plugin)

						count += 1

					end

				end

			end

		end

	end

	return count

end



local function loadFromDisk(ctx, featureHost)

	local boot = ctx.boot

	local root = ctx.fileRoot or "proton/"

	if not boot or not listfiles or not isfolder then

		return 0

	end

	local count = 0

	for _, cat in ipairs(categories) do

		local dir = (root .. "src/proton/plugins/" .. cat):gsub("\\", "/")

		if isfolder(dir) then

			for _, path in listfiles(dir) do

				path = path:gsub("\\", "/")

				if path:find("%.lua$") then

					local name = path:match("([^/\\]+)%.lua$")

					if name and name:sub(1, 1) ~= "_" then

						local rel = "src/proton/plugins/" .. cat .. "/" .. name .. ".lua"

						local ok, plugin = pcall(function()

							return boot.run(rel)

						end)

						if ok and type(plugin) == "table" and plugin.id then

							featureHost:load(plugin)

							count += 1

						end

					end

				end

			end

		end

	end

	return count

end



function loader.run(ctx, featureHost)

	local count = loadFromDisk(ctx, featureHost)

	if count == 0 then

		count = loadFromTree(featureHost)

	end

	for _, def in ipairs(registry.manifest().list) do

		if not featureHost.plugins[def.id] then

			featureHost:load(registry.buildPlugin(def))

		end

	end

end



return loader

