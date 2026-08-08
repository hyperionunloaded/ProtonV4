--proton-cache:build
local ctx = {}
ctx.__index = ctx

function ctx.new()
	return setmetatable({
		player = nil,
		character = nil,
		roots = {},
		remotes = {},
		controllers = {},
		inventory = {},
		targeting = {},
		kits = {},
		ui = nil,
		plugins = {},
		overlays = {},
		flags = {},
		binds = {},
		running = false,
		gameId = nil,
		game = nil,
		client = nil,
		resolver = nil,
		events = nil,
		scheduler = nil,
		notify = nil,
		manifest = nil,
		session = nil,
		host = nil,
		bw = nil,
		store = nil,
		entity = nil,
	}, ctx)
end

function ctx:setPlayer(plr)
	self.player = plr
end

function ctx:setUI(adapter)
	self.ui = adapter
end

function ctx:registerPlugin(plugin)
	if not plugin or not plugin.id then return end
	self.plugins[plugin.id] = plugin
end

function ctx:plugin(id)
	return self.plugins[id]
end

return ctx
