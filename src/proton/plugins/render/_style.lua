--proton-cache:build
local Players = game:GetService("Players")

local accent = Color3.fromRGB(45, 210, 150)
local panel = Color3.fromRGB(12, 16, 20)
local text = Color3.fromRGB(228, 234, 240)
local muted = Color3.fromRGB(108, 118, 128)

local function root(name)
	local gui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local tag = "ProtonRender_" .. name
	local existing = gui:FindFirstChild(tag)
	if existing then
		return existing
	end
	local holder = Instance.new("Folder")
	holder.Name = tag
	holder.Parent = gui
	return holder
end

local function wipe(holder)
	holder:ClearAllChildren()
end

local function bracketFrame(parent, thickness, span)
	thickness = thickness or 1
	span = span or 7
	local wrap = Instance.new("Frame")
	wrap.BackgroundTransparency = 1
	wrap.Size = UDim2.fromOffset(span, span)
	wrap.Parent = parent

	local h = Instance.new("Frame")
	h.BackgroundColor3 = accent
	h.BorderSizePixel = 0
	h.Size = UDim2.fromOffset(span, thickness)
	h.Parent = wrap

	local v = Instance.new("Frame")
	v.BackgroundColor3 = accent
	v.BorderSizePixel = 0
	v.Size = UDim2.fromOffset(thickness, span)
	v.Parent = wrap

	return wrap
end

local function tagShell(parent)
	local shell = Instance.new("Frame")
	shell.BackgroundColor3 = panel
	shell.BackgroundTransparency = 0.28
	shell.BorderSizePixel = 0
	shell.AutomaticSize = Enum.AutomaticSize.XY
	shell.Parent = parent

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 5)
	pad.PaddingBottom = UDim.new(0, 5)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = shell

	local tl = bracketFrame(shell, 1, 8)
	tl.AnchorPoint = Vector2.new(0, 0)
	tl.Position = UDim2.fromOffset(-2, -2)

	local tr = bracketFrame(shell, 1, 8)
	tr.AnchorPoint = Vector2.new(1, 0)
	tr.Position = UDim2.new(1, 2, 0, -2)
	tr.Rotation = 90

	local bl = bracketFrame(shell, 1, 8)
	bl.AnchorPoint = Vector2.new(0, 1)
	bl.Position = UDim2.new(0, -2, 1, 2)
	bl.Rotation = -90

	local br = bracketFrame(shell, 1, 8)
	br.AnchorPoint = Vector2.new(1, 1)
	br.Position = UDim2.new(1, 2, 1, 2)
	br.Rotation = 180

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextColor3 = text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.Parent = shell

	return shell, label
end

local function screenTag(holder)
	local anchor = Instance.new("Frame")
	anchor.BackgroundTransparency = 1
	anchor.Size = UDim2.fromOffset(0, 0)
	anchor.Visible = false
	anchor.Parent = holder
	local shell, label = tagShell(anchor)
	shell.Position = UDim2.fromOffset(0, 0)
	return anchor, label
end

local function worldBillboard(holder, studs)
	local bb = Instance.new("BillboardGui")
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 512
	bb.Size = UDim2.fromOffset(0, 0)
	bb.StudsOffset = studs or Vector3.new(0, 2, 0)
	bb.Parent = holder
	local shell, label = tagShell(bb)
	return bb, label
end

local function partOutline(part, parent, tint)
	local tone = tint or accent
	local folder = Instance.new("Folder")
	folder.Parent = parent
	local hl = Instance.new("Highlight")
	hl.Adornee = part
	hl.FillColor = panel
	hl.FillTransparency = 0.82
	hl.OutlineColor = tone
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = folder
	local edge = Instance.new("SelectionBox")
	edge.Adornee = part
	edge.Color3 = tone
	edge.LineThickness = 0.02
	edge.SurfaceTransparency = 1
	edge.Parent = folder
	return folder
end

local function plateBoard(holder, adornee, offset)
	local bb = Instance.new("BillboardGui")
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Size = UDim2.fromOffset(40, 40)
	bb.StudsOffsetWorldSpace = offset or Vector3.new(0, 3, 0)
	bb.Adornee = adornee
	bb.Parent = holder

	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = panel
	frame.BackgroundTransparency = 0.35
	frame.BorderSizePixel = 0
	frame.Parent = bb

	local tl = bracketFrame(frame, 1, 10)
	tl.Position = UDim2.fromOffset(2, 2)
	local br = bracketFrame(frame, 1, 10)
	br.AnchorPoint = Vector2.new(1, 1)
	br.Position = UDim2.new(1, -2, 1, -2)
	br.Rotation = 180

	local row = Instance.new("Frame")
	row.Name = "Row"
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromScale(1, 1)
	row.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 3)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = row

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		bb.Size = UDim2.fromOffset(math.max(layout.AbsoluteContentSize.X + 12, 40), 40)
	end)

	return bb, row
end

local function healthTone(ratio)
	ratio = math.clamp(ratio or 0, 0, 1)
	if ratio > 0.66 then
		return accent
	end
	if ratio > 0.33 then
		return Color3.fromRGB(210, 180, 45)
	end
	return Color3.fromRGB(210, 70, 70)
end

return {
	accent = accent,
	panel = panel,
	text = text,
	muted = muted,
	root = root,
	wipe = wipe,
	screenTag = screenTag,
	worldBillboard = worldBillboard,
	partOutline = partOutline,
	plateBoard = plateBoard,
	healthTone = healthTone,
}
