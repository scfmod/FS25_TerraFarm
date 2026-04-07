source(g_modDirectory .. 'scripts/gui/editor/EditorCamera.lua')
source(g_modDirectory .. 'scripts/gui/editor/EditorCursor.lua')

source(g_modDirectory .. 'scripts/gui/editor/EditorUtils.lua')
source(g_modDirectory .. 'scripts/gui/editor/Editor.lua')
source(g_modDirectory .. 'scripts/gui/editor/AreaEditor.lua')
source(g_modDirectory .. 'scripts/gui/editor/PathEditor.lua')
source(g_modDirectory .. 'scripts/gui/editor/PolygonEditor.lua')
source(g_modDirectory .. 'scripts/gui/editor/WaterplaneEditor.lua')

source(g_modDirectory .. 'scripts/landscaping/events/AreaDeleteEvent.lua')
source(g_modDirectory .. 'scripts/landscaping/events/AreaRegisterEvent.lua')
source(g_modDirectory .. 'scripts/landscaping/events/AreaUpdateEvent.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingArea.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingAreaPath.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingAreaPolygon.lua')

source(g_modDirectory .. 'scripts/landscaping/events/WaterplaneDeleteEvent.lua')
source(g_modDirectory .. 'scripts/landscaping/events/WaterplaneRegisterEvent.lua')
source(g_modDirectory .. 'scripts/landscaping/events/WaterplaneSetVisibleEvent.lua')
source(g_modDirectory .. 'scripts/landscaping/events/WaterplaneUpdateEvent.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingWaterplane.lua')

source(g_modDirectory .. 'scripts/landscaping/LandscapingBase.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingInput.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingInputFlatten.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingInputLower.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingInputPaint.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingInputSlope.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingInputSmooth.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingOutput.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingOutputFlatten.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingOutputPaint.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingOutputRaise.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingOutputSlope.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingOutputSmooth.lua')

LandscapingArea.createXMLSchema()

---@class TerrainLayerItem
---@field id number
---@field name string
---@field title string

---@class LandscapingManager
---@field areas table<string, LandscapingArea>
---@field waterplanesRootNode number
---@field waterplanes table<string, LandscapingWaterplane>
---@field waterplaneGroupNodes table<string, number>
---@field borderRootNode number -- Root node for ALL area border shapes, except editor
---@field borderMode BorderMode
---@field borderVisibilityMode BorderVisibilityMode
---@field borderColor number[]
---@field borderDecalColor? number[]
---@field borderIntensity number[]
---@field borderDash number[]
---@field areaBorderRootNode table<string, number>
---@field areaBorderNodes table<string, number[]>
---@field areaBorderShape number
---
---@field terrainLayers TerrainLayerItem[]
---@field nameToTerrainLayer table<string, TerrainLayerItem>
---@field idToTerrainLayer table<number, TerrainLayerItem>
---
---@field activeAreaId? string
---@field lastActiveAreaId? string
LandscapingManager = {}
LandscapingManager.BORDER_SHAPE_FILENAME = g_modDirectory .. 'data/areaBorderLine.i3d'

---@enum BorderMode
BorderMode = {
    NORMAL = 1,
    DECAL = 2,
    MESH = 3,
}

---@enum BorderVisibilityMode
BorderVisibilityMode = {
    ALL = 1,
    ACTIVE_ONLY = 2,
    NONE = 3
}

LandscapingManager.DEFAULT_FILLTYPE = 'STONE'
LandscapingManager.DEFAULT_TERRAIN_LAYERS = {
    'DIRT',
    'GRAVEL'
}

LandscapingManager.BORDER_COLOR = { 0.3, 0.3, 0.3, 0.5 }
LandscapingManager.BORDER_DECAL_COLOR = { 0.3, 0.3, 0.3, 0.85 }

local LandscapingManager_mt = Class(LandscapingManager)

---@return LandscapingManager
function LandscapingManager.new()
    ---@type LandscapingManager
    local self = setmetatable({}, LandscapingManager_mt)

    self.borderRootNode = createTransformGroup('borderRootNode')
    link(getRootNode(), self.borderRootNode)

    self.waterplanesRootNode = createTransformGroup('waterplanesRootNode')
    link(getRootNode(), self.waterplanesRootNode)

    self.waterplanes = {}
    self.waterplaneGroupNodes = {}
    self.areas = {}
    self.areaBorderRootNode = {}
    self.areaBorderNodes = {}
    self.borderVisibilityMode = BorderVisibilityMode.ALL
    self.borderMode = BorderMode.NORMAL
    self.borderColor = LandscapingManager.BORDER_COLOR
    self.borderDecalColor = LandscapingManager.BORDER_DECAL_COLOR
    self.borderIntensity = { 1, 1, 4, 1 }
    self.borderDash = { 16, 1, 0, 0 }

    self.terrainLayers = {}
    self.nameToTerrainLayer = {}
    self.idToTerrainLayer = {}

    self:loadWaterMaterialHolder()

    g_modController:subscribe(ModEvent.onPostTerrainInit, self.onPostTerrainInit, self)
    g_modController:subscribe(ModEvent.onTerrainInit, self.onTerrainInit, self)
    g_modController:subscribe(ModEvent.onSendInitialClientState, self.onSendInitialClientState, self)

    if g_client ~= nil then
        g_messageCenter:subscribe(ModMessageType.ACTIVE_AREA_CHANGED, self.onActiveAreaChanged, self)
        g_messageCenter:subscribe(ModMessageType.ACTIVE_MACHINE_CHANGED, self.onActiveMachineChanged, self)
        g_messageCenter:subscribe(ModMessageType.LANDSCAPING_AREA_UPDATED, self.onAreaUpdated, self)
    end

    return self
end

function LandscapingManager:loadShapes()
    local i3dNode = g_i3DManager:loadSharedI3DFile(LandscapingManager.BORDER_SHAPE_FILENAME, false, false)

    if i3dNode ~= 0 then
        self.areaBorderShape = getChildAt(i3dNode, 0)

        link(self.borderRootNode, self.areaBorderShape)
        delete(i3dNode)
        setVisibility(self.areaBorderShape, false)

        LandscapingUtils.updateAreaBorderShaderNode(self.areaBorderShape)
    end
end

function LandscapingManager:loadWaterMaterialHolder()
    local filename = Utils.getFilename('$data/shared/materialHolders/waterSimulationMaterialHolder.i3d')
    g_i3DManager:loadI3DFile(filename, true, false)
end

function LandscapingManager:onTerrainInit()
    local numLayers = getTerrainNumOfLayers(g_terrainNode)

    for i = 0, numLayers - 1 do
        local numSubLayers = getTerrainLayerNumOfSubLayers(g_terrainNode, i)

        if numSubLayers > 1 then
            local name = getTerrainLayerName(g_terrainNode, i)
            local title = LandscapingUtils.getTerrainLayerTitle(name)

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
                Logging.warning('LandscapingManager:onTerrainInit() Duplicate layer name found: %s', name)
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

---@return TerrainLayerItem[]
---@nodiscard
function LandscapingManager:getTerrainLayers()
    return self.terrainLayers
end

---@param id number
---@return TerrainLayerItem?
---@nodiscard
function LandscapingManager:getTerrainLayerById(id)
    return self.idToTerrainLayer[id]
end

---@param name string
---@return TerrainLayerItem?
---@nodiscard
function LandscapingManager:getTerrainLayerByName(name)
    return self.nameToTerrainLayer[name]
end

---@return TerrainLayerItem
---@nodiscard
function LandscapingManager:getDefaultTerrainLayer()
    for _, name in ipairs(LandscapingManager.DEFAULT_TERRAIN_LAYERS) do
        if self.nameToTerrainLayer[name] ~= nil then
            return self.nameToTerrainLayer[name]
        end
    end

    return self.terrainLayers[1]
end

---@return number
---@nodiscard
function LandscapingManager:getDefaultTerrainLayerId()
    local terrainLayer = self:getDefaultTerrainLayer()

    return terrainLayer and terrainLayer.id or 0
end

---@return number
---@nodiscard
function LandscapingManager:getDefaultFillTypeIndex()
    return g_fillTypeManager:getFillTypeIndexByName(LandscapingManager.DEFAULT_FILLTYPE) or FillType.UNKNOWN
end

---@param vehicle? Machine
function LandscapingManager:onActiveMachineChanged(vehicle)
    ---@type string?
    local id = nil

    if vehicle ~= nil then
        id = vehicle:getMachineLandscapingAreaId()
    end

    self:setActiveAreaId(id)
end

---@param uniqueId? string
---@param vehicle Machine
function LandscapingManager:onActiveAreaChanged(uniqueId, vehicle)
    self:setActiveAreaId(uniqueId)
end

---@param area LandscapingArea
function LandscapingManager:onAreaUpdated(area)
    if area.uniqueId == self.activeAreaId then
        self:updateActiveAreaBorder()
    end
end

---@param mode BorderVisibilityMode
---@param noUpdateSettings? boolean
function LandscapingManager:setBorderVisibilityMode(mode, noUpdateSettings)
    if self.borderVisibilityMode ~= mode then
        self.borderVisibilityMode = mode

        if mode == BorderVisibilityMode.NONE then
            setVisibility(self.borderRootNode, false)
        else
            self:updateActiveAreaBorder()
            self:updateInactiveBorders()
            setVisibility(self.borderRootNode, true)
        end

        if not noUpdateSettings then
            g_modSettings:saveUserSettings()
        end
    end
end

---@param id? string
function LandscapingManager:setActiveAreaId(id)
    if self.areas[id] == nil then
        id = nil
    end

    if self.activeAreaId ~= id then
        self.lastActiveAreaId = self.activeAreaId
        self.activeAreaId = id

        self:updateActiveAreaBorder()
    end
end

---@return number diffuseAlpha
---@return number decalAlpha
function LandscapingManager:getAreaBorderAlpha()
    local diffuseAlpha = 1
    local decalAlpha = 1

    if self.borderMode == BorderMode.DECAL then
        diffuseAlpha = 0
    elseif self.borderMode == BorderMode.MESH then
        decalAlpha = 0
    end

    return diffuseAlpha, decalAlpha
end

function LandscapingManager:updateActiveAreaBorder()
    local diffuseAlpha, decalAlpha = self:getAreaBorderAlpha()
    local lastActiveAreaId = self.lastActiveAreaId

    if lastActiveAreaId ~= nil then
        local lastArea = self.areas[lastActiveAreaId]
        local rootNode = self.areaBorderRootNode[lastActiveAreaId]

        if rootNode ~= nil and lastArea ~= nil then
            local visible = self.borderVisibilityMode ~= BorderVisibilityMode.ACTIVE_ONLY and lastArea.visible

            setVisibility(rootNode, false)
            LandscapingUtils.setAreaBorderColor(rootNode, LandscapingManager.BORDER_COLOR, diffuseAlpha, LandscapingManager.BORDER_DECAL_COLOR, decalAlpha)
            setVisibility(rootNode, visible)
        end

        self.lastActiveAreaId = nil
    end

    local activeAreaId = self.activeAreaId
    local activeArea = self.areas[activeAreaId]

    if activeAreaId ~= nil and activeArea ~= nil then
        local rootNode = self.areaBorderRootNode[activeAreaId]

        if rootNode ~= nil and activeArea ~= nil then
            local diffuseColor, decalColor = activeArea:getBorderColor()

            setVisibility(rootNode, false)
            LandscapingUtils.setAreaBorderColor(rootNode, diffuseColor, diffuseAlpha, decalColor, decalAlpha)
            setVisibility(rootNode, true)
        end
    end
end

function LandscapingManager:updateInactiveBorders()
    local activeBorderId = self.activeAreaId
    local visible = self.borderVisibilityMode ~= BorderVisibilityMode.ACTIVE_ONLY

    for id, rootNode in pairs(self.areaBorderRootNode) do
        if id ~= activeBorderId then
            setVisibility(rootNode, false)
            LandscapingUtils.setAreaBorderColor(rootNode, LandscapingManager.BORDER_COLOR, nil, LandscapingManager.BORDER_DECAL_COLOR, nil)
            setVisibility(rootNode, visible)
        end
    end
end

function LandscapingManager:setWaterplanesVisible(visible)
    setVisibility(self.waterplanesRootNode, visible)
end

---@param area LandscapingArea
---@param forceVisibility? boolean
function LandscapingManager:updateAreaBorderVisibility(area, forceVisibility)
    local rootNode = self.areaBorderRootNode[area.uniqueId]

    if rootNode ~= nil then
        if forceVisibility ~= nil then
            setVisibility(rootNode, forceVisibility)
        else
            local isActive = self.activeAreaId == area.uniqueId
            local visible = area.visible and (self.borderVisibilityMode ~= BorderVisibilityMode.ACTIVE_ONLY or isActive)

            setVisibility(rootNode, visible)
        end
    end
end

---@return LandscapingArea[]
---@nodiscard
function LandscapingManager:getAreas()
    local result = {}

    for _, area in pairs(self.areas) do
        table.insert(result, area)
    end

    return table.clone(result)
end

---@return LandscapingWaterplane[]
---@nodiscard
function LandscapingManager:getWaterplanes()
    local result = {}

    for _, waterplane in pairs(self.waterplanes) do
        table.insert(result, waterplane)
    end

    return table.clone(result)
end

---@param area LandscapingArea
---@return number[]
function LandscapingManager:getAreaBorderShapes(area)
    return self.areaBorderNodes[area.uniqueId]
end

---@param area LandscapingArea
---@return number
function LandscapingManager:getAreaBorderRootNode(area)
    return self.areaBorderRootNode[area.uniqueId]
end

---@param uniqueId string
---@return LandscapingArea?
function LandscapingManager:getAreaByUniqueId(uniqueId)
    return self.areas[uniqueId]
end

---@return boolean
function LandscapingManager:getCanCreateArea()
    local i = 0
    for _, _ in pairs(self.areas) do i = i + 1 end
    return i <= LandscapingArea.MAX_NUM_AREAS
end

function LandscapingManager:getCanCreateWaterplane()
    local i = 0
    for _, _ in pairs(self.waterplanes) do i = i + 1 end
    return i <= LandscapingWaterplane.MAX_NUM_PLANES
end

---@param className string
---@param uniqueId? string
---@return LandscapingArea?
---@nodiscard
function LandscapingManager:createArea(className, uniqueId)
    if self:getCanCreateArea() then
        local class = _G[className]

        if class ~= nil then
            ---@type LandscapingArea
            local area = class.new(uniqueId)

            return area
        else
            Logging.error('LandscapingManager:createArea() Unknown class "%s"', tostring(className))
        end
    end
end

---@param area LandscapingArea
---@param noEventSend? boolean
function LandscapingManager:registerArea(area, noEventSend)
    local uniqueId = area.uniqueId

    if not self:getCanCreateArea() then
        Logging.error('LandscapingManager:registerArea() can not create any more areas, MAX_NUM_AREAS = %d', LandscapingArea.MAX_NUM_AREAS)
        return
    elseif uniqueId == nil then
        Logging.error('LandscapingManager:registerArea() uniqueId is nil')
        return
    end

    if self.areas[uniqueId] == nil then
        AreaRegisterEvent.sendEvent(area, noEventSend)

        self.areas[uniqueId] = area

        if g_client ~= nil then
            local rootNode = createTransformGroup('areaBorderRootNode')
            link(self.borderRootNode, rootNode)
            self.areaBorderRootNode[uniqueId] = rootNode
            self.areaBorderNodes[uniqueId] = {}

            self:updateAreaBorderVisibility(area)
            self:updateAreaBorder(area)
        end

        g_messageCenter:publish(ModMessageType.LANDSCAPING_AREA_REGISTERED, area)
    else
        Logging.warning('LandscapingManager:registerArea() Trying to register duplicate uniqueId entry "%s"', area.uniqueId)
    end
end

function LandscapingManager:deleteAreaByUniqueId(uniqueId, noEventSend)
    if self.areas[uniqueId] ~= nil then
        AreaDeleteEvent.sendEvent(uniqueId, noEventSend)

        self.areas[uniqueId] = nil

        if g_client ~= nil and self.areaBorderRootNode[uniqueId] ~= nil then
            delete(self.areaBorderRootNode[uniqueId])
            self.areaBorderRootNode[uniqueId] = nil
            self.areaBorderNodes[uniqueId] = nil
        end

        g_messageCenter:publish(ModMessageType.LANDSCAPING_AREA_DELETED, uniqueId)
    else
        Logging.warning('LandscapingManager:deleteAreaByUniqueId() Unknown uniqueId "%s"', uniqueId)
    end
end

---@param area LandscapingArea
---@param noEventSend? boolean
function LandscapingManager:updateArea(area, noEventSend)
    if self.areas[area.uniqueId] ~= nil then
        AreaUpdateEvent.sendEvent(area, noEventSend)

        self.areas[area.uniqueId] = area

        if g_client ~= nil then
            self:updateAreaBorderVisibility(area)
            self:updateAreaBorder(area)

            if self.activeAreaId == area.uniqueId then
                self:updateActiveAreaBorder()
            end
        end

        g_messageCenter:publish(ModMessageType.LANDSCAPING_AREA_UPDATED, area)
    else
        Logging.error('LandscapingManager:updateArea() Unknown uniqueId "%s"', area.uniqueId)
    end
end

---@param area LandscapingArea
function LandscapingManager:updateAreaBorder(area)
    if self.areaBorderRootNode[area.uniqueId] ~= nil then
        area:updateAreaBorder(self.areaBorderShape, self.areaBorderRootNode[area.uniqueId], self.areaBorderNodes[area.uniqueId])
    end
end

---@param mode BorderMode
---@param noUpdateSettings? boolean
function LandscapingManager:setBorderMode(mode, noUpdateSettings)
    if self.borderMode ~= mode then
        self.borderMode = mode

        self:updateActiveAreaBorder()
        self:updateInactiveBorders()

        if not noUpdateSettings then
            g_modSettings:saveUserSettings()
        end
    end
end

function LandscapingManager:loadAreasFromXML()
    local xmlFile = ModUtils.loadSavegameDirectoryXMLFile('terraFarmAreas', 'terraFarmAreas.xml', LandscapingArea.XML_SCHEMA)

    if xmlFile ~= nil then
        for _, key in xmlFile:iterator('areas.landscaping.area') do
            local className = xmlFile:getValue(key .. '#className')
            local area = self:createArea(className)

            if area ~= nil and area:loadFromXMLFile(xmlFile, key) then
                self:registerArea(area, true)
            end
        end

        for _, key in xmlFile:iterator('areas.waterplanes.area') do
            local waterplane = LandscapingWaterplane.new()

            if waterplane:loadFromXMLFile(xmlFile, key) then
                self:registerWaterplane(waterplane, true)
            end
        end

        xmlFile:delete()
    end
end

function LandscapingManager:saveAreasToXML()
    local xmlFile = ModUtils.createSavegameDirectoryXMLFile('terraFarmAreas', 'terraFarmAreas.xml', 'areas', LandscapingArea.XML_SCHEMA)

    if xmlFile ~= nil then
        local i = 0

        for _, area in pairs(self.areas) do
            local key = string.format('areas.landscaping.area(%i)', i)

            area:saveToXMLFile(xmlFile, key)

            i = i + 1
        end

        i = 0

        for _, waterplane in pairs(self.waterplanes) do
            local key = string.format('areas.waterplanes.area(%i)', i)

            local _ = waterplane:saveToXMLFile(xmlFile, key)

            i = i + 1
        end

        xmlFile:save()
        xmlFile:delete()
    end
end

function LandscapingManager:onPostTerrainInit()
    if g_server ~= nil then
        self:loadAreasFromXML()
    end
end

---@param connection Connection
function LandscapingManager:onSendInitialClientState(connection)
    connection:sendEvent(SetLandscapingAreasEvent.new())
    connection:sendEvent(SetWaterplanesEvent.new())
end

---@param waterplane LandscapingWaterplane
---@param noEventSend? boolean
function LandscapingManager:registerWaterplane(waterplane, noEventSend)
    local uniqueId = waterplane.uniqueId

    if not self:getCanCreateWaterplane() then
        Logging.error('LandscapingManager:registerWaterplane() can not create any more waterplanes, MAX_NUM_PLANES = %d', LandscapingWaterplane.MAX_NUM_PLANES)
        return
    elseif uniqueId == nil then
        Logging.error('LandscapingManager:registerWaterplane() uniqueId is nil')
        return
    end

    if self.waterplanes[uniqueId] == nil then
        WaterplaneRegisterEvent.sendEvent(waterplane, noEventSend)

        self.waterplanes[uniqueId] = waterplane

        local groupNode = createTransformGroup('waterplane_root')
        link(self.waterplanesRootNode, groupNode)
        setWorldTranslation(groupNode, 0, waterplane.targetY, 0)
        setVisibility(groupNode, waterplane.visible)

        self.waterplaneGroupNodes[uniqueId] = groupNode

        self:updateWaterplaneShapes(waterplane)

        g_messageCenter:publish(ModMessageType.WATERPLANE_REGISTERED, waterplane)
    else
        Logging.error('LandscapingManager:registerWaterplane() Trying to register a waterplane with duplicate uniqueId')
    end
end

---@param waterplane LandscapingWaterplane
---@param noEventSend? boolean
function LandscapingManager:updateWaterplane(waterplane, noEventSend)
    local uniqueId = waterplane.uniqueId

    if self.waterplanes[uniqueId] ~= nil then
        WaterplaneUpdateEvent.sendEvent(waterplane, noEventSend)

        self.waterplanes[uniqueId] = waterplane

        local groupNode = self.waterplaneGroupNodes[uniqueId]
        setWorldTranslation(groupNode, 0, waterplane.targetY, 0)
        setVisibility(groupNode, waterplane.visible)

        self:updateWaterplaneShapes(waterplane)

        g_messageCenter:publish(ModMessageType.WATERPLANE_UPDATED, waterplane)
    else
        Logging.error('LandscapingManager:updateWaterplane() Unknown uniqueId "%s"', waterplane.uniqueId)
    end
end

---@param uniqueId string
---@param noEventSend? boolean
function LandscapingManager:deleteWaterplaneByUniqueId(uniqueId, noEventSend)
    local waterplane = self.waterplanes[uniqueId]

    if waterplane ~= nil then
        WaterplaneDeleteEvent.sendEvent(waterplane, noEventSend)

        self.waterplanes[uniqueId] = nil

        local groupNode = self.waterplaneGroupNodes[uniqueId]
        LandscapingUtils.deleteWaterplaneShapes(groupNode)
        delete(groupNode)
        self.waterplaneGroupNodes[uniqueId] = nil

        g_messageCenter:publish(ModMessageType.WATERPLANE_DELETED, uniqueId)
    end
end

---@param uniqueId string
---@return LandscapingWaterplane?
---@nodiscard
function LandscapingManager:getWaterplaneByUniqueId(uniqueId)
    return self.waterplanes[uniqueId]
end

---@param uniqueId string
---@param visible boolean
---@param noEventSend? boolean
function LandscapingManager:setWaterplaneVisible(uniqueId, visible, noEventSend)
    local waterplane = self.waterplanes[uniqueId]
    local groupNode = self.waterplaneGroupNodes[uniqueId]

    if waterplane ~= nil and groupNode ~= nil then
        WaterplaneSetVisibleEvent.sendEvent(waterplane, visible, noEventSend)

        waterplane.visible = visible
        setVisibility(groupNode, visible)

        g_messageCenter:publish(ModMessageType.WATERPLANE_UPDATED, waterplane)
    end
end

---@param waterplane LandscapingWaterplane
function LandscapingManager:updateWaterplaneShapes(waterplane)
    local uniqueId = waterplane.uniqueId
    local groupNode = self.waterplaneGroupNodes[uniqueId]

    if groupNode == nil then
        Logging.error('LandscapingManager:updateWaterplaneShapes() Could not find rootNode for unqiueId "%s"', tostring(waterplane.uniqueId))
        return
    end

    LandscapingUtils.deleteWaterplaneShapes(groupNode)

    if #waterplane.points > 2 then
        local vertices = waterplane:getVertices()
        LandscapingUtils.createWaterplaneShapesFromVertices(groupNode, vertices, waterplane.color)
    end
end

---@diagnostic disable-next-line: lowercase-global
g_landscapingManager = LandscapingManager.new()
g_landscapingManager:loadShapes()
