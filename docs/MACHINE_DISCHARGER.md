# Discharger

Suitable for generic vehicles with discharge only such as trailers and trucks.

- [Prerequisites](#prerequisites)
- [Machine](#machine)
- [Work area](#work-area)
- [State object changes](#state-object-changes)

## Prerequisites

| Specialization | Required |
|----------------|----------|
| fillUnit       | Yes      |
| dischargeable  | Yes      |
| trailer        | Optional |

**NOTE**: If the vehicle doesn't have trailer specialization, you need to set dischargeNodeIndex attribute value.

## Machine

```
vehicle.machine
```

```xml
<vehicle>
    ...
    <machine type="discharger">
        ...
    </machine>
</vehicle>
```

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| type               | string | Yes |            | Machine type identifier |
| requireTurnedOn    | boolean | No | ```true``` | If set to true then the machine will not be activated unless vehicle is turned on as long as vehicle has implemented specialization. Will be ignored otherwise. |
| requirePoweredOn   | boolean | No | ```true``` | If set to true then the machine will not be activated unless vehicle is powered on as long as vehicle has implemented specialization. Will be ignored otherwise. |
| fillUnitIndex      | integer | No |            | Defaults to using fillUnit from dischargeNode |
| dischargeNodeIndex | integer | No | ```1```    |  |


## Work area

```
vehicle.machine.workArea
```

Machine work area adjustments.

```xml
<vehicle>
    <machine type="discharger">
        <workArea offset="0 -0.15 0.75" width="3" />
    </machine>
</vehicle>
```

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| referenceNode | node    | No | | Override reference node, defaults to using dischargeNode |
| width         | float   | No | | Override work area width, defaults to using dischargeNode width |
| density       | float   | No | ```0.75```  | Work area density |
| offset        | vector3 | No | ```0 0 0``` | Offset position |
| rotation      | vector3 | No | ```0 0 0``` | Rotation in degrees |
| raycastDistance | float | No | ```0.4```   | Raycast distance for preventing discharge. |

## State object changes

Apply state object changes whether machine is active or not.

(NOTE: Implemented, but not tested as of yet.)

```xml
<vehicle>
    <machine type="discharger">
        <stateObjectChanges>
            <objectChange node="warningSignal" visibilityActive="false" visibilityInactive="true" />
        </stateObjectChanges>
    </machine>
</vehicle>
```