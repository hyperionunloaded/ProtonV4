--proton-cache:build
local CollectionService = game:GetService("CollectionService")

local style = require(script.Parent._style)

local kitMap = {
	alchemist = { "alchemist_ingedients", "wild_flower" },
	beekeeper = { "bee", "bee" },
	bigman = { "treeOrb", "natures_essence_1" },
	ghost_catcher = { "ghost", "ghost_orb" },
	metal_detector = { "hidden-metal", "iron" },
	sheep_herder = { "SheepModel", "purple_hay_bale" },
	sorcerer = { "alchemy_crystal", "wild_flower" },
	star_collector = { "stars", "crit_star" },
}

return {
	id = "KitESP",
	category = "render",
	settings = {
		{ id = "background", kind = "toggle", default = true },
	},
	init = function(ctx, plugin)
		plugin.state.boards = {}
	end,
	enable = function(ctx, plugin, host)
		local holder = style.root("KitESP")
		plugin.state.holder = holder
		local bw = ctx.bw

		local function attach(part, icon)
			if not part or plugin.state.boards[part] then return end
			local bb = style.plateBoard(holder, part, Vector3.new(0, 2.5, 0))
			bb.Frame.BackgroundTransparency = plugin.state.background and 0.35 or 1
			local row = bb.Frame.Row
			local image = Instance.new("ImageLabel")
			image.Size = UDim2.fromOffset(30, 30)
			image.BackgroundTransparency = 1
			image.Image = bw.getIcon({ itemType = icon }, true)
			image.Parent = row
			plugin.state.boards[part] = bb
		end

		local function detach(part)
			local bb = plugin.state.boards[part]
			if bb then
				bb:Destroy()
				plugin.state.boards[part] = nil
			end
		end

		local function watch(tag, icon)
			host:track(CollectionService:GetInstanceAddedSignal(tag):Connect(function(model)
				if model.PrimaryPart then
					attach(model.PrimaryPart, icon)
				end
			end))
			host:track(CollectionService:GetInstanceRemovedSignal(tag):Connect(function(model)
				if model.PrimaryPart then
					detach(model.PrimaryPart)
				end
			end))
			for _, model in CollectionService:GetTagged(tag) do
				if model.PrimaryPart then
					attach(model.PrimaryPart, icon)
				end
			end
		end

		task.spawn(function()
			repeat task.wait() until ctx.store.equippedKit ~= "" or not plugin.enabled
			if not plugin.enabled then return end
			local pair = kitMap[ctx.store.equippedKit]
			if pair then
				watch(pair[1], pair[2])
			end
		end)
	end,
	disable = function(ctx, plugin)
		if plugin.state.holder then
			style.wipe(plugin.state.holder)
		end
		table.clear(plugin.state.boards)
	end,
}
