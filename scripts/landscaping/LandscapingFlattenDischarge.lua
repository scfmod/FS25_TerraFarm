---@class LandscapingFlattenDischarge : LandscapingFlatten
---@field droppedLiters number
---@field litersToDrop number
LandscapingFlattenDischarge = {}

local LandscapingFlattenDischarge_mt = Class(LandscapingFlattenDischarge, LandscapingFlatten)

---@param workArea MachineWorkArea
---@param targetY number
---@param litersToDrop number
---@param fillTypeIndex number
---@return LandscapingFlattenDischarge
---@nodiscard
function LandscapingFlattenDischarge.new(workArea, targetY, litersToDrop, fillTypeIndex)
    ---@type LandscapingFlattenDischarge
    ---@diagnostic disable-next-line: assign-type-mismatch
    local self = LandscapingFlatten.new(workArea, targetY, LandscapingFlattenDischarge_mt)

    self.droppedLiters = 0
    self.litersToDrop = litersToDrop
    self.fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
    self.terrainLayerId = self.vehicle.spec_machine.dischargeTerrainLayerId or 0

    self.heightChangeAmount = 0.75

    self.strength = 0.25
    self.radius = math.max(2, math.min(self.radius, 6))
    self.hardness = 0.2

    local minValidValue = g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex)

    self.strength = math.max(0.1, math.min(1, (litersToDrop / minValidValue) * self.strength))
    self.heightChangeAmount = self.heightChangeAmount * self.strength * (workArea.width / 4)

    self:verifyAndApplyMapResources()

    return self
end

function LandscapingFlattenDischarge:apply()
    local deformation = self:createTerrainDeformation()
    local paintDeformation = self:createPaintDeformation()

    local densityRadius = self.radius * self.state.densityModifier
    local paintRadius = self.radius * self.state.paintModifier

    if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        for node, position in pairs(self.workArea.nodePosition) do
            if self.workArea.nodeTerrainY[node] < self.targetY then
                deformation:addSoftCircleBrush(position[1], position[3], self.radius, self.hardness, self.strength, -1)
                MachineUtils.addModifiedCircleArea(self.modifiedAreas, position[1], position[3], self.radius)
            end

            MachineUtils.addModifiedCircleArea(self.densityModifiedAreas, position[1], position[3], densityRadius)

            if paintDeformation ~= nil then
                paintDeformation:addSoftCircleBrush(position[1], position[3], paintRadius, 0.2, 0.5, self.terrainLayerId)
            end
        end
    else
        for node, position in pairs(self.workArea.nodePosition) do
            if self.workArea.nodeTerrainY[node] < self.targetY then
                deformation:addSoftSquareBrush(position[1], position[3], self.radius * 2, self.hardness, self.strength, -1)
                MachineUtils.addModifiedSquareArea(self.modifiedAreas, position[1], position[3], self.radius * 2)
            end

            MachineUtils.addModifiedSquareArea(self.densityModifiedAreas, position[1], position[3], densityRadius * 2)

            if paintDeformation ~= nil then
                paintDeformation:addSoftSquareBrush(position[1], position[3], paintRadius * 2, 0.2, 0.5, self.terrainLayerId)
            end
        end
    end

    if #self.modifiedAreas == 0 then
        deformation:delete()
        return
    end

    deformation:setOutsideAreaConstraints(0, math.rad(65), math.rad(65))
    deformation:setBlockedAreaMaxDisplacement(0)
    deformation:setDynamicObjectCollisionMask(0)
    deformation:setDynamicObjectMaxDisplacement(0)

    deformation:apply(false, 'onDeformationCallback', self)
end

function LandscapingFlattenDischarge:verifyAndApplyMapResources()
    if g_resourceManager:getIsActive() and self.vehicle.spec_machine.resourcesEnabled then
        local worldPosX, _, worldPosZ = getWorldTranslation(self.workArea.rootNode)
        local layer = g_resourceManager:getResourceLayerAtWorldPos(worldPosX, worldPosZ)

        if layer ~= nil then
            self.terrainLayerId = g_resourceManager:getResourcePaintLayerId(layer, true)
        end
    end
end

---@param volume number
function LandscapingFlattenDischarge:onDeformationSuccess(volume)
    if volume > 0 and self.fillType ~= nil then
        self:applyDeformationChanges()

        self.droppedLiters = MachineUtils.volumeToFillTypeLiters(volume, self.fillType.index)
    end
end
