---@type table<string, boolean>
local defaultExcludeFillTypes = {
    ['BARLEY'] = true,
    ['BEETROOT'] = true,
    ['CANOLA'] = true,
    ['CARROT'] = true,
    ['CHAFF'] = true,
    ['DRYGRASS_WINDROW'] = true,
    ['FERTILIZER'] = true,
    ['FORAGE'] = true,
    ['FORAGE_MIXING'] = true,
    ['GRAPE'] = true,
    ['GRASS_WINDROW'] = true,
    ['GREENBEAN'] = true,
    ['MAIZE'] = true,
    ['MANURE'] = true,
    ['MINERAL_FEED'] = true,
    ['OAT'] = true,
    ['OLIVE'] = true,
    ['PARSNIP'] = true,
    ['PEA'] = true,
    ['PIGFOOD'] = true,
    ['POTATO'] = true,
    ['RICE'] = true,
    ['RICELONGGRAIN'] = true,
    ['SEEDS'] = true,
    ['SILAGE'] = true,
    ['SORGHUM'] = true,
    ['SPINACH'] = true,
    ['STRAW'] = true,
    ['SUGARBEET'] = true,
    ['SUGARBEET_CUT'] = true,
    ['SUGARCANE'] = true,
    ['SUNFLOWER'] = true,
    ['SOYBEAN'] = true,
    ['WHEAT'] = true,
    ['WOODCHIPS'] = true,
}

---@class ModSettings
---@field materials Array<string>
---@field defaultEnabled boolean
---@field enabled boolean
---@field conversionModifier number
---@field hudEnabled boolean
---@field debugMachineNodes boolean
---@field debugMachineCalibration boolean
---@field experimental_dischargePaintModifier number
ModSettings = {}

ModSettings.MOD_SETTINGS_FOLDER = g_currentModSettingsDirectory
ModSettings.XML_FILENAME_USER_SETTINGS = g_currentModSettingsDirectory .. 'userSettings.xml'

local ModSettings_mt = Class(ModSettings)

---@return ModSettings
---@nodiscard
function ModSettings.new()
    ---@type ModSettings
    local self = setmetatable({}, ModSettings_mt)

    self.materials = {}
    self.defaultEnabled = true
    self.enabled = true
    self.conversionModifier = 1
    self.hudEnabled = true
    self.debugMachineNodes = true
    self.debugMachineCalibration = true

    -- Experimental settings
    self.experimental_dischargePaintModifier = 1

    if g_client ~= nil then
        addConsoleCommand('tfSetConversionModifier', '', 'consoleSetConversionModifier', self)
        addConsoleCommand('tfSetDischargePaintModifier', '', 'consoleSetDischargePaintModifier', self)
    end

    return self
end

---@param defaultEnabled boolean
---@param noEventSend boolean | nil
function ModSettings:setDefaultEnabled(defaultEnabled, noEventSend)
    if self.defaultEnabled ~= defaultEnabled then
        SetDefaultEnabledEvent.sendEvent(defaultEnabled, noEventSend)

        self.defaultEnabled = defaultEnabled

        g_messageCenter:publish(SetDefaultEnabledEvent, defaultEnabled)
    end
end

---@return boolean
---@nodiscard
function ModSettings:getDefaultEnabled()
    return self.defaultEnabled
end

function ModSettings:setIsEnabled(enabled, noEventSend)
    if self.enabled ~= enabled then
        SetEnabledEvent.sendEvent(enabled, noEventSend)

        self.enabled = enabled

        g_messageCenter:publish(SetEnabledEvent, enabled)
    end
end

---@return boolean
---@nodiscard
function ModSettings:getIsEnabled()
    return self.enabled
end

---@param materials Array<string>
---@param noEventSend? boolean
function ModSettings:setMaterials(materials, noEventSend)
    if self.materials ~= materials then
        SetMaterialsEvent.sendEvent(materials, noEventSend)

        self.materials = materials

        g_messageCenter:publish(SetMaterialsEvent, materials)
    end
end

---@param enabled boolean
function ModSettings:setDebugNodes(enabled)
    self.debugMachineNodes = enabled

    self:saveUserSettings()
end

---@return boolean
---@nodiscard
function ModSettings:getDebugNodes()
    return self.debugMachineNodes
end

---@param enabled boolean
function ModSettings:setDebugCalibration(enabled)
    self.debugMachineCalibration = enabled

    self:saveUserSettings()

    g_modDebug:updateCalibration()
end

---@return boolean
---@nodiscard
function ModSettings:getDebugCalibration()
    return self.debugMachineCalibration
end

function ModSettings:getHUDIsVisible()
    return g_modHud.display.isVisible
end

---@return Array<string>
---@nodiscard
function ModSettings:getMaterials()
    return self.materials
end

---@private
function ModSettings:loadSettings()
    if g_server ~= nil then
        if g_currentMission.missionInfo.savegameDirectory ~= nil then
            local xmlFilename = g_currentMission.missionInfo.savegameDirectory .. '/terraFarmSettings.xml'

            ---@type XMLFile | nil
            local xmlFile = XMLFile.loadIfExists('modSettings', xmlFilename)

            if xmlFile ~= nil then
                self.enabled = xmlFile:getBool('settings.enabled', self.enabled)
                self.defaultEnabled = xmlFile:getBool('settings.defaultEnabled', self.defaultEnabled)

                g_resourceManager.active = xmlFile:getBool('settings.resourcesActive', g_resourceManager.active)

                self:loadMaterialSettings(xmlFile)

                xmlFile:delete()

                return
            end
        end

        self:setDefaultMaterials()
    end
end

---@param xmlFile XMLFile
---@private
function ModSettings:loadMaterialSettings(xmlFile)
    if xmlFile:hasProperty('settings.materials.material(0)') then
        self.materials = {}

        xmlFile:iterate('settings.materials.material', function (_, key)
            local fillTypeName = xmlFile:getString(key .. '#fillType')

            if fillTypeName ~= nil then
                ---@type FillTypeObject | nil
                local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName)

                if fillType ~= nil then
                    table.insert(self.materials, fillType.name)
                else
                    -- g_modDebug:debug('loadMaterials() fillType "%s" not found, skipping', fillTypeName)
                end
            end
        end)
    else
        self:setDefaultMaterials()
    end
end

---@param xmlFile XMLFile
function ModSettings:saveMaterialSettings(xmlFile)
    local i = 0

    for _, fillTypeName in ipairs(self.materials) do
        local key = string.format('settings.materials.material(%i)', i)
        xmlFile:setString(key .. '#fillType', fillTypeName)
        i = i + 1
    end
end

---@private
function ModSettings:setDefaultMaterials()
    self.materials = {}

    for _, index in ipairs(g_fillTypeManager:getFillTypesByCategoryNames('SHOVEL')) do
        ---@type string | nil
        local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(index)

        if fillTypeName ~= nil and defaultExcludeFillTypes[fillTypeName] ~= true then
            table.insert(self.materials, fillTypeName)
        end
    end
end

function ModSettings:saveSettings()
    if g_server ~= nil then
        local xmlFilename = g_currentMission.missionInfo.savegameDirectory .. '/terraFarmSettings.xml'

        ---@type XMLFile | nil
        local xmlFile = XMLFile.create('modSettings', xmlFilename, 'settings')

        if xmlFile ~= nil then
            xmlFile:setBool('settings.enabled', self.enabled)
            xmlFile:setBool('settings.defaultEnabled', self.defaultEnabled)
            xmlFile:setBool('settings.resourcesActive', g_resourceManager.active)

            self:saveMaterialSettings(xmlFile)

            xmlFile:save()
            xmlFile:delete()
        end
    end
end

function ModSettings:loadUserSettings()
    if g_client ~= nil then
        ---@type XMLFile | nil
        local xmlFile = XMLFile.loadIfExists('userSettings', ModSettings.XML_FILENAME_USER_SETTINGS)

        if xmlFile ~= nil then
            self.debugMachineNodes = xmlFile:getBool('userSettings.debugNodes', self.debugMachineNodes)
            self.debugMachineCalibration = xmlFile:getBool('userSettings.debugCalibration', self.debugMachineCalibration)
            self.hudEnabled = xmlFile:getBool('userSettings.hudEnabled', true)

            xmlFile:delete()
        end
    end
end

function ModSettings:saveUserSettings()
    if g_client ~= nil then
        createFolder(ModSettings.MOD_SETTINGS_FOLDER)

        ---@type XMLFile | nil
        local xmlFile = XMLFile.create('userSettings', ModSettings.XML_FILENAME_USER_SETTINGS, 'userSettings')

        if xmlFile ~= nil then
            xmlFile:setBool('userSettings.debugNodes', self.debugMachineNodes)
            xmlFile:setBool('userSettings.debugCalibration', self.debugMachineCalibration)
            xmlFile:setBool('userSettings.hudEnabled', self:getHUDIsVisible())

            xmlFile:save()
            xmlFile:delete()
        end
    end
end

function ModSettings:onMapLoaded()
    self:loadSettings()
end

---@param connection Connection
function ModSettings:onSendInitialClientState(connection)
    connection:sendEvent(SetEnabledEvent.new(self.enabled))
    connection:sendEvent(SetMaterialsEvent.new(self.materials))
    connection:sendEvent(SetDefaultEnabledEvent.new(self.defaultEnabled))
end

function ModSettings:onInitTerrain()
    if g_server ~= nil then
        self.conversionModifier = g_currentMission.terrainSize / g_currentMission.terrainDetailHeightMapSize * 1.85
    end
end

function ModSettings:consoleSetConversionModifier(modifier)
    if g_server ~= nil and not g_currentMission.missionDynamicInfo.isMultiplayer then
        if modifier ~= nil then
            local value = tonumber(modifier)

            if value ~= nil then
                self.conversionModifier = math.min(math.max(value, 0.1), 5)
            end
        end

        return 'conversionModifier: ' .. tostring(self.conversionModifier)
    else
        return 'Only available in single player'
    end
end

function ModSettings:consoleSetDischargePaintModifier(modifier)
    if g_server ~= nil and not g_currentMission.missionDynamicInfo.isMultiplayer then
        if modifier ~= nil then
            local value = tonumber(modifier)

            if value ~= nil then
                self.experimental_dischargePaintModifier = math.min(math.max(value, 0.001), 500)
            end
        end

        return 'dischargePaintModifier: ' .. tostring(self.experimental_dischargePaintModifier)
    else
        return 'Only available in single player'
    end
end

---@diagnostic disable-next-line: lowercase-global
g_modSettings = ModSettings.new()
