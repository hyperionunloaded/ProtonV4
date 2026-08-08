--proton-cache:build
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local entity = {}
entity.alive = false
entity.self = nil
entity.list = {}
entity.threads = {}
entity.playerLinks = {}
entity.links = {}
entity.running = false

local function eventBus()
	local pool = {}
	return {
		connect = function(_, fn)
			pool[#pool + 1] = fn
			return function()
				for i, v in ipairs(pool) do
					if v == fn then
						table.remove(pool, i)
						break
					end
				end
			end
		end,
		fire = function(_, ...)
			for i = 1, #pool do
				task.spawn(pool[i], ...)
			end
		end,
	}
end

entity.events = {
	localAdded = eventBus(),
	localRemoved = eventBus(),
	added = eventBus(),
	removed = eventBus(),
	updated = eventBus(),
}

local camera = Workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

local function waitPart(parent, className, timeout, useProperty)
	local deadline = os.clock() + (timeout or 10)
	local found
	repeat
		found = useProperty and parent[className] or parent:FindFirstChildOfClass(className)
		if found then return found end
		task.wait()
	until os.clock() >= deadline
	return found
end

function entity.isVulnerable(ent)
	if not ent or not ent.character then return false end
	if ent.health <= 0 then return false end
	return not ent.character:FindFirstChildWhichIsA("ForceField")
end

function entity.canTarget(ent, player)
	if not ent then return false end
	if ent.npc then return true end
	if not player or not ent.player then return false end
	if player:GetAttribute("Team") and ent.player:GetAttribute("Team") then
		return player:GetAttribute("Team") ~= ent.player:GetAttribute("Team")
	end
	if player.Team and ent.player.Team then
		return player.Team ~= ent.player.Team
	end
	return true
end

function entity.get(char)
	for i, ent in ipairs(entity.list) do
		if ent.character == char or ent.player == char then
			return ent, i
		end
	end
end

function entity.remove(char, isLocal)
	if isLocal then
		if entity.alive and entity.self then
			entity.alive = false
			for _, conn in ipairs(entity.self.connections) do
				conn:Disconnect()
			end
			entity.events.localRemoved:fire(entity.self)
		end
		return
	end
	if entity.threads[char] then
		task.cancel(entity.threads[char])
		entity.threads[char] = nil
	end
	local ent, idx = entity.get(char)
	if not idx then return end
	for _, conn in ipairs(ent.connections) do
		conn:Disconnect()
	end
	table.remove(entity.list, idx)
	entity.events.removed:fire(ent)
end

function entity.track(char, player, teamFn)
	if not char then return end
	entity.threads[char] = task.spawn(function()
		local hum = waitPart(char, "Humanoid", 10)
		local root = hum and waitPart(hum, "RootPart", Workspace.StreamingEnabled and 999999 or 10, true)
		local head = char:FindFirstChild("Head") or root
		if not hum or not root then
			entity.threads[char] = nil
			return
		end
		local ent = {
			character = char,
			player = player,
			npc = player == nil,
			humanoid = hum,
			root = root,
			head = head,
			health = char:GetAttribute("Health") or hum.Health,
			maxHealth = char:GetAttribute("MaxHealth") or hum.MaxHealth,
			connections = {},
			teamFn = teamFn,
		}
		if player == localPlayer then
			entity.self = ent
			entity.alive = true
			entity.events.localAdded:fire(ent)
		else
			ent.targetable = teamFn and teamFn(ent) or entity.canTarget(ent, localPlayer)
			ent.connections[#ent.connections + 1] = char:GetAttributeChangedSignal("Health"):Connect(function()
				ent.health = char:GetAttribute("Health") or hum.Health
				entity.events.updated:fire(ent)
			end)
			ent.connections[#ent.connections + 1] = char:GetAttributeChangedSignal("MaxHealth"):Connect(function()
				ent.maxHealth = char:GetAttribute("MaxHealth") or hum.MaxHealth
				entity.events.updated:fire(ent)
			end)
			entity.list[#entity.list + 1] = ent
			entity.events.added:fire(ent)
		end
		ent.connections[#ent.connections + 1] = char.ChildRemoved:Connect(function(part)
			if part == root or part == hum or part == head then
				entity.remove(char, player == localPlayer)
			end
		end)
		entity.threads[char] = nil
	end)
end

function entity.refresh(char, player, teamFn)
	entity.remove(char, player == localPlayer)
	entity.track(char, player, teamFn)
end

function entity.watchPlayer(player)
	if player.Character then
		entity.refresh(player.Character, player)
	end
	entity.playerLinks[player] = {
		player.CharacterAdded:Connect(function(char)
			entity.refresh(char, player)
		end),
		player.CharacterRemoving:Connect(function(char)
			entity.remove(char, player == localPlayer)
		end),
		player:GetAttributeChangedSignal("Team"):Connect(function()
			if player == localPlayer then
				for _, ent in ipairs(entity.list) do
					entity.refresh(ent.character, ent.player, ent.teamFn)
				end
			else
				local ent = entity.get(player)
				if ent then entity.refresh(ent.character, player, ent.teamFn) end
			end
		end),
	}
end

function entity.unwatchPlayer(player)
	local pack = entity.playerLinks[player]
	if not pack then return end
	for _, conn in ipairs(pack) do
		conn:Disconnect()
	end
	entity.playerLinks[player] = nil
	entity.remove(player.Character, player == localPlayer)
end

function entity.nearest(opts)
	if not entity.alive then return nil end
	opts = opts or {}
	local origin = opts.origin or entity.self.root.Position
	local part = opts.part or "root"
	local maxRange = opts.range or 30
	local best, bestMag
	for _, ent in ipairs(entity.list) do
		if not ent.targetable then continue end
		if opts.players == false and ent.player then continue end
		if opts.npcs == false and ent.npc then continue end
		local node = part == "head" and ent.head or ent.root
		if not node then continue end
		if not entity.isVulnerable(ent) then continue end
		local mag = (node.Position - origin).Magnitude
		if mag > maxRange then continue end
		if not best or mag < bestMag then
			best, bestMag = ent, mag
		end
	end
	return best
end

function entity.start()
	if entity.running then entity.stop() end
	entity.links[#entity.links + 1] = Players.PlayerAdded:Connect(entity.watchPlayer)
	entity.links[#entity.links + 1] = Players.PlayerRemoving:Connect(entity.unwatchPlayer)
	entity.links[#entity.links + 1] = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		camera = Workspace.CurrentCamera
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		entity.watchPlayer(player)
	end
	entity.running = true
end

function entity.stop()
	for _, conn in ipairs(entity.links) do
		conn:Disconnect()
	end
	table.clear(entity.links)
	for player in pairs(entity.playerLinks) do
		entity.unwatchPlayer(player)
	end
	entity.remove(nil, true)
	for char in pairs(entity.threads) do
		task.cancel(entity.threads[char])
	end
	table.clear(entity.threads)
	entity.running = false
end

return entity
