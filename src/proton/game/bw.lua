--proton-cache:build
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local util = require(script.Parent.util)

local bw = {}

local function waitKnit()
	local knit
	repeat
		local ok, res = pcall(function()
			return debug.getupvalue(require(Players.LocalPlayer.PlayerScripts.TS.knit).setup, 9)
		end)
		if ok then knit = res break end
		task.wait()
	until knit
	repeat task.wait() until debug.getupvalue(knit.Start, 1)
	return knit
end

function bw.init(ctx)
	local knit = waitKnit()
	local flamework = require(ReplicatedStorage.rbxts_include.node_modules["@flamework"].core.out).Flamework
	local inventoryUtil = require(ReplicatedStorage.TS.inventory["inventory-util"]).InventoryUtil
	local remotes = require(ReplicatedStorage.TS.remotes).default
	local client = remotes.Client
	local oldGet = client.Get

	local cache = {}
	local handler = {}
	handler.__index = handler

	function handler:Get(id)
		if cache[id] then return cache[id] end
		local slot = setmetatable({ id = id }, handler)
		local ok, remote = pcall(function()
			return oldGet(client, id)
		end)
		slot.ok = ok
		slot.remote = ok and remote or nil
		cache[id] = slot
		return slot
	end

	function handler:Fire(method, ...)
		if not self.ok or not self.remote then return end
		local fn = self.remote[method] or self.remote.SendToServer or self.remote.CallServer or self.remote.CallServerAsync
		if fn then
			return fn(self.remote, ...)
		end
	end

	local blockEngine = require(ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["block-engine"].out).BlockEngine

	ctx.bw = setmetatable({
		knit = knit,
		client = client,
		handler = handler,
		query = require(ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["game-core"].out).GameQueryUtil,
		blockEngine = blockEngine,
		blockController = blockEngine,
		itemMeta = debug.getupvalue(require(ReplicatedStorage.TS.item["item-meta"]).getItemMeta, 1),
		projectileMeta = require(ReplicatedStorage.TS.projectile["projectile-meta"]).ProjectileMeta,
		combatConstant = require(ReplicatedStorage.TS.combat["combat-constant"]).CombatConstant,
		knockbackUtil = require(ReplicatedStorage.TS.damage["knockback-util"]).KnockbackUtil,
		appController = require(ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["game-core"].out.client.controllers["app-controller"]).AppController,
		uiLayers = require(ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["game-core"].out).UILayers,
		sprintController = knit.Controllers.SprintController,
		swordController = knit.Controllers.SwordController,
		blockBreaker = knit.Controllers.BlockBreakController.blockBreaker,
		blockBreakController = knit.Controllers.BlockBreakController,
		balloonController = knit.Controllers.BalloonController,
		partyController = flamework.resolveDependency("@easy-games/lobby:client/controllers/party-controller@PartyController"),
		queueController = knit.Controllers.QueueController,
		emoteController = knit.Controllers.EmoteController,
		emoteMeta = require(ReplicatedStorage.TS.locker.emote["emote-meta"]).EmoteMeta,
		emoteType = require(ReplicatedStorage.TS.locker.emote["emote-type"]).EmoteType,
		emoteDisplayMeta = require(ReplicatedStorage.TS.locker.emote["emote-display-meta"]).EmoteDisplayMeta,
		settingsController = knit.Controllers.SettingsController,
		settingsMeta = require(ReplicatedStorage.TS.settings["settings-meta"]).SettingMeta,
		bedwarsKitMeta = require(ReplicatedStorage.TS.games.bedwars.kit["bedwars-kit-meta"]).BedwarsKitMeta,
		queueMeta = require(ReplicatedStorage.TS.game["queue-meta"]).QueueMeta,
		sharedConstants = require(ReplicatedStorage.TS["shared-constants"]).CpsConstants,
		projectileController = knit.Controllers.ProjectileController,
		ravenController = knit.Controllers.RavenController,
		guidedProjectileController = knit.Controllers.GuidedProjectileController,
		runtimeLib = require(ReplicatedStorage.rbxts_include.RuntimeLib),
		bowConstantsTable = debug.getupvalue(knit.Controllers.ProjectileController.enableBeam, 8),
		userInputController = knit.Controllers.UserInputController,
		abilityController = knit.Controllers.AbilityController,
		getInventory = function(plr)
			local ok, res = pcall(function()
				return inventoryUtil.getInventory(plr)
			end)
			return ok and res or { items = {}, armor = {} }
		end,
		fire = function(name, method, ...)
			return handler:Get(name):Fire(method or "SendToServer", ...)
		end,
		call = function(name, ...)
			return handler:Get(name):Fire("CallServer", ...)
		end,
		util = util,
	}, {
		__index = function(t, k)
			local v = knit.Controllers[k]
			rawset(t, k, v)
			return v
		end,
	})

	ctx.store = require(script.Parent.Parent.core.store)
	ctx.entity = require(script.Parent.Parent.core.entity)
	ctx.entity.start()
	util.attach(ctx, ctx.bw)
	ctx.session = util.session
	if ctx.session.inMatch then
		ctx.session.loadMap()
	end
end

return bw
