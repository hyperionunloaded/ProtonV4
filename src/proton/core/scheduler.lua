--proton-cache:build
local scheduler = {}
local jobs = {}
local nextId = 0

function scheduler.every(interval, fn)
	nextId += 1
	local id = nextId
	local alive = true
	jobs[id] = true
	task.spawn(function()
		while alive and jobs[id] do
			task.spawn(fn)
			task.wait(interval)
		end
	end)
	return function()
		alive = false
		jobs[id] = nil
	end
end

function scheduler.defer(fn)
	task.defer(fn)
end

function scheduler.stopAll()
	table.clear(jobs)
end

return scheduler
