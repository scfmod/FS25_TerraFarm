---@class MachineWorkArea
---@field vehicle Machine
---@field machineType MachineType
---@field referenceNode number
---@field rootNode number
---@field width number
---@field offset number[]
---@field rotation number[]
---
---@field areaNodes number[]
---@field areaNodeActive table<number, boolean>
---@field areaNodePosition table<number, number[]>
---@field areaNodeTerrainY table<number, number>
---@field isAreaNodeActive boolean
---
---@field outputNode number?
---@field outputNodeActive boolean
---@field outputNodePosition number[]
---@field outputNodeTerrainY number
---@field outputOffset number[]
---
---@field density number
---@field raycastHitTerrain boolean
---@field raycastDistance number
MachineWorkArea = {}

local MachineWorkArea_mt = Class(MachineWorkArea)

---@param schema XMLSchema
---@param key string
function MachineWorkArea.registerXMLPaths(schema, key)
    schema:register(XMLValueType.NODE_INDEX, key .. '#referenceNode')
    schema:register(XMLValueType.FLOAT, key .. '#raycastDistance')
    schema:register(XMLValueType.FLOAT, key .. '#width')
    schema:register(XMLValueType.FLOAT, key .. '#density', 'Node density', 0.75)
    schema:register(XMLValueType.VECTOR_3, key .. '#offset', 'Offset position from reference node', '0 0 0')
    schema:register(XMLValueType.VECTOR_ROT, key .. '#rotation', 'Rotation in degrees', '0 0 0')
    schema:register(XMLValueType.VECTOR_3, key .. '#outputOffset', 'Output node offset position from center of area', '0 0 0', false)
end

---@param vehicle Machine
---@return MachineWorkArea
---@nodiscard
function MachineWorkArea.new(vehicle)
    ---@type MachineWorkArea
    local self = setmetatable({}, MachineWorkArea_mt)

    self.vehicle = vehicle
    self.machineType = vehicle.spec_machine.machineType
    self.isAreaNodeActive = false
    self.density = 0.5

    self.areaNodes = {}
    self.areaNodeActive = {}
    self.areaNodePosition = {}
    self.areaNodeTerrainY = {}

    self.outputNode = nil
    self.outputNodeActive = false
    self.outputNodePosition = { 0, 0, 0 }
    self.outputNodeTerrainY = 0

    self.raycastHitTerrain = false
    self.raycastDistance = 0.5

    return self
end

---@param xmlFile XMLFile
---@param key string
function MachineWorkArea:loadFromXMLFile(xmlFile, key)
    self.referenceNode = xmlFile:getValue(key .. '#referenceNode', nil, self.vehicle.components, self.vehicle.i3dMappings)

    self.width = xmlFile:getValue(key .. '#width')

    if self.width ~= nil then
        self.width = math.clamp(self.width, 0.1, 16)
    end

    self.density = math.clamp(xmlFile:getValue(key .. '#density', self.density), 0.25, 4)
    self.offset = xmlFile:getValue(key .. '#offset', '0 0 0', true)
    self.rotation = xmlFile:getValue(key .. '#rotation', '0 0 0', true)
    self.outputOffset = xmlFile:getValue(key .. '#outputOffset', '0 0 0', true)
    self.raycastDistance = xmlFile:getValue(key .. '#raycastDistance', self.raycastDistance)
end

function MachineWorkArea:createOutputNode()
    self.outputNode = createTransformGroup('output_node')

    link(self.rootNode, self.outputNode)
    setTranslation(self.outputNode, self.outputOffset[1], self.outputOffset[2], self.outputOffset[3])
end

function MachineWorkArea:createAreaNodes()
    local halfWidth = self.width / 2
    local z = 0

    if self.width < 0.5 then
        self:addAreaNode(0, 0, z)
    elseif self.width < 0.8 then
        self:addAreaNode(-halfWidth, 0, z)
        self:addAreaNode(halfWidth, 0, z)
    elseif self.width < 1.5 then
        self:addAreaNode(-halfWidth, 0, z)
        self:addAreaNode(0, 0, z)
        self:addAreaNode(halfWidth, 0, z)
    else
        local numOfNodes = MathUtil.round(self.width / self.density)
        local distance = self.width / numOfNodes

        for i = 0, numOfNodes do
            local x = -halfWidth + (i * distance)

            self:addAreaNode(x, 0, z)
        end
    end
end

---@return boolean
---@nodiscard
function MachineWorkArea:initialize()
    if self.rootNode ~= nil then
        Logging.error('MachineWorkArea:initialize() workArea is already initialized!')
        return false
    end

    local spec = self.vehicle.spec_machine

    if self.referenceNode == nil and self.machineType.useShovel and spec.hasShovel then
        local shovelNode = spec.shovelNode

        if shovelNode ~= nil then
            self.referenceNode = shovelNode.node

            self.offset[2] = self.offset[2] + shovelNode.yOffset
            self.offset[3] = self.offset[3] + shovelNode.zOffset

            if self.width == nil then
                self.width = shovelNode.width
            end
        end
    end

    if self.referenceNode == nil and self.machineType.useLeveler and spec.hasLeveler then
        local levelerNode = spec.levelerNode

        if levelerNode ~= nil then
            self.referenceNode = levelerNode.node

            self.offset[2] = self.offset[2] + levelerNode.yOffset
            self.offset[3] = self.offset[3] + levelerNode.zOffset

            if self.width == nil then
                self.width = levelerNode.width
            end
        end
    end

    if self.referenceNode == nil and self.machineType.useDischargeable and spec.hasDischargeable then
        local dischargeNode = spec.dischargeNode

        if dischargeNode ~= nil then
            self.referenceNode = dischargeNode.node

            -- self.offset[2] = self.offset[2] + dischargeNode.info.yOffset
            -- self.offset[3] = self.offset[3] + dischargeNode.info.zOffset

            if self.width == nil then
                self.width = dischargeNode.info.width
            end
        end
    end

    if self.referenceNode == nil then
        Logging.error('MachineWorkArea:initialize() No referenceNode found ...')
        return false
    end

    self.rootNode = createTransformGroup('root')

    link(self.referenceNode, self.rootNode)
    setTranslation(self.rootNode, self.offset[1], self.offset[2], self.offset[3])
    setRotation(self.rootNode, self.rotation[1], self.rotation[2], self.rotation[3])

    self:createAreaNodes()

    if MachineUtils.getHasOutputs(self.vehicle) then
        self:createOutputNode()
    end

    return true
end

---@param x number
---@param y number
---@param z number
function MachineWorkArea:addAreaNode(x, y, z)
    local node = createTransformGroup('node')

    link(self.rootNode, node)
    setTranslation(node, x, y, z)

    table.insert(self.areaNodes, node)

    self.areaNodePosition[node] = { 0, 0, 0 }
    self.areaNodeTerrainY[node] = 0
    self.areaNodeActive[node] = false
end

function MachineWorkArea:update()
    self.isAreaNodeActive = false

    if self.outputNode ~= nil then
        self.outputNodePosition[1], self.outputNodePosition[2], self.outputNodePosition[3] = getWorldTranslation(self.outputNode)
        self.outputNodeTerrainY = getTerrainHeightAtWorldPos(g_terrainNode, self.outputNodePosition[1], 0, self.outputNodePosition[3])
        self.outputNodeActive = self.outputNodeTerrainY >= self.outputNodePosition[2]
    end

    for _, node in ipairs(self.areaNodes) do
        local position = self.areaNodePosition[node]

        position[1], position[2], position[3] = getWorldTranslation(node)

        self.areaNodeTerrainY[node] = getTerrainHeightAtWorldPos(g_terrainNode, position[1], 0, position[3])
        self.areaNodeActive[node] = self.areaNodeTerrainY[node] >= position[2]

        if self.areaNodeActive[node] then
            self.isAreaNodeActive = true
        end
    end
end

---@param mode MachineMode
function MachineWorkArea:input(mode)
    local area = self.vehicle:getMachineLandscapingArea()

    if mode == Machine.MODE.FLATTEN then
        return self:flatten(area)
    end

    local terrainLayerId, fillTypeIndex

    if area ~= nil then
        local state = self.vehicle:getMachineState()
        local x, y, z = self:getPosition()
        local isInsideArea = area:getIsInsideArea(x, y, z)

        if not state.ignoreAreaGroundTextures and isInsideArea or not area.restrictArea then
            terrainLayerId = area.forceInputLayer
        end

        if not state.ignoreAreaMaterial and isInsideArea or not area.restrictArea then
            fillTypeIndex = area.forceFillTypeIndex
        end
    end

    if mode == Machine.MODE.PAINT then
        local op = LandscapingInputPaint.new(self, terrainLayerId)
        op:apply()
    elseif mode == Machine.MODE.LOWER then
        local op = LandscapingInputLower.new(self, terrainLayerId, fillTypeIndex)
        op:apply()
    elseif mode == Machine.MODE.SMOOTH then
        local op = LandscapingInputSmooth.new(self, terrainLayerId, fillTypeIndex)
        op:apply()
    end
end

---@param mode MachineMode
---@param liters number
---@param fillTypeIndex number
---@return number litersDropped
---@nodiscard
function MachineWorkArea:output(mode, liters, fillTypeIndex)
    local area = self.vehicle:getMachineLandscapingArea()
    local terrainLayerId

    if mode == Machine.MODE.FLATTEN then
        return self:flattenDischarge(area, fillTypeIndex, liters)
    end

    if area ~= nil then
        local state = self.vehicle:getMachineState()
        local x, y, z = self:getPosition()
        local isInsideArea = area:getIsInsideArea(x, y, z)

        if not state.ignoreAreaGroundTextures and isInsideArea or not area.restrictArea then
            terrainLayerId = area.forceOutputLayer
        end
    end

    if mode == Machine.MODE.PAINT then
        local op = LandscapingOutputPaint.new(self, terrainLayerId)
        op:apply()
        return op.outputLiters
    elseif mode == Machine.MODE.RAISE then
        local op = LandscapingOutputRaise.new(self, terrainLayerId, fillTypeIndex, liters)
        op:apply()
        return op.outputLiters
    elseif mode == Machine.MODE.SMOOTH then
        local op = LandscapingOutputSmooth.new(self, terrainLayerId, fillTypeIndex, liters)
        op:apply()
        return op.outputLiters
    end

    return 0
end

---@param area? LandscapingArea
function MachineWorkArea:flatten(area)
    if area ~= nil then
        local x, y, z = self:getPosition()
        local valid, targetY, minY, maxY, nx, ny, nz, direction = area:getDeformationParams(x, y, z)

        if valid then
            local terrainLayerId, fillTypeIndex
            local state = self.vehicle:getMachineState()

            if not state.ignoreAreaGroundTextures then
                terrainLayerId = area.forceInputLayer
            end

            if not state.ignoreAreaMaterial then
                fillTypeIndex = area.forceFillTypeIndex
            end

            if minY == maxY then
                local op = LandscapingInputFlatten.new(self, terrainLayerId, fillTypeIndex, targetY)
                op:apply()
            else
                local op = LandscapingInputSlope.new(self, terrainLayerId, fillTypeIndex, minY, maxY, nx, ny, nz, direction, targetY)
                op:apply()
            end
        end
    else
        local targetWorldPosY = MachineUtils.getVehicleTargetHeight(self.vehicle)
        local op = LandscapingInputFlatten.new(self, nil, nil, targetWorldPosY)

        op:apply()
    end
end

---@return number
---@nodiscard
function MachineWorkArea:getOutputTargetHeight()
    local area = self.vehicle:getMachineLandscapingArea()

    if area ~= nil then
        local x, y, z = self:getOutputPosition()
        local valid, targetY, minY, maxY, nx, ny, nz, direction = area:getDeformationParams(x, y, z)

        if valid then
            return targetY
        end
    end

    return MachineUtils.getVehicleTargetHeight(self.vehicle)
end

---@param area? LandscapingArea
---@param litersToDrop number
---@param fillTypeIndex number
---@return number
---@nodiscard
function MachineWorkArea:flattenDischarge(area, fillTypeIndex, litersToDrop)
    if area ~= nil then
        local x, y, z = self:getOutputPosition()
        local valid, targetY, minY, maxY, nx, ny, nz, direction = area:getDeformationParams(x, y, z)

        if valid then
            local terrainLayerId

            local state = self.vehicle:getMachineState()

            if not state.ignoreAreaGroundTextures then
                terrainLayerId = area.forceOutputLayer
            end

            if minY == maxY then
                local op = LandscapingOutputFlatten.new(self, terrainLayerId, fillTypeIndex, litersToDrop, targetY)
                op:apply()
                return op.outputLiters
            else
                local op = LandscapingOutputSlope.new(self, terrainLayerId, fillTypeIndex, litersToDrop, minY, maxY, nx, ny, nz, direction, targetY)
                op:apply()
                return op.outputLiters
            end
        end
    else
        local targetWorldPosY = MachineUtils.getVehicleTargetHeight(self.vehicle)
        local op = LandscapingOutputFlatten.new(self, nil, fillTypeIndex, litersToDrop, targetWorldPosY)

        op:apply()

        return op.outputLiters
    end

    return 0
end

---@return number worldPosX
---@return number worldPosY
---@return number worldPosZ
function MachineWorkArea:getPosition()
    return getWorldTranslation(self.rootNode)
end

---@return number rotationY
---@nodiscard
function MachineWorkArea:getRotationY()
    local _, rotY, _ = getWorldRotation(self.rootNode)

    return rotY
end

---@return number worldPosX
---@return number worldPosY
---@return number worldPosZ
function MachineWorkArea:getOutputPosition()
    if self.outputNode ~= nil then
        return getWorldTranslation(self.outputNode)
    end

    return getWorldTranslation(self.rootNode)
end

---@return boolean
---@nodiscard
function MachineWorkArea:getCanOutputToTerrain()
    if self.isAreaNodeActive or self.outputNodeActive then
        return false
    end

    local maxDistance = self.raycastDistance
    local collisionMask = CollisionFlag.TERRAIN + CollisionFlag.TERRAIN_DISPLACEMENT

    self.raycastHitTerrain = false

    if self.outputNode ~= nil then
        raycastClosest(self.outputNodePosition[1], self.outputNodePosition[2], self.outputNodePosition[3], 0, -1, 0, maxDistance, 'terrainRaycastCallback', self, collisionMask)

        if self.raycastHitTerrain then
            return false
        end
    end

    if #self.areaNodes > 0 then
        local nodePosX, nodePosY, nodePosZ = self:getPosition()

        raycastClosest(nodePosX, nodePosY, nodePosZ, 0, -1, 0, maxDistance, 'terrainRaycastCallback', self, collisionMask)

        if not self.raycastHitTerrain and #self.areaNodes > 2 then
            local firstPosX, firstPosY, firstPosZ = getWorldTranslation(self.areaNodes[1])

            raycastClosest(firstPosX, firstPosY, firstPosZ, 0, -1, 0, maxDistance, 'terrainRaycastCallback', self, collisionMask)

            if not self.raycastHitTerrain then
                local lastPosX, lastPosY, lastPosZ = getWorldTranslation(self.areaNodes[#self.areaNodes])

                raycastClosest(lastPosX, lastPosY, lastPosZ, 0, -1, 0, maxDistance, 'terrainRaycastCallback', self, collisionMask)
            end
        end
    end

    return self.raycastHitTerrain ~= true
end

function MachineWorkArea:terrainRaycastCallback(hitObjectId)
    if hitObjectId == g_terrainNode then
        self.raycastHitTerrain = true

        return false
    end

    return true
end
