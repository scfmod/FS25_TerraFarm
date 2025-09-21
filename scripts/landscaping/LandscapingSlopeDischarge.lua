---@class LandscapingSlopeDischarge : LandscapingSlope
---@field droppedLiters number
---@field litersToDrop number
LandscapingSlopeDischarge = {}

LandscapingSlopeDischarge.NODE_TARGET_Y_OFFSET = -0.05

local LandscapingSlopeDischarge_mt = Class(LandscapingSlopeDischarge, LandscapingSlope)

---@param workArea MachineWorkArea
---@param minY number
---@param maxY number
---@param nx number
---@param ny number
---@param nz number
---@param d number
---@param targetY number
---@param litersToDrop number
---@param fillTypeIndex number
---@return LandscapingSlopeDischarge
---@nodiscard
function LandscapingSlopeDischarge.new(workArea, minY, maxY, nx, ny, nz, d, targetY, litersToDrop, fillTypeIndex)
    local self = LandscapingSlope.new(workArea, minY, maxY, nx, ny, nz, d, targetY, LandscapingSlopeDischarge_mt)
    ---@cast self LandscapingSlopeDischarge

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

function LandscapingSlopeDischarge:apply()
    local deformation = self:createTerrainDeformation()
    local paintDeformation = self:createPaintDeformation()

    local densityRadius = self.radius * self.state.densityModifier
    local paintRadius = self.radius * self.state.paintModifier

    local targetY = self.targetY + LandscapingSlopeDischarge.NODE_TARGET_Y_OFFSET

    if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        for node, position in pairs(self.workArea.nodePosition) do
            if self.workArea.nodeTerrainY[node] < targetY then
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
            if self.workArea.nodeTerrainY[node] < targetY then
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

function LandscapingSlopeDischarge:verifyAndApplyMapResources()
    ---@diagnostic disable-next-line: param-type-mismatch
    LandscapingFlattenDischarge.verifyAndApplyMapResources(self)
end

---@param volume number
function LandscapingSlopeDischarge:onDeformationSuccess(volume)
    ---@diagnostic disable-next-line: param-type-mismatch
    LandscapingFlattenDischarge.onDeformationSuccess(self, volume)
end
