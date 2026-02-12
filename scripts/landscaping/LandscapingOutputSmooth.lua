---@class LandscapingOutputSmooth : LandscapingOutput
---@field litersToDrop number
LandscapingOutputSmooth = {}

local LandscapingOutputSmooth_mt = Class(LandscapingOutputSmooth, LandscapingOutput)

---@param workArea MachineWorkArea
---@param litersToDrop number
---@param fillTypeIndex number
---@return LandscapingOutputSmooth
---@nodiscard
function LandscapingOutputSmooth.new(workArea, litersToDrop, fillTypeIndex)
    local self = LandscapingOutput.new(LandscapingOperation.SMOOTH, workArea, LandscapingOutputSmooth_mt)
    ---@cast self LandscapingOutputSmooth

    self.litersToDrop = litersToDrop
    self.fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
    self.heightChangeAmount = 0.75

    self:checkMapResources()

    return self
end

---@return TerrainDeformation
---@nodiscard
function LandscapingOutputSmooth:createTerrainDeformation()
    self.deformation = MachineUtils.createTerrainDeformation()

    self.deformation:setAdditiveHeightChangeAmount(self.heightChangeAmount)
    self.deformation:enableSmoothingMode()

    return self.deformation
end
