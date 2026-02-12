---@class LandscapingInputPaint : LandscapingInput
LandscapingInputPaint = {}

local LandscapingInputPaint_mt = Class(LandscapingInputPaint, LandscapingInput)

---@param workArea MachineWorkArea
---@return LandscapingInputPaint
---@nodiscard
function LandscapingInputPaint.new(workArea)
    local self = LandscapingInput.new(LandscapingOperation.PAINT, workArea, LandscapingInputPaint_mt)
    ---@cast self LandscapingInputPaint

    self.strength = 0.5
    self.hardness = 0.2

    return self
end

function LandscapingInputPaint:apply()
    local deformation = self:createTerrainDeformation()
    local densityRadius = self.radius * self.state.densityModifier
    local paintRadius = self.radius * self.state.paintModifier

    if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        for node, position in pairs(self.workArea.areaNodePosition) do
            if self.workArea.areaNodeActive[node] then
                deformation:addSoftCircleBrush(position[1], position[3], paintRadius, self.hardness, self.strength, self.terrainLayerId)
                MachineUtils.addModifiedCircleArea(self.modifiedAreas, position[1], position[3], paintRadius)
                MachineUtils.addModifiedCircleArea(self.densityModifiedAreas, position[1], position[3], densityRadius)
            end
        end
    else
        for node, position in pairs(self.workArea.areaNodePosition) do
            if self.workArea.areaNodeActive[node] then
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
function LandscapingInputPaint:createTerrainDeformation()
    self.deformation = MachineUtils.createTerrainDeformation()

    self.deformation:enablePaintingMode()

    return self.deformation
end

---@param volume number
function LandscapingInputPaint:onDeformationSuccess(volume)
    self:applyDeformationChanges()
end

function LandscapingInputPaint:applyDeformationChanges()
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
