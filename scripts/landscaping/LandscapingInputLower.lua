---@class LandscapingInputLower : LandscapingInput
LandscapingInputLower = {}

local LandscapingInputLower_mt = Class(LandscapingInputLower, LandscapingInput)

---@param workArea MachineWorkArea
---@param terrainLayerId? number
---@param fillTypeIndex? number
---@return LandscapingInputLower
---@nodiscard
function LandscapingInputLower.new(workArea, terrainLayerId, fillTypeIndex)
    local self = LandscapingInput.new(LandscapingOperation.LOWER, workArea, terrainLayerId, fillTypeIndex, LandscapingInputLower_mt)
    ---@cast self LandscapingInputLower

    self.heightChangeAmount = 0.05

    self:checkMapResources()

    return self
end

function LandscapingInputLower:createTerrainDeformation()
    self.deformation = TerrainDeformation.new(g_terrainNode)

    self.deformation:enableAdditiveDeformationMode()
    self.deformation:setAdditiveHeightChangeAmount(-self.heightChangeAmount)

    return self.deformation
end
