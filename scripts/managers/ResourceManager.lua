---@class TerrainLayer
---@field id number
---@field name string
---@field title string

---@class ResourceLayer
---@field bit number
---@field fillTypeName string
---@field layerInputName string
---@field layerOutputName string
---@field yield number

---@class ResourceManager
---@field available boolean
---@field active boolean
---@field layers ResourceLayer[]
---@field infoLayerName string
---@field infoLayerId number
---@field numChannels number
---@field width number
---@field height number
---
---@field terrainLayers TerrainLayer[]
---@field nameToTerrainLayer table<string, TerrainLayer>
---@field idToTerrainLayer table<number, TerrainLayer>
ResourceManager = {}

ResourceManager.xmlSchema = (function ()
    ---@type XMLSchema
    local schema = XMLSchema.new('groundResources')

    schema:register(XMLValueType.STRING, 'groundResources#infoLayer')
    schema:register(XMLValueType.INT, 'groundResources.layers.layer(?)#value', nil, nil, true)
    schema:register(XMLValueType.STRING, 'groundResources.layers.layer(?)#fillType', nil, nil, true)
    schema:register(XMLValueType.STRING, 'groundResources.layers.layer(?)#paintLayer', nil, nil, true)
    schema:register(XMLValueType.STRING, 'groundResources.layers.layer(?)#paintLayerDischarge')
    schema:register(XMLValueType.FLOAT, 'groundResources.layers.layer(?)#yield')

    return schema
end)()

local ResourceManager_mt = Class(ResourceManager)

---@return ResourceManager
---@nodiscard
function ResourceManager.new()
    ---@type ResourceManager
    local self = setmetatable({}, ResourceManager_mt)

    self.active = true
    self.available = false

    self.layers = {}
    self.infoLayerName = 'mapGroundResources'
    self.infoLayerId = 0
    self.numChannels = 0
    self.width = 0
    self.height = 0

    self.terrainLayers = {}
    self.nameToTerrainLayer = {}
    self.idToTerrainLayer = {}

    return self
end

---@param active boolean
---@param noEventSend boolean | nil
function ResourceManager:setIsActive(active, noEventSend)
    if self.available and self.active ~= active then
        SetResourcesEvent.sendEvent(true, active, noEventSend)

        self.active = active

        g_messageCenter:publish(SetResourcesEvent, true, active)
    end
end

---@return boolean
---@nodiscard
function ResourceManager:getIsActive()
    return self.available and self.active
end

---@return boolean
---@nodiscard
function ResourceManager:getIsAvailable()
    return self.available
end

---@param id number
---@return ResourceLayer | nil
---@nodiscard
function ResourceManager:getResourceLayer(id)
    return self.layers[id]
end

---@param layer ResourceLayer
---@param isOutput boolean
---@return number
---@nodiscard
function ResourceManager:getResourcePaintLayerId(layer, isOutput)
    if isOutput then
        return self.nameToTerrainLayer[layer.layerOutputName].id
    end

    return self.nameToTerrainLayer[layer.layerInputName].id
end

---@param worldPosX number
---@param worldPosZ number
---@param isOutput boolean
---@return number
---@nodiscard
function ResourceManager:getPaintLayerIdAtWorldPosition(worldPosX, worldPosZ, isOutput)
    local layer = self:getResourceLayerAtWorldPos(worldPosX, worldPosZ)

    if layer ~= nil then
        return self:getResourcePaintLayerId(layer, isOutput)
    end

    return 0
end

---@param worldPosX number
---@param worldPosZ number
---@return ResourceLayer | nil
---@nodiscard
function ResourceManager:getResourceLayerAtWorldPos(worldPosX, worldPosZ)
    local value = self:getValueAtWorldPos(worldPosX, worldPosZ)

    return self.layers[value] or self.layers[0]
end

---@param worldPosX number      # X position in world space
---@param worldPosZ number      # Z position in world space
---@param first number | nil    # First channel
---@param channels number | nil # Number of channels
---@return number
---@nodiscard
function ResourceManager:getValueAtWorldPos(worldPosX, worldPosZ, first, channels)
    ---@diagnostic disable-next-line: param-type-mismatch
    local x, y = InfoLayer.convertWorldToLocalPosition(self, worldPosX, worldPosZ)

    return getBitVectorMapPoint(self.infoLayerId, x, y, first or 0, channels or self.numChannels)
end

---@param worldPosX number
---@param worldPosZ number
---@return FillTypeObject | nil
---@nodiscard
function ResourceManager:getFillTypeAtWorldPos(worldPosX, worldPosZ)
    local layer = self:getResourceLayerAtWorldPos(worldPosX, worldPosZ)

    if layer ~= nil then
        return g_fillTypeManager:getFillTypeByName(layer.fillTypeName)
    end
end

---@param connection Connection
function ResourceManager:onSendInitialClientState(connection)
    connection:sendEvent(SetResourcesEvent.new(self.available, self.active))
end

function ResourceManager:onInitTerrain()
    if g_server ~= nil then
        local mapXMLDirectory = Utils.getDirectory(g_currentMission.missionInfo.mapXMLFilename)
        local mapResourcesFile = g_currentMission.baseDirectory .. mapXMLDirectory .. 'mapGroundResources.xml'

        if fileExists(mapResourcesFile) then
            ---@type XMLFile | nil
            local xmlFile = XMLFile.load('mapGroundResources', mapResourcesFile, ResourceManager.xmlSchema)

            if xmlFile ~= nil then
                if xmlFile:hasProperty('groundResources.layers(0)') then
                    self.infoLayerName = xmlFile:getString('groundResources#infoLayer', self.infoLayerName)

                    self:loadResourceLayers(xmlFile, 'groundResources.layers')
                    self:loadInfoLayer()

                    g_modDebug:debug('ResourceManager:onTerrainInitialized() Map extension enabled')
                else
                    g_modDebug:debug('ResourceManager:onTerrainInitialized() Map extension disabled - no layers')
                end

                xmlFile:delete()
            else
                Logging.warning('ResourceManager:onTerrainInitialized() Failed to open: %s', mapResourcesFile)
            end
        end
    end

    self:loadTerrainLayers()
end

function ResourceManager:loadInfoLayer()
    if g_terrainNode == nil then
        Logging.error('g_terrainNode is nil')
        return
    end

    self.infoLayerId = getInfoLayerFromTerrain(g_terrainNode, self.infoLayerName)

    if self.infoLayerId ~= 0 and self.infoLayerId ~= nil then
        self.numChannels = getBitVectorMapNumChannels(self.infoLayerId)
        self.width, self.height = getBitVectorMapSize(self.infoLayerId)

        self.available = true

        g_modDebug:debug('ResourceManager:loadInfoLayer() Map resources extension available')
    else
        Logging.warning('ResourceManager:loadInfoLayer() Failed to load map infoLayer: %s', tostring(self.infoLayerName))
    end
end

---@param xmlFile XMLFile
---@param basePath string
function ResourceManager:loadResourceLayers(xmlFile, basePath)
    xmlFile:iterate(basePath .. '.layer', function (_, key)
        local bitValue = xmlFile:getValue(key .. '#value')
        local fillTypeName = xmlFile:getValue(key .. '#fillType')
        local layerInput = xmlFile:getValue(key .. '#paintLayer')
        local layerOutput = xmlFile:getValue(key .. '#paintLayerDischarge', layerInput)
        local yield = xmlFile:getValue(key .. '#yield', 1.0)

        if bitValue == nil then
            Logging.xmlError(xmlFile, 'Missing "bit" field (%s)', key)
            return
        elseif self.layers[bitValue] ~= nil then
            Logging.xmlError(xmlFile, 'Duplicate bit entry: %i (%s)', bitValue, key)
            return
        elseif fillTypeName == nil then
            Logging.xmlError(xmlFile, 'Missing "fillType" field (%s)', key)
            return
        elseif layerInput == nil then
            Logging.xmlError(xmlFile, 'Missing "paintLayer" field (%s)', key)
            return
        end

        ---@type ResourceLayer
        local layer = {
            bit = bitValue,
            fillTypeName = fillTypeName,
            layerInputName = layerInput,
            layerOutputName = layerOutput,
            yield = yield
        }

        self.layers[bitValue] = layer

        -- g_machineDebug:debug('Found map resource layer: %s (bit: %i)', fillTypeName, bitValue)
    end)

    if self.layers[0] == nil then
        Logging.error('ResourceManager:loadResourceLayers() Default layer "0" not defined (%s)', xmlFile.filename)
        self.available = false
    end
end

function ResourceManager:loadTerrainLayers()
    local numLayers = getTerrainNumOfLayers(g_terrainNode)

    for i = 0, numLayers - 1 do
        local numSubLayers = getTerrainLayerNumOfSubLayers(g_terrainNode, i)

        if numSubLayers > 1 then
            local name = getTerrainLayerName(g_terrainNode, i)
            local title = MachineUtils.getGroundLayerTitle(name)

            if title:contains('_') then
                title = title:gsub('_', ' ')
                title = title:lower()
                title = title:gsub("^%l", string.upper)
            elseif title:upper() == title then
                title = title:lower()
                title = title:gsub("^%l", string.upper)
            end

            local layer = {
                id = i,
                name = name,
                title = title
            }

            table.insert(self.terrainLayers, layer)

            if self.nameToTerrainLayer[name] ~= nil then
                Logging.warning('  Duplicate layer name found: %s', name)
            end

            self.nameToTerrainLayer[name] = layer
            self.idToTerrainLayer[i] = layer

            -- Logging.info('  Layer | id: %i  name: %s  title: %s', i, name, tostring(title))
        end
    end

    -- Logging.info('Found a total of %i terrain layers', #self.terrainLayers)

    table.sort(self.terrainLayers, function (a, b)
        return a.title < b.title
    end)
end

---@return TerrainLayer
---@nodiscard
function ResourceManager:getDefaultTerrainLayer()
    for _, name in ipairs(Machine.DEFAULT_TERRAIN_LAYERS) do
        if self.nameToTerrainLayer[name] ~= nil then
            return self.nameToTerrainLayer[name]
        end
    end

    return self.terrainLayers[1]
end

---@return number
---@nodiscard
function ResourceManager:getDefaultTerrainLayerId()
    local layer = self:getDefaultTerrainLayer()

    return layer and layer.id or 0
end

---@return FillTypeObject
---@nodiscard
function ResourceManager:getDefaultFillType()
    local fillType = g_fillTypeManager:getFillTypeByName(Machine.DEFAULT_FILLTYPE)

    return fillType or g_fillTypeManager.fillTypes[1]
end

---@return number
---@nodiscard
function ResourceManager:getDefaultFillTypeIndex()
    local fillType = self:getDefaultFillType()

    return fillType and fillType.index or FillType.UNKNOWN
end

---@param id number
---@return TerrainLayer
---@nodiscard
function ResourceManager:getTerrainLayerById(id)
    return self.idToTerrainLayer[id]
end

---@param name string
---@return TerrainLayer | nil
---@nodiscard
function ResourceManager:getTerrainLayerByName(name)
    return self.nameToTerrainLayer[name]
end

---@diagnostic disable-next-line: lowercase-global
g_resourceManager = ResourceManager.new()
