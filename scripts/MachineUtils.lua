---@class MachineUtils
MachineUtils = {}

---@param vehicle Machine
---@return boolean
---@nodiscard
function MachineUtils.getIsShovel(vehicle)
    local spec = vehicle.spec_machine

    if spec ~= nil then
        return spec.machineType.id == 'shovel' or spec.machineType.id == 'excavatorShovel'
    end

    return false
end

---@param targetVehicle Machine
---@return Machine | nil
function MachineUtils.getActiveVehicle(targetVehicle)
    if targetVehicle == nil then
        return nil
    end

    ---@type Machine | nil
    local selectedVehicle = targetVehicle:getSelectedVehicle()

    if selectedVehicle == nil then
        return nil
    end

    if selectedVehicle.spec_machine ~= nil then
        return selectedVehicle
    end

    ---@type Machine
    ---@diagnostic disable-next-line: assign-type-mismatch
    local rootVehicle = selectedVehicle:findRootVehicle()

    ---@type Machine[]
    local childVehicles = rootVehicle:getChildVehicles()

    if #childVehicles == 0 then
        if rootVehicle.spec_machine ~= nil then
            return rootVehicle
        end
    else
        for _, vehicle in ipairs(childVehicles) do
            if vehicle.spec_machine ~= nil then
                if vehicle.spec_machine.hasAttachable then
                    if vehicle:getIsActiveForInput() then
                        return vehicle
                    end
                elseif vehicle:getIsActiveForInput(true) then
                    return vehicle
                end
            end
        end
    end

    return nil
end

---@param targetVehicle Machine
---@return Machine[]
---@nodiscard
function MachineUtils.getAvailableVehicles(targetVehicle)
    ---@type Machine[]
    local result = {}

    ---@type Machine
    ---@diagnostic disable-next-line: assign-type-mismatch
    local rootVehicle = targetVehicle:findRootVehicle()

    if rootVehicle.spec_machine ~= nil then
        table.insert(result, targetVehicle)
    end

    ---@type Machine[]
    local childVehicles = rootVehicle:getChildVehicles()

    for _, vehicle in ipairs(childVehicles) do
        if vehicle.spec_machine ~= nil then
            table.insert(result, vehicle)
        end
    end


    return result
end

---@param vehicle Machine
---@return number
---@nodiscard
function MachineUtils.getVehicleTargetHeight(vehicle)
    local spec = vehicle.spec_machine

    if spec.hasAttachable then
        ---@diagnostic disable-next-line: cast-local-type
        vehicle = vehicle:findRootVehicle()
    end

    local x, _, z = getWorldTranslation(vehicle.rootNode)

    return getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
end

---@return number worldPosX
---@return number worldPosY
---@return number worldPosZ
---@return number terrainHeight
function MachineUtils.getVehicleTargetWorldTerrainPosition(vehicle)
    local spec = vehicle.spec_machine

    if spec.hasAttachable then
        ---@diagnostic disable-next-line: cast-local-type
        vehicle = vehicle:findRootVehicle()
    end

    local x, y, z = getWorldTranslation(vehicle.rootNode)
    local terrainHeight = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)

    return x, y, z, terrainHeight
end

---@param vehicle Vehicle
---@return string | nil xmlFilename
---@return string modFilename
---@nodiscard
function MachineUtils.getVehicleConfiguration(vehicle)
    local modFilename = MachineUtils.getVehicleModFilename(vehicle)

    return g_machineManager:getConfigurationXMLFilename(modFilename), modFilename
end

---@param vehicle Vehicle
---@return string
---@nodiscard
function MachineUtils.getVehicleModFilename(vehicle)
    ---@type string
    local xmlFilename = vehicle.configFileName
    local modName, baseDirectory = Utils.getModNameAndBaseDirectory(xmlFilename)

    if baseDirectory == '' then
        return xmlFilename
    elseif modName ~= nil and modName:startsWith('pdlc') then
        return modName .. xmlFilename:sub(baseDirectory:len())
    else
        return xmlFilename:sub(g_modsDirectory:len() + 1)
    end
end

---@param storeItem StoreItem
function MachineUtils.getStoreItemModFilename(storeItem)
    if storeItem ~= nil and storeItem.xmlFilename ~= nil then
        local modName, baseDirectory = Utils.getModNameAndBaseDirectory(storeItem.xmlFilename)

        if baseDirectory == '' then
            return storeItem.xmlFilename
        elseif modName ~= nil and modName:startsWith('pdlc') then
            return modName .. storeItem.xmlFilename:sub(baseDirectory:len())
        else
            return storeItem.xmlFilename:sub(g_modsDirectory:len() + 1)
        end
    end
end

---@param vehicle Vehicle
---@param defaultText string | nil
---@return string
---@nodiscard
function MachineUtils.getVehicleFarmName(vehicle, defaultText)
    if vehicle ~= nil then
        local farm = g_farmManager:getFarmById(vehicle:getOwnerFarmId())

        if farm ~= nil then
            return farm.name
        end
    end

    return defaultText or 'Unknown'
end

---@return TerrainDeformation
---@nodiscard
function MachineUtils.createTerrainDeformation()
    return TerrainDeformation.new(g_terrainNode)
end

local SQRT_2_DIV_FACTOR = 1 / math.sqrt(2)

---@param tbl table
---@param x number
---@param z number
---@param radius number
function MachineUtils.addModifiedCircleArea(tbl, x, z, radius)
    local terrainUnit = getTerrainHeightmapUnitSize(g_terrainNode)
    local halfTerrainUnit = terrainUnit / 2

    if radius < terrainUnit + halfTerrainUnit then
        local size = radius * 2 * SQRT_2_DIV_FACTOR

        MachineUtils.addModifiedSquareArea(tbl, x, z, size)
    else
        for ox = -radius / terrainUnit, radius / terrainUnit - 1 do
            local xStart = ox * terrainUnit
            local xEnd = ox * terrainUnit + terrainUnit
            local zOffset1 = math.sin(math.acos(math.abs(xStart) / radius)) * radius
            local zOffset2 = math.sin(math.acos(math.abs(xEnd) / radius)) * radius
            local zOffset = math.min(zOffset1, zOffset2) - 0.02

            table.insert(tbl, {
                x + xStart,
                z - zOffset,
                x + xEnd,
                z - zOffset,
                x + xStart,
                z + zOffset
            })
        end
    end
end

---@param tbl table
---@param x number
---@param z number
---@param size number
function MachineUtils.addModifiedSquareArea(tbl, x, z, size)
    local halfSize = size * 0.5

    table.insert(tbl, {
        x - halfSize,
        z - halfSize,
        x + halfSize,
        z - halfSize,
        x - halfSize,
        z + halfSize
    })
end

---@param layerName string
---@return string
function MachineUtils.getGroundLayerTitle(layerName)
    for _, groundType in pairs(g_groundTypeManager.groundTypeMappings) do
        if groundType.layerName == layerName then
            return g_i18n:convertText(groundType.title) or layerName
        end
    end

    return layerName
end

---@param xmlFile XMLFile
---@param key string
---@return MachineMode[]
function MachineUtils.loadMachineModesFromXML(xmlFile, key)
    local modes = {}
    local str = xmlFile:getValue(key)

    if str ~= nil then
        local arr = str:split(' ')

        for _, strMode in ipairs(arr) do
            if Machine.MODE[strMode] ~= nil then
                table.insert(modes, Machine.MODE[strMode])
            else
                Logging.xmlWarning('Invalid mode "%s" (%s)', strMode, key)
            end
        end
    else
        -- Logging.xmlError(xmlFile, 'No modes defined (%s)', key)
    end

    return modes
end

---@param volume number
---@param fillTypeIndex number
---@return number
---@nodiscard
function MachineUtils.volumeToFillTypeLiters(volume, fillTypeIndex)
    return volume * 1000 * g_modSettings.conversionModifier
end

---@param liters number
---@param fillTypeIndex number
---@return number
---@nodiscard
function MachineUtils.fillTypeLitersToVolume(liters, fillTypeIndex)
    return liters / 1000 / g_modSettings.conversionModifier
end

---@param permission string
---@param connection Connection | nil
---@param farmId number | nil
---@return boolean
---@nodiscard
function MachineUtils.getPlayerHasPermission(permission, connection, farmId)
    if g_currentMission ~= nil then
        return g_currentMission:getHasPlayerPermission(permission, connection, farmId)
    end

    return false
end

---@return boolean
---@nodiscard
function MachineUtils.getCanModifySettings()
    if g_server ~= nil then
        return true
    elseif g_currentMission ~= nil and g_currentMission.missionDynamicInfo ~= nil then
        return not g_currentMission.missionDynamicInfo.isMultiplayer or g_currentMission.isMasterUser
    end

    return false
end

---@param startX number
---@param startY number
---@param startZ number
---@param endX number
---@param endY number
---@param endZ number
---@param targetX number
---@param targetY number
---@param targetZ number
---@return number z
---@return number y
---@return number z
---@return number distance
---@nodiscard
function MachineUtils.getClosestPointOnLine(startX, startY, startZ, endX, endY, endZ, targetX, targetY, targetZ)
    local dirTargetX, dirTargetY, dirTargetZ = targetX - startX, targetY - startY, targetZ - startZ
    local dirLineX, dirLineY, dirLineZ = endX - startX, endY - startY, endZ - startZ
    local lengthSq = MathUtil.vector3LengthSq(dirLineX, dirLineY, dirLineZ)
    local dot = MathUtil.dotProduct(dirTargetX, dirTargetY, dirTargetZ, dirLineX, dirLineY, dirLineZ)
    local distance = dot / lengthSq

    return startX + dirLineX * distance, startY + dirLineY * distance, startZ + dirLineZ * distance, distance
end

---@param startX number
---@param startY number
---@param startZ number
---@param endX number
---@param endY number
---@param endZ number
---@return number
---@nodiscard
function MachineUtils.getAngleBetweenPoints(startX, startY, startZ, endX, endY, endZ)
    if startY ~= math.huge and endY ~= math.huge then
        local opposite = math.abs(endY - startY)
        local adjacent = MathUtil.getPointPointDistance(startX, startZ, endX, endZ)

        if opposite ~= 0 and adjacent ~= 0 then
            if startY > endY then
                return -math.deg(math.atan(opposite / adjacent))
            else
                return math.deg(math.atan(opposite / adjacent))
            end
        end
    end

    return 0
end

---@param sVehicle Vehicle
---@param tVehicle Vehicle
---@return number
---@nodiscard
function MachineUtils.getVehiclesDistance(sVehicle, tVehicle)
    local sx, sy, sz = getWorldTranslation(sVehicle.rootNode)
    local tx, ty, tz = getWorldTranslation(tVehicle.rootNode)

    return MachineUtils.getVector3Distance(sx, sy, sz, tx, ty, tz)
end

---@param sx number
---@param sy number
---@param sz number
---@param tx number
---@param ty number
---@param tz number
---@return number
---@nodiscard
function MachineUtils.getVector3Distance(sx, sy, sz, tx, ty, tz)
    local dx = sx - tx
    local dy = sy - ty
    local dz = sz - tz

    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

---@param sx number
---@param sy number
---@param sz number
---@param tx number
---@param ty number
---@param tz number
---@return number dx
---@return number dy
---@return number dz
---@return number distance
---@nodiscard
function MachineUtils.getVector3Direction(sx, sy, sz, tx, ty, tz)
    local x, y, z = tx - sx, ty - sy, tx - sx
    local distance = MathUtil.vector3Length(x, y, z)

    if distance > 0.01 then
        return x / distance, y / distance, z / distance, distance
    end

    return 0, 0, 0, 0
end

---@param x number
---@param z number
---@return number
---@nodiscard
function MachineUtils.getTerrainHeightAtPosition(x, z)
    return getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
end

---@param vehicle Vehicle
---@return number worldPosX
---@return number worldPosY
---@return number worldPosZ
function MachineUtils.getVehicleTerrainHeight(vehicle)
    local worldPosX, _, worldPosZ = getWorldTranslation(vehicle.rootNode)
    local worldPosY = MachineUtils.getTerrainHeightAtPosition(worldPosX, worldPosZ)

    return worldPosX, worldPosY, worldPosZ
end

---@param streamId number
---@param worldPosX number
---@param worldPosY number
---@param worldPosZ number
function MachineUtils.writeCompressedXYZPos(streamId, worldPosX, worldPosY, worldPosZ)
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
function MachineUtils.readCompressedXYZPos(streamId)
    local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
    local paramsY = g_currentMission.vehicleYPosCompressionParams

    local x = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
    local y = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
    local z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)

    return x, y, z
end

---@param streamId number
---@param worldPosX number
---@param worldPosY number
---@param worldPosZ number
function MachineUtils.writeCompressedPosition(streamId, worldPosX, worldPosY, worldPosZ)
    if streamWriteBool(streamId, worldPosY ~= math.huge) then
        MachineUtils.writeCompressedXYZPos(streamId, worldPosX, worldPosY, worldPosZ)
    end
end

---@param streamId number
---@return number worldPosX
---@return number worldPosY
---@return number worldPosZ
function MachineUtils.readCompressedPosition(streamId)
    local x, y, z = 0, math.huge, 0

    if streamReadBool(streamId) then
        x, y, z = MachineUtils.readCompressedXYZPos(streamId)
    end

    return x, y, z
end

local MAP_CHARS = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "r", "s", "t", "u", "v", "z", "y", "w", "q", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }

---@param length number | nil
---@return string
---@nodiscard
function MachineUtils.createUniqueId(length)
    length = length or 12

    local str = ''

    for i = 1, length do
        local r = math.random(1, 35)
        str = str .. MAP_CHARS[r]
    end

    return str
end

---@param x number
---@param y number
---@param z number
---@param text string
---@param textSize number
---@param textOffset number | nil
---@param color table | nil
---@param bold boolean | nil
function MachineUtils.renderTextAtWorldPosition(x, y, z, text, textSize, textOffset, color, bold)
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

---@param vehicle Machine
---@param mode MachineMode
---@return boolean
---@nodiscard
function MachineUtils.getHasInputMode(vehicle, mode)
    local spec = vehicle.spec_machine

    return table.hasElement(spec.modesInput, mode)
end

---@param vehicle Machine
---@param mode MachineMode
---@return boolean
---@nodiscard
function MachineUtils.getHasOutputMode(vehicle, mode)
    local spec = vehicle.spec_machine

    return table.hasElement(spec.modesOutput, mode)
end

---@param vehicle Machine
---@return boolean
---@nodiscard
function MachineUtils.getHasInputs(vehicle)
    local spec = vehicle.spec_machine

    return #spec.modesInput > 0
end

---@param vehicle Machine
---@return boolean
---@nodiscard
function MachineUtils.getHasOutputs(vehicle)
    local spec = vehicle.spec_machine

    return #spec.modesOutput > 0
end

---@param vehicle Machine
---@return number
---@nodiscard
function MachineUtils.getNumInputs(vehicle)
    local spec = vehicle.spec_machine

    return #spec.modesInput
end

---@param vehicle Machine
---@return number
---@nodiscard
function MachineUtils.getNumOutputs(vehicle)
    local spec = vehicle.spec_machine

    return #spec.modesOutput
end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return number normalX
---@return number normalY
---@return number normalZ
---@return number direction
---@return number slopeAngle
function MachineUtils.getSlopeParams(x1, y1, z1, x2, y2, z2)
    local vx1, vy1, vz1 = MathUtil.vector3Normalize(x2 - x1, y2 - y1, z2 - z1)
    local slope = math.abs((y1 - y2) / math.max(MathUtil.vector2Length(x1 - x2, z1 - z2), 1e-6))
    local slopeAngle = math.clamp(slope, 0, 1)
    local vx2, vy2, vz2 = MathUtil.vector3Normalize(-vz1, 0, vx1)
    local nx, ny, nz = MathUtil.crossProduct(vx2, vy2, vz2, vx1, vy1, vz1)
    local d = -(nx * x1 + ny * y1 + nz * z1)

    return nx, ny, nz, d, slopeAngle
end
