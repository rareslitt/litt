-- Session-only egg tycoon. Currency, ownership, proximity and cooldowns live here.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("EggHeistShared")
local Config = require(Shared:WaitForChild("Config"))
local Rules = require(Shared:WaitForChild("Rules"))
local World = require(script:WaitForChild("World"))
local EggVisual = require(script:WaitForChild("EggVisual"))
local world = World.build(Config)

local remotes = Instance.new("Folder")
remotes.Name = "EggHeistRemotes"
local function remote(class, name)
	local object = Instance.new(class)
	object.Name = name
	object.Parent = remotes
	return object
end
local stateEvent = remote("RemoteEvent", "State")
local notifyEvent = remote("RemoteEvent", "Notify")
local actionEvent = remote("RemoteEvent", "Action")
local getState = remote("RemoteFunction", "GetState")
-- Parent only after handlers below are ready, so clients cannot race initialization.
local sessions = {}
local eggs = {}
local nextId = 0
local random = Random.new()
local practiceBase = nil
local practiceEnabled = true
local secondAccumulator = 0
local beltAccumulator = Config.BeltSpawnSeconds
local guardAccumulator = 0
local restoreCarry
local refreshEgg
local interactEgg
local updatePractice

for _, base in ipairs(world.bases) do
	base.eggs = {}
	base.bank = 0
	base.lockUntil = 0
	base.lastLock = -Config.LockCooldown
	base.owner = nil
	base.practice = false
end

local function notify(player, text, kind)
	if player and player.Parent == Players then
		notifyEvent:FireClient(player, { text = text, kind = kind or "info" })
	end
end

local function rootOf(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root and humanoid and humanoid.Health > 0 then
		return root, humanoid
	end
	return nil, nil
end

local function near(player, position, distance)
	local root = rootOf(player)
	return root ~= nil and (root.Position - position).Magnitude <= (distance or Config.PromptDistance)
end

local function inside(base, position)
	local delta = position - base.bounds.center
	local half = base.bounds.size / 2
	return math.abs(delta.X) <= half.X and math.abs(delta.Z) <= half.Z
		and position.Y >= -5 and position.Y <= 40
end

local function speed(player)
	local session = sessions[player]
	local _, humanoid = rootOf(player)
	if session and humanoid then
		humanoid.WalkSpeed = session.carry and Config.CarrySpeed
			or (session.slow and 10 or Config.WalkSpeed + session.speedLevel * Config.SpeedStep)
	end
end

local function setCash(player, amount)
	local session = sessions[player]
	if not session then return end
	session.cash = math.max(0, math.floor(amount))
	local stats = player:FindFirstChild("leaderstats")
	if stats then stats.Cash.Value = session.cash end
end

local function snapshot(player)
	local session = sessions[player]
	if not session then return nil end
	local base = session.base
	local now = os.clock()
	local list = {}
	local growing = 0
	if base then
		for slot = 1, Config.SlotsPerBase do
			local egg = base.eggs[slot]
			if egg and not egg.carrier then
				if not egg.hatched then growing += 1 end
				table.insert(list, {
					name = egg.definition.name, pet = egg.definition.pet,
					rarity = egg.definition.rarity, income = egg.definition.income,
					hatched = egg.hatched, remaining = math.max(0, math.ceil((egg.hatchesAt or now) - now)),
					slot = slot, color = egg.definition.color, equipped = egg.equipped,
				})
			end
		end
	end
	return {
		cash = session.cash, income = base and Rules.income(base.eggs, Config.SlotsPerBase) or 0,
		bank = base and base.bank or 0, base = base and base.index or 0,
		eggs = base and Rules.countEggs(base.eggs, Config.SlotsPerBase) or 0,
		capacity = Config.SlotsPerBase,
		carrying = session.carry and (session.carry.hatched and session.carry.definition.pet or session.carry.definition.name) or nil,
		lockRemaining = base and math.max(0, math.ceil(base.lockUntil - now)) or 0,
		lockCooldown = base and math.max(0, math.ceil(base.lastLock + Config.LockCooldown - now)) or 0,
		speedLevel = session.speedLevel, speedCost = Config.SpeedCosts[session.speedLevel + 1],
		practice = practiceBase ~= nil, slow = session.slow, eggsList = list, growCost = growing * 100,
	}
end

local function sendState(player)
	if player.Parent == Players and sessions[player] then stateEvent:FireClient(player, snapshot(player)) end
end

local function updateBase(base)
	local now = os.clock()
	base.sign.Text = base.owner and (base.owner.DisplayName .. "'S PEN")
		or (base.practice and "PRACTICE RIVAL - STEAL HERE" or "EMPTY PEN")
	local locked = Rules.isLocked(base, now)
	base.barrier.Transparency = locked and 0.5 or 1
	base.lockLabel.Text = locked and ("LOCKED " .. math.ceil(base.lockUntil - now) .. "s") or "OPEN"
	base.lockLabel.TextColor3 = locked and Color3.fromRGB(255, 105, 105) or Color3.fromRGB(107, 255, 97)
	base.bankLabel.Text = "COLLECT $" .. math.floor(base.bank)
	base.lockPrompt.Enabled = base.owner ~= nil
	base.lockPrompt.ActionText = Rules.canLock(base, now, Config.LockCooldown) and "Lock for 30s" or "Shield recharging"
end

local function destroyEgg(egg)
	eggs[egg.id] = nil
	if egg.model then egg.model:Destroy() end
end

local function labelEgg(egg)
	local def = egg.definition
	local name = egg.hatched and def.pet or def.name
	if egg.carrier then
		egg.label.Text = name .. "\nCARRIED BY " .. egg.carrier.DisplayName
	elseif egg.base then
		local status
		if not egg.hatched then
			status = "HATCHING " .. math.max(0, math.ceil(egg.hatchesAt - os.clock())) .. "s"
		elseif not egg.equipped then
			status = "UNEQUIPPED"
		else
			status = "+$" .. def.income .. "/s"
		end
		egg.label.Text = def.rarity .. "\n" .. name .. "\n" .. status
		egg.prompt.ActionText = "Steal"
		egg.prompt.ObjectText = name
	else
		egg.label.Text = def.rarity .. "\n" .. name .. "\n$" .. def.cost .. " | +$" .. def.income .. "/s"
		egg.prompt.ActionText = "Buy $" .. def.cost
		egg.prompt.ObjectText = name
	end
	egg.prompt.Enabled = not egg.carrier
end

refreshEgg = function(egg, position)
	if egg.model then egg.model:Destroy() end
	egg.model, egg.label, egg.prompt = EggVisual.create(egg.definition, position, egg.hatched, world.root)
	egg.prompt.Triggered:Connect(function(player) interactEgg(player, egg) end)
	labelEgg(egg)
end

local function newEgg(definition, base, slot, hatched)
	nextId += 1
	local egg = {
		id = nextId, definition = definition, base = base, slot = slot,
		hatched = hatched or false, equipped = true, born = os.clock(), carrier = nil,
		hatchesAt = os.clock() + Config.HatchSeconds,
	}
	eggs[egg.id] = egg
	if base then base.eggs[slot] = egg end
	refreshEgg(egg, base and base.slots[slot] or world.beltStart)
	return egg
end

restoreCarry = function(player, message)
	local session = sessions[player]
	local egg = session and session.carry
	if not egg then return end
	session.carry = nil
	egg.carrier = nil
	if egg.base and egg.base.eggs[egg.slot] == egg then
		refreshEgg(egg, egg.base.slots[egg.slot])
		if egg.base.owner then sendState(egg.base.owner) end
	else
		-- A newly bought egg is refunded if dropped, lost on death or disconnected.
		if egg.paidBy == player then setCash(player, session.cash + egg.definition.cost) end
		destroyEgg(egg)
	end
	speed(player)
	if message then notify(player, message) end
	sendState(player)
end

local function pickup(player, egg)
	local session = sessions[player]
	session.carry = egg
	egg.carrier = player
	speed(player)
	labelEgg(egg)
	if egg.base and egg.base.owner then
		notify(egg.base.owner, player.DisplayName .. " is stealing your " .. egg.definition.pet .. "! Chase them and hold E to recover it!", "error")
		sendState(egg.base.owner)
	end
	notify(player, "Carry it to the glowing delivery pad in YOUR pen. Q returns it.", "success")
	sendState(player)
end

interactEgg = function(player, egg)
	local session = sessions[player]
	if not session or not session.base or eggs[egg.id] ~= egg or egg.carrier then return end
	if not near(player, egg.model:GetPivot().Position) then return end
	local now = os.clock()
	if now - session.lastInteract < 0.35 then return end
	session.lastInteract = now
	if egg.base == session.base then
		notify(player, "Your egg is safe here. Collect earnings on the green pad.")
		return
	end
	local cost = egg.base and 0 or egg.definition.cost
	local allowed, reason = Rules.canAcquire(session.cash, cost, session.carry ~= nil,
		Rules.firstFreeSlot(session.base.eggs, Config.SlotsPerBase))
	if not allowed then notify(player, reason, "error"); return end
	if egg.base then
		if Rules.isLocked(egg.base, now) then notify(player, "That pen is locked!", "error"); return end
		if not egg.base.owner and not egg.base.practice then return end
	else
		setCash(player, session.cash - cost)
		egg.paidBy = player
	end
	pickup(player, egg)
end

local function deposit(player)
	local session = sessions[player]
	local egg = session and session.carry
	local base = session and session.base
	if not egg or not base or not near(player, base.depositPad.Position, 9) then return end
	local slot = Rules.firstFreeSlot(base.eggs, Config.SlotsPerBase)
	if not slot then notify(player, "Your pen is full. Return this egg with Q.", "error"); return end
	local oldBase = egg.base
	if oldBase then oldBase.eggs[egg.slot] = nil end
	egg.base, egg.slot, egg.carrier, egg.paidBy = base, slot, nil, nil
	base.eggs[slot] = egg
	session.carry = nil
	if not egg.hatched then egg.hatchesAt = os.clock() + Config.HatchSeconds end
	egg.equipped = true
	refreshEgg(egg, base.slots[slot])
	speed(player)
	if oldBase and oldBase.owner then
		notify(oldBase.owner, "Your " .. egg.definition.pet .. " was stolen!", "error")
		sendState(oldBase.owner)
	end
	notify(player, oldBase and "Steal complete! Your new pet is home." or "Egg delivered! It will hatch in 12 seconds.", "success")
	sendState(player)
end

local function collect(player)
	local session = sessions[player]
	local base = session and session.base
	if not base or base.bank < 1 or not near(player, base.claimPad.Position, 9) then return end
	local amount = base.bank
	base.bank = 0
	setCash(player, session.cash + amount)
	notify(player, "Collected $" .. math.floor(amount) .. "!", "success")
	updateBase(base)
	sendState(player)
end

local function upgrade(player)
	local session = sessions[player]
	if not session or not session.base then return end
	local cost = Config.SpeedCosts[session.speedLevel + 1]
	if not cost then notify(player, "Speed is already maxed!"); return end
	if session.cash < cost then notify(player, "You need $" .. cost .. " for more speed.", "error"); return end
	setCash(player, session.cash - cost)
	session.speedLevel += 1
	speed(player)
	notify(player, "Speed upgraded! Level " .. session.speedLevel, "success")
	sendState(player)
end

local function clearBase(base)
	-- Return carried items before deleting their origin, including on owner exit.
	for player, session in pairs(sessions) do
		if session.carry and session.carry.base == base then
			restoreCarry(player, "The original pen closed. That egg was returned.")
		end
	end
	for slot = 1, Config.SlotsPerBase do
		if base.eggs[slot] then destroyEgg(base.eggs[slot]) end
	end
	base.eggs = {}
	base.bank = 0
	base.owner = nil
	base.practice = false
	base.lockUntil = 0
	base.lastLock = -Config.LockCooldown
	updateBase(base)
end

updatePractice = function()
	local count = 0
	for _ in pairs(sessions) do count += 1 end
	local shouldHave = practiceEnabled and count == 1
	if practiceBase and not shouldHave then
		local previous = practiceBase
		practiceBase = nil
		clearBase(previous)
	end
	if shouldHave and not practiceBase then
		for _, base in ipairs(world.bases) do
			if not base.owner and not base.practice then
				practiceBase = base
				base.practice = true
				newEgg(Config.Eggs[1], base, 1, true)
				newEgg(Config.Eggs[2], base, 3, true)
				newEgg(Config.Eggs[3], base, 5, true)
				updateBase(base)
				break
			end
		end
	end
end

for _, base in ipairs(world.bases) do
	base.lockPrompt.Triggered:Connect(function(player)
		local session = sessions[player]
		if not session or session.base ~= base or not near(player, base.lockPrompt.Parent.Position) then return end
		local now = os.clock()
		if not Rules.canLock(base, now, Config.LockCooldown) then
			notify(player, "Shield recharges " .. math.ceil(base.lastLock + Config.LockCooldown - now) .. "s after now.", "error")
			return
		end
		base.lastLock, base.lockUntil = now, now + Config.LockSeconds
		updateBase(base)
		notify(player, "Your pen is protected for 30 seconds!", "success")
		sendState(player)
	end)
	updateBase(base)
end
world.shopPrompt.Triggered:Connect(function(player)
	if near(player, world.shopPrompt.Parent.Position) then upgrade(player) end
end)

local function setupCharacter(player, character)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local session = sessions[player]
	if not root or not humanoid or not session or player.Character ~= character then return end
	if session.base then character:PivotTo(session.base.spawn) end
	speed(player)
	humanoid.Died:Connect(function() restoreCarry(player) end)
	local recover = Instance.new("ProximityPrompt")
	recover.Name = "RecoverStolenEgg"
	recover.ActionText = "Recover your stolen egg"
	recover.ObjectText = player.DisplayName
	recover.MaxActivationDistance = 8
	recover.RequiresLineOfSight = false
	recover.HoldDuration = 0.2
	recover.Enabled = false
	recover.Parent = root
	recover.Triggered:Connect(function(defender)
		local egg = session.carry
		if egg and egg.base and egg.base.owner == defender and near(defender, root.Position, 10) then
			restoreCarry(player, "Caught! The owner recovered their egg.")
			notify(defender, "You recovered your egg!", "success")
		end
	end)
end

local function assignBase(player)
	local session = sessions[player]
	for _, base in ipairs(world.bases) do
		if not base.owner and not base.practice then
			base.owner = player
			session.base = base
			updateBase(base)
			local root = rootOf(player)
			if root then player.Character:PivotTo(base.spawn) end
			return true
		end
	end
	return false
end

local function playerAdded(player)
	if sessions[player] then return end
	sessions[player] = { cash = Config.StartingCash, base = nil, carry = nil,
		speedLevel = 0, slow = false, lastAction = -1, lastInteract = -1 }
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name, cash.Value, cash.Parent = "Cash", Config.StartingCash, stats
	stats.Parent = player
	-- The practice pen yields its slot when another real player arrives.
	updatePractice()
	if not assignBase(player) then
		notify(player, "All six pens are occupied. You can explore until one becomes free.")
	end
	player.CharacterAdded:Connect(function(character) setupCharacter(player, character) end)
	if player.Character then task.spawn(setupCharacter, player, player.Character) end
	sendState(player)
end

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(function(player)
	local session = sessions[player]
	if not session then return end
	restoreCarry(player)
	if session.base then clearBase(session.base) end
	sessions[player] = nil
	-- Offer the released pen to a waiting player.
	for waiting, data in pairs(sessions) do
		if not data.base then assignBase(waiting); sendState(waiting) end
	end
	updatePractice()
end)

getState.OnServerInvoke = function(player) return snapshot(player) end

actionEvent.OnServerEvent:Connect(function(player, action, argument)
	local session = sessions[player]
	if not session or type(action) ~= "string" then return end
	local now = os.clock()
	if now - session.lastAction < 0.25 then return end
	session.lastAction = now
	local base = session.base
	if action == "drop" then
		restoreCarry(player, "Egg returned. Purchased eggs are refunded.")
	elseif action == "upgrade" then
		upgrade(player)
	elseif action == "slow" then
		session.slow = not session.slow
		speed(player)
	elseif action == "home" then
		if session.carry then notify(player, "Walk home while carrying an egg!", "error")
		elseif base and rootOf(player) then player.Character:PivotTo(base.spawn) end
	elseif action == "practice" then
		local count = 0
		for _ in pairs(sessions) do count += 1 end
		if count ~= 1 then notify(player, "Practice mode is only for solo tests. Steal from real players now!", "error")
		else practiceEnabled = not practiceEnabled; updatePractice() end
	elseif action == "sell" and base then
		if session.carry then notify(player, "Deliver or return your carried egg first.", "error"); return end
		for slot = Config.SlotsPerBase, 1, -1 do
			local egg = base.eggs[slot]
			if egg and not egg.carrier then
				base.eggs[slot] = nil
				local refund = math.floor(egg.definition.cost * Config.SellFraction)
				setCash(player, session.cash + refund)
				destroyEgg(egg)
				notify(player, "Sold for $" .. refund .. ".", "success")
				break
			end
		end
	elseif action == "grow" and base then
		local growing = {}
		for slot = 1, Config.SlotsPerBase do
			local egg = base.eggs[slot]
			if egg and not egg.hatched and not egg.carrier then table.insert(growing, egg) end
		end
		local cost = #growing * 100
		if cost == 0 then notify(player, "No eggs growing right now."); return end
		if session.cash < cost then notify(player, "Grow All costs $" .. cost .. ".", "error"); return end
		setCash(player, session.cash - cost)
		for _, egg in ipairs(growing) do egg.hatchesAt = now end
		notify(player, "Growing accelerated!", "success")
	elseif action == "equip" and base then
		if type(argument) ~= "number" or argument % 1 ~= 0 or argument < 1 or argument > Config.SlotsPerBase then return end
		local egg = base.eggs[argument]
		if egg and egg.hatched and not egg.carrier then egg.equipped = not egg.equipped; labelEgg(egg) end
	elseif action == "equipBest" and base then
		for slot = 1, Config.SlotsPerBase do
			local egg = base.eggs[slot]
			if egg and egg.hatched and not egg.carrier then egg.equipped = true; labelEgg(egg) end
		end
	end
	sendState(player)
end)
remotes.Parent = ReplicatedStorage
for _, player in ipairs(Players:GetPlayers()) do playerAdded(player) end

RunService.Heartbeat:Connect(function(dt)
	local now = os.clock()
	beltAccumulator += dt
	secondAccumulator += dt
	guardAccumulator += dt
	if beltAccumulator >= Config.BeltSpawnSeconds then
		beltAccumulator %= Config.BeltSpawnSeconds
		local onBelt = 0
		for _, egg in pairs(eggs) do if not egg.base and not egg.carrier then onBelt += 1 end end
		if onBelt < Config.BeltMaxEggs then
			-- Every third egg is affordable, so beginners never wait for random luck.
			local definition = nextId % 3 == 0 and Config.Eggs[1] or Rules.selectEgg(Config.Eggs, random:NextInteger(1, 100))
			newEgg(definition)
		end
	end
	for _, egg in pairs(eggs) do
		if egg.carrier then
			local root = rootOf(egg.carrier)
			if root then egg.model:PivotTo(root.CFrame * CFrame.new(0, 0.7, -3)) end
		elseif not egg.base then
			local progress = (now - egg.born) / Config.BeltTravelSeconds
			if progress >= 1 then destroyEgg(egg)
			else egg.model:PivotTo(CFrame.new(world.beltStart:Lerp(world.beltEnd, progress)) * CFrame.Angles(0, now * 0.8, 0)) end
		end
	end
	-- Slow checks independently of frame rate. Authoritative base protection and delivery.
	if guardAccumulator >= 0.2 then
		guardAccumulator %= 0.2
		for player, session in pairs(sessions) do
			local root = rootOf(player)
			if root then
				for _, base in ipairs(world.bases) do
					if base.owner ~= player and Rules.isLocked(base, now) and inside(base, root.Position) then
						if session.carry and session.carry.base == base then restoreCarry(player, "The owner locked the pen and recovered their egg!") end
						player.Character:PivotTo(CFrame.new(base.entry))
						root.AssemblyLinearVelocity = Vector3.zero
					end
				end
				local recover = root:FindFirstChild("RecoverStolenEgg")
				if recover then recover.Enabled = session.carry ~= nil and session.carry.base ~= nil and session.carry.base.owner ~= nil end
				if session.base then deposit(player); collect(player) end
				if root.Position.Y < -25 then
					restoreCarry(player)
					if session.base then player.Character:PivotTo(session.base.spawn) end
				end
			end
		end
	end
	if secondAccumulator >= 1 then
		local elapsed = math.floor(secondAccumulator)
		secondAccumulator -= elapsed
		for _, base in ipairs(world.bases) do
			for slot = 1, Config.SlotsPerBase do
				local egg = base.eggs[slot]
				if egg and not egg.carrier then
					if not egg.hatched and now >= egg.hatchesAt then
						egg.hatched = true
						refreshEgg(egg, base.slots[slot])
						if base.owner then notify(base.owner, egg.definition.pet .. " hatched! +$" .. egg.definition.income .. "/s", "success") end
					end
					labelEgg(egg)
				end
			end
			if base.owner then base.bank += Rules.income(base.eggs, Config.SlotsPerBase) * elapsed end
			updateBase(base)
		end
		for player in pairs(sessions) do sendState(player) end
	end
end)

print("[Litt] Egg Heist prototype ready. Buy, hatch, earn and steal! Session progress is not saved.")
