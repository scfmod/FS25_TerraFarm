---@class LandscapingInputSmooth : LandscapingInput
LandscapingInputSmooth = {}

local LandscapingInputSmooth_mt = Class(LandscapingInputSmooth, LandscapingInput)

---@param workArea MachineWorkArea
---@return LandscapingInputSmooth
---@nodiscard
function LandscapingInputSmooth.new(workArea)
    local self = LandscapingInput.new(LandscapingOperation.SMOOTH, workArea, LandscapingInputSmooth_mt)
    ---@cast self LandscapingInputSmooth

    self.heightChangeAmount = 0.05

    self:checkMapResources()

    return self
end

function LandscapingInputSmooth:createTerrainDeformation()
    self.deformation = TerrainDeformation.new(g_terrainNode)

    self.deformation:setAdditiveHeightChangeAmount(self.heightChangeAmount)
    self.deformation:enableSmoothingMode()

    return self.deformation
end
