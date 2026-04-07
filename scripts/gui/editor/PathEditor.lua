---@class PathEditor : AreaEditor
---@field superClass fun(): AreaEditor
---
---@field area LandscapingAreaPath
---@field widthInputElement TextInputElement
---@field forceAngleInputElement TextInputElement
---@field forceAngleOptionElement BinaryOptionElement
---@field useForceAngle boolean
---@field forceAngle number
---
---@field setPointPositionButton ButtonElement
---@field splitSegmentButton ButtonElement
---@field segmentRotationNegYMoveButton ButtonElement
---@field segmentRotationNegYButton ButtonElement
---@field segmentRotationPosYButton ButtonElement
---@field segmentRotationPosYMoveButton ButtonElement
---@field segmentRotationNegXFollowButton ButtonElement
---@field segmentRotationNegXMoveButton ButtonElement
---@field segmentRotationNegXButton ButtonElement
---@field segmentRotationPosXButton ButtonElement
---@field segmentRotationPosXMoveButton ButtonElement
---@field segmentRotationPosXFollowButton ButtonElement
---
---@field cameraStartButton ButtonElement
---@field cameraMiddleButton ButtonElement
---@field cameraEndButton ButtonElement
PathEditor = {}

PathEditor.CLASS_NAME = 'PathEditor'
PathEditor.XML_FILENAME = g_modDirectory .. 'data/gui/editor/PathEditor.xml'

local PathEditor_mt = Class(PathEditor, AreaEditor)

---@return PathEditor
---@nodiscard
function PathEditor.new()
    local self = AreaEditor.new(PathEditor_mt)
    ---@cast self PathEditor

    self.numPointsLimit = LandscapingAreaPath.MAX_NUM_POINTS

    self.useForceAngle = false
    self.forceAngle = 0

    return self
end

---@return number[]?
---@nodiscard
function PathEditor:getTargetPos()
    local inputPos = self:getPlacementPos()
    local selectedIndex = self.selectedIndex

    if inputPos ~= nil then
        local points = self.points

        if #points == 0 then
            return table.pack(self:calculateTargetPosition(nil, nil, inputPos))
        elseif selectedIndex ~= nil then
            local direction = self.placementDirection
            local startIndex = direction == 1 and selectedIndex - 1 or selectedIndex + 1
            local endIndex = selectedIndex
            local targetAngle = self.useForceAngle and self.forceAngle or nil

            if self.mode == EditorMode.MOVE_POINT then
                if selectedIndex == 1 then
                    startIndex = 1
                    endIndex = 2

                    if targetAngle ~= nil then
                        targetAngle = -targetAngle
                    end
                elseif selectedIndex == 2 and points[selectedIndex - 2] == nil then
                    endIndex = selectedIndex - 1
                elseif points[selectedIndex - 2] ~= nil then
                    startIndex = selectedIndex - 2
                    endIndex = selectedIndex - 1
                end
            elseif self.mode == EditorMode.CREATE_POINT then
                if targetAngle ~= nil and direction == -1 then
                    targetAngle = -targetAngle
                end
            end

            local startPos = points[startIndex]
            local endPos = points[endIndex]

            return table.pack(self:calculateTargetPosition(startPos, endPos, inputPos, targetAngle))
        end
    end
end

---@param direction EditorDirection
---@return number[]? startPos
---@return number[]? endPos
---@nodiscard
function PathEditor:getSelectedSegment(direction)
    local points = self.points
    local selectedIndex = self.selectedIndex
    local startPos, endPos

    if selectedIndex ~= nil then
        startPos = points[selectedIndex - 1]
        endPos = points[selectedIndex]
    end

    if direction == EditorDirection.POSITIVE then
        return startPos, endPos
    else
        return endPos, startPos
    end
end

---@return number?
function PathEditor:getSelectedSegmentAngleY()
    local startPos, endPos = self:getSelectedSegment(EditorDirection.POSITIVE)

    if startPos ~= nil and endPos ~= nil then
        return EditorUtils.getWorldRotYAngle(startPos, endPos)
    end
end

function PathEditor:createPoint()
    local points = self.points
    local targetPos = self:getTargetPos()

    if targetPos ~= nil and #points <= self.numPointsLimit then
        local selectedIndex = self.selectedIndex
        local targetIndex = selectedIndex or 1

        if selectedIndex ~= nil and self.placementDirection == EditorDirection.POSITIVE then
            targetIndex = targetIndex + 1
        end

        table.insert(points, targetIndex, targetPos)

        self:updateBorder()
        self:setHasChanged(true)
        self:setSelectedIndex(targetIndex, true)
    end
end

function PathEditor:deleteSelectedPoint()
    local points = self.points
    local selectedIndex = self.selectedIndex

    if selectedIndex ~= nil and table.remove(points, selectedIndex) ~= nil then
        local numPoints = #points

        self:setHasChanged(true)

        if numPoints == 0 then
            self.selectedIndex = nil
            self.placementDirection = EditorDirection.POSITIVE
            self:setMode(EditorMode.CREATE_POINT)
        elseif selectedIndex > numPoints then
            self:setSelectedIndex(numPoints, true)
        end

        self:updateBorder()
    end
end

function PathEditor:moveSelectedPoint()
    local selectedPos = self.points[self.selectedIndex]

    if selectedPos ~= nil then
        local targetPos = self:getTargetPos()

        if targetPos ~= nil then
            selectedPos[1], selectedPos[2], selectedPos[3] = targetPos[1], targetPos[2], targetPos[3]

            self:setMode(EditorMode.SELECT_POINT)
            self:updateBorder()
            self:setHasChanged(true)
        end
    end
end

---@param dx number
---@param dy number
---@param dz number
function PathEditor:moveSelectedPointDirection(dx, dy, dz)
    local selectedPos = self.points[self.selectedIndex]

    if selectedPos ~= nil then
        selectedPos[1] = selectedPos[1] + dx
        selectedPos[2] = selectedPos[2] + dy
        selectedPos[3] = selectedPos[3] + dz

        self:updateBorder()
        self:updateDisplayText()
        self:setHasChanged(true)
    end
end

---@param step number
function PathEditor:moveAllPointsY(step)
    local points = self.points

    for _, pos in ipairs(points) do
        pos[2] = pos[2] + step
    end

    self:setHasChanged(true)
    self:updateBorder()
end

---@param angle number
---@param direction EditorDirection
function PathEditor:setSelectedSegmentYRotation(angle, direction)
    local startPos, endPos = self:getSelectedSegment(direction)

    if startPos ~= nil and endPos ~= nil then
        if direction == EditorDirection.NEGATIVE then
            angle = (angle + 180) % 360
        end

        local x, z = EditorUtils.calculateXZUsingRotationYAngle(startPos, endPos, angle)

        endPos[1] = x
        endPos[3] = z

        self:updateBorder()
        self:updateDisplayText()
        self:setHasChanged(true)
    end
end

---@param angle number
---@param direction EditorDirection
function PathEditor:setSelectedSegmentYRotationMove(angle, direction)
    local pivotPos, firstPos = self:getSelectedSegment(direction)

    if pivotPos == nil or firstPos == nil then
        return
    end

    local points = self.points
    local numPoints = #points
    local firstIndex = self.selectedIndex
    local lastIndex = numPoints
    local step = 1

    if direction == EditorDirection.NEGATIVE then
        firstIndex = firstIndex - 1
        lastIndex  = 1
        step       = -1
        angle      = angle + 180
    end

    local px = pivotPos[1]
    local pz = pivotPos[3]
    local yaw = EditorUtils.getWorldYaw(px, pz, firstPos[1], firstPos[3])

    local delta = yaw - math.rad(angle)
    local cosA, sinA = math.cos(delta), math.sin(delta)
    local dx, dz = {}, {}

    for i = firstIndex, lastIndex, step do
        local prev = points[i - step]
        local cur  = points[i]

        if prev == nil or cur == nil then
            break
        end

        dx[i] = cur[1] - prev[1]
        dz[i] = cur[3] - prev[3]
    end

    local prevX, prevZ = px, pz

    for i = firstIndex, lastIndex, step do
        local odx, odz = dx[i], dz[i]

        if odx == nil or odz == nil then
            break
        end

        local rdx = odx * cosA - odz * sinA
        local rdz = odx * sinA + odz * cosA
        local cur = points[i]

        cur[1] = prevX + rdx
        cur[3] = prevZ + rdz

        prevX, prevZ = cur[1], cur[3]
    end

    self:updateBorder()
    self:updateDisplayText()
    self:setHasChanged(true)
end

---@param startPos? number[]
---@param endPos? number[]
---@param targetPos number[]
---@param targetAngle? number
---@param targetHeight? number
---@return number x
---@return number y
---@return number z
function PathEditor:calculateTargetPosition(startPos, endPos, targetPos, targetAngle, targetHeight)
    local isInputAngle, isInputHeight, isInputDirZ = self.isInputAngle, self.isInputHeight, self.isInputDirZ

    ---@type number[]
    targetPos = table.clone(targetPos)

    local followHeight = isInputHeight or targetHeight ~= nil

    if endPos ~= nil then
        local followAngle = targetAngle ~= nil or (startPos ~= nil and isInputAngle)
        local followDirZ = isInputDirZ and startPos ~= nil

        if followDirZ then
            ---@cast startPos -?

            targetPos[1], targetPos[3] = EditorUtils.calculateTargetPosXZ(targetPos, startPos, endPos)
        end

        if followAngle then
            ---@cast startPos -?

            targetAngle = targetAngle or EditorUtils.calculateTargetAngle(startPos, endPos)
            ---@cast targetAngle -?

            targetPos[2] = EditorUtils.calculateTargetHeightUsingAngle(endPos, targetPos, targetAngle)
        elseif followHeight then
            targetPos[2] = targetHeight or endPos[2]
        end
    elseif startPos ~= nil then
        if followHeight then
            targetPos[2] = targetHeight or startPos[2]
        end
    end

    return targetPos[1], targetPos[2], targetPos[3]
end

function PathEditor:drawLines()
    local lineColor = Editor.COLOR.LINE_DEFAULT
    local points = self.points
    local numPoints = #points
    local selectedIndex = self.selectedIndex
    local mode = self.mode

    local defaultColor = Editor.COLOR.POINT_DEFAULT
    local selectedColor = Editor.COLOR.POINT_SELECTED
    local radius = Editor.RADIUS.POINT
    local selectedRadius = Editor.RADIUS.POINT_SELECTED

    if mode == EditorMode.MOVE_AREA or mode == EditorMode.ROTATE_AREA then
        radius = 0
        selectedRadius = 0
        selectedColor = defaultColor
    end

    for i = 1, numPoints do
        local pos = points[i]
        local nextPos = points[i + 1]
        local isSelected = i == selectedIndex
        local color = isSelected and selectedColor or defaultColor
        local lineOffsetY = isSelected and numPoints == 1 and 1 or nil

        EditorUtils.drawPointPosWithTerrainLine(pos, nil, radius, nil, lineOffsetY, color, false)

        if isSelected then
            EditorUtils.drawPointPosWithTerrainLine(pos, nil, selectedRadius, nil, nil, selectedColor, false)
        end

        if nextPos ~= nil then
            EditorUtils.drawLinePos(pos, nextPos, nil, lineColor, false)
        end
    end
end

function PathEditor:drawPoints()
    local mode = self.mode
    local points = self.points
    local numPoints = #points

    local selectedIndex = self.selectedIndex
    local selectedPos = points[selectedIndex]
    local nextPos = selectedIndex and points[selectedIndex + 1]
    local prevPos = selectedIndex and points[selectedIndex - 1]
    local direction = self.placementDirection

    local textOffsetY = 0.35
    local textColor = Editor.COLOR.TEXT_DEFAULT

    if mode == EditorMode.CREATE_POINT then
        local targetPos = self:getTargetPos()

        if targetPos ~= nil then
            local color = Editor.COLOR.POINT_SELECTED

            if numPoints == 0 then
                EditorUtils.drawPointPosWithTerrainLine(targetPos, nil, Editor.RADIUS.POINT_SELECTED, nil, 1, color, false)
            else
                EditorUtils.drawPointPosWithTerrainLine(targetPos, nil, Editor.RADIUS.POINT_SELECTED, nil, nil, color, false)
            end

            if selectedPos ~= nil then
                if direction == 1 then
                    EditorUtils.drawLineWithArrowPos(selectedPos, targetPos, nil, nil, nil, color, false)
                    EditorUtils.drawLineCenterPosAngleText(selectedPos, targetPos, textOffsetY, textColor)

                    if nextPos ~= nil then
                        EditorUtils.drawLineWithArrowPos(targetPos, nextPos, nil, nil, nil, color, false)
                        EditorUtils.drawLineCenterPosAngleText(targetPos, nextPos, textOffsetY, textColor)
                    end
                    if prevPos ~= nil then
                        EditorUtils.drawArrowPosDirection(prevPos, selectedPos, nil, nil, nil, Editor.COLOR.LINE_DEFAULT, false)
                    end
                else
                    EditorUtils.drawLineWithArrowPos(targetPos, selectedPos, nil, nil, nil, color, false)
                    EditorUtils.drawLineCenterPosAngleText(targetPos, selectedPos, textOffsetY, textColor)

                    if prevPos ~= nil then
                        EditorUtils.drawLineWithArrowPos(prevPos, targetPos, nil, nil, nil, color, false)
                        EditorUtils.drawLineCenterPosAngleText(prevPos, targetPos, textOffsetY, textColor)
                    end
                    if nextPos ~= nil then
                        EditorUtils.drawArrowPosDirection(selectedPos, nextPos, nil, nil, nil, Editor.COLOR.LINE_DEFAULT, false)
                    end
                end
            end
        end
    elseif mode == EditorMode.MOVE_POINT then
        local targetPos = self:getTargetPos()

        if targetPos ~= nil then
            local lineColor = Editor.COLOR.LINE_SELECTED

            EditorUtils.drawPointPosWithTerrainLine(targetPos, nil, Editor.RADIUS.POINT_SELECTED, nil, nil, Editor.COLOR.POINT_SELECTED, false)

            if prevPos ~= nil then
                local startPos = points[selectedIndex - 2]

                EditorUtils.drawLineWithArrowPos(prevPos, targetPos, nil, nil, nil, lineColor, false)

                if startPos ~= nil then
                    EditorUtils.drawArrowPosDirection(startPos, prevPos, nil, nil, nil, Editor.COLOR.LINE_DEFAULT, false)
                end

                EditorUtils.drawLineCenterPosAngleText(prevPos, targetPos, textOffsetY, textColor)
            end

            if nextPos ~= nil then
                EditorUtils.drawLineWithArrowPos(targetPos, nextPos, nil, nil, nil, lineColor, false)
                EditorUtils.drawLineCenterPosAngleText(targetPos, nextPos, textOffsetY, textColor)
            end
        end
    elseif mode == EditorMode.SELECT_POINT then
        if selectedPos ~= nil then
            if nextPos ~= nil then
                EditorUtils.drawArrowPosDirection(selectedPos, nextPos, nil, nil, nil, Editor.COLOR.LINE_DEFAULT, false)
                EditorUtils.drawLineCenterPosAngleText(selectedPos, nextPos, textOffsetY, textColor, 0.012)
            end

            if prevPos ~= nil then
                EditorUtils.drawLineWithArrowPos(prevPos, selectedPos, nil, nil, nil, Editor.COLOR.LINE_SELECTED, false)
                EditorUtils.drawLineCenterPosAngleText(prevPos, selectedPos, textOffsetY, Editor.COLOR.TEXT_SELECTED, nil, true)
                EditorUtils.drawLineCenterPosAngleText(prevPos, selectedPos, textOffsetY, Editor.COLOR.TEXT_SELECTED)

                local startPos = points[selectedIndex - 2]

                if startPos ~= nil then
                    EditorUtils.drawArrowPosDirection(startPos, prevPos, nil, nil, nil, Editor.COLOR.LINE_DEFAULT, false)
                    EditorUtils.drawLineCenterPosAngleText(startPos, prevPos, textOffsetY, textColor, 0.012)
                end
            end
        end

        local index = self:getNearestMouseOverIndex()
        local targetPos = points[index]

        if targetPos ~= nil and index ~= selectedIndex then
            EditorUtils.drawPointPos(targetPos, nil, Editor.RADIUS.POINT_OVER, nil, nil, Editor.COLOR.POINT_SELECTED, false)
        end
    end
end

function PathEditor:updateActionEvents()
    PathEditor:superClass().updateActionEvents(self)

    local hasValidSegments = #self.points > 1
    local isSelectedPoint = self.selectedIndex ~= nil
    local mode = self.mode

    if mode == EditorMode.NONE then
        return
    end

    if mode == EditorMode.CREATE_POINT then
        self:updateActionEvent(self.inputEventPrimary, true, Editor.L10N_SYMBOL.PLACE_POINT)
        self:updateActionEvent(self.inputEventCancel, true)
        self:updateActionEvent(self.inputEventDelete, isSelectedPoint)

        self:updateActionEvent(self.inputEventPrevNextAxis, hasValidSegments, Editor.L10N_SYMBOL.CHANGE_DIRECTION)
        self:updateActionEvent(self.inputEventUpDownAxis, isSelectedPoint, Editor.L10N_SYMBOL.MOVE_VERTICAL, nil, GS_PRIO_NORMAL)
        if self.isMouseMode then
            self:updateActionEvent(self.inputEventLeftRightAxis, isSelectedPoint, Editor.L10N_SYMBOL.MOVE_HORIZONTAL, nil, GS_PRIO_NORMAL)
        end

        self:updateActionEvent(self.inputEventLevel, isSelectedPoint, nil, nil, GS_PRIO_LOW)
        self:updateActionEvent(self.inputEventAngle, isSelectedPoint and hasValidSegments, nil, nil, GS_PRIO_LOW)
        self:updateActionEvent(self.inputEventDirZ, isSelectedPoint and hasValidSegments, nil, nil, GS_PRIO_LOW)
    elseif mode == EditorMode.SELECT_POINT then
        self:updateActionEvent(self.inputEventPrimary, true, Editor.L10N_SYMBOL.SELECT_POINT)
        self:updateActionEvent(self.inputEventExit, true)
        self:updateActionEvent(self.inputEventDelete, isSelectedPoint)
        self:updateActionEvent(self.inputEventMove, isSelectedPoint)

        self:updateActionEvent(self.inputEventPrevNextAxis, isSelectedPoint, Editor.L10N_SYMBOL.CREATE_POINT)
        self:updateActionEvent(self.inputEventUpDownAxis, isSelectedPoint, Editor.L10N_SYMBOL.MOVE_VERTICAL, nil, GS_PRIO_NORMAL)

        if self.isMouseMode then
            self:updateActionEvent(self.inputEventLeftRightAxis, isSelectedPoint, Editor.L10N_SYMBOL.MOVE_HORIZONTAL, nil, GS_PRIO_NORMAL)
        end
    elseif mode == EditorMode.MOVE_POINT then
        self:updateActionEvent(self.inputEventPrimary, true, Editor.L10N_SYMBOL.SET_NEW_POSITION)
        self:updateActionEvent(self.inputEventCancel, true)

        self:updateActionEvent(self.inputEventUpDownAxis, true, Editor.L10N_SYMBOL.MOVE_VERTICAL, true)
        self:updateActionEvent(self.inputEventLeftRightAxis, true, Editor.L10N_SYMBOL.MOVE_HORIZONTAL, true)

        self:updateActionEvent(self.inputEventAngle, hasValidSegments, nil, nil, GS_PRIO_LOW)
        self:updateActionEvent(self.inputEventDirZ, hasValidSegments, nil, nil, GS_PRIO_LOW)
        self:updateActionEvent(self.inputEventLevel, true, nil, nil, GS_PRIO_LOW)
    elseif mode == EditorMode.MOVE_AREA then
        self:updateActionEvent(self.inputEventCancel, true)

        self:updateActionEvent(self.inputEventUpDownAxis, true, Editor.L10N_SYMBOL.MOVE_VERTICAL, true)
        self:updateActionEvent(self.inputEventLeftRightAxis, true, Editor.L10N_SYMBOL.MOVE_HORIZONTAL, true)
    end
end

function PathEditor:draw()
    local mode = self.mode

    if mode ~= EditorMode.NONE then
        self:drawLines()

        if mode ~= EditorMode.MOVE_AREA and mode ~= EditorMode.ROTATE_AREA then
            self:drawPoints()
        end
    end

    PathEditor:superClass().draw(self)
end

function PathEditor:updateData()
    EditorUtils.setTextInputNumber(self.widthInputElement, self.area.width, 1)
    EditorUtils.setTextInputNumber(self.forceAngleInputElement, self.forceAngle, 2)

    PathEditor:superClass().updateData(self)
end

function PathEditor:updatePositionPanel()
    local mode = self.mode
    local visible = mode ~= EditorMode.NONE and mode ~= EditorMode.MOVE_AREA and mode ~= EditorMode.ROTATE_AREA

    if not visible then
        self.positionPanelElement:setVisible(false)
        return
    end

    self.positionPanelElement:setVisible(true)

    local selectedIndex = self.selectedIndex
    local enabled = visible and selectedIndex ~= nil and (mode == EditorMode.SELECT_POINT or mode == EditorMode.MOVE_POINT)

    self.positionPanelElement:setDisabled(not enabled)
end

function PathEditor:updateOptionPanel()
    local mode = self.mode

    if mode == EditorMode.NONE or mode == EditorMode.MOVE_AREA or mode == EditorMode.ROTATE_AREA then
        self.optionPanelElement:setVisible(false)
        return
    end

    self.optionPanelElement:setVisible(true)

    local isEditMode = (mode == EditorMode.SELECT_POINT or mode == EditorMode.MOVE_POINT)
    local selectedIndex = self.selectedIndex
    local numPoints = #self.points
    local disableButton = not (isEditMode and selectedIndex ~= nil and selectedIndex > 1)

    self.splitSegmentButton:setDisabled(disableButton)

    self.segmentRotationNegXMoveButton:setDisabled(disableButton)
    self.segmentRotationNegXFollowButton:setDisabled(disableButton)

    self.segmentRotationPosXButton:setDisabled(disableButton)
    self.segmentRotationNegXButton:setDisabled(disableButton)

    self.segmentRotationPosXFollowButton:setDisabled(disableButton)
    self.segmentRotationPosXMoveButton:setDisabled(disableButton)

    self.segmentRotationNegYMoveButton:setDisabled(disableButton)
    self.segmentRotationPosYButton:setDisabled(disableButton)
    self.segmentRotationNegYButton:setDisabled(disableButton)
    self.segmentRotationPosYMoveButton:setDisabled(disableButton)

    self.cameraStartButton:setDisabled(numPoints < 2)
    self.cameraMiddleButton:setDisabled(numPoints < 3)
    self.cameraEndButton:setDisabled(numPoints < 2)
end

---@param binding Binding
function PathEditor:onInputEventUpDownAxis(action, _, _, _, _, _, binding)
    local mode = self.mode
    local isPositiveDirection = binding.axisDirection == 1

    if mode == EditorMode.MOVE_AREA then
        if isPositiveDirection then
            self:moveAllPointsY(self.stepMoveY)
        else
            self:moveAllPointsY(-self.stepMoveY)
        end
    else
        PathEditor:superClass().onInputEventUpDownAxis(self, action, nil, nil, nil, nil, nil, binding)
    end
end

---@param binding Binding
function PathEditor:onInputEventLeftRightAxis(action, _, _, _, _, _, binding)
    local mode = self.mode
    local isPositiveDirection = binding.axisDirection == 1

    if mode == EditorMode.MOVE_AREA then
        if isPositiveDirection then
            self:moveAllPointsXZUsingCamera(-self.stepMoveXZ)
        else
            self:moveAllPointsXZUsingCamera(self.stepMoveXZ)
        end
    else
        PathEditor:superClass().onInputEventLeftRightAxis(self, action, nil, nil, nil, nil, nil, binding)
    end
end

---@param element TextInputElement
function PathEditor:onTextInputPressed(element)
    if element == self.widthInputElement then
        local value = EditorUtils.getTextInputNumber(element, 1, self.area.width, 2, 100)
        ---@cast value -?

        self.area.width = value
        EditorUtils.setTextInputNumber(element, value, 1)
        self:updateBorder()
        self:setHasChanged(true)
    elseif element == self.forceAngleInputElement then
        local value = EditorUtils.getTextInputNumber(element, 2, self.forceAngle, -65, 65)
        ---@cast value -?

        self.forceAngle = value
        EditorUtils.setTextInputNumber(element, value, 2)
    else
        PathEditor:superClass().onTextInputPressed(self, element)
    end
end

---@param state number
---@param element BinaryOptionElement
function PathEditor:onPressedOption(state, element)
    if element == self.forceAngleOptionElement then
        self.useForceAngle = element:getIsChecked()
    else
        PathEditor:superClass().onPressedOption(self, state, element)
    end
end

function PathEditor:onClickSetPointPosition()
    local selectedPos = self.points[self.selectedIndex]

    if selectedPos ~= nil then
        ---@param x number
        ---@param y number
        ---@param z number
        local function callback(x, y, z)
            self:setSelectedPointXYZ(x, y, z)
        end

        g_setPositionDialog:setCallback(callback)
        g_setPositionDialog:show(selectedPos[1], selectedPos[2], selectedPos[3])
    end
end

---@param element ButtonElement
function PathEditor:onClickSegmentRotationX(element)
    if self.selectedIndex == nil then
        return
    end

    local angle = self:getSelectedSegmentAngleX()

    if angle ~= nil then
        ---@type EditorDirection
        local direction = element == self.segmentRotationPosXButton and EditorDirection.POSITIVE or EditorDirection.NEGATIVE

        ---@param value number
        local function callback(value)
            self:setSelectedSegmentRotationX(value, direction)
        end

        g_setNumberDialog:setCallback(callback)
        g_setNumberDialog:show(angle, -65, 65, 2, g_i18n:getText('ui_setAngle'))
    end
end

---@param element ButtonElement
function PathEditor:onClickSegmentRotationXFollow(element)
    local angle = self:getSelectedSegmentAngleX()

    if angle ~= nil then
        ---@type EditorDirection
        local direction = element == self.segmentRotationPosXFollowButton and EditorDirection.POSITIVE or EditorDirection.NEGATIVE

        ---@param value number
        local function callback(value)
            self:setSelectedSegmentRotationXFollow(value, direction)
        end

        g_setNumberDialog:setCallback(callback)
        g_setNumberDialog:show(angle, -65, 65, 2, g_i18n:getText('ui_setAngle'))
    end
end

---@param element ButtonElement
function PathEditor:onClickSegmentRotationXMove(element)
    local angle = self:getSelectedSegmentAngleX()

    if angle ~= nil then
        local direction = element == self.segmentRotationNegXMoveButton and -1 or 1

        ---@param value number
        local function callback(value)
            self:setSelectedSegmentRotationXMove(value, direction)
        end

        g_setNumberDialog:setCallback(callback)
        g_setNumberDialog:show(angle, -65, 65, 2, g_i18n:getText('ui_setAngle'))
    end
end

---@param element ButtonElement
function PathEditor:onClickCameraPosition(element)
    local points = self.points
    local numPoints = #points

    if numPoints < 2 then
        return
    end

    local startPos, endPos

    if element == self.cameraStartButton then
        startPos = points[1]
        endPos = points[2]
    elseif element == self.cameraEndButton then
        startPos = points[numPoints - 1]
        endPos = points[numPoints]
    elseif numPoints > 2 then
        local index = math.ceil(numPoints / 2)
        startPos = points[index - 1]
        endPos = points[index]
    end

    if startPos ~= nil and endPos ~= nil then
        local rotY = EditorUtils.getWorldYawPos(startPos, endPos)

        if element == self.cameraStartButton then
            self.camera:setCameraPositionWithRotationY(startPos[1], startPos[3], rotY)
        else
            self.camera:setCameraPositionWithRotationY(endPos[1], endPos[3], rotY)
        end
    end
end

---@param element ButtonElement
function PathEditor:onClickSegmentRotationY(element)
    local angle = self:getSelectedSegmentAngleY()

    if angle ~= nil then
        local callback = function (value)
            if value < 0 then
                value = value + 360
            end

            if element == self.segmentRotationNegYMoveButton then
                self:setSelectedSegmentYRotationMove(value, EditorDirection.NEGATIVE)
            elseif element == self.segmentRotationNegYButton then
                self:setSelectedSegmentYRotation(value, EditorDirection.NEGATIVE)
            elseif element == self.segmentRotationPosYButton then
                self:setSelectedSegmentYRotation(value, EditorDirection.POSITIVE)
            elseif element == self.segmentRotationPosYMoveButton then
                self:setSelectedSegmentYRotationMove(value, EditorDirection.POSITIVE)
            end
        end

        g_setNumberDialog:setCallback(callback)
        g_setNumberDialog:show(angle, -360, 360, 2, g_i18n:getText('ui_setAngle'))
    end
end

---@param element ButtonElement
function PathEditor:onClickMoveSelectedPoint(element)
    if element.name == 'up' then
        self:moveSelectedPointDirection(0, self.stepMoveY, 0)
    elseif element.name == 'down' then
        self:moveSelectedPointDirection(0, -self.stepMoveY, 0)
    elseif element.name == 'left' then
        self:moveSelectedPointXZUsingCamera(self.stepMoveXZ)
    elseif element.name == 'right' then
        self:moveSelectedPointXZUsingCamera(-self.stepMoveXZ)
    end
end
