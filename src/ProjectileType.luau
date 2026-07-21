export type Projectile = {
	startPosition: Vector3,
	startVelocity: Vector3,
	acceleration: Vector3,
	lifetime: number,
	raycastParams: RaycastParams?,
	radius: number,
	pierces: boolean,
	startTime: number,

	onStep: (lastPosition: Vector3, newPosition: Vector3, deltaTime: number) -> (),
	onHit: (raycast: RaycastResult, velocity: Vector3) -> (),
	onDestroy: () -> (),

	new: (
		startPosition: Vector3,
		startVelocity: Vector3,
		acceleration: Vector3,
		lifetime: number
	) -> Projectile,
	Start: (self: Projectile) -> (),
	Step: (self: Projectile, deltaTime: number) -> (),
	Deflect: (self: Projectile, newVelocity: Vector3) -> (),
	Destroy: (self: Projectile) -> (),

	__index: Projectile,
}

return {}
