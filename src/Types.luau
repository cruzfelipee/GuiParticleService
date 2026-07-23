export type EmitterSettings = {
	Acceleration: Vector2,
	Color: ColorSequence,
	Drag: number,
	EmissionDirection: Enum.NormalId,
	Enabled: boolean,

	--TODO: Flipbooks
	-- FlipbookBlendFrames: boolean,
	-- FlipbookFramerate: NumberRange,
	-- FlipbookIncompatible: string,
	-- FlipbookLayout: Enum.ParticleFlipbookLayout,
	-- FlipbookMode: Enum.ParticleFlipbookMode,
	-- FlipbookSizeX: number,
	-- FlipbookSizeY: number,
	-- FlipbookStartRandom: boolean,

	Lifetime: NumberRange,
	LockedToPart: boolean,
	Orientation: Enum.ParticleOrientation, --TODO
	Rate: number,
	Rotation: NumberRange,
	RotSpeed: NumberRange,

	--TODO: Emitter shape
	-- Shape: Enum.ParticleEmitterShape,
	-- ShapeInOut: Enum.ParticleEmitterShapeInOut,
	-- ShapePartial: number,
	-- ShapeStyle: Enum.ParticleEmitterShapeStyle,

	Size: NumberSequence,
	Speed: NumberRange,
	SpreadAngle: number,
	Squash: NumberSequence, --TODO
	Texture: string,
	TimeScale: number,
	Transparency: NumberSequence,

	ZOffset: number,

	Parent: GuiBase2d,
}

export type Particle = {
	startVelocity: Vector2,
	startPosition: Vector2,

	spawnTime: number,
	lifetime: number,
	currentTween: Tween?,

	particleImage: ImageLabel,
}

export type Emitter = {
	properties: EmitterSettings,
	renderedParticles: { Particle },
	polledParticles: { ImageLabel },
	emitTimeAccumulator: number,

	Emit: (self: Emitter, count: number) -> (),
	Clear: (self: Emitter) -> (),
	Destroy: (self: Emitter) -> (),
	StepAll: (self: Emitter) -> (),
}

return {}
