local EggVisual = {}

local function part(model, name, size, cf, color, shape)
	local p = Instance.new(shape == "Wedge" and "WedgePart" or "Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	if shape ~= "Wedge" then p.Shape = shape or Enum.PartType.Block end
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Parent = model
	return p
end

function EggVisual.create(definition, position, hatched, parent)
	local model = Instance.new("Model")
	model.Name = definition.id .. (hatched and "_Pet" or "_Egg")
	local color = Color3.fromRGB(unpack(definition.color))
	local cf = CFrame.new(position)
	local body = part(model, "Body", hatched and Vector3.new(2.8, 2.4, 2.6) or Vector3.new(2.7, 3.5, 2.7), cf, color, Enum.PartType.Ball)
	model.PrimaryPart = body
	if hatched then
		local pale = color:Lerp(Color3.new(1, 1, 1), 0.45)
		if definition.id == "meadow" then
			for _, side in ipairs({ -1, 1 }) do
				part(model, "BunnyEar", Vector3.new(0.65, 2, 0.7), cf * CFrame.new(side * 0.8, 1.6, 0) * CFrame.Angles(0, 0, -side * 0.2), color, Enum.PartType.Ball)
				part(model, "InnerEar", Vector3.new(0.3, 1.1, 0.15), cf * CFrame.new(side * 0.8, 1.7, -0.32), pale, Enum.PartType.Ball)
			end
			part(model, "FluffyTail", Vector3.new(1, 1, 1), cf * CFrame.new(0, -0.2, 1.3), pale, Enum.PartType.Ball)
		elseif definition.id == "ocean" then
			for _, side in ipairs({ -1, 1 }) do
				for i = 1, 3 do
					part(model, "AxolotlGill", Vector3.new(1.1, 0.3, 0.35), cf * CFrame.new(side * 1.5, (i - 2) * 0.45 + 0.3, -0.35) * CFrame.Angles(0, 0, side * (i - 2) * 0.45), Color3.fromRGB(255, 164, 209), Enum.PartType.Ball)
				end
			end
			part(model, "SwimmingTail", Vector3.new(0.55, 0.8, 2.4), cf * CFrame.new(0, -0.15, 1.9), pale, Enum.PartType.Ball)
		elseif definition.id == "cosmic" then
			for _, side in ipairs({ -1, 1 }) do
				part(model, "FoxEar", Vector3.new(1, 1.4, 0.8), cf * CFrame.new(side * 0.8, 1.25, -0.2) * CFrame.Angles(0, 0, side * 0.4), color, "Wedge")
			end
			part(model, "FoxTail", Vector3.new(1.4, 1.2, 2.5), cf * CFrame.new(0.7, 0, 1.8) * CFrame.Angles(0, -0.4, 0), pale, Enum.PartType.Ball)
		else
			-- Winged silhouettes distinguish the two highest rarities.
			for _, side in ipairs({ -1, 1 }) do
				local wing = part(model, "Wing", Vector3.new(2.3, 1.8, 0.5), cf * CFrame.new(side * 2, 0.4, 0.4) * CFrame.Angles(0.25, side * 0.4, side * 0.4), pale, "Wedge")
				wing.Material = Enum.Material.Neon
				part(model, "CrownHorn", Vector3.new(0.4, 1.3, 0.5), cf * CFrame.new(side * 0.7, 1.4, 0.1) * CFrame.Angles(-0.2, 0, -side * 0.3), Color3.fromRGB(255, 222, 83), "Wedge")
			end
			part(model, "Tail", Vector3.new(0.65, 0.65, 2.4), cf * CFrame.new(0, -0.1, 2), color, Enum.PartType.Ball)
		end
		for _, side in ipairs({ -1, 1 }) do
			part(model, "Eye", Vector3.new(0.3, 0.45, 0.18), cf * CFrame.new(side * 0.56, 0.25, -1.22), Color3.fromRGB(27, 32, 52), Enum.PartType.Ball)
			part(model, "EyeShine", Vector3.new(0.1, 0.12, 0.1), cf * CFrame.new(side * 0.56 - 0.05, 0.35, -1.3), Color3.new(1, 1, 1), Enum.PartType.Ball)
			part(model, "Paw", Vector3.new(0.8, 0.5, 0.9), cf * CFrame.new(side * 0.8, -1, -0.7), color:Lerp(Color3.new(1, 1, 1), 0.35), Enum.PartType.Ball)
		end
		part(model, "Nose", Vector3.new(0.3, 0.22, 0.2), cf * CFrame.new(0, -0.05, -1.3), Color3.fromRGB(255, 172, 185), Enum.PartType.Ball)
	else
		for i = 1, 7 do
			local angle = i * 2.4
			part(model, "ShellSpot", Vector3.new(0.5, 0.7, 0.3), cf * CFrame.new(math.sin(angle) * 1.1, (i % 3 - 1) * 0.65, math.cos(angle) * 1.1) * CFrame.Angles(0, angle, 0), color:Lerp(Color3.new(1, 1, 1), 0.55), Enum.PartType.Ball)
		end
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "EggLabel"
	gui.Size = UDim2.fromOffset(210, 92)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 100
	gui.Parent = body
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.25)
	text.TextStrokeTransparency = 0.2
	text.TextStrokeColor3 = Color3.fromRGB(22, 28, 47)
	text.Font = Enum.Font.GothamBold
	text.TextSize = 15
	text.Parent = gui
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "EggInteract"
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0.4
	prompt.Parent = body
	model.Parent = parent
	return model, text, prompt
end

return EggVisual
