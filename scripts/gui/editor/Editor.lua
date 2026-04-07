---@class Editor: ScreenElement
---@field isa fun(self: Editor, class: table): boolean
---@field superClass fun(): ScreenElement
---
---@field originalSafeFrameOffsetX number
---@field originalInputHelpVisibility boolean
---@field originalMaxNumHelpDisplayElements number
---@field isMouseInMenu boolean
---@field isMouseMode boolean
---@field camera EditorCamera
---@field cursor EditorCursor
---
---@field menuElement BitmapElement
---@field controlPanelElement BoxLayoutElement
---@field dataPanelElement BoxLayoutElement
---@field optionPanelElement BoxLayoutElement
---@field positionPanelElement BoxLayoutElement
---@field helpDisplayElement GuiElement
---@field compassImageElement BitmapElement
---@field saveButtonElement ButtonElement
---@field moveButtonElement ButtonElement
---@field nameInputElement TextInputElement
---@field infoDisplayTextElement TextElement
---
---@field inputIsActive boolean
---@field inputPos number[]
---@field isInputAngle boolean
---@field isInputHeight boolean
---@field isInputDirZ boolean
---
---@field inputEventAngle string
---@field inputEventBack string
---@field inputEventCancel string
---@field inputEventDelete string
---@field inputEventDirZ string
---@field inputEventEnter string
---@field inputEventExit string
---@field inputEventLeftRightAxis string
---@field inputEventLevel string
---@field inputEventMove string
---@field inputEventPrevNextAxis string
---@field inputEventPrimary string
---@field inputEventUpDownAxis string
---
---@field showInGameMenuWhenClosed boolean
---@field mode EditorMode
---@field selectedIndex? number
---@field points number[][]
---@field hasChanged boolean
---@field placementDirection EditorDirection
---@field numPointsLimit number
---@field stepMoveXZ number
---@field stepMoveY number
---@field stepRotate number
---
---@field borderVisible boolean
---@field borderShape number
---@field borderRootNode number
---@field borderChildNodes number[]
---
---@field editBorderColor number[]
---@field editBorderDecalColor number[]
Editor = {}

Editor.CLASS_NAME = ''
Editor.XML_FILENAME = ''
Editor.INPUT_CONTEXT = 'AREA_EDITOR'

---@enum EditorDirection
EditorDirection = {
    POSITIVE = 1,
    NEGATIVE = -1,
}

---@enum EditorMode
EditorMode = {
    NONE = 0,
    CREATE_POINT = 1,
    SELECT_POINT = 2,
    MOVE_POINT = 4,
    MOVE_AREA = 3,
    ROTATE_AREA = 5,
}

---@type table<EditorMode, string>
---@diagnostic disable-next-line: inject-field
Editor.MODE_TEXT = {
    [EditorMode.NONE] = 'NONE',
    [EditorMode.SELECT_POINT] = 'SELECT_POINT',
    [EditorMode.CREATE_POINT] = 'CREATE_POINT',
    [EditorMode.MOVE_POINT] = 'MOVE_POINT',
    [EditorMode.MOVE_AREA] = 'MOVE_AREA',
    [EditorMode.ROTATE_AREA] = 'ROTATE_AREA',
}

---@diagnostic disable-next-line: inject-field
Editor.L10N_SYMBOL = {
    ALIGN_WORLD_AXES = g_i18n:getText('ui_alignWorldAxes'),
    CANCEL = g_i18n:getText('button_cancel'),
    CHANGE_DIRECTION = g_i18n:getText('input_DIRECTION_CHANGE'),
    CREATE_AREA = g_i18n:getText('ui_createArea'),
    CREATE_POINT = g_i18n:getText('ui_createPoint'),
    CREATE_WATERPLANE = g_i18n:getText('ui_createWaterplane'),
    DELETE = g_i18n:getText('button_delete'),
    EDIT = g_i18n:getText('ui_edit'),
    EXIT_EDITOR = g_i18n:getText('input_CONSTRUCTION_EXIT'),
    ENTER_EDIT_MODE = g_i18n:getText('ui_editMode'),
    EXIT_EDIT_MODE = g_i18n:getText('ui_exitEditMode'),
    FOLLOW_ANGLE = g_i18n:getText('ui_followAngle'),
    LEVEL = g_i18n:getText('construction_item_level'),
    HIDDEN = g_i18n:getText('ui_hidden'),
    KEEP_DIRECTION = g_i18n:getText('ui_keepDirection'),
    MOVE_HORIZONTAL = g_i18n:getText('ui_moveHorizontal'),
    MOVE_POINT = g_i18n:getText('ui_movePoint'),
    MOVE_VERTICAL = g_i18n:getText('ui_moveVertical'),
    NOT_SET = g_i18n:getText('ui_notSet'),
    PLACE_POINT = g_i18n:getText('ui_placePoint'),
    SAVE = g_i18n:getText('button_save'),
    SAVE_CHANGES = g_i18n:getText('ui_editorSaveChanges'),
    SELECT_POINT = g_i18n:getText('ui_selectPoint'),
    SET_HIDDEN = g_i18n:getText('ui_setHidden'),
    SET_NEW_POSITION = g_i18n:getText('ui_setNewPosition'),
    SET_POSITION = g_i18n:getText('ui_setPosition'),
    SET_TARGET_HEIGHT = g_i18n:getText('ui_setTargetHeight'),
    SET_VISIBLE = g_i18n:getText('ui_setVisible'),
    VISIBLE = g_i18n:getText('ui_visible')
}

local COLOR_GRAY = { 0.4, 0.4, 0.4, 1 }
-- local COLOR_BLUE = { 0, 0.3, 1, 1 }
local COLOR_BLUE = { 0, 0.25, 0.6, 1 }
-- local COLOR_ORANGE = { 1, 0.3, 0, 1 }
local COLOR_ORANGE = { 0.4, 0.1, 0, 1 }
local COLOR_GREEN = { 0, 0.45, 0, 1 }
local TEXT_COLOR_BLUE = { 0, 0, 1, 1 }
local TEXT_COLOR_GREEN = { 0, 1, 0, 1 }

---@diagnostic disable-next-line: inject-field
Editor.COLOR = {
    TEXT_DEFAULT = { 1, 1, 1, 1 },
    -- TEXT_SELECTED = COLOR_BLUE,
    TEXT_SELECTED = TEXT_COLOR_GREEN,

    LINE_DEFAULT = COLOR_GRAY,
    LINE_SELECTED = COLOR_GREEN,

    POINT_DEFAULT = COLOR_GRAY,
    POINT_SELECTED = COLOR_GREEN,
}

---@diagnostic disable-next-line: inject-field
Editor.RADIUS = {
    POINT = 0.2,
    POINT_SELECTED = 0.3,
    POINT_OVER = 0.4
}

local Editor_mt = Class(Editor, ScreenElement)

---@param customMt table
---@return Editor
---@nodiscard
function Editor.new(customMt)
    ---@type Editor
    local self = ScreenElement.new(nil, customMt)

    self.isMouseInMenu = false
    self.isMouseMode = true

    self.camera = EditorCamera.new(self)
    self.camera.zoomFactor = 0.025
    self.camera.targetZoomFactor = 0.025
    self.cursor = EditorCursor.new(self)

    self.selectedIndex = nil
    self.placementDirection = 1
    self.numPointsLimit = 0
    self.stepMoveXZ = 0.25
    self.stepMoveY = 0.1
    self.stepRotate = 11.25

    self.borderVisible = false
    self.borderChildNodes = {}
    self.borderRootNode = createTransformGroup('borderRootNode')

    link(getRootNode(), self.borderRootNode)
    setVisibility(self.borderRootNode, false)

    self.editBorderColor = { 1, 1, 1, 1 }
    self.editBorderDecalColor = { 1, 0.865, 0, 1 }

    self:loadShapes()

    return self
end

function Editor:delete()
    delete(self.borderRootNode)

    self.borderChildNodes = nil

    self.camera:delete()
    self.cursor:delete()

    FocusManager.guiFocusData[self.CLASS_NAME] = {
        idToElementMapping = {}
    }

    Editor:superClass().delete(self)
end

function Editor:load()
    g_gui:loadGui(self.XML_FILENAME, self.CLASS_NAME, self)
end

function Editor:loadShapes()
    local i3dNode = g_i3DManager:loadSharedI3DFile(LandscapingManager.BORDER_SHAPE_FILENAME, false, false)

    if i3dNode ~= 0 then
        local node = getChildAt(i3dNode, 0)

        self.borderShape = node

        local borderIntensity = g_landscapingManager.borderIntensity
        local borderDash = g_landscapingManager.borderDash
        local borderColor = self.editBorderColor
        local decalColor = self.editBorderDecalColor

        link(self.borderRootNode, node)
        delete(i3dNode)

        setIsTerrainDecal(node, true)
        setShaderParameter(node, 'diffuseColor', borderColor[1], borderColor[2], borderColor[3], borderColor[4], false)
        setShaderParameter(node, 'decalColor', decalColor[1], decalColor[2], decalColor[3], decalColor[4], false)

        setShaderParameter(node, 'intensitySize', borderIntensity[1], borderIntensity[2], borderIntensity[3], borderIntensity[4], false)
        setShaderParameter(node, 'dashNumLength', borderDash[1], borderDash[2], borderDash[3], borderDash[4], true)
    end
end

function Editor:onOpen()
    Editor:superClass().onOpen(self)

    self.selectedIndex = nil
    self.placementDirection = EditorDirection.POSITIVE

    self.originalMaxNumHelpDisplayElements = InputHelpDisplay.MAX_NUM_ELEMENTS
    InputHelpDisplay.MAX_NUM_ELEMENTS = 16

    g_inputBinding:setContext(self.INPUT_CONTEXT)
    g_messageCenter:subscribe(MessageType.INPUT_MODE_CHANGED, self.onInputModeChanged, self)

    self:onInputModeChanged({ g_inputBinding:getLastInputMode() })
    self:setHasChanged(false)
    self:registerActionEvents()

    local viewPortStartX = self.menuElement.absPosition[1] + self.menuElement.absSize[1]
    local mapX, mapZ = self:getCameraFocusWorldPositionXZ()

    self.camera:setTerrainRootNode(g_terrainNode)
    self.camera:activate()

    if mapX ~= math.huge then
        self.camera:setCameraPosition(mapX, mapZ)
    end

    self.cursor:activate()

    self.originalSafeFrameOffsetX = g_safeFrameOffsetX
    g_safeFrameOffsetX = viewPortStartX + g_safeFrameOffsetX
    self.originalInputHelpVisibility = g_currentMission.hud.inputHelp:getVisible()
    g_currentMission.hud:setInputHelpVisible(true, true)

    self:updateData()
end

function Editor:onClose()
    InputHelpDisplay.MAX_NUM_ELEMENTS = self.originalMaxNumHelpDisplayElements

    self.cursor:deactivate()
    self.camera:deactivate()

    g_messageCenter:unsubscribeAll(self)

    g_inputBinding:removeActionEventsByTarget(self)
    g_inputBinding:revertContext()

    -- Restore safe frame offset to original value
    g_safeFrameOffsetX = self.originalSafeFrameOffsetX
    -- Restore input help visibility to original value
    g_currentMission.hud:setInputHelpVisible(self.originalInputHelpVisibility)

    Editor:superClass().onClose(self)
end

---@param mode EditorMode
function Editor:setMode(mode)
    -- implemented by inherited class
    self.mode = mode
end

---@return number x
---@return number z
function Editor:getCameraFocusWorldPositionXZ()
    -- implemented by inherited class
    return 0, 0
end

---@return string
---@nodiscard
function Editor:getName()
    -- implemented by inherited class
    return 'NO_NAME'
end

---@param name string
function Editor:setName(name)
    -- implemented by inherited class
end

---@param changed boolean
function Editor:setHasChanged(changed)
    self.hasChanged = changed

    self:updateControlPanel()
end

---@param index? number
---@param forceUpdate? boolean
function Editor:setSelectedIndex(index, forceUpdate)
    local hasChanged = false

    if self.selectedIndex ~= index then
        self.selectedIndex = index
        hasChanged = true
    end

    if hasChanged or forceUpdate then
        self:updateActionEvents()
        self:updatePanels()
        self:updateDisplayText()
    end
end

---@param visible boolean
function Editor:setBorderVisibility(visible)
    self.borderVisible = visible
    setVisibility(self.borderRootNode, visible)
end

function Editor:updateBorder()
    -- implemented by inherited class
end

function Editor:updateBorderColor()
    -- implemented by inherited class
end

---@return boolean
---@nodiscard
function Editor:getIsInputActive()
    return self.cursor.currentHitTerrain and (not self.isMouseMode or not self.isMouseInMenu)
end

---@return number[]?
---@nodiscard
function Editor:getPlacementPos()
    if self:getIsInputActive() then
        return table.pack(self.cursor.currentHitX, self.cursor.currentHitY, self.cursor.currentHitZ)
    end
end

---@return number?
---@nodiscard
function Editor:getNearestMouseOverIndex()
    if self:getIsInputActive() then
        local points = self.points
        local maxDistance = 0.025
        local mousePosX, mousePosY = self.cursor.mousePosX, self.cursor.mousePosY

        for i, pos in ipairs(points) do
            local sx, sy, sz = project(pos[1], pos[2], pos[3])

            if sx > -1 and sx < 2 and sy > -1 and sy < 2 and sz <= 1 then
                local distance = MathUtil.getPointPointDistance(mousePosX, mousePosY, sx, sy)
                if distance < maxDistance then
                    return i
                end
            end
        end
    end
end

function Editor:splitSelectedSegment()
    local selectedIndex = self.selectedIndex
    local points = self.points

    if selectedIndex ~= nil then
        local selectedPos = points[selectedIndex]
        local prevPos = points[selectedIndex - 1]

        if selectedPos and prevPos then
            local x, y, z = EditorUtils.getCenterOf(prevPos, selectedPos)

            table.insert(points, selectedIndex, { x, y, z })

            self:updateBorder()
            self:setHasChanged(true)
            self:setSelectedIndex(selectedIndex, true)
        end
    end
end

---@return number?
---@nodiscard
function Editor:getSelectedSegmentAngleY()
    -- implemented by inherited class
end

---@return number?
---@nodiscard
function Editor:getSelectedSegmentAngleX()
    local points = self.points
    local selectedIndex = self.selectedIndex
    local startPos = points[selectedIndex - 1]
    local endPos = points[selectedIndex]

    if startPos ~= nil and endPos ~= nil then
        return EditorUtils.calculateTargetAngle(startPos, endPos)
    end
end

function Editor:deleteSelectedPoint()
    -- implemented by inherited class
end

function Editor:createPoint()
    -- implemented by inherited class
end

function Editor:moveSelectedPoint()
    -- implemented by inherited class
end

---@param dx number
---@param dy number
---@param dz number
function Editor:moveSelectedPointPos(dx, dy, dz)
    local pos = self.points[self.selectedIndex]

    if pos ~= nil then
        pos[1] = pos[1] + dx
        pos[2] = pos[2] + dy
        pos[3] = pos[3] + dz
    end

    self:updateBorder()
    self:updateDisplayText()
    self:setHasChanged(true)
end

---@param step number
function Editor:moveSelectedPointXZUsingCamera(step)
    local rightX = math.cos(self.camera.cameraRotY)
    local rightZ = -math.sin(self.camera.cameraRotY)

    self:moveSelectedPointPos(rightX * step, 0, rightZ * step)
end

---@param step number
function Editor:moveAllPointsXZUsingCamera(step)
    local rightX = math.cos(self.camera.cameraRotY)
    local rightZ = -math.sin(self.camera.cameraRotY)
    local dx = rightX * step
    local dz = rightZ * step

    for _, pos in ipairs(self.points) do
        pos[1] = pos[1] + dx
        pos[3] = pos[3] + dz
    end

    self:setHasChanged(true)
    self:updateBorder()
end

---@param x number
---@param y number
---@param z number
function Editor:setSelectedPointXYZ(x, y, z)
    local selectedPos = self.points[self.selectedIndex]

    if selectedPos ~= nil then
        selectedPos[1] = x
        selectedPos[2] = y
        selectedPos[3] = z

        self:updateBorder()
        self:updateDisplayText()
        self:setHasChanged(true)
    end
end

-- ---@param y number
-- function Editor:updateSelectedPointY(y)
--     local selectedPos = self.points[self.selectedIndex]

--     if selectedPos ~= nil then
--         selectedPos[2] = y

--         self:updateBorder()
--         self:setHasChanged(true)
--     end
-- end

---@param angle number
---@param direction number
function Editor:setSelectedSegmentRotationXMove(angle, direction)
    local points = self.points
    local numPoints = #points
    local selectedIndex = self.selectedIndex
    local selectedPos = points[selectedIndex]

    if selectedPos ~= nil and selectedIndex > 1 then
        local prevPos = points[selectedIndex - 1]
        local targetY, originalY, startIndex, endIndex

        if direction == 1 then
            originalY = selectedPos[2]
            targetY = EditorUtils.calculateTargetHeightUsingAngle(prevPos, selectedPos, angle)
            startIndex = selectedIndex
            endIndex = numPoints
        else
            angle = -angle
            originalY = prevPos[2]
            targetY = EditorUtils.calculateTargetHeightUsingAngle(selectedPos, prevPos, angle)
            startIndex = 1
            endIndex = selectedIndex - 1
        end

        local deltaY = targetY - originalY

        for i = startIndex, endIndex do
            local pos = points[i]

            if pos ~= nil then
                pos[2] = pos[2] + deltaY
            end
        end

        self:updateBorder()
        self:updateDisplayText()
        self:setHasChanged(true)
    end
end

---@param angle number
---@param direction EditorDirection
function Editor:setSelectedSegmentRotationX(angle, direction)
    local points = self.points
    local selectedIndex = self.selectedIndex

    if selectedIndex == nil then
        return
    end

    local selectedPos = points[selectedIndex]
    local prevPos = points[selectedIndex - 1]

    if selectedPos ~= nil and prevPos ~= nil then
        if direction == EditorDirection.POSITIVE then
            local targetY = EditorUtils.calculateTargetHeightUsingAngle(prevPos, selectedPos, angle)
            selectedPos[2] = targetY
        else
            local targetY = EditorUtils.calculateTargetHeightUsingAngle(selectedPos, prevPos, -angle)
            prevPos[2] = targetY
        end

        self:updateBorder()
        self:updateDisplayText()
        self:setHasChanged(true)
    end
end

---@param targetAngle number
---@param direction EditorDirection
function Editor:setSelectedSegmentRotationXFollow(targetAngle, direction)
    local points = self.points
    local numPoints = #points
    local selectedIndex = self.selectedIndex
    local selectedPos = points[selectedIndex]

    if selectedPos ~= nil and selectedIndex > 1 then
        if direction == EditorDirection.POSITIVE then
            for i = selectedIndex, numPoints do
                local pos = points[i]
                local prevPos = points[i - 1]

                if pos ~= nil then
                    local targetY = EditorUtils.calculateTargetHeightUsingAngle(prevPos, pos, targetAngle)

                    pos[2] = targetY
                end
            end
        else
            targetAngle = -targetAngle
            for i = selectedIndex, 1, -1 do
                local pos = points[i]
                local prevPos = points[i - 1]

                if prevPos ~= nil then
                    local targetY = EditorUtils.calculateTargetHeightUsingAngle(pos, prevPos, targetAngle)

                    prevPos[2] = targetY
                end
            end
        end

        self:updateBorder()
        self:updateDisplayText()
        self:setHasChanged(true)
    end
end

function Editor:registerActionEvents()
    g_inputBinding:removeActionEventsByTarget(self)

    self.inputEventAngle = nil
    self.inputEventBack = nil
    self.inputEventCancel = nil
    self.inputEventDelete = nil
    self.inputEventDirZ = nil
    self.inputEventEnter = nil
    self.inputEventExit = nil
    self.inputEventLeftRightAxis = nil
    self.inputEventLevel = nil
    self.inputEventMove = nil
    self.inputEventPrevNextAxis = nil
    self.inputEventPrimary = nil
    self.inputEventUpDownAxis = nil

    local eventId

    if self.mode == EditorMode.NONE then
        _, eventId = g_inputBinding:registerActionEvent(InputAction.MENU_BACK, self, self.onInputEventBack, true, false, false, true)
        g_inputBinding:setActionEventText(eventId, Editor.L10N_SYMBOL.EXIT_EDITOR)
        g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_HIGH)
        self.inputEventBack = eventId

        _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_ENTER', self, self.onInputEventEnter, true, false, false, true)
        g_inputBinding:setActionEventText(eventId, Editor.L10N_SYMBOL.ENTER_EDIT_MODE)
        g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_HIGH)
        self.inputEventEnter = eventId
    else
        _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_EXIT', self, self.onInputEventExit, true, false, false, false)
        g_inputBinding:setActionEventText(eventId, Editor.L10N_SYMBOL.EXIT_EDIT_MODE)
        g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_HIGH)
        self.inputEventExit = eventId

        _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_PRIMARY', self, self.onInputEventPrimary, false, true, false, false)
        g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_HIGH)
        self.inputEventPrimary = eventId

        _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_CANCEL', self, self.onInputEventCancel, true, false, false, false)
        g_inputBinding:setActionEventText(eventId, Editor.L10N_SYMBOL.CANCEL)
        g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_HIGH)
        self.inputEventCancel = eventId

        _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_MOVE', self, self.onInputEventMove, false, true, false, false)
        g_inputBinding:setActionEventText(eventId, Editor.L10N_SYMBOL.MOVE_POINT)
        g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_HIGH)
        self.inputEventMove = eventId

        _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_DELETE', self, self.onInputEventDelete, false, true, false, false)
        g_inputBinding:setActionEventText(eventId, Editor.L10N_SYMBOL.DELETE)
        g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_HIGH)
        self.inputEventDelete = eventId

        _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_UP_DOWN', self, self.onInputEventUpDownAxis, false, true, false, false)
        g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_HIGH)
        self.inputEventUpDownAxis = eventId

        _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_LEFT_RIGHT', self, self.onInputEventLeftRightAxis, false, true, false, false)
        g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_HIGH)
        self.inputEventLeftRightAxis = eventId

        _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_PREV_NEXT', self, self.onInputEventPrevNextAxis, false, true, false, false)
        g_inputBinding:setActionEventText(eventId, Editor.L10N_SYMBOL.CHANGE_DIRECTION)
        g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_HIGH)
        self.inputEventPrevNextAxis = eventId

        _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_DIRECTION', self, self.onInputEventDirZ, true, true, false, false)
        g_inputBinding:setActionEventText(eventId, Editor.L10N_SYMBOL.KEEP_DIRECTION)
        g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_NORMAL)
        self.inputEventDirZ = eventId

        _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_ANGLE', self, self.onInputEventAngle, true, true, false, false)
        g_inputBinding:setActionEventText(eventId, Editor.L10N_SYMBOL.FOLLOW_ANGLE)
        g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_NORMAL)
        self.inputEventAngle = eventId

        _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_LEVEL', self, self.onInputEventLevel, true, true, false, false)
        g_inputBinding:setActionEventText(eventId, Editor.L10N_SYMBOL.LEVEL)
        g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_NORMAL)
        self.inputEventLevel = eventId
    end

    self:updateActionEvents()
end

function Editor:updateActionEvents()
    self:updateActionEvent(self.inputEventBack, false)
    self:updateActionEvent(self.inputEventExit, false)
    self:updateActionEvent(self.inputEventPrimary, false)
    self:updateActionEvent(self.inputEventCancel, false)
    self:updateActionEvent(self.inputEventMove, false)
    self:updateActionEvent(self.inputEventDelete, false)
    self:updateActionEvent(self.inputEventUpDownAxis, false)
    self:updateActionEvent(self.inputEventLeftRightAxis, false)
    self:updateActionEvent(self.inputEventPrevNextAxis, false)
    self:updateActionEvent(self.inputEventDirZ, false)
    self:updateActionEvent(self.inputEventAngle, false)
    self:updateActionEvent(self.inputEventLevel, false)

    if self.mode == EditorMode.NONE then
        self:updateActionEvent(self.inputEventBack, true)

        local _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onPressMenuUpDown, false, true, true, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)

        _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onPressMenuLeftRight, false, true, true, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)

        _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onReleaseMenuUpDown, true, false, false, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)

        _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onReleaseMenuLeftRight, true, false, false, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)

        _, eventId = g_inputBinding:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onPressMenuAccept, false, true, false, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
    end
end

---@param eventId string
---@param isActive boolean
---@param text? string
---@param textVisibility? boolean
---@param priority? number
function Editor:updateActionEvent(eventId, isActive, text, textVisibility, priority)
    if eventId ~= nil then
        g_inputBinding:setActionEventActive(eventId, isActive)

        if text ~= nil then
            g_inputBinding:setActionEventText(eventId, text)
        end

        if textVisibility ~= nil then
            g_inputBinding:setActionEventTextVisibility(eventId, textVisibility)
        end

        if priority ~= nil then
            g_inputBinding:setActionEventTextPriority(eventId, priority)
        end
    end
end

function Editor:onInputEventBack()
    self:requestClose()
end

function Editor:onInputEventPrimary()
    if self.mode == EditorMode.SELECT_POINT then
        if not self.isMouseMode or not self.isMouseInMenu then
            self:setSelectedIndex(self:getNearestMouseOverIndex())
        end
    elseif self.mode == EditorMode.CREATE_POINT then
        self:createPoint()
    elseif self.mode == EditorMode.MOVE_POINT then
        self:moveSelectedPoint()
    end
end

function Editor:onInputButtonAccept()
    if self.mode == EditorMode.NONE then
        g_gui:notifyControls("MENU_ACCEPT")
    end
end

function Editor:onInputButtonCancel()
    local mode = self.mode

    if mode == EditorMode.SELECT_POINT then
        self:setMode(EditorMode.NONE)
    elseif mode == EditorMode.CREATE_POINT then
        if #self.points == 0 then
            self:setMode(EditorMode.NONE)
        else
            self:setMode(EditorMode.SELECT_POINT)
        end
    elseif mode == EditorMode.MOVE_POINT then
        self:setMode(EditorMode.SELECT_POINT)
    end
end

function Editor:onInputEventMove()
    if self.selectedIndex ~= nil and self.mode == EditorMode.SELECT_POINT then
        self:setMode(EditorMode.MOVE_POINT)
    end
end

function Editor:onInputEventDelete()
    local mode = self.mode

    if mode == EditorMode.SELECT_POINT or mode == EditorMode.CREATE_POINT then
        self:deleteSelectedPoint()
    end
end

---@param action any
---@param value number
function Editor:onInputEventDirZ(action, value)
    self.isInputDirZ = value == 1
end

---@param action any
---@param value number
function Editor:onInputEventAngle(action, value)
    self.isInputAngle = value == 1
end

---@param action any
---@param value number
function Editor:onInputEventLevel(action, value)
    self.isInputHeight = value == 1
end

---@param binding Binding
function Editor:onInputEventUpDownAxis(action, _, _, _, _, _, binding)
    local mode = self.mode
    local isPositiveDirection = binding.axisDirection == 1

    if mode == EditorMode.MOVE_POINT or mode == EditorMode.CREATE_POINT or mode == EditorMode.SELECT_POINT then
        if isPositiveDirection then
            self:moveSelectedPointPos(0, self.stepMoveY, 0)
        else
            self:moveSelectedPointPos(0, -self.stepMoveY, 0)
        end
    end
end

---@param binding Binding
function Editor:onInputEventLeftRightAxis(action, _, _, _, _, _, binding)
    local isPositiveDirection = binding.axisDirection == 1

    if self.isMouseMode then
        if isPositiveDirection then
            self:moveSelectedPointXZUsingCamera(-self.stepMoveXZ)
        else
            self:moveSelectedPointXZUsingCamera(self.stepMoveXZ)
        end
    else
        self:onInputEventPrevNextAxis(nil, nil, nil, nil, nil, nil, binding)
    end
end

---@param binding Binding
function Editor:onInputEventPrevNextAxis(_, _, _, _, _, _, binding)
    local mode = self.mode
    local isPositiveDirection = binding.axisDirection == 1

    if self.selectedIndex ~= nil and (mode == EditorMode.SELECT_POINT or mode == EditorMode.CREATE_POINT) then
        if isPositiveDirection then
            self.placementDirection = EditorDirection.POSITIVE
        else
            self.placementDirection = EditorDirection.NEGATIVE
        end

        self:setMode(EditorMode.CREATE_POINT)
    end
end

function Editor:onInputEventEnter()
    self:setMode(EditorMode.SELECT_POINT)
end

function Editor:onInputEventExit()
    self:setMode(EditorMode.NONE)
end

function Editor:onInputEventCancel()
    if self.mode == EditorMode.MOVE_AREA or self.mode == EditorMode.ROTATE_AREA then
        self:setMode(EditorMode.NONE)
    else
        self:setMode(EditorMode.SELECT_POINT)
    end
end

function Editor:onInputModeChanged(inputMode)
    self.isMouseMode = inputMode[1] == GS_INPUT_HELP_MODE_KEYBOARD

    self:updateActionEvents()
end

function Editor:onPressMenuAccept()
    g_gui:notifyControls("MENU_ACCEPT")
end

function Editor:onPressMenuUpDown(_, value)
    g_gui:onMenuInput(InputAction.MENU_AXIS_UP_DOWN, value)
end

function Editor:onReleaseMenuUpDown()
    g_gui:onReleaseMovement(InputAction.MENU_AXIS_UP_DOWN)
end

function Editor:onPressMenuLeftRight(_, value)
    g_gui:onMenuInput(InputAction.MENU_AXIS_LEFT_RIGHT, value)
end

function Editor:onReleaseMenuLeftRight()
    g_gui:onReleaseMovement(InputAction.MENU_AXIS_LEFT_RIGHT)
end

---@param state number
---@param element BinaryOptionElement
function Editor:onPressedOption(state, element)
    -- implemented by inherited class
end

---@param element ButtonElement
function Editor:onPressedButton(element)
    -- implemented by inherited class
end

---@param element TextInputElement
function Editor:onTextInputPressed(element)
    if element == self.nameInputElement then
        local text = EditorUtils.getTextInput(element, nil, self:getName())
        self:setName(text)
        element:setText(text)
        self:setHasChanged(true)
    end
end

function Editor:onClickSegmentSplit()
    self:splitSelectedSegment()
end

function Editor:onClickHelp()
    g_editorGuide:show()
end

function Editor:onClickMove()
    self:setMode(EditorMode.MOVE_AREA)
end

function Editor:requestClose()
    if self.hasChanged then
        ---@param yes boolean
        local callbackFn = function (yes)
            if yes then
                self:closeScreen()
            end
        end

        YesNoDialog.show(callbackFn, nil,
            g_i18n:getText('ui_editorConfirmCloseText'), '',
            g_i18n:getText("button_ok"),
            g_i18n:getText("button_cancel")
        )
    else
        self:closeScreen()
    end
end

function Editor:closeScreen()
    if self.showInGameMenuWhenClosed then
        g_gui:showGui('InGameMenu')
    else
        g_gui:showGui(nil)
    end
end

function Editor:updateData()
    self.nameInputElement:setText(self:getName())

    self:updateDataPanel()
end

function Editor:updatePanels()
    self:updateControlPanel()
    self:updateDataPanel()
    self:updateOptionPanel()
    self:updatePositionPanel()
end

function Editor:updateDataPanel()
    -- implemented by inherited class
end

function Editor:updateControlPanel()
    -- implemented by inherited class
end

function Editor:updateOptionPanel()
    -- implemented by inherited class
end

function Editor:updatePositionPanel()
    -- implemented by inherited class
end

---@param dt number
function Editor:update(dt)
    Editor:superClass().update(self, dt)

    g_currentMission.hud.sideNotifications:update(dt)

    self.camera:setCursorLocked(self.cursor.isCatchingCursor)
    self.camera:update(dt)

    if not self.isMouseMode or not self.isMouseInMenu then
        self.cursor:setCameraRay(self.camera:getPickRay())
    else
        self.cursor:setCameraRay()
    end

    self.cursor:update(dt)

    if self.compassImageElement ~= nil then
        self.compassImageElement.overlay.rotation = -self.camera.cameraRotY
    end
end

---@param posX number
---@param posY number
function Editor:mouseEvent(posX, posY)
    local isMouseInMenu = GuiUtils.checkOverlayOverlap(
        posX, posY,
        self.menuElement.absPosition[1],
        self.menuElement.absPosition[2],
        self.menuElement.absSize[1],
        self.menuElement.absSize[2]
    )

    self.camera.mouseDisabled = isMouseInMenu
    self.cursor.mouseDisabled = isMouseInMenu

    self.isMouseInMenu = isMouseInMenu

    self.camera:mouseEvent(posX, posY)
    self.cursor:mouseEvent(posX, posY)
end

function Editor:draw(...)
    Editor:superClass().draw(self, ...)

    self.cursor:draw()

    g_currentMission.hud:drawInputHelp(self.helpDisplayElement.position[1], self.helpDisplayElement.position[2])
end

---@param fillTypeIndex? number
---@param imageElement BitmapElement
---@param textElement TextElement
---@param buttonElement ButtonElement
function Editor:updateFillTypeInput(fillTypeIndex, imageElement, textElement, buttonElement)
    ---@type FillTypeObject?
    local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

    if fillType ~= nil then
        imageElement:setImageFilename(fillType.hudOverlayFilename)
        imageElement:setVisible(true)
        textElement:setText(fillType.title)
        textElement:setDisabled(false)
        buttonElement:setDisabled(false)
    else
        imageElement:setVisible(false)
        textElement:setText(Editor.L10N_SYMBOL.NOT_SET)
        textElement:setDisabled(true)
        buttonElement:setDisabled(true)
    end
end

---@param layerId? number
---@param terrainLayerElement TerrainLayerElement
---@param textElement TextElement
---@param buttonElement ButtonElement
function Editor:updateTerrainLayerInput(layerId, terrainLayerElement, textElement, buttonElement)
    ---@diagnostic disable-next-line: param-type-mismatch
    local layer = g_landscapingManager:getTerrainLayerById(layerId)

    if layer ~= nil then
        terrainLayerElement:setTerrainLayer(g_terrainNode, layer.id)
        terrainLayerElement:setVisible(true)
        textElement:setText(layer.title)
        textElement:setDisabled(false)
        buttonElement:setDisabled(false)
    else
        terrainLayerElement:setVisible(false)
        textElement:setText(Editor.L10N_SYMBOL.NOT_SET)
        textElement:setDisabled(true)
        buttonElement:setDisabled(true)
    end
end

function Editor:updateDisplayText()
    local text = ''

    if self.mode ~= EditorMode.NONE then
        local selectedPos = self.points[self.selectedIndex]

        if selectedPos ~= nil then
            local rotY = self:getSelectedSegmentAngleY()

            if rotY ~= nil then
                text = string.format('x: %.2f  y: %.2f  z: %.2f    y-rotation: %.2f°', selectedPos[1], selectedPos[2], selectedPos[3], rotY)
            else
                text = string.format('x: %.2f  y: %.2f  z: %.2f', selectedPos[1], selectedPos[2], selectedPos[3])
            end
        end
    end

    self.infoDisplayTextElement:setText(text)
end
