--proton-cache:build
repeat task.wait() until game:IsLoaded()

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
	return "hyperionunloaded/ProtonV4"
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

local splashGui

local function makeSplash()
	local Players = game:GetService("Players")
	local pg = (gethui and gethui()) or Players.LocalPlayer:WaitForChild("PlayerGui")
	splashGui = Instance.new("ScreenGui")
	splashGui.Name = "proton_boot"
	splashGui.ResetOnSpawn = false
	splashGui.IgnoreGuiInset = true
	splashGui.DisplayOrder = 998
	splashGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	splashGui.Parent = pg
	local shell = Color3.fromRGB(13, 13, 15)
	local accent = Color3.fromRGB(45, 210, 150)
	local grey = Color3.fromRGB(108, 108, 115)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(960, 590)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.BackgroundColor3 = shell
	frame.BorderSizePixel = 0
	frame.Parent = splashGui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromOffset(240, 28)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.new(0.5, 0, 0, 168)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Text = "PROTON V4"
	title.Parent = frame
	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.Size = UDim2.fromOffset(240, 20)
	sub.AnchorPoint = Vector2.new(0.5, 0)
	sub.Position = UDim2.new(0.5, 0, 0, 198)
	sub.Font = Enum.Font.GothamMedium
	sub.TextSize = 13
	sub.TextColor3 = grey
	sub.Text = "Fetching UI..."
	sub.Parent = frame
	local track = Instance.new("Frame")
	track.Size = UDim2.fromOffset(440, 10)
	track.AnchorPoint = Vector2.new(0.5, 0)
	track.Position = UDim2.new(0.5, 0, 0, 232)
	track.BackgroundColor3 = Color3.fromRGB(46, 46, 51)
	track.BorderSizePixel = 0
	track.Parent = frame
	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(0, 5)
	tc.Parent = track
	local pulse = Instance.new("Frame")
	pulse.Size = UDim2.fromScale(0.35, 1)
	pulse.BackgroundColor3 = accent
	pulse.BorderSizePixel = 0
	pulse.Parent = track
	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(0, 5)
	pc.Parent = pulse
	task.spawn(function()
		while splashGui and splashGui.Parent and pulse.Parent do
			pulse.Position = UDim2.fromScale(0, 0)
			pulse:TweenPosition(UDim2.fromScale(0.65, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, 0.9, true)
			task.wait(0.9)
		end
	end)
	return splashGui
end

local function killSplash()
	if splashGui then
		splashGui:Destroy()
		splashGui = nil
	end
end

local function downloadFile(workspacePath, remotePath)
	remotePath = remotePath or workspacePath:gsub("^" .. ROOT, "")
	if isfile(workspacePath) then
		return readfile(workspacePath), false
	end
	local ok, res = pcall(function()
		return game:HttpGet(rawUrl(remotePath), true)
	end)
	if not ok or res == "" or res == "404: Not Found" then
		error(tostring(res))
	end
	ensureParent(workspacePath)
	writefile(workspacePath, stamp(res))
	return res, true
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
	writefile(ROOT .. "profiles/repo.txt", "hyperionunloaded/ProtonV4")
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

makeSplash()

local uiApi
local loadStart = tick()

local function pushProgress(done, total, name)
	if uiApi and uiApi.updateDownload then
		uiApi.updateDownload(done, total, name, loadStart)
	end
end

downloadFile(ROOT .. "manifest/files.txt", "manifest/files.txt")

local manifestFiles = {}
local manifestBody = readfile(ROOT .. "manifest/files.txt")
for line in manifestBody:gmatch("[^\r\n]+") do
	local rel = line:gsub("^%s+", ""):gsub("%s+$", "")
	if rel ~= "" and rel:find("%.lua$") and rel ~= "loader.lua" then
		manifestFiles[#manifestFiles + 1] = rel
	end
end

table.sort(manifestFiles, function(a, b)
	if a == "ui/proton_ui.lua" then return true end
	if b == "ui/proton_ui.lua" then return false end
	return a < b
end)

local total = #manifestFiles
local done = 0
local uiLoaded = false

for _, rel in ipairs(manifestFiles) do
	local path = ROOT .. rel
	if not isfile(path) then
		downloadFile(path, rel)
	end
	if rel == "ui/proton_ui.lua" and not uiLoaded then
		local uiFn, uiErr = loadstring(readfile(path), path)
		if not uiFn then
			killSplash()
			error(uiErr)
		end
		uiApi = uiFn()
		_G.ProtonUI = uiApi
		uiLoaded = true
		killSplash()
		if uiApi.startDownload then
			uiApi.startDownload(total)
		end
	end
	done += 1
	pushProgress(done, total, rel)
end

if not uiLoaded then
	killSplash()
	error("proton ui missing from manifest")
end

if uiApi.finishDownload then
	uiApi.finishDownload()
end

return loadstring(readfile(ROOT .. "main.lua"), "proton/main")()
