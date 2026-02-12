---@class LandscapingOutputRaise : LandscapingOutput
---@field litersToDrop number
LandscapingOutputRaise = {}

local LandscapingOutputRaise_mt = Class(LandscapingOutputRaise, LandscapingOutput)

---@param workArea MachineWorkArea
---@param litersToDrop number
---@param fillTypeIndex number
---@return LandscapingOutputRaise
---@nodiscard
function LandscapingOutputRaise.new(workArea, litersToDrop, fillTypeIndex)
    local self = LandscapingOutput.new(LandscapingOperation.RAISE, workArea, LandscapingOutputRaise_mt)
    ---@cast self LandscapingOutputRaise

    self.litersToDrop = litersToDrop
    self.fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
    self.heightChangeAmount = 0.015

    self:checkMapResources()

    return self
end

---@return TerrainDeformation
---@nodiscard
function LandscapingOutputRaise:createTerrainDeformation()
    self.deformation = MachineUtils.createTerrainDeformation()

    self.deformation:enableAdditiveDeformationMode()
    self.deformation:setAdditiveHeightChangeAmount(self.heightChangeAmount)

    return self.deformation
end
