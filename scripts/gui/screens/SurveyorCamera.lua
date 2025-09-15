---@class SurveyorCamera : GuiTopDownCamera
SurveyorCamera = {}

SurveyorCamera.CAMERA_ZOOM_FACTOR = 0.05
SurveyorCamera.CAMERA_ZOOM_FACTOR_MIN = 0.05
SurveyorCamera.INPUT_MOVE_FACTOR = 0.7
SurveyorCamera.INPUT_MOVE_FACTOR_MOUSE = 0.2

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

---@param camera number
function SurveyorCamera:setRotationFromCamera(camera)
    local dx, _, dz = localDirectionToWorld(camera, 0, 0, 1)
    local rotY = math.atan2(dx, dz)

    rotY = MathUtil.getValidLimit(rotY - math.rad(180))

    self.cameraRotY = rotY
    self.targetRotation = rotY
end

function SurveyorCamera:activate()
    g_inputBinding:setShowMouseCursor(true)
    self:onInputModeChanged({ g_inputBinding:getLastInputMode() })

    self.previousCamera = g_cameraManager:getActiveCamera()
    self:setRotationFromCamera(self.previousCamera)

    self:updatePosition()

    g_cameraManager:setActiveCamera(self.camera)

    local x, _, z = g_localPlayer:getPosition()
    self:setCameraPosition(x, z)

    self:registerActionEvents()
    g_messageCenter:subscribe(MessageType.INPUT_MODE_CHANGED, self.onInputModeChanged, self)

    self.isActive = true
end

function SurveyorCamera:onZoom(_, inputValue, _, isAnalog, isMouse)
    if isMouse and self.mouseDisabled then
        return
    end

    local change = math.max(SurveyorCamera.CAMERA_ZOOM_FACTOR * self.zoomFactor, SurveyorCamera.CAMERA_ZOOM_FACTOR_MIN) * inputValue * 0.5

    self.inputZoom = change
end

function SurveyorCamera:onMoveSide(_, inputValue, _, isAnalog, isMouse)
    if isAnalog and isMouse then
        self.inputMoveSide = inputValue * SurveyorCamera.INPUT_MOVE_FACTOR_MOUSE / g_currentDt
    else
        self.inputMoveSide = inputValue * SurveyorCamera.INPUT_MOVE_FACTOR / g_currentDt
    end
end

function SurveyorCamera:onMoveForward(_, inputValue, _, isAnalog, isMouse)
    if isAnalog and isMouse then
        self.inputMoveForward = inputValue * SurveyorCamera.INPUT_MOVE_FACTOR_MOUSE / g_currentDt
    else
        self.inputMoveForward = inputValue * SurveyorCamera.INPUT_MOVE_FACTOR / g_currentDt
    end
end

function SurveyorCamera:onRotate(_, inputValue, _, isAnalog, isMouse)
    if isMouse and self.mouseDisabled then
        return
    end

    if isMouse and inputValue ~= 0 then
        self.lastActionFrame = g_time

        if not self.isCatchingCursor then
            g_inputBinding:setShowMouseCursor(false)
            self.isCatchingCursor = true
        end
    end

    if isMouse and isAnalog then
        inputValue = inputValue * 3
    end

    self.inputRotate = -inputValue * 3 / g_currentDt * 16
end

function SurveyorCamera:onTilt(_, inputValue, _, isAnalog, isMouse)
    if isMouse and self.mouseDisabled then
        return
    end

    if isMouse and inputValue ~= 0 then
        self.lastActionFrame = g_time

        if not self.isCatchingCursor then
            g_inputBinding:setShowMouseCursor(false)
            self.isCatchingCursor = true
        end
    end

    if isMouse and isAnalog then
        inputValue = inputValue * 1
    end

    self.inputTilt = inputValue * 3
end
