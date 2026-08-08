--proton-cache:build
local loader = {}
local registry = require(script.Parent.registry)

local categories = {
	"combat", "blatant", "render", "utility",
	"world", "inventory", "minigames", "legit",
}

function loader.run(ctx, featureHost)
	local root = script.Parent.Parent.plugins
	for _, cat in ipairs(categories) do
		local folder = root:FindFirstChild(cat)
		if folder then
			for _, mod in folder:GetChildren() do
				if mod:IsA("ModuleScript") and mod.Name:sub(1, 1) ~= "_" then
					local ok, plugin = pcall(require, mod)
					if ok and type(plugin) == "table" and plugin.id then
						featureHost:load(plugin)
					end
				end
			end
		end
	end
	for _, def in ipairs(registry.manifest().list) do
		if not featureHost.plugins[def.id] then
			featureHost:load(registry.buildPlugin(def))
		end
	end
end

return loader
