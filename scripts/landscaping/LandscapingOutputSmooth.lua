---@class LandscapingOutputSmooth : LandscapingOutput
---@field litersToDrop number
LandscapingOutputSmooth = {}

local LandscapingOutputSmooth_mt = Class(LandscapingOutputSmooth, LandscapingOutput)

---@param workArea MachineWorkArea
---@param terrainLayerId? number
---@param fillTypeIndex number
---@param litersToDrop number
---@return LandscapingOutputSmooth
---@nodiscard
function LandscapingOutputSmooth.new(workArea, terrainLayerId, fillTypeIndex, litersToDrop)
    local self = LandscapingOutput.new(LandscapingOperation.SMOOTH, workArea, terrainLayerId, LandscapingOutputSmooth_mt)
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
    self.deformation = TerrainDeformation.new(g_terrainNode)

    self.deformation:setAdditiveHeightChangeAmount(self.heightChangeAmount)
    self.deformation:enableSmoothingMode()

    return self.deformation
end
