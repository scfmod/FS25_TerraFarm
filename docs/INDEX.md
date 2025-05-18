# Documentation

- [Implementing specialization](#implementing-specialization)
  - [Vehicle type](#vehicle-type)
  - [Vehicle XML](#vehicle-xml)
- [Machine configurations](#machine-configurations)
- [InteractiveControl](#interactivecontrol)
- [Console commands](#console-commands)

TerraFarm supports integrating configurations in mods using following methods:
- Vehicle specialization
- Adding machine configuration xml files

## Implementing specialization

### Vehicle type

``modDesc.xml``

```xml
<modDesc version="...">
    ...

    <vehicleTypes>
        <type name="kouppaEC750" parent="baseFillable" className="Vehicle" filename="$dataS/scripts/vehicles/Vehicle.lua">
            <specialization name="dischargeable" />
            <specialization name="bunkerSiloInteractor" />
            <specialization name="shovel" />

            <!-- Add machine specialization as last entry -->
            <specialization name="FS25_0_TerraFarm.machine" />
        </type>
    </vehicleTypes>
</modDesc>
```

If TerraFarm mod is not loaded the log will show an error specialization not found, but the vehicle will still load as usual and function without machine functionality.

IMPORTANT: The specialization entry should be the last in order.

### Vehicle XML

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<vehicle type="kouppaEC750">
    ...

    <machine type="shovel">
        ...
    </machine>
</vehicle>
```

## Using XML configuration file

A mod can supply one or more configurations for both internal and external mod vehicles.
This means you can also create a mod only for adding specific machine configurations.

``machineConfigurations.xml``
```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<configurations>
    <configuration
        vehicle="FS25_gjerstadPack/vehicles/cableBucket850L_S70/cableBucket850L_S70.xml"
        file="xml/machines/gjerstadPack/cableBucket850L_S70.xml" />
</configurations>
```

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| vehicle | string | Yes | | Relative path to vehicle XML file (with mod name). |
| file | string | Yes | | Relative path to machine XML configuration file. |

In order for TerraFarm to find the main XML file, it must be located in either of these two places inside mod:
- ``/machineConfigurations.xml``
- ``/xml/machineConfigurations.xml``

(Case sensitive filename and path)

### Basic configuration file format

Uses the same format as vehicle specialization configuration.

```xml
<vehicle>
    <machine type="shovel">
        <input modes="FLATTEN SMOOTH LOWER PAINT" />
    </machine>
</vehicle>
```

## Machine configurations

| Type | Description |
|------|-------------|
| [```compactor```](./MACHINE_COMPACTOR.md) | For compactors and some generic equipment. |
| [```excavatorRipper```](./MACHINE_EXCAVATOR_RIPPER.md) | For excavator ground rippers. |
| [```excavatorShovel```](./MACHINE_EXCAVATOR_SHOVEL.md) | For excavators and excavator shovels. |
| [```discharger```](./MACHINE_DISCHARGER.md) | For trailers, trucks and generic discharge only vehicles. |
| [```leveler```](./MACHINE_LEVELER.md) | For bulldozers, bulldozer blades, graders and similar levelers. |
| [```ripper```](./MACHINE_RIPPER.md) | For ground rippers. |
| [```shovel``` ](./MACHINE_SHOVEL.md) | For wheel loaders, generic shovels etc. |
| [```trencher```](./MACHINE_TRENCHER.md) | For trenchers and similar equipment. |

## InteractiveControl

When [FS25_interactiveControl](https://www.farming-simulator.com/mod.php?mod_id=323135) mod is active, TerraFarm will add new functions available for use:

| Function | Description |
|----------|-------------|
| MACHINE_TOGGLE_ENABLED | Toggle whether machine is enabled or not. |
| MACHINE_TOGGLE_ACTIVE | Toggle whether machine is active or not. |
| MACHINE_TOGGLE_INPUT | Toggle input mode if applicable. |
| MACHINE_TOGGLE_OUTPUT | Toggle output mode if applicable. |
| MACHINE_TOGGLE_HUD | Toggle HUD visibility. |
| MACHINE_SETTINGS | Open machine settings dialog. |
| MACHINE_SELECT_MATERIAL | Open select material dialog. |
| MACHINE_SELECT_TEXTURE | Open select ground texture dialog. |
| MACHINE_SELECT_SURVEYOR | Open select surveyor dialog for calibration. Only available if machine has FLATTEN mode for input and/or output. |

**NOTE**: Outside triggers are not supported.

**NOTE**: These IC functions will use the current active selected machine, so you don't need Machine specialization implemented on entered vehicle in order for functions to work.

## Console commands

### Reload registered configurations

Command: ```tfReloadConfigurations```

This will clear all registered configuration file entries (internal and external "machineConfigurations.xml"), and reload them.

Useful when creating and editing machine configurations mods. This will not reload any loaded vehicles.

For vehicles that implements the Machine specialization you can use the regular ```gsVehicleReload``` command. Also works for hot-reloading when modifying external configuration files.

**NOTE**: Only available in single player mode.

---

### Verify loaded mod configurations
Command: ```tfVerifyModConfigurations <modName>```

Verify that vehicle .xml files exists for configuration entries for given loaded mod.

**NOTE**: modName is case sensitive.

---

### Verify all loaded mods configurations

Command: ```tfVerifyAllModsConfigurations```

Verify vehicle .xml files exists for all configuration entries for all loaded mods.