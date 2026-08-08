--proton-cache:build
local adapter = {}
adapter.__index = adapter

function adapter.new(guiApi)
	return setmetatable({
		api = guiApi,
		ctx = nil,
		modules = {},
		overlays = {},
	}, adapter)
end

function adapter:syncManifest(manifest)
	if not self.api or not self.api.applyManifest then return end
	self.api.applyManifest(manifest)
	if self.ctx then
		self.ctx.manifest = manifest
	end
end

function adapter:registerModule(def)
	self.modules[def.id] = def
	if self.api and self.api.registerModule then
		self.api.registerModule(def)
	end
end

function adapter:getModule(id)
	return self.modules[id]
end

function adapter:isEnabled(id)
	if self.api and self.api.isEnabled then
		return self.api.isEnabled(id)
	end
	local m = self.modules[id]
	return m and m.enabled == true
end

function adapter:setEnabled(id, state)
	if self.api and self.api.setEnabled then
		self.api.setEnabled(id, state)
		return
	end
	local m = self.modules[id]
	if not m then return end
	m.enabled = state
	if state and m.enable then m.enable(self.ctx) end
	if not state and m.disable then m.disable(self.ctx) end
end

function adapter:overlay(id)
	return self.overlays[id]
end

function adapter:setOverlay(id, state)
	self.overlays[id] = state
	if self.api and self.api.setOverlay then
		self.api.setOverlay(id, state)
	end
	if self.ctx and self.ctx.events then
		self.ctx.events.emit("overlay:" .. id, state)
	end
end

function adapter:getSetting(id, key)
	if self.api and self.api.getSetting then
		return self.api.getSetting(id, key)
	end
end

function adapter:setVisible(state)
	if self.api and self.api.setWindowVisible then
		self.api.setWindowVisible(state)
	end
end

return adapter
