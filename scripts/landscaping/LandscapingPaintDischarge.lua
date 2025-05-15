---@class LandscapingPaintDischarge : LandscapingPaint
---@field droppedLiters number
LandscapingPaintDischarge = {}

local LandscapingPaintDischarge_mt = Class(LandscapingPaintDischarge, LandscapingPaint)

function LandscapingPaintDischarge.new(workArea)
    ---@type LandscapingPaintDischarge
    ---@diagnostic disable-next-line: assign-type-mismatch
    local self = LandscapingPaint.new(workArea, LandscapingPaintDischarge_mt)

    self.droppedLiters = 0

    return self
end

function LandscapingPaintDischarge:apply()
    local deformation = self:createTerrainDeformation()
    local densityRadius = self.radius * self.state.densityModifier
    local paintRadius = self.radius * self.state.paintModifier

    if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        for _, position in pairs(self.workArea.nodePosition) do
            deformation:addSoftCircleBrush(position[1], position[3], paintRadius, self.hardness, self.strength, self.terrainLayerId)
            MachineUtils.addModifiedCircleArea(self.modifiedAreas, position[1], position[3], paintRadius)
            MachineUtils.addModifiedCircleArea(self.densityModifiedAreas, position[1], position[3], densityRadius)
        end
    else
        for _, position in pairs(self.workArea.nodePosition) do
            deformation:addSoftSquareBrush(position[1], position[3], paintRadius * 2, self.hardness, self.strength, self.terrainLayerId)
            MachineUtils.addModifiedSquareArea(self.modifiedAreas, position[1], position[3], paintRadius * 2)
            MachineUtils.addModifiedSquareArea(self.densityModifiedAreas, position[1], position[3], densityRadius * 2)
        end
    end

    if #self.modifiedAreas == 0 then
        deformation:delete()
        return
    end

    deformation:apply(false, 'onDeformationCallback', self)
end

function LandscapingPaintDischarge:verifyAndApplyMapResources()
    -- void
end

---@param area number
function LandscapingPaintDischarge:onDeformationSuccess(area)
    self:applyDeformationChanges()

    self.droppedLiters = area * g_modSettings.experimental_dischargePaintModifier
end
