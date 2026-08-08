--proton-cache:build
local notify = {}

function notify.push(title, body, kind)
	kind = kind or "info"
	print(string.format("[proton:%s] %s — %s", kind, title, body or ""))
end

return notify
