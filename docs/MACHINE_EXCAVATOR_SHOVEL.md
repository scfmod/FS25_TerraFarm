# Excavator shovel

Suitable for stationary vehicles like excavators and excavator attachables.
Same as [```shovel```](./MACHINE_SHOVEL.md), but with some custom adjustments. Also doesn't use driving direction to apply terrain deformations.

- [Prerequisites](#prerequisites)
- [Machine](#machine)
- [Input](#input)
- [Work area](#work-area)
- [Effects](#effects)
- [Animations](#animations)
- [Sounds](#sounds)
- [State object changes](#state-object-changes)

## Prerequisites

| Specialization | Required |
|----------------|----------|
| fillUnit       | Yes      |
| shovel         | Yes      |
| dischargeable  | Optional |
| leveler        | Optional |


## Machine

```
vehicle.machine
```

```xml
<vehicle>
    ...
    <machine type="excavatorShovel">
        ...
    </machine>
</vehicle>
```

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| type               | string | Yes |         | Machine type identifier |
| requireTurnedOn    | boolean | No | ```true``` | If set to true then the machine will not be activated unless vehicle is turned on as long as vehicle has implemented specialization. Will be ignored otherwise. |
| requirePoweredOn   | boolean | No | ```true``` | If set to true then the machine will not be activated unless vehicle is powered on as long as vehicle has implemented specialization. Will be ignored otherwise. |
| fillUnitIndex      | integer | No |         | Defaults to using fillUnit from shovelNode |
| shovelNodeIndex    | integer | No | ```1``` | Override if vehicle has multiple shovelNodes |
| levelerNodeIndex   | integer | No | ```1``` | Override if vehicle has multiple levelerNodes |
| dischargeNodeIndex | integer | No |         | Defaults to using dischargeNode from shovelNode |

## Input

```
vehicle.machine.input
```

```xml
<vehicle>
    ...
    <machine type="excavatorShovel">
        <input modes="FLATTEN SMOOTH LOWER PAINT" />
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
    <machine type="excavatorShovel">
        <input modes="FLATTEN SMOOTH LOWER PAINT" />

        <workArea offset="0 -0.15 0.75" width="3" />
    </machine>
</vehicle>
```

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| referenceNode | node    | No | | Override reference node, defaults to using shovelNode |
| width         | float   | No | | Override work area width, defaults to using shovelNode width |
| density       | float   | No | ```0.75```  | Work area density |
| offset        | vector3 | No | ```0 0 0``` | Offset position |
| rotation      | vector3 | No | ```0 0 0``` | Rotation in degrees |
| raycastDistance | float | No | ```0.4```   | Raycast distance for preventing discharge. |

## Effects

```
vehicle.machine.effects
```

Enable effect nodes when machine is working the ground. Uses the base game vehicle effectNode setup.

```xml
<vehicle>
    <machine type="excavatorShovel">
        <input modes="FLATTEN SMOOTH LOWER PAINT" />

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
    <machine type="excavatorShovel">
        <input modes="FLATTEN SMOOTH LOWER PAINT" />

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
    <machine type="excavatorShovel">
        <input modes="FLATTEN SMOOTH LOWER PAINT" />

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
    <machine type="excavatorShovel">
        <input modes="FLATTEN SMOOTH LOWER PAINT" />

        <stateObjectChanges>
            <objectChange node="warningSignal" visibilityActive="false" visibilityInactive="true" />
        </stateObjectChanges>
    </machine>
</vehicle>
```