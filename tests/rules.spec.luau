local Rules = require("../src/shared/Rules")
local Config = require("../src/shared/Config")

local passed = 0
local function test(name, run)
	run()
	passed += 1
	print("PASS " .. name)
end

local function equal(actual, expected)
	assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function egg(definition, properties)
	local result = { definition = definition, hatched = true, equipped = true }
	for key, value in pairs(properties or {}) do result[key] = value end
	return result
end

test("purchase accepts exact price and a free slot", function()
	local allowed, reason = Rules.canAcquire(100, 100, false, 1)
	equal(allowed, true)
	equal(reason, nil)
end)

test("purchase rejects insufficient funds without changing the balance", function()
	local cash = 99
	local allowed, reason = Rules.canAcquire(cash, 100, false, 1)
	equal(allowed, false)
	assert(reason and #reason > 0)
	equal(cash, 99)
end)

test("free stealing still requires a free slot", function()
	equal(Rules.canAcquire(0, 0, false, 2), true)
	equal(Rules.canAcquire(1000, 0, false, nil), false)
end)

test("purchase and stealing reject a player already carrying", function()
	equal(Rules.canAcquire(1000, 100, true, 1), false)
	equal(Rules.canAcquire(0, 0, true, 1), false)
end)

test("full capacity rejects acquiring even with enough money", function()
	equal(Rules.canAcquire(10000, 100, false, nil), false)
end)

test("sparse slots count reserved carried eggs and find the first actual gap", function()
	local slots = { [1] = egg(Config.Eggs[1]), [3] = egg(Config.Eggs[2], { carrier = {} }) }
	equal(Rules.countEggs(slots, Config.SlotsPerBase), 2)
	equal(Rules.firstFreeSlot(slots, Config.SlotsPerBase), 2)
	for slot = 1, Config.SlotsPerBase do slots[slot] = egg(Config.Eggs[1]) end
	equal(Rules.firstFreeSlot(slots, Config.SlotsPerBase), nil)
	equal(Rules.countEggs(slots, Config.SlotsPerBase), Config.SlotsPerBase)
	-- Out-of-capacity entries must never alter a base's logical occupancy.
	slots[Config.SlotsPerBase + 1] = egg(Config.Eggs[5])
	equal(Rules.countEggs(slots, Config.SlotsPerBase), Config.SlotsPerBase)
end)

test("empty or entirely unhatched base produces no income", function()
	equal(Rules.income({}, Config.SlotsPerBase), 0)
	equal(Rules.income({ egg(Config.Eggs[5], { hatched = false }) }, Config.SlotsPerBase), 0)
end)

test("income excludes carried, unequipped and unhatched eggs", function()
	local slots = {
		egg(Config.Eggs[1]),
		egg(Config.Eggs[2], { carrier = {} }),
		egg(Config.Eggs[3], { equipped = false }),
		egg(Config.Eggs[4], { hatched = false }),
		egg(Config.Eggs[5]),
	}
	equal(Rules.income(slots, Config.SlotsPerBase), Config.Eggs[1].income + Config.Eggs[5].income)
end)

test("sparse earnings include active eggs after gaps", function()
	local slots = { [2] = egg(Config.Eggs[2]), [6] = egg(Config.Eggs[3]) }
	equal(Rules.income(slots, Config.SlotsPerBase), Config.Eggs[2].income + Config.Eggs[3].income)
end)

test("lock stops exactly at expiration", function()
	equal(Rules.isLocked({ lockUntil = 30 }, 29.999), true)
	equal(Rules.isLocked({ lockUntil = 30 }, 30), false)
	equal(Rules.isLocked({ lockUntil = 30 }, 31), false)
end)

test("lock cooldown permits exact boundary and initial activation", function()
	equal(Rules.canLock({ lastLock = -Config.LockCooldown }, 0, Config.LockCooldown), true)
	equal(Rules.canLock({ lastLock = 10 }, 69.999, 60), false)
	equal(Rules.canLock({ lastLock = 10 }, 70, 60), true)
end)

test("weighted rarity boundaries select expected eggs", function()
	local expected = {
		{ 1, 1 }, { 55, 1 }, { 56, 2 }, { 81, 2 }, { 82, 3 },
		{ 94, 3 }, { 95, 4 }, { 99, 4 }, { 100, 5 },
	}
	for _, pair in ipairs(expected) do equal(Rules.selectEgg(Config.Eggs, pair[1]), Config.Eggs[pair[2]]) end
end)

test("all 100 legal rarity rolls match configured weights", function()
	local counts = {}
	for roll = 1, 100 do
		local selected = Rules.selectEgg(Config.Eggs, roll)
		counts[selected.id] = (counts[selected.id] or 0) + 1
	end
	local weight = 0
	for _, definition in ipairs(Config.Eggs) do
		equal(counts[definition.id], definition.weight)
		assert(definition.cost > 0 and definition.income > 0)
		weight += definition.weight
	end
	equal(weight, 100)
end)

print("Rules: " .. passed .. " tests passed.")
