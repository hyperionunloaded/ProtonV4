--proton-cache:build
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GameAnimationUtil = require(ReplicatedStorage.TS.animation["animation-util"]).GameAnimationUtil

return {
	id = "SetEmote",
	category = "utility",
	settings = {
		{ id = "emote", kind = "drop", default = "nightmare", options = { "nightmare" } },
	},
	init = function(ctx, plugin)
		plugin.state.emoteMap = {}
		local list = {}
		for id, meta in ctx.bw.emoteMeta do
			if id ~= ctx.bw.emoteType.NONE and meta.name and not plugin.state.emoteMap[meta.name] then
				plugin.state.emoteMap[meta.name] = id
				list[#list + 1] = meta.name
			end
		end
		table.sort(list)
		if #list == 0 then list[1] = "nightmare" end
		for i, def in ipairs(plugin.settings) do
			if def.id == "emote" then plugin.settings[i].options = list end
		end
		plugin.state.track = nil
	end,
	enable = function(ctx, plugin, host)
		host:disable("SetEmote")
		if not ctx.entity.alive then return end
		local emoteType = plugin.state.emoteMap[plugin.state.emote or "nightmare"]
		local meta = emoteType and ctx.bw.emoteMeta[emoteType]
		if not meta then return end
		local char = ctx.player.Character
		char:SetAttribute("PlayingEmote", emoteType)
		ctx.bw.emoteController:playEmoteBeginSounds(emoteType, ctx.player)
		local animation = meta.animation
		if not animation and meta.emoteDisplayType then
			local display = ctx.bw.emoteDisplayMeta[meta.emoteDisplayType]
			animation = display and display.animation
		end
		if animation then
			local track = char.Humanoid:LoadAnimation(GameAnimationUtil:getAnimation(animation.type))
			track.Looped = animation.looped or false
			track:Play(nil, nil, animation.speed or 1)
			plugin.state.track = track
		end
		if not meta.animation and meta.image then
			local gui = Instance.new("BillboardGui")
			gui.Size = UDim2.fromScale(6, 2.5)
			gui.StudsOffset = Vector3.new(0, 2, 0)
			gui.AlwaysOnTop = true
			gui.Adornee = char.Head
			local image = Instance.new("ImageLabel")
			image.AnchorPoint = Vector2.new(0.5, 1)
			image.Position = UDim2.fromScale(0.5, 1)
			image.Size = UDim2.fromScale(0, 0)
			image.Image = meta.image
			image.BackgroundTransparency = 1
			image.ImageTransparency = 1
			image.ScaleType = Enum.ScaleType.Fit
			image.Parent = gui
			gui.Parent = char.Head
			TweenService:Create(image, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				ImageTransparency = 0,
			}):Play()
		end
	end,
	disable = function(ctx, plugin)
		if plugin.state.track then
			plugin.state.track:Stop()
			plugin.state.track:Destroy()
			plugin.state.track = nil
		end
		if ctx.player.Character and ctx.player.Character:GetAttribute("PlayingEmote") then
			ctx.player.Character:SetAttribute("PlayingEmote", nil)
		end
	end,
}
