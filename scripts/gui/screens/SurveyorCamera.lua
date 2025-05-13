---@class SurveyorCamera : GuiTopDownCamera
SurveyorCamera = {}

local SurveyorCamera_mt = Class(SurveyorCamera, GuiTopDownCamera)

---@return SurveyorCamera
---@nodiscard
function SurveyorCamera.new()
    ---@type SurveyorCamera
    local self = GuiTopDownCamera.new(SurveyorCamera_mt)
    return self
end

function SurveyorCamera:updatePosition()
    local terrainBorder = GuiTopDownCamera.TERRAIN_BORDER
    local minXFar = GuiTopDownCamera.ROTATION_MIN_X_FAR
    local minXNear = GuiTopDownCamera.ROTATION_MIN_X_NEAR

    GuiTopDownCamera.TERRAIN_BORDER = 5
    GuiTopDownCamera.ROTATION_MIN_X_FAR = 0
    GuiTopDownCamera.ROTATION_MIN_X_NEAR = 0
    GuiTopDownCamera.DISTANCE_MIN_Z = -1

    GuiTopDownCamera.updatePosition(self)

    GuiTopDownCamera.TERRAIN_BORDER = terrainBorder
    GuiTopDownCamera.ROTATION_MIN_X_FAR = minXFar
    GuiTopDownCamera.ROTATION_MIN_X_NEAR = minXNear
    GuiTopDownCamera.DISTANCE_MIN_Z = -10
end
