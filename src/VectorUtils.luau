local VectorUtils = {}

function VectorUtils.rotateVector(vector: Vector2, angle: number): Vector2
	local cosine = math.cos(angle)
	local sine = math.sin(angle)

	return Vector2.new(vector.X * cosine - vector.Y * sine, vector.X * sine + vector.Y * cosine)
end

--[[
	Converts between a GUI object's rotated local coordinates and screen coordinates.
]]
function VectorUtils.getScreenPosition(
	localPosition: Vector2,
	parentSize: Vector2,
	parentPosition: Vector2,
	parentRotation: number
): Vector2
	local halfSize = parentSize * 0.5
	local center = parentPosition + halfSize

	return center + VectorUtils.rotateVector(localPosition - halfSize, math.rad(parentRotation))
end

function VectorUtils.getLocalPosition(
	screenPosition: Vector2,
	parentSize: Vector2,
	parentPosition: Vector2,
	parentRotation: number
): Vector2
	local halfSize = parentSize * 0.5
	local center = parentPosition + halfSize

	return halfSize + VectorUtils.rotateVector(screenPosition - center, -math.rad(parentRotation))
end

return VectorUtils
