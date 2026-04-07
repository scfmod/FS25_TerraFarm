---@class EditorCamera : GuiTopDownCamera
---@field target Editor
EditorCamera = {}
EditorCamera.CAMERA_ZOOM_FACTOR = 0.05
EditorCamera.CAMERA_ZOOM_FACTOR_MIN = 0.05
EditorCamera.INPUT_MOVE_FACTOR = 0.7
EditorCamera.INPUT_MOVE_FACTOR_MOUSE = 0.2

local EditorCamera_mt = Class(EditorCamera, GuiTopDownCamera)

---@param target any
---@return EditorCamera
---@nodiscard
function EditorCamera.new(target)
    ---@type EditorCamera
    local self = GuiTopDownCamera.new(EditorCamera_mt)

    self.target = target
    self.isMouseEdgeScrollingActive = false

    setNearClip(self.camera, 0.05)

    return self
end

---@param x number
---@param z number
---@param rotY number Y rotation in radians
function EditorCamera:setCameraPositionWithRotationY(x, z, rotY)
    rotY = MathUtil.getValidLimit(rotY + math.pi / 2)

    self.cameraX = x
    self.cameraZ = z
    self.targetCameraX = x
    self.targetCameraZ = z

    self.cameraRotY = rotY
    self.targetRotation = rotY

    self:updatePosition()
end

function EditorCamera:registerActionEvents()
    local _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_MOVE_SIDE_PLAYER, self, self.onMoveSide, false, false, true, true)
    g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_LOW)
    g_inputBinding:setActionEventTextVisibility(eventId, false)
    self.eventMoveSide = eventId
    _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_MOVE_FORWARD_PLAYER, self, self.onMoveForward, false, false, true, true)
    g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_LOW)
    g_inputBinding:setActionEventTextVisibility(eventId, false)
    self.eventMoveForward = eventId
    _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_CAMERA_ZOOM, self, self.onZoom, false, false, true, true)
    g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_LOW)
    g_inputBinding:setActionEventTextVisibility(eventId, false)
    _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_CAMERA_ROTATE, self, self.onRotate, false, false, true, true)
    g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_LOW)
    g_inputBinding:setActionEventTextVisibility(eventId, false)
    _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_CAMERA_TILT, self, self.onTilt, false, false, true, true)
    g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_LOW)
    g_inputBinding:setActionEventTextVisibility(eventId, false)
end

function EditorCamera:updatePosition()
    local terrainBorder = GuiTopDownCamera.TERRAIN_BORDER
    local minXFar = GuiTopDownCamera.ROTATION_MIN_X_FAR
    local minXNear = GuiTopDownCamera.ROTATION_MIN_X_NEAR
    local groundMinY = GuiTopDownCamera.GROUND_DISTANCE_MIN_Y
    local terrainOffset = GuiTopDownCamera.CAMERA_TERRAIN_OFFSET

    GuiTopDownCamera.TERRAIN_BORDER = 5
    GuiTopDownCamera.ROTATION_MIN_X_FAR = 0
    GuiTopDownCamera.ROTATION_MIN_X_NEAR = 0
    GuiTopDownCamera.DISTANCE_MIN_Z = -1
    GuiTopDownCamera.GROUND_DISTANCE_MIN_Y = 0.1
    GuiTopDownCamera.CAMERA_TERRAIN_OFFSET = 0.1

    GuiTopDownCamera.updatePosition(self)

    GuiTopDownCamera.TERRAIN_BORDER = terrainBorder
    GuiTopDownCamera.ROTATION_MIN_X_FAR = minXFar
    GuiTopDownCamera.ROTATION_MIN_X_NEAR = minXNear
    GuiTopDownCamera.DISTANCE_MIN_Z = -10
    GuiTopDownCamera.GROUND_DISTANCE_MIN_Y = groundMinY
    GuiTopDownCamera.CAMERA_TERRAIN_OFFSET = terrainOffset
end

function EditorCamera:onZoom(_, inputValue, _, isAnalog, isMouse)
    if isMouse and self.mouseDisabled then
        return
    end

    local change = math.max(EditorCamera.CAMERA_ZOOM_FACTOR * self.zoomFactor, EditorCamera.CAMERA_ZOOM_FACTOR_MIN) * inputValue * 0.25

    self.inputZoom = change
end

function EditorCamera:onMoveSide(_, inputValue, _, isAnalog, isMouse)
    if isAnalog and isMouse then
        self.inputMoveSide = inputValue * EditorCamera.INPUT_MOVE_FACTOR_MOUSE / g_currentDt
    else
        self.inputMoveSide = inputValue * EditorCamera.INPUT_MOVE_FACTOR / g_currentDt
    end
end

function EditorCamera:onMoveForward(_, inputValue, _, isAnalog, isMouse)
    if isAnalog and isMouse then
        self.inputMoveForward = inputValue * EditorCamera.INPUT_MOVE_FACTOR_MOUSE / g_currentDt
    else
        self.inputMoveForward = inputValue * EditorCamera.INPUT_MOVE_FACTOR / g_currentDt
    end
end

function EditorCamera:onRotate(_, inputValue, _, isAnalog, isMouse)
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

function EditorCamera:onTilt(_, inputValue, _, isAnalog, isMouse)
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
