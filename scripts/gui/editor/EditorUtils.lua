---@class EditorUtils
EditorUtils = {}

---@param startPos number[]
---@param endPos number[]
---@param offsetY? number
---@param color? number[]
---@param solid? boolean
function EditorUtils.drawLinePos(startPos, endPos, offsetY, color, solid)
    color = color or { 1, 1, 1 }
    offsetY = offsetY or 0

    EditorUtils.drawLine(startPos[1], startPos[2] + offsetY, startPos[3], endPos[1], endPos[2] + offsetY, endPos[3], color, solid)
end

---@param startPos number[]
---@param endPos number[]
---@param offsetY? number
---@param sizeX? number width of the arrow, default = 0.3
---@param sizeZ? number length of the arrow, default = 0.2
---@param color? number[]
---@param solid? boolean
function EditorUtils.drawLineWithArrowPos(startPos, endPos, offsetY, sizeX, sizeZ, color, solid)
    EditorUtils.drawLinePos(startPos, endPos, offsetY, color, solid)
    EditorUtils.drawArrowPosDirection(startPos, endPos, offsetY, sizeX, sizeZ, color, solid)
end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param color? number[]
---@param solid? boolean
function EditorUtils.drawLine(x1, y1, z1, x2, y2, z2, color, solid)
    color = color or { 1, 1, 1 }

    local r, g, b = unpack(color)

    drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b, solid)
end

---@param startPos number[]
---@param endPos number[]
---@param offsetY? number
---@param sizeX? number width of the arrow, default = 0.3
---@param sizeZ? number length of the arrow, default = 0.2
---@param color? number[]
---@param solid? boolean
function EditorUtils.drawArrowPosDirection(startPos, endPos, offsetY, sizeX, sizeZ, color, solid)
    local dirX, dirY, dirZ = EditorUtils.getDirection(startPos, endPos)
    local x, y, z = EditorUtils.getCenterOf(startPos, endPos)

    EditorUtils.drawArrow(x, y, z, dirX, dirY, dirZ, sizeX, sizeZ, color, solid)
end

---@param startPos number[]
---@param endPos number[]
---@param text string
---@param textOffsetY? number
---@param textColor? number[]
---@param textSize? number default = 0.016
---@param bold? boolean default = false
function EditorUtils.drawLineCenterPosText(startPos, endPos, text, textOffsetY, textColor, textSize, bold)
    textOffsetY = textOffsetY or 0
    textColor = textColor or { 1, 1, 1, 1 }
    textSize = textSize or 0.016

    local x, y, z = EditorUtils.getCenterOf(startPos, endPos)

    ModUtils.renderTextAtWorldPosition(x, y + textOffsetY, z, text, textSize, nil, textColor, bold)
end

---@param startPos number[]
---@param endPos number[]
---@param textOffsetY? number
---@param textColor? number[]
---@param textSize? number default = 0.016
---@param bold? boolean default = false
function EditorUtils.drawLineCenterPosAngleText(startPos, endPos, textOffsetY, textColor, textSize, bold)
    local text = string.format('%.2f°', EditorUtils.calculateTargetAngle(startPos, endPos))
    EditorUtils.drawLineCenterPosText(startPos, endPos, text, textOffsetY, textColor, textSize, bold)
end

---@param x number
---@param y number
---@param z number
---@param dirX number
---@param dirY number
---@param dirZ number
---@param sizeX? number width of the arrow, default = 0.2
---@param sizeZ? number length of the arrow, default = 0.15
---@param color? number[]
---@param solid? boolean
function EditorUtils.drawArrow(x, y, z, dirX, dirY, dirZ, sizeX, sizeZ, color, solid)
    sizeX = sizeX or 0.2
    sizeZ = sizeZ or 0.15

    local px, pz = -dirZ, dirX
    local pm = math.sqrt(px * px + pz * pz)

    if pm > 0.05 then
        px, pz = px / pm, pz / pm

        local tipX = x + dirX * sizeZ
        local tipY = y + dirY * sizeZ
        local tipZ = z + dirZ * sizeZ

        EditorUtils.drawLine(tipX, tipY, tipZ, x - dirX * sizeZ + px * sizeX, y - dirY * sizeZ, z - dirZ * sizeZ + pz * sizeX, color, solid)
        EditorUtils.drawLine(tipX, tipY, tipZ, x - dirX * sizeZ - px * sizeX, y - dirY * sizeZ, z - dirZ * sizeZ - pz * sizeX, color, solid)
    end
end

---@param pos number[]
---@param offsetY? number
---@param radius? number circle radius, default = 0.2
---@param steps? number circle steps, default = 8
---@param lineOffsetY? number set to render vertical line from pos[y] to pos[y] + lineOffsetY
---@param color? number[]
---@param solid? boolean
function EditorUtils.drawPointPos(pos, offsetY, radius, steps, lineOffsetY, color, solid)
    offsetY = offsetY or 0

    local x, y, z = unpack(pos)

    EditorUtils.drawPoint(x, y + offsetY, z, radius, steps, lineOffsetY, color, solid)
end

---@param pos number[]
---@param offsetY? number
---@param radius? number circle radius, default = 0.2
---@param steps? number circle steps, default = 8
---@param lineOffsetY? number set to render vertical line from pos[y] to pos[y] + lineOffsetY
---@param color? number[]
---@param solid? boolean
function EditorUtils.drawPointPosWithTerrainLine(pos, offsetY, radius, steps, lineOffsetY, color, solid)
    if radius > 0 then
        EditorUtils.drawPointPos(pos, offsetY, radius, steps, lineOffsetY, color, solid)
    end

    local x, y, z = unpack(pos)
    local h = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)

    EditorUtils.drawLine(x, y, z, x, h, z, color, solid)
end

---@param x number
---@param y number
---@param z number
---@param radius? number circle radius, default = 0.2
---@param steps? number circle steps, default = 8
---@param lineOffsetY? number set to render vertical line from pos[y] to pos[y] + lineOffsetY
---@param color? number[]
---@param solid? boolean
function EditorUtils.drawPoint(x, y, z, radius, steps, lineOffsetY, color, solid)
    radius = radius or 0.2
    steps = steps or 16
    color = color or { 1, 1, 1 }

    DebugUtil.drawDebugCircle(x, y, z, radius, steps, color, nil, nil, solid)

    if lineOffsetY ~= nil then
        EditorUtils.drawLine(x, y, z, x, y + lineOffsetY, z, color, solid)
    end
end

---@param element TextInputElement
---@param minLength? number
---@param default? string
---@return string
---@nodiscard
function EditorUtils.getTextInput(element, minLength, default)
    minLength = minLength or 2
    default = default or ''

    local text = element:getText()

    if text ~= nil then
        text = text:trim()

        if text:len() >= minLength then
            return text
        end
    end

    return default
end

---@param element TextInputElement
---@param precision? number default precision = 2
---@param default? number
---@param min? number
---@param max? number
---@return number?
---@nodiscard
function EditorUtils.getTextInputNumber(element, precision, default, min, max)
    precision = precision or 2

    local text = element:getText()
    local value = tonumber(text)

    value = MathUtil.round(value, precision) or default

    if value ~= nil then
        if min ~= nil then
            value = math.max(min, value)
        end
        if max ~= nil then
            value = math.min(max, value)
        end
    end

    return value
end

---@param element TextInputElement
---@param value number
---@param precision? number
function EditorUtils.setTextInputNumber(element, value, precision)
    precision = precision or 2

    local text = string.format('%.' .. precision .. 'f', value)

    element:setText(text)
end

-- Get axes direction values from [startPos -> endPos]
---@param startPos number[]
---@param endPos number[]
---@return number
---@return number
---@return number
---@nodiscard
function EditorUtils.getDirection(startPos, endPos)
    local dx = endPos[1] - startPos[1]
    local dy = endPos[2] - startPos[2]
    local dz = endPos[3] - startPos[3]

    local length = math.sqrt(dx * dx + dy * dy + dz * dz)

    if length == 0 then
        return 0, 0, 0
    end

    return dx / length, dy / length, dz / length
end

-- Get center of line between [startPos -> endPos]
---@param startPos number[]
---@param endPos number[]
---@return number
---@return number
---@return number
---@nodiscard
function EditorUtils.getCenterOf(startPos, endPos)
    local cx = (startPos[1] + endPos[1]) * 0.5
    local cy = (startPos[2] + endPos[2]) * 0.5
    local cz = (startPos[3] + endPos[3]) * 0.5

    return cx, cy, cz
end

---@param x1 number
---@param z1 number
---@param x2 number
---@param z2 number
---@return number worldYaw Engine yaw
---@nodiscard
function EditorUtils.getWorldYaw(x1, z1, x2, z2)
    local dx = x2 - x1
    local dz = z2 - z1

    local worldYaw = math.atan2(dx, dz)

    return worldYaw
end

---@param startPos number[]
---@param endPos number[]
---@return number worldYaw Engine yaw
---@nodiscard
function EditorUtils.getWorldYawPos(startPos, endPos)
    return EditorUtils.getWorldYaw(startPos[1], startPos[3], endPos[1], endPos[3])
end

---@param startPos number[]
---@param endPos number[]
---@return number worldYrot Engine y rotation angle
---@nodiscard
function EditorUtils.getWorldRotYAngle(startPos, endPos)
    local worldYrot = EditorUtils.getWorldYawPos(startPos, endPos)

    worldYrot = math.deg(worldYrot) % 360

    return worldYrot
end

---@param startPos number[]
---@param endPos number[]
---@return number angle World rotation Y angle
---@nodiscard
---@deprecated
function EditorUtils.getWorldRotationYAngle(startPos, endPos)
    local dx = endPos[1] - startPos[1]
    local dz = endPos[3] - startPos[3]

    local angle = math.deg(math.atan2(dx, dz)) % 360

    return angle
end

---@param startPos number[]
---@param endPos number[]
---@return number x
---@return number z
---@nodiscard
function EditorUtils.calculateXZUsingRotationYAngle(startPos, endPos, angle)
    local dx = endPos[1] - startPos[1]
    local dz = endPos[3] - startPos[3]
    local yaw = math.atan2(dx, dz)

    local delta = yaw - math.rad(angle)
    local cosA = math.cos(delta)
    local sinA = math.sin(delta)

    local rx = dx * cosA - dz * sinA
    local rz = dx * sinA + dz * cosA

    return startPos[1] + rx, startPos[3] + rz
end

-- Calculate pitch angle between [startPos -> endPos]
---@param startPos number[]
---@param endPos number[]
---@return number angle Target angle from segment positions
---@nodiscard
function EditorUtils.calculateTargetAngle(startPos, endPos)
    local dx = endPos[1] - startPos[1]
    local dy = endPos[2] - startPos[2]
    local dz = endPos[3] - startPos[3]

    local distance = math.sqrt(dx * dx + dz * dz)
    local angle = math.atan2(dy, distance)

    return math.deg(angle)
end

---@param startPos number[]
---@param endPos number[]
---@param numDirections? number Default = 2 (x and z directions only)
---@return number x
---@return number z
---@nodiscard
function EditorUtils.calculateTargetPosXZAligned(startPos, endPos, numDirections)
    numDirections = numDirections or 2

    local dx = endPos[1] - startPos[1]
    local dz = endPos[3] - startPos[3]

    local ang = math.atan2(dz, dx)
    local snap = math.pi / numDirections
    local a = math.floor((ang + snap * 0.5) / snap) * snap

    local len = math.sqrt(dx * dx + dz * dz)
    local rx = math.cos(a) * len
    local rz = math.sin(a) * len

    return startPos[1] + rx, startPos[3] + rz
end

-- Calculate target XZ position using directional vector [startPos -> endPos]
---@param targetPos number[]
---@param startPos number[]
---@param endPos number[]
---@return number x
---@return number z
---@nodiscard
function EditorUtils.calculateTargetPosXZ(targetPos, startPos, endPos)
    local dx = endPos[1] - startPos[1]
    local dz = endPos[3] - startPos[3]
    local tx = targetPos[1] - startPos[1]
    local tz = targetPos[3] - startPos[3]
    local distSq = dx * dx + dz * dz

    if distSq == 0 then
        return startPos[1], startPos[3]
    end

    local t = (tx * dx + tz * dz) / distSq
    local projX = startPos[1] + dx * t
    local projZ = startPos[3] + dz * t

    return projX, projZ
end

-- Calculate target height using [startPos -> endPos] as directional vector
-- and a specified target angle.
---@param startPos number[]
---@param endPos number[]
---@param targetAngle number
---@return number
---@nodiscard
function EditorUtils.calculateTargetHeightUsingAngle(startPos, endPos, targetAngle)
    local dx = endPos[1] - startPos[1]
    local dz = endPos[3] - startPos[3]
    local horizDist = math.sqrt(dx * dx + dz * dz)
    local angleRad = math.rad(targetAngle)
    local heightOffset = math.tan(angleRad) * horizDist

    return startPos[2] + heightOffset
end
