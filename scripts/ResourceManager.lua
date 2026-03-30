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

    g_modController:subscribe(ModEvent.onTerrainInit, self.onInitTerrain, self)
    g_modController:subscribe(ModEvent.onSendInitialClientState, self.onSendInitialClientState, self)

    return self
end

---@param active boolean
---@param noEventSend boolean?
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
---@return ResourceLayer?
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
---@return ResourceLayer?
---@nodiscard
function ResourceManager:getResourceLayerAtWorldPos(worldPosX, worldPosZ)
    local value = self:getValueAtWorldPos(worldPosX, worldPosZ)

    return self.layers[value] or self.layers[0]
end

---@param worldPosX number      # X position in world space
---@param worldPosZ number      # Z position in world space
---@param first number?    # First channel
---@param channels number? # Number of channels
---@return number
---@nodiscard
function ResourceManager:getValueAtWorldPos(worldPosX, worldPosZ, first, channels)
    ---@diagnostic disable-next-line: param-type-mismatch
    local x, y = InfoLayer.convertWorldToLocalPosition(self, worldPosX, worldPosZ)

    return getBitVectorMapPoint(self.infoLayerId, x, y, first or 0, channels or self.numChannels)
end

---@param worldPosX number
---@param worldPosZ number
---@return FillTypeObject?
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
        local xmlFile = ModUtils.loadMapDirectoryXMLFile('mapGroundResources', 'mapGroundResources.xml', ResourceManager.xmlSchema)

        if xmlFile ~= nil then
            if xmlFile:hasProperty('groundResources.layers(0)') then
                self.infoLayerName = xmlFile:getString('groundResources#infoLayer', self.infoLayerName)

                self:loadResourceLayers(xmlFile, 'groundResources.layers')
                self:loadInfoLayer()
            else
                Logging.xmlWarning(xmlFile, 'No ground resource layers found')
            end

            xmlFile:delete()

            if self.available then
                Logging.info('ResourceManager:onTerrainInitialized() Map resources extension enabled')
            else
                Logging.info('ResourceManager:onTerrainInitialized() Map resources extension disabled')
            end
        end
    end
end

function ResourceManager:loadInfoLayer()
    if g_terrainNode == nil then
        Logging.error('ResourceManager:loadInfoLayer() g_terrainNode is nil')
        return
    end

    self.infoLayerId = getInfoLayerFromTerrain(g_terrainNode, self.infoLayerName)

    if self.infoLayerId ~= 0 and self.infoLayerId ~= nil then
        self.numChannels = getBitVectorMapNumChannels(self.infoLayerId)
        self.width, self.height = getBitVectorMapSize(self.infoLayerId)

        self.available = true
    else
        Logging.warning('ResourceManager:loadInfoLayer() Failed to load map infoLayer: %s', tostring(self.infoLayerName))
    end
end

---@param xmlFile XMLFile
---@param basePath string
function ResourceManager:loadResourceLayers(xmlFile, basePath)
    for _, key in xmlFile:iterator(basePath .. '.layer') do
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

        -- g_modController:debug('Found map resource layer: %s (bit: %i)', fillTypeName, bitValue)
    end

    if self.layers[0] == nil then
        Logging.xmlError(xmlFile, 'ResourceManager:loadResourceLayers() Default layer "0" not defined')
        self.available = false
    end
end

---@diagnostic disable-next-line: lowercase-global
g_resourceManager = ResourceManager.new()
