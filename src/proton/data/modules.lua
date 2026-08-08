--proton-cache:build
local exclude = {
	SongBeats = true,
	SoundChanger = true,
	YaminiExtender = true,
	CatExtender = true,
	PhaseMine = true,
	DaveyAim = true,
}

local rename = {
	VulcanAssist = "VulcanAimbot",
	VoidRegentExtender = "VoidRegentReach",
	JadeExtender = "JadeReach",
}

local raw = {
	combat = {
		{ id = "AimAssist", info = "Assists aim toward enemies" },
		{ id = "AutoClicker", info = "Automatic clicking" },
		{ id = "Reach", info = "Extends melee attack reach" },
		{ id = "SilentAim", info = "Silent hit registration" },
		{ id = "Sprint", info = "Auto-sprint" },
		{ id = "TriggerBot", info = "Attacks when crosshair on target" },
		{ id = "Velocity", info = "Modifies knockback velocity" },
		{ id = "SilentAura", info = "Silent aura attacks" },
	},
	blatant = {
		{ id = "AntiDeath", info = "Prevents death state" },
		{ id = "AntiFall", info = "Negates fall damage" },
		{ id = "AutoChargeProj", info = "Auto-charges projectiles" },
		{ id = "CannonSpeed", info = "Modifies cannon speed" },
		{ id = "DamageBoost", info = "Increases damage dealt" },
		{ id = "FastBreak", info = "Breaks blocks faster" },
		{ id = "Fly", info = "Flight movement" },
		{ id = "HitBoxes", info = "Expands hitboxes" },
		{ id = "InfiniteBlock", info = "Infinite block placement" },
		{ id = "LongJump", info = "Extended jump distance" },
		{ id = "NoFall", info = "No fall damage" },
		{ id = "NoKnockback", info = "Removes knockback" },
		{ id = "OwlAura", info = "Owl kit aura automation" },
		{ id = "ProjectileAimbot", info = "Aims projectiles at targets" },
		{ id = "ProjectileAura", info = "Automatic projectile attacks" },
		{ id = "Speed", info = "Movement speed boost" },
		{ id = "Killaura", info = "Automatic melee attacks" },
	},
	render = {
		{ id = "BedESP", info = "Highlights beds" },
		{ id = "HiveESP", info = "Highlights hives" },
		{ id = "GeneratorESP", info = "Highlights generators" },
		{ id = "Health", info = "Health display overlay" },
		{ id = "ItemESP", info = "Highlights dropped items" },
		{ id = "ItemPlates", info = "Item name plates" },
		{ id = "KitDisplay", info = "Shows player kits" },
		{ id = "KitESP", info = "Kit-based ESP" },
		{ id = "NameTags", info = "Custom name tags" },
		{ id = "NoTextures", info = "Removes world textures" },
		{ id = "BulletTracers", info = "Projectile tracers" },
		{ id = "SkinChanger", info = "Custom player skins" },
		{ id = "StorageESP", info = "Highlights storage blocks" },
	},
	utility = {
		{ id = "AntiLasso", info = "Counters lasso attacks" },
		{ id = "AutoBalloon", info = "Automatic balloon use" },
		{ id = "AutoBlockUp", info = "Blocks upward attacks" },
		{ id = "AutoCounter", info = "Automatic counter attacks" },
		{ id = "AutoHonor", info = "Auto honor interactions" },
		{ id = "AutoKit", info = "Automatic kit selection" },
		{ id = "AutoPearl", info = "Automatic pearl throws" },
		{ id = "AutoPlay", info = "Auto queue and play" },
		{ id = "AutoShoot", info = "Automatic shooting" },
		{ id = "AutoToxic", info = "Auto chat responses" },
		{ id = "AutoVoidDrop", info = "Void drop automation" },
		{ id = "DeviceSpoofer", info = "Spoofs input device" },
		{ id = "EquipKit", info = "Quick kit equip" },
		{ id = "KnockbackDelay", info = "Delays knockback packets" },
		{ id = "LeaveParty", info = "Leaves party automatically" },
		{ id = "MissileTP", info = "Missile teleportation" },
		{ id = "PickupRange", info = "Extended pickup range" },
		{ id = "RavenTP", info = "Raven teleportation" },
		{ id = "Scaffold", info = "Automatic bridging" },
		{ id = "SetEmote", info = "Sets emote automatically" },
		{ id = "SetSettings", info = "Modifies game settings" },
		{ id = "ShopQuickBuy", info = "Quick shop purchases" },
		{ id = "StaffDetector", info = "Detects staff members" },
		{ id = "TrapDisabler", info = "Disables trap effects" },
		{ id = "CheatDetector", info = "Detects other cheaters" },
	},
	world = {
		{ id = "AutoBreak", info = "Automatic block breaking" },
		{ id = "AutoTool", info = "Automatic tool switching" },
		{ id = "BedAssist", info = "Assists bed breaking" },
		{ id = "BedPatcher", info = "Patches beds with blocks" },
		{ id = "BedProtector", info = "Protects your bed" },
		{ id = "BlockIn", info = "Blocks yourself in" },
		{ id = "ChestSteal", info = "Steals from chests" },
		{ id = "FastPlace", info = "Places blocks faster" },
	},
	inventory = {
		{ id = "ArmorSwitch", info = "Auto armor switching" },
		{ id = "AutoBuy", info = "Automatic shop buying" },
		{ id = "AutoConsume", info = "Auto consumes items" },
		{ id = "AutoFish", info = "Automatic fishing" },
		{ id = "AutoHotbar", info = "Hotbar organization" },
		{ id = "AutoSteal", info = "Steals from inventories" },
		{ id = "FastConsume", info = "Fast item consumption" },
		{ id = "FastDrop", info = "Fast item dropping" },
		{ id = "AutoBank", info = "Automatic banking" },
	},
	minigames = {
		{ id = "AutoAdetunde", info = "Adetunde kit automation" },
		{ id = "AutoBeekeeper", info = "Beekeeper kit automation" },
		{ id = "AutoBuilder", info = "Builder kit automation" },
		{ id = "AutoCaitlyn", info = "Caitlyn kit automation" },
		{ id = "AutoDavey", info = "Davey kit automation" },
		{ id = "AutoDrill", info = "Drill kit automation" },
		{ id = "AutoElder", info = "Elder kit automation" },
		{ id = "AutoEmber", info = "Ember kit automation" },
		{ id = "AutoGingerbread", info = "Gingerbread kit automation" },
		{ id = "AutoGrim", info = "Grim kit automation" },
		{ id = "AutoHannah", info = "Hannah kit automation" },
		{ id = "AutoHephaestus", info = "Hephaestus kit automation" },
		{ id = "AutoKaliyah", info = "Kaliyah kit automation" },
		{ id = "AutoKrystal", info = "Krystal kit automation" },
		{ id = "AutoLani", info = "Lani kit automation" },
		{ id = "AutoMarina", info = "Marina kit automation" },
		{ id = "AutoMartin", info = "Martin kit automation" },
		{ id = "AutoMelody", info = "Melody kit automation" },
		{ id = "AutoMetal", info = "Metal kit automation" },
		{ id = "AutoMiner", info = "Miner kit automation" },
		{ id = "AutoNoelle", info = "Noelle kit automation" },
		{ id = "AutoNyx", info = "Nyx kit automation" },
		{ id = "AutoPyro", info = "Pyro kit automation" },
		{ id = "AutoRagnar", info = "Ragnar kit automation" },
		{ id = "AutoRamil", info = "Ramil kit automation" },
		{ id = "AutoSheep", info = "Sheep kit automation" },
		{ id = "AutoStar", info = "Star kit automation" },
		{ id = "AutoTaliyah", info = "Taliyah kit automation" },
		{ id = "AutoTriton", info = "Triton kit automation" },
		{ id = "AutoUma", info = "Uma kit automation" },
		{ id = "AutoVanessa", info = "Vanessa kit automation" },
		{ id = "AutoWhisper", info = "Whisper kit automation" },
		{ id = "AutoZeno", info = "Zeno kit automation" },
		{ id = "BedPlates", info = "Bed plate automation" },
		{ id = "Breaker", info = "Breaker automation" },
		{ id = "FishermanSpy", info = "Fisherman spy tool" },
		{ id = "InfiniteKrystal", info = "Infinite Krystal ability" },
		{ id = "JadeExtender", info = "Jade reach extension" },
		{ id = "AutoPickpocket", info = "Pickpocket automation" },
		{ id = "VoidRegentExtender", info = "Void Regent reach extension" },
		{ id = "VulcanAssist", info = "Vulcan aim assistance" },
		{ id = "YuziExtender", info = "Yuzi reach extension" },
		{ id = "AutoCyber", info = "Cyber kit automation" },
	},
	legit = {
		{ id = "BedBreakEffect", info = "Custom bed break effect" },
		{ id = "Crosshair", info = "Custom crosshair" },
		{ id = "DamageIndicator", info = "Damage numbers" },
		{ id = "FOV", info = "Field of view modifier" },
		{ id = "FPSBoost", info = "Performance optimizations" },
		{ id = "HitColor", info = "Hit color overlay" },
		{ id = "Interface", info = "HUD customization" },
		{ id = "KillEffect", info = "Custom kill effect" },
		{ id = "Ping", info = "Ping display" },
		{ id = "ReachDisplay", info = "Reach distance display" },
		{ id = "UICleanup", info = "Removes game UI clutter" },
		{ id = "Viewmodel", info = "Viewmodel customization" },
		{ id = "WinEffect", info = "Custom win effect" },
	},
}

local shelfMeta = {
	Favorites = { sym = "\u{2605}\u{FE0E}", tint = Color3.fromRGB(245, 166, 35) },
	Combat = { sym = "\u{2694}\u{FE0E}" },
	Blatant = { sym = "\u{26A1}" },
	Render = { sym = "\u{25C8}" },
	Utility = { sym = "\u{2692}\u{FE0E}" },
	World = { sym = "\u{25CE}" },
	Inventory = { sym = "\u{25A4}" },
	Minigames = { sym = "\u{265F}" },
	Legit = { sym = "\u{25D0}" },
}

local shelfOrder = {
	"Favorites", "Combat", "Blatant", "Render",
	"Utility", "World", "Inventory", "Minigames", "Legit",
}

local function titleCase(s)
	return s:sub(1, 1):upper() .. s:sub(2)
end

local stock = {}
local index = {}
local list = {}

for cat, entries in pairs(raw) do
	local shelf = titleCase(cat)
	stock[shelf] = stock[shelf] or {}
	for _, entry in ipairs(entries) do
		if not exclude[entry.id] then
			local id = rename[entry.id] or entry.id
			local def = { id = id, info = entry.info, category = cat }
			stock[shelf][#stock[shelf] + 1] = def
			index[id] = { def = def, shelf = shelf }
			list[#list + 1] = def
		end
	end
end

table.sort(list, function(a, b) return a.id < b.id end)

return {
	stock = stock,
	index = index,
	list = list,
	shelfOrder = shelfOrder,
	shelfMeta = shelfMeta,
	exclude = exclude,
	rename = rename,
}
