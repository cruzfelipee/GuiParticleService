const TweenService = game:GetService("TweenService")

const InterpolationUtils = require(script.Parent.InterpolationUtils)
const Types = require(script.Parent.Types)

local TweenParticleUtils = {}

type ParticleTweenGoal = {
	ImageColor3: Color3,
	ImageTransparency: number,
	Size: UDim2,
	Rotation: number,
	[string]: any,
}

--[[
	Determine the state of the particle properties at each keypoint in the lifetime of the particle, based on the emitter's properties.
]]
function TweenParticleUtils.getParticleTweenGoals(emitter: Types.Emitter, lifetime: number)
	local transparencyEnvelope = math.random()
	local sizeEnvelope = math.random()
	local startRotation = InterpolationUtils.getNumberInRange(emitter.properties.Rotation, math.random())
	local rotationSpeed = InterpolationUtils.getNumberInRange(emitter.properties.RotSpeed, math.random())

	local goals: { [number]: ParticleTweenGoal } = {}

	for _, colorKeypoint in emitter.properties.Color.Keypoints do
		local size = InterpolationUtils.getNumberAtSequenceTime(emitter.properties.Size, colorKeypoint.Time, sizeEnvelope)
		goals[colorKeypoint.Time] = {
			ImageColor3 = colorKeypoint.Value,
			ImageTransparency = InterpolationUtils.getNumberAtSequenceTime(
				emitter.properties.Transparency,
				colorKeypoint.Time,
				transparencyEnvelope
			),
			Size = UDim2.fromOffset(size, size),
			Rotation = startRotation + rotationSpeed * colorKeypoint.Time * lifetime,
		}
	end

	for _, transparencyKeypoint in emitter.properties.Transparency.Keypoints do
		local size = InterpolationUtils.getNumberAtSequenceTime(emitter.properties.Size, transparencyKeypoint.Time, sizeEnvelope)
		goals[transparencyKeypoint.Time] = {
			ImageColor3 = InterpolationUtils.getColorAtSequenceTime(emitter.properties.Color, transparencyKeypoint.Time),
			ImageTransparency = transparencyKeypoint.Value,
			Size = UDim2.fromOffset(size, size),
			Rotation = startRotation + rotationSpeed * transparencyKeypoint.Time * lifetime,
		}
	end

	for _, sizeKeypoint in emitter.properties.Size.Keypoints do
		goals[sizeKeypoint.Time] = {
			ImageColor3 = InterpolationUtils.getColorAtSequenceTime(emitter.properties.Color, sizeKeypoint.Time),
			ImageTransparency = InterpolationUtils.getNumberAtSequenceTime(
				emitter.properties.Transparency,
				sizeKeypoint.Time,
				transparencyEnvelope
			),
			Size = UDim2.fromOffset(sizeKeypoint.Value, sizeKeypoint.Value),
			Rotation = startRotation + rotationSpeed * sizeKeypoint.Time * lifetime,
		}
	end

	return goals
end

--[[
	Creates a single tween chain to control some particle properties over its lifetime.
	The tween chain needs to be recreated for every particle since lifetime and envelopes are randomized per particle.
]]
function TweenParticleUtils.getParticleTween(emitter: Types.Emitter, particle: Types.Particle): Tween?
	local image = particle.particleImage

	debug.profilebegin("getParticleTweenGoals")
	local goals = TweenParticleUtils.getParticleTweenGoals(emitter, particle.lifetime)
	debug.profileend()

	local times = {}
	for time in goals do
		table.insert(times, time)
	end
	table.sort(times)

	local firstTween: Tween
	local lastTween: Tween

	for i, currentTime in times do
		local currentGoal = goals[currentTime]

		if i == 1 then --sets properties to start
			image.ImageTransparency = currentGoal.ImageTransparency
			image.Size = currentGoal.Size
			image.Rotation = currentGoal.Rotation
			image.ImageColor3 = currentGoal.ImageColor3

			continue
		end

		local lastTweenTime = times[i - 1]

		local currentTween = TweenService:Create(
			image,
			TweenInfo.new((currentTime - lastTweenTime) * particle.lifetime, Enum.EasingStyle.Linear),
			currentGoal
		) --seems to be the bottleneck of performance,

		firstTween = firstTween or currentTween

		if lastTween then
			lastTween.Completed:Once(function(playbackState)
				if playbackState == Enum.PlaybackState.Cancelled then
					return
				end

				particle.currentTween = currentTween
				currentTween:Play()
			end)
		end

		lastTween = currentTween
	end

	return firstTween
end

return TweenParticleUtils
