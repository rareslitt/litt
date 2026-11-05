-- Colorful playtest HUD. All purchases, balances, and inventory live on the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("EggHeistHUD")
if old then old:Destroy() end

local C = {
	black = Color3.fromRGB(23, 20, 24), white = Color3.fromRGB(255, 255, 255),
	body = Color3.fromRGB(53, 65, 77), card = Color3.fromRGB(72, 88, 103),
	tan = Color3.fromRGB(193, 157, 111), green = Color3.fromRGB(101, 241, 45),
	cyan = Color3.fromRGB(59, 210, 255), red = Color3.fromRGB(242, 67, 66),
	orange = Color3.fromRGB(255, 163, 45), yellow = Color3.fromRGB(255, 222, 62),
}
local function make(className, properties, parent)
	local object = Instance.new(className)
	for key, value in pairs(properties) do object[key] = value end
	if object:IsA("GuiObject") and properties.ZIndex == nil then
		object.ZIndex = parent and parent:IsA("GuiObject") and parent.ZIndex + 1 or 1
	end
	object.Parent = parent
	return object
end
local function round(object, radius)
	make("UICorner", { CornerRadius = UDim.new(0, radius or 12) }, object)
end
local function border(object, thickness, color)
	make("UIStroke", { Color = color or C.black, Thickness = thickness or 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, object)
end
local function text(parent, value, position, size, fontSize, color, align)
	local object = make("TextLabel", {
		BackgroundTransparency = 1, Text = value, Position = position, Size = size,
		TextColor3 = color or C.white, Font = Enum.Font.FredokaOne,
		TextSize = fontSize or 20, TextWrapped = true,
		TextXAlignment = align or Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
	}, parent)
	make("UIStroke", { Color = C.black, Thickness = fontSize and fontSize >= 30 and 3 or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, object)
	return object
end
local function button(parent, value, position, size, color, fontSize)
	local object = make("TextButton", {
		Text = value, Position = position, Size = size, BackgroundColor3 = color or C.green,
		TextColor3 = C.white, Font = Enum.Font.FredokaOne, TextSize = fontSize or 22,
		TextWrapped = true, BorderSizePixel = 0, AutoButtonColor = true,
	}, parent)
	round(object, 10)
	border(object, 3)
	make("UIStroke", { Color = C.black, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, object)
	make("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(199, 199, 199)), Rotation = 90 }, object)
	return object
end
local function box(parent, position, size, color)
	local object = make("Frame", { Position = position, Size = size, BackgroundColor3 = color or C.card, BorderSizePixel = 0 }, parent)
	round(object, 10)
	border(object, 2)
	return object
end
local function rgb(value, fallback)
	if type(value) == "table" then
		return Color3.fromRGB(value[1] or value.r or 255, value[2] or value.g or 220, value[3] or value.b or 85)
	end
	return fallback or C.yellow
end
local function eggIcon(parent, position, size, color)
	local holder = make("Frame", { Position = position, Size = size, BackgroundTransparency = 1 }, parent)
	local egg = box(holder, UDim2.fromScale(0.19, 0.05), UDim2.fromScale(0.62, 0.9), color or C.yellow)
	round(egg, 100)
	local shine = make("Frame", { Position = UDim2.fromScale(0.23, 0.18), Size = UDim2.fromScale(0.2, 0.25), BackgroundColor3 = C.white, BackgroundTransparency = 0.35, BorderSizePixel = 0 }, egg)
	round(shine, 100)
	return holder
end
local function pawIcon(parent, position, size, color)
	local holder = make("Frame", { Position = position, Size = size, BackgroundTransparency = 1 }, parent)
	local pad = box(holder, UDim2.fromScale(0.23, 0.44), UDim2.fromScale(0.54, 0.46), color or C.white)
	round(pad, 100)
	for index = 1, 4 do
		local toe = box(holder, UDim2.fromScale(0.02 + (index - 1) * 0.25, (index == 1 or index == 4) and 0.25 or 0.05), UDim2.fromScale(0.22, 0.29), color or C.white)
		round(toe, 100)
	end
	return holder
end

local screen = make("ScreenGui", { Name = "EggHeistHUD", ResetOnSpawn = false, IgnoreGuiInset = false, DisplayOrder = 20, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)
local viewport = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, screen)
local canvas = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, viewport)
local scale = make("UIScale", { Scale = 1 }, canvas)
local hint
local resetNote
local function fit()
	local size = viewport.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then return end
	scale.Scale = math.clamp(math.min(size.X / 1100, size.Y / 720), 0.55, 1)
	canvas.Size = UDim2.fromOffset(size.X / scale.Scale, size.Y / scale.Scale)
	local compact = size.X / scale.Scale < 900
	if hint then hint.Position = compact and UDim2.new(0.5, -215, 0, 88) or UDim2.new(0.5, -215, 1, -65) end
	if resetNote then resetNote.Position = compact and UDim2.new(0.5, -170, 0, 132) or UDim2.new(0.5, -170, 1, -23) end
end
viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
task.defer(fit)

text(canvas, "STEAL AN EGG  •  LITT PLAYTEST", UDim2.new(0.5, -220, 0, 7), UDim2.fromOffset(440, 26), 17, C.white, Enum.TextXAlignment.Center)
local baseLabel = text(canvas, "Finding your base...", UDim2.new(0.5, -220, 0, 36), UDim2.fromOffset(440, 24), 17, C.yellow, Enum.TextXAlignment.Center)
local lockLabel = text(canvas, "", UDim2.new(0.5, -220, 0, 61), UDim2.fromOffset(440, 22), 15, C.green, Enum.TextXAlignment.Center)

local shopButton = button(canvas, "SHOP", UDim2.new(0, 20, 0.5, -110), UDim2.fromOffset(128, 64), C.green, 29)
local indexButton = button(canvas, "INDEX", UDim2.new(0, 20, 0.5, -36), UDim2.fromOffset(128, 64), C.cyan, 27)
local slowButton = button(canvas, "SLOW: OFF", UDim2.new(0, 20, 0.5, 38), UDim2.fromOffset(128, 39), C.red, 17)
local toolsButton = button(canvas, "TOOLS", UDim2.new(0, 20, 0.5, 87), UDim2.fromOffset(128, 34), C.orange, 17)
local cashLabel = text(canvas, "$0", UDim2.new(0, 20, 1, -77), UDim2.fromOffset(350, 63), 46, C.green)
local incomeLabel = text(canvas, "+$0 / sec", UDim2.new(0, 24, 1, -104), UDim2.fromOffset(300, 30), 22, C.white)
local bankLabel = text(canvas, "$0 on your green pad", UDim2.new(0, 24, 1, -24), UDim2.fromOffset(340, 19), 12, C.white)
local eggButton = button(canvas, "", UDim2.new(1, -94, 0.5, -76), UDim2.fromOffset(74, 74), C.red)
eggIcon(eggButton, UDim2.fromOffset(17, 7), UDim2.fromOffset(40, 49), C.yellow)
text(eggButton, "EGGS", UDim2.fromOffset(0, 48), UDim2.fromOffset(74, 24), 16, C.white, Enum.TextXAlignment.Center)
local petsButton = button(canvas, "", UDim2.new(1, -94, 0.5, 10), UDim2.fromOffset(74, 74), C.orange)
pawIcon(petsButton, UDim2.fromOffset(17, 8), UDim2.fromOffset(40, 42), C.white)
text(petsButton, "PETS", UDim2.fromOffset(0, 48), UDim2.fromOffset(74, 24), 16, C.white, Enum.TextXAlignment.Center)

hint = text(canvas, "Hold E at the egg trail to buy an egg.", UDim2.new(0.5, -215, 1, -65), UDim2.fromOffset(430, 42), 18, C.white, Enum.TextXAlignment.Center)
resetNote = text(canvas, "PLAYTEST: progress resets each server", UDim2.new(0.5, -170, 1, -23), UDim2.fromOffset(340, 18), 10, C.white, Enum.TextXAlignment.Center)
local carry = box(canvas, UDim2.new(0.5, -240, 1, -157), UDim2.fromOffset(480, 82), C.body)
carry.Visible = false
local carryLabel = text(carry, "CARRYING AN EGG", UDim2.fromOffset(12, 5), UDim2.fromOffset(330, 31), 20, C.yellow)
text(carry, "Return to your glowing delivery pad!", UDim2.fromOffset(12, 39), UDim2.fromOffset(330, 28), 15, C.white)
local returnButton = button(carry, "RETURN\n[Q]", UDim2.fromOffset(353, 15), UDim2.fromOffset(114, 51), C.red, 17)

local shade = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.black, BackgroundTransparency = 0.47, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 30, BorderSizePixel = 0 }, canvas)
local modal = box(canvas, UDim2.new(0.5, 0, 0.5, 0), UDim2.fromOffset(550, 440), C.body)
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.ZIndex = 40
modal.Visible = false
local header = box(modal, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 79), C.tan)
for index = 0, 12 do
	local stud = make("Frame", { Position = UDim2.fromOffset(index * 45 + 8, 10), Size = UDim2.fromOffset(23, 18), BackgroundColor3 = Color3.fromRGB(239, 206, 158), BackgroundTransparency = 0.5, BorderSizePixel = 0 }, header)
	round(stud, 100)
end
local modalTitle = text(header, "SHOP", UDim2.fromOffset(18, 10), UDim2.new(1, -84, 0, 38), 30)
local modalSubtitle = text(header, "", UDim2.fromOffset(18, 48), UDim2.new(1, -38, 0, 22), 14)
local closeButton = button(header, "X", UDim2.new(1, -53, 0, 12), UDim2.fromOffset(40, 40), C.red, 24)
local list = make("ScrollingFrame", { Position = UDim2.fromOffset(13, 91), Size = UDim2.new(1, -26, 1, -166), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, ScrollBarImageColor3 = C.white, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y }, modal)
make("UIListLayout", { Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder }, list)
make("UIPadding", { PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 7), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 6) }, list)
local footer = button(modal, "", UDim2.new(0, 16, 1, -61), UDim2.new(1, -32, 0, 45), C.green, 21)

local state = {}
local catalog = {}
local activeModal
local actionRemote
local lastAction = 0
local notify
local function send(action, arg)
	if not actionRemote then
		if notify then notify({ text = "Waiting for the game server...", kind = "info" }) end
		return
	end
	if os.clock() - lastAction < 0.2 then return end
	lastAction = os.clock()
	actionRemote:FireServer(action, arg)
end
local function money(value)
	local n = math.floor(tonumber(value) or 0)
	if n >= 1000000 then return string.format("$%.2fM", n / 1000000) end
	if n >= 10000 then return string.format("$%.1fK", n / 1000) end
	local s = tostring(n)
	while true do
		local count
		s, count = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
		if count == 0 then break end
	end
	return "$" .. s
end
local function clearRows()
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
end
local function row(titleText, subtitle, color, kind)
	local item = box(list, UDim2.new(), UDim2.new(1, -5, 0, 73), C.card)
	if kind == "pet" then pawIcon(item, UDim2.fromOffset(10, 12), UDim2.fromOffset(45, 45), color)
	else eggIcon(item, UDim2.fromOffset(9, 6), UDim2.fromOffset(44, 58), color) end
	text(item, titleText, UDim2.fromOffset(65, 7), UDim2.new(1, -192, 0, 29), 20)
	text(item, subtitle, UDim2.fromOffset(65, 37), UDim2.new(1, -192, 0, 26), 13, C.yellow)
	return item
end
local function empty(message)
	text(list, message, UDim2.new(), UDim2.new(1, -10, 0, 140), 20, C.white, Enum.TextXAlignment.Center)
end
local function showModal(kind)
	activeModal = kind
	modal.Visible = kind ~= nil
	shade.Visible = kind ~= nil
	if not kind then return end
	local scroll = list.CanvasPosition
	clearRows()
	footer.Visible = true
	if kind == "eggs" then
		modalTitle.Text = "GROWING EGGS"
		modalSubtitle.Text = "Delivered eggs hatch automatically. In-game cash only."
		local count = 0
		for _, egg in ipairs(state.eggsList or {}) do
			if not egg.hatched then
				count += 1
				local item = row(egg.name, egg.rarity .. "  /  " .. math.ceil(egg.remaining or 0) .. "s to hatch", rgb(egg.color), "egg")
				text(item, "GROWING", UDim2.new(1, -119, 0, 20), UDim2.fromOffset(108, 33), 16, C.green, Enum.TextXAlignment.Center)
			end
		end
		if count == 0 then empty("No eggs growing yet!\nBuy one, then deliver it to your base.") end
		footer.Text = "GROW ALL  •  " .. money(state.growCost or count * 100)
		footer.BackgroundColor3 = C.yellow
	elseif kind == "pets" then
		modalTitle.Text = "YOUR PETS"
		local count, active = 0, 0
		for _, egg in ipairs(state.eggsList or {}) do
			if egg.hatched then
				count += 1
				local equipped = egg.equipped ~= false
				if equipped then active += 1 end
				local item = row(egg.pet or egg.name, money(egg.income) .. "/sec  •  " .. egg.rarity, rgb(egg.color), "pet")
				local equip = button(item, equipped and "UNEQUIP" or "EQUIP", UDim2.new(1, -119, 0, 19), UDim2.fromOffset(108, 36), equipped and C.red or C.green, 15)
				equip.Activated:Connect(function() send("equip", egg.slot) end)
			end
		end
		modalSubtitle.Text = "ACTIVE: " .. active .. "  /  CAPACITY: " .. (state.capacity or 6)
		if count == 0 then empty("Your pets appear here after eggs hatch.") end
		footer.Text = "EQUIP BEST"
		footer.BackgroundColor3 = C.green
	elseif kind == "index" then
		modalTitle.Text = "EGG INDEX"
		modalSubtitle.Text = "Find rare eggs on the egg trail. Every rarity earns more."
		for _, egg in ipairs(catalog) do
			local item = row(egg.name, egg.rarity .. "  •  " .. (egg.pet or "Mystery pet"), rgb(egg.color), "egg")
			text(item, money(egg.cost) .. "\n" .. money(egg.income) .. "/sec", UDim2.new(1, -119, 0, 8), UDim2.fromOffset(108, 57), 15, C.green, Enum.TextXAlignment.Center)
		end
		if #catalog == 0 then empty("Loading egg catalog...") end
		footer.Text = "BACK TO THE GAME"
		footer.BackgroundColor3 = C.cyan
	elseif kind == "shop" then
		modalTitle.Text = "SHOP"
		modalSubtitle.Text = "Earn cash by collecting from your green base pad."
		local upgrade = row("SPEED UPGRADE", "Level " .. (state.speedLevel or 0) .. "  •  Run faster between bases", C.green, "pet")
		local speed = button(upgrade, state.speedCost and money(state.speedCost) or "MAX", UDim2.new(1, -119, 0, 19), UDim2.fromOffset(108, 36), C.green, 17)
		speed.Activated:Connect(function() send("upgrade") end)
		local grow = row("GROW ALL EGGS", "Skip the hatch wait using earned cash", C.yellow, "egg")
		local growButton = button(grow, money(state.growCost or 0), UDim2.new(1, -119, 0, 19), UDim2.fromOffset(108, 36), C.yellow, 17)
		growButton.Activated:Connect(function() send("grow") end)
		local note = text(list, "No Robux purchases in this prototype.\nEverything here uses your in-game cash.", UDim2.new(), UDim2.new(1, -12, 0, 57), 14, C.white, Enum.TextXAlignment.Center)
		note.LayoutOrder = 10
		footer.Text = "BACK TO THE GAME"
		footer.BackgroundColor3 = C.green
	elseif kind == "tools" then
		modalTitle.Text = "PLAYTEST TOOLS"
		modalSubtitle.Text = "Try the game alone, or invite a second test player."
		local function tool(name, detail, color, action)
			local item = row(name, detail, color, "egg")
			local use = button(item, "GO", UDim2.new(1, -119, 0, 19), UDim2.fromOffset(108, 36), color, 17)
			use.Activated:Connect(function() send(action) end)
		end
		tool("GO HOME", "Return to your base without carrying an egg", C.cyan, "home")
		tool(state.practice and "PRACTICE: ON" or "PRACTICE: OFF", "Toggle the rival base when playing alone", C.green, "practice")
		tool("SELL LAST EGG", "Sell your last egg to free up a slot", C.orange, "sell")
		footer.Text = "HOW TO PLAY"
		footer.BackgroundColor3 = C.yellow
	elseif kind == "help" then
		modalTitle.Text = "HOW TO PLAY"
		modalSubtitle.Text = "BUY  >  HATCH  >  EARN  >  STEAL"
		local lines = {
			"1. Hold E near a trail egg to buy it.",
			"2. Carry it onto your base's glowing delivery pad.",
			"3. Wait for it to hatch. Pets earn cash every second.",
			"4. Step on the green collection pad to claim cash.",
			"5. Steal rival eggs and carry them home!",
			"6. Use your red lock button to protect your base.",
		}
		for _, line in ipairs(lines) do text(list, line, UDim2.new(), UDim2.new(1, -12, 0, 39), 17) end
		footer.Text = "LET'S PLAY!"
		footer.BackgroundColor3 = C.green
	end
	list.CanvasPosition = scroll
end
shade.Activated:Connect(function() showModal(nil) end)
closeButton.Activated:Connect(function() showModal(nil) end)
footer.Activated:Connect(function()
	if activeModal == "eggs" then send("grow")
	elseif activeModal == "pets" then send("equipBest")
	elseif activeModal == "tools" then showModal("help")
	else showModal(nil) end
end)
shopButton.Activated:Connect(function() showModal("shop") end)
indexButton.Activated:Connect(function() showModal("index") end)
eggButton.Activated:Connect(function() showModal("eggs") end)
petsButton.Activated:Connect(function() showModal("pets") end)
toolsButton.Activated:Connect(function() showModal("tools") end)
slowButton.Activated:Connect(function() send("slow") end)
returnButton.Activated:Connect(function() send("drop") end)

local toast = box(canvas, UDim2.new(0.5, 0, 0, 94), UDim2.fromOffset(490, 62), C.body)
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.ZIndex = 60
toast.Visible = false
local toastText = text(toast, "", UDim2.fromOffset(12, 5), UDim2.fromOffset(466, 52), 19, C.white, Enum.TextXAlignment.Center)
local generation = 0
local toastTween
notify = function(payload)
	generation += 1
	local current = generation
	if toastTween then toastTween:Cancel() end
	toast.Visible = true
	toastText.TextTransparency = 0
	toastText.Text = type(payload) == "table" and payload.text or tostring(payload)
	local kind = type(payload) == "table" and payload.kind or "info"
	toastText.TextColor3 = kind == "error" and Color3.fromRGB(255, 133, 133) or (kind == "success" and C.green or C.white)
	task.delay(4, function()
		if current ~= generation then return end
		toastTween = TweenService:Create(toastText, TweenInfo.new(0.25), { TextTransparency = 1 })
		toastTween:Play()
		toastTween.Completed:Wait()
		if current == generation then toast.Visible = false end
	end)
end
local function render(nextState)
	if type(nextState) ~= "table" then return end
	state = nextState
	cashLabel.Text = money(state.cash)
	incomeLabel.Text = "+" .. money(state.income) .. " / sec"
	bankLabel.Text = money(state.bank) .. " on your green pad"
	baseLabel.Text = "BASE " .. (state.base or "?") .. "  •  " .. (state.eggs or 0) .. "/" .. (state.capacity or 6) .. " SLOTS"
	local locked = math.ceil(state.lockRemaining or 0)
	local cooldown = math.ceil(state.lockCooldown or 0)
	lockLabel.Text = locked > 0 and ("BASE LOCKED: " .. locked .. "s") or (cooldown > 0 and ("BASE OPEN  •  lock ready in " .. cooldown .. "s") or "BASE OPEN  •  use your red lock button")
	lockLabel.TextColor3 = locked > 0 and C.green or C.yellow
	slowButton.Text = state.slow and "SLOW: ON" or "SLOW: OFF"
	slowButton.BackgroundColor3 = state.slow and C.green or C.red
	carry.Visible = type(state.carrying) == "string" and state.carrying ~= ""
	if carry.Visible then
		carryLabel.Text = "CARRYING: " .. string.upper(state.carrying)
		hint.Text = "Get home safely! Q returns the egg."
	elseif (state.eggs or 0) == 0 then hint.Text = "Hold E at the egg trail to buy an egg."
	elseif (state.bank or 0) > 0 then hint.Text = "Cash is waiting on your green collection pad!"
	else hint.Text = "Collect pets, earn cash, and steal rivals' eggs!" end
	if activeModal then showModal(activeModal) end
end
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.Q and state.carrying then send("drop") end
	if input.KeyCode == Enum.KeyCode.Escape and activeModal then showModal(nil) end
end)

task.spawn(function()
	local shared = ReplicatedStorage:WaitForChild("EggHeistShared", 30)
	local config = shared and shared:WaitForChild("Config", 10)
	if config then
		local ok, result = pcall(require, config)
		if ok and type(result) == "table" then catalog = result.Eggs or {} end
		if activeModal == "index" then showModal("index") end
	end
end)
task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("EggHeistRemotes", 30)
	if not remotes then notify({ text = "Game server did not start. Check Studio Output.", kind = "error" }) return end
	local stateRemote = remotes:WaitForChild("State", 10)
	local notifyRemote = remotes:WaitForChild("Notify", 10)
	local getState = remotes:WaitForChild("GetState", 10)
	actionRemote = remotes:WaitForChild("Action", 10)
	if not stateRemote or not notifyRemote or not getState or not actionRemote then notify({ text = "Server connection incomplete. Check Output.", kind = "error" }) return end
	stateRemote.OnClientEvent:Connect(render)
	notifyRemote.OnClientEvent:Connect(notify)
	for _ = 1, 5 do
		local ok, initial = pcall(function() return getState:InvokeServer() end)
		if ok and type(initial) == "table" then render(initial) break end
		task.wait(1)
	end
end)
print("Egg Heist HUD ready. Buy, hatch, earn, and steal!")
