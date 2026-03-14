---@class WaterplaneColorData
---@field name string
---@field fogColor number[]
---@field fogDepth number[]

---@class LandscapingWaterplane
---@field uniqueId string
---@field name string
---@field targetY number
---@field color WaterplaneColor
---@field visible boolean
---@field points [number, number][]
LandscapingWaterplane = {}
LandscapingWaterplane.SEND_NUM_BITS_PLANES = 2 ^ 5
LandscapingWaterplane.MAX_NUM_PLANES = LandscapingWaterplane.SEND_NUM_BITS_PLANES - 1

---@enum WaterplaneColor
LandscapingWaterplane.COLOR = {
    NORTH_SEA_BLUE = 1,
    DARK_BLUE = 2,
    RIVER = 3,
    DIRTY = 4,
}

---@type table<WaterplaneColor, WaterplaneColorData>
LandscapingWaterplane.COLOR_DATA = {
    [LandscapingWaterplane.COLOR.NORTH_SEA_BLUE] = {
        name = 'North sea blue',
        fogColor = { 0.1, 0.21, 0.32, 1 },
        fogDepth = { 1.2, 1.5, 1, 0.7 }
    },
    [LandscapingWaterplane.COLOR.DARK_BLUE] = {
        name = 'Dark blue',
        fogColor = { 0.1, 0.21, 0.32, 0.2 },
        fogDepth = { 1.2, 1.5, 1, 0.7 }
    },
    [LandscapingWaterplane.COLOR.RIVER] = {
        name = 'River',
        fogColor = { 0.12, 0.14, 0.11, 1 },
        fogDepth = { 1.4, 1.2, 1, 1 }
    },
    [LandscapingWaterplane.COLOR.DIRTY] = {
        name = 'Dirty',
        fogColor = { 0.34, 0.24, 0.13, 0.5 },
        fogDepth = { 0.05, 1, 1, 1 }
    }
}


local LandscapingWaterplane_mt = Class(LandscapingWaterplane)

---@param schema XMLSchema
---@param key string
function LandscapingWaterplane.registerXMLPaths(schema, key)
    schema:register(XMLValueType.STRING, key .. '#uniqueId')
    schema:register(XMLValueType.STRING, key .. '#name')
    schema:register(XMLValueType.FLOAT, key .. '#targetY')
    schema:register(XMLValueType.INT, key .. '#color')
    schema:register(XMLValueType.BOOL, key .. '#visible')
    schema:register(XMLValueType.VECTOR_3, key .. '.points.point(?)#position')
end

---@param uniqueId? string
---@return LandscapingWaterplane
---@nodiscard
function LandscapingWaterplane.new(uniqueId)
    ---@type LandscapingWaterplane
    local self = setmetatable({}, LandscapingWaterplane_mt)

    self.uniqueId = uniqueId or ModUtils.createUniqueId()
    self.name = self.uniqueId
    self.targetY = math.huge
    self.points = {}
    self.visible = true
    self.color = LandscapingWaterplane.COLOR.DARK_BLUE

    return self
end

---@return LandscapingWaterplane
---@nodiscard
function LandscapingWaterplane:clone()
    local clone = LandscapingWaterplane.new(self.uniqueId)

    clone.name = self.name
    clone.visible = self.visible
    clone.color = self.color
    clone.targetY = self.targetY
    clone.points = table.clone(self.points, 2)

    return clone
end

---@return boolean
---@nodiscard
function LandscapingWaterplane:getIsRegistered()
    return g_landscapingManager:getWaterplaneByUniqueId(self.uniqueId) ~= nil
end

---@return boolean
---@nodiscard
function LandscapingWaterplane:getIsValid()
    return self.uniqueId ~= nil and self.targetY ~= math.huge and #self.points > 2
end

---@return boolean
---@nodiscard
function LandscapingWaterplane:getCanAddPoint()
    return #self.points <= LandscapingAreaPolygon.MAX_NUM_POINTS
end

---@return string
---@nodiscard
function LandscapingWaterplane:getName()
    return self.name or self.uniqueId
end

---@return number worldPosX
---@return number worldPosZ
function LandscapingWaterplane:getCameraFocusWorldPositionXZ()
    ---@diagnostic disable-next-line: param-type-mismatch
    return LandscapingAreaPolygon.getCameraFocusWorldPositionXZ(self)
end

---@return number[]
function LandscapingWaterplane:getVertices()
    local result = {}

    for _, pos in ipairs(self.points) do
        table.insert(result, pos[1])
        table.insert(result, pos[2])
    end

    return result
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
---@nodiscard
function LandscapingWaterplane:loadFromXMLFile(xmlFile, key)
    self.uniqueId = xmlFile:getValue(key .. '#uniqueId')

    if self.uniqueId == nil then
        Logging.xmlWarning(xmlFile, 'Missing #uniqueId (%s)', key)
        return false
    end

    self.name = xmlFile:getValue(key .. '#name', self.uniqueId)
    self.visible = xmlFile:getValue(key .. '#visible', self.visible)
    self.color = xmlFile:getValue(key .. '#color', self.color)
    self.targetY = xmlFile:getValue(key .. '#targetY', self.targetY)

    self.points = {}

    for _, itemKey in xmlFile:iterator(key .. '.points.point') do
        local x, _, z = xmlFile:getValue(itemKey .. '#position')

        table.insert(self.points, { x, z })
    end

    return true
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
---@nodiscard
function LandscapingWaterplane:saveToXMLFile(xmlFile, key)
    if self.uniqueId == nil then
        Logging.error('LandscapingWaterplane:saveToXMLFile() uniqueId is nil')
        return false
    end

    xmlFile:setValue(key .. '#uniqueId', self.uniqueId)
    xmlFile:setValue(key .. '#name', self.name)
    xmlFile:setValue(key .. '#visible', self.visible)
    xmlFile:setValue(key .. '#color', self.color)

    if self.targetY ~= math.huge then
        xmlFile:setValue(key .. '#targetY', self.targetY)
    end

    for i, point in ipairs(self.points) do
        local itemKey = string.format('%s.points.point(%i)', key, i - 1)
        xmlFile:setValue(itemKey .. '#position', point[1], 0, point[2])
    end

    return true
end

---@param streamId number
---@param connection Connection
function LandscapingWaterplane:writeStream(streamId, connection)
    streamWriteString(streamId, self.name)
    streamWriteBool(streamId, self.visible)
    streamWriteUInt8(streamId, self.color)

    if streamWriteBool(streamId, self.targetY ~= math.huge) then
        streamWriteFloat32(streamId, self.targetY)
    end

    streamWriteUIntN(streamId, #self.points, LandscapingAreaPolygon.SEND_NUM_BITS_POINTS)

    for _, point in ipairs(self.points) do
        ModUtils.writeCompressedXYZPos(streamId, point[1], 0, point[2])
    end
end

---@param streamId number
---@param connection Connection
function LandscapingWaterplane:readStream(streamId, connection)
    self.name = streamReadString(streamId)
    self.visible = streamReadBool(streamId)
    self.color = streamReadUInt8(streamId)

    if streamReadBool(streamId) then
        self.targetY = streamReadFloat32(streamId)
    end

    local numPoints = streamReadUIntN(streamId, LandscapingAreaPolygon.SEND_NUM_BITS_POINTS)

    self.points = {}

    for _ = 1, numPoints do
        local x, _, z = ModUtils.readCompressedXYZPos(streamId)
        table.insert(self.points, { x, z })
    end
end

---@param shapeNode number
---@param rootNode number
---@param childNodes number[]
function LandscapingWaterplane:updateAreaBorder(shapeNode, rootNode, childNodes)
    ---@diagnostic disable-next-line: param-type-mismatch
    LandscapingAreaPolygon.updateAreaBorder(self, shapeNode, rootNode, childNodes)
end
