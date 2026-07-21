local ProjectilesService = require(script.ProjectilesService)
local ProjectileType = require(script.ProjectileType)

local function calculatePosition(
	startPosition: Vector3,
	startVelocity: Vector3,
	acceleration: Vector3,
	time: number
): Vector3
	return startPosition + startVelocity * time + acceleration * (time ^ 2) / 2
end

local Projectile = {} :: ProjectileType.Projectile
Projectile.__index = Projectile

--[[
    Creates a new projectile with physics-based motion

    @param startPosition The initial position of the projectile in world space
    @param startVelocity The initial velocity vector of the projectile in studs/second
    @param acceleration Optional acceleration vector applied over time (default: Vector3.zero)
    @param lifetime Optional duration in seconds before the projectile expires (default: 5)
    @return A new projectile instance
]]
function Projectile.new(
	startPosition: Vector3,
	startVelocity: Vector3,
	acceleration: Vector3,
	lifetime: number
): ProjectileType.Projectile
	local self = setmetatable({} :: ProjectileType.Projectile, Projectile)

	-- sets all necessary fields
	self.startPosition = startPosition
	self.startVelocity = startVelocity
	self.acceleration = acceleration
	self.lifetime = lifetime

	return self :: ProjectileType.Projectile
end

--[[
	Starts the projectile's motion

	@param self The projectile instance
]]
function Projectile.Start(self: ProjectileType.Projectile)
	self.startTime = tick()

	ProjectilesService.registerProjectile(self)
end

--[[
	Steps the projectile's motion forward in time by deltaTime seconds

	@param self The projectile instance
	@param deltaTime The time in seconds to step forward
]]
function Projectile.Step(self: ProjectileType.Projectile, deltaTime: number)
	local currentTime = tick()

	local elapsed = currentTime - self.startTime

	if elapsed >= self.lifetime then
		self:Destroy()
		return
	end

	local currentPosition = calculatePosition(self.startPosition, self.startVelocity, self.acceleration, elapsed)

	local lastPosition =
		calculatePosition(self.startPosition, self.startVelocity, self.acceleration, elapsed - deltaTime)

	local raycast

	if self.radius > 0 then
		raycast = workspace:Spherecast(lastPosition, self.radius, currentPosition - lastPosition, self.raycastParams)
	else
		raycast = workspace:Raycast(lastPosition, currentPosition - lastPosition, self.raycastParams)
	end

	if raycast then
		self.onHit(raycast, self.startVelocity + self.acceleration * elapsed)

		if not self.pierces then
			self:Destroy()
		end

		return
	end

	self.onStep(lastPosition, currentPosition, deltaTime)
end

--[[
	Deflects the projectile's velocity based on a surface normal

	@param self The projectile instance
	@param normal The surface normal to deflect against
]]
function Projectile.Deflect(self: ProjectileType.Projectile, normal: Vector3)
	local elapsed = tick() - self.startTime

	local velocity = self.startVelocity + self.acceleration * elapsed

	local reflectedVelocity = velocity - 2 * velocity:Dot(normal) * normal
	if reflectedVelocity.Magnitude == 0 then
		reflectedVelocity = normal * self.startVelocity.Magnitude
	end

	local currentPosition = calculatePosition(self.startPosition, self.startVelocity, self.acceleration, elapsed)

	self.startPosition = currentPosition + normal * self.radius
	self.startVelocity = reflectedVelocity
	self.lifetime = math.max(self.lifetime - elapsed, 0)
	self.startTime = tick()
end

--[[
	Stops projectile motion and removes it from the simulation

	@param self The projectile instance
]]
function Projectile.Destroy(self: ProjectileType.Projectile)
	ProjectilesService.removeProjectile(self)

	self.onDestroy()
end

return Projectile
