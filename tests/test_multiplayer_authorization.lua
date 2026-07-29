local testFilename = debug.getinfo(1, 'S').source:sub(2)
local projectDirectory = testFilename:match('^(.*)/tests/[^/]+$')

if projectDirectory == nil and testFilename:match('^tests/[^/]+$') then
    projectDirectory = '.'
end

if projectDirectory == nil then
    error('Run this test from a file inside the tests directory.')
end

local function loadProjectFile(filename)
    dofile(projectDirectory .. '/' .. filename)
end

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(string.format('%s: expected %s, got %s', message, tostring(expected), tostring(actual)), 2)
    end
end

local function copyTable(values)
    local result = {}

    for key, value in pairs(values) do
        result[key] = value
    end

    return result
end

Event = {}

function Event.new(mt)
    return setmetatable({}, mt)
end

function Class(classTable)
    return { __index = classTable }
end

function InitEventClass()
end

loadProjectFile('scripts/ModUtils.lua')

local eventFiles = {
    'scripts/events/SetDefaultEnabledEvent.lua',
    'scripts/events/SetEnabledEvent.lua',
    'scripts/events/SetMaterialsEvent.lua',
    'scripts/events/SetResourcesEvent.lua',
    'scripts/landscaping/events/AreaDeleteEvent.lua',
    'scripts/landscaping/events/AreaRegisterEvent.lua',
    'scripts/landscaping/events/AreaUpdateEvent.lua',
    'scripts/landscaping/events/WaterplaneDeleteEvent.lua',
    'scripts/landscaping/events/WaterplaneRegisterEvent.lua',
    'scripts/landscaping/events/WaterplaneSetVisibleEvent.lua',
    'scripts/landscaping/events/WaterplaneUpdateEvent.lua',
    'scripts/specializations/events/SetMachineActiveEvent.lua',
    'scripts/specializations/events/SetMachineEnabledEvent.lua',
    'scripts/specializations/events/SetMachineFillTypeEvent.lua',
    'scripts/specializations/events/SetMachineInputAreaEnabledEvent.lua',
    'scripts/specializations/events/SetMachineInputAreaIdEvent.lua',
    'scripts/specializations/events/SetMachineInputLayerEvent.lua',
    'scripts/specializations/events/SetMachineInputModeEvent.lua',
    'scripts/specializations/events/SetMachineOutputAreaEnabledEvent.lua',
    'scripts/specializations/events/SetMachineOutputAreaIdEvent.lua',
    'scripts/specializations/events/SetMachineOutputLayerEvent.lua',
    'scripts/specializations/events/SetMachineOutputModeEvent.lua',
    'scripts/specializations/events/SetMachineResourcesEvent.lua',
    'scripts/specializations/events/SetMachineStateEvent.lua',
}

for _, filename in ipairs(eventFiles) do
    loadProjectFile(filename)
end

local mutationCount = 0
local broadcastCount = 0

local function recordMutation()
    mutationCount = mutationCount + 1
end

local function resetCounts()
    mutationCount = 0
    broadcastCount = 0
end

local function newConnection(options)
    options = options or {}

    local connection = {
        permissions = options.permissions or {},
        permittedFarmIds = options.permittedFarmIds or {},
    }

    function connection:getIsServer()
        return options.isServer == true
    end

    function connection:getIsMasterUser()
        return options.isAdministrator == true
    end

    return connection
end

g_currentMission = {
    userManager = {
        getUserByConnection = function (_, connection)
            return connection
        end,
    },
}

function g_currentMission:getHasPlayerPermission(permission, connection, farmId)
    if connection == nil or connection.permissions[permission] ~= true then
        return false
    end

    return farmId == nil or connection.permittedFarmIds[farmId] == true
end

g_server = {
    broadcastEvent = function ()
        broadcastCount = broadcastCount + 1
    end,
}

g_modSettings = {
    setDefaultEnabled = recordMutation,
    setIsEnabled = recordMutation,
    setMaterials = recordMutation,
}

g_resourceManager = {
    setIsActive = recordMutation,
}

g_landscapingManager = {
    deleteAreaByUniqueId = recordMutation,
    registerArea = recordMutation,
    updateArea = recordMutation,
    deleteWaterplaneByUniqueId = recordMutation,
    registerWaterplane = recordMutation,
    setWaterplaneVisible = recordMutation,
    updateWaterplane = recordMutation,
}

local vehicle = {
    ownerFarmId = 7,
}

function vehicle:getOwnerFarmId()
    return self.ownerFarmId
end

function vehicle:getIsSynchronized()
    return true
end

vehicle.setMachineActive = recordMutation
vehicle.setMachineEnabled = recordMutation
vehicle.setMachineFillTypeIndex = recordMutation
vehicle.setIsMachineInputAreaEnabled = recordMutation
vehicle.setMachineInputAreaId = recordMutation
vehicle.setMachineInputLayerId = recordMutation
vehicle.setInputMode = recordMutation
vehicle.setIsMachineOutputAreaEnabled = recordMutation
vehicle.setMachineOutputAreaId = recordMutation
vehicle.setMachineOutputLayerId = recordMutation
vehicle.setOutputMode = recordMutation
vehicle.setResourcesEnabled = recordMutation
vehicle.setMachineState = recordMutation

local unauthorizedConnection = newConnection()
local administratorConnection = newConnection({ isAdministrator = true })
local landscapingConnection = newConnection({
    permissions = { landscaping = true },
    permittedFarmIds = { [7] = true },
})
local farmManagerConnection = newConnection({
    permissions = { manageRights = true },
    permittedFarmIds = { [7] = true },
})
local wrongFarmConnection = newConnection({
    permissions = { landscaping = true, manageRights = true },
    permittedFarmIds = { [9] = true },
})
local serverConnection = newConnection({ isServer = true })

local globalEvents = {
    { name = 'SetDefaultEnabledEvent', class = SetDefaultEnabledEvent, values = { defaultEnabled = true } },
    { name = 'SetEnabledEvent', class = SetEnabledEvent, values = { enabled = true } },
    { name = 'SetMaterialsEvent', class = SetMaterialsEvent, values = { materials = { 'DIRT' } } },
    { name = 'SetResourcesEvent', class = SetResourcesEvent, values = { available = true, active = true } },
}

local landscapingEvents = {
    { name = 'AreaDeleteEvent', class = AreaDeleteEvent, values = { uniqueId = 'area' } },
    { name = 'AreaRegisterEvent', class = AreaRegisterEvent, values = { area = {} } },
    { name = 'AreaUpdateEvent', class = AreaUpdateEvent, values = { area = {} } },
    { name = 'WaterplaneDeleteEvent', class = WaterplaneDeleteEvent, values = { uniqueId = 'waterplane' } },
    { name = 'WaterplaneRegisterEvent', class = WaterplaneRegisterEvent, values = { waterplane = {} } },
    { name = 'WaterplaneSetVisibleEvent', class = WaterplaneSetVisibleEvent, values = { uniqueId = 'waterplane', visible = true } },
    { name = 'WaterplaneUpdateEvent', class = WaterplaneUpdateEvent, values = { waterplane = {} } },
}

local machineEvents = {
    { name = 'SetMachineActiveEvent', class = SetMachineActiveEvent, permission = 'landscaping', values = { active = true } },
    { name = 'SetMachineEnabledEvent', class = SetMachineEnabledEvent, permission = 'manageRights', values = { enabled = true } },
    { name = 'SetMachineFillTypeEvent', class = SetMachineFillTypeEvent, permission = 'landscaping', values = { fillTypeIndex = 1 } },
    { name = 'SetMachineInputAreaEnabledEvent', class = SetMachineInputAreaEnabledEvent, permission = 'landscaping', values = { enabled = true } },
    { name = 'SetMachineInputAreaIdEvent', class = SetMachineInputAreaIdEvent, permission = 'landscaping', values = { id = 'area' } },
    { name = 'SetMachineInputLayerEvent', class = SetMachineInputLayerEvent, permission = 'landscaping', values = { terrainLayerId = 1 } },
    { name = 'SetMachineInputModeEvent', class = SetMachineInputModeEvent, permission = 'landscaping', values = { mode = 1 } },
    { name = 'SetMachineOutputAreaEnabledEvent', class = SetMachineOutputAreaEnabledEvent, permission = 'landscaping', values = { enabled = true } },
    { name = 'SetMachineOutputAreaIdEvent', class = SetMachineOutputAreaIdEvent, permission = 'landscaping', values = { id = 'area' } },
    { name = 'SetMachineOutputLayerEvent', class = SetMachineOutputLayerEvent, permission = 'landscaping', values = { terrainLayerId = 1 } },
    { name = 'SetMachineOutputModeEvent', class = SetMachineOutputModeEvent, permission = 'landscaping', values = { mode = 1 } },
    { name = 'SetMachineResourcesEvent', class = SetMachineResourcesEvent, permission = 'manageRights', values = { enabled = true } },
    { name = 'SetMachineStateEvent', class = SetMachineStateEvent, permission = 'landscaping', values = { state = {} } },
}

local function runEvent(eventDefinition, connection)
    local event = copyTable(eventDefinition.values)
    event.vehicle = event.vehicle or vehicle
    eventDefinition.class.run(event, connection)
end

for _, eventDefinition in ipairs(globalEvents) do
    resetCounts()
    runEvent(eventDefinition, unauthorizedConnection)
    assertEqual(mutationCount, 0, eventDefinition.name .. ' accepted a non-administrator')
    assertEqual(broadcastCount, 0, eventDefinition.name .. ' broadcast an unauthorized request')

    resetCounts()
    runEvent(eventDefinition, administratorConnection)
    assertEqual(mutationCount, 1, eventDefinition.name .. ' rejected an administrator')
    assertEqual(broadcastCount, 1, eventDefinition.name .. ' did not broadcast an administrator change')

    resetCounts()
    runEvent(eventDefinition, serverConnection)
    assertEqual(mutationCount, 1, eventDefinition.name .. ' rejected server replication')
    assertEqual(broadcastCount, 0, eventDefinition.name .. ' rebroadcast a server event')
end

for _, eventDefinition in ipairs(landscapingEvents) do
    resetCounts()
    runEvent(eventDefinition, unauthorizedConnection)
    assertEqual(mutationCount, 0, eventDefinition.name .. ' accepted a client without landscaping permission')
    assertEqual(broadcastCount, 0, eventDefinition.name .. ' broadcast an unauthorized request')

    resetCounts()
    runEvent(eventDefinition, landscapingConnection)
    assertEqual(mutationCount, 1, eventDefinition.name .. ' rejected a client with landscaping permission')
    assertEqual(broadcastCount, 1, eventDefinition.name .. ' did not broadcast an authorized change')

    resetCounts()
    runEvent(eventDefinition, serverConnection)
    assertEqual(mutationCount, 1, eventDefinition.name .. ' rejected server replication')
    assertEqual(broadcastCount, 0, eventDefinition.name .. ' rebroadcast a server event')
end

for _, eventDefinition in ipairs(machineEvents) do
    local authorizedConnection = eventDefinition.permission == 'manageRights' and farmManagerConnection or landscapingConnection

    resetCounts()
    runEvent(eventDefinition, unauthorizedConnection)
    assertEqual(mutationCount, 0, eventDefinition.name .. ' accepted a client without permission')
    assertEqual(broadcastCount, 0, eventDefinition.name .. ' broadcast an unauthorized request')

    resetCounts()
    runEvent(eventDefinition, wrongFarmConnection)
    assertEqual(mutationCount, 0, eventDefinition.name .. ' accepted a request for another farm')
    assertEqual(broadcastCount, 0, eventDefinition.name .. ' broadcast a request for another farm')

    resetCounts()
    runEvent(eventDefinition, authorizedConnection)
    assertEqual(mutationCount, 1, eventDefinition.name .. ' rejected an authorized client')
    assertEqual(broadcastCount, 1, eventDefinition.name .. ' did not broadcast an authorized change')

    resetCounts()
    runEvent(eventDefinition, serverConnection)
    assertEqual(mutationCount, 1, eventDefinition.name .. ' rejected server replication')
    assertEqual(broadcastCount, 0, eventDefinition.name .. ' rebroadcast a server event')
end

local authoritativeArea = {
    uniqueId = 'area',
    readCount = 0,
}
local receivedArea

function authoritativeArea:clone()
    local clone = {
        uniqueId = self.uniqueId,
        readCount = 0,
    }

    function clone:readStream()
        self.readCount = self.readCount + 1
    end

    return clone
end

function authoritativeArea:readStream()
    self.readCount = self.readCount + 1
end

streamReadString = function ()
    return authoritativeArea.uniqueId
end

g_landscapingManager.getAreaByUniqueId = function ()
    return authoritativeArea
end

g_landscapingManager.updateArea = function (_, area)
    receivedArea = area
    recordMutation()
end

resetCounts()
AreaUpdateEvent.readStream(setmetatable({}, { __index = AreaUpdateEvent }), 0, unauthorizedConnection)
assertEqual(authoritativeArea.readCount, 0, 'AreaUpdateEvent changed the registered area before authorization')
assertEqual(mutationCount, 0, 'AreaUpdateEvent applied an unauthorized streamed update')
assertEqual(broadcastCount, 0, 'AreaUpdateEvent broadcast an unauthorized streamed update')

resetCounts()
AreaUpdateEvent.readStream(setmetatable({}, { __index = AreaUpdateEvent }), 0, landscapingConnection)
assertEqual(authoritativeArea.readCount, 0, 'AreaUpdateEvent changed the registered area while decoding an authorized update')
assertEqual(receivedArea ~= authoritativeArea, true, 'AreaUpdateEvent did not apply a separate decoded area')
assertEqual(receivedArea.readCount, 1, 'AreaUpdateEvent did not decode the authorized update')
assertEqual(mutationCount, 1, 'AreaUpdateEvent rejected an authorized streamed update')
assertEqual(broadcastCount, 1, 'AreaUpdateEvent did not broadcast an authorized streamed update')

print(string.format('All %d multiplayer authorization checks passed.', #globalEvents + #landscapingEvents + #machineEvents))
