local testFilename = debug.getinfo(1, 'S').source:sub(2)
local projectDirectory = testFilename:match('^(.*)/tests/[^/]+$')

if projectDirectory == nil and testFilename:match('^tests/[^/]+$') then
    projectDirectory = '.'
end

if projectDirectory == nil then
    error('Run this test from a file inside the tests directory.')
end

local function loadProjectFile(filename)
    local path = projectDirectory .. '/' .. filename
    local file = assert(io.open(path, 'r'))
    local contents = file:read('*a')
    file:close()

    contents = contents:gsub(
        '([%w_%.%[%]]+)%s*([%+%-%*/])=%s*([^\r\n]+)',
        function (name, operator, value)
            return string.format('%s = %s %s %s', name, name, operator, value)
        end
    )
    contents = contents:gsub('([ \t]*)continue([ \t]*)(\r?\n)', '%1-- continue%2%3')

    assert(load(contents, '@' .. path))()
end

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(string.format('%s: expected %s, got %s', message, tostring(expected), tostring(actual)), 2)
    end
end

g_currentModDirectory = projectDirectory .. '/'
g_currentModName = 'FS25_0_TerraFarm'
g_i18n = {
    getText = function (_, key)
        return key
    end
}

function source()
end

Attachable = {}
Dischargeable = {}
Drivable = {}
Enterable = {}
FillUnit = {}
Leveler = {}
Motorized = {}
Shovel = {}
Trailer = {}
TurnOnVehicle = {}

AudioGroup = {
    VEHICLE = 1
}

Vehicle = {
    xmlSchema = {},
    xmlSchemaSavegame = {},
}

MachineState = {
    new = function ()
        return {}
    end
}

MachineUtils = {
    loadMachineModesFromXML = function ()
        return {}
    end,
    loadUpdateCollisionNodesFromXML = function ()
        return {}
    end,
}

MachineWorkArea = {
    new = function ()
        return {
            loadFromXMLFile = function ()
            end,
            initialize = function ()
                return true
            end,
        }
    end
}

ObjectChangeUtil = {
    loadObjectChangeFromXML = function ()
    end,
    setObjectChanges = function ()
    end,
}

SpecializationUtil = {
    hasSpecialization = function ()
        return false
    end,
    registerEventListener = function ()
    end,
    removeEventListener = function ()
    end,
}

Utils = {
    getDirectory = function (filename)
        return filename:match('^(.*[/\\])') or ''
    end,
}

g_machineManager = {
    getMachineTypeById = function (_, machineTypeId)
        if machineTypeId == 'testMachine' then
            return {
                useDischargeable = false,
                useFillUnit = false,
                useLeveler = false,
                useShovel = false,
            }
        end
    end
}

g_modSettings = {
    getDefaultEnabled = function ()
        return true
    end
}

g_landscapingManager = {
    getDefaultFillTypeIndex = function ()
        return 1
    end,
    getDefaultTerrainLayerId = function ()
        return 1
    end,
}

local externalXMLFile

XMLFile = {
    loadIfExists = function ()
        return externalXMLFile
    end
}

local animationXMLFile
local effectXMLFile
local soundXMLFile
local soundBaseDirectory

g_animationManager = {
    loadAnimations = function (_, xmlFile)
        animationXMLFile = xmlFile
        return {}
    end
}

g_effectManager = {
    loadEffect = function (_, xmlFile)
        effectXMLFile = xmlFile
        return { {} }
    end
}

g_soundManager = {
    loadSampleFromXML = function (_, xmlFile, _, _, baseDirectory)
        soundXMLFile = xmlFile
        soundBaseDirectory = baseDirectory
        return {}
    end
}

loadProjectFile('scripts/specializations/Machine.lua')

local function makeXMLFile(name)
    return {
        name = name,
        deleteCount = 0,
        delete = function (self)
            self.deleteCount = self.deleteCount + 1
        end,
        getValue = function (_, key, default)
            if key == 'vehicle.machine#type' then
                return 'testMachine'
            elseif key == 'vehicle.machine#playSound' then
                return true
            end

            return default
        end,
        hasProperty = function ()
            return false
        end,
    }
end

local function runLoadCase(isExternal)
    animationXMLFile = nil
    effectXMLFile = nil
    soundXMLFile = nil
    soundBaseDirectory = nil

    local vehicleXMLFile = makeXMLFile('vehicle')
    externalXMLFile = makeXMLFile('external')

    local spec = {
        isExternal = isExternal,
        xmlFilenameConfig = '/mods/AddOn/config/machine.xml',
    }

    local vehicle = {
        [Machine.SPEC_NAME] = spec,
        baseDirectory = '/mods/Vehicle/',
        components = {},
        i3dMappings = {},
        isClient = true,
        specializations = {},
        xmlFile = vehicleXMLFile,
        getNextDirtyFlag = function ()
            return 1
        end,
    }

    assertEqual(Machine.onLoad(vehicle), nil, 'Machine loading did not complete')

    return vehicleXMLFile, externalXMLFile
end

local vehicleXMLFile, loadedExternalXMLFile = runLoadCase(true)

assertEqual(effectXMLFile, loadedExternalXMLFile, 'External effects used the wrong XML file')
assertEqual(animationXMLFile, loadedExternalXMLFile, 'External animations used the wrong XML file')
assertEqual(soundXMLFile, loadedExternalXMLFile, 'External work sound used the wrong XML file')
assertEqual(soundBaseDirectory, '/mods/AddOn/config/', 'External work sound used the wrong base directory')
assertEqual(loadedExternalXMLFile.deleteCount, 1, 'External configuration XML was not released')
assertEqual(vehicleXMLFile.deleteCount, 0, 'Vehicle XML was released while loading an external configuration')

vehicleXMLFile, loadedExternalXMLFile = runLoadCase(false)

assertEqual(effectXMLFile, vehicleXMLFile, 'Embedded effects used the wrong XML file')
assertEqual(animationXMLFile, vehicleXMLFile, 'Embedded animations used the wrong XML file')
assertEqual(soundXMLFile, vehicleXMLFile, 'Embedded work sound used the wrong XML file')
assertEqual(soundBaseDirectory, '/mods/Vehicle/', 'Embedded work sound used the wrong base directory')
assertEqual(loadedExternalXMLFile.deleteCount, 0, 'External XML was loaded for an embedded configuration')
assertEqual(vehicleXMLFile.deleteCount, 0, 'Vehicle XML was released while loading an embedded configuration')

print('All external machine asset checks passed.')
