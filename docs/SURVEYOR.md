# Surveyor

- [Vehicle type](#vehicle-type)
- [Vehicle XML](#vehicle-xml)
  - [Object changes](#object-changes)
  - [Animations](#animations)

Supports optional foldable specialization.

## Vehicle type

``modDesc.xml``

```xml
<modDesc version="...">
    ...

    <vehicleTypes>
        <type name="customSurveyor" className="Vehicle" filename="$dataS/scripts/vehicles/Vehicle.lua">
            <!-- Add surveyor specialization -->
            <specialization name="FS25_0_TerraFarm.surveyor" />
        </type>
    </vehicleTypes>
</modDesc>
```

## Vehicle XML

```
vehicle.surveyor
```

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<vehicle type="customSurveyor">
    ...

    <surveyor trigger="0>1" offsetY="1.7" />
</vehicle>
```

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| trigger | node | Yes | | Player activation trigger node. The collisionMask must have bit ```20``` (TRIGGER_PLAYER) set in order to function. |
| defaultName | string | No | Vehicle name | Default name for surveyor. L10N string supported. |
| offsetY | float | No | ```1.5``` | Y offset for visual guide lines. |

### Object changes

Apply object changes when the surveyor calibration state is changed.

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<vehicle type="customSurveyor">
    ...

    <surveyor trigger="0>1" offsetY="1.7">
        <objectChanges>
            <objectChange node="0>2" shaderParameter="colorScale" shaderParameterActive="0 1 0 0" shaderParameterInactive="1 0 0 0" />
        </objectChanges>
    </surveyor>
</vehicle>
```

### Animations

Enable animation nodes when surveyor is calibrated. Uses the base game vehicle animationNode setup.

(NOTE: Implemented, but not tested as of yet.)

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<vehicle type="customSurveyor">
    ...

    <surveyor trigger="0>1" offsetY="1.7">
        <animations>
            <animationNode ...>
        </animations>
    </surveyor>
</vehicle>
```