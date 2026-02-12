---@enum LandscapingOperation
LandscapingOperation = {
    LOWER = 1,
    RAISE = 2,
    SMOOTH = 3,
    FLATTEN = 4,
    SLOPE = 5,
    PAINT = 6
}

LANDSCAPING_OPERATION_TO_STRING = {
    [LandscapingOperation.FLATTEN] = 'FLATTEN',
    [LandscapingOperation.SLOPE] = 'SLOPE',
    [LandscapingOperation.SMOOTH] = 'SMOOTH',
    [LandscapingOperation.LOWER] = 'LOWER',
    [LandscapingOperation.RAISE] = 'RAISE',
}

---@class MachineLandscaping
---@field workArea MachineWorkArea
---@field vehicle Machine
---@field operation LandscapingOperation
---@field deformation TerrainDeformation
---@field paintDeformation TerrainDeformation
---@field state MachineState
---
---@field modifiedAreas table
---@field densityModifiedAreas table
---@field terrainUnit number
---@field halfTerrainUnit number
---
---@field radius number
---@field strength number
---@field hardness number
---@field terrainLayerId number
---@field brushShape number
---@field heightChangeAmount number
---@field fillType FillTypeObject | nil
---@field yield number
MachineLandscaping = {}

---@param operation LandscapingOperation
---@param workArea MachineWorkArea
---@param customMt table
---@return MachineLandscaping
function MachineLandscaping.new(operation, workArea, customMt)
    ---@type MachineLandscaping
    local self = setmetatable({}, customMt)

    self.operation = operation
    self.workArea = workArea
    self.vehicle = workArea.vehicle
    self.state = self.vehicle.spec_machine.state

    self.modifiedAreas = {}
    self.densityModifiedAreas = {}

    self.terrainUnit = getTerrainHeightmapUnitSize(g_terrainNode)
    self.halfTerrainUnit = self.terrainUnit / 2

    self.terrainLayerId = 0
    self.heightChangeAmount = 0.05
    self.brushShape = Landscaping.BRUSH_SHAPE.CIRCLE
    self.fillType = g_fillTypeManager:getFillTypeByIndex(self.vehicle.spec_machine.fillTypeIndex)
    self.yield = 1

    return self
end

function MachineLandscaping:checkMapResources()
    if g_resourceManager:getIsActive() and self.vehicle.spec_machine.resourcesEnabled then
        self:applyMapResources()
    end
end

---@param code number
---@param volume number
function MachineLandscaping:onDeformationCallback(code, volume)
    if code == TerrainDeformation.STATE_SUCCESS then
        self:onDeformationSuccess(volume)
    else
        self.deformation:cancel()

        if self.paintDeformation ~= nil then
            self.paintDeformation:cancel()
        end
    end

    self.deformation:delete()
    self.deformation = nil

    if self.paintDeformation ~= nil then
        self.paintDeformation:delete()
        self.paintDeformation = nil
    end
end

function MachineLandscaping:applyDeformationChanges()
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

    for _, area in ipairs(self.modifiedAreas) do
        local x, z, x1, z1, x2, z2 = unpack(area)

        if self.state.eraseTireTracks then
            FSDensityMapUtil.eraseTireTrack(x, z, x1, z1, x2, z2)
        end

        local minX = math.min(x, x1, x2, x2 + x1 - x)
        local maxX = math.max(x, x1, x2, x2 + x1 - x)
        local minZ = math.min(z, z1, z2, z2 + z1 - z)
        local maxZ = math.max(z, z1, z2, z2 + z1 - z)

        ---@diagnostic disable-next-line: undefined-field
        g_currentMission.aiSystem:setAreaDirty(minX, maxX, minZ, maxZ)
    end

    if self.paintDeformation ~= nil then
        self.paintDeformation:apply(false, 'onPaintDeformationCallback', self)
    end
end

function MachineLandscaping:onPaintDeformationCallback(code, volume)
    -- void
end

---@return TerrainDeformation?
---@nodiscard
function MachineLandscaping:createPaintDeformation()
    assert(false, 'MachineLandscaping:createPaintDeformation() must be handled by inherited class!')
end

---@param volume number
function MachineLandscaping:onDeformationSuccess(volume)
    assert(false, 'MachineLandscaping:onDeformationSuccess() must be handled by inherited class!')
end

---@return TerrainDeformation
---@nodiscard
function MachineLandscaping:createTerrainDeformation()
    ---@diagnostic disable-next-line: missing-return
    assert(false, 'MachineLandscaping:createTerrainDeformation() must be handled by inherited class!')
end

function MachineLandscaping:applyMapResources()
    assert(false, 'MachineLandscaping:applyMapResources() must be handled by inherited class!')
end

function MachineLandscaping:apply()
    assert(false, 'MachineLandscaping:apply() must be handled by inherited class!')
end
