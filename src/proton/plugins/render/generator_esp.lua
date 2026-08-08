--proton-cache:build
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local style = require(script.Parent._style)

local whitelistDefault = { "diamond", "iron", "emerald", "gold" }

return {
	id = "GeneratorESP",
	category = "render",
	settings = {
		{ id = "scale", kind = "range", default = 1, min = 0.5, max = 1.5, step = 0.1 },
		{ id = "whitelist", kind = "toggle", default = true },
	},
	init = function(ctx, plugin)
		plugin.state.tags = {}
		plugin.state.allowed = whitelistDefault
	end,
	enable = function(ctx, plugin, host)
		local holder = style.root("GeneratorESP")
		plugin.state.holder = holder
		local camera = Workspace.CurrentCamera

		local function tierKey(ent, titleText)
			if titleText then return "iron" end
			local ore = ent:GetAttribute("Id")
			if not ore then return "" end
			ore = ore:sub(1, #ore - 2)
			return (ore:sub(1, 1):upper() .. ore:sub(2)):lower()
		end

		local function title(ent)
			local app = ent:FindFirstChild("RoactTree")
			app = app and app:FindFirstChild("TeamOreGeneratorApp")
			local node = app and (app:FindFirstChild("GlobalOreGenerator") or app:FindFirstChild("TeamGenMain"))
			node = node and node:FindFirstChild("Title")
			if node then return node.Text, true end
			local ore = ent:GetAttribute("Id")
			if not ore then return "Generator", false end
			ore = ore:sub(1, #ore - 2)
			local name = ore:sub(1, 1):upper() .. ore:sub(2)
			return name .. " Generator", false
		end

		local function cooldownText(ent)
			local app = ent:FindFirstChild("RoactTree")
			app = app and app:FindFirstChild("TeamOreGeneratorApp")
			if not app then return "" end
			for _, d in app:GetDescendants() do
				if d:IsA("TextLabel") and d.Text:find("%d") then
					local sec = d.Text:match("%[(%d+)%]") or d.Text:match("(%d+)")
					if sec then return " · " .. sec .. "s" end
				end
			end
			return ""
		end

		local function attach(ent)
			if plugin.state.tags[ent] then return end
			local name, isTeam = title(ent)
			local tier = tierKey(ent, isTeam and name or nil)
			if plugin.state.whitelist and not table.find(plugin.state.allowed, tier) then
				return
			end
			local bb, label = style.worldBillboard(holder, Vector3.new(0, 1.5, 0))
			bb.Adornee = ent
			local level = ent:GetAttribute("GeneratorLevel") or 1
			label.Text = name .. " · T" .. tostring(level)
			label.TextSize = 13 * (plugin.state.scale or 1)
			plugin.state.tags[ent] = { bb = bb, label = label, name = name }
		end

		local function detach(ent)
			local row = plugin.state.tags[ent]
			if row then
				row.bb:Destroy()
				plugin.state.tags[ent] = nil
			end
		end

		for _, ent in CollectionService:GetTagged("Generator") do
			attach(ent)
		end
		host:track(CollectionService:GetInstanceAddedSignal("Generator"):Connect(attach))
		host:track(CollectionService:GetInstanceRemovedSignal("Generator"):Connect(detach))
		host:track(RunService.PreRender:Connect(function()
			for ent, row in pairs(plugin.state.tags) do
				if not ent.Parent then
					detach(ent)
					continue
				end
				local _, vis = camera:WorldToViewportPoint(ent.Position + Vector3.new(0, 1.5, 0))
				row.bb.Enabled = vis
				if vis then
					local level = ent:GetAttribute("GeneratorLevel") or 1
					row.label.Text = row.name .. " · T" .. tostring(level) .. cooldownText(ent)
				end
			end
		end))
	end,
	disable = function(ctx, plugin)
		if plugin.state.holder then
			style.wipe(plugin.state.holder)
		end
		table.clear(plugin.state.tags)
	end,
}
