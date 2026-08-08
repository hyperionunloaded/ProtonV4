--proton-cache:build
local events = {}
local pools = {}

function events.on(name, fn)
	pools[name] = pools[name] or {}
	pools[name][#pools[name] + 1] = fn
	return function()
		local bucket = pools[name]
		if not bucket then return end
		for i, v in ipairs(bucket) do
			if v == fn then
				table.remove(bucket, i)
				break
			end
		end
	end
end

function events.emit(name, ...)
	local bucket = pools[name]
	if not bucket then return end
	for i = 1, #bucket do
		task.spawn(bucket[i], ...)
	end
end

return events
