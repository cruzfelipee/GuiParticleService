local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GuiParticleService = require(ReplicatedStorage.GuiParticleService)

local PARTICLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GuiParticleServiceDemo"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(17, 19, 30)
background.BorderSizePixel = 0
background.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -48, 0, 58)
title.Position = UDim2.fromOffset(24, 20)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "GuiParticleService demo"
title.TextColor3 = Color3.fromRGB(240, 244, 255)
title.TextSize = 28
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = background

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -48, 0, 28)
subtitle.Position = UDim2.fromOffset(24, 68)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "Six continuously emitting GUI particle effects"
subtitle.TextColor3 = Color3.fromRGB(158, 170, 200)
subtitle.TextSize = 16
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = background

local function makeParticleArea(name: string, position: UDim2, color: Color3): Frame
	local area = Instance.new("Frame")
	area.Name = name
	area.AnchorPoint = Vector2.new(0.5, 0.5)
	area.Size = UDim2.fromOffset(250, 250)
	area.Position = position
	area.BackgroundColor3 = color:Lerp(Color3.fromRGB(28, 31, 48), 0.8)
	area.BorderSizePixel = 0
	area.ClipsDescendants = false
	area.Parent = background

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = area

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -24, 0, 32)
	label.Position = UDim2.fromOffset(12, 12)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = name
	label.TextColor3 = Color3.fromRGB(235, 238, 255)
	label.TextSize = 18
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 2
	label.Parent = area

	return area
end

local function addEmitterControls(area: Frame, emitter)
	local clearButton = Instance.new("TextButton")
	clearButton.Size = UDim2.new(1, -24, 0, 28)
	clearButton.Position = UDim2.fromOffset(12, 168)
	clearButton.BackgroundColor3 = Color3.fromRGB(76, 49, 68)
	clearButton.BorderSizePixel = 0
	clearButton.Font = Enum.Font.GothamMedium
	clearButton.Text = "Clear"
	clearButton.TextColor3 = Color3.fromRGB(255, 232, 240)
	clearButton.TextSize = 14
	clearButton.ZIndex = 3
	clearButton.Parent = area

	local clearCorner = Instance.new("UICorner")
	clearCorner.CornerRadius = UDim.new(0, 6)
	clearCorner.Parent = clearButton

	local countInput = Instance.new("TextBox")
	countInput.Size = UDim2.new(1, -108, 0, 32)
	countInput.Position = UDim2.fromOffset(12, 204)
	countInput.BackgroundColor3 = Color3.fromRGB(35, 39, 57)
	countInput.BorderSizePixel = 0
	countInput.ClearTextOnFocus = false
	countInput.Font = Enum.Font.Gotham
	countInput.PlaceholderText = "Particle count"
	countInput.PlaceholderColor3 = Color3.fromRGB(132, 140, 166)
	countInput.Text = "20"
	countInput.TextColor3 = Color3.fromRGB(240, 243, 255)
	countInput.TextSize = 14
	countInput.ZIndex = 3
	countInput.Parent = area

	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 6)
	inputCorner.Parent = countInput

	local emitButton = Instance.new("TextButton")
	emitButton.Size = UDim2.fromOffset(90, 32)
	emitButton.Position = UDim2.new(1, -102, 0, 204)
	emitButton.BackgroundColor3 = Color3.fromRGB(68, 102, 184)
	emitButton.BorderSizePixel = 0
	emitButton.Font = Enum.Font.GothamMedium
	emitButton.Text = "Emit"
	emitButton.TextColor3 = Color3.fromRGB(242, 246, 255)
	emitButton.TextSize = 14
	emitButton.ZIndex = 3
	emitButton.Parent = area

	local emitCorner = Instance.new("UICorner")
	emitCorner.CornerRadius = UDim.new(0, 6)
	emitCorner.Parent = emitButton

	clearButton.Activated:Connect(function()
		emitter:Clear()
	end)

	emitButton.Activated:Connect(function()
		local count = tonumber(countInput.Text)
		if count and count > 0 then
			emitter:Emit(math.floor(count))
		end
	end)
end

local embersArea = makeParticleArea("Rising embers", UDim2.fromScale(0.27, 0.4), Color3.fromRGB(244, 129, 45))
local rotatingArea = makeParticleArea("Rotating sparks", UDim2.fromScale(0.5, 0.4), Color3.fromRGB(106, 86, 228))
local snowArea = makeParticleArea("Falling snow", UDim2.fromScale(0.73, 0.4), Color3.fromRGB(98, 184, 255))
local sparksArea = makeParticleArea("Side sparks", UDim2.fromScale(0.27, 0.76), Color3.fromRGB(195, 111, 255))
local staticArea = makeParticleArea("Static stars (no tweens)", UDim2.fromScale(0.5, 0.76), Color3.fromRGB(84, 193, 208))
local rainbowArea = makeParticleArea("Rainbow confetti", UDim2.fromScale(0.73, 0.76), Color3.fromRGB(106, 86, 228))

local embers = GuiParticleService.start({
	Parent = embersArea,
	Texture = PARTICLE_TEXTURE,
	Rate = 24,
	Lifetime = NumberRange.new(1.2, 2.1),
	Speed = NumberRange.new(48, 100),
	EmissionDirection = Enum.NormalId.Top,
	SpreadAngle = 50,
	Acceleration = Vector2.new(0, 30),
	Drag = 1.5,
	Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 16, 5),
		NumberSequenceKeypoint.new(0.75, 9),
		NumberSequenceKeypoint.new(1, 2),
	}),
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	}),
	Color = ColorSequence.new(Color3.fromRGB(255, 232, 116), Color3.fromRGB(255, 76, 42)),
	RotSpeed = NumberRange.new(-140, 140),
	ZOffset = 3,
})

local rotating = GuiParticleService.start({
	Parent = rotatingArea,
	Texture = PARTICLE_TEXTURE,
	Rate = 30,
	Lifetime = NumberRange.new(2),
	Speed = NumberRange.new(80),
	EmissionDirection = Enum.NormalId.Top,
	SpreadAngle = 0,
	Acceleration = Vector2.zero,
	Size = NumberSequence.new(10),
	Transparency = NumberSequence.new(0),
	Color = ColorSequence.new(Color3.fromRGB(213, 166, 255), Color3.fromRGB(91, 74, 225)),
	RotSpeed = NumberRange.new(-180, 180),
	ZOffset = 3,
})

TweenService:Create(
	rotatingArea,
	TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1),
	{ Rotation = 360 }
):Play()

local snow = GuiParticleService.start({
	Parent = snowArea,
	Texture = PARTICLE_TEXTURE,
	Rate = 18,
	Lifetime = NumberRange.new(1.5, 2.6),
	Speed = NumberRange.new(35, 65),
	EmissionDirection = Enum.NormalId.Bottom,
	SpreadAngle = 28,
	Acceleration = Vector2.new(18, 8),
	Drag = 0.2,
	Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 7, 3),
		NumberSequenceKeypoint.new(1, 13, 3),
	}),
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.15, 0),
		NumberSequenceKeypoint.new(0.8, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	}),
	Color = ColorSequence.new(Color3.fromRGB(220, 242, 255)),
	Rotation = NumberRange.new(0, 0),
	RotSpeed = NumberRange.new(-25, 25),
	ZOffset = 3,
})

local rainbow = GuiParticleService.start({
	Parent = rainbowArea,
	Texture = PARTICLE_TEXTURE,
	Rate = 100,
	Lifetime = NumberRange.new(1.5, 2),
	Speed = NumberRange.new(70, 130),
	EmissionDirection = Enum.NormalId.Top,
	SpreadAngle = 130,
	Acceleration = Vector2.new(0, 190),
	Drag = 1,
	Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 30),
		NumberSequenceKeypoint.new(0.8, 20),
		NumberSequenceKeypoint.new(1, 0),
	}),
	Transparency = NumberSequence.new(0),
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 222, 255)),
		ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
	}),
	RotSpeed = NumberRange.new(-240, 240),
	ZOffset = 3,
})

-- This converted emitter uses single-value sequences, so its particles do not create visual tweens.
local staticSource = Instance.new("ParticleEmitter")
staticSource.Name = "StaticStarsSource"
staticSource.Texture = PARTICLE_TEXTURE
staticSource.Rate = 12
staticSource.Lifetime = NumberRange.new(2.5, 4)
staticSource.Speed = NumberRange.new(18, 36)
staticSource.EmissionDirection = Enum.NormalId.Top
staticSource.SpreadAngle = Vector2.new(110, 0)
staticSource.Acceleration = Vector3.new(0, 45, 0)
staticSource.Drag = 0.2
staticSource.Size = NumberSequence.new(9)
staticSource.Transparency = NumberSequence.new(0.15)
staticSource.Color = ColorSequence.new(Color3.fromRGB(153, 240, 255))
staticSource.Rotation = NumberRange.new(0, 0)
staticSource.RotSpeed = NumberRange.new(0, 0)
staticSource.ZOffset = 3
staticSource.Parent = staticArea

local staticStars = GuiParticleService.fromEmitter(staticSource, nil, true)

-- This emitter is converted to a 2D GUI emitter by GuiParticleService.fromEmitter.
local sparksSource = Instance.new("ParticleEmitter")
sparksSource.Name = "SparksSource"
sparksSource.Texture = PARTICLE_TEXTURE
sparksSource.Rate = 20
sparksSource.Lifetime = NumberRange.new(0.7, 1.25)
sparksSource.Speed = NumberRange.new(90, 145)
sparksSource.EmissionDirection = Enum.NormalId.Right
-- fromEmitter converts the native Vector2 spread to a scalar using its magnitude.
sparksSource.SpreadAngle = Vector2.new(70, 0)
sparksSource.Acceleration = Vector3.new(-55, 25, 0)
sparksSource.Drag = 2
sparksSource.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 12, 4),
	NumberSequenceKeypoint.new(1, 1),
})
sparksSource.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.65, 0.2),
	NumberSequenceKeypoint.new(1, 1),
})
sparksSource.Color = ColorSequence.new(Color3.fromRGB(242, 194, 255), Color3.fromRGB(143, 89, 255))
sparksSource.RotSpeed = NumberRange.new(-300, 300)
sparksSource.ZOffset = 3
sparksSource.Parent = sparksArea

local sparks = GuiParticleService.fromEmitter(sparksSource, nil, true)

addEmitterControls(embersArea, embers)
addEmitterControls(rotatingArea, rotating)
addEmitterControls(snowArea, snow)
addEmitterControls(sparksArea, sparks)
addEmitterControls(staticArea, staticStars)
addEmitterControls(rainbowArea, rainbow)

-- Add a visible burst immediately, so the demo has particles before the first rate-based emissions.
embers:Emit(20)
rotating:Emit(16)
snow:Emit(16)
sparks:Emit(20)
rainbow:Emit(16)
staticStars:Emit(16)
