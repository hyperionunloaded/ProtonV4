--proton-cache:build
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local overlays = {}
overlays.__index = overlays

local function guiRoot()
	local plr = Players.LocalPlayer
	return (gethui and gethui()) or plr:WaitForChild("PlayerGui")
end

function overlays.new(ctx)
	local root = Instance.new("ScreenGui")
	root.Name = "proton_overlays"
	root.ResetOnSpawn = false
	root.IgnoreGuiInset = true
	root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	root.DisplayOrder = 998
	root.Parent = guiRoot()

	local watermark = Instance.new("TextLabel")
	watermark.Name = "Watermark"
	watermark.BackgroundTransparency = 1
	watermark.Size = UDim2.fromOffset(200, 24)
	watermark.Position = UDim2.new(1, -210, 0, 8)
	watermark.Font = Enum.Font.GothamBold
	watermark.TextSize = 14
	watermark.TextColor3 = Color3.fromRGB(255, 255, 255)
	watermark.Text = "PROTON"
	watermark.TextXAlignment = Enum.TextXAlignment.Right
	watermark.Visible = false
	watermark.Parent = root

	local list = Instance.new("Frame")
	list.Name = "ArrayList"
	list.BackgroundTransparency = 1
	list.AutomaticSize = Enum.AutomaticSize.Y
	list.Size = UDim2.fromOffset(180, 0)
	list.Position = UDim2.new(1, -190, 0, 36)
	list.Visible = false
	list.Parent = root

	local flow = Instance.new("UIListLayout")
	flow.Padding = UDim.new(0, 2)
	flow.HorizontalAlignment = Enum.HorizontalAlignment.Right
	flow.SortOrder = Enum.SortOrder.LayoutOrder
	flow.Parent = list

	local ping = Instance.new("TextLabel")
	ping.Name = "Ping"
	ping.BackgroundTransparency = 1
	ping.Size = UDim2.fromOffset(120, 20)
	ping.Position = UDim2.new(0, 8, 0, 8)
	ping.Font = Enum.Font.GothamMedium
	ping.TextSize = 13
	ping.TextColor3 = Color3.fromRGB(200, 200, 210)
	ping.Text = "0 ms"
	ping.TextXAlignment = Enum.TextXAlignment.Left
	ping.Visible = false
	ping.Parent = root

	return setmetatable({
		ctx = ctx,
		root = root,
		watermark = watermark,
		list = list,
		ping = ping,
		listConn = nil,
		pingConn = nil,
		rows = {},
	}, overlays)
end

function overlays:set(id, state)
	if id == "Watermark" then
		self.watermark.Visible = state == true
	elseif id == "ArrayList" then
		self.list.Visible = state == true
		if state then
			self:bindList()
		else
			self:unbindList()
		end
	elseif id == "Ping" then
		self.ping.Visible = state == true
		if state then
			self:bindPing()
		else
			self:unbindPing()
		end
	elseif id == "TextGUI" then
		if self.ctx.ui and self.ctx.ui.setVisible then
			self.ctx.ui:setVisible(state == true)
		end
	end
end

function overlays:bindList()
	self:unbindList()
	self.listConn = RunService.RenderStepped:Connect(function()
		for _, row in self.rows do
			row:Destroy()
		end
		table.clear(self.rows)
		local n = 0
		for id, plugin in pairs(self.ctx.plugins) do
			if plugin.enabled then
				n += 1
				local row = Instance.new("TextLabel")
				row.BackgroundTransparency = 1
				row.Size = UDim2.new(1, 0, 0, 16)
				row.Font = Enum.Font.GothamMedium
				row.TextSize = 13
				row.TextColor3 = Color3.fromRGB(255, 255, 255)
				row.TextXAlignment = Enum.TextXAlignment.Right
				row.Text = id
				row.LayoutOrder = n
				row.Parent = self.list
				self.rows[#self.rows + 1] = row
			end
		end
	end)
end

function overlays:unbindList()
	if self.listConn then
		self.listConn:Disconnect()
		self.listConn = nil
	end
	for _, row in self.rows do
		row:Destroy()
	end
	table.clear(self.rows)
end

function overlays:bindPing()
	self:unbindPing()
	self.pingConn = RunService.RenderStepped:Connect(function()
		local n = 0
		pcall(function()
			n = math.floor(Players.LocalPlayer:GetNetworkPing() * 1000)
		end)
		self.ping.Text = tostring(n) .. " ms"
	end)
end

function overlays:unbindPing()
	if self.pingConn then
		self.pingConn:Disconnect()
		self.pingConn = nil
	end
end

function overlays:attach(ctx)
	for id, plugin in pairs(ctx.plugins) do
		if plugin.enabled then
			self:set(id, true)
		end
	end
	ctx.events.on("plugin:enable", function(id)
		if self.list.Visible then
		end
	end)
end

return overlays
