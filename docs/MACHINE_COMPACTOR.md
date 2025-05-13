# Compactor

Suitable for ground compactors and various generic equipment that does not require any material functionality.

- [Prerequisites](#prerequisites)
- [Machine](#machine)
- [Input](#input)
- [Work area](#work-area)
- [Effects](#effects)
- [Animations](#animations)
- [Sounds](#sounds)
- [State object changes](#state-object-changes)

## Prerequisites

None.

## Machine

```
vehicle.machine
```

```xml
<vehicle>
    ...
    <machine type="compactor">
        ...
    </machine>
</vehicle>
```

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| type               | string | Yes |         | Machine type identifier |
| requireTurnedOn    | boolean | No | ```true``` | If set to true then the machine will not be activated unless vehicle is turned on as long as vehicle has implemented specialization. Will be ignored otherwise. |
| requirePoweredOn   | boolean | No | ```true``` | If set to true then the machine will not be activated unless vehicle is powered on as long as vehicle has implemented specialization. Will be ignored otherwise. |

## Input

```
vehicle.machine.input
```

```xml
<vehicle>
    ...
    <machine type="compactor">
        <input modes="FLATTEN SMOOTH PAINT" />
    </machine>
</vehicle>
```

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| modes| string | Yes    |         | Define work mode(s) separated by space. The order of modes in xml will also affect the order shown ingame. |

Available modes:
- ```FLATTEN```
- ```SMOOTH```
- ```LOWER```
- ```PAINT```

## Work area

```
vehicle.machine.workArea
```

Machine work area adjustments.

```xml
<vehicle>
    <machine type="compactor">
        <input modes="FLATTEN SMOOTH PAINT" />

        <workArea referenceNode="posNodeRef" offset="0 -0.15 0.75" rotation="0 0 90" width="3" />
    </machine>
</vehicle>
```

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| referenceNode | node    | Yes | | Work area reference node |
| width         | float   | Yes | | Work area width |
| density       | float   | No  | ```0.75``` | Work area density |
| offset        | vector3 | No  | ```0 0 0``` | Offset position |
| rotation      | vector3 | No  | ```0 0 0``` | Rotation in degrees |


## Effects

```
vehicle.machine.effects
```

Enable effect nodes when machine is working the ground. Uses the base game vehicle effectNode setup.

```xml
<vehicle>
    <machine type="compactor">
        <input modes="FLATTEN SMOOTH PAINT" />
        <workArea referenceNode="posNodeRef" offset="0 -0.15 0.75" rotation="0 0 90" width="3" />

        <effects effectTurnOffThreshold="0.3" >
            <effectNode effectClass="ParticleEffect" effectNode="0>4|0|1|6" particleType="smoke" emitCountScale="4" delay="0" spriteScale="1.0" ignoreDistanceLifeSpan="true" lifespan="3.0" worldSpace="true" />
        </effects>
    </machine>
</vehicle>
```

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| effectTurnOffThreshold | float | No | ```0.25``` | |

## Animations

```
vehicle.machine.effectAnimations.animationNode(?)
```

Enable animation nodes when machine is working the ground. Uses the base game vehicle animationNode setup.
Only applicable if machine has effect nodes.

(NOTE: Implemented, but not tested as of yet.)

```xml
<vehicle>
    <machine type="compactor">
        <input modes="FLATTEN SMOOTH PAINT" />
        <workArea referenceNode="posNodeRef" offset="0 -0.15 0.75" rotation="0 0 90" width="3" />

        <effectAnimations>
            <animationNode ... />
        </effectAnimations>
    </machine>
</vehicle>
```

## Sounds

```
vehicle.machine.workSound
```

Enable playing sound sample when machine is working the ground. Uses the base game vehicle sample setup.
Only applicable if machine has effect nodes.

```xml
<vehicle>
    <machine type="compactor">
        <input modes="FLATTEN SMOOTH PAINT" />
        <workArea referenceNode="posNodeRef" offset="0 -0.15 0.75" rotation="0 0 90" width="3" />

        <effects effectTurnOffThreshold="0.3" >
            <effectNode effectClass="ParticleEffect" effectNode="0>4|0|1|6" particleType="smoke" emitCountScale="4" delay="0" spriteScale="1.0" ignoreDistanceLifeSpan="true" lifespan="3.0" worldSpace="true" />
        </effects>

        <workSound linkNode="workSoundNode" file="$data/sounds/vehicles/surfaces/gravel_loop.wav" loops="0" fadeOut="0.5" />
    </machine>
</vehicle>
```

## State object changes

Apply state object changes whether machine is active or not.

(NOTE: Implemented, but not tested as of yet.)

```xml
<vehicle>
    <machine type="compactor">
        <input modes="FLATTEN SMOOTH PAINT" />
        <workArea referenceNode="posNodeRef" offset="0 -0.15 0.75" rotation="0 0 90" width="3" />

        <stateObjectChanges>
            <objectChange node="warningSignal" visibilityActive="false" visibilityInactive="true" />
        </stateObjectChanges>
    </machine>
</vehicle>
```