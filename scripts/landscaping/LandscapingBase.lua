---@class LandscapingBase
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
---@field fillType FillTypeObject?
---@field yield number
LandscapingBase = {}

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

---@param operation LandscapingOperation
---@param workArea MachineWorkArea
---@param fillTypeIndex? number
---@param customMt table
---@return LandscapingBase
function LandscapingBase.new(operation, workArea, fillTypeIndex, customMt)
    ---@type LandscapingBase
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
    self.fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex or self.vehicle:getMachineFillTypeIndex())
    self.yield = 1

    return self
end

function LandscapingBase:checkMapResources()
    if g_resourceManager:getIsActive() and self.vehicle.spec_machine.resourcesEnabled then
        self:applyMapResources()
    end
end

---@param code number
---@param volume number
function LandscapingBase:onDeformationCallback(code, volume)
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

function LandscapingBase:applyDeformationChanges()
    local state = self.state
    local densityAreas = self.densityModifiedAreas
    local modifiedAreas = self.modifiedAreas

    local removeFieldArea = state.removeFieldArea
    local removeWeedArea = state.removeWeedArea
    local removeStoneArea = state.removeStoneArea
    local clearDensityMapHeightArea = state.clearDensityMapHeightArea
    local clearDecoArea = state.clearDecoArea

    local aiSystem = g_currentMission.aiSystem

    for i = 1, #densityAreas do
        local area = densityAreas[i]

        local x    = area[1]
        local z    = area[2]
        local x1   = area[3]
        local z1   = area[4]
        local x2   = area[5]
        local z2   = area[6]

        if removeFieldArea then
            FSDensityMapUtil.removeFieldArea(x, z, x1, z1, x2, z2, false)
        end
        if removeWeedArea then
            FSDensityMapUtil.removeWeedArea(x, z, x1, z1, x2, z2)
        end
        if removeStoneArea then
            FSDensityMapUtil.removeStoneArea(x, z, x1, z1, x2, z2)
        end
        if clearDensityMapHeightArea then
            DensityMapHeightUtil.clearArea(x, z, x1, z1, x2, z2)
        end
        if clearDecoArea then
            FSDensityMapUtil.clearDecoArea(x, z, x1, z1, x2, z2)
        end
    end

    for i = 1, #modifiedAreas do
        local area = modifiedAreas[i]

        local x    = area[1]
        local z    = area[2]
        local x1   = area[3]
        local z1   = area[4]
        local x2   = area[5]
        local z2   = area[6]

        local xx   = x2 + x1 - x
        local zz   = z2 + z1 - z

        local minX = x
        minX       = (x1 < minX) and x1 or minX
        minX       = (x2 < minX) and x2 or minX
        minX       = (xx < minX) and xx or minX

        local maxX = x
        maxX       = (x1 > maxX) and x1 or maxX
        maxX       = (x2 > maxX) and x2 or maxX
        maxX       = (xx > maxX) and xx or maxX

        local minZ = z
        minZ       = (z1 < minZ) and z1 or minZ
        minZ       = (z2 < minZ) and z2 or minZ
        minZ       = (zz < minZ) and zz or minZ

        local maxZ = z
        maxZ       = (z1 > maxZ) and z1 or maxZ
        maxZ       = (z2 > maxZ) and z2 or maxZ
        maxZ       = (zz > maxZ) and zz or maxZ

        aiSystem:setAreaDirty(minX, maxX, minZ, maxZ)
    end

    local paint = self.paintDeformation

    if paint ~= nil then
        paint:apply(false, "onPaintDeformationCallback", self)
    end
end

function LandscapingBase:onPaintDeformationCallback(code, volume)
    -- void
end

---@return TerrainDeformation?
---@nodiscard
function LandscapingBase:createPaintDeformation()
    assert(false, 'LandscapingBase:createPaintDeformation() must be handled by inherited class!')
end

---@param volume number
function LandscapingBase:onDeformationSuccess(volume)
    assert(false, 'LandscapingBase:onDeformationSuccess() must be handled by inherited class!')
end

---@return TerrainDeformation
---@nodiscard
function LandscapingBase:createTerrainDeformation()
    ---@diagnostic disable-next-line: missing-return
    assert(false, 'LandscapingBase:createTerrainDeformation() must be handled by inherited class!')
end

function LandscapingBase:applyMapResources()
    assert(false, 'LandscapingBase:applyMapResources() must be handled by inherited class!')
end

function LandscapingBase:apply()
    assert(false, 'LandscapingBase:apply() must be handled by inherited class!')
end
