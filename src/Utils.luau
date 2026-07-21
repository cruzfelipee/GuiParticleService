local Utils = {}

function Utils.getNumberAtSequenceTime(sequence: NumberSequence, time: number, envelopeFactor: number?): number
	for i, v in sequence.Keypoints do
		if v.Time < time then --target time is after this keypoint, continue to next keypoint
			continue
		end

		if i == 1 then --target time is before or at the first keypoint, return the first keypoint's value
			return v.Value + v.Envelope * ((envelopeFactor or 0.5) - 0.5) * 2
		end

		local prev = sequence.Keypoints[i - 1]
		local t = (time - prev.Time) / (v.Time - prev.Time)
		local midEnvelope = math.lerp(prev.Envelope, v.Envelope, t)
		return math.lerp(prev.Value, v.Value, t) + midEnvelope * ((envelopeFactor or 0.5) - 0.5) * 2
	end

	return sequence.Keypoints[#sequence.Keypoints].Value
end

function Utils.getColorAtSequenceTime(sequence: ColorSequence, time: number): Color3
	for i, v in sequence.Keypoints do
		if v.Time < time then --target time is after this keypoint, continue to next keypoint
			continue
		end

		if i == 1 then --target time is before or at the first keypoint, return the first keypoint's value
			return v.Value
		end

		local prev = sequence.Keypoints[i - 1]
		local t = (time - prev.Time) / (v.Time - prev.Time)
		return prev.Value:Lerp(v.Value, t)
	end

	return sequence.Keypoints[#sequence.Keypoints].Value
end

function Utils.getNumberInRange(range: NumberRange, alpha: number)
	return math.lerp(range.Min, range.Max, alpha)
end

return Utils
