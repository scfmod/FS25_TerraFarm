---@class ModUtils
ModUtils = {}

---@param objectName string
---@param filename string
---@param schema? XMLSchema
---@return XMLFile?
---@nodiscard
function ModUtils.loadSavegameDirectoryXMLFile(objectName, filename, schema)
    local absFilename = ModUtils.getSavegameDirectoryFilename(filename)

    if absFilename ~= nil then
        return XMLFile.loadIfExists(objectName, absFilename, schema)
    end
end

---@param objectName string
---@param filename string
---@param schema? XMLSchema
---@return XMLFile?
---@nodiscard
function ModUtils.loadMapDirectoryXMLFile(objectName, filename, schema)
    local absFilename = ModUtils.getMapDirectoryFilename(filename)

    if absFilename ~= nil then
        return XMLFile.loadIfExists(objectName, absFilename, schema)
    end
end

---@param objectName string
---@param filename string
---@param rootNodeName string
---@param schema? XMLSchema
---@return XMLFile?
---@nodiscard
function ModUtils.createSavegameDirectoryXMLFile(objectName, filename, rootNodeName, schema)
    local absFilename = ModUtils.getSavegameDirectoryFilename(filename)

    if absFilename ~= nil then
        return XMLFile.create(objectName, absFilename, rootNodeName, schema)
    end
end

---@return string?
---@nodiscard
function ModUtils.getSavegameDirectoryFilename(filename)
    local savegameDirectory = ModUtils.getSavegameDirectory()

    if savegameDirectory ~= nil then
        return savegameDirectory .. '/' .. filename
    end
end

---@param filename string
---@return string?
---@nodiscard
function ModUtils.getMapDirectoryFilename(filename)
    if g_currentMission and g_currentMission.missionInfo then
        local mapXMLDirectory = Utils.getDirectory(g_currentMission.missionInfo.mapXMLFilename)
        return g_currentMission.baseDirectory .. mapXMLDirectory .. filename
    end
end

---@return string?
---@nodiscard
function ModUtils.getSavegameDirectory()
    if g_currentMission ~= nil and g_currentMission.missionInfo ~= nil then
        return g_currentMission.missionInfo.savegameDirectory
    end
end

local MAP_CHARS = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "r", "s", "t", "u", "v", "z", "y", "w", "q", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }

---@param length? number
---@return string
---@nodiscard
function ModUtils.createUniqueId(length)
    local str = ''

    for _ = 1, length or 12 do
        str = str .. MAP_CHARS[math.random(1, 35)]
    end

    return str
end

---@param permission string
---@param connection? Connection
---@param farmId? number
---@return boolean
---@nodiscard
function ModUtils.getPlayerHasPermission(permission, connection, farmId)
    if g_currentMission ~= nil then
        return g_currentMission:getHasPlayerPermission(permission, connection, farmId)
    end

    return false
end

---@param x number
---@param y number
---@param z number
---@param text string
---@param textSize number
---@param textOffset number?
---@param color number[]?
---@param bold boolean?
function ModUtils.renderTextAtWorldPosition(x, y, z, text, textSize, textOffset, color, bold)
    local sx, sy, sz = project(x, y, z)

    if bold == nil then
        bold = false
    end

    local r, g, b, a = 0.5, 1, 0.5, 1
    textOffset = textOffset or 0

    if color then
        r, g, b, a = color[1], color[2], color[3], color[4] or 1
    end

    if sx > -1 and sx < 2 and sy > -1 and sy < 2 and sz <= 1 then
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextBold(bold)
        setTextColor(0, 0, 0, 0.75)
        renderText(sx, sy - 0.0015 + textOffset, textSize, text)
        setTextColor(r, g, b, a)
        renderText(sx, sy + textOffset, textSize, text)
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextColor(1, 1, 1, 1)
    end
end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return number
---@nodiscard
function ModUtils.getPointsDistance(x1, y1, z1, x2, y2, z2)
    local dx, dy, dz = x1 - x2, y1 - y2, z1 - z2

    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

---@return boolean
---@nodiscard
function ModUtils.getIsAdministrator()
    if g_server ~= nil then
        return true
    elseif g_currentMission ~= nil and g_currentMission.missionDynamicInfo ~= nil then
        return not g_currentMission.missionDynamicInfo.isMultiplayer or g_currentMission.isMasterUser
    end

    return false
end

---@param streamId number
---@param worldPosX number
---@param worldPosY number
---@param worldPosZ number
function ModUtils.writeCompressedXYZPos(streamId, worldPosX, worldPosY, worldPosZ)
    local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
    local paramsY = g_currentMission.vehicleYPosCompressionParams

    NetworkUtil.writeCompressedWorldPosition(streamId, worldPosX, paramsXZ)
    NetworkUtil.writeCompressedWorldPosition(streamId, worldPosY, paramsY)
    NetworkUtil.writeCompressedWorldPosition(streamId, worldPosZ, paramsXZ)
end

---@param streamId number
---@return number worldPosX
---@return number worldPosY
---@return number worldPosZ
function ModUtils.readCompressedXYZPos(streamId)
    local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
    local paramsY = g_currentMission.vehicleYPosCompressionParams

    local x = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
    local y = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
    local z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)

    return x, y, z
end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param color number[]
---@param solid? boolean Set to false to render through terrain, objects etc.
function ModUtils.drawDebugLine(x1, y1, z1, x2, y2, z2, color, solid)
    drawDebugLine(x1, y1, z1, color[1], color[2], color[3], x2, y2, z2, color[1], color[2], color[3], solid)
end
