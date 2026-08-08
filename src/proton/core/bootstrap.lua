--proton-cache:build
local Players = game:GetService("Players")
local cloneref = cloneref or function(o) return o end

local ctx = require(script.Parent.ctx)
local events = require(script.Parent.events)
local scheduler = require(script.Parent.scheduler)
local registry = require(script.Parent.registry)
local notify = require(script.Parent.notify)

local bootstrap = {}
bootstrap.__index = bootstrap

function bootstrap.new()
	local c = ctx.new()
	c.events = events
	c.scheduler = scheduler
	c.notify = notify
	return setmetatable({ ctx = c }, bootstrap)
end

function bootstrap:init()
	local plr = cloneref(Players.LocalPlayer)
	self.ctx:setPlayer(plr)
	self.ctx.character = plr.Character or plr.CharacterAdded:Wait()
	plr.CharacterAdded:Connect(function(char)
		self.ctx.character = char
	end)
	registry.seed(self.ctx)
	return self
end

function bootstrap:loadGame(name)
	self.ctx.gameId = name
	if name == "bedwars" then
		require(script.Parent.Parent.game.bw).init(self.ctx)
	else
		local ok, gameMod = pcall(require, script.Parent.Parent.game[name])
		if ok and gameMod and gameMod.init then
			gameMod.init(self.ctx)
		end
	end
	self.ctx.game = name
	return self
end

function bootstrap:attachUI(adapter)
	self.ctx:setUI(adapter)
	adapter.ctx = self.ctx
	if adapter.syncManifest then
		adapter:syncManifest(registry.manifest())
	end
	return self
end

function bootstrap:loadPlugins()
	local loader = require(script.Parent.loader)
	loader.run(self.ctx)
	return self
end

function bootstrap:run()
	self.ctx.running = true
	events.emit("proton:ready", self.ctx)
end

return bootstrap
