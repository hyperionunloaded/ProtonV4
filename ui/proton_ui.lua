--proton-cache:build
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local me = Players.LocalPlayer

local hue = {
	shell    = Color3.fromRGB(13, 13, 15),
	rim      = Color3.fromRGB(34, 34, 39),
	line     = Color3.fromRGB(28, 28, 32),
	slab     = Color3.fromRGB(26, 26, 29),
	slabLit  = Color3.fromRGB(38, 38, 42),
	white    = Color3.fromRGB(255, 255, 255),
	label    = Color3.fromRGB(228, 228, 232),
	grey     = Color3.fromRGB(108, 108, 115),
	dust     = Color3.fromRGB(84, 84, 91),
	chip     = Color3.fromRGB(42, 42, 47),
	offBar   = Color3.fromRGB(46, 46, 51),
	offNub   = Color3.fromRGB(210, 210, 218),
	onNub    = Color3.fromRGB(16, 16, 18),
	amber    = Color3.fromRGB(245, 166, 35),
	accent   = Color3.fromRGB(45, 210, 150),
	sheet    = Color3.fromRGB(20, 20, 23),
	dock     = Color3.fromRGB(14, 14, 17),
	well     = Color3.fromRGB(26, 26, 30),
	wellRim  = Color3.fromRGB(44, 44, 50),
	wellTxt  = Color3.fromRGB(190, 190, 198),
	rail     = Color3.fromRGB(44, 44, 50),
	tip      = Color3.fromRGB(122, 122, 130),
	liveBar  = Color3.fromRGB(228, 228, 232),
}

local W, H = 960, 590
local HEAD, TABS = 56, 42
local RULE = HEAD + TABS

local SIDE_X, SIDE_W = 24, 228
local BODY_Y = RULE + 18
local BODY_H = H - BODY_Y - 18

local MAIN_X = SIDE_X + SIDE_W + 18
local MAIN_W = W - MAIN_X - 18

local CAT_H, CAT_SPACE = 40, 4
local MOD_H, MOD_SPACE = 50, 6

local DOCK_GAP = 8
local PANEL_W = 330
local PANEL_TOP = RULE
local PANEL_H = H - RULE
local NARROW_W = MAIN_W - PANEL_W - DOCK_GAP

local function round(o, r)
	local u = Instance.new("UICorner")
	u.CornerRadius = UDim.new(0, r)
	u.Parent = o
	return u
end

local function edge(o, c, t)
	local s = Instance.new("UIStroke")
	s.Color = c
	s.Thickness = t or 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = o
	return s
end

local function pane(par, sz, ps, col)
	local f = Instance.new("Frame")
	f.Size = sz
	f.Position = ps
	f.BackgroundColor3 = col or hue.slab
	f.BorderSizePixel = 0
	f.Parent = par
	return f
end

local function words(par, s, px, col, fnt)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Text = s
	t.TextSize = px
	t.TextColor3 = col
	t.Font = fnt or Enum.Font.GothamMedium
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.RichText = false
	t.Parent = par
	return t
end

local function tap(par, sz, ps)
	local b = Instance.new("TextButton")
	b.Size = sz
	b.Position = ps
	b.BackgroundTransparency = 1
	b.Text = ""
	b.AutoButtonColor = false
	b.Parent = par
	return b
end

local screen = Instance.new("ScreenGui")
screen.Name = "proton"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.IgnoreGuiInset = true
screen.DisplayOrder = 999
screen.Parent = (gethui and gethui()) or me:WaitForChild("PlayerGui")

local overlayDefs = {}
local overlayState = {}
local overlayTiles = {}
local protonApi = {}

local buildOverlayTiles, setOverlayOpen, paintOverlayTile, toggleOverlay, overlayPanelRef
do
	local OVL_W, OVL_H = 620, 78
	local OVL_BTN, OVL_GAP = 36, 4
	local OVL_RED = Color3.fromRGB(235, 58, 58)
	local OVL_OFF = Color3.fromRGB(38, 38, 44)

	local overlayDim = tap(screen, UDim2.fromScale(1, 1), UDim2.new())
	overlayDim.BackgroundColor3 = Color3.new()
	overlayDim.BackgroundTransparency = 1
	overlayDim.Visible = false
	overlayDim.ZIndex = 200

	local overlayPanel = pane(screen, UDim2.fromOffset(OVL_W, OVL_H), UDim2.new(0.5, 0, 1, -24))
	overlayPanel.AnchorPoint = Vector2.new(0.5, 1)
	overlayPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 21)
	overlayPanel.Visible = false
	overlayPanel.ZIndex = 201
	round(overlayPanel, 8)
	edge(overlayPanel, hue.rim)

	local ovlHead = pane(overlayPanel, UDim2.new(1, 0, 0, 22), UDim2.new(), Color3.fromRGB(18, 18, 21))
	ovlHead.BackgroundTransparency = 1
	ovlHead.ZIndex = 202

	local ovlTab = Instance.new("ImageLabel")
	ovlTab.Size = UDim2.fromOffset(12, 11)
	ovlTab.Position = UDim2.fromOffset(10, 6)
	ovlTab.BackgroundTransparency = 1
	ovlTab.Image = "rbxassetid://14397380433"
	ovlTab.ImageColor3 = hue.label
	ovlTab.ZIndex = 203
	ovlTab.Parent = ovlHead

	local ovlTitle = words(ovlHead, "Overlays", 12, hue.label, Enum.Font.GothamMedium)
	ovlTitle.Position = UDim2.fromOffset(28, 0)
	ovlTitle.Size = UDim2.fromOffset(120, 22)
	ovlTitle.ZIndex = 203

	local ovlBack = tap(ovlHead, UDim2.fromOffset(56, 22), UDim2.new(1, -10, 0, 0))
	ovlBack.ZIndex = 203
	local ovlBackIco = Instance.new("ImageLabel")
	ovlBackIco.Size = UDim2.fromOffset(10, 10)
	ovlBackIco.Position = UDim2.fromOffset(0, 6)
	ovlBackIco.BackgroundTransparency = 1
	ovlBackIco.Image = "rbxassetid://14368303894"
	ovlBackIco.ImageColor3 = hue.grey
	ovlBackIco.Parent = ovlBack
	local ovlBackTxt = words(ovlBack, "Back", 12, hue.grey)
	ovlBackTxt.Position = UDim2.fromOffset(14, 0)
	ovlBackTxt.Size = UDim2.fromOffset(40, 22)

	local ovlRow = pane(overlayPanel, UDim2.new(1, -16, 0, OVL_BTN), UDim2.fromOffset(8, 30), Color3.fromRGB(18, 18, 21))
	ovlRow.BackgroundTransparency = 1
	ovlRow.ZIndex = 202

	local ovlFlow = Instance.new("UIListLayout")
	ovlFlow.FillDirection = Enum.FillDirection.Horizontal
	ovlFlow.Padding = UDim.new(0, OVL_GAP)
	ovlFlow.SortOrder = Enum.SortOrder.LayoutOrder
	ovlFlow.Parent = ovlRow

	setOverlayOpen = function(open)
		overlayDim.Visible = open
		overlayPanel.Visible = open
		overlayDim.BackgroundTransparency = open and 0.45 or 1
	end

	paintOverlayTile = function(id)
		local tile = overlayTiles[id]
		if not tile then return end
		local on = overlayState[id] == true
		tile.btn.BackgroundColor3 = on and OVL_RED or OVL_OFF
		tile.ico.ImageColor3 = on and hue.white or hue.dust
	end

	toggleOverlay = function(id)
		overlayState[id] = not overlayState[id]
		paintOverlayTile(id)
		if protonApi.onOverlay then
			protonApi.onOverlay(id, overlayState[id])
		end
	end

	buildOverlayTiles = function(list)
		for _, ch in ipairs(ovlRow:GetChildren()) do
			if not ch:IsA("UIListLayout") then ch:Destroy() end
		end
		table.clear(overlayTiles)
		overlayDefs = list or {}
		for i, def in ipairs(overlayDefs) do
			if overlayState[def.id] == nil then overlayState[def.id] = false end
			local btn = tap(ovlRow, UDim2.fromOffset(OVL_BTN, OVL_BTN), UDim2.new())
			btn.LayoutOrder = i
			btn.BackgroundTransparency = 0
			btn.ZIndex = 203
			round(btn, 6)
			local ico = Instance.new("ImageLabel")
			ico.Size = UDim2.fromOffset(18, 18)
			ico.AnchorPoint = Vector2.new(0.5, 0.5)
			ico.Position = UDim2.fromScale(0.5, 0.5)
			ico.BackgroundTransparency = 1
			ico.Image = def.icon
			ico.ScaleType = Enum.ScaleType.Fit
			ico.ZIndex = 204
			ico.Parent = btn
			overlayTiles[def.id] = { btn = btn, ico = ico }
			btn.MouseButton1Click:Connect(function()
				toggleOverlay(def.id)
			end)
			paintOverlayTile(def.id)
		end
	end

	overlayDim.MouseButton1Click:Connect(function() setOverlayOpen(false) end)
	ovlBack.MouseButton1Click:Connect(function() setOverlayOpen(false) end)

	overlayPanelRef = overlayPanel
end

local win = Instance.new("Frame")
win.Name = "win"
win.AnchorPoint = Vector2.new(0.5, 0.5)
win.Size = UDim2.fromOffset(W, H)
win.Position = UDim2.fromScale(0.5, 0.5)
win.BackgroundColor3 = hue.shell
win.BorderSizePixel = 0
win.ClipsDescendants = false
win.ZIndex = 1
win.Parent = screen
edge(win, hue.rim)

local winScale = Instance.new("UIScale")
winScale.Parent = win

local loadLayer = pane(win, UDim2.fromScale(1, 1), UDim2.new(), hue.dock)
loadLayer.ZIndex = 90
loadLayer.Visible = false

local loadLogo = Instance.new("ImageLabel")
loadLogo.Size = UDim2.fromOffset(48, 48)
loadLogo.AnchorPoint = Vector2.new(0.5, 0)
loadLogo.Position = UDim2.new(0.5, 0, 0, 148)
loadLogo.BackgroundTransparency = 1
loadLogo.Image = "rbxassetid://14368322199"
loadLogo.ScaleType = Enum.ScaleType.Fit
loadLogo.Parent = loadLayer

local loadTitle = words(loadLayer, "PROTON", 20, hue.white, Enum.Font.GothamBold)
loadTitle.AnchorPoint = Vector2.new(0.5, 0)
loadTitle.Position = UDim2.new(0.5, 0, 0, 200)
loadTitle.Size = UDim2.fromOffset(240, 28)
loadTitle.TextXAlignment = Enum.TextXAlignment.Center

local loadSub = words(loadLayer, "Downloading assets", 13, hue.grey)
loadSub.AnchorPoint = Vector2.new(0.5, 0)
loadSub.Position = UDim2.new(0.5, 0, 0, 228)
loadSub.Size = UDim2.fromOffset(240, 20)
loadSub.TextXAlignment = Enum.TextXAlignment.Center

local barTrack = pane(loadLayer, UDim2.fromOffset(440, 10), UDim2.new(0.5, -220, 0, 262), hue.offBar)
round(barTrack, 5)
local barFill = pane(barTrack, UDim2.fromScale(0, 1), UDim2.new(), hue.accent)
round(barFill, 5)

local loadPct = words(loadLayer, "0%", 12, hue.white, Enum.Font.GothamBold)
loadPct.AnchorPoint = Vector2.new(0.5, 0)
loadPct.Position = UDim2.new(0.5, 0, 0, 282)
loadPct.Size = UDim2.fromOffset(80, 18)
loadPct.TextXAlignment = Enum.TextXAlignment.Center

local loadMeta = words(loadLayer, "0 / 0 · 0.0s", 12, hue.tip)
loadMeta.AnchorPoint = Vector2.new(0.5, 0)
loadMeta.Position = UDim2.new(0.5, 0, 0, 302)
loadMeta.Size = UDim2.fromOffset(440, 18)
loadMeta.TextXAlignment = Enum.TextXAlignment.Center

local loadFile = words(loadLayer, "", 11, hue.dust)
loadFile.AnchorPoint = Vector2.new(0.5, 0)
loadFile.Position = UDim2.new(0.5, 0, 0, 324)
loadFile.Size = UDim2.fromOffset(440, 16)
loadFile.TextXAlignment = Enum.TextXAlignment.Center

local loadStart = 0
local loadTotal = 0

do
	local held, grab, anchor
	win.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if i.Position.Y - win.AbsolutePosition.Y > RULE * winScale.Scale then return end
		held, grab, anchor = true, i.Position, win.Position
	end)
	win.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then held = false end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if not held or i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local d = i.Position - grab
		win.Position = UDim2.new(anchor.X.Scale, anchor.X.Offset + d.X, anchor.Y.Scale, anchor.Y.Offset + d.Y)
	end)
end

local mark = words(win, "PROTON", 22, hue.white, Enum.Font.GothamBold)
mark.Position = UDim2.fromOffset(28, 0)
mark.Size = UDim2.fromOffset(120, HEAD)

local tag = pane(win, UDim2.fromOffset(58, 20), UDim2.fromOffset(88, 18), hue.chip)
round(tag, 5)
tag.Visible = false
local tagTxt = words(tag, "", 11, Color3.fromRGB(172, 172, 180), Enum.Font.GothamBold)
tagTxt.Size = UDim2.fromScale(1, 1)
tagTxt.TextXAlignment = Enum.TextXAlignment.Center

local STAR_ICON = "rbxassetid://6034509993"
local SEARCH_ICON = "rbxassetid://14368354234"

local featureHost = nil

local overlayBtn = tap(win, UDim2.fromOffset(32, 32), UDim2.new(1, -94, 0, 12))
local overlayIco = Instance.new("ImageLabel")
overlayIco.Size = UDim2.fromScale(1, 1)
overlayIco.BackgroundTransparency = 1
overlayIco.Image = "rbxassetid://14368339581"
overlayIco.ImageColor3 = hue.grey
overlayIco.ScaleType = Enum.ScaleType.Fit
overlayIco.Parent = overlayBtn

local gearBtn = tap(win, UDim2.fromOffset(32, 32), UDim2.new(1, -54, 0, 12))
local gearIco = Instance.new("ImageLabel")
gearIco.Size = UDim2.fromScale(1, 1)
gearIco.BackgroundTransparency = 1
gearIco.Image = "rbxassetid://14368318994"
gearIco.ImageColor3 = hue.grey
gearIco.ScaleType = Enum.ScaleType.Fit
gearIco.Parent = gearBtn

for _, set in ipairs({ { overlayBtn, nil, overlayIco }, { gearBtn, nil, gearIco } }) do
	local btn = set[1]
	local img = set[3]
	local function tint(c)
		if set[2] then set[2].TextColor3 = c end
		if img then img.ImageColor3 = c end
		for _, ch in ipairs(btn:GetDescendants()) do
			if ch:IsA("Frame") and ch.BackgroundColor3 ~= hue.shell then ch.BackgroundColor3 = c end
			if ch:IsA("UIStroke") then ch.Color = c end
		end
	end
	btn.MouseEnter:Connect(function() tint(hue.white) end)
	btn.MouseLeave:Connect(function() tint(hue.grey) end)
end

pane(win, UDim2.new(1, -44, 0, 2), UDim2.fromOffset(22, RULE), hue.line)

local tabMap = {}
local tabPick = "Modules"
local tx = 22

for _, nm in ipairs({ "Modules", "Friends", "Profiles" }) do
	local w = #nm * 9 + 18

	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(w, TABS)
	b.Position = UDim2.fromOffset(tx, HEAD)
	b.BackgroundTransparency = 1
	b.Text = nm
	b.TextSize = 15
	b.Font = Enum.Font.GothamMedium
	b.TextColor3 = nm == tabPick and hue.white or hue.dust
	b.AutoButtonColor = false
	b.Parent = win

	local ul = pane(win, UDim2.fromOffset(w - 18, 2), UDim2.fromOffset(tx + 9, RULE - 1), hue.white)
	ul.Visible = nm == tabPick
	ul.ZIndex = 2
	round(ul, 2)

	tabMap[nm] = { b = b, ul = ul }
	tx = tx + w + 12
end

local heading = words(win, "Modules", 18, hue.white, Enum.Font.GothamBold)
heading.Position = UDim2.fromOffset(28, BODY_Y)
heading.Size = UDim2.fromOffset(SIDE_W, 28)

local catBox = Instance.new("ScrollingFrame")
catBox.Size = UDim2.fromOffset(SIDE_W, BODY_H - 44)
catBox.Position = UDim2.fromOffset(SIDE_X, BODY_Y + 38)
catBox.BackgroundTransparency = 1
catBox.BorderSizePixel = 0
catBox.ScrollBarThickness = 0
catBox.CanvasSize = UDim2.new()
catBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
catBox.ScrollingDirection = Enum.ScrollingDirection.Y
catBox.ZIndex = 3
catBox.Parent = win

local catFlow = Instance.new("UIListLayout")
catFlow.Padding = UDim.new(0, CAT_SPACE)
catFlow.SortOrder = Enum.SortOrder.LayoutOrder
catFlow.Parent = catBox

local catPad = Instance.new("UIPadding")
catPad.PaddingLeft = UDim.new(0, 10)
catPad.PaddingRight = UDim.new(0, 10)
catPad.Parent = catBox

local shelves = {
	{ id = "Favorites", icon = STAR_ICON, tint = hue.amber },
	{ id = "Combat", icon = "rbxassetid://14368312652" },
	{ id = "Blatant", icon = "rbxassetid://14368306745" },
	{ id = "Render", icon = "rbxassetid://14368350193" },
	{ id = "Utility", icon = "rbxassetid://14368359107" },
	{ id = "World", icon = "rbxassetid://14368362492" },
	{ id = "Inventory", icon = "rbxassetid://14928011633" },
	{ id = "Minigames", icon = "rbxassetid://14368324807" },
	{ id = "Legit", icon = "rbxassetid://14425650534" },
}

local stock = {}
local rawManifest = nil
local lobbyMode = false
local lobbyHidden = { Combat = true, Minigames = true }
local manifestLoaded = false

local function loadManifestSource()
	if _G.ProtonManifest then return _G.ProtonManifest end
	local ok, data = pcall(function()
		return loadfile("src/proton/data/modules.lua")()
	end)
	if ok then return data end
	ok, data = pcall(function()
		return loadfile("../src/proton/data/modules.lua")()
	end)
	if ok then return data end
	return nil
end

local function seedStockFromManifest(manifest, hideLobby)
	table.clear(stock)
	for shelf, list in pairs(manifest.stock) do
		if not (hideLobby and lobbyHidden[shelf]) then
			stock[shelf] = {}
			for _, def in ipairs(list) do
				stock[shelf][#stock[shelf] + 1] = { id = def.id, info = def.info }
			end
		end
	end
	manifestLoaded = true
end

local fallback = {
	Combat = {
		{ id = "AutoClicker", info = "Automatic clicking" },
		{ id = "Reach", info = "Extends melee attack reach" },
		{ id = "Velocity", info = "Modifies knockback velocity", key = "G" },
	},
	Blatant = {
		{ id = "Fly", info = "Flight movement" },
		{ id = "Speed", info = "Movement speed boost" },
		{ id = "Killaura", info = "Automatic melee attacks" },
	},
	Render = {
		{ id = "BedESP", info = "Highlights beds" },
		{ id = "NameTags", info = "Custom name tags", key = "X" },
		{ id = "ItemESP", info = "Highlights dropped items" },
	},
	Utility = {
		{ id = "Scaffold", info = "Automatic bridging" },
		{ id = "AutoKit", info = "Automatic kit selection" },
	},
	World = {
		{ id = "BedPatcher", info = "Patches beds with blocks" },
		{ id = "BlockIn", info = "Blocks yourself in" },
		{ id = "FastPlace", info = "Places blocks faster", key = "Z" },
	},
	Inventory = {
		{ id = "AutoBuy", info = "Automatic shop buying" },
		{ id = "AutoHotbar", info = "Hotbar organization" },
	},
	Minigames = {
		{ id = "AutoZeno", info = "Zeno kit automation" },
		{ id = "VulcanAimbot", info = "Vulcan aim assistance" },
		{ id = "JadeReach", info = "Jade reach extension" },
	},
	Legit = {
		{ id = "FOV", info = "Field of view modifier" },
		{ id = "Crosshair", info = "Custom crosshair" },
		{ id = "Interface", info = "HUD customization" },
	},
}

local manifest = loadManifestSource()
if manifest then
	seedStockFromManifest(manifest)
else
	for shelf, list in pairs(fallback) do
		stock[shelf] = list
	end
end

local moduleIndex = {}
local favorites = {}
local rowStars = {}
local binds = {}
local binding = nil

local function rebuildModuleIndex()
	table.clear(moduleIndex)
	for shelf, list in pairs(stock) do
		for _, def in ipairs(list) do
			moduleIndex[def.id] = { def = def, shelf = shelf }
		end
	end
end

rebuildModuleIndex()

local knobs = {
	AutoClicker = {
		{ t = "toggle", label = "Hold to click", on = true },
		{ t = "toggle", label = "Trigger mode" },
		{ t = "toggle", label = "Break blocks", on = true },
		{ t = "range",  label = "Break blocks delay", lo = 0, hi = 10, min = 0, max = 100, step = 1 },
		{ t = "toggle", label = "Break blocks whitelist" },
		{ t = "range",  label = "CPS", lo = 13.7, hi = 17.2, min = 0, max = 30, step = 0.1 },
		{ t = "drop",   label = "Randomization", pick = "Extra", opts = { "None", "Low", "Normal", "Extra" } },
		{ t = "toggle", label = "Jitter" },
		{ t = "toggle", label = "Limit items" },
	},
	Reach = {
		{ t = "range",  label = "Range", lo = 3.05, hi = 3.1, min = 3, max = 5, step = 0.05 },
		{ t = "range",  label = "Chance", lo = 100, hi = 100, min = 0, max = 100, step = 1 },
		{ t = "toggle", label = "Advanced", on = true },
		{ t = "toggle", label = "Vertical check", on = true },
		{ t = "toggle", label = "Only while holding" },
		{ t = "drop",   label = "Mode", pick = "Legit", opts = { "Legit", "Normal", "Rage" } },
	},
	Velocity = {
		{ t = "range",  label = "Chance", lo = 50, hi = 50, min = 0, max = 100, step = 1 },
		{ t = "range",  label = "Horizontal", lo = 90, hi = 90, min = 0, max = 100, step = 1 },
		{ t = "range",  label = "Vertical", lo = 100, hi = 100, min = 0, max = 100, step = 1 },
		{ t = "range",  label = "Ticks", lo = 1, hi = 1, min = 0, max = 20, step = 1 },
		{ t = "toggle", label = "Only while holding" },
		{ t = "toggle", label = "Jump reset" },
	},
	Scaffold = {
		{ t = "drop",   label = "Mode", pick = "Legit", opts = { "Legit", "Normal", "Telly" } },
		{ t = "range",  label = "Pitch", lo = 50, hi = 50, min = 0, max = 90, step = 1 },
		{ t = "toggle", label = "Tower", on = true },
		{ t = "toggle", label = "Sprint" },
		{ t = "toggle", label = "Safe walk" },
	},
	ESP = {
		{ t = "drop",   label = "Style", pick = "3D", opts = { "Box", "3D", "Corners", "Chams" } },
		{ t = "toggle", label = "Invisibles", on = true },
		{ t = "toggle", label = "Hide bots", on = true },
		{ t = "toggle", label = "Tracers" },
		{ t = "range",  label = "Range", lo = 0, hi = 300, min = 0, max = 500, step = 5 },
	},
}

local fallbackKnobs = {
	{ t = "toggle", label = "Enabled", on = true },
}

local playerFriends = {}
local useFriends = true
local useAlias = true
local profileNames = { "default" }
local activeProfile = "default"

local searchBar = pane(win, UDim2.fromOffset(MAIN_W, 40), UDim2.fromOffset(MAIN_X, BODY_Y), hue.slab)
searchBar.ZIndex = 3
round(searchBar, 7)
edge(searchBar, hue.line)

local searchIco = Instance.new("ImageLabel")
searchIco.Size = UDim2.fromOffset(16, 16)
searchIco.Position = UDim2.fromOffset(16, 12)
searchIco.BackgroundTransparency = 1
searchIco.Image = SEARCH_ICON
searchIco.ImageColor3 = hue.dust
searchIco.ScaleType = Enum.ScaleType.Fit
searchIco.ZIndex = 4
searchIco.Parent = searchBar

local field = Instance.new("TextBox")
field.Size = UDim2.new(1, -88, 1, 0)
field.Position = UDim2.fromOffset(42, 0)
field.BackgroundTransparency = 1
field.Text = ""
field.PlaceholderText = "Search modules..."
field.PlaceholderColor3 = hue.dust
field.TextColor3 = hue.white
field.TextSize = 15
field.Font = Enum.Font.GothamMedium
field.TextXAlignment = Enum.TextXAlignment.Left
field.ClearTextOnFocus = false
field.TextEditable = true
field.Parent = searchBar

local nib = words(searchBar, "\u{270E}", 20, hue.dust)
nib.Position = UDim2.new(1, -40, 0, 0)
nib.Size = UDim2.fromOffset(25, 49)
nib.TextXAlignment = Enum.TextXAlignment.Center

local modBox = Instance.new("ScrollingFrame")
modBox.Size = UDim2.fromOffset(MAIN_W, BODY_H - 54)
modBox.Position = UDim2.fromOffset(MAIN_X, BODY_Y + 54)
modBox.BackgroundTransparency = 1
modBox.BorderSizePixel = 0
modBox.ScrollBarThickness = 5
modBox.ScrollBarImageColor3 = Color3.fromRGB(62, 62, 68)
modBox.CanvasSize = UDim2.new()
modBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
modBox.ScrollingDirection = Enum.ScrollingDirection.Y
modBox.ZIndex = 2
modBox.Parent = win

local modFlow = Instance.new("UIListLayout")
modFlow.Padding = UDim.new(0, MOD_SPACE)
modFlow.SortOrder = Enum.SortOrder.LayoutOrder
modFlow.Parent = modBox

local friendsPanel = pane(win, UDim2.fromOffset(W - 46, BODY_H), UDim2.fromOffset(23, BODY_Y + 38), hue.shell)
friendsPanel.Visible = false
friendsPanel.ZIndex = 3

local friendsHead = words(friendsPanel, "Friends", 18, hue.white, Enum.Font.GothamBold)
friendsHead.Size = UDim2.fromOffset(200, 28)

local friendsBox = Instance.new("ScrollingFrame")
friendsBox.Size = UDim2.new(1, 0, 1, -80)
friendsBox.Position = UDim2.fromOffset(0, 38)
friendsBox.BackgroundTransparency = 1
friendsBox.BorderSizePixel = 0
friendsBox.ScrollBarThickness = 5
friendsBox.CanvasSize = UDim2.new()
friendsBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
friendsBox.Parent = friendsPanel

local friendsFlow = Instance.new("UIListLayout")
friendsFlow.Padding = UDim.new(0, 6)
friendsFlow.SortOrder = Enum.SortOrder.LayoutOrder
friendsFlow.Parent = friendsBox

local profilesPanel = pane(win, UDim2.fromOffset(W - 46, BODY_H), UDim2.fromOffset(23, BODY_Y + 38), hue.shell)
profilesPanel.Visible = false
profilesPanel.ZIndex = 3

local profilesHead = words(profilesPanel, "Profiles", 18, hue.white, Enum.Font.GothamBold)
profilesHead.Size = UDim2.fromOffset(200, 28)

local profileField = Instance.new("TextBox")
profileField.Size = UDim2.new(1, -120, 0, 32)
profileField.Position = UDim2.fromOffset(0, 38)
profileField.BackgroundColor3 = hue.slab
profileField.Text = ""
profileField.PlaceholderText = "Profile name..."
profileField.PlaceholderColor3 = hue.dust
profileField.TextColor3 = hue.white
profileField.TextSize = 14
profileField.Font = Enum.Font.GothamMedium
profileField.ClearTextOnFocus = false
profileField.Parent = profilesPanel
round(profileField, 6)

local profileAdd = tap(profilesPanel, UDim2.fromOffset(100, 32), UDim2.new(1, -100, 0, 38))
profileAdd.BackgroundColor3 = hue.accent
round(profileAdd, 6)
local profileAddTxt = words(profileAdd, "Add", 14, hue.onNub, Enum.Font.GothamBold)
profileAddTxt.Size = UDim2.fromScale(1, 1)
profileAddTxt.TextXAlignment = Enum.TextXAlignment.Center

local profilesBox = Instance.new("ScrollingFrame")
profilesBox.Size = UDim2.new(1, 0, 1, -84)
profilesBox.Position = UDim2.fromOffset(0, 78)
profilesBox.BackgroundTransparency = 1
profilesBox.BorderSizePixel = 0
profilesBox.ScrollBarThickness = 5
profilesBox.CanvasSize = UDim2.new()
profilesBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
profilesBox.Parent = profilesPanel

local profilesFlow = Instance.new("UIListLayout")
profilesFlow.Padding = UDim.new(0, 6)
profilesFlow.SortOrder = Enum.SortOrder.LayoutOrder
profilesFlow.Parent = profilesBox

local panelLayer = Instance.new("Frame")
panelLayer.Name = "panels"
panelLayer.Size = UDim2.fromScale(1, 1)
panelLayer.BackgroundTransparency = 1
panelLayer.BorderSizePixel = 0
panelLayer.ZIndex = 50
panelLayer.Parent = win

local dock = pane(panelLayer, UDim2.fromOffset(PANEL_W, PANEL_H), UDim2.fromOffset(W - PANEL_W, PANEL_TOP), hue.sheet)
dock.Visible = false
dock.ZIndex = 50
edge(dock, hue.line, 1)
pane(dock, UDim2.fromOffset(1, PANEL_H), UDim2.new(), hue.line)

local dockGear = Instance.new("ImageLabel")
dockGear.Size = UDim2.fromOffset(16, 16)
dockGear.Position = UDim2.fromOffset(14, 19)
dockGear.BackgroundTransparency = 1
dockGear.Image = "rbxassetid://14368318994"
dockGear.ImageColor3 = hue.grey
dockGear.ScaleType = Enum.ScaleType.Fit
dockGear.ZIndex = 4
dockGear.Parent = dock

local dockName = words(dock, "", 18, hue.white, Enum.Font.GothamBold)
dockName.Position = UDim2.fromOffset(40, 19)
dockName.Size = UDim2.fromOffset(200, 16)
dockName.ZIndex = 4

local dockStar = tap(dock, UDim2.fromOffset(20, 20), UDim2.fromOffset(250, 17))
dockStar.ZIndex = 4
local dockStarIco = Instance.new("ImageLabel")
dockStarIco.Size = UDim2.fromScale(1, 1)
dockStarIco.BackgroundTransparency = 1
dockStarIco.Image = STAR_ICON
dockStarIco.ImageColor3 = hue.dust
dockStarIco.ScaleType = Enum.ScaleType.Fit
dockStarIco.ZIndex = 4
dockStarIco.Parent = dockStar

local dockPill = tap(dock, UDim2.fromOffset(36, 16), UDim2.new(1, -64, 0, 19))
dockPill.BackgroundTransparency = 0
dockPill.BackgroundColor3 = hue.offBar
dockPill.ZIndex = 4
round(dockPill, 4)
local dockPillTxt = words(dockPill, "OFF", 10, hue.grey, Enum.Font.GothamBold)
dockPillTxt.Size = UDim2.fromScale(1, 1)
dockPillTxt.TextXAlignment = Enum.TextXAlignment.Center
dockPillTxt.ZIndex = 5

local dockBox = Instance.new("ScrollingFrame")
dockBox.Size = UDim2.new(1, 0, 1, -52)
dockBox.Position = UDim2.fromOffset(0, 52)
dockBox.BackgroundTransparency = 1
dockBox.BorderSizePixel = 0
dockBox.ScrollBarThickness = 7
dockBox.ScrollBarImageColor3 = Color3.fromRGB(96, 96, 104)
dockBox.ScrollBarImageTransparency = 0
dockBox.ScrollingEnabled = true
dockBox.Active = true
dockBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
dockBox.CanvasSize = UDim2.new()
dockBox.ScrollingDirection = Enum.ScrollingDirection.Y
dockBox.ZIndex = 11
dockBox.Parent = dock

local dockFlow = Instance.new("UIListLayout")
dockFlow.Padding = UDim.new(0, 0)
dockFlow.SortOrder = Enum.SortOrder.LayoutOrder
dockFlow.Parent = dockBox

local dockPad = Instance.new("UIPadding")
dockPad.PaddingLeft = UDim.new(0, 19)
dockPad.PaddingRight = UDim.new(0, 24)
dockPad.PaddingTop = UDim.new(0, 4)
dockPad.PaddingBottom = UDim.new(0, 16)
dockPad.Parent = dockBox

local dockStarIco

local flags = {}
local cards = {}
local bindChips = {}
local dockOn = nil
local panelMode = nil
local dockConns = {}
local board
local knobState = {}
local rows = {}
local shelfPick = "Combat"
local cfg
local badgeDock
local fillList
local rebuildModuleList
local runSearch

local function syncSetting(moduleId, key, value)
	if not featureHost or not moduleId or not key then return end
	local plugin = featureHost.plugins[moduleId]
	if plugin then
		plugin.state[key] = value
	end
end

local settingLabels = {
	value = "Speed",
	vertical = "Vertical",
	wallCheck = "Wall check",
	autoJump = "Auto jump",
	alwaysJump = "Always jump",
	popBalloons = "Pop balloons",
	tpDown = "TP down",
	mode = "Mode",
	range = "Range",
	chance = "Chance",
	players = "Players",
	npcs = "NPCs",
}

local function labelFor(id)
	return settingLabels[id] or (id:sub(1, 1):upper() .. id:sub(2))
end

local function buildKnobsFromPlugin(plugin)
	local out = {}
	for i, def in ipairs(plugin.settings or {}) do
		local val = plugin.state and plugin.state[def.id]
		if val == nil then val = def.default end
		if def.kind == "toggle" then
			out[i] = { t = "toggle", label = labelFor(def.id), on = val == true, key = def.id }
		elseif def.kind == "range" then
			local n = val or def.min or 0
			out[i] = { t = "range", label = labelFor(def.id), lo = n, hi = n, min = def.min, max = def.max, step = def.step or 0.1, key = def.id }
		elseif def.kind == "drop" then
			out[i] = { t = "drop", label = labelFor(def.id), pick = val or def.default, opts = def.options, key = def.id }
		end
	end
	return out
end

local function knobsFor(name)
	if featureHost and featureHost.plugins[name] then
		local plugin = featureHost.plugins[name]
		if plugin.settings and #plugin.settings > 0 then
			return buildKnobsFromPlugin(plugin)
		end
	end
	if not knobState[name] then
		local src = knobs[name] or fallbackKnobs
		local out = {}
		for i, d in ipairs(src) do
			local c = {}
			for k, v in pairs(d) do c[k] = v end
			out[i] = c
		end
		knobState[name] = out
	end
	return knobState[name]
end

local function keep(conn)
	dockConns[#dockConns + 1] = conn
end

local function bindTag(code)
	if typeof(code) == "string" then
		if #code == 1 then return code:upper() end
		return code:gsub("Enum.KeyCode.", ""):gsub("Left", ""):gsub("Right", "")
	end
	local n = code.Name
	if #n == 1 then return n:upper() end
	return n:gsub("Left", ""):gsub("Right", "")
end

local function seedBinds()
	for id, m in pairs(moduleIndex) do
		if m.def.key and not binds[id] then
			local ok, code = pcall(function() return Enum.KeyCode[m.def.key] end)
			if ok and code then binds[id] = code end
		end
	end
end

local function shelfList(shelf)
	if shelf ~= "Favorites" then
		return stock[shelf] or {}
	end
	local out = {}
	for id in pairs(favorites) do
		local m = moduleIndex[id]
		if m then out[#out + 1] = m.def end
	end
	table.sort(out, function(a, b) return a.id < b.id end)
	return out
end

local function refreshCatCounts()
	for shelf, row in pairs(rows) do
		if row.tally then
			local n = 0
			if shelf == "Favorites" then
				for _ in pairs(favorites) do n += 1 end
			else
				for _, def in ipairs(stock[shelf] or {}) do
					if flags[def.id] then n += 1 end
				end
			end
			row.tally.Text = tostring(n)
			row.tally.Visible = cfg and cfg.count and n > 0
		end
	end
end

local function paintStar(id)
	local lit = favorites[id] == true
	local col = lit and hue.amber or hue.dust
	if dockStarIco then dockStarIco.ImageColor3 = col end
	local rs = rowStars[id]
	if rs then rs.ImageColor3 = col end
end

local function toggleModule(id)
	flags[id] = not flags[id]
	local state = flags[id]
	for _, c in ipairs(cards) do
		if c.id == id then
			c.apply(state)
			break
		end
	end
	refreshCatCounts()
	if dockOn == id and badgeDock then badgeDock(state) end
	if protonApi.onToggle then protonApi.onToggle(id, state) end
end

local function toggleFavorite(id)
	if favorites[id] then
		favorites[id] = nil
	else
		favorites[id] = true
	end
	paintStar(id)
	refreshCatCounts()
	if shelfPick == "Favorites" then fillList("Favorites") end
end

local function setBindLabel(id, code)
	local chip = bindChips[id]
	if not chip then return end
	chip.Text = code and bindTag(code) or (binding == id and "..." or "-")
end

local function startBind(id)
	binding = id
	setBindLabel(id, nil)
end

local function applyBind(id, code)
	binds[id] = code
	setBindLabel(id, code)
	binding = nil
end

seedBinds()

local function fmt(v, step)
	if step < 1 then return string.format("%.1f", v) end
	return tostring(math.floor(v + 0.5))
end

local function knobToggle(slot, def, order)
	local row = tap(dockBox, UDim2.new(1, 0, 0, 42), UDim2.new())
	row.LayoutOrder = order
	row.ZIndex = 5

	local lbl = words(row, def.label, 17, slot.on and hue.white or hue.grey)
	lbl.Position = UDim2.fromOffset(19, 0)
	lbl.Size = UDim2.fromOffset(240, 42)
	lbl.ZIndex = 5

	local sw = tap(row, UDim2.fromOffset(36, 18), UDim2.new(1, -64, 0, 12))
	sw.BackgroundTransparency = 0
	sw.BackgroundColor3 = slot.on and hue.white or hue.offBar
	sw.ClipsDescendants = true
	round(sw, 9)

	local nub = pane(sw, UDim2.fromOffset(14, 14), UDim2.fromOffset(slot.on and 16 or 2, 2), slot.on and hue.onNub or hue.offNub)
	nub.ZIndex = 2
	round(nub, 7)

	sw.MouseButton1Click:Connect(function()
		slot.on = not slot.on
		local ti = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(sw, ti, { BackgroundColor3 = slot.on and hue.white or hue.offBar }):Play()
		TweenService:Create(nub, ti, {
			Position = UDim2.fromOffset(slot.on and 20 or 2, 2),
			BackgroundColor3 = slot.on and hue.onNub or hue.offNub,
		}):Play()
		lbl.TextColor3 = slot.on and hue.white or hue.grey
		if slot.key and slot.module then syncSetting(slot.module, slot.key, slot.on) end
	end)
end

local function knobRange(slot, def, order)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 72)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.ZIndex = 5
	row.Parent = dockBox

	local lbl = words(row, def.label, 17, hue.white)
	lbl.Position = UDim2.fromOffset(19, 10)
	lbl.Size = UDim2.fromOffset(200, 24)
	lbl.ZIndex = 5

	local loTxt = words(row, "", 15, hue.grey)
	loTxt.Position = UDim2.fromOffset(210, 10)
	loTxt.Size = UDim2.fromOffset(60, 24)
	loTxt.TextXAlignment = Enum.TextXAlignment.Right
	loTxt.ZIndex = 5

	local hiTxt = words(row, "", 15, hue.grey)
	hiTxt.Position = UDim2.fromOffset(256, 10)
	hiTxt.Size = UDim2.fromOffset(60, 24)
	hiTxt.TextXAlignment = Enum.TextXAlignment.Right
	hiTxt.ZIndex = 5

	local TRACK_X, TRACK_W = 19, 250
	local rail = pane(row, UDim2.fromOffset(TRACK_W, 3), UDim2.fromOffset(TRACK_X, 51), hue.rail)
	rail.ZIndex = 5
	round(rail, 2)

	local span = pane(row, UDim2.fromOffset(0, 3), UDim2.fromOffset(TRACK_X, 51), hue.accent)
	span.ZIndex = 6
	round(span, 2)

	local loGrip = words(row, "\u{25B8}", 15, hue.accent)
	loGrip.Size = UDim2.fromOffset(14, 20)
	loGrip.TextXAlignment = Enum.TextXAlignment.Center
	loGrip.ZIndex = 7

	local hiGrip = words(row, "\u{25C2}", 15, hue.accent)
	hiGrip.Size = UDim2.fromOffset(14, 20)
	hiGrip.TextXAlignment = Enum.TextXAlignment.Center
	hiGrip.ZIndex = 7

	local function refresh()
		local range = def.max - def.min
		local a = (slot.lo - def.min) / range
		local b = (slot.hi - def.min) / range
		span.Position = UDim2.fromOffset(TRACK_X + a * TRACK_W, 51)
		span.Size = UDim2.fromOffset((b - a) * TRACK_W, 3)
		loGrip.Position = UDim2.fromOffset(TRACK_X + a * TRACK_W - 11, 43)
		hiGrip.Position = UDim2.fromOffset(TRACK_X + b * TRACK_W - 3, 43)
		loTxt.Text = fmt(slot.lo, def.step)
		hiTxt.Text = fmt(slot.hi, def.step)
	end

	local function snap(v)
		local n = math.floor(v / def.step + 0.5) * def.step
		return math.clamp(n, def.min, def.max)
	end

	local function grab(which)
		local zone = tap(row, UDim2.fromOffset(26, 26), UDim2.new())
		zone.ZIndex = 8
		local sync = which == "lo" and loGrip or hiGrip
		sync:GetPropertyChangedSignal("Position"):Connect(function()
			zone.Position = UDim2.fromOffset(sync.Position.X.Offset - 6, 40)
		end)

		local live = false
		zone.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then live = true end
		end)
		keep(UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				live = false
				if slot.key and slot.module then
					syncSetting(slot.module, slot.key, slot.lo)
				end
			end
		end))
		keep(UserInputService.InputChanged:Connect(function(i)
			if not live or i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
			if not rail.Parent then return end
			local origin = rail.AbsolutePosition.X
			local wide = rail.AbsoluteSize.X
			local pct = math.clamp((i.Position.X - origin) / wide, 0, 1)
			local v = snap(def.min + pct * (def.max - def.min))
			if which == "lo" then
				slot.lo = math.min(v, slot.hi)
			else
				slot.hi = math.max(v, slot.lo)
			end
			refresh()
		end))
	end

	grab("lo")
	grab("hi")
	refresh()
end

local function knobDrop(slot, def, order)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 46)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.ZIndex = 5
	row.Parent = dockBox

	local box = tap(row, UDim2.fromOffset(297, 30), UDim2.fromOffset(19, 8))
	box.BackgroundTransparency = 0
	box.BackgroundColor3 = hue.well
	box.ZIndex = 5
	round(box, 7)
	edge(box, hue.wellRim, 1.2)

	local cap = words(box, def.label .. " - " .. slot.pick, 15, hue.wellTxt)
	cap.Position = UDim2.fromOffset(13, 0)
	cap.Size = UDim2.fromOffset(240, 30)
	cap.ZIndex = 6

	local arrow = words(box, "\u{2304}", 17, hue.grey)
	arrow.Position = UDim2.new(1, -26, 0, -4)
	arrow.Size = UDim2.fromOffset(18, 30)
	arrow.TextXAlignment = Enum.TextXAlignment.Center
	arrow.ZIndex = 6

	local sheet = pane(dock, UDim2.fromOffset(297, #def.opts * 30 + 8), UDim2.new(), hue.well)
	sheet.Visible = false
	sheet.ZIndex = 20
	round(sheet, 7)
	edge(sheet, hue.wellRim, 1.2)

	local sheetFlow = Instance.new("UIListLayout")
	sheetFlow.Padding = UDim.new(0, 0)
	sheetFlow.SortOrder = Enum.SortOrder.LayoutOrder
	sheetFlow.Parent = sheet

	local sheetPad = Instance.new("UIPadding")
	sheetPad.PaddingTop = UDim.new(0, 4)
	sheetPad.Parent = sheet

	for oi, opt in ipairs(def.opts) do
		local pickBtn = tap(sheet, UDim2.new(1, 0, 0, 30), UDim2.new())
		pickBtn.LayoutOrder = oi
		pickBtn.ZIndex = 21

		local ot = words(pickBtn, opt, 15, opt == slot.pick and hue.accent or hue.wellTxt)
		ot.Position = UDim2.fromOffset(13, 0)
		ot.Size = UDim2.fromScale(1, 1)
		ot.ZIndex = 21

		pickBtn.MouseEnter:Connect(function()
			pickBtn.BackgroundTransparency = 0.88
			pickBtn.BackgroundColor3 = hue.white
		end)
		pickBtn.MouseLeave:Connect(function() pickBtn.BackgroundTransparency = 1 end)

		pickBtn.MouseButton1Click:Connect(function()
			slot.pick = opt
			cap.Text = def.label .. " - " .. opt
			sheet.Visible = false
			for _, sib in ipairs(sheet:GetChildren()) do
				local lab = sib:FindFirstChildWhichIsA("TextLabel")
				if lab then lab.TextColor3 = lab.Text == opt and hue.accent or hue.wellTxt end
			end
			if slot.key and slot.module then syncSetting(slot.module, slot.key, opt) end
		end)
	end

	box.MouseButton1Click:Connect(function()
		if sheet.Visible then
			sheet.Visible = false
			return
		end
		local y = box.AbsolutePosition.Y - dock.AbsolutePosition.Y
		sheet.Position = UDim2.fromOffset(19, y / winScale.Scale + 34)
		sheet.Visible = true
	end)
end

local function setPanelLayout(open)
	if open then
		searchBar.Size = UDim2.fromOffset(NARROW_W, 40)
		modBox.Size = UDim2.fromOffset(NARROW_W, BODY_H - 54)
	else
		searchBar.Size = UDim2.fromOffset(MAIN_W, 40)
		modBox.Size = UDim2.fromOffset(MAIN_W, BODY_H - 54)
	end
end

badgeDock = function(live)
	dockPill.BackgroundColor3 = live and hue.white or hue.offBar
	dockPillTxt.Text = live and "ON" or "OFF"
	dockPillTxt.TextColor3 = live and hue.onNub or hue.grey
end

local function loadDock(name)
	for _, c in ipairs(dockConns) do c:Disconnect() end
	table.clear(dockConns)

	for _, ch in ipairs(dockBox:GetChildren()) do
		if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then ch:Destroy() end
	end
	for _, ch in ipairs(dock:GetChildren()) do
		if ch:IsA("Frame") and ch.ZIndex == 20 then ch:Destroy() end
	end

	dockName.Text = name
	badgeDock(flags[name] == true)
	paintStar(name)

	for i, slot in ipairs(knobsFor(name)) do
		slot.module = name
		if slot.t == "toggle" then
			knobToggle(slot, slot, i)
		elseif slot.t == "range" then
			knobRange(slot, slot, i)
		else
			knobDrop(slot, slot, i)
		end
	end
	dockBox.CanvasPosition = Vector2.new()
end

local function setDim(active)
	for _, c in ipairs(cards) do
		local off = active ~= nil and c.needle ~= active:lower()
		c.frame.BackgroundTransparency = off and 0.45 or 0
		for _, d in ipairs(c.frame:GetDescendants()) do
			if d:IsA("TextLabel") then
				d.TextTransparency = off and 0.55 or 0
			elseif d.Name == "knob" then
			elseif d:IsA("TextButton") and d.ClipsDescendants then
			elseif d:IsA("Frame") or d:IsA("TextButton") then
				if d.BackgroundTransparency < 1 then
					d.BackgroundTransparency = off and 0.5 or 0
				end
			end
		end
	end
end

local function openGuiPanel(show)
	if show and panelMode == "gui" then
		panelMode = nil
		board.Visible = false
		setPanelLayout(false)
		return
	end
	if show then
		panelMode = "gui"
		dockOn = nil
		dock.Visible = false
		board.Visible = true
		setPanelLayout(true)
		setDim(nil)
	else
		panelMode = nil
		board.Visible = false
		setPanelLayout(false)
	end
end

local function openDock(name)
	if dockOn == name and panelMode == "dock" then
		dockOn = nil
		panelMode = nil
		dock.Visible = false
		setPanelLayout(false)
		setDim(nil)
		return
	end
	panelMode = "dock"
	dockOn = name
	board.Visible = false
	dock.Visible = true
	setPanelLayout(true)
	loadDock(name)
	setDim(name)
end

local function refreshFriends()
	for _, ch in ipairs(friendsBox:GetChildren()) do
		if not ch:IsA("UIListLayout") then ch:Destroy() end
	end
	local order = 2
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == me then continue end
		order += 1
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 36)
		row.BackgroundColor3 = hue.slab
		row.BorderSizePixel = 0
		row.LayoutOrder = order
		row.Parent = friendsBox
		round(row, 6)
		local dot = pane(row, UDim2.fromOffset(14, 14), UDim2.fromOffset(14, 11), playerFriends[plr.UserId] and hue.amber or hue.accent)
		round(dot, 7)
		local nm = words(row, plr.DisplayName, 14, hue.white)
		nm.Position = UDim2.fromOffset(44, 0)
		nm.Size = UDim2.new(1, -54, 1, 0)
		local hit = tap(row, UDim2.fromScale(1, 1), UDim2.new())
		hit.MouseButton1Click:Connect(function()
			if playerFriends[plr.UserId] then
				playerFriends[plr.UserId] = nil
				dot.BackgroundColor3 = hue.accent
			else
				playerFriends[plr.UserId] = plr.Name
				dot.BackgroundColor3 = hue.amber
			end
		end)
	end
end

local function refreshProfiles()
	for _, ch in ipairs(profilesBox:GetChildren()) do
		if not ch:IsA("UIListLayout") then ch:Destroy() end
	end
	for i, name in ipairs(profileNames) do
		local row = tap(profilesBox, UDim2.new(1, -8, 0, 36), UDim2.new())
		row.LayoutOrder = i
		row.BackgroundTransparency = 0
		row.BackgroundColor3 = name == activeProfile and hue.slabLit or hue.slab
		round(row, 6)
		local lbl = words(row, name, 14, name == activeProfile and hue.white or hue.grey)
		lbl.Size = UDim2.new(1, -16, 1, 0)
		lbl.Position = UDim2.fromOffset(14, 0)
		row.MouseButton1Click:Connect(function()
			activeProfile = name
			refreshProfiles()
		end)
	end
end

profileAdd.MouseButton1Click:Connect(function()
	local name = profileField.Text:match("^%s*(.-)%s*$") or ""
	if name == "" or name:lower() == "default" then return end
	for _, n in ipairs(profileNames) do
		if n:lower() == name:lower() then return end
	end
	profileNames[#profileNames + 1] = name
	profileField.Text = ""
	refreshProfiles()
end)

local function setTab(nm)
	tabPick = nm
	for other, p in pairs(tabMap) do
		p.b.TextColor3 = other == nm and hue.white or hue.dust
		p.ul.Visible = other == nm
	end
	local isModules = nm == "Modules"
	local isFriends = nm == "Friends"
	local isProfiles = nm == "Profiles"
	heading.Visible = isModules
	catBox.Visible = isModules
	searchBar.Visible = isModules
	modBox.Visible = isModules
	friendsPanel.Visible = isFriends
	profilesPanel.Visible = isProfiles
	heading.Text = isModules and "Modules" or nm
	if isFriends then refreshFriends() end
	if isProfiles then refreshProfiles() end
	if not isModules then
		dockOn = nil
		panelMode = nil
		dock.Visible = false
		board.Visible = false
		setPanelLayout(false)
		setDim(nil)
	end
end

for nm, o in pairs(tabMap) do
	o.b.MouseButton1Click:Connect(function()
		setTab(nm)
	end)
end

local function drawCard(def, order)
	local key = def.id
	if flags[key] == nil then flags[key] = false end
	local on = flags[key]

	local card = Instance.new("Frame")
	card.Name = key
	card.Size = UDim2.new(1, -12, 0, MOD_H)
	card.BackgroundColor3 = on and hue.slabLit or hue.slab
	card.BorderSizePixel = 0
	card.LayoutOrder = order
	card.Parent = modBox
	round(card, 7)

	local spine = pane(card, UDim2.fromOffset(4, 32), UDim2.fromOffset(0, 9), hue.white)
	spine.Visible = on
	round(spine, 2)

	local title = words(card, key, 15, hue.label, Enum.Font.GothamMedium)
	title.Position = UDim2.fromOffset(20, 0)
	title.Size = UDim2.fromOffset(140, MOD_H)
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.ZIndex = 2

	local sub = words(card, def.info, 13, hue.grey)
	sub.Position = UDim2.fromOffset(168, 0)
	sub.Size = UDim2.new(1, -318, 1, 0)
	sub.TextTruncate = Enum.TextTruncate.AtEnd
	sub.ZIndex = 2

	local starBtn = tap(card, UDim2.fromOffset(20, 20), UDim2.new(1, -146, 0, 15))
	starBtn.ZIndex = 4
	local starIco = Instance.new("ImageLabel")
	starIco.Size = UDim2.fromScale(1, 1)
	starIco.BackgroundTransparency = 1
	starIco.Image = STAR_ICON
	starIco.ImageColor3 = favorites[key] and hue.amber or hue.dust
	starIco.ScaleType = Enum.ScaleType.Fit
	starIco.ZIndex = 4
	starIco.Parent = starBtn
	rowStars[key] = starIco
	starBtn.MouseEnter:Connect(function()
		if not favorites[key] then starIco.ImageColor3 = hue.white end
	end)
	starBtn.MouseLeave:Connect(function()
		starIco.ImageColor3 = favorites[key] and hue.amber or hue.dust
	end)
	starBtn.MouseButton1Click:Connect(function()
		toggleFavorite(key)
	end)

	local kb = tap(card, UDim2.fromOffset(22, 20), UDim2.new(1, -118, 0, 15))
	kb.BackgroundTransparency = 0
	kb.BackgroundColor3 = hue.chip
	kb.ZIndex = 4
	round(kb, 4)
	local kt = words(kb, binds[key] and bindTag(binds[key]) or "-", 11, hue.grey, Enum.Font.GothamBold)
	kt.Size = UDim2.fromScale(1, 1)
	kt.TextXAlignment = Enum.TextXAlignment.Center
	bindChips[key] = kt
	kb.MouseButton1Click:Connect(function()
		startBind(key)
	end)

	local sw = Instance.new("TextButton")
	sw.Size = UDim2.fromOffset(40, 20)
	sw.Position = UDim2.new(1, -84, 0, 15)
	sw.BackgroundColor3 = on and hue.white or hue.offBar
	sw.BorderSizePixel = 0
	sw.Text = ""
	sw.AutoButtonColor = false
	sw.ZIndex = 4
	sw.ClipsDescendants = true
	sw.Parent = card
	round(sw, 10)

	local nub = pane(sw, UDim2.fromOffset(14, 14), UDim2.fromOffset(on and 23 or 3, 3), on and hue.onNub or hue.offNub)
	nub.Name = "knob"
	nub.ZIndex = 5
	round(nub, 7)

	local menu = tap(card, UDim2.fromOffset(30, MOD_H), UDim2.new(1, -32, 0, 0))
	menu.ZIndex = 6
	menu.Active = true
	local pips = {}
	for k = 0, 2 do
		local p = pane(menu, UDim2.fromOffset(3, 3), UDim2.fromOffset(12, 18 + k * 7), hue.dust)
		p.ZIndex = 6
		round(p, 2)
		pips[#pips + 1] = p
	end

	menu.MouseEnter:Connect(function()
		for _, p in ipairs(pips) do p.BackgroundColor3 = hue.white end
	end)
	menu.MouseLeave:Connect(function()
		for _, p in ipairs(pips) do p.BackgroundColor3 = hue.dust end
	end)
	menu.MouseButton1Click:Connect(function() openDock(key) end)

	local function apply(state)
		flags[key] = state
		local ti = TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(sw, ti, { BackgroundColor3 = state and hue.white or hue.offBar }):Play()
		TweenService:Create(nub, ti, {
			Position = UDim2.fromOffset(state and 23 or 3, 3),
			BackgroundColor3 = state and hue.onNub or hue.offNub,
		}):Play()
		TweenService:Create(card, ti, { BackgroundColor3 = state and hue.slabLit or hue.slab }):Play()
		spine.Visible = state
		if dockOn == key then badgeDock(state) end
	end

	local function flip()
		toggleModule(key)
	end

	sw.MouseButton1Click:Connect(flip)

	card.MouseEnter:Connect(function()
		if not flags[key] and dockOn == nil then
			TweenService:Create(card, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(31, 31, 35) }):Play()
		end
	end)
	card.MouseLeave:Connect(function()
		if not flags[key] and dockOn == nil then
			TweenService:Create(card, TweenInfo.new(0.1), { BackgroundColor3 = hue.slab }):Play()
		end
	end)

	cards[#cards + 1] = { frame = card, needle = key:lower(), id = key, flip = flip, apply = apply }
end

local function allModulesList()
	local out, seen = {}, {}
	for _, list in pairs(stock) do
		for _, def in ipairs(list) do
			if not seen[def.id] then
				seen[def.id] = true
				out[#out + 1] = def
			end
		end
	end
	table.sort(out, function(a, b) return a.id < b.id end)
	return out
end

rebuildModuleList = function(list)
	for _, c in ipairs(cards) do c.frame:Destroy() end
	table.clear(cards)
	table.clear(bindChips)
	for i, def in ipairs(list) do
		drawCard(def, i)
	end
	modBox.CanvasPosition = Vector2.new()
	if dockOn then setDim(dockOn) end
end

runSearch = function()
	local q = field.Text:lower():match("^%s*(.-)%s*$") or ""
	if q == "" then
		rebuildModuleList(shelfList(shelfPick))
		return
	end
	local hits = {}
	for _, def in ipairs(allModulesList()) do
		local hay = (def.id .. " " .. (def.info or "")):lower()
		if hay:find(q, 1, true) then
			hits[#hits + 1] = def
		end
	end
	rebuildModuleList(hits)
end

fillList = function(shelf)
	shelfPick = shelf
	local q = field.Text:lower():match("^%s*(.-)%s*$") or ""
	if q ~= "" then
		runSearch()
		return
	end
	rebuildModuleList(shelfList(shelf))
	refreshCatCounts()
end

for i, def in ipairs(shelves) do
	local sel = def.id == shelfPick

	local r = Instance.new("TextButton")
	r.Name = def.id
	r.Size = UDim2.new(1, -6, 0, CAT_H)
	r.BackgroundColor3 = hue.slabLit
	r.BackgroundTransparency = sel and 0 or 1
	r.BorderSizePixel = 0
	r.Text = ""
	r.AutoButtonColor = false
	r.LayoutOrder = i
	r.Parent = catBox
	round(r, 9)

	local ico = Instance.new("ImageLabel")
	ico.Size = UDim2.fromOffset(16, 16)
	ico.Position = UDim2.fromOffset(14, 12)
	ico.BackgroundTransparency = 1
	ico.Image = def.icon
	ico.ImageColor3 = def.tint or (sel and hue.white or hue.grey)
	ico.ScaleType = Enum.ScaleType.Fit
	ico.Parent = r

	local nm = words(r, def.id, 15, sel and hue.white or hue.grey)
	nm.Position = UDim2.fromOffset(42, 0)
	nm.Size = UDim2.fromOffset(130, CAT_H)

	local tally = words(r, "0", 14, hue.dust)
	tally.Position = UDim2.new(1, -55, 0, 0)
	tally.Size = UDim2.fromOffset(22, CAT_H)
	tally.TextXAlignment = Enum.TextXAlignment.Right
	tally.Visible = false

	local ch = words(r, "\u{203A}", 22, hue.dust)
	ch.Position = UDim2.new(1, -28, 0, 0)
	ch.Size = UDim2.fromOffset(18, CAT_H)
	ch.TextXAlignment = Enum.TextXAlignment.Center

	rows[def.id] = { r = r, nm = nm, ico = ico, tint = def.tint, tally = tally }

	r.MouseButton1Click:Connect(function()
		shelfPick = def.id
		for id, o in pairs(rows) do
			local hit = id == shelfPick
			TweenService:Create(o.r, TweenInfo.new(0.12), { BackgroundTransparency = hit and 0 or 1 }):Play()
			o.nm.TextColor3 = hit and hue.white or hue.grey
			if not o.tint then o.ico.ImageColor3 = hit and hue.white or hue.grey end
		end
		field.Text = ""
		fillList(shelfPick)
	end)

	r.MouseEnter:Connect(function()
		if shelfPick ~= def.id then r.BackgroundTransparency = 0.62 end
	end)
	r.MouseLeave:Connect(function()
		if shelfPick ~= def.id then r.BackgroundTransparency = 1 end
	end)
end

fillList(shelfPick)

field:GetPropertyChangedSignal("Text"):Connect(runSearch)
field.FocusLost:Connect(runSearch)

cfg = {
	blur = true,
	bindHint = true,
	tips = true,
	rainbow = 1,
	rgb = false,
	hue = 0.44,
	sat = 1,
	val = 1,
	style = "Central",
	count = true,
	scale = "Normal",
}

local function applyTheme()
	local h, s, v = cfg.hue or 0.44, cfg.sat or 1, cfg.val or 1
	if cfg.rgb then
		h = (tick() * (cfg.rainbow or 1) * 0.08) % 1
	end
	hue.accent = Color3.fromHSV(h, s, v)
	barFill.BackgroundColor3 = hue.accent
	loadLogo.ImageColor3 = Color3.fromHSV(h, s, v)
	profileAdd.BackgroundColor3 = hue.accent
end

local scaleMap = { Tiny = 0.45, Small = 0.58, Normal = 0.65, Large = 0.78, Huge = 0.92 }
winScale.Scale = scaleMap[cfg.scale]

local blurFx = Instance.new("BlurEffect")
blurFx.Size = 0
blurFx.Enabled = false
blurFx.Parent = Lighting

local function applyStyle()
	local half = (W * winScale.Scale) / 2
	if cfg.style == "Left" then
		win.Position = UDim2.new(0, half + 36, 0.5, 0)
	elseif cfg.style == "Right" then
		win.Position = UDim2.new(1, -half - 36, 0.5, 0)
	else
		win.Position = UDim2.fromScale(0.5, 0.5)
	end
end

local function applyBlur()
	local want = cfg.blur and win.Visible
	blurFx.Enabled = want
	TweenService:Create(blurFx, TweenInfo.new(0.2), { Size = want and 14 or 0 }):Play()
end

local function applyCount()
	refreshCatCounts()
end

local function buildSettingsPanel()
	board = pane(panelLayer, UDim2.fromOffset(PANEL_W, PANEL_H), UDim2.fromOffset(W - PANEL_W, PANEL_TOP), hue.sheet)
board.Name = "cfg"
board.Visible = false
board.ZIndex = 50
edge(board, hue.line, 1)
pane(board, UDim2.fromOffset(1, PANEL_H), UDim2.new(), hue.line)

local badge = pane(board, UDim2.fromOffset(20, 20), UDim2.fromOffset(20, 16), hue.chip)
round(badge, 10)
local badgeIco = Instance.new("ImageLabel")
badgeIco.Size = UDim2.fromScale(1, 1)
badgeIco.BackgroundTransparency = 1
badgeIco.Image = "rbxassetid://14368318994"
badgeIco.ImageColor3 = hue.grey
badgeIco.ScaleType = Enum.ScaleType.Fit
badgeIco.Parent = badge

local boardTitle = words(board, "GUI", 15, hue.white, Enum.Font.GothamBold)
boardTitle.Position = UDim2.fromOffset(50, 16)
boardTitle.Size = UDim2.fromOffset(200, 22)

local shut = tap(board, UDim2.fromOffset(20, 20), UDim2.new(1, -36, 0, 16))
local shutTxt = words(shut, "\u{00D7}", 18, hue.grey)
shutTxt.Size = UDim2.fromScale(1, 1)
shutTxt.TextXAlignment = Enum.TextXAlignment.Center
shut.MouseEnter:Connect(function() shutTxt.TextColor3 = hue.white end)
shut.MouseLeave:Connect(function() shutTxt.TextColor3 = hue.grey end)
shut.MouseButton1Click:Connect(function()
	board.Visible = false
	panelMode = nil
	setPanelLayout(false)
end)

local boardBox = Instance.new("ScrollingFrame")
boardBox.Size = UDim2.new(1, 0, 1, -52)
boardBox.Position = UDim2.fromOffset(0, 52)
boardBox.BackgroundTransparency = 1
boardBox.BorderSizePixel = 0
boardBox.ScrollBarThickness = 7
boardBox.ScrollBarImageColor3 = Color3.fromRGB(96, 96, 104)
boardBox.ScrollBarImageTransparency = 0
boardBox.ScrollingEnabled = true
boardBox.Active = true
boardBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
boardBox.CanvasSize = UDim2.new()
boardBox.ScrollingDirection = Enum.ScrollingDirection.Y
boardBox.ZIndex = 11
boardBox.Parent = board

local boardFlow = Instance.new("UIListLayout")
boardFlow.Padding = UDim.new(0, 0)
boardFlow.SortOrder = Enum.SortOrder.LayoutOrder
boardFlow.Parent = boardBox

local boardPad = Instance.new("UIPadding")
boardPad.PaddingLeft = UDim.new(0, 19)
boardPad.PaddingRight = UDim.new(0, 14)
boardPad.PaddingTop = UDim.new(0, 4)
boardPad.PaddingBottom = UDim.new(0, 16)
boardPad.Parent = boardBox

local tipLine = words(boardBox, "", 12, hue.tip)
tipLine.Size = UDim2.new(1, -38, 0, 20)
tipLine.Visible = false
tipLine.LayoutOrder = 99

local function cfgToggle(order, label, hint, get, set)
	local row = tap(boardBox, UDim2.new(1, 0, 0, 36), UDim2.new())
	row.LayoutOrder = order

	local lbl = words(row, label, 14, hue.white)
	lbl.Size = UDim2.new(1, -48, 1, 0)

	local sw = tap(row, UDim2.fromOffset(36, 18), UDim2.new(1, -36, 0, 9))
	sw.BackgroundTransparency = 0
	sw.BackgroundColor3 = get() and hue.white or hue.offBar
	sw.ClipsDescendants = true
	round(sw, 9)

	local nub = pane(sw, UDim2.fromOffset(14, 14), UDim2.fromOffset(get() and 19 or 3, 2), get() and hue.onNub or hue.offNub)
	round(nub, 7)

	local function repaint(v)
		local ti = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(sw, ti, { BackgroundColor3 = v and hue.white or hue.offBar }):Play()
		TweenService:Create(nub, ti, {
			Position = UDim2.fromOffset(v and 19 or 3, 2),
			BackgroundColor3 = v and hue.onNub or hue.offNub,
		}):Play()
	end

	sw.MouseButton1Click:Connect(function()
		set(not get())
		repaint(get())
	end)

	row.MouseEnter:Connect(function()
		if not cfg.tips then return end
		tipLine.Text = hint
		tipLine.Visible = true
	end)
	row.MouseLeave:Connect(function() tipLine.Visible = false end)
end

local function cfgDrop(order, label, opts, get, set)
	local wrap = Instance.new("Frame")
	wrap.Size = UDim2.new(1, 0, 0, 38)
	wrap.BackgroundTransparency = 1
	wrap.LayoutOrder = order
	wrap.Parent = boardBox

	local box = tap(wrap, UDim2.new(1, 0, 0, 32), UDim2.new())
	box.BackgroundTransparency = 0
	box.BackgroundColor3 = hue.well
	round(box, 7)
	edge(box, hue.wellRim, 1.2)

	local cap = words(box, label .. " - " .. get(), 14, hue.wellTxt)
	cap.Position = UDim2.fromOffset(14, 0)
	cap.Size = UDim2.new(1, -40, 1, 0)

	local arrow = words(box, "\u{2304}", 16, hue.grey)
	arrow.Position = UDim2.new(1, -28, 0, -5)
	arrow.Size = UDim2.fromOffset(18, 32)
	arrow.TextXAlignment = Enum.TextXAlignment.Center

	local sheet = pane(board, UDim2.new(1, -38, 0, #opts * 32 + 8), UDim2.new(), hue.well)
	sheet.Visible = false
	sheet.ZIndex = 20
	round(sheet, 7)
	edge(sheet, hue.wellRim, 1.2)

	local flow = Instance.new("UIListLayout")
	flow.SortOrder = Enum.SortOrder.LayoutOrder
	flow.Parent = sheet

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.Parent = sheet

	local marks = {}
	for oi, opt in ipairs(opts) do
		local b = tap(sheet, UDim2.new(1, 0, 0, 32), UDim2.new())
		b.LayoutOrder = oi

		local ot = words(b, opt, 14, opt == get() and hue.white or hue.wellTxt)
		ot.Position = UDim2.fromOffset(20, 0)
		ot.Size = UDim2.fromScale(1, 1)
		marks[opt] = ot

		b.MouseEnter:Connect(function()
			b.BackgroundTransparency = 0.9
			b.BackgroundColor3 = hue.white
		end)
		b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)

		b.MouseButton1Click:Connect(function()
			set(opt)
			cap.Text = label .. " - " .. opt
			sheet.Visible = false
			for name, lab in pairs(marks) do
				lab.TextColor3 = name == opt and hue.white or hue.wellTxt
			end
		end)
	end

	box.MouseButton1Click:Connect(function()
		if sheet.Visible then
			sheet.Visible = false
			return
		end
		local y = box.AbsolutePosition.Y - board.AbsolutePosition.Y
		sheet.Position = UDim2.fromOffset(19, y / winScale.Scale + 47)
		sheet.Size = UDim2.new(1, -38, 0, #opts * 32 + 8)
		sheet.Visible = true
	end)
end

cfgToggle(1, "Blur background", "Blur the background of the GUI",
	function() return cfg.blur end,
	function(v) cfg.blur = v; applyBlur() end)

cfgToggle(2, "RGB mode", "Cycle GUI accent colors",
	function() return cfg.rgb end,
	function(v) cfg.rgb = v; applyTheme() end)

cfgToggle(3, "GUI bind indicator", "Show the keybind hint under the GUI",
	function() return cfg.bindHint end,
	function(v) cfg.bindHint = v end)

cfgToggle(4, "Show tooltips", "Show a short description when hovering options",
	function() return cfg.tips end,
	function(v) cfg.tips = v; if not v then tipLine.Visible = false end end)

cfgToggle(5, "Use friends", "Friend list protection in combat modules",
	function() return useFriends end,
	function(v) useFriends = v end)

local themeWrap = Instance.new("Frame")
themeWrap.Size = UDim2.new(1, 0, 0, 52)
themeWrap.BackgroundTransparency = 1
themeWrap.LayoutOrder = 6
themeWrap.Parent = boardBox

local themeLbl = words(themeWrap, "GUI theme", 14, hue.grey)
themeLbl.Size = UDim2.new(1, -32, 0, 22)

local themeRail = pane(themeWrap, UDim2.new(1, 0, 0, 4), UDim2.fromOffset(0, 34), hue.rail)
round(themeRail, 2)

local themeFill = pane(themeRail, UDim2.fromScale(cfg.hue, 1), UDim2.new(), hue.accent)
round(themeFill, 2)

local themeNub = pane(themeWrap, UDim2.fromOffset(16, 16), UDim2.new(cfg.hue, -8, 0, 28), hue.white)
round(themeNub, 8)

do
	local live = false
	local zone = tap(themeWrap, UDim2.new(1, 0, 0, 24), UDim2.fromOffset(0, 26))
	zone.ZIndex = 2
	local function setThemePct(pct)
		pct = math.clamp(pct, 0, 1)
		cfg.hue = pct
		themeFill.Size = UDim2.fromScale(pct, 1)
		themeNub.Position = UDim2.new(pct, -8, 0, 28)
		applyTheme()
	end
	zone.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		live = true
		setThemePct((i.Position.X - themeRail.AbsolutePosition.X) / themeRail.AbsoluteSize.X)
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then live = false end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if not live or i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		setThemePct((i.Position.X - themeRail.AbsolutePosition.X) / themeRail.AbsoluteSize.X)
	end)
	setThemePct(cfg.hue)
end

local speedWrap = Instance.new("Frame")
speedWrap.Size = UDim2.new(1, 0, 0, 52)
speedWrap.BackgroundTransparency = 1
speedWrap.LayoutOrder = 7
speedWrap.Parent = boardBox

local speedLbl = words(speedWrap, "Rainbow speed", 14, hue.grey)
speedLbl.Size = UDim2.new(1, -32, 0, 22)

local destructBtn = tap(boardBox, UDim2.new(1, -38, 0, 40), UDim2.new())
destructBtn.LayoutOrder = 60
destructBtn.BackgroundTransparency = 0
destructBtn.BackgroundColor3 = Color3.fromRGB(190, 55, 55)
round(destructBtn, 6)
local destructTxt = words(destructBtn, "Self Destruct", 14, hue.white, Enum.Font.GothamBold)
destructTxt.Size = UDim2.fromScale(1, 1)
destructTxt.TextXAlignment = Enum.TextXAlignment.Center
destructBtn.MouseButton1Click:Connect(function()
	if protonApi.onSelfDestruct then protonApi.onSelfDestruct() end
	screen:Destroy()
end)

local speedVal = words(speedWrap, "1", 14, hue.white)
speedVal.Size = UDim2.fromOffset(32, 22)
speedVal.Position = UDim2.new(1, -32, 0, 0)
speedVal.TextXAlignment = Enum.TextXAlignment.Right

local speedRail = pane(speedWrap, UDim2.new(1, 0, 0, 4), UDim2.fromOffset(0, 34), hue.rail)
round(speedRail, 2)

local speedFill = pane(speedRail, UDim2.fromScale(0.1, 1), UDim2.new(), hue.white)
round(speedFill, 2)

local speedNub = pane(speedWrap, UDim2.fromOffset(16, 16), UDim2.fromOffset(0, 28), hue.white)
round(speedNub, 8)

do
	local live = false
	local zone = tap(speedWrap, UDim2.new(1, 0, 0, 24), UDim2.fromOffset(0, 26))
	zone.ZIndex = 2

	local function set(pct)
		pct = math.clamp(pct, 0, 1)
		cfg.rainbow = math.floor(pct * 10 + 0.5)
		local q = cfg.rainbow / 10
		speedFill.Size = UDim2.fromScale(q, 1)
		speedNub.Position = UDim2.new(q, -8, 0, 28)
		speedVal.Text = tostring(cfg.rainbow)
	end

	zone.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		live = true
		set((i.Position.X - speedRail.AbsolutePosition.X) / speedRail.AbsoluteSize.X)
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then live = false end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if not live or i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		set((i.Position.X - speedRail.AbsolutePosition.X) / speedRail.AbsoluteSize.X)
	end)

	set(0.1)
end

local baseApplyTheme = applyTheme
applyTheme = function()
	baseApplyTheme()
	if themeFill then themeFill.BackgroundColor3 = hue.accent end
	if speedFill then speedFill.BackgroundColor3 = hue.accent end
end

cfgDrop(8, "GUI style", { "Central", "Left", "Right" },
	function() return cfg.style end,
	function(v) cfg.style = v; applyStyle() end)

cfgToggle(9, "Show enabled count", "Show how many modules are on in each category",
	function() return cfg.count end,
	function(v) cfg.count = v; applyCount() end)

cfgDrop(10, "GUI Scale", { "Tiny", "Small", "Normal", "Large", "Huge" },
	function() return cfg.scale end,
	function(v)
		cfg.scale = v
		winScale.Scale = scaleMap[v]
		task.defer(applyStyle)
	end)
end

buildSettingsPanel()

gearBtn.MouseButton1Click:Connect(function()
	openGuiPanel(panelMode ~= "gui")
end)

gearBtn.MouseEnter:Connect(function() gearIco.ImageColor3 = hue.white end)
gearBtn.MouseLeave:Connect(function() gearIco.ImageColor3 = hue.grey end)

overlayBtn.MouseButton1Click:Connect(function()
	setOverlayOpen(not overlayPanelRef.Visible)
end)

overlayBtn.MouseEnter:Connect(function() overlayIco.ImageColor3 = hue.white end)
overlayBtn.MouseLeave:Connect(function() overlayIco.ImageColor3 = hue.grey end)

dockPill.MouseButton1Click:Connect(function()
	if not dockOn then return end
	for _, c in ipairs(cards) do
		if c.id == dockOn then
			c.flip()
			return
		end
	end
end)

dockStar.MouseButton1Click:Connect(function()
	if not dockOn then return end
	toggleFavorite(dockOn)
end)

applyCount()
applyBlur()
applyStyle()
applyTheme()
refreshCatCounts()

RunService.RenderStepped:Connect(function()
	if cfg.rgb then applyTheme() end
end)

UserInputService.InputBegan:Connect(function(i, gameProcessed)
	if i.UserInputType ~= Enum.UserInputType.Keyboard then return end

	if binding then
		if i.KeyCode == Enum.KeyCode.Escape then
			local id = binding
			binding = nil
			setBindLabel(id, binds[id])
			return
		end
		if i.KeyCode == Enum.KeyCode.Backspace then
			binds[binding] = nil
			local id = binding
			binding = nil
			setBindLabel(id, nil)
			return
		end
		applyBind(binding, i.KeyCode)
		return
	end

	local focused = UserInputService:GetFocusedTextBox()
	if focused and focused ~= field then return end
	if focused == field and i.KeyCode ~= Enum.KeyCode.Return then return end

	local isBind = false
	for _, code in pairs(binds) do
		if code == i.KeyCode then isBind = true break end
	end
	if gameProcessed and not isBind then return end

	if i.KeyCode == Enum.KeyCode.RightShift then
		win.Visible = not win.Visible
		if not win.Visible then
			board.Visible = false
			dock.Visible = false
			panelMode = nil
			setPanelLayout(false)
		end
		applyBlur()
		return
	end

	for id, code in pairs(binds) do
		if code == i.KeyCode then
			toggleModule(id)
			return
		end
	end
end)

function protonApi.bindHost(host)
	featureHost = host
	table.clear(knobState)
end

function protonApi.onSelfDestruct()
end

function protonApi.startDownload(total)
	loadStart = tick()
	loadTotal = total
	loadLayer.Visible = true
	protonApi.updateDownload(0, total, "Starting...", loadStart)
end

function protonApi.updateDownload(done, total, name, started)
	total = total or loadTotal
	started = started or loadStart
	local pct = total > 0 and math.max(0, math.min(1, done / total)) or 0
	barFill.Size = UDim2.fromScale(pct, 1)
	local elapsed = tick() - started
	local short = name or ""
	if #short > 52 then
		short = "..." .. short:sub(-49)
	end
	loadFile.Text = short
	loadMeta.Text = string.format("%d / %d · %.1fs", done, total, elapsed)
	loadPct.Text = math.floor(pct * 100) .. "%"
end

function protonApi.finishDownload()
	protonApi.updateDownload(loadTotal, loadTotal, "Ready", loadStart)
	task.wait(0.12)
	loadLayer.Visible = false
end

function protonApi.applyManifest(manifest)
	if not manifest or not manifest.stock then return end
	rawManifest = manifest
	seedStockFromManifest(manifest, lobbyMode)
	rebuildModuleIndex()
	seedBinds()
	fillList(shelfPick)
	refreshCatCounts()
end

function protonApi.setSession(label)
	if not label then return end
	tag.Visible = false
end

function protonApi.setWindowVisible(state)
	win.Visible = state == true
	if not state then
		board.Visible = false
		dock.Visible = false
		panelMode = nil
		setPanelLayout(false)
	end
	applyBlur()
end

function protonApi.setLobbyMode(state)
	local nextMode = state == true
	if lobbyMode == nextMode or not rawManifest then
		lobbyMode = nextMode
		return
	end
	lobbyMode = nextMode
	seedStockFromManifest(rawManifest, lobbyMode)
	rebuildModuleIndex()
	if lobbyMode and (lobbyHidden[shelfPick] or shelfPick == "Favorites") then
		shelfPick = "Utility"
	end
	fillList(shelfPick)
	refreshCatCounts()
end

function protonApi.forceEnabled(id, state)
	if flags[id] == state then return end
	flags[id] = state
	for _, c in ipairs(cards) do
		if c.id == id then
			c.apply(state)
			break
		end
	end
	refreshCatCounts()
	if dockOn == id and badgeDock then badgeDock(state) end
end

function protonApi.initOverlays(list)
	buildOverlayTiles(list)
end

function protonApi.setOverlay(id, state)
	overlayState[id] = state == true
	paintOverlayTile(id)
end

function protonApi.isOverlayEnabled(id)
	return overlayState[id] == true
end

function protonApi.isEnabled(id)
	return flags[id] == true
end

function protonApi.setEnabled(id, state)
	if flags[id] == state then return end
	toggleModule(id)
end

function protonApi.registerModule(def)
end

function protonApi.onToggle(id, state)
end

function protonApi.onOverlay(id, state)
end

protonApi.initOverlays({
	{ id = "TextGUI", icon = "rbxassetid://14368355456" },
	{ id = "TargetInfo", icon = "rbxassetid://14368354234" },
	{ id = "Radar", icon = "rbxassetid://14368343291" },
	{ id = "SessionInfo", icon = "rbxassetid://14368324807" },
	{ id = "ArrayList", icon = "rbxassetid://14368312652" },
	{ id = "Watermark", icon = "rbxassetid://14368322199" },
	{ id = "Keybinds", icon = "rbxassetid://14368304734" },
	{ id = "ReachDisplay", icon = "rbxassetid://14368347435" },
	{ id = "Crosshair", icon = "rbxassetid://14425650534" },
	{ id = "Ping", icon = "rbxassetid://14368326029" },
	{ id = "KitDisplay", icon = "rbxassetid://14928011633" },
	{ id = "HealthBar", icon = "rbxassetid://14368350193" },
	{ id = "ESPPreview", icon = "rbxassetid://14368359107" },
	{ id = "Notifications", icon = "rbxassetid://16738721069" },
})

_G.ProtonUI = protonApi

return protonApi
