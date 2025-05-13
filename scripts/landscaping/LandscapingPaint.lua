---@class LandscapingPaint : MachineLandscaping
LandscapingPaint = {}

local LandscapingPaint_mt = Class(LandscapingPaint, MachineLandscaping)

---@param workArea MachineWorkArea
---@param customMt table | nil
---@return LandscapingPaint
---@nodiscard
function LandscapingPaint.new(workArea, customMt)
    ---@type LandscapingPaint
    ---@diagnostic disable-next-line: assign-type-mismatch
    local self = MachineLandscaping.new(LandscapingOperation.PAINT, workArea, customMt or LandscapingPaint_mt)

    self.strength = 0.5
    self.hardness = 0.2

    return self
end

function LandscapingPaint:apply()
    local deformation = self:createTerrainDeformation()
    local densityRadius = self.radius * self.state.densityModifier
    local paintRadius = self.radius * self.state.paintModifier

    if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        for node, position in pairs(self.workArea.nodePosition) do
            if self.workArea.nodeActive[node] then
                deformation:addSoftCircleBrush(position[1], position[3], paintRadius, self.hardness, self.strength, self.terrainLayerId)
                MachineUtils.addModifiedCircleArea(self.modifiedAreas, position[1], position[3], paintRadius)
                MachineUtils.addModifiedCircleArea(self.densityModifiedAreas, position[1], position[3], densityRadius)
            end
        end
    else
        for node, position in pairs(self.workArea.nodePosition) do
            if self.workArea.nodeActive[node] then
                deformation:addSoftSquareBrush(position[1], position[3], paintRadius * 2, self.hardness, self.strength, self.terrainLayerId)
                MachineUtils.addModifiedSquareArea(self.modifiedAreas, position[1], position[3], paintRadius * 2)
                MachineUtils.addModifiedSquareArea(self.densityModifiedAreas, position[1], position[3], densityRadius * 2)
            end
        end
    end

    if #self.modifiedAreas == 0 then
        deformation:cancel()
        return
    end

    deformation:apply(false, 'onDeformationCallback', self)
end

---@return TerrainDeformation
---@nodiscard
function LandscapingPaint:createTerrainDeformation()
    self.deformation = MachineUtils.createTerrainDeformation()

    self.deformation:enablePaintingMode()

    return self.deformation
end

---@param volume number
function LandscapingPaint:onDeformationSuccess(volume)
    self:applyDeformationChanges()
end

function LandscapingPaint:applyDeformationChanges()
    for _, area in ipairs(self.densityModifiedAreas) do
        local x, z, x1, z1, x2, z2 = unpack(area)

        if self.state.removeFieldArea then
            FSDensityMapUtil.removeFieldArea(x, z, x1, z1, x2, z2, false)
        end

        if self.state.removeWeedArea then
            FSDensityMapUtil.removeWeedArea(x, z, x1, z1, x2, z2)
        end

        if self.state.removeStoneArea then
            FSDensityMapUtil.removeStoneArea(x, z, x1, z1, x2, z2)
        end

        if self.state.clearDensityMapHeightArea then
            DensityMapHeightUtil.clearArea(x, z, x1, z1, x2, z2)
        end

        if self.state.clearDecoArea then
            FSDensityMapUtil.clearDecoArea(x, z, x1, z1, x2, z2)
        end
    end

    if self.state.eraseTireTracks then
        for _, area in ipairs(self.modifiedAreas) do
            local x, z, x1, z1, x2, z2 = unpack(area)

            FSDensityMapUtil.eraseTireTrack(x, z, x1, z1, x2, z2)
        end
    end
end
