---@class MachineType
---@field id string
---@field name string
---@field useDischargeable boolean
---@field useDrivingDirection boolean
---@field useFillUnit boolean
---@field useLeveler boolean
---@field useShovel boolean
---@field useInput boolean

---@type MachineType
local machineTypeCompactor = {
    id = 'compactor',
    name = g_i18n:getText('machineType_compactor'),
    useDischargeable = false,
    useDrivingDirection = true,
    useFillUnit = false,
    useLeveler = false,
    useShovel = false,
    useInput = true,
}

---@type MachineType
local machineTypeDischarger = {
    id = 'discharger',
    name = g_i18n:getText('configuration_dischargeable'),
    useDischargeable = true,
    useDrivingDirection = false,
    useFillUnit = true,
    useLeveler = false,
    useShovel = false,
    useTrailer = true,
    useInput = false,
}

---@type MachineType
local machineTypeExcavatorRipper = {
    id = 'excavatorRipper',
    name = g_i18n:getText('machineType_ripper'),
    useDischargeable = false,
    useDrivingDirection = false,
    useFillUnit = false,
    useLeveler = false,
    useShovel = false,
    useInput = true,
}

---@type MachineType
local machineTypeExcavatorShovel = {
    id = 'excavatorShovel',
    name = g_i18n:getText('machineType_excavator'),
    useDischargeable = true,
    useDrivingDirection = false,
    useFillUnit = true,
    useLeveler = true,
    useShovel = true,
    useInput = true,
}

---@type MachineType
local machineTypeLeveler = {
    id = 'leveler',
    name = g_i18n:getText('machineType_leveler'),
    useDischargeable = false,
    useDrivingDirection = true,
    useFillUnit = true,
    useLeveler = true,
    useShovel = false,
    useInput = true,
}

---@type MachineType
local machineTypeRipper = {
    id = 'ripper',
    name = g_i18n:getText('machineType_ripper'),
    useDischargeable = false,
    useDrivingDirection = true,
    useFillUnit = false,
    useLeveler = false,
    useShovel = false,
    useInput = true,
}

---@type MachineType
local machineTypeShovel = {
    id = 'shovel',
    name = g_i18n:getText('machineType_shovel'),
    useDischargeable = true,
    useDrivingDirection = true,
    useFillUnit = true,
    useLeveler = true,
    useShovel = true,
    useInput = true,
}

---@type MachineType
local machineTypeTrencher = {
    id = 'trencher',
    name = g_i18n:getText('machineType_trencher'),
    useDischargeable = true,
    useDrivingDirection = false,
    useFillUnit = true,
    useLeveler = false,
    useShovel = false,
    useInput = true,
}

g_machineManager:registerMachineType(machineTypeCompactor)
g_machineManager:registerMachineType(machineTypeDischarger)
g_machineManager:registerMachineType(machineTypeExcavatorRipper)
g_machineManager:registerMachineType(machineTypeExcavatorShovel)
g_machineManager:registerMachineType(machineTypeLeveler)
g_machineManager:registerMachineType(machineTypeRipper)
g_machineManager:registerMachineType(machineTypeShovel)
g_machineManager:registerMachineType(machineTypeTrencher)
