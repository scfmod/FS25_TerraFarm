---@class LandscapingAreaPath : LandscapingArea
---@field superClass fun(): LandscapingArea
---@field width number
---@field points number[][]
LandscapingAreaPath = {}
LandscapingAreaPath.CLASS_NAME = 'LandscapingAreaPath'
LandscapingAreaPath.TYPE_NAME = g_i18n:getText('ui_areaPath')
LandscapingAreaPath.SEND_NUM_BITS_POINTS = 6
LandscapingAreaPath.MAX_NUM_POINTS = 2 ^ LandscapingAreaPath.SEND_NUM_BITS_POINTS - 1

local LandscapingAreaPath_mt = Class(LandscapingAreaPath, LandscapingArea)

---@param schema XMLSchema
---@param key string
function LandscapingAreaPath.registerXMLPaths(schema, key)
    schema:register(XMLValueType.VECTOR_3, key .. '.points.point(?)#position')
    schema:register(XMLValueType.FLOAT, key .. '#width')
end

---@param uniqueId? string
---@return LandscapingAreaPath
---@nodiscard
function LandscapingAreaPath.new(uniqueId)
    local self = LandscapingArea.new(uniqueId, LandscapingAreaPath.CLASS_NAME, LandscapingAreaPath_mt)
    ---@cast self LandscapingAreaPath

    self.points = {}
    self.width = 4

    return self
end

---@return LandscapingAreaPath
---@nodiscard
function LandscapingAreaPath:clone()
    local clone = LandscapingAreaPath.new()

    self:copyInto(clone)

    clone.width = self.width
    clone.points = table.clone(self.points, 2)

    return clone
end

---@return boolean
---@nodiscard
function LandscapingAreaPath:getIsValid()
    return self:superClass().getIsValid(self) and #self.points > 1 and self.width > 0
end

---@return boolean
---@nodiscard
function LandscapingAreaPath:getCanAddPoint()
    return #self.points <= LandscapingAreaPath.MAX_NUM_POINTS
end

---@param x number
---@param y number
---@param z number
---@return boolean
---@nodiscard
function LandscapingAreaPath:getIsInsideArea(x, y, z)
    local valid = self:getClosestSegment(x, y, z, true)
    return valid
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
function LandscapingAreaPath:getDeformationParams(x, y, z)
    local valid, nx, ny, nz, direction, _, targetY, _, index = self:getClosestSegmentParams(x, y, z, self.restrictArea)

    if valid then
        local numPoints = #self.points
        local point = self.points[index]
        local nextPoint = self.points[index + 1]
        local minY = math.min(point[2], nextPoint[2])
        local maxY = math.max(point[2], nextPoint[2])

        if numPoints > 2 then
            if index == 1 then
                if point[2] < nextPoint[2] then
                    minY = point[2]
                    maxY = math.huge
                else
                    minY = -math.huge
                    maxY = point[2]
                end
            elseif index == numPoints - 1 then
                if nextPoint[2] < point[2] then
                    minY = nextPoint[2]
                    maxY = math.huge
                else
                    minY = -math.huge
                    maxY = nextPoint[2]
                end
            else
                minY = -math.huge
                maxY = math.huge
            end
        end

        return true, targetY, minY, maxY, nx, ny, nz, direction
    end

    ---@diagnostic disable-next-line: missing-return-value
    return false
end

---@return number worldPosX
---@return number worldPosZ
function LandscapingAreaPath:getCameraFocusWorldPositionXZ()
    local points = self.points
    local numPoints = #points

    if numPoints < 3 then
        local firstPoint = points[1]

        if firstPoint ~= nil then
            return firstPoint[1], firstPoint[3]
        end

        return math.huge, 0
    end

    local total = 0
    for i = 1, numPoints - 1 do
        local a, b = points[i], points[i + 1]
        local dx = b[1] - a[1]
        local dz = b[3] - a[3]
        total += (dx * dx + dz * dz) ^ 0.5
    end

    local half = total * 0.5
    local dist = 0

    for i = 1, numPoints - 1 do
        local a, b = points[i], points[i + 1]
        local dx = b[1] - a[1]
        local dz = b[3] - a[3]
        local seg = (dx * dx + dz * dz) ^ 0.5

        if dist + seg >= half then
            local t = (half - dist) / seg
            return a[1] + dx * t, a[3] + dz * t
        end

        dist += seg
    end

    return points[numPoints][1], points[numPoints][3]
end

---@private
---@param x number
---@param y number
---@param z number
---@param restrictArea boolean
---@return boolean valid
---@return number nx
---@return number ny
---@return number nz
---@return number direction
---@return number px
---@return number py
---@return number pz
---@return number index
function LandscapingAreaPath:getClosestSegmentParams(x, y, z, restrictArea)
    local valid, index, px, py, pz = self:getClosestSegment(x, y, z, restrictArea)

    if valid then
        local point = self.points[index]
        local nextPoint = self.points[index + 1]

        if nextPoint then -- Probably don't need the check here but..
            local nx, ny, nz, direction = LandscapingUtils.getSlopeParams(point[1], point[2], point[3], nextPoint[1], nextPoint[2], nextPoint[3])

            return true, nx, ny, nz, direction, px, py, pz, index
        end
    end

    return false, 0, 0, 0, 0, 0, 0, 0, 0
end

---@private
---@param x number
---@param y number
---@param z number
---@param restrictArea boolean
---@return boolean isvalid
---@return number index Segment index
---@return number x
---@return number y
---@return number z
---@return number segmentDistance Position [0, 1] on the line segment
function LandscapingAreaPath:getClosestSegment(x, y, z, restrictArea)
    local halfWidth = self.width / 2
    local sx, sy, sz = 0, 0, 0
    local distance = math.huge
    local index
    local segmentDistance

    for i, pos in ipairs(self.points) do
        local nextPoint = self.points[i + 1]

        if nextPoint ~= nil then
            local px, py, pz, pdistance = LandscapingUtils.getClosestPointOnLineSegmentXZ(pos[1], pos[2], pos[3], nextPoint[1], nextPoint[2], nextPoint[3], x, y, z)

            if restrictArea then
                local length2 = MathUtil.vector2Length(x - px, z - pz)

                if length2 > halfWidth then
                    continue
                end
            end

            local length = MathUtil.vector3Length(x - px, y - py, z - pz)

            if length < distance then
                sx, sy, sz = px, py, pz
                index = i
                distance = length
                segmentDistance = pdistance
            end
        end
    end

    if index ~= nil then
        return true, index, sx, sy, sz, segmentDistance
    end

    return false, 0, 0, 0, 0, 0
end

---@private
---@return number[] pLines1
---@return number[] pLines2
function LandscapingAreaPath:buildParallelLines()
    local points = self.points
    local numPoints = #points

    if numPoints < 2 then
        return {}, {}
    end

    local half = self.width * 0.5
    local EPS = 1e-8
    local miterLimit = 2

    local sqrt = math.sqrt
    local abs = math.abs

    local segNx = table.create(numPoints - 1, 0)
    local segNz = table.create(numPoints - 1, 0)

    for i = 1, numPoints - 1 do
        local p1 = points[i]
        local p2 = points[i + 1]

        local dx = p2[1] - p1[1]
        local dz = p2[3] - p1[3]

        local L = dx * dx + dz * dz
        if L > EPS then
            L = sqrt(L)
            dx /= L
            dz /= L
        else
            dx, dz = 0, 0
        end

        segNx[i] = -dz
        segNz[i] = dx
    end

    local offX = table.create(numPoints, 0)
    local offZ = table.create(numPoints, 0)

    for i = 1, numPoints do
        local hasPrev = (i > 1)
        local hasNext = (i < numPoints)

        if not hasPrev and not hasNext then
            offX[i] = 0
            offZ[i] = 0
        elseif not hasPrev then
            offX[i] = segNx[i] * half
            offZ[i] = segNz[i] * half
        elseif not hasNext then
            offX[i] = segNx[i - 1] * half
            offZ[i] = segNz[i - 1] * half
        else
            local n1x = segNx[i - 1]
            local n1z = segNz[i - 1]
            local n2x = segNx[i]
            local n2z = segNz[i]

            local mx = n1x + n2x
            local mz = n1z + n2z

            local mlen = mx * mx + mz * mz
            if mlen < EPS then
                offX[i] = n1x * half
                offZ[i] = n1z * half
            else
                mlen = sqrt(mlen)
                mx /= mlen
                mz /= mlen

                local dot_m_n1 = mx * n1x + mz * n1z
                if abs(dot_m_n1) < EPS then
                    offX[i] = n1x * half
                    offZ[i] = n1z * half
                else
                    local scale = half / dot_m_n1
                    local ox = mx * scale
                    local oz = mz * scale

                    if sqrt(ox * ox + oz * oz) / half > miterLimit then
                        ox = n1x * half
                        oz = n1z * half
                    end

                    offX[i] = ox
                    offZ[i] = oz
                end
            end
        end
    end

    local outCount = (numPoints - 1) * 2
    local pLines1 = table.create(outCount, 0)
    local pLines2 = table.create(outCount, 0)

    local idx = 1
    for i = 1, numPoints - 1 do
        local p1         = points[i]
        local p2         = points[i + 1]

        local ox1        = offX[i]
        local oz1        = offZ[i]
        local ox2        = offX[i + 1]
        local oz2        = offZ[i + 1]

        pLines1[idx]     = { p1[1] + ox1, p1[2], p1[3] + oz1 }
        pLines1[idx + 1] = { p2[1] + ox2, p2[2], p2[3] + oz2 }

        pLines2[idx]     = { p1[1] - ox1, p1[2], p1[3] - oz1 }
        pLines2[idx + 1] = { p2[1] - ox2, p2[2], p2[3] - oz2 }

        idx              += 2
    end

    return pLines1, pLines2
end

---@param shapeNode number
---@param rootNode number
---@param childNodes number[]
function LandscapingAreaPath:updateAreaBorder(shapeNode, rootNode, childNodes)
    local pLines1, pLines2 = self:buildParallelLines()
    local index = 1

    for i = 1, #pLines1 - 1 do
        local p1, p2 = pLines1[i], pLines1[i + 1]

        LandscapingUtils.setAreaSegmentTransform(
            shapeNode, rootNode, childNodes, index,
            p1[1], p1[2], p1[3],
            p2[1], p2[2], p2[3]
        )

        index = index + 1
    end

    for i = 1, #pLines2 - 1 do
        local p1, p2 = pLines2[i], pLines2[i + 1]

        LandscapingUtils.setAreaSegmentTransform(
            shapeNode, rootNode, childNodes, index,
            p1[1], p1[2], p1[3],
            p2[1], p2[2], p2[3]
        )

        index = index + 1
    end

    for i, node in ipairs(childNodes) do
        setVisibility(node, i < index)
    end
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
---@nodiscard
function LandscapingAreaPath:loadFromXMLFile(xmlFile, key)
    if self:superClass().loadFromXMLFile(self, xmlFile, key) then
        self.width = xmlFile:getValue(key .. '#width', self.width)

        self.points = {}

        for _, itemKey in xmlFile:iterator(key .. '.points.point') do
            local x, y, z = xmlFile:getValue(itemKey .. '#position')

            table.insert(self.points, { x, y, z })
        end

        return true
    end

    return false
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
---@nodiscard
function LandscapingAreaPath:saveToXMLFile(xmlFile, key)
    self:superClass().saveToXMLFile(self, xmlFile, key)

    xmlFile:setValue(key .. '#width', self.width)

    for i, point in ipairs(self.points) do
        local itemKey = string.format('%s.points.point(%i)', key, i - 1)
        xmlFile:setValue(itemKey .. '#position', point[1], point[2], point[3])
    end

    return true
end

---@param streamId number
---@param connection Connection
function LandscapingAreaPath:writeStream(streamId, connection)
    self:superClass().writeStream(self, streamId, connection)

    streamWriteFloat32(streamId, self.width)
    streamWriteUIntN(streamId, #self.points, LandscapingAreaPolygon.SEND_NUM_BITS_POINTS)

    for _, point in ipairs(self.points) do
        ModUtils.writeCompressedXYZPos(streamId, point[1], point[2], point[3])
    end
end

---@param streamId number
---@param connection Connection
function LandscapingAreaPath:readStream(streamId, connection)
    self:superClass().readStream(self, streamId, connection)

    self.width = streamReadFloat32(streamId)

    local numPoints = streamReadUIntN(streamId, LandscapingAreaPolygon.SEND_NUM_BITS_POINTS)

    self.points = {}

    for _ = 1, numPoints do
        local x, y, z = ModUtils.readCompressedXYZPos(streamId)
        table.insert(self.points, { x, y, z })
    end
end
