---@class LandscapingArea : ClassObject
---@field className string
---@field uniqueId string
---@field name? string
---@field icon number
---@field color number
---@field restrictArea boolean
---@field forceFillTypeIndex? number
---@field forceInputLayer? number
---@field forceOutputLayer? number
---@field points number[][]
---@field visible boolean
LandscapingArea = {}
LandscapingArea.CLASS_NAME = ''
LandscapingArea.TYPE_NAME = ''

---@type XMLSchema
LandscapingArea.XML_SCHEMA = nil
LandscapingArea.SEND_NUM_BITS_AREAS = 2 ^ 6
LandscapingArea.MAX_NUM_AREAS = LandscapingArea.SEND_NUM_BITS_AREAS - 1

---@param schema XMLSchema
---@param key string
function LandscapingArea.registerXMLPaths(schema, key)
    schema:register(XMLValueType.STRING, key .. '#className')
    schema:register(XMLValueType.STRING, key .. '#uniqueId')
    schema:register(XMLValueType.STRING, key .. '#name')
    schema:register(XMLValueType.INT, key .. '#icon')
    schema:register(XMLValueType.INT, key .. '#color')
    schema:register(XMLValueType.BOOL, key .. '#restrictArea')
    schema:register(XMLValueType.STRING, key .. '#forceFillType')
    schema:register(XMLValueType.STRING, key .. '#forceInputLayer')
    schema:register(XMLValueType.STRING, key .. '#forceOutputLayer')
end

function LandscapingArea.createXMLSchema()
    local schema = XMLSchema.new('LandscapingArea')
    local key = 'areas.landscaping.area(?)'

    LandscapingArea.registerXMLPaths(schema, key)
    LandscapingAreaPolygon.registerXMLPaths(schema, key)
    LandscapingAreaPath.registerXMLPaths(schema, key)

    LandscapingWaterplane.registerXMLPaths(schema, 'areas.waterplanes.area(?)')

    LandscapingArea.XML_SCHEMA = schema
end

---@param uniqueId? string
---@param className string
---@param customMt table
---@return LandscapingArea
---@nodiscard
function LandscapingArea.new(uniqueId, className, customMt)
    ---@type LandscapingArea
    local self = setmetatable({}, customMt)

    self.uniqueId = uniqueId or ModUtils.createUniqueId()
    self.className = className
    self.name = self.uniqueId
    self.restrictArea = true
    self.icon = 1
    self.color = 1
    self.visible = true

    return self
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
---@nodiscard
function LandscapingArea:loadFromXMLFile(xmlFile, key)
    self.uniqueId = xmlFile:getValue(key .. '#uniqueId')

    if self.uniqueId == nil then
        Logging.xmlWarning(xmlFile, 'Missing #uniqueId (%s)', key)
        return false
    end

    self.name = xmlFile:getValue(key .. '#name', self.uniqueId)
    self.restrictArea = xmlFile:getValue(key .. '#restrictArea', self.restrictArea)
    self.icon = xmlFile:getValue(key .. '#icon', self.icon)
    self.color = xmlFile:getValue(key .. '#color', self.color)

    local forceFillTypeName = xmlFile:getValue(key .. '#forceFillType')

    if forceFillTypeName ~= nil then
        self.forceFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(forceFillTypeName)
    end

    local inputLayer = g_landscapingManager:getTerrainLayerByName(xmlFile:getValue(key .. '#forceInputLayer'))

    if inputLayer ~= nil then
        self.forceInputLayer = inputLayer.id
    end

    local outputLayer = g_landscapingManager:getTerrainLayerByName(xmlFile:getValue(key .. '#forceOutputLayer'))

    if outputLayer ~= nil then
        self.forceOutputLayer = outputLayer.id
    end

    return true
end

---@param xmlFile XMLFile
---@param key string
function LandscapingArea:saveToXMLFile(xmlFile, key)
    if self.uniqueId ~= nil then
        xmlFile:setValue(key .. '#uniqueId', self.uniqueId)
    end
    xmlFile:setValue(key .. '#className', self.className)
    xmlFile:setValue(key .. '#name', self.name)
    xmlFile:setValue(key .. '#restrictArea', self.restrictArea)
    xmlFile:setValue(key .. '#icon', self.icon)
    xmlFile:setValue(key .. '#color', self.color)

    if self.forceFillTypeIndex ~= nil then
        local fillType = g_fillTypeManager:getFillTypeByIndex(self.forceFillTypeIndex)

        if fillType ~= nil then
            xmlFile:setValue(key .. '#forceFillType', fillType.name)
        end
    end

    if self.forceInputLayer ~= nil then
        local layerName = getTerrainLayerName(g_terrainNode, self.forceInputLayer)

        if layerName ~= nil then
            xmlFile:setValue(key .. '#forceInputLayer', layerName)
        end
    end

    if self.forceOutputLayer ~= nil then
        local layerName = getTerrainLayerName(g_terrainNode, self.forceOutputLayer)

        if layerName ~= nil then
            xmlFile:setValue(key .. '#forceOutputLayer', layerName)
        end
    end
end

---@return string
---@nodiscard
function LandscapingArea:getTypeName()
    return self.TYPE_NAME
end

---@return boolean
---@nodiscard
function LandscapingArea:getIsRegistered()
    return g_landscapingManager:getAreaByUniqueId(self.uniqueId) ~= nil
end

---@return string
---@nodiscard
function LandscapingArea:getName()
    return self.name or self.uniqueId or 'nil'
end

---@return string
---@nodiscard
function LandscapingArea:getIconSliceId()
    return LandscapingUtils.getAreaIconSliceId(self.icon)
end

---@generic T
---@return T
---@nodiscard
function LandscapingArea:clone()
    ---@diagnostic disable-next-line: missing-return
    assert(false, 'LandscapingArea:clone() must be implemented by inherited class')
end

---@param area LandscapingArea
function LandscapingArea:copyInto(area)
    area.uniqueId = self.uniqueId
    area.name = self.name
    area.icon = self.icon
    area.color = self.color
    area.restrictArea = self.restrictArea
    area.forceFillTypeIndex = self.forceFillTypeIndex
    area.forceInputLayer = self.forceInputLayer
    area.forceOutputLayer = self.forceOutputLayer

    -- Client side only
    area.visible = self.visible
end

---@param shape number
---@param rootNode number
---@param childNodes number[]
function LandscapingArea:updateAreaBorder(shape, rootNode, childNodes)
    -- void
end

---@return boolean
---@nodiscard
function LandscapingArea:getIsValid()
    return self.uniqueId ~= nil
end

---@param x number
---@param y number
---@param z number
---@return boolean
---@nodiscard
function LandscapingArea:getIsInsideArea(x, y, z)
    return false
end

---@return boolean
---@nodiscard
function LandscapingArea:getCanAddPoint()
    return false
end

---@param visible boolean
function LandscapingArea:setIsVisible(visible)
    if self.visible ~= visible then
        self.visible = visible

        g_landscapingManager:updateAreaBorderVisibility(self)
    end
end

---@param x number worldPosX
---@param y number worldPosY
---@param z number worldPosZ
---@return boolean valid
---@return number targetY
---@return number minY
---@return number maxY
---@return number nx
---@return number ny
---@return number nz
---@return number direction
function LandscapingArea:getDeformationParams(x, y, z)
    ---@diagnostic disable-next-line: missing-return
    assert(false, 'LandscapingArea:getSlopeDeformationParams() must be implemented by inherited class')
end

---@return number worldPosX -- Set to math.huge if no position is set/available
---@return number worldPosZ
function LandscapingArea:getCameraFocusWorldPositionXZ()
    return math.huge, 0
end

---@param streamId number
---@param connection Connection
function LandscapingArea:writeStream(streamId, connection)
    streamWriteBool(streamId, self.restrictArea)
    streamWriteUIntN(streamId, self.icon, 4)
    streamWriteUIntN(streamId, self.color, 4)

    if streamWriteBool(streamId, self.name ~= nil) then
        streamWriteString(streamId, self.name)
    end

    if streamWriteBool(streamId, self.forceFillTypeIndex ~= nil) then
        streamWriteUIntN(streamId, self.forceFillTypeIndex, FillTypeManager.SEND_NUM_BITS)
    end

    if streamWriteBool(streamId, self.forceInputLayer ~= nil) then
        streamWriteUIntN(streamId, self.forceInputLayer, TerrainDeformation.LAYER_SEND_NUM_BITS)
    end

    if streamWriteBool(streamId, self.forceOutputLayer ~= nil) then
        streamWriteUIntN(streamId, self.forceOutputLayer, TerrainDeformation.LAYER_SEND_NUM_BITS)
    end
end

---@param streamId number
---@param connection Connection
function LandscapingArea:readStream(streamId, connection)
    self.restrictArea = streamReadBool(streamId)
    self.icon = streamReadUIntN(streamId, 4)
    self.color = streamReadUIntN(streamId, 4)

    if streamReadBool(streamId) then
        self.name = streamReadString(streamId)
    else
        self.name = nil
    end

    if streamReadBool(streamId) then
        self.forceFillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
    else
        self.forceFillTypeIndex = nil
    end

    if streamReadBool(streamId) then
        self.forceInputLayer = streamReadUIntN(streamId, TerrainDeformation.LAYER_SEND_NUM_BITS)
    else
        self.forceInputLayer = nil
    end

    if streamReadBool(streamId) then
        self.forceOutputLayer = streamReadUIntN(streamId, TerrainDeformation.LAYER_SEND_NUM_BITS)
    else
        self.forceOutputLayer = nil
    end
end

---@return number[] diffuseColor
---@return number[] decalColor
---@nodiscard
function LandscapingArea:getBorderColor()
    return LandscapingUtils.getAreaColorByIndex(self.color)
end
