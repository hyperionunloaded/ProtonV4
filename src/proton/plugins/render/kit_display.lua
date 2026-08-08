--proton-cache:build
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

return {
	id = "KitDisplay",
	category = "render",
	settings = {},
	init = function(ctx, plugin)
		plugin.state.links = {}
	end,
	enable = function(ctx, plugin, host)
		local bw = ctx.bw
		local localPlayer = Players.LocalPlayer

		local function findPlayer(name)
			if not name or name == "" then return nil end
			for _, plr in Players:GetPlayers() do
				if plr.Name == name or plr.DisplayName == name or plr:GetAttribute("DisguiseDisplayName") == name then
					return plr
				end
			end
			return nil
		end

		local function slide(image)
			image.Position = UDim2.fromScale(1.08, 0.5)
			TweenService:Create(image, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(1.02, 0.5),
			}):Play()
		end

		local function paint(card, plr)
			if not card or not plr then return end
			local kit = plr:GetAttribute("PlayingAsKits") or "none"
			local meta = bw.kitMeta[kit] or bw.kitMeta.none
			local image = card:FindFirstChild("ProtonKit")
			if not image then
				image = Instance.new("ImageLabel")
				image.Name = "ProtonKit"
				image.BackgroundTransparency = 1
				image.AnchorPoint = Vector2.new(1, 0.5)
				image.Size = UDim2.fromScale(1.35, 1.35)
				image.Position = UDim2.fromScale(1.08, 0.5)
				image.ImageTransparency = 0.15
				image.ScaleType = Enum.ScaleType.Crop
				image.ZIndex = 2
				image.Parent = card
				local ratio = Instance.new("UIAspectRatioConstraint")
				ratio.AspectRatio = 1
				ratio.Parent = image
			end
			image.Image = meta.renderImage
			slide(image)
		end

		local function bindRow(row)
			local nameLabel = row:FindFirstChild("PlayerName", true)
			if not nameLabel then return end
			local card = row:FindFirstChild("1")
			card = card and card:FindFirstChild("MatchDraftPlayerCard")
			if not card then return end
			local plr = findPlayer(nameLabel.Text)
			if not plr then return end
			paint(card, plr)
			host:track(plr:GetAttributeChangedSignal("PlayingAsKits"):Connect(function()
				if plugin.enabled then
					paint(card, plr)
				end
			end))
			host:track(nameLabel:GetPropertyChangedSignal("Text"):Connect(function()
				if plugin.enabled then
					local nextPlr = findPlayer(nameLabel.Text)
					if nextPlr then
						paint(card, nextPlr)
					end
				end
			end))
		end

		local function scanColumn(column)
			for _, row in column:GetChildren() do
				task.spawn(bindRow, row)
			end
			host:track(column.ChildAdded:Connect(bindRow))
		end

		task.spawn(function()
			local body
			repeat
				local app = localPlayer.PlayerGui:FindFirstChild("MatchDraftApp")
				local bg = app and app:FindFirstChild("DraftAppBackground")
				local frame = bg and bg:FindFirstChild("1")
				body = frame and frame:FindFirstChild("BodyContainer")
				task.wait(0.1)
			until body or not plugin.enabled
			if not plugin.enabled or not body then return end
			for i = 1, 2 do
				local column = body:FindFirstChild("Team" .. i .. "Column")
				if column then
					scanColumn(column)
				end
			end
		end)
	end,
	disable = function(ctx, plugin)
		local localPlayer = Players.LocalPlayer
		local app = localPlayer.PlayerGui:FindFirstChild("MatchDraftApp")
		if app then
			for _, image in app:GetDescendants() do
				if image.Name == "ProtonKit" then
					image:Destroy()
				end
			end
		end
	end,
}
