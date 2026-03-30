source(g_modDirectory .. 'scripts/MachineState.lua')
source(g_modDirectory .. 'scripts/MachineUtils.lua')
source(g_modDirectory .. 'scripts/MachineWorkArea.lua')

---@class MachineManager
---@field types table<string, MachineType>
---@field activeVehicle Machine?
---@field vehicles Machine[]
---@field configurations table<string, string> -- <vehicleFile, xmlFilename>
---@field displayWarning boolean
MachineManager = {}

MachineManager.CONFIGURATIONS_FILE = g_modDirectory .. 'data/configurations/index.xml'

local MachineManager_mt = Class(MachineManager)

---@return MachineManager
---@nodiscard
function MachineManager.new()
    ---@type MachineManager
    local self = setmetatable({}, MachineManager_mt)

    self.types = {}
    self.vehicles = {}
    self.configurations = {}

    self.displayWarning = false

    if g_server ~= nil then
        addConsoleCommand('tfReloadConfigurations', '', 'consoleReloadConfigurations', self)
        addConsoleCommand('tfVerifyModConfigurations', '', 'consoleVerifyModConfigurations', self)
        addConsoleCommand('tfVerifyAllModsConfigurations', '', 'consoleVerifyAllModsConfigurations', self)
    end

    g_modController:subscribe(ModEvent.onMapLoaded, self.onMapLoaded, self)
    g_modController:subscribe(ModEvent.onModsLoaded, self.onModsLoaded, self)

    return self
end

function MachineManager:checkDisplayWarning()
    if self.displayWarning then
        local warningText = 'TerraFarm mod filename has been altered, this may cause issues with mods dependencies.\n\n' ..
            'Please rename to "FS25_0_TerraFarm.zip"\n\n' ..
            'Always download latest official version from: https://github.com/scfmod/FS25_TerraFarm'

        ---@diagnostic disable-next-line: undefined-global
        InfoDialog.show(warningText, nil, nil, DialogElement.TYPE_WARNING)

        self.displayWarning = false
    end
end

---@param vehicle Machine?
function MachineManager:setActiveVehicle(vehicle)
    if self.activeVehicle ~= vehicle then
        self.activeVehicle = vehicle

        g_messageCenter:publish(ModMessageType.ACTIVE_MACHINE_CHANGED, vehicle)
    end
end

---@return Machine?
---@nodiscard
function MachineManager:getActiveVehicle()
    return self.activeVehicle
end

---@return Machine[]
---@nodiscard
function MachineManager:getAccessibleVehicles()
    ---@type Machine[]
    local result = {}

    if g_currentMission.isMasterUser then
        return table.clone(self.vehicles)
    end

    for _, vehicle in ipairs(self.vehicles) do
        if g_currentMission.accessHandler:canPlayerAccess(vehicle) then
            table.insert(result, vehicle)
        end
    end

    return result
end

---@param vehicle Machine
function MachineManager:registerVehicle(vehicle)
    -- g_modController:debug('MachineManager:registerVehicle()')

    if not table.hasElement(self.vehicles, vehicle) then
        table.insert(self.vehicles, vehicle)

        -- g_modController:debug('Registered vehicle: %s', vehicle:getFullName())
        g_messageCenter:publishDelayed(ModMessageType.MACHINE_ADDED, vehicle)
    end
end

---@param vehicle Machine
function MachineManager:unregisterVehicle(vehicle)
    if table.removeElement(self.vehicles, vehicle) then
        -- g_modController:debug('Unregistered vehicle: %s', vehicle:getFullName())
        g_messageCenter:publish(ModMessageType.MACHINE_REMOVED, vehicle)
    end
end

---@param xmlFilename string
---@param vehicleFile string
function MachineManager:registerConfiguration(xmlFilename, vehicleFile)
    self.configurations[vehicleFile] = xmlFilename
end

---@param vehicleFile string
---@return string? xmlFilename
---@nodiscard
function MachineManager:getConfigurationXMLFilename(vehicleFile)
    return self.configurations[vehicleFile]
end

---@param xmlFilename string
---@param modEnv string
function MachineManager:loadConfigurationsFromXMLFile(xmlFilename, modEnv)
    ---@type XMLFile?
    local xmlFile = XMLFile.loadIfExists('machineConfigurations', xmlFilename)

    if xmlFile ~= nil then
        local baseDirectory = g_modNameToDirectory[modEnv]
        local numEntries = 0

        g_modController:debug('MachineManager:loadConfigurationsFromXMLFile() Loading machine configuration entries from "%s"', xmlFilename)

        for _, key in xmlFile:iterator('configurations.configuration') do
            local vehicleFile = xmlFile:getString(key .. '#vehicle')
            local configFile = xmlFile:getString(key .. '#file')

            if vehicleFile ~= nil and configFile ~= nil then
                local modXMLFilename = baseDirectory .. configFile

                if fileExists(modXMLFilename) then
                    self:registerConfiguration(modXMLFilename, vehicleFile)
                    numEntries = numEntries + 1
                else
                    Logging.xmlWarning(xmlFile, 'Machine configuration entry file not found: "%s"', modXMLFilename)
                end
            end
        end

        xmlFile:delete()

        if numEntries > 0 then
            g_modController:debug('  Registered %i machine configurations', numEntries)
        end
    else
        Logging.warning('MachineManager:loadConfigurationsFromXMLFile() Failed to load configurations file: %s', tostring(xmlFilename))
    end
end

function MachineManager:loadInternalConfigurations()
    self:loadConfigurationsFromXMLFile(MachineManager.CONFIGURATIONS_FILE, g_modName)
end

function MachineManager:loadModsConfigurations()
    ---@type Mod[]
    local mods = g_modManager:getActiveMods()

    for _, mod in ipairs(mods) do
        if mod.modName ~= g_modName then
            ---@type string?
            local xmlFilename

            if fileExists(mod.modDir .. 'machineConfigurations.xml') then
                xmlFilename = mod.modDir .. 'machineConfigurations.xml'
            elseif fileExists(mod.modDir .. 'xml/machineConfigurations.xml') then
                xmlFilename = mod.modDir .. 'xml/machineConfigurations.xml'
            end

            if xmlFilename ~= nil then
                self:loadConfigurationsFromXMLFile(xmlFilename, mod.modName)
            end
        end
    end
end

function MachineManager:onModsLoaded()
    self:loadInternalConfigurations()
    self:loadModsConfigurations()

    self.displayWarning = g_client ~= nil and g_modName ~= 'FS25_0_TerraFarm'
end

function MachineManager:consoleReloadConfigurations()
    if g_server ~= nil and not g_currentMission.missionDynamicInfo.isMultiplayer then
        self.configurations = {}

        self:loadInternalConfigurations()
        self:loadModsConfigurations()

        return 'Mods configurations reloaded'
    end

    return 'Only available in single player'
end

---@param name string?
function MachineManager:consoleVerifyModConfigurations(name)
    if name ~= nil then
        if g_modIsLoaded[name] then
            local found, notFound = self:verifyModConfigurations(name)

            Logging.info('%i config entries verified', #found)

            for _, file in ipairs(notFound) do
                Logging.warning('File not found: %s', file)
            end

            return
        else
            return string.format('Mod "%s" is not loaded', name)
        end
    end

    return 'Usage: tfVerifyModConfigurations <modName>'
end

function MachineManager:consoleVerifyAllModsConfigurations()
    ---@type table<string, string[]>
    local modConfigs = {}

    for vehicleFilename, _ in pairs(self.configurations) do
        ---@type string
        local modName = vehicleFilename:split('/')[1]

        if modName ~= 'data' and not modName:startsWith('pdlc') and g_modIsLoaded[modName] then
            if modConfigs[modName] == nil then
                modConfigs[modName] = {}
            end

            table.insert(modConfigs[modName], g_modsDirectory .. vehicleFilename)
        end
    end

    for modName, files in pairs(modConfigs) do
        Logging.info('Verifying configuration entries for mod "%s"', modName)

        ---@type string[]
        local found = {}
        ---@type string[]
        local notFound = {}

        for _, file in ipairs(files) do
            if fileExists(file) then
                table.insert(found, file)
            else
                table.insert(notFound, file)
            end
        end

        if #found > 0 then
            Logging.info('%i config entries verified', #found)
        end

        for _, file in ipairs(notFound) do
            Logging.warning('File not found: %s', file)
        end
    end

    return 'Done.'
end

---@param modName string
---@return string[] found
---@return string[] notFound
function MachineManager:verifyModConfigurations(modName)
    ---@type string[]
    local found = {}
    ---@type string[]
    local notFound = {}

    local cmp = modName .. '/'

    for vehicleFile, _ in pairs(self.configurations) do
        if vehicleFile:startsWith(cmp) then
            local file = g_modsDirectory .. vehicleFile

            if fileExists(file) then
                table.insert(found, g_modsDirectory .. vehicleFile)
            else
                table.insert(notFound, g_modsDirectory .. vehicleFile)
            end
        end
    end

    return found, notFound
end

--
-- Note: can be nil!
-- Omitted from return type because we only use it in MachineSpecialization:onLoad()
--
---@param id string
---@return MachineType
---@nodiscard
function MachineManager:getMachineTypeById(id)
    return self.types[id]
end

---@param type MachineType
function MachineManager:registerMachineType(type)
    if self.types[type.id] == nil then
        self.types[type.id] = type

        print(string.format("  Register machineType '%s'", type.id))
    else
        Logging.warning('Duplicate machine type ID: %s', type.id)
    end
end

---@param dt number
function MachineManager:update(dt)
    if g_currentMission ~= nil and g_localPlayer ~= nil then
        ---@diagnostic disable-next-line: param-type-mismatch
        self:setActiveVehicle(MachineUtils.getActiveVehicle(g_localPlayer:getCurrentVehicle()))
    else
        self:setActiveVehicle(nil)
    end
end

function MachineManager:onMapLoaded()
    if g_client ~= nil then
        g_currentMission:addUpdateable(self)
    end
end

---@diagnostic disable-next-line: lowercase-global
g_machineManager = MachineManager.new()
