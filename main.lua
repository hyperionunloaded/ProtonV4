--proton-cache:build
repeat task.wait() until game:IsLoaded()

if shared.ProtonCtx and shared.ProtonCtx.running then
	shared.ProtonCtx.running = false
end

local ROOT = "proton/"
local cloneref = cloneref or function(o) return o end
local playersService = cloneref(game:GetService("Players"))
local queue_on_teleport = queue_on_teleport or function() end

local isfile = isfile or function(file)
	local ok, res = pcall(function()
		return readfile(file)
	end)
	return ok and res ~= nil and res ~= ""
end

local function finishLoading(ctx)
	task.spawn(function()
		local teleported
		local conn = playersService.LocalPlayer.OnTeleport:Connect(function()
			if teleported or shared.ProtonIndependent then
				return
			end
			teleported = true
			local branch = isfile(ROOT .. "profiles/commit.txt") and readfile(ROOT .. "profiles/commit.txt"):gsub("%s+", "") or "main"
			local slug = isfile(ROOT .. "profiles/repo.txt") and readfile(ROOT .. "profiles/repo.txt"):gsub("%s+", "") or "bitdancerfr/ProtonCompiled"
			local reload = [[
shared.protonreload = true
]]
			if shared.ProtonDeveloper then
				reload = reload .. "shared.ProtonDeveloper = true\nloadstring(readfile('proton/loader.lua'), 'proton-loader')()\n"
			else
				reload = reload .. "loadstring(game:HttpGet('https://raw.githubusercontent.com/" .. slug .. "/'..'" .. branch .. "'..'/loader.lua', true), 'proton-loader')()\n"
			end
			queue_on_teleport(reload)
		end)
		if ctx.events then
			ctx.events.on("proton:shutdown", function()
				conn:Disconnect()
			end)
		end
	end)
end

local boot = loadstring(readfile(ROOT .. "lib/boot.lua"), "proton/boot")()
boot.setRoot(ROOT)

local manifestBody = readfile(ROOT .. "manifest/files.txt")
local files = {}
for line in manifestBody:gmatch("[^\r\n]+") do
	local rel = line:gsub("^%s+", ""):gsub("%s+$", "")
	if rel ~= "" then
		files[#files + 1] = rel
	end
end
boot.registerMany(files)

boot.loadUI("ui/vape_ui.lua")

local ctx = boot.run("src/proton/main.lua")
shared.ProtonCtx = ctx

if not shared.ProtonIndependent then
	finishLoading(ctx)
end

return ctx
