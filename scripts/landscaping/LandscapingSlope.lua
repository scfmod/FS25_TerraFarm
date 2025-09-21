---@class LandscapingSlope : MachineLandscaping
---@field minY number
---@field maxY number
---@field nx number
---@field ny number
---@field nz number
---@field d number
---@field targetY number
LandscapingSlope = {}

local LandscapingSlope_mt = Class(LandscapingSlope, MachineLandscaping)

---@param workArea MachineWorkArea
---@param minY number
---@param maxY number
---@param nx number
---@param ny number
---@param nz number
---@param d number
---@param targetY number
---@param customMt? table
function LandscapingSlope.new(workArea, minY, maxY, nx, ny, nz, d, targetY, customMt)
    local self = MachineLandscaping.new(LandscapingOperation.SLOPE, workArea, customMt or LandscapingSlope_mt)
    ---@cast self LandscapingSlope

    self.minY = minY
    self.maxY = maxY
    self.nx = nx
    self.ny = ny
    self.nz = nz
    self.d = d
    self.targetY = targetY

    self.heightChangeAmount = 0.75

    if self.vehicle.spec_machine.machineType.id == 'excavatorShovel' then
        self.heightChangeAmount = 2.0
    end

    self:verifyAndApplyMapResources()

    return self
end

function LandscapingSlope:apply()
    ---@diagnostic disable-next-line: param-type-mismatch
    LandscapingFlatten.apply(self)
end

function LandscapingSlope:onSculptingFinished()
    -- void
end

---@return TerrainDeformation
---@nodiscard
function LandscapingSlope:createTerrainDeformation()
    self.deformation = MachineUtils.createTerrainDeformation()

    self.deformation:setAdditiveHeightChangeAmount(self.heightChangeAmount)
    self.deformation:setHeightTarget(self.minY, self.maxY, self.nx, self.ny, self.nz, self.d)
    self.deformation:enableSetDeformationMode()

    return self.deformation
end

---@param volume number
function LandscapingSlope:onDeformationSuccess(volume)
    ---@diagnostic disable-next-line: param-type-mismatch
    LandscapingFlatten.onDeformationSuccess(self, volume)
end
