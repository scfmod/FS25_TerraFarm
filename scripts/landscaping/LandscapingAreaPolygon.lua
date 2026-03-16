---@class LandscapingAreaPolygon : LandscapingArea
---@field targetY number
---@field points [number, number][]
---@field superClass fun(): LandscapingArea
LandscapingAreaPolygon = {}
LandscapingAreaPolygon.CLASS_NAME = 'LandscapingAreaPolygon'
LandscapingAreaPolygon.TYPE_NAME = g_i18n:getText('ui_areaPolygon')
LandscapingAreaPolygon.SEND_NUM_BITS_POINTS = 6
LandscapingAreaPolygon.MAX_NUM_POINTS = 2 ^ LandscapingAreaPolygon.SEND_NUM_BITS_POINTS - 1

local LandscapingAreaPolygon_mt = Class(LandscapingAreaPolygon, LandscapingArea)

---@param schema XMLSchema
---@param key string
function LandscapingAreaPolygon.registerXMLPaths(schema, key)
    schema:register(XMLValueType.VECTOR_3, key .. '.points.point(?)#position')
    schema:register(XMLValueType.FLOAT, key .. '#targetY')
end

---@param uniqueId? string
---@return LandscapingAreaPolygon
---@nodiscard
function LandscapingAreaPolygon.new(uniqueId)
    local self = LandscapingArea.new(uniqueId, LandscapingAreaPolygon.CLASS_NAME, LandscapingAreaPolygon_mt)
    ---@cast self LandscapingAreaPolygon

    self.targetY = math.huge
    self.points = {}

    return self
end

---@return LandscapingAreaPolygon
---@nodiscard
function LandscapingAreaPolygon:clone()
    local clone = LandscapingAreaPolygon.new()

    self:copyInto(clone)

    clone.targetY = self.targetY
    clone.points = table.clone(self.points, 2)

    return clone
end

---@return boolean
---@nodiscard
function LandscapingAreaPolygon:getIsValid()
    return self:superClass().getIsValid(self) and self.targetY ~= math.huge and #self.points > 2
end

---@param x number
---@param z number
---@return boolean
---@nodiscard
function LandscapingAreaPolygon:getIsInsideArea(x, _, z)
    return LandscapingUtils.getIsPointInsidePolygon(x, z, self.points)
end

---@return boolean
---@nodiscard
function LandscapingAreaPolygon:getCanAddPoint()
    return #self.points <= LandscapingAreaPolygon.MAX_NUM_POINTS
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
function LandscapingAreaPolygon:getDeformationParams(x, y, z)
    if self:getIsValid() then
        if not self.restrictArea or LandscapingUtils.getIsPointInsidePolygon(x, z, self.points) then
            return true, self.targetY, 0, 0, 0, 0, 0, 0
        end
    end

    ---@diagnostic disable-next-line: missing-return-value
    return false
end

---@return number worldPosX
---@return number worldPosZ
function LandscapingAreaPolygon:getCameraFocusWorldPositionXZ()
    local points = self.points
    local numPoints = #points

    if numPoints < 3 then
        return math.huge, 0
    end

    local area, cx, cy = 0, 0, 0

    for i = 1, numPoints do
        local x1, y1 = points[i][1], points[i][2]
        local x2, y2 = points[(i % numPoints) + 1][1], points[(i % numPoints) + 1][2]
        local cross = x1 * y2 - x2 * y1
        area += cross
        cx += (x1 + x2) * cross
        cy += (y1 + y2) * cross
    end

    area *= 0.5
    if area == 0 then
        local ax, ay = 0, 0
        for i = 1, numPoints do
            ax += points[i][1]
            ay += points[i][2]
        end
        return ax / numPoints, ay / numPoints
    end

    local f = 1 / (6 * area)
    return cx * f, cy * f
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
---@nodiscard
function LandscapingAreaPolygon:loadFromXMLFile(xmlFile, key)
    if self:superClass().loadFromXMLFile(self, xmlFile, key) then
        self.targetY = xmlFile:getValue(key .. '#targetY', self.targetY)

        self.points = {}

        for _, itemKey in xmlFile:iterator(key .. '.points.point') do
            local x, _, z = xmlFile:getValue(itemKey .. '#position')

            table.insert(self.points, { x, z })
        end

        return true
    end

    return false
end

---@param xmlFile XMLFile
---@param key string
function LandscapingAreaPolygon:saveToXMLFile(xmlFile, key)
    self:superClass().saveToXMLFile(self, xmlFile, key)

    if self.targetY ~= math.huge then
        xmlFile:setValue(key .. '#targetY', self.targetY)
    end

    for i, point in ipairs(self.points) do
        local itemKey = string.format('%s.points.point(%i)', key, i - 1)
        xmlFile:setValue(itemKey .. '#position', point[1], 0, point[2])
    end
end

---@param streamId number
---@param connection Connection
function LandscapingAreaPolygon:writeStream(streamId, connection)
    self:superClass().writeStream(self, streamId, connection)

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
function LandscapingAreaPolygon:readStream(streamId, connection)
    self:superClass().readStream(self, streamId, connection)

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
function LandscapingAreaPolygon:updateAreaBorder(shapeNode, rootNode, childNodes)
    local numPoints = #self.points

    for i = 1, numPoints do
        local point = self.points[i]
        local nextPoint = self.points[i + 1]

        if nextPoint ~= nil then
            LandscapingUtils.setAreaSegmentTransform(
                shapeNode, rootNode, childNodes, i,
                point[1], self.targetY, point[2],
                nextPoint[1], self.targetY, nextPoint[2]
            )
        end
    end

    if numPoints > 2 then
        local lastPoint = self.points[numPoints]
        local firstPoint = self.points[1]

        LandscapingUtils.setAreaSegmentTransform(
            shapeNode, rootNode, childNodes, numPoints,
            lastPoint[1], self.targetY, lastPoint[2],
            firstPoint[1], self.targetY, firstPoint[2]
        )
        for index, node in ipairs(childNodes) do
            setVisibility(node, index <= numPoints)
        end
    else
        for index, node in ipairs(childNodes) do
            setVisibility(node, index < numPoints)
        end
    end
end
