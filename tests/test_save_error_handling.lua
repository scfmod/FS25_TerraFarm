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
    contents = contents:gsub('\ng_modSettings = ModSettings%.new%(%)[\r\n]*$', '\n')
    contents = contents:gsub('\ng_landscapingManager = LandscapingManager%.new%(%)\r?\ng_landscapingManager:loadShapes%(%)[\r\n]*$', '\n')

    assert(load(contents, '@' .. path))()
end

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(string.format('%s: expected %s, got %s', message, tostring(expected), tostring(actual)), 2)
    end
end

local originalSaveCalls = 0
local logEntries = {}

local function assertLogContains(pattern, message)
    for _, entry in ipairs(logEntries) do
        if entry:find(pattern, 1, true) ~= nil then
            return
        end
    end

    error(message .. ': ' .. table.concat(logEntries, ' | '), 2)
end

g_modDirectory = projectDirectory .. '/'
g_modDirectorySettings = '/user/'
g_currentMission = {
    missionInfo = {
        savegameDirectory = '/savegame1',
    }
}
g_resourceManager = {
    active = true,
}
g_server = {}

function source()
end

function Class(class)
    return {
        __index = class,
    }
end

Logging = {
    error = function (formatString, ...)
        table.insert(logEntries, string.format(formatString, ...))
    end,
}

LandscapingArea = {
    XML_SCHEMA = {},
    createXMLSchema = function ()
    end,
}

Savegame = {
    ERROR_OK = 0,
}

SavegameController = {
    onSaveComplete = function ()
        originalSaveCalls = originalSaveCalls + 1
        return 'originalResult'
    end,
}

Utils = {
    appendedFunction = function (originalFunction, appendedFunction)
        return function (...)
            local results = { originalFunction(...) }
            appendedFunction(...)
            return table.unpack(results)
        end
    end,
}

XMLFile = {}

loadProjectFile('scripts/ModUtils.lua')
loadProjectFile('scripts/ModSettings.lua')
loadProjectFile('scripts/landscaping/LandscapingManager.lua')
loadProjectFile('scripts/extensions/SavegameControllerExtension.lua')

local settingsSaveCalls = 0
local areaSaveCalls = 0

g_modSettings = {
    saveSettings = function ()
        settingsSaveCalls = settingsSaveCalls + 1
        error('settings exploded')
    end,
}
g_landscapingManager = {
    saveAreasToXML = function ()
        areaSaveCalls = areaSaveCalls + 1
    end,
}

local originalResult = SavegameController:onSaveComplete(Savegame.ERROR_OK)

assertEqual(originalResult, 'originalResult', 'Save callback return value changed')
assertEqual(originalSaveCalls, 1, 'Original save callback was not called')
assertEqual(settingsSaveCalls, 1, 'Settings save was not attempted')
assertEqual(areaSaveCalls, 1, 'Settings failure prevented the landscaping save')
assertLogContains('/savegame1/terraFarmSettings.xml', 'Settings exception did not include its save path')
assertLogContains('settings exploded', 'Settings exception was not logged')

logEntries = {}
g_modSettings.saveSettings = function ()
    settingsSaveCalls = settingsSaveCalls + 1
end
g_landscapingManager.saveAreasToXML = function ()
    areaSaveCalls = areaSaveCalls + 1
    error('areas exploded')
end

SavegameController:onSaveComplete(Savegame.ERROR_OK)

assertLogContains('/savegame1/terraFarmAreas.xml', 'Landscaping exception did not include its save path')
assertLogContains('areas exploded', 'Landscaping exception was not logged')

local callsBeforeFailedBaseSave = settingsSaveCalls + areaSaveCalls
SavegameController:onSaveComplete(1)
assertEqual(settingsSaveCalls + areaSaveCalls, callsBeforeFailedBaseSave, 'TerraFarm data was saved after the base save failed')

local function makeXMLFile(saveResult)
    return {
        deleteCount = 0,
        setBool = function ()
        end,
        setString = function ()
        end,
        setValue = function ()
        end,
        save = function ()
            return saveResult
        end,
        delete = function (self)
            self.deleteCount = self.deleteCount + 1
        end,
    }
end

local settings = setmetatable({
    enabled = true,
    defaultEnabled = true,
    materials = {},
}, {
    __index = ModSettings,
})

logEntries = {}
XMLFile.create = function ()
    return nil
end

assertEqual(settings:saveSettings(), false, 'Settings XML creation failure was not returned')
assertLogContains('/savegame1/terraFarmSettings.xml', 'Settings XML creation failure did not include its save path')

logEntries = {}
local settingsXMLFile = makeXMLFile(false)
XMLFile.create = function ()
    return settingsXMLFile
end

assertEqual(settings:saveSettings(), false, 'Settings XML write failure was not returned')
assertEqual(settingsXMLFile.deleteCount, 1, 'Settings XML file was not released after a write failure')
assertLogContains('/savegame1/terraFarmSettings.xml', 'Settings XML write failure did not include its save path')

logEntries = {}
local areasManager = setmetatable({
    areas = {},
    waterplanes = {},
}, {
    __index = LandscapingManager,
})

XMLFile.create = function ()
    return nil
end

assertEqual(areasManager:saveAreasToXML(), false, 'Landscaping XML creation failure was not returned')
assertLogContains('/savegame1/terraFarmAreas.xml', 'Landscaping XML creation failure did not include its save path')

logEntries = {}
local areasXMLFile = makeXMLFile(false)
XMLFile.create = function ()
    return areasXMLFile
end

assertEqual(areasManager:saveAreasToXML(), false, 'Landscaping XML write failure was not returned')
assertEqual(areasXMLFile.deleteCount, 1, 'Landscaping XML file was not released after a write failure')
assertLogContains('/savegame1/terraFarmAreas.xml', 'Landscaping XML write failure did not include its save path')

print('All save error handling checks passed.')
