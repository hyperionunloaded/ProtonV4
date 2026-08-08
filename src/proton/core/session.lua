--proton-cache:build
local Workspace = game:GetService("Workspace")

local session = {
	placeId = 0,
	isLobbyPlace = false,
	isGamePlace = false,
	matchState = 0,
	queueType = "bedwars_test",
	inLobby = true,
	inMatch = false,
	postGame = false,
	inGame = false,
	map = nil,
	mapName = "Unknown",
}

local LOBBY_PLACES = {
	[6872265039] = true,
}

local GAME_PLACES = {
	[6872274481] = true,
	[8560631822] = true,
	[8444591321] = true,
}

local function parseMapName(map)
	if not map then return "Unknown" end
	local raw = map.Name
	local split = string.split(raw, "_")[2] or raw
	return string.gsub(split, "-", "") or "Blank"
end

function session.bind(ctx)
	session.ctx = ctx
	session.store = ctx.store
	session.refresh()
	if session.ctx and session.ctx.events then
		session.ctx.events.emit("session:changed", session.snapshot())
	end
	return session
end

function session.refresh()
	local store = session.store
	session.placeId = game.PlaceId
	session.isLobbyPlace = LOBBY_PLACES[session.placeId] == true
	session.isGamePlace = GAME_PLACES[session.placeId] == true
	session.matchState = store and store.matchState or 0
	session.queueType = store and store.queueType or "bedwars_test"
	session.inMatch = session.matchState == 1
	session.postGame = session.matchState == 2
	session.inLobby = session.isLobbyPlace or session.matchState == 0
	session.inGame = not session.inLobby
	if store then
		store.map = session.map
	end
end

function session.onStoreChange(new, old)
	old = old or {}
	if not new.Game or new.Game == old.Game then return end
	local prevLobby = session.inLobby
	local prevMatch = session.inMatch
	local prevPost = session.postGame
	session.refresh()
	if prevLobby ~= session.inLobby or prevMatch ~= session.inMatch or prevPost ~= session.postGame then
		if session.ctx and session.ctx.events then
			session.ctx.events.emit("session:changed", session.snapshot())
		end
		if session.inMatch and not prevMatch then
			session.loadMap()
		end
		if session.inLobby and not prevLobby then
			session.map = nil
			session.mapName = "Unknown"
			if session.store then
				session.store.map = nil
			end
		end
	end
end

function session.snapshot()
	return {
		placeId = session.placeId,
		isLobbyPlace = session.isLobbyPlace,
		isGamePlace = session.isGamePlace,
		matchState = session.matchState,
		queueType = session.queueType,
		inLobby = session.inLobby,
		inMatch = session.inMatch,
		postGame = session.postGame,
		inGame = session.inGame,
		mapName = session.mapName,
	}
end

function session.loadMap()
	if session.map then return session.map end
	task.spawn(function()
		local ok = pcall(function()
			local mapFolder = Workspace:WaitForChild("Map", 20)
			if not mapFolder then return end
			local worlds = mapFolder:WaitForChild("Worlds", 20)
			if not worlds then return end
			local map = worlds:GetChildren()[1]
			if not map then return end
			session.map = map
			session.mapName = parseMapName(map)
			if session.store then
				session.store.map = map
			end
			if session.ctx and session.ctx.events then
				session.ctx.events.emit("session:map", map, session.mapName)
			end
		end)
		if not ok then
			session.mapName = "Unknown"
		end
	end)
end

function session.waitForMatch()
	if session.inMatch then return true end
	if session.isLobbyPlace then return false end
	repeat
		task.wait()
	until session.inGame or (session.ctx and session.ctx.running == false)
	return session.inGame
end

function session.waitForActiveMatch()
	if session.inMatch then return true end
	repeat
		task.wait()
	until session.inMatch or (session.ctx and session.ctx.running == false)
	return session.inMatch
end

function session.canRun(scope)
	scope = scope or "match"
	if scope == "any" then return true end
	if scope == "lobby" then return session.isLobbyPlace end
	if scope == "game" then return session.inGame end
	if scope == "match" then return session.inMatch end
	if scope == "not_post" then return session.inMatch or session.inGame and not session.postGame end
	return session.inMatch
end

function session.label()
	if session.isLobbyPlace then return "Lobby" end
	if session.inMatch then return "In Game" end
	if session.postGame then return "Post Game" end
	if session.inGame then return "Loading" end
	return "Lobby"
end

return session
