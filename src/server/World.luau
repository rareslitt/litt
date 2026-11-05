-- The whole test map is built from Roblox parts: no asset downloads are needed.
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local World = {}

local COLORS = {
	Color3.fromRGB(62, 185, 255),
	Color3.fromRGB(255, 121, 168),
	Color3.fromRGB(255, 196, 71),
	Color3.fromRGB(149, 117, 255),
	Color3.fromRGB(64, 219, 171),
	Color3.fromRGB(255, 144, 73),
}
local WHITE = Color3.fromRGB(247, 250, 255)
local NAVY = Color3.fromRGB(27, 38, 63)
local WOOD = Color3.fromRGB(176, 102, 44)
local GRASS = Color3.fromRGB(112, 205, 45)
local LIME = Color3.fromRGB(157, 232, 47)

local function part(parent, name, size, position, color, material)
	local object = Instance.new("Part")
	object.Name = name
	object.Anchored = true
	object.Size = size
	object.Position = position
	object.Color = color
	object.Material = material or Enum.Material.SmoothPlastic
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local function billboard(adornee, text, color, offset, width, height)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	gui.Size = UDim2.fromOffset(width or 220, height or 48)
	gui.StudsOffset = offset or Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 150
	gui.Adornee = adornee
	gui.Parent = adornee
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = color or WHITE
	label.TextStrokeColor3 = NAVY
	label.TextStrokeTransparency = 0.15
	label.TextSize = 19
	label.TextWrapped = true
	label.Parent = gui
	return label
end

local function prompt(parent, action, objectText, duration)
	local result = Instance.new("ProximityPrompt")
	result.Name = "Interact"
	result.ActionText = action
	result.ObjectText = objectText
	result.HoldDuration = duration or 0
	result.MaxActivationDistance = 10
	result.RequiresLineOfSight = false
	result.KeyboardKeyCode = Enum.KeyCode.E
	result.Parent = parent
	return result
end

local function neon(parent, name, size, position, color)
	local object = part(parent, name, size, position, color, Enum.Material.Neon)
	object.CanCollide = false
	object.CastShadow = false
	return object
end

local function tree(parent, x, z, scale)
	local treeModel = Instance.new("Model")
	treeModel.Name = "Tree"
	treeModel.Parent = parent
	part(treeModel, "Trunk", Vector3.new(2, 7, 2) * scale, Vector3.new(x, 3.5 * scale, z), Color3.fromRGB(125, 88, 59), Enum.Material.Wood)
	for index, spec in ipairs({{0, 8, 0, 8}, {-2, 7, 0, 6}, {2, 7, 1, 6}}) do
		local leaf = part(treeModel, "Canopy", Vector3.new(spec[4], spec[4], spec[4]) * scale,
			Vector3.new(x + spec[1] * scale, spec[2] * scale, z + spec[3] * scale),
			index == 1 and LIME or GRASS)
		leaf.TopSurface = Enum.SurfaceType.Studs
		leaf.CanCollide = false
	end
end

local function beam(parent, name, from, to, thickness, color)
	local object = part(parent, name, Vector3.new(thickness, thickness, (to - from).Magnitude), (from + to) / 2, color)
	object.CFrame = CFrame.lookAt((from + to) / 2, to)
	return object
end

local function fence(parent, from, to)
	local segments = math.ceil((to - from).Magnitude / 13)
	for index = 0, segments do
		local at = from:Lerp(to, index / segments)
		part(parent, "FencePost", Vector3.new(1.5, 6, 1.5), at + Vector3.new(0, 4, 0), WOOD)
		part(parent, "WhitePostCap", Vector3.new(1.8, 0.4, 1.8), at + Vector3.new(0, 7.2, 0), WHITE)
		if index < segments then
			local nextAt = from:Lerp(to, (index + 1) / segments)
			beam(parent, "FenceRail", at + Vector3.new(0, 2.5, 0), nextAt + Vector3.new(0, 2.5, 0), 0.65, WOOD)
			beam(parent, "WhiteFenceTrim", at + Vector3.new(0, 6.3, 0), nextAt + Vector3.new(0, 6.3, 0), 0.65, WHITE)
			beam(parent, "CrossBrace", at + Vector3.new(0, 2.8, 0), nextAt + Vector3.new(0, 6, 0), 0.45, WOOD)
			beam(parent, "CrossBrace", at + Vector3.new(0, 6, 0), nextAt + Vector3.new(0, 2.8, 0), 0.45, WOOD)
		end
	end
end

local function moneyTree(parent)
	local model = Instance.new("Model")
	model.Name = "MoneyTree"
	model.Parent = parent
	local trunk = part(model, "Trunk", Vector3.new(5, 18, 5), Vector3.new(0, 9, 118), WOOD)
	trunk.CanCollide = false
	for _, branch in ipairs({{-9, 14, 118}, {8, 16, 118}, {0, 18, 124}}) do
		beam(model, "Branch", Vector3.new(0, 8, 118), Vector3.new(branch[1], branch[2], branch[3]), 2.8, WOOD).CanCollide = false
	end
	for index, cluster in ipairs({{-8, 19, 118, 13}, {7, 21, 118, 15}, {0, 25, 118, 16}, {0, 19, 123, 12}}) do
		local leaves = part(model, "MoneyLeaves", Vector3.new(cluster[4], cluster[4] * 0.7, cluster[4]), Vector3.new(cluster[1], cluster[2], cluster[3]), index % 2 == 0 and LIME or Color3.fromRGB(133, 211, 33))
		leaves.CanCollide = false
		leaves.TopSurface = Enum.SurfaceType.Studs
	end
	for _, position in ipairs({Vector3.new(-11, 20, 110), Vector3.new(3, 27, 109), Vector3.new(12, 19, 110)}) do
		local bill = part(model, "CashLeaf", Vector3.new(4, 2, 0.3), position, Color3.fromRGB(72, 185, 63))
		bill.CanCollide = false
		bill.CFrame = bill.CFrame * CFrame.Angles(0, 0, math.rad(position.X * 2))
		billboard(bill, "$", WHITE, Vector3.zero, 30, 30).TextSize = 24
	end
	billboard(trunk, "MONEY TREE", Color3.fromRGB(255, 238, 110), Vector3.new(0, 10, 0), 250, 45)
end

local function makeBase(root, index, side, z, slotCount)
	local accent = COLORS[index]
	local x = side * 58
	local front = x - side * 27
	local model = Instance.new("Model")
	model.Name = "Base" .. index
	model.Parent = root

	part(model, "Foundation", Vector3.new(58, 1, 56), Vector3.new(x, 0.35, z), Color3.fromRGB(100, 157, 43))
	local floor = part(model, "Floor", Vector3.new(56, 1, 54), Vector3.new(x, 0.5, z), Color3.fromRGB(136, 216, 61))
	floor.TopSurface = Enum.SurfaceType.Studs
	fence(model, Vector3.new(x + side * 27.5, 0, z - 27), Vector3.new(x + side * 27.5, 0, z + 27))
	for _, edge in ipairs({-1, 1}) do
		fence(model, Vector3.new(x - 28, 0, z + edge * 27), Vector3.new(x + 28, 0, z + edge * 27))
		part(model, "EntrancePost", Vector3.new(2, 9, 2), Vector3.new(front, 5.5, z + edge * 25), WOOD)
		part(model, "PostCap", Vector3.new(2.3, 0.5, 2.3), Vector3.new(front, 10.2, z + edge * 25), WHITE)
	end
	part(model, "EntranceBeam", Vector3.new(1.5, 0.7, 52), Vector3.new(front, 9.3, z), WOOD)
	local header = part(model, "PenBoard", Vector3.new(1.5, 3, 22), Vector3.new(front, 9.8, z), NAVY)
	local sign = billboard(header, "UNCLAIMED BASE", WHITE, Vector3.new(0, 2.3, 0), 280, 50)
	local barrier = neon(model, "Shield", Vector3.new(0.7, 9, 48), Vector3.new(front, 5.5, z), accent)
	barrier.Transparency = 1
	barrier.CanTouch = false
	local lockLabel = billboard(header, "OPEN", Color3.fromRGB(121, 255, 173), Vector3.new(0, -0.3, 0), 180, 32)
	lockLabel.TextSize = 15

	local slots = {}
	for slot = 1, slotCount do
		local column = (slot - 1) % 2
		local row = math.floor((slot - 1) / 2)
		local position = Vector3.new(x + (column == 0 and -9 or 9), 3.5, z + (row - 1) * 16)
		local pedestal = part(model, "Nest" .. slot, Vector3.new(10, 0.5, 10), Vector3.new(position.X, 1.25, position.Z), WOOD)
		local nest = part(model, "NestCushion" .. slot, Vector3.new(7.5, 0.25, 7.5), Vector3.new(position.X, 1.6, position.Z), Color3.fromRGB(219, 179, 111), Enum.Material.Fabric)
		nest.CanCollide = false
		billboard(pedestal, tostring(slot), Color3.fromRGB(246, 228, 181), Vector3.new(0, 0.7, 0), 40, 24).TextSize = 13
		table.insert(slots, position)
	end

	local buttonX = x - side * 20
	local claimPad = part(model, "CollectCash", Vector3.new(9, 0.2, 9), Vector3.new(buttonX, 1.15, z + 16), Color3.fromRGB(77, 234, 67))
	claimPad.CanCollide = false
	local bankLabel = billboard(claimPad, "COLLECT CASH", WHITE, Vector3.new(0, 1.8, 0), 170, 40)
	bankLabel.TextSize = 15
	local depositPad = part(model, "DepositEgg", Vector3.new(10, 0.2, 10), Vector3.new(buttonX, 1.15, z), accent)
	depositPad.CanCollide = false
	billboard(depositPad, "BRING EGGS HERE", WHITE, Vector3.new(0, 1.7, 0), 170, 40).TextSize = 14
	local lockButton = part(model, "LockButton", Vector3.new(4, 2.5, 4), Vector3.new(buttonX, 2.25, z - 17), Color3.fromRGB(255, 97, 104))
	billboard(lockButton, "BASE SHIELD", WHITE, Vector3.new(0, 2.5, 0), 145, 35).TextSize = 14
	local lockPrompt = prompt(lockButton, "Activate shield", "Base shield", 0.2)
	return {
		index = index,
		model = model,
		origin = Vector3.new(x, 1, z),
		spawn = CFrame.new(buttonX, 5, z) * CFrame.Angles(0, side == -1 and -math.pi / 2 or math.pi / 2, 0),
		slots = slots,
		claimPad = claimPad,
		depositPad = depositPad,
		lockPrompt = lockPrompt,
		sign = sign,
		bankLabel = bankLabel,
		lockLabel = lockLabel,
		barrier = barrier,
		bounds = {center = Vector3.new(x, 6, z), size = Vector3.new(56, 12, 54)},
		entry = Vector3.new(front - side * 7, 4, z),
		accent = accent,
	}
end

function World.build(config)
	local old = Workspace:FindFirstChild("EggHeistWorld")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Model")
	root.Name = "EggHeistWorld"
	root.Parent = Workspace
	Lighting.ClockTime = 13.5
	Lighting.Brightness = 2.5
	Lighting.Ambient = Color3.fromRGB(164, 164, 148)
	Lighting.OutdoorAmbient = Color3.fromRGB(180, 185, 161)
	Lighting.GlobalShadows = true

	-- Sit above Studio's default baseplate to avoid overlapping surfaces.
	local ground = part(root, "StuddedGrass", Vector3.new(230, 8, 260), Vector3.new(0, -3.8, 0), GRASS)
	ground.TopSurface = Enum.SurfaceType.Studs
	local lane = part(root, "GrassyLane", Vector3.new(60, 0.08, 232), Vector3.new(0, 0.24, 0), Color3.fromRGB(127, 214, 45))
	lane.TopSurface = Enum.SurfaceType.Studs
	local trail = part(root, "EggTrail", Vector3.new(13, 0.1, 200), Vector3.new(0, 0.33, 0), Color3.fromRGB(195, 166, 91))
	trail.TopSurface = Enum.SurfaceType.Studs
	for z = -90, 90, 15 do
		local steppingStone = part(root, "TrailTile", Vector3.new(5, 0.12, 5), Vector3.new(0, 0.42, z), Color3.fromRGB(211, 186, 117))
		steppingStone.CFrame = steppingStone.CFrame * CFrame.Angles(0, math.rad(10), 0)
	end
	local bases = {}
	local count = math.min(config.BaseCount or 6, 6)
	for index = 1, count do
		local side = index <= 3 and -1 or 1
		local row = (index - 1) % 3
		table.insert(bases, makeBase(root, index, side, (row - 1) * 66, math.min(config.SlotsPerBase or 6, 6)))
	end

	local trailBoard = part(root, "EggTrailBoard", Vector3.new(16, 3.5, 1), Vector3.new(0, 8, -105), NAVY)
	part(root, "TrailSignPost", Vector3.new(1.4, 9, 1.4), Vector3.new(-7, 4.5, -105), WOOD)
	part(root, "TrailSignPost", Vector3.new(1.4, 9, 1.4), Vector3.new(7, 4.5, -105), WOOD)
	billboard(trailBoard, "EGG TRAIL\nNEW EGGS EVERY FEW SECONDS", Color3.fromRGB(255, 236, 121), Vector3.new(0, 1.2, 0), 300, 70).TextSize = 19
	moneyTree(root)

	local shop = Instance.new("Model")
	shop.Name = "SpeedShop"
	shop.Parent = root
	part(shop, "ShopFloor", Vector3.new(16, 1, 14), Vector3.new(-29, 0.5, -112), WOOD)
	local counter = part(shop, "Counter", Vector3.new(12, 4, 3), Vector3.new(-29, 3, -109), NAVY)
	part(shop, "Awning", Vector3.new(18, 1, 15), Vector3.new(-29, 9, -112), Color3.fromRGB(234, 234, 214))
	for _, x in ipairs({-36, -22}) do
		part(shop, "Post", Vector3.new(0.9, 8, 0.9), Vector3.new(x, 5, -116), WOOD)
	end
	billboard(counter, "SPEED SHOP\nFaster escapes. Bigger heists.", WHITE, Vector3.new(0, 5.5, 0), 245, 65).TextSize = 17
	local shopPrompt = prompt(counter, "Upgrade speed", "Speed shop", 0.2)

	local instructions = part(root, "HowToPlay", Vector3.new(17, 10, 1), Vector3.new(29, 6, -113), NAVY)
	local panel = Instance.new("SurfaceGui")
	panel.Name = "Instructions"
	panel.Face = Enum.NormalId.Back
	panel.CanvasSize = Vector2.new(640, 390)
	panel.Parent = instructions
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0.07, 0.06)
	label.Size = UDim2.fromScale(0.86, 0.88)
	label.TextColor3 = WHITE
	label.TextSize = 32
	label.Font = Enum.Font.GothamBold
	label.TextWrapped = true
	label.Text = "EGG HEIST\n\nBuy eggs on the trail.\nCollect cash at your pen.\nSteal eggs from unlocked pens.\nCarry them home to keep them!"
	label.Parent = panel
	part(root, "BoardLeftLeg", Vector3.new(1, 5, 1), Vector3.new(23, 2.5, -113), NAVY)
	part(root, "BoardRightLeg", Vector3.new(1, 5, 1), Vector3.new(35, 2.5, -113), NAVY)

	for _, side in ipairs({-1, 1}) do
		for segment = 0, 5 do
			local z = -110 + segment * 44
			local height = 58 + (segment % 3) * 4
			local wall = part(root, "TerracottaCliff", Vector3.new(18, height, 45), Vector3.new(side * 120, height / 2, z), segment % 2 == 0 and Color3.fromRGB(157, 102, 65) or Color3.fromRGB(169, 111, 72))
			wall.TopSurface = Enum.SurfaceType.Studs
			wall.LeftSurface = Enum.SurfaceType.Studs
			wall.RightSurface = Enum.SurfaceType.Studs
			local cap = part(root, "CliffGrass", Vector3.new(21, 2, 45), Vector3.new(side * 120, height + 1, z), GRASS)
			cap.TopSurface = Enum.SurfaceType.Studs
			part(root, "CliffRidge", Vector3.new(2, height - 5, 8), Vector3.new(side * 110.5, (height - 5) / 2, z - 9), Color3.fromRGB(182, 123, 78))
		end
		for z = -110, 110, 44 do
			tree(root, side * 100, z, 0.65)
			local rock = part(root, "Rock", Vector3.new(4, 3, 5), Vector3.new(side * 103, 1.5, z + 8), Color3.fromRGB(136, 134, 115))
			rock.CFrame = rock.CFrame * CFrame.Angles(0, math.rad(z), math.rad(10))
			local cactus = part(root, "Cactus", Vector3.new(2, 7, 2), Vector3.new(side * 105, 3.5, z - 9), Color3.fromRGB(73, 162, 63))
			cactus.TopSurface = Enum.SurfaceType.Studs
			part(root, "CactusArm", Vector3.new(4, 1.5, 1.5), Vector3.new(side * 105 + 1, 4, z - 9), cactus.Color)
		end
	end
	for _, z in ipairs({-133, 133}) do
		part(root, "EndCliff", Vector3.new(258, 48, 10), Vector3.new(0, 24, z), Color3.fromRGB(157, 102, 65))
		local cap = part(root, "EndCliffGrass", Vector3.new(258, 2, 12), Vector3.new(0, 49, z), GRASS)
		cap.TopSurface = Enum.SurfaceType.Studs
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(8, 0.4, 8)
	spawn.Position = Vector3.new(20, 0.4, 110)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = root

	return {
		root = root,
		beltStart = Vector3.new(0, 2.5, -96),
		beltEnd = Vector3.new(0, 2.5, 96),
		bases = bases,
		shopPrompt = shopPrompt,
	}
end

return World
