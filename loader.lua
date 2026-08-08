--proton-cache:build
local ROOT = "proton/"
local MARKER = "--proton-cache:"

local isfile = isfile or function(file)
	local ok, res = pcall(function()
		return readfile(file)
	end)
	return ok and res ~= nil and res ~= ""
end

local delfile = delfile or function(file)
	writefile(file, "")
end

local function repoSlug()
	local path = ROOT .. "profiles/repo.txt"
	if isfile(path) then
		local slug = readfile(path):gsub("%s+", "")
		if slug ~= "" then
			return slug
		end
	end
	return "hyperionunloaded/ProtonCompiled"
end

local function branchRef()
	local path = ROOT .. "profiles/commit.txt"
	if isfile(path) then
		return readfile(path):gsub("%s+", "")
	end
	return "main"
end

local function rawUrl(rel)
	return "https://raw.githubusercontent.com/" .. repoSlug() .. "/" .. branchRef() .. "/" .. rel
end

local function ensureParent(path)
	local dir = path:match("^(.*)/[^/]+$")
	if not dir or dir == "" then
		return
	end
	if isfolder and not isfolder(dir) then
		makefolder(dir)
	end
end

local function stamp(body)
	if body:find("%.lua") then
		return MARKER .. branchRef() .. "\n" .. body
	end
	return body
end

local function downloadFile(workspacePath, remotePath)
	remotePath = remotePath or workspacePath:gsub("^" .. ROOT, "")
	if isfile(workspacePath) then
		return readfile(workspacePath)
	end
	local ok, res = pcall(function()
		return game:HttpGet(rawUrl(remotePath), true)
	end)
	if not ok or res == "" or res == "404: Not Found" then
		error(tostring(res))
	end
	ensureParent(workspacePath)
	writefile(workspacePath, stamp(res))
	return res
end

local function wipeFolder(path)
	if not isfolder or not isfolder(path) then
		return
	end
	for _, file in listfiles(path) do
		if file:find("loader") then
			continue
		end
		if isfile(file) then
			local body = readfile(file)
			if body:sub(1, #MARKER) == MARKER then
				delfile(file)
			end
		end
	end
end

for _, folder in {
	ROOT:sub(1, -2),
	ROOT .. "profiles",
	ROOT .. "manifest",
	ROOT .. "lib",
	ROOT .. "ui",
	ROOT .. "src/proton/core",
	ROOT .. "src/proton/data",
	ROOT .. "src/proton/game",
	ROOT .. "src/proton/ui",
	ROOT .. "src/proton/plugins",
} do
	if isfolder and not isfolder(folder) then
		makefolder(folder)
	end
end

if not isfile(ROOT .. "profiles/repo.txt") then
	writefile(ROOT .. "profiles/repo.txt", "hyperionunloaded/ProtonCompiled")
end

if not shared.ProtonDeveloper then
	local commit = "main"
	pcall(function()
		local html = game:HttpGet("https://github.com/" .. repoSlug())
		local pos = html:find("currentOid")
		if pos then
			local hash = html:sub(pos + 13, pos + 52)
			if #hash == 40 then
				commit = hash
			end
		end
	end)
	local prev = isfile(ROOT .. "profiles/commit.txt") and readfile(ROOT .. "profiles/commit.txt"):gsub("%s+", "") or ""
	if commit == "main" or prev ~= commit then
		wipeFolder(ROOT)
		wipeFolder(ROOT .. "manifest")
		wipeFolder(ROOT .. "lib")
		wipeFolder(ROOT .. "ui")
		wipeFolder(ROOT .. "src")
	end
	writefile(ROOT .. "profiles/commit.txt", commit)
end

downloadFile(ROOT .. "manifest/files.txt", "manifest/files.txt")
downloadFile(ROOT .. "lib/boot.lua", "lib/boot.lua")

local manifest = readfile(ROOT .. "manifest/files.txt")
for line in manifest:gmatch("[^\r\n]+") do
	local rel = line:gsub("^%s+", ""):gsub("%s+$", "")
	if rel ~= "" and rel:find("%.lua$") then
		pcall(function()
			downloadFile(ROOT .. rel, rel)
		end)
	end
end

downloadFile(ROOT .. "main.lua", "main.lua")
return loadstring(readfile(ROOT .. "main.lua"), "proton/main")()
