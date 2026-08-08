--proton-cache:build
local manifest = require(script.Parent.Parent.data.modules)

local registry = {}

function registry.manifest()
	return manifest
end

function registry.stock()
	return manifest.stock
end

function registry.index()
	return manifest.index
end

function registry.shelves()
	return manifest.shelfOrder
end

function registry.meta()
	return manifest.shelfMeta
end

function registry.buildPlugin(def)
	local scope = "match"
	if def.category == "legit" then
		scope = "any"
	elseif def.category == "utility" and (def.id == "AutoPlay" or def.id == "EquipKit" or def.id == "LeaveParty" or def.id == "StaffDetector") then
		scope = "any"
	end
	return {
		id = def.id,
		category = def.category,
		info = def.info,
		scope = scope,
		settings = {},
		enabled = false,
		init = function() end,
		enable = function() end,
		disable = function() end,
	}
end

function registry.seed(ctx)
	for _, def in ipairs(manifest.list) do
		local existing = ctx.plugins[def.id]
		if not existing then
			ctx:registerPlugin(registry.buildPlugin(def))
		end
	end
end

return registry
