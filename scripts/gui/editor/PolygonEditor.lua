---@class PolygonEditor : AreaEditor
---@field superClass fun(): AreaEditor
---@field new fun(): PolygonEditor
---
---@field area LandscapingAreaPolygon
---@field targetInputElement TextInputElement
---@field splitSegmentButton ButtonElement
---@field segmentRotationNegYButton ButtonElement
---@field segmentRotationPosYButton ButtonElement
---@field alignWorldAxesOptionElement BinaryOptionElement
---@field useAlignWorldAxes boolean
PolygonEditor = {}

PolygonEditor.CLASS_NAME = 'PolygonEditor'
PolygonEditor.XML_FILENAME = g_modDirectory .. 'data/gui/editor/PolygonEditor.xml'

local PolygonEditor_mt = Class(PolygonEditor, AreaEditor)

---@return PolygonEditor
---@nodiscard
function PolygonEditor.new()
    local self = AreaEditor.new(PolygonEditor_mt)
    ---@cast self PolygonEditor

    self.numPointsLimit = LandscapingAreaPolygon.MAX_NUM_POINTS
    self.useAlignWorldAxes = false

    return self
end

---@param direction EditorDirection
---@return number[]?
---@return number[]?
function PolygonEditor:getAlignmentSegment(direction)
    local points = self.points
    local numPoints = #points
    local selectedIndex = self.selectedIndex

    if selectedIndex == nil then
        return
    elseif numPoints == 1 then
        return
    end

    if direction == EditorDirection.POSITIVE then
        if selectedIndex == 1 then
            if numPoints > 2 then
                return points[numPoints], points[selectedIndex]
            end
        else
            return points[selectedIndex], points[selectedIndex - 1]
        end
    else
        if selectedIndex == numPoints then
            if numPoints > 2 then
                return points[selectedIndex], points[1]
            end
        else
            return points[selectedIndex + 1], points[selectedIndex]
        end
    end
end

---@return number[]?
---@nodiscard
function PolygonEditor:getTargetPos()
    local points = self.points
    local numPoints = #points
    local selectedIndex = self.selectedIndex
    local selectedPos = points[selectedIndex]
    local placementPos = self:getPlacementPos()
    local targetY = self:getTargetY()

    if placementPos ~= nil then
        if selectedPos ~= nil then
            if self.isInputAngle then
                local x, z = EditorUtils.calculateTargetPosXZAligned(selectedPos, placementPos, 2)
                placementPos[1] = x
                placementPos[3] = z
            elseif self.isInputDirZ and numPoints > 1 then
                local startPos, endPos = self:getAlignmentSegment(self.placementDirection)

                if startPos ~= nil and endPos ~= nil then
                    placementPos[1], placementPos[3] = EditorUtils.calculateTargetPosXZ(placementPos, startPos, endPos)
                end
            end
        end

        if targetY ~= math.huge then
            placementPos[2] = targetY
        end

        return placementPos
    end
end

function PolygonEditor:splitSelectedSegment()
    local selectedIndex = self.selectedIndex
    local points = self.points
    local numPoints = #points

    if selectedIndex ~= nil then
        local selectedPos = points[selectedIndex]
        local prevPos = points[selectedIndex - 1]

        if selectedIndex == 1 and numPoints > 2 then
            prevPos = points[numPoints]
        end

        if selectedPos and prevPos then
            local x, y, z = EditorUtils.getCenterOf(prevPos, selectedPos)

            table.insert(points, selectedIndex, { x, y, z })

            self:updateBorder()
            self:setHasChanged(true)
            self:setSelectedIndex(selectedIndex, true)
        end
    end
end

---@param direction EditorDirection
---@return number[]? startPos
---@return number[]? endPos
---@nodiscard
function PolygonEditor:getSelectedSegment(direction)
    local selectedIndex = self.selectedIndex
    local points = self.points
    local numPoints = #points
    local startPos, endPos

    if selectedIndex ~= nil then
        if selectedIndex == 1 then
            if numPoints > 2 then
                startPos = points[numPoints]
                endPos = points[1]
            end
        else
            startPos = points[selectedIndex - 1]
            endPos = points[selectedIndex]
        end
    end

    if direction == EditorDirection.POSITIVE then
        return startPos, endPos
    else
        return endPos, startPos
    end
end

---@return number?
---@nodiscard
function PolygonEditor:getSelectedSegmentAngleY()
    local startPos, endPos = self:getSelectedSegment(EditorDirection.POSITIVE)

    if startPos ~= nil and endPos ~= nil then
        return EditorUtils.getWorldRotYAngle(startPos, endPos)
    end
end

---@return number
---@nodiscard
function PolygonEditor:getTargetY()
    return self.area.targetY
end

---@param value number
function PolygonEditor:setTargetY(value)
    self.area.targetY = value

    if value ~= math.huge then
        local points = self.points

        if #points > 0 then
            for _, pos in ipairs(points) do
                pos[2] = value
            end
        end

        EditorUtils.setTextInputNumber(self.targetInputElement, value, 2)
    else
        self.targetInputElement:setText('')
    end
end

---@return boolean
function PolygonEditor:createPoint()
    local points = self.points
    local numPoints = #points
    local targetPos = self:getTargetPos()

    if targetPos ~= nil and numPoints <= self.numPointsLimit then
        local selectedIndex = self.selectedIndex
        local targetIndex = selectedIndex or 1

        if self:getTargetY() == math.huge then
            self:setTargetY(targetPos[2])
        end

        if selectedIndex ~= nil and self.placementDirection == EditorDirection.POSITIVE then
            targetIndex = targetIndex + 1
        end

        table.insert(points, targetIndex, targetPos)

        self:updateBorder()
        self:setHasChanged(true)
        self:setSelectedIndex(targetIndex, true)

        return true
    end

    return false
end

---@return boolean
function PolygonEditor:deleteSelectedPoint()
    local points = self.points
    local selectedIndex = self.selectedIndex

    if selectedIndex ~= nil and table.remove(points, selectedIndex) ~= nil then
        local numPoints = #points

        self:setHasChanged(true)

        if numPoints == 0 then
            self.selectedIndex = nil
            self.placementDirection = EditorDirection.POSITIVE
            self:setTargetY(math.huge)
            self:setMode(EditorMode.CREATE_POINT)
        elseif selectedIndex > numPoints then
            self:setSelectedIndex(numPoints, true)
        end

        self:updateBorder()

        return true
    end

    return false
end

function PolygonEditor:moveSelectedPoint()
    local selectedPos = self.points[self.selectedIndex]

    if selectedPos ~= nil then
        local targetPos = self:getTargetPos()

        if targetPos ~= nil then
            selectedPos[1] = targetPos[1]
            selectedPos[3] = targetPos[3]

            self:setMode(EditorMode.SELECT_POINT)
            self:updateBorder()
            self:setHasChanged(true)
        end
    end
end

---@param dx number
---@param dy number
---@param dz number
function PolygonEditor:moveSelectedPointDirection(dx, dy, dz)
    local selectedPos = self.points[self.selectedIndex]

    if selectedPos ~= nil then
        selectedPos[1] = selectedPos[1] + dx
        selectedPos[3] = selectedPos[3] + dz

        self:updateBorder()
        self:updateDisplayText()
        self:setHasChanged(true)
    end
end

---@param x number
---@param z number
function PolygonEditor:setSelectedPointXZ(x, z)
    local selectedPos = self.points[self.selectedIndex]

    if selectedPos ~= nil then
        selectedPos[1] = x
        selectedPos[3] = z

        self:updateBorder()
        self:updateDisplayText()
        self:setHasChanged(true)
    end
end

---@param angle number
---@param direction EditorDirection
function PolygonEditor:setSelectedSegmentRotationY(angle, direction)
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

function PolygonEditor:drawLines()
    local points = self.points
    local numPoints = #points
    local selectedIndex = self.selectedIndex
    local mode = self.mode

    local lineColor = Editor.COLOR.LINE_DEFAULT
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

        if isSelected and mode ~= EditorMode.MOVE_AREA then
            EditorUtils.drawPointPosWithTerrainLine(pos, nil, selectedRadius, nil, nil, selectedColor, false)
        end

        if i == numPoints and numPoints > 2 then
            nextPos = points[1]
        end

        if nextPos ~= nil then
            EditorUtils.drawLinePos(pos, nextPos, nil, lineColor, false)
        end
    end
end

function PolygonEditor:drawPoints()
    local points = self.points
    local numPoints = #points
    local mode = self.mode

    local selectedIndex = self.selectedIndex
    local selectedPos = points[selectedIndex]
    local nextPos = selectedIndex and points[selectedIndex + 1]
    local prevPos = selectedIndex and points[selectedIndex - 1]
    local direction = self.placementDirection

    if selectedIndex == 1 then
        if numPoints > 2 then
            prevPos = points[numPoints]
        end
    elseif selectedIndex == numPoints then
        if numPoints > 2 then
            nextPos = points[1]
        end
    end

    if mode == EditorMode.CREATE_POINT then
        local targetPos = self:getTargetPos()

        if targetPos ~= nil then
            local color = Editor.COLOR.POINT_SELECTED

            EditorUtils.drawPointPosWithTerrainLine(targetPos, nil, Editor.RADIUS.POINT_SELECTED, nil, nil, color, false)

            if selectedPos ~= nil then
                EditorUtils.drawLineWithArrowPos(selectedPos, targetPos, nil, nil, nil, color, false)
                EditorUtils.drawLinePos(selectedPos, targetPos, nil, color, false)

                if direction == 1 then
                    if nextPos ~= nil then
                        EditorUtils.drawLineWithArrowPos(targetPos, nextPos, nil, nil, nil, color, false)
                    end
                else
                    if prevPos ~= nil then
                        EditorUtils.drawLineWithArrowPos(targetPos, prevPos, nil, nil, nil, color, false)
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
                EditorUtils.drawLineWithArrowPos(prevPos, targetPos, nil, nil, nil, lineColor, false)
            end

            if nextPos ~= nil then
                EditorUtils.drawLinePos(targetPos, nextPos, nil, lineColor, false)
            end
        end
    elseif mode == EditorMode.SELECT_POINT then
        if selectedPos ~= nil and prevPos ~= nil then
            EditorUtils.drawLineWithArrowPos(prevPos, selectedPos, nil, nil, nil, Editor.COLOR.LINE_SELECTED, false)
        end

        local index = self:getNearestMouseOverIndex()
        local targetPos = points[index]

        if targetPos ~= nil and index ~= selectedIndex then
            EditorUtils.drawPointPos(targetPos, nil, Editor.RADIUS.POINT_OVER, nil, nil, Editor.COLOR.POINT_SELECTED, false)
        end
    elseif mode == EditorMode.MOVE_AREA then
        local placePos = self:getPlacementPos()

        if placePos ~= nil then
            local targetY = self:getTargetY()
            local targetYDiff = targetY - placePos[2]
            local targetPos = { placePos[1], targetY, placePos[3] }

            EditorUtils.drawPointPos(targetPos, nil, Editor.RADIUS.POINT_SELECTED, nil, nil, Editor.COLOR.POINT_DEFAULT, false)
            EditorUtils.drawPointPos(placePos, nil, Editor.RADIUS.POINT_OVER, nil, targetYDiff, Editor.COLOR.POINT_SELECTED, false)
        end
    end
end

function PolygonEditor:updateActionEvents()
    PolygonEditor:superClass().updateActionEvents(self)

    local numPoints = #self.points
    local hasValidSegments = numPoints > 1
    local isSelectedPoint = self.selectedIndex ~= nil
    local mode = self.mode


    if mode == EditorMode.CREATE_POINT then
        self:updateActionEvent(self.inputEventPrimary, true, Editor.L10N_SYMBOL.PLACE_POINT)
        self:updateActionEvent(self.inputEventExit, numPoints == 0)
        self:updateActionEvent(self.inputEventCancel, numPoints > 0)
        self:updateActionEvent(self.inputEventDelete, isSelectedPoint)

        self:updateActionEvent(self.inputEventPrevNextAxis, hasValidSegments, Editor.L10N_SYMBOL.CHANGE_DIRECTION)
        self:updateActionEvent(self.inputEventUpDownAxis, isSelectedPoint, Editor.L10N_SYMBOL.MOVE_VERTICAL, nil, GS_PRIO_NORMAL)
        if self.isMouseMode then
            self:updateActionEvent(self.inputEventLeftRightAxis, isSelectedPoint, Editor.L10N_SYMBOL.MOVE_HORIZONTAL, nil, GS_PRIO_NORMAL)
        end

        self:updateActionEvent(self.inputEventAngle, isSelectedPoint, Editor.L10N_SYMBOL.ALIGN_WORLD_AXES, nil, GS_PRIO_LOW)
        self:updateActionEvent(self.inputEventDirZ, isSelectedPoint and hasValidSegments, nil, nil, GS_PRIO_LOW)
    elseif mode == EditorMode.SELECT_POINT then
        self:updateActionEvent(self.inputEventPrimary, true, Editor.L10N_SYMBOL.SELECT_POINT)
        self:updateActionEvent(self.inputEventExit, true)
        self:updateActionEvent(self.inputEventDelete, isSelectedPoint)
        self:updateActionEvent(self.inputEventMove, isSelectedPoint)

        self:updateActionEvent(self.inputEventPrevNextAxis, isSelectedPoint, Editor.L10N_SYMBOL.CREATE_POINT)

        if self.isMouseMode then
            self:updateActionEvent(self.inputEventLeftRightAxis, isSelectedPoint, Editor.L10N_SYMBOL.MOVE_HORIZONTAL, nil, GS_PRIO_NORMAL)
        end
    elseif mode == EditorMode.MOVE_POINT then
        self:updateActionEvent(self.inputEventPrimary, true, Editor.L10N_SYMBOL.SET_NEW_POSITION)
        self:updateActionEvent(self.inputEventCancel, true)

        self:updateActionEvent(self.inputEventLeftRightAxis, true, Editor.L10N_SYMBOL.MOVE_HORIZONTAL, true)

        self:updateActionEvent(self.inputEventAngle, hasValidSegments, Editor.L10N_SYMBOL.ALIGN_WORLD_AXES, nil, GS_PRIO_LOW)
        self:updateActionEvent(self.inputEventDirZ, hasValidSegments, nil, nil, GS_PRIO_LOW)
    elseif mode == EditorMode.MOVE_AREA then
        self:updateActionEvent(self.inputEventPrimary, true, Editor.L10N_SYMBOL.SET_TARGET_HEIGHT)
        self:updateActionEvent(self.inputEventCancel, true)

        self:updateActionEvent(self.inputEventUpDownAxis, true, Editor.L10N_SYMBOL.MOVE_VERTICAL, true)
        self:updateActionEvent(self.inputEventLeftRightAxis, true, Editor.L10N_SYMBOL.MOVE_HORIZONTAL, true)
    end
end

function PolygonEditor:draw()
    local mode = self.mode

    if mode ~= EditorMode.NONE then
        self:drawLines()
        self:drawPoints()
    end

    PolygonEditor:superClass().draw(self)
end

function PolygonEditor:updateData()
    local targetY = self:getTargetY()

    if targetY ~= math.huge then
        EditorUtils.setTextInputNumber(self.targetInputElement, targetY, 2)
    else
        self.targetInputElement:setText('')
    end

    PolygonEditor:superClass().updateData(self)
end

function PolygonEditor:updatePositionPanel()
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

function PolygonEditor:updateOptionPanel()
    local mode = self.mode

    if mode == EditorMode.NONE or mode == EditorMode.MOVE_AREA or mode == EditorMode.ROTATE_AREA then
        self.optionPanelElement:setVisible(false)
        return
    end

    self.optionPanelElement:setVisible(true)

    local isEditMode = (mode == EditorMode.SELECT_POINT or mode == EditorMode.MOVE_POINT)
    local startPos, endPos = self:getSelectedSegment(EditorDirection.POSITIVE)
    local isSelectedSegment = startPos ~= nil and endPos ~= nil
    local disableButton = not (isEditMode and isSelectedSegment)

    self.splitSegmentButton:setDisabled(disableButton)

    self.segmentRotationPosYButton:setDisabled(disableButton)
    self.segmentRotationNegYButton:setDisabled(disableButton)
end

function PolygonEditor:onInputEventPrimary()
    if self.mode == EditorMode.MOVE_AREA then
        local targetPos = self:getPlacementPos()

        if targetPos ~= nil then
            self:setTargetY(targetPos[2])
            self:setHasChanged(true)
            self:updateBorder()
        end
    else
        PolygonEditor:superClass().onInputEventPrimary(self)
    end
end

---@param binding Binding
function PolygonEditor:onInputEventUpDownAxis(action, _, _, _, _, _, binding)
    local mode = self.mode
    local isPositiveDirection = binding.axisDirection == 1

    if mode == EditorMode.MOVE_AREA then
        local targetY = self:getTargetY()

        if targetY ~= math.huge then
            if isPositiveDirection then
                self:setTargetY(targetY + self.stepMoveY)
            else
                self:setTargetY(targetY - self.stepMoveY)
            end

            self:setHasChanged(true)
            self:updateBorder()
        end
    else
        PolygonEditor:superClass().onInputEventUpDownAxis(self, action, nil, nil, nil, nil, nil, binding)
    end
end

---@param binding Binding
function PolygonEditor:onInputEventLeftRightAxis(action, _, _, _, _, _, binding)
    local mode = self.mode
    local isPositiveDirection = binding.axisDirection == 1

    if mode == EditorMode.MOVE_AREA then
        if isPositiveDirection then
            self:moveAllPointsXZUsingCamera(-self.stepMoveXZ)
        else
            self:moveAllPointsXZUsingCamera(self.stepMoveXZ)
        end
    else
        PolygonEditor:superClass().onInputEventLeftRightAxis(self, action, nil, nil, nil, nil, nil, binding)
    end
end

---@param element TextInputElement
function PolygonEditor:onTextInputPressed(element)
    if element == self.targetInputElement then
        local targetY = self:getTargetY()
        local default = targetY ~= math.huge and targetY or nil
        local value = EditorUtils.getTextInputNumber(element, 2, default, 0, 1024)

        if value ~= nil then
            self:setTargetY(value)
            self:setHasChanged(true)
            self:updateBorder()
        end
    else
        PolygonEditor:superClass().onTextInputPressed(self, element)
    end
end

---@param state number
---@param element BinaryOptionElement
function PolygonEditor:onPressedOption(state, element)
    if element == self.alignWorldAxesOptionElement then
        self.useAlignWorldAxes = element:getIsChecked()
    else
        PolygonEditor:superClass().onPressedOption(self, state, element)
    end
end

---@param element ButtonElement
function PolygonEditor:onClickMoveSelectedPoint(element)
    if element.name == 'left' then
        self:moveSelectedPointXZUsingCamera(self.stepMoveXZ)
    elseif element.name == 'right' then
        self:moveSelectedPointXZUsingCamera(-self.stepMoveXZ)
    end
end

function PolygonEditor:onClickSetPointPosition()
    local selectedPos = self.points[self.selectedIndex]

    if selectedPos ~= nil then
        ---@param x number
        ---@param z number
        local function callback(x, _, z)
            self:setSelectedPointXZ(x, z)
        end

        g_setPositionDialog:setCallback(callback)
        g_setPositionDialog:show(selectedPos[1], nil, selectedPos[3])
    end
end

---@param element ButtonElement
function PolygonEditor:onClickSegmentRotationY(element)
    local angle = self:getSelectedSegmentAngleY()

    if angle ~= nil then
        ---@param value number
        local callback = function (value)
            if value < 0 then
                value = value + 360
            end

            if element == self.segmentRotationNegYButton then
                self:setSelectedSegmentRotationY(value, EditorDirection.NEGATIVE)
            elseif element == self.segmentRotationPosYButton then
                self:setSelectedSegmentRotationY(value, EditorDirection.POSITIVE)
            end
        end

        g_setNumberDialog:setCallback(callback)
        g_setNumberDialog:show(angle, -360, 360, 2, g_i18n:getText('ui_setAngle'))
    end
end
