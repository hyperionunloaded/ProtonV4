--proton-cache:build
local resolver = {}
resolver.__index = resolver

function resolver.new(ctx)
	return setmetatable({ ctx = ctx, cache = {}, ns = {} }, resolver)
end

function resolver:remote(name)
	if self.cache[name] then return self.cache[name] end
	for _, root in ipairs(self.ctx.roots) do
		local found = root:FindFirstChild(name, true)
		if found and (found:IsA("RemoteEvent") or found:IsA("RemoteFunction")) then
			self.cache[name] = found
			return found
		end
	end
	return nil
end

function resolver:namespace(ns)
	if self.ns[ns] then return self.ns[ns] end
	local client = self.ctx.client
	if not client or not client.GetNamespace then return nil end
	local ok, mod = pcall(function()
		return client:GetNamespace(ns)
	end)
	if ok then
		self.ns[ns] = mod
		return mod
	end
	return nil
end

function resolver:bedwarsRemote(name)
	local key = "bw:" .. name
	if self.cache[key] then return self.cache[key] end
	local client = self.ctx.client
	if client and client.Get then
		local ok, mod = pcall(function()
			return client:Get(name)
		end)
		if ok and mod then
			self.cache[key] = mod
			return mod
		end
	end
	return self:remote(name)
end

function resolver:bedwarsFire(name, ...)
	local r = self:bedwarsRemote(name)
	if not r then return false end
	if r.SendToServer then
		r:SendToServer(...)
		return true
	end
	if r.FireServer then
		r:FireServer(...)
		return true
	end
	if r.Fire then
		r:Fire(...)
		return true
	end
	return false
end

function resolver:fire(name, ...)
	local r = self:remote(name)
	if not r then return false end
	if r.FireServer then
		r:FireServer(...)
	else
		r:Fire(...)
	end
	return true
end

return resolver
