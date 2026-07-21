# GuiParticleService

GuiParticleService is a client-side Luau library for rendering animated particles inside Roblox UI. It aims to make GUI particles feel familiar to developers who use Roblox's built-in `ParticleEmitter`, while providing a small API for UI objects such as `Frame`, `ImageLabel`, and `ScreenGui` descendants.

## Features

- Emits reusable `ImageLabel` particles into any `GuiBase2d` parent.
- Continuous, rate-based emission and one-shot bursts with `:Emit()`.
- Particle motion with speed, spread, acceleration, and drag.
- `ColorSequence`, `NumberSequence`, and `NumberRange` support for gradual visual changes and randomized values.
- Configurable lifetime, rotation, rotation speed, transparency, size, texture, and Z offset.
- Choose whether particles move with their parent UI object (`LockedToPart`).
- Create an emitter from a Roblox `ParticleEmitter` with `fromEmitter`, optionally keeping compatible properties synchronized.
- Pools finished particle instances to reduce allocations during repeated emission.

## Requirements

- Roblox Studio
- A client-side `LocalScript` or UI controller. GuiParticleService updates particles through `RunService:BindToRenderStep`.
- [Wally](https://wally.run/) is recommended for package installation.

## Installation

### Wally

Add the package to your project's `wally.toml`:

```toml
[dependencies]
GuiParticleService = "cruzfelipee/gui_particle_service@0.1.0"
```

Install dependencies:

```sh
wally install
```

Then require the installed package from the location used by your project. A typical Rojo setup looks like this:

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiParticleService = require(ReplicatedStorage.Packages.GuiParticleService)
```

### Manual installation

Copy the contents of `src` into your project and require `init.luau` as a ModuleScript. Keep `Utils.luau` as a child/sibling ModuleScript named `Utils`, since the main module requires `script.Utils`.

## Usage

Create an emitter by supplying at least a GUI parent. The emitter begins emitting immediately unless `Enabled` is set to `false`.

```luau
local GuiParticleService = require(path.to.GuiParticleService)

local emitter = GuiParticleService.start({
	Parent = script.Parent.ParticleArea,
	Texture = "rbxassetid://1234567890",
	Rate = 20,
	Lifetime = NumberRange.new(0.75, 1.25),
	Speed = NumberRange.new(60, 120),
	EmissionDirection = Enum.NormalId.Top,
	SpreadAngle = 40,
	Acceleration = Vector2.new(0, 80),
	Drag = 1,
	Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 12),
		NumberSequenceKeypoint.new(1, 3),
	}),
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0),
		NumberSequenceKeypoint.new(1, 1),
	}),
	Color = ColorSequence.new(Color3.fromRGB(255, 219, 117)),
})

-- Emit a one-shot burst in addition to the continuous Rate emission.
emitter:Emit(30)

-- Pause/resume continuous emission.
emitter.properties.Enabled = false
emitter.properties.Enabled = true

-- Release pooled and active particle instances when they are no longer needed.
emitter:Destroy()
```

### Creating from a `ParticleEmitter`

`fromEmitter` maps the supported settings of an existing `ParticleEmitter` to a GUI emitter. The source `ParticleEmitter` must be parented to a `GuiBase2d`. Pass `true` as the third argument to synchronize compatible property changes and destroy the GUI emitter when the source emitter is destroyed.

```luau
local guiEmitter = GuiParticleService.fromEmitter(
	script.Parent.ParticleEmitter,
	{
		Parent = script.Parent.ParticleArea,
		Rate = 35, -- optional override
	},
	true
)
```

When supplying the overrides table, include `Parent`; otherwise the emitter has no GUI target. If no overrides are needed, `GuiParticleService.fromEmitter(sourceEmitter)` uses the source emitter's GUI parent.

## Emitter API

| Member | Description |
| --- | --- |
| `GuiParticleService.start(parameters)` | Creates and registers a GUI emitter. |
| `GuiParticleService.fromEmitter(particleEmitter, overrides?, bound?)` | Creates an emitter from supported `ParticleEmitter` properties. |
| `emitter:Emit(count)` | Immediately creates `count` particles. |
| `emitter:Clear()` | Removes active particles and retains them for reuse. |
| `emitter:Destroy()` | Clears the emitter, destroys its pooled particles, and unregisters it. |
| `emitter.properties` | Mutable table containing the emitter configuration. |

## Configuration

All settings are passed to `start` and can later be changed through `emitter.properties`.

| Property | Type | Default | Notes |
| --- | --- | --- | --- |
| `Parent` | `GuiBase2d` | required | UI object that receives the particle `ImageLabel`s. |
| `Texture` | `string` | `""` | Image asset ID or content URI. |
| `Enabled` | `boolean` | `true` | Controls continuous rate emission. |
| `Rate` | `number` | `10` | Positive number of particles emitted per second. |
| `Lifetime` | `NumberRange` | `NumberRange.new(1, 1)` | Particle lifespan in seconds. |
| `Speed` | `NumberRange` | `NumberRange.new(10, 10)` | Initial speed in pixels per second. |
| `EmissionDirection` | `Enum.NormalId` | `Top` | Supports `Top`, `Bottom`, `Left`, and `Right`. |
| `SpreadAngle` | `number` | `0` | Angular spread around the emission direction, in degrees. |
| `Acceleration` | `Vector2` | `Vector2.zero` | Acceleration in UI pixels per second squared. |
| `Drag` | `number` | `0` | Exponential velocity drag. |
| `Color` | `ColorSequence` | white | Particle colour over its lifetime. |
| `Transparency` | `NumberSequence` | `NumberSequence.new(0)` | Image transparency over its lifetime. |
| `Size` | `NumberSequence` | `NumberSequence.new(1)` | Square image size in pixels over its lifetime. |
| `Rotation` | `NumberRange` | `0-360` | Initial rotation in degrees. |
| `RotSpeed` | `NumberRange` | `-90-90` | Rotation speed in degrees per second. |
| `LockedToPart` | `boolean` | `false` | When true, particles move with the UI parent; otherwise they remain in screen space if it moves. |
| `ZOffset` | `number` | `0` | Z index used for newly created particle images. |

## Current limitations and roadmap

The following ParticleEmitter-style capabilities are not currently rendered or simulated:

- `Orientation`
- `Squash`
- `TimeScale`
- Flipbook properties
- Emitter shapes and shape settings

`fromEmitter` with `bound = true` only synchronizes properties whose runtime types match the GUI emitter property. Some native particle settings need conversion, such as 3D acceleration and `Vector2` spread angles, so they are not automatically kept in sync.

There is also no automated test suite or example place yet.

## Development

This repository uses [Rokit](https://github.com/rojo-rbx/rokit) to manage its toolchain.

```sh
rokit install
selene src
stylua --check src
```

To build a Roblox place from the project tree:

```sh
rojo build -o "GuiParticleService.rbxlx"
```

To sync the project with Roblox Studio:

```sh
rojo serve
```

## Contributing

Contributions are welcome. Please open an issue or pull request describing the behaviour you want to add or change. For code contributions:

1. Create a focused branch from the latest default branch.
2. Keep the public API and `ParticleEmitter` compatibility in mind.
3. Format and lint your changes with `stylua src` and `selene src`.
4. Include clear reproduction or validation steps in the pull request.

The repository runs Selene and StyLua checks on pull requests, which are required for merging.

## License

This project is licensed under the [MIT License](LICENSE).
