--proton-cache:build
local bootstrap = require(script.Parent.core.bootstrap)
local adapter = require(script.Parent.ui.adapter)
local manifest = require(script.Parent.data.modules)
local overlays = require(script.Parent.data.overlays)
local hostMod = require(script.Parent.core.host)

_G.ProtonManifest = manifest

local app = bootstrap.new()
app:init()
app:loadGame("bedwars")

local featureHost = hostMod.new(app.ctx)
app.ctx.host = featureHost

local guiApi = _G.ProtonUI
local uiAdapter
if guiApi then
	uiAdapter = adapter.new(guiApi)
	guiApi.onOverlay = function(id, state)
		uiAdapter:setOverlay(id, state)
	end
	if guiApi.initOverlays then
		guiApi.initOverlays(overlays)
	end
	guiApi.onToggle = function(id, state)
		if state then featureHost:enable(id) else featureHost:disable(id) end
	end
	app:attachUI(uiAdapter)
end

local loader = require(script.Parent.core.loader)
loader.run(app.ctx, featureHost)
featureHost:bindSession()

if guiApi and app.ctx.session then
	local function syncSession()
		local snap = app.ctx.session.snapshot()
		if guiApi.setSession then
			guiApi.setSession(app.ctx.session.label())
		end
		if guiApi.setLobbyMode then
			guiApi.setLobbyMode(snap.isLobbyPlace)
		end
	end
	syncSession()
	app.ctx.events.on("session:changed", syncSession)
end

app.ctx.events.on("plugin:disable", function(id)
	if guiApi and guiApi.forceEnabled then
		guiApi.forceEnabled(id, false)
	end
end)

app:run()

return app.ctx
