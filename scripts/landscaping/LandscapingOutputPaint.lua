---@class LandscapingOutputPaint : LandscapingOutput
LandscapingOutputPaint = {}

local LandscapingOutputPaint_mt = Class(LandscapingOutputPaint, LandscapingOutput)

---@param workArea MachineWorkArea
---@return LandscapingOutputPaint
---@nodiscard
function LandscapingOutputPaint.new(workArea)
    local self = LandscapingOutput.new(LandscapingOperation.PAINT, workArea, LandscapingOutputPaint_mt)
    ---@cast self LandscapingOutputPaint

    self.createTerrainDeformation = LandscapingInputPaint.createTerrainDeformation
    self.applyDeformationChanges = LandscapingInputPaint.applyDeformationChanges

    return self
end

function LandscapingOutputPaint:applyMapResources()
    -- void
end

function LandscapingOutputPaint:apply()
    if self.workArea.outputNode == nil or not self.workArea.outputNodeActive then
        return
    end

    local deformation = self:createTerrainDeformation()
    local densityRadius = self.radius * self.state.densityModifier
    local paintRadius = self.radius * self.state.paintModifier
    local position = self.workArea.outputNodePosition

    if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        deformation:addSoftCircleBrush(position[1], position[3], paintRadius, self.hardness, self.strength, self.terrainLayerId)
        MachineUtils.addModifiedCircleArea(self.modifiedAreas, position[1], position[3], paintRadius)
        MachineUtils.addModifiedCircleArea(self.densityModifiedAreas, position[1], position[3], densityRadius)
    else
        deformation:addSoftSquareBrush(position[1], position[3], paintRadius * 2, self.hardness, self.strength, self.terrainLayerId)
        MachineUtils.addModifiedSquareArea(self.modifiedAreas, position[1], position[3], paintRadius * 2)
        MachineUtils.addModifiedSquareArea(self.densityModifiedAreas, position[1], position[3], densityRadius * 2)
    end

    deformation:apply(false, 'onDeformationCallback', self)
end

---@param area number
function LandscapingOutputPaint:onDeformationSuccess(area)
    self:applyDeformationChanges()

    self.outputLiters = area
end
