--proton-cache:build
local host = {}
host.__index = host

function host.new(ctx)
	return setmetatable({
		ctx = ctx,
		plugins = {},
		refs = {},
		conns = {},
	}, host)
end

function host:track(conn)
	self.conns[#self.conns + 1] = conn
	return conn
end

function host:clear()
	for _, conn in ipairs(self.conns) do
		conn:Disconnect()
	end
	table.clear(self.conns)
end

function host:register(plugin)
	if not plugin or not plugin.id then return end
	plugin.settings = plugin.settings or {}
	plugin.state = plugin.state or {}
	self.plugins[plugin.id] = plugin
	self.ctx:registerPlugin(plugin)
end

function host:setRef(key, value)
	self.refs[key] = value
end

function host:getRef(key)
	return self.refs[key]
end

function host:applyDefaults(plugin)
	for _, def in ipairs(plugin.settings or {}) do
		if plugin.state[def.id] == nil and def.default ~= nil then
			plugin.state[def.id] = def.default
		end
	end
end

function host:enable(id)
	local plugin = self.plugins[id]
	if not plugin or plugin.enabled then return end
	plugin.enabled = true
	plugin.pendingEnable = nil
	if plugin.enable then
		plugin.enable(self.ctx, plugin, self)
	end
	self.ctx.events.emit("plugin:enable", id)
end

function host:disable(id)
	local plugin = self.plugins[id]
	if not plugin or not plugin.enabled then
		if plugin then plugin.pendingEnable = nil end
		return
	end
	plugin.enabled = false
	plugin.pendingEnable = nil
	if plugin._waitConn then
		plugin._waitConn()
		plugin._waitConn = nil
	end
	if plugin.disable then
		plugin.disable(self.ctx, plugin, self)
	end
	self.ctx.events.emit("plugin:disable", id)
end

function host:toggle(id)
	local plugin = self.plugins[id]
	if not plugin then return end
	if plugin.enabled then
		self:disable(id)
	else
		self:enable(id)
	end
end

function host:get(plugin, key, fallback)
	if plugin.state[key] ~= nil then
		return plugin.state[key]
	end
	return fallback
end

function host:load(plugin)
	if not plugin.scope then
		plugin.scope = "match"
	end
	self:register(plugin)
	self:applyDefaults(plugin)
	if plugin.init then
		plugin.init(self.ctx, plugin, self)
	end
end

function host:bindSession()
	local session = self.ctx.session
	if not session or self._sessionBound then return end
	self._sessionBound = true
	self:track(self.ctx.events.on("session:changed", function()
		for id, plugin in pairs(self.plugins) do
			local scope = plugin.scope or "match"
			if plugin.enabled and not session.canRun(scope) then
				self:disable(id)
			end
		end
	end))
end

return host
