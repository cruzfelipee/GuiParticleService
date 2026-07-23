const MAX_EMISSION_DELTA_TIME = 1 / 60 --maximum frame time to use for emission calculations, to avoid large bursts of particles when the framerate drops
const VELOCITY_ANGLES = {
	[Enum.NormalId.Top] = math.rad(-90),
	[Enum.NormalId.Bottom] = math.rad(90),
	[Enum.NormalId.Left] = math.rad(180),
	[Enum.NormalId.Right] = math.rad(0),
}
const DRAG_EPSILON = 1e-6 --minimum drag magnitude to avoid divisions with numbers close to zero, which can cause large displacements due to floating point precision

const RunService = game:GetService("RunService")

local InterpolationUtils = require(script.InterpolationUtils)
const TweenParticleUtils = require(script.TweenParticleUtils)
const Types = require(script.Types)
const VectorUtils = require(script.VectorUtils)

type BaseEmitterParameters = {
	Acceleration: Vector2?,
	Color: ColorSequence?,
	Drag: number?,
	EmissionDirection: Enum.NormalId?,
	Enabled: boolean?,

	-- FlipbookBlendFrames: boolean?,
	-- FlipbookFramerate: NumberRange?,
	-- FlipbookIncompatible: string?,
	-- FlipbookLayout: Enum.ParticleFlipbookLayout?,
	-- FlipbookMode: Enum.ParticleFlipbookMode?,
	-- FlipbookSizeX: number?,
	-- FlipbookSizeY: number?,
	-- FlipbookStartRandom: boolean?,

	Lifetime: NumberRange?,
	LockedToPart: boolean?,
	Orientation: Enum.ParticleOrientation?,
	Rate: number?,
	Rotation: NumberRange?,
	RotSpeed: NumberRange?,

	-- Shape: Enum.ParticleEmitterShape?,
	-- ShapeInOut: Enum.ParticleEmitterShapeInOut?,
	-- ShapePartial: number?,
	-- ShapeStyle: Enum.ParticleEmitterShapeStyle?,

	Size: NumberSequence?,
	Speed: NumberRange?,
	SpreadAngle: number?,
	Squash: NumberSequence?,
	Texture: string?,
	TimeScale: number?,
	Transparency: NumberSequence?,

	ZOffset: number?,
}

type OptionalParentEmitterParameters = BaseEmitterParameters & {
	Parent: GuiBase2d?,
}

type ParentedEmitterParameters = BaseEmitterParameters & {
	Parent: GuiBase2d,
}

local emitters: { Types.Emitter } = {}

--[[
	Calculates the position of a particle at a given time, based on its motion parameters
]]
const function getPosition(
	startPosition: Vector2,
	elapsedTime: number,
	startVelocity: Vector2,
	acceleration: Vector2,
	drag: number
): Vector2
	if math.abs(drag) < DRAG_EPSILON then
		return startPosition + startVelocity * elapsedTime + 0.5 * acceleration * elapsedTime ^ 2
	end

	local decayRate = drag * math.log(2)
	local decay = math.exp(-decayRate * elapsedTime)
	local decayIntegral = (1 - decay) / decayRate

	local velocityDisplacement = startVelocity * decayIntegral

	local accelerationDisplacement = acceleration * (elapsedTime / decayRate - decayIntegral / decayRate)

	return startPosition + velocityDisplacement + accelerationDisplacement
end

local GuiParticleService = {}

--[[
	Starts a new emitter with the given parameters. The emitter will continue to emit emitter.properties.Rate particles per second until it is either destroyed or disabled.
	
	@param emitterParameters The parameters to use for the emitter.
	@return An Emitter object that can be used to control the emitter.
]]
function GuiParticleService.start(emitterParameters: ParentedEmitterParameters): Types.Emitter
	local emitter: Types.Emitter = {
		properties = {
			Acceleration = emitterParameters.Acceleration or Vector2.new(0, 0),
			Color = emitterParameters.Color or ColorSequence.new(Color3.fromRGB(255, 255, 255)),
			Drag = emitterParameters.Drag or 0,
			EmissionDirection = emitterParameters.EmissionDirection or Enum.NormalId.Top,
			Enabled = if emitterParameters.Enabled == nil then true else emitterParameters.Enabled,

			Lifetime = emitterParameters.Lifetime or NumberRange.new(1, 1),
			LockedToPart = emitterParameters.LockedToPart or false,
			Orientation = emitterParameters.Orientation or Enum.ParticleOrientation.VelocityPerpendicular,
			Rate = emitterParameters.Rate or 10,
			Rotation = emitterParameters.Rotation or NumberRange.new(0, 360),
			RotSpeed = emitterParameters.RotSpeed or NumberRange.new(-90, 90),

			Size = emitterParameters.Size or NumberSequence.new(1),
			Speed = emitterParameters.Speed or NumberRange.new(10, 10),
			SpreadAngle = emitterParameters.SpreadAngle or 0,
			Squash = emitterParameters.Squash or NumberSequence.new(1),
			Texture = emitterParameters.Texture or "",
			TimeScale = emitterParameters.TimeScale or 1,
			Transparency = emitterParameters.Transparency or NumberSequence.new(0),

			ZOffset = emitterParameters.ZOffset or 0,

			Parent = emitterParameters.Parent,
		},

		renderedParticles = {},
		polledParticles = {},
		emitTimeAccumulator = 0,

		Emit = function(self, count)
			local parent = self.properties.Parent
			local absoluteSize = parent.AbsoluteSize
			local absolutePosition = parent.AbsolutePosition
			local absoluteRotation = parent.AbsoluteRotation

			local emissionAngle = VELOCITY_ANGLES[self.properties.EmissionDirection]
			assert(emissionAngle, "EmissionDirection must be Top, Bottom, Left or Right")

			if not self.properties.LockedToPart then
				emissionAngle += math.rad(absoluteRotation)
			end

			for _ = 1, count do
				local image = table.remove(self.polledParticles)
				if not image then
					if #self.renderedParticles > 0 then --clones an existing particle instead of creating a new one from scratch
						image = self.renderedParticles[1].particleImage:Clone()
					else
						local newImage = Instance.new("ImageLabel")
						newImage.Image = self.properties.Texture
						newImage.BackgroundTransparency = 1
						newImage.AnchorPoint = Vector2.new(0.5, 0.5)
						newImage.ZIndex = self.properties.ZOffset

						image = newImage
					end
				end

				assert(image)

				local speed = InterpolationUtils.getNumberInRange(self.properties.Speed, math.random())
				local spreadAngle = math.rad(self.properties.SpreadAngle * (math.random() - 0.5))

				local localStartPosition = Vector2.new(math.random() * absoluteSize.X, math.random() * absoluteSize.Y)
				local particle: Types.Particle = {
					startPosition = if self.properties.LockedToPart
						then localStartPosition
						else VectorUtils.getScreenPosition(
							localStartPosition,
							absoluteSize,
							absolutePosition,
							absoluteRotation
						),
					startVelocity = Vector2.new(
						speed * math.cos(emissionAngle + spreadAngle),
						speed * math.sin(emissionAngle + spreadAngle)
					),
					spawnTime = tick(),
					particleImage = image,
					lifetime = InterpolationUtils.getNumberInRange(self.properties.Lifetime, math.random()),
					currentTween = nil,
				}

				table.insert(self.renderedParticles, particle)

				debug.profilebegin("getParticleTween")
				local tween = TweenParticleUtils.getParticleTween(self, particle)
				if tween then
					particle.currentTween = tween
					tween:Play()
				end
				debug.profileend()

				image.Visible = true
				image.Parent = self.properties.Parent
			end
		end,

		Clear = function(self)
			for _, v in self.renderedParticles do
				if v.currentTween then
					v.currentTween:Cancel()
					v.currentTween = nil
				end

				table.insert(self.polledParticles, v.particleImage)

				v.particleImage.Visible = false
			end

			table.clear(self.renderedParticles)
		end,

		Destroy = function(self)
			self:Clear()

			for _, v in self.polledParticles do
				v:Destroy()
			end

			local index = table.find(emitters, self)

			assert(index, "Emitter was already destroyed")

			table.remove(emitters, index)
		end,

		StepAll = function(self)
			local absoluteSize = self.properties.Parent.AbsoluteSize
			local absolutePosition = self.properties.Parent.AbsolutePosition
			local absoluteRotation = self.properties.Parent.AbsoluteRotation

			for i, v in self.renderedParticles do
				local timeAlive = tick() * self.properties.TimeScale - v.spawnTime * self.properties.TimeScale

				if timeAlive >= v.lifetime then
					table.insert(self.polledParticles, v.particleImage)

					v.particleImage.Visible = false

					table.remove(self.renderedParticles, i)
					continue
				end

				local position = getPosition(
					v.startPosition,
					timeAlive,
					v.startVelocity,
					self.properties.Acceleration,
					self.properties.Drag
				)

				if self.properties.LockedToPart then
					v.particleImage.Position = UDim2.fromOffset(position.X, position.Y)
				else
					local localPosition = VectorUtils.getLocalPosition(position, absoluteSize, absolutePosition, absoluteRotation)
					v.particleImage.Position = UDim2.fromOffset(localPosition.X, localPosition.Y)
				end
			end
		end,
	}

	table.insert(emitters, emitter)

	return emitter
end

--[[
	Starts a new emitter using the properties of a Roblox ParticleEmitter.

	@param particleEmitter The ParticleEmitter to convert into a GuiParticleService Emitter.
	@param _emitterParameters Optional parameters to override the properties of the ParticleEmitter.
	@param bound If true, the Emitter will attempt to update its properties when the ParticleEmitter's properties change to match the original emitter. Destroying the original emitter will destroy the GuiParticleService Emitter. Defaults to false.
	@return An Emitter object that can be used to control the emitter.
]]
function GuiParticleService.fromEmitter(
	particleEmitter: ParticleEmitter,
	_emitterParameters: OptionalParentEmitterParameters?,
	bound: boolean?
): Types.Emitter
	assert(
		particleEmitter.Parent,
		"Particle Emitter must be parented to a GuiBase2d to be converted into a GuiParticleService Emitter"
	)
	assert(
		particleEmitter.Parent:IsA("GuiBase2d"),
		"Particle Emitter must be parented to a GuiBase2d to be converted into a GuiParticleService Emitter"
	)

	local emitterParameters: OptionalParentEmitterParameters = _emitterParameters or {}

	local emitter = GuiParticleService.start({
		Acceleration = emitterParameters.Acceleration
			or Vector2.new(particleEmitter.Acceleration.X, particleEmitter.Acceleration.Y),
		Color = emitterParameters.Color or particleEmitter.Color,
		Drag = emitterParameters.Drag or particleEmitter.Drag,
		EmissionDirection = emitterParameters.EmissionDirection or particleEmitter.EmissionDirection,
		Enabled = if emitterParameters.Enabled ~= nil then emitterParameters.Enabled else particleEmitter.Enabled,

		Lifetime = emitterParameters.Lifetime or particleEmitter.Lifetime,
		LockedToPart = if emitterParameters.LockedToPart ~= nil
			then emitterParameters.LockedToPart
			else particleEmitter.LockedToPart,
		Orientation = emitterParameters.Orientation or particleEmitter.Orientation,
		Rate = emitterParameters.Rate or particleEmitter.Rate,
		Rotation = emitterParameters.Rotation or particleEmitter.Rotation,
		RotSpeed = emitterParameters.RotSpeed or particleEmitter.RotSpeed,

		Size = emitterParameters.Size or particleEmitter.Size,
		Speed = emitterParameters.Speed or particleEmitter.Speed,
		SpreadAngle = emitterParameters.SpreadAngle or particleEmitter.SpreadAngle.Magnitude,
		Squash = emitterParameters.Squash or particleEmitter.Squash,
		Texture = emitterParameters.Texture or particleEmitter.Texture,
		TimeScale = emitterParameters.TimeScale or particleEmitter.TimeScale,
		Transparency = emitterParameters.Transparency or particleEmitter.Transparency,

		ZOffset = emitterParameters.ZOffset or particleEmitter.ZOffset,

		Parent = emitterParameters.Parent or particleEmitter.Parent,
	})

	if bound then
		particleEmitter.Changed:Connect(function(property: string)
			local newValue = particleEmitter[property]

			if emitter.properties[property] == nil then
				return
			end

			if typeof(newValue) == typeof(emitter.properties[property]) then
				emitter.properties[property] = newValue
			else
				print(property, "needs to be manually converted")
			end
		end)

		particleEmitter.Destroying:Once(function()
			emitter:Destroy()
		end)
	end

	return emitter
end

--[[
	Counts the number of particles currently being rendered by all emitters

	@return The number of particles currently rendered in
]]
function GuiParticleService.getRenderedParticlesCount()
	local count = 0

	for _, v in emitters do
		count += #v.renderedParticles
	end

	return count
end

--[[
	Counts the number of particles currently pooled of all emitters

	@return The number of particles pooled
]]
function GuiParticleService.getPooledParticlesCount()
	local count = 0

	for _, v in emitters do
		count += #v.polledParticles
	end

	return count
end

--[[
	Counts the existing particles of all emitters, including both rendered and pooled particles

	@return The total number of particles
]]
function GuiParticleService.getTotalParticlesCount()
	local count = 0

	for _, v in emitters do
		count += #v.renderedParticles + #v.polledParticles
	end

	return count
end

--Controls the emission and updating of all emitters.
RunService:BindToRenderStep("UpdateGuiParticleServiceParticles", Enum.RenderPriority.Last.Value, function(delta: number)
	for _, v in emitters do
		debug.profilebegin("GuiParticleService.Emits")
		--Emits particles based on the emitter's rate and the time since the last frame.
		if v.properties.Enabled and v.properties.Rate > 0 then
			local finalDelta = math.min(delta * v.properties.TimeScale, MAX_EMISSION_DELTA_TIME) + v.emitTimeAccumulator

			v:Emit(v.properties.Rate * finalDelta)

			v.emitTimeAccumulator = finalDelta % (1 / v.properties.Rate)
		end
		debug.profileend()

		debug.profilebegin("GuiParticleService.StepAll")
		--Step all particles, updating their images properties to simulate particle-like behaviour.
		v:StepAll()
		debug.profileend()
	end
end)

return GuiParticleService
