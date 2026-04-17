---@class LandscapingUtils
LandscapingUtils = {}

---@type string[]
LandscapingUtils.AREA_ICON_SLICE_IDS = {
    'gui.icon_ingameMenu_map',
    'gui.icon_ingameMenu_productionChains',
    'gui.icon_ingameMenu_contracts',
    'terraFarm.icon_area',
    'terraFarm.icon_excavator',
    'terraFarm.icon_bulldozer',
    'terraFarm.icon_factory',
    'terraFarm.icon_garage',
    'terraFarm.icon_house',
    'terraFarm.icon_warehouse',
    'terraFarm.icon_road',
}

---@type LandscapingAreaColor[]
LandscapingUtils.AREA_COLORS = {
    {
        name = g_i18n:getText('ui_colorOrange'),
        diffuseColor = { 1, 0.1, 0, 1 },
        decalColor = { 1, 0.2, 0, 1 }
    },
    {
        name = g_i18n:getText('ui_colorRed'),
        diffuseColor = { 0.7, 0, 0, 1 },
        decalColor = { 1, 0, 0, 1 }
    },
    {
        name = g_i18n:getText('ui_colorYellow'),
        diffuseColor = { 0.5, 0.5, 0, 1 },
        decalColor = { 0.5, 0.5, 0, 1 }
    },
    {
        name = g_i18n:getText('ui_colorGreenLight'),
        diffuseColor = { 0, 0.8, 0, 1 },
        decalColor = { 0, 1, 0, 1 }
    },
    {
        name = g_i18n:getText('ui_colorGreen'),
        diffuseColor = { 0, 0.2, 0, 1 },
        decalColor = { 0, 0.2, 0, 1 }
    },
    {
        name = g_i18n:getText('ui_colorTurquoise'),
        diffuseColor = { 0, 0.2, 0.2, 1 },
        decalColor = { 0, 0.25, 0.25, 1 }
    },
    {
        name = g_i18n:getText('ui_colorBlue'),
        diffuseColor = { 0, 0.25, 0.8, 1 },
        decalColor = { 0, 0.25, 0.8, 1 }
    },
    {
        name = g_i18n:getText('ui_colorPink'),
        diffuseColor = { 1, 0, 1, 1 },
        decalColor = { 1, 0, 1, 1 }
    },
    {
        name = g_i18n:getText('ui_colorPurple'),
        diffuseColor = { 0.1, 0.05, 1, 1 },
        decalColor = { 0.2, 0.05, 1, 1 }
    },
    {
        name = g_i18n:getText('ui_colorWhite'),
        diffuseColor = { 1, 1, 1, 1 },
        decalColor = { 1, 1, 1, 1 }
    }
}


---@type string[]
LandscapingUtils.AREA_COLOR_NAMES = (function ()
    local names = {}

    for _, item in ipairs(LandscapingUtils.AREA_COLORS) do
        table.insert(names, item.name)
    end

    return names
end)()

---@param n number
---@return string
---@nodiscard
function LandscapingUtils.getAreaIconSliceId(n)
    return LandscapingUtils.AREA_ICON_SLICE_IDS[n] or LandscapingUtils.AREA_ICON_SLICE_IDS[1]
end

---@param index number
---@return number[] diffuseColor
---@return number[] decalColor
---@nodiscard
function LandscapingUtils.getAreaColorByIndex(index)
    local item = LandscapingUtils.AREA_COLORS[index] or LandscapingUtils.AREA_COLORS[1]
    return item.diffuseColor, item.decalColor
end

---@param str string
---@return number[] diffuseColor
---@return number[] decalColor
---@nodiscard
function LandscapingUtils.getAreaColorByName(str)
    for index, name in ipairs(LandscapingUtils.AREA_COLOR_NAMES) do
        if name:upper() == str:upper() then
            return LandscapingUtils.getAreaColorByIndex(index)
        end
    end

    local item = LandscapingUtils.AREA_COLORS[1]

    return item.diffuseColor, item.decalColor
end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return number nx
---@return number ny
---@return number nz
---@return number direction
function LandscapingUtils.getSlopeParams(x1, y1, z1, x2, y2, z2)
    local vx1, vy1, vz1 = MathUtil.vector3Normalize(x2 - x1, y2 - y1, z2 - z1)
    local vx2, vy2, vz2 = MathUtil.vector3Normalize(-vz1, 0, vx1)
    local nx, ny, nz = MathUtil.crossProduct(vx2, vy2, vz2, vx1, vy1, vz1)
    local d = -(nx * x1 + ny * y1 + nz * z1)

    return nx, ny, nz, d
end

---@param x number
---@param z number
---@return number
function LandscapingUtils.getTerrainHeightAt(x, z)
    return getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
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
---@return number px
---@return number py
---@return number pz
---@return number distance
function LandscapingUtils.getClosestPointOnLineSegmentXZ(startX, startY, startZ, endX, endY, endZ, targetX, targetY, targetZ)
    local dirTargetX = targetX - startX
    local dirTargetZ = targetZ - startZ
    local dirLineX = endX - startX
    local dirLineZ = endZ - startZ

    local lengthSq = dirLineX * dirLineX + dirLineZ * dirLineZ

    if lengthSq == 0 then
        return startX, startY, startZ, 0
    end

    local distance = (dirTargetX * dirLineX + dirTargetZ * dirLineZ) / lengthSq

    if distance < 0 then
        return startX, startY, startZ, 0
    elseif distance > 1 then
        return endX, endY, endZ, 1
    else
        return startX + dirLineX * distance,
            startY + (endY - startY) * distance,
            startZ + dirLineZ * distance,
            distance
    end
end

---@param sx number
---@param sy number
---@param sz number
---@param ex number
---@param ey number
---@param ez number
---@return number? dirX
---@return number dirY
---@return number dirZ
---@return number distance
function LandscapingUtils.getWorldDirection(sx, sy, sz, ex, ey, ez)
    local wdx, wdy, wdz = ex - sx, ey - sy, ez - sz
    local dist = MathUtil.vector3Length(wdx, wdy, wdz)

    if dist and dist > 0.001 then
        return wdx / dist, wdy / dist, wdz / dist, dist
    end

    return nil, 0, 0, 0
end

---@param shapeNode number
---@param rootNode number
---@param childNodes number[]
---@param index number
---@param sx number
---@param sy number
---@param sz number
---@param ex number
---@param ey number
---@param ez number
---@return number node
function LandscapingUtils.setAreaSegmentTransform(shapeNode, rootNode, childNodes, index, sx, sy, sz, ex, ey, ez)
    local node = childNodes[index]

    if node == nil then
        if index > 1 and childNodes[index - 1] == nil then
            Logging.error('LandscapingUtils.setAreaSegmentTransform() called in non-consecutive order!')
            return 0
        end

        node = LandscapingUtils.createAreaSegment(shapeNode, rootNode, childNodes, index)
    end

    LandscapingUtils.setSegmentTransform(node, sx, sy, sz, ex, ey, ez)

    return node
end

---@param shapeNode number
---@param rootNode number
---@param childNodes number[]
---@param index number
---@return number node
function LandscapingUtils.createAreaSegment(shapeNode, rootNode, childNodes, index)
    local node = clone(shapeNode, true)
    link(rootNode, node)
    table.insert(childNodes, node)

    return node
end

---@param node number
---@param sx number
---@param sy number
---@param sz number
---@param ex number
---@param ey number
---@param ez number
function LandscapingUtils.setSegmentTransform(node, sx, sy, sz, ex, ey, ez)
    local dx, dy, dz, distance = LandscapingUtils.getWorldDirection(sx, sy, sz, ex, ey, ez)

    setWorldTranslation(node, sx, sy, sz)

    if dx == nil then
        setDirection(node, 0, 0, 1, 0, 1, 0)
        setScale(node, 1, 1, 0.0001)
        setShaderParameter(node, "meshScaleZ", 0, 0, 0, 0, false)
    else
        setDirection(node, dx, dy, dz, 0, 1, 0)
        setScale(node, 1, 1, distance)
        setShaderParameter(node, 'meshScaleZ', distance, 0, 0, 0, false)
    end
end

---@param area LandscapingArea
---@param fromMenu? boolean
function LandscapingUtils.openAreaInEditor(area, fromMenu)
    if area.className == LandscapingAreaPolygon.CLASS_NAME then
        g_polygonEditor:show(area:clone(), fromMenu)
    elseif area.className == LandscapingAreaPath.CLASS_NAME then
        g_pathEditor:show(area:clone(), fromMenu)
    end
end

---@param fromMenu? boolean
function LandscapingUtils.createAreaInEditor(fromMenu)
    ---@param item? AreaTypeItem
    local function selectCallback(item)
        if item ~= nil then
            local area = g_landscapingManager:createArea(item.className)

            if area ~= nil then
                LandscapingUtils.openAreaInEditor(area, fromMenu)
            end
        end
    end

    g_selectAreaTypeDialog:setSelectCallback(selectCallback)
    g_selectAreaTypeDialog:show()
end

---@param terrainLayerName string
---@return string
---@nodiscard
function LandscapingUtils.getTerrainLayerTitle(terrainLayerName)
    for _, groundType in pairs(g_groundTypeManager.groundTypeMappings) do
        if groundType.layerName == terrainLayerName then
            return g_i18n:convertText(groundType.title) or terrainLayerName
        end
    end

    return terrainLayerName
end

local SQRT_2_DIV_FACTOR = 1 / math.sqrt(2)

-- Optimized
---@param tbl table
---@param x number
---@param z number
---@param radius number
function LandscapingUtils.addModifiedCircleArea(tbl, x, z, radius)
    local terrainUnit = getTerrainHeightmapUnitSize(g_terrainNode)
    local halfTerrainUnit = terrainUnit * 0.5

    if radius < terrainUnit + halfTerrainUnit then
        local size = radius * 2 * SQRT_2_DIV_FACTOR
        LandscapingUtils.addModifiedSquareArea(tbl, x, z, size)
        return
    end

    local invTerrainUnit = 1 / terrainUnit
    local maxOx = radius * invTerrainUnit
    local minOx = -maxOx
    local r2 = radius * radius

    for ox = minOx, maxOx - 1 do
        local xStart = ox * terrainUnit
        local xEnd = xStart + terrainUnit

        local ax1 = xStart
        local ax2 = xEnd

        local zOffset1 = math.sqrt(r2 - ax1 * ax1)
        local zOffset2 = math.sqrt(r2 - ax2 * ax2)

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

---@param tbl table
---@param x number
---@param z number
---@param size number
function LandscapingUtils.addModifiedSquareArea(tbl, x, z, size)
    local h = size * 0.5

    local x1 = x - h
    local x2 = x + h
    local z1 = z - h
    local z2 = z + h

    table.insert(tbl, { x1, z1, x2, z1, x1, z2 })
end

---@param volume number
---@param fillTypeIndex number
---@return number
---@nodiscard
function LandscapingUtils.volumeToFillTypeLiters(volume, fillTypeIndex)
    return volume * 1000
end

---@param liters number
---@param fillTypeIndex number
---@return number
---@nodiscard
function LandscapingUtils.fillTypeLitersToVolume(liters, fillTypeIndex)
    return liters / 1000
end

---@param px number
---@param pz number
---@param points number[][]
---@return boolean
---@nodiscard
function LandscapingUtils.getIsPointInsidePolygon(px, pz, points)
    local count = 0
    local n = #points

    local v1 = points[1]
    local x1 = v1[1]
    local z1 = v1[3]

    for i = 1, n do
        local j = i + 1
        if j > n then j = 1 end

        local v2 = points[j]
        local x2 = v2[1]
        local z2 = v2[3]

        local tz = pz
        if tz == z1 or tz == z2 then
            tz = tz + 0.00001
        end

        local z1Above = z1 > tz
        local z2Above = z2 > tz

        if z1Above ~= z2Above then
            local dx = x2 - x1
            local dz = z2 - z1
            local t = (tz - z1) / dz
            local xIntersect = x1 + dx * t

            if px < xIntersect then
                count = count + 1
            end
        end

        x1 = x2
        z1 = z2
    end

    return (count % 2 == 1)
end

---@param rootNode number
---@param borderMode BorderMode
---@param diffuseColor number[]
---@param diffuseAlpha? number
---@param decalColor number[]
---@param decalAlpha? number
function LandscapingUtils.setAreaBorderParameters(rootNode, borderMode, diffuseColor, diffuseAlpha, decalColor, decalAlpha)
    if rootNode ~= nil then
        local numChildren = getNumOfChildren(rootNode)

        for i = 0, numChildren - 1 do
            local node = getChildAt(rootNode, i)
            LandscapingUtils.setAreaBorderShaderParameters(node, borderMode, diffuseColor, diffuseAlpha, decalColor, decalAlpha)
        end
    end
end

---@param node number
---@param borderMode BorderMode
---@param diffuseColor number[]
---@param diffuseAlpha? number
---@param decalColor number[]
---@param decalAlpha? number
function LandscapingUtils.setAreaBorderShaderParameters(node, borderMode, diffuseColor, diffuseAlpha, decalColor, decalAlpha)
    setShaderParameter(node, 'diffuseColor', diffuseColor[1], diffuseColor[2], diffuseColor[3], diffuseAlpha or diffuseColor[4], false)
    setShaderParameter(node, 'decalColor', decalColor[1], decalColor[2], decalColor[3], decalAlpha or decalColor[4], false)
    setShaderParameter(node, 'mode', borderMode, nil, nil, nil, false)
end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param color number[]
function LandscapingUtils.renderAngleTextBetween(x1, y1, z1, x2, y2, z2, color)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1

    local distance = math.sqrt(dx * dx + dy * dy + dz * dz)

    if distance > 0.45 then
        local cx = (x1 + x2) * 0.5
        local cy = (y1 + y2) * 0.5
        local cz = (z1 + z2) * 0.5
        local horizontalDist = math.sqrt(dx * dx + dz * dz)
        local pitch = math.abs(math.deg(math.atan2(dy, horizontalDist)))

        local text = string.format('%.1f°', pitch ~= -0 and pitch or 0)
        ModUtils.renderTextAtWorldPosition(cx, cy, cz, text, 0.014, 0.015, color)
    end
end

---@param rootNode number
---@param vertices number[]
---@param colorIndex WaterplaneColor
function LandscapingUtils.createWaterplaneShapesFromVertices(rootNode, vertices, colorIndex)
    local colorData = LandscapingWaterplane.COLOR_DATA[colorIndex]
    local r, g, b, a = unpack(colorData.fogColor)
    local depthScale, refractionColorScale, getWaterDepthScale, inscatteringScale = unpack(colorData.fogDepth)

    if #vertices < 3 then
        Logging.error('LandscapingUtils.createWaterplaneShapesFromVertices() Number of vertices less than 3!')
        return
    end

    local waterplaneNode = createPlaneShapeFrom2DContour('water_plane', vertices, true)
    local waterplaneMirrorsNode = clone(waterplaneNode, false, false, false)

    link(rootNode, waterplaneNode)
    link(rootNode, waterplaneMirrorsNode)

    setShapeReceiveShadowmap(waterplaneNode, true)
    setShapeCastShadowmap(waterplaneNode, false)
    setShapeReceiveShadowmap(waterplaneMirrorsNode, true)
    setShapeCastShadowmap(waterplaneMirrorsNode, false)

    removeFromPhysics(waterplaneNode)
    setCollisionFilter(waterplaneNode, CollisionFlag.WATER, 1)
    addToPhysics(waterplaneNode)

    local waterMaterial = g_materialManager:getBaseMaterialByName("riceFieldWaterSimulation")
    local waterMirrorMaterial = g_materialManager:getBaseMaterialByName("riceFieldWaterInMirror")

    if waterMaterial ~= nil and waterMirrorMaterial ~= nil then
        setMaterial(waterplaneNode, waterMaterial, 0)
        setMaterial(waterplaneMirrorsNode, waterMirrorMaterial, 0)

        setShaderParameter(waterplaneNode, "underwaterFogColor", r, g, b, a, false)
        setShaderParameter(waterplaneNode, "underwaterFogDepth", depthScale, refractionColorScale, getWaterDepthScale, inscatteringScale, false)

        setObjectMask(waterplaneMirrorsNode, ObjectMask.SHAPE_VIS_MIRROR_ONLY)
    else
        Logging.warning('LandscapingUtils.createWaterplaneShapesFromVertices() Water simulation materials not loaded!')
    end

    if g_currentMission.shallowWaterSimulation ~= nil then
        g_currentMission.shallowWaterSimulation:addWaterPlane(waterplaneNode)
        g_currentMission.shallowWaterSimulation:addAreaGeometry(waterplaneNode)
    else
        Logging.warning('LandscapingUtils.createWaterplaneShapesFromVertices() shallowWaterSimulation is not loaded!')
    end
end

---@param rootNode number
function LandscapingUtils.deleteWaterplaneShapes(rootNode)
    if getNumOfChildren(rootNode) == 2 then
        local waterplaneNode = getChildAt(rootNode, 0)
        local waterplaneMirrorsNode = getChildAt(rootNode, 1)

        g_currentMission.shallowWaterSimulation:removeWaterPlane(waterplaneNode)
        g_currentMission.shallowWaterSimulation:removeAreaGeometry(waterplaneNode)

        delete(waterplaneNode)
        delete(waterplaneMirrorsNode)
    end
end
