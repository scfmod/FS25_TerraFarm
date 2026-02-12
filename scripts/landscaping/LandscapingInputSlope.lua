---@class LandscapingInputSlope : LandscapingInput
---@field minY number
---@field maxY number
---@field nx number
---@field ny number
---@field nz number
---@field d number
---@field targetY number
LandscapingInputSlope = {}

local LandscapingInputSlope_mt = Class(LandscapingInputSlope, LandscapingInput)

---@param workArea MachineWorkArea
---@param minY number
---@param maxY number
---@param nx number
---@param ny number
---@param nz number
---@param d number
---@param targetY number
---@return LandscapingInputSlope
---@nodiscard
function LandscapingInputSlope.new(workArea, minY, maxY, nx, ny, nz, d, targetY)
    local self = LandscapingInput.new(LandscapingOperation.SLOPE, workArea, LandscapingInputSlope_mt)
    ---@cast self LandscapingInputSlope

    self.minY = minY
    self.maxY = maxY
    self.nx = nx
    self.ny = ny
    self.nz = nz
    self.d = d
    self.targetY = targetY

    self.heightChangeAmount = 0.75

    self:checkMapResources()

    self.apply = LandscapingInputFlatten.apply

    return self
end

---@return TerrainDeformation
---@nodiscard
function LandscapingInputSlope:createTerrainDeformation()
    self.deformation = TerrainDeformation.new(g_terrainNode)

    self.deformation:setAdditiveHeightChangeAmount(self.heightChangeAmount)
    self.deformation:setHeightTarget(self.minY, self.maxY, self.nx, self.ny, self.nz, self.d)
    self.deformation:enableSetDeformationMode()

    return self.deformation
end
