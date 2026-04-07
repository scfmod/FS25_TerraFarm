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
---@field materials string[]
---@field defaultEnabled boolean
---@field enabled boolean
---@field hudEnabled boolean
---@field debugMachineNodes boolean
---@field debugMachineCalibration boolean
ModSettings = {}

ModSettings.XML_FILENAME_USER_SETTINGS = g_modDirectorySettings .. 'userSettings.xml'

local ModSettings_mt = Class(ModSettings)

---@return ModSettings
---@nodiscard
function ModSettings.new()
    ---@type ModSettings
    local self = setmetatable({}, ModSettings_mt)

    self.materials = {}
    self.defaultEnabled = true
    self.enabled = true
    self.hudEnabled = true
    self.debugMachineNodes = true
    self.debugMachineCalibration = true

    g_modController:subscribe(ModEvent.onMapLoaded, self.onMapLoaded, self)
    g_modController:subscribe(ModEvent.onTerrainInit, self.onInitTerrain, self)
    g_modController:subscribe(ModEvent.onSendInitialClientState, self.onSendInitialClientState, self)

    return self
end

---@param defaultEnabled boolean
---@param noEventSend boolean?
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

---@param materials string[]
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
end

---@return boolean
---@nodiscard
function ModSettings:getDebugCalibration()
    return self.debugMachineCalibration
end

function ModSettings:getHUDIsVisible()
    return g_modHud.display.isVisible
end

---@return string[]
---@nodiscard
function ModSettings:getMaterials()
    return self.materials
end

---@return string?
function ModSettings:getSavegameDirectory()
    if g_currentMission ~= nil and g_currentMission.missionInfo ~= nil then
        return g_currentMission.missionInfo.savegameDirectory
    end
end

---@private
function ModSettings:loadSettings()
    if g_server ~= nil then
        local xmlFile = ModUtils.loadSavegameDirectoryXMLFile('modSettings', 'terraFarmSettings.xml')

        if xmlFile ~= nil then
            self.enabled = xmlFile:getBool('settings.enabled', self.enabled)
            self.defaultEnabled = xmlFile:getBool('settings.defaultEnabled', self.defaultEnabled)

            g_resourceManager.active = xmlFile:getBool('settings.resourcesActive', g_resourceManager.active)

            self:loadMaterialSettings(xmlFile)

            xmlFile:delete()
        else
            self:setDefaultMaterials()
        end
    end
end

---@param xmlFile XMLFile
---@private
function ModSettings:loadMaterialSettings(xmlFile)
    if xmlFile:hasProperty('settings.materials.material(0)') then
        self.materials = {}

        for _, key in xmlFile:iterator('settings.materials.material') do
            local fillTypeName = xmlFile:getString(key .. '#fillType')

            if fillTypeName ~= nil then
                ---@type FillTypeObject?
                local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName)

                if fillType ~= nil then
                    table.insert(self.materials, fillType.name)
                else
                    g_modController:debug('ModSettings:loadMaterialSettings() fillType "%s" not found, skipping', fillTypeName)
                end
            end
        end
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
        ---@type string?
        local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(index)

        if fillTypeName ~= nil and defaultExcludeFillTypes[fillTypeName] ~= true then
            table.insert(self.materials, fillTypeName)
        end
    end
end

function ModSettings:saveSettings()
    if g_server ~= nil then
        local xmlFile = ModUtils.createSavegameDirectoryXMLFile('modSettings', 'terraFarmSettings.xml', 'settings')

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
        ---@type XMLFile?
        local xmlFile = XMLFile.loadIfExists('userSettings', ModSettings.XML_FILENAME_USER_SETTINGS)

        if xmlFile ~= nil then
            self.debugMachineNodes = xmlFile:getBool('userSettings.debugNodes', self.debugMachineNodes)
            self.debugMachineCalibration = xmlFile:getBool('userSettings.debugCalibration', self.debugMachineCalibration)
            self.hudEnabled = xmlFile:getBool('userSettings.hudEnabled', true)

            if xmlFile:getBool('userSettings.areaBorderVisible') == false then
                g_landscapingManager:setBorderVisibilityMode(BorderVisibilityMode.ACTIVE_ONLY, true)
            else
                g_landscapingManager:setBorderVisibilityMode(xmlFile:getInt('userSettings.borderVisibilityMode', g_landscapingManager.borderVisibilityMode), true)
            end

            local borderBode = xmlFile:getInt('userSettings.areaBorderMode', xmlFile:getInt('userSettings.borderMode', g_landscapingManager.borderMode))

            g_landscapingManager:setBorderMode(borderBode, true)

            xmlFile:delete()
        end
    end
end

function ModSettings:saveUserSettings()
    if g_client ~= nil then
        createFolder(g_modDirectorySettings)

        ---@type XMLFile?
        local xmlFile = XMLFile.create('userSettings', ModSettings.XML_FILENAME_USER_SETTINGS, 'userSettings')

        if xmlFile ~= nil then
            xmlFile:setBool('userSettings.debugNodes', self.debugMachineNodes)
            xmlFile:setBool('userSettings.debugCalibration', self.debugMachineCalibration)
            xmlFile:setBool('userSettings.hudEnabled', self:getHUDIsVisible())

            xmlFile:setInt('userSettings.borderVisibilityMode', g_landscapingManager.borderVisibilityMode)
            xmlFile:setInt('userSettings.borderMode', g_landscapingManager.borderMode)

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

---@diagnostic disable-next-line: lowercase-global
g_modSettings = ModSettings.new()
