--proton-cache:build
local store = {
	attackReach = 0,
	lastAttack = 0,
	lastHit = 0,
	attackReachUpdate = 0,
	hand = {},
	inventory = {
		inventory = { items = {}, armor = {} },
		hotbar = {},
	},
	inventories = {},
	matchState = 0,
	queueType = "bedwars_test",
	equippedKit = "",
	map = nil,
	tools = {},
	swordDistance = 14.4,
}

return store
