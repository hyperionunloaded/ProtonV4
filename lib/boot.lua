--proton-cache:build
local ROOT = "proton/"
local nodes = {}
local loaded = {}

local boot = {}

function boot.setRoot(root)
	ROOT = root or "proton/"
	if ROOT ~= "" and ROOT:sub(-1) ~= "/" then
		ROOT = ROOT .. "/"
	end
end

local function split(path)
	local out = {}
	for part in string.gmatch(path, "[^/]+") do
		out[#out + 1] = part
	end
	return out
end

local function childKey(parentKey, name)
	if parentKey == "" then
		return name
	end
	return parentKey .. "/" .. name
end

local function makeFolder(key, name, parent)
	local node = {
		Name = name,
		Parent = parent,
		_key = key,
		_isModule = false,
	}
	function node:IsA(class)
		return class == "Folder" or class == "ModuleScript" and self._isModule == true
	end
	function node:FindFirstChild(n)
		return nodes[childKey(self._key, n)]
	end
	function node:GetChildren()
		local kids = {}
		local prefix = self._key .. "/"
		for k, v in pairs(nodes) do
			if k:sub(1, #prefix) == prefix then
				local rest = k:sub(#prefix + 1)
				if rest ~= "" and not rest:find("/") then
					kids[#kids + 1] = v
				end
			end
		end
		return kids
	end
	setmetatable(node, {
		__index = function(self, n)
			if rawget(self, n) ~= nil then
				return rawget(self, n)
			end
			return self:FindFirstChild(n)
		end,
	})
	nodes[key] = node
	return node
end

local function ensurePath(dirPath)
	local parts = split(dirPath)
	local key = ""
	local parent = nil
	for _, name in ipairs(parts) do
		key = childKey(key, name)
		if not nodes[key] then
			parent = makeFolder(key, name, parent)
		else
			parent = nodes[key]
		end
	end
	return parent
end

local function register(relPath)
	relPath = relPath:gsub("\\", "/")
	if not relPath:find("%.lua$") then
		return
	end
	local dir = relPath:match("^(.*)/") or ""
	local name = relPath:match("([^/]+)%.lua$")
	ensurePath(dir)
	local modKey = dir == "" and name or dir .. "/" .. name
	local parent = dir == "" and nil or nodes[dir]
	local node = nodes[modKey]
	if not node then
		node = {
			Name = name,
			Parent = parent,
			_key = modKey,
			_isModule = true,
			_file = ROOT .. relPath,
		}
		function node:IsA(class)
			return class == "ModuleScript" or class == "Folder" and false
		end
		function node:FindFirstChild(n)
			return nodes[childKey(self._key, n)]
		end
		function node:GetChildren()
			return {}
		end
		setmetatable(node, {
			__index = function(self, n)
				if rawget(self, n) ~= nil then
					return rawget(self, n)
				end
				return self:FindFirstChild(n)
			end,
		})
		nodes[modKey] = node
	end
	node._isModule = true
	node._file = ROOT .. relPath
	node.Parent = parent
end

local function protonRequire(mod)
	if type(mod) ~= "table" or not mod._file then
		error("proton require: bad module", 2)
	end
	local key = mod._key
	if loaded[key] ~= nil then
		return loaded[key]
	end
	local src = readfile(mod._file)
	if not src or src == "" then
		error("proton require: missing " .. mod._file, 2)
	end
	loaded[key] = true
	local env = setmetatable({
		script = mod,
		require = protonRequire,
	}, { __index = _G })
	local fn, err
	if load then
		fn, err = load(src, mod._file, "t", env)
	else
		fn, err = loadstring(src, mod._file)
		if fn and setfenv then
			setfenv(fn, env)
		end
	end
	if not fn then
		loaded[key] = nil
		error(err, 2)
	end
	local ok, result = pcall(fn)
	if not ok then
		loaded[key] = nil
		error(result, 2)
	end
	if result == nil then
		result = true
	end
	loaded[key] = result
	return result
end

function boot.register(relPath)
	register(relPath)
end

function boot.registerMany(list)
	for _, path in ipairs(list) do
		register(path)
	end
end

function boot.run(relPath)
	register(relPath)
	local key = relPath:gsub("%.lua$", "")
	local node = nodes[key]
	if not node then
		error("proton boot: unknown module " .. relPath)
	end
	return protonRequire(node)
end

function boot.loadUI(relPath)
	register(relPath)
	local node = nodes[relPath:gsub("%.lua$", "")]
	local src = readfile(node._file)
	local fn, err = loadstring(src, node._file)
	if not fn then
		error(err, 2)
	end
	return fn()
end

return boot
