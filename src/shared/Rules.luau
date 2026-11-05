-- Pure gameplay rules, also exercised by the command-line tests.
local Rules = {}

function Rules.firstFreeSlot(eggs, capacity)
	for slot = 1, capacity do
		if eggs[slot] == nil then
			return slot
		end
	end
	return nil
end

function Rules.countEggs(eggs, capacity)
	local count = 0
	for slot = 1, capacity do
		if eggs[slot] ~= nil then
			count += 1
		end
	end
	return count
end

function Rules.income(eggs, capacity)
	local total = 0
	for slot = 1, capacity do
		local egg = eggs[slot]
		if egg and egg.hatched and egg.equipped ~= false and not egg.carrier then
			total += egg.definition.income
		end
	end
	return total
end

function Rules.canAcquire(cash, cost, hasCarry, freeSlot)
	if hasCarry then
		return false, "Deliver your carried egg first."
	end
	if not freeSlot then
		return false, "Your base is full. Sell an egg to make room."
	end
	if cash < cost then
		return false, "Not enough cash for this egg."
	end
	return true, nil
end

function Rules.isLocked(base, now)
	return base.lockUntil > now
end

function Rules.canLock(base, now, cooldown)
	return now >= base.lastLock + cooldown
end

function Rules.selectEgg(definitions, roll)
	local cumulative = 0
	for _, definition in ipairs(definitions) do
		cumulative += definition.weight
		if roll <= cumulative then
			return definition
		end
	end
	return definitions[#definitions]
end

return Rules
