--proton-cache:build
local CollectionService = game:GetService("CollectionService")

local style = require(script.Parent._style)

return {
	id = "BedESP",
	category = "render",
	settings = {},
	init = function(ctx, plugin)
		plugin.state.refs = {}
	end,
	enable = function(ctx, plugin, host)
		local holder = style.root("BedESP")
		plugin.state.holder = holder

		local function attach(bed)
			if plugin.state.refs[bed] then return end
			local pack = Instance.new("Folder")
			pack.Name = "bed"
			pack.Parent = holder
			plugin.state.refs[bed] = pack
			for _, part in bed:GetChildren() do
				if part:IsA("BasePart") and part.Name ~= "Blanket" then
					local tint = part.Name == "Legs" and Color3.fromRGB(167, 112, 64) or style.accent
					style.partOutline(part, pack, tint)
				end
			end
		end

		local function detach(bed)
			local pack = plugin.state.refs[bed]
			if pack then
				pack:Destroy()
				plugin.state.refs[bed] = nil
			end
		end

		for _, bed in CollectionService:GetTagged("bed") do
			attach(bed)
		end
		host:track(CollectionService:GetInstanceAddedSignal("bed"):Connect(function(bed)
			task.delay(0.2, attach, bed)
		end))
		host:track(CollectionService:GetInstanceRemovedSignal("bed"):Connect(detach))
	end,
	disable = function(ctx, plugin)
		if plugin.state.holder then
			style.wipe(plugin.state.holder)
		end
		table.clear(plugin.state.refs)
	end,
}
