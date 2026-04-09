---@class WaterplaneEditor : Editor
---@field superClass fun(): Editor
---
---@field planeRootNode number
---
---@field waterplane LandscapingWaterplane
---@field targetInputElement TextInputElement
---@field colorOptionElement MultiTextOptionElement
---@field visibleOptionElement BinaryOptionElement
---@field splitSegmentButton ButtonElement
---@field segmentRotationPosXButton ButtonElement
---@field segmentRotationNegXButton ButtonElement
---@field alignWorldAxesOptionElement BinaryOptionElement
---@field useAlignWorldAxes boolean
---
---@field borderColor number[]
---@field borderDecalColor number[]
WaterplaneEditor = {}

WaterplaneEditor.CLASS_NAME = 'WaterplaneEditor'
WaterplaneEditor.XML_FILENAME = g_modDirectory .. 'data/gui/editor/WaterplaneEditor.xml'

local WaterplaneEditor_mt = Class(WaterplaneEditor, Editor)

---@return WaterplaneEditor
---@nodiscard
function WaterplaneEditor.new()
    local self = Editor.new(WaterplaneEditor_mt)
    ---@cast self WaterplaneEditor

    self.numPointsLimit = LandscapingAreaPolygon.MAX_NUM_POINTS
    self.useAlignWorldAxes = false

    self.planeRootNode = createTransformGroup('editor_waterplane_root')
    link(getRootNode(), self.planeRootNode)

    self.borderColor = { 0, 0.25, 0.8, 1 }
    self.borderDecalColor = { 0, 0.25, 0.8, 0.75 }

    return self
end

---@param forceUpdate? boolean
function WaterplaneEditor:updateShapes(forceUpdate)
    if self.mode ~= EditorMode.NONE then
        self:deleteShapes()
        return
    end

    if self:getHasShapes() and not forceUpdate then
        return
    end

    self:createShapes()
end

---@return boolean
---@nodiscard
function WaterplaneEditor:getHasShapes()
    return getNumOfChildren(self.planeRootNode) == 2
end

function WaterplaneEditor:createShapes()
    if self:getHasShapes() then
        self:deleteShapes()
    end

    if #self.points > 2 then
        local waterplane = self.waterplane
        local vertices = waterplane:getVertices()

        LandscapingUtils.createWaterplaneShapesFromVertices(self.planeRootNode, vertices, waterplane.color)

        setWorldTranslation(self.planeRootNode, 0, waterplane.targetY, 0)
    end
end

function WaterplaneEditor:deleteShapes()
    LandscapingUtils.deleteWaterplaneShapes(self.planeRootNode)
end

function WaterplaneEditor:updateBorder()
    self.waterplane:updateAreaBorder(self.borderShape, self.borderRootNode, self.borderChildNodes)
end

function WaterplaneEditor:onGuiSetupFinished()
    WaterplaneEditor:superClass().onGuiSetupFinished(self)

    local texts = {}

    for _, data in pairs(LandscapingWaterplane.COLOR_DATA) do
        table.insert(texts, data.name)
    end

    self.colorOptionElement:setTexts(texts)
end

---@param waterplane LandscapingWaterplane
---@param showInGameMenuWhenClosed? boolean
function WaterplaneEditor:show(waterplane, showInGameMenuWhenClosed)
    self.waterplane = waterplane
    self.points = waterplane.points
    self.showInGameMenuWhenClosed = showInGameMenuWhenClosed or false

    g_gui:showGui(self.CLASS_NAME)
end

function WaterplaneEditor:onOpen()
    WaterplaneEditor:superClass().onOpen(self)

    self:setMode(EditorMode.NONE)

    g_landscapingManager:setWaterplanesVisible(false)

    self:updateBorderColor()
    self:updateBorder()
    self:setBorderVisibility(true)
    self:updateShapes()
    self:updateDisplayText()

    ---@type GuiElement?
    local focusedElement = FocusManager:getFocusedElement()

    if focusedElement == nil or focusedElement.name == self.CLASS_NAME or focusedElement.disabled then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.nameInputElement)
        self:setSoundSuppressed(false)
    end
end

function WaterplaneEditor:onClose()
    self:deleteShapes()

    g_landscapingManager:setWaterplanesVisible(true)

    self:setBorderVisibility(false)

    self.waterplane = nil
    self.points = {}

    WaterplaneEditor:superClass().onClose(self)
end

---@param mode EditorMode
function WaterplaneEditor:setMode(mode)
    local previousMode = self.mode

    if mode == EditorMode.SELECT_POINT and #self.points == 0 then
        self.selectedIndex = nil
        self.placementDirection = EditorDirection.POSITIVE
        mode = EditorMode.CREATE_POINT
    end

    self.mode = mode

    local changed = mode ~= previousMode

    if changed and (mode == EditorMode.NONE or previousMode == EditorMode.NONE) then
        self:registerActionEvents()
        self:updateBorderColor()
    else
        self:updateActionEvents()
    end

    if changed then
        self:updateShapes()
    end

    self:updatePanels()
    self:updateDisplayText()
end

function WaterplaneEditor:getName()
    return self.waterplane:getName()
end

---@param name string
function WaterplaneEditor:setName(name)
    self.waterplane.name = name
end

---@return number x
---@return number z
function WaterplaneEditor:getCameraFocusWorldPositionXZ()
    return self.waterplane:getCameraFocusWorldPositionXZ()
end

function WaterplaneEditor:updateData()
    self.colorOptionElement:setState(self.waterplane.color)
    self.visibleOptionElement:setIsChecked(self.waterplane.visible)

    local targetY = self:getTargetY()

    if targetY ~= math.huge then
        EditorUtils.setTextInputNumber(self.targetInputElement, targetY, 2)
    else
        self.targetInputElement:setText('')
    end

    WaterplaneEditor:superClass().updateData(self)
end

function WaterplaneEditor:updateControlPanel()
    local visible = self.mode == EditorMode.NONE

    self.controlPanelElement:setVisible(visible)

    if visible then
        local disabled = not (self.waterplane:getIsValid() and self.hasChanged)

        self.saveButtonElement:setDisabled(disabled)

        if self.waterplane:getIsRegistered() then
            self.saveButtonElement:setText(Editor.L10N_SYMBOL.SAVE_CHANGES)
        else
            self.saveButtonElement:setText(Editor.L10N_SYMBOL.SAVE)
        end

        self.moveButtonElement:setDisabled(#self.points < 3)
    end
end

function WaterplaneEditor:updateDataPanel()
    ---@diagnostic disable-next-line: param-type-mismatch
    PolygonEditor.updateDataPanel(self)
end

function WaterplaneEditor:updatePositionPanel()
    ---@diagnostic disable-next-line: param-type-mismatch
    PolygonEditor.updatePositionPanel(self)
end

function WaterplaneEditor:updateOptionPanel()
    ---@diagnostic disable-next-line: param-type-mismatch
    PolygonEditor.updateOptionPanel(self)
end

function WaterplaneEditor:onClickSave()
    if self.waterplane:getIsValid() then
        if self.waterplane:getIsRegistered() then
            g_landscapingManager:updateWaterplane(self.waterplane:clone())
        else
            if g_landscapingManager:getCanCreateWaterplane() then
                g_landscapingManager:registerWaterplane(self.waterplane:clone())
            else
                InfoDialog.show(g_i18n:getText('ui_waterplanesLimitWarning'), nil, nil, DialogElement.TYPE_WARNING)
                return
            end
        end

        self:setHasChanged(false)
    end
end

---@param state number
function WaterplaneEditor:onClickVisibleOption(state)
    self.waterplane.visible = state == CheckedOptionElement.STATE_CHECKED
    self:setHasChanged(true)
end

---@param state number
function WaterplaneEditor:onClickColorOption(state)
    self.waterplane.color = state
    self:updateShapes(true)
    self:setHasChanged(true)
end

function WaterplaneEditor:updateBorderColor()
    setVisibility(self.borderRootNode, false)

    if self.mode == EditorMode.NONE then
        LandscapingUtils.setAreaBorderParameters(self.borderRootNode, BorderMode.GROUND_MESH_XRAY, self.borderColor, nil, self.borderDecalColor, nil)
    else
        LandscapingUtils.setAreaBorderParameters(self.borderRootNode, BorderMode.GROUND_MESH_XRAY, self.editBorderColor, nil, self.editBorderDecalColor, nil)
    end

    setVisibility(self.borderRootNode, true)
end

---@param direction EditorDirection
---@return number[]?
---@return number[]?
function WaterplaneEditor:getAlignmentSegment(direction)
    ---@diagnostic disable-next-line: param-type-mismatch
    return PolygonEditor.getAlignmentSegment(self, direction)
end

---@return number[]?
---@nodiscard
function WaterplaneEditor:getTargetPos()
    ---@diagnostic disable-next-line: param-type-mismatch
    return PolygonEditor.getTargetPos(self)
end

---@param direction EditorDirection
---@return number[]? startPos
---@return number[]? endPos
---@nodiscard
function WaterplaneEditor:getSelectedSegment(direction)
    ---@diagnostic disable-next-line: param-type-mismatch
    return PolygonEditor.getSelectedSegment(self, direction)
end

---@return number?
---@nodiscard
function WaterplaneEditor:getSelectedSegmentAngleY()
    ---@diagnostic disable-next-line: param-type-mismatch
    return PolygonEditor.getSelectedSegmentAngleY(self)
end

---@return number
---@nodiscard
function WaterplaneEditor:getTargetY()
    return self.waterplane.targetY
end

---@param value number
function WaterplaneEditor:setTargetY(value)
    self.waterplane.targetY = value

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

function WaterplaneEditor:createPoint()
    ---@diagnostic disable-next-line: param-type-mismatch
    PolygonEditor.createPoint(self)
end

function WaterplaneEditor:deleteSelectedPoint()
    ---@diagnostic disable-next-line: param-type-mismatch
    PolygonEditor.deleteSelectedPoint(self)
end

function WaterplaneEditor:splitSelectedSegment()
    ---@diagnostic disable-next-line: param-type-mismatch
    PolygonEditor.splitSelectedSegment(self)
end

function WaterplaneEditor:moveSelectedPoint()
    ---@diagnostic disable-next-line: param-type-mismatch
    PolygonEditor.moveSelectedPoint(self)
end

---@param dx number
---@param dy number
---@param dz number
function WaterplaneEditor:moveSelectedPointDirection(dx, dy, dz)
    ---@diagnostic disable-next-line: param-type-mismatch
    PolygonEditor.moveSelectedPointDirection(self, dx, dy, dz)
end

---@param x number
---@param z number
function WaterplaneEditor:setSelectedPointXZ(x, z)
    ---@diagnostic disable-next-line: param-type-mismatch
    PolygonEditor.setSelectedPointXZ(self, x, z)
end

---@param angle number
---@param direction number
function WaterplaneEditor:setSelectedSegmentRotationY(angle, direction)
    ---@diagnostic disable-next-line: param-type-mismatch
    PolygonEditor.setSelectedSegmentRotationY(self, angle, direction)
end

function WaterplaneEditor:drawLines()
    ---@diagnostic disable-next-line: param-type-mismatch
    PolygonEditor.drawLines(self)
end

function WaterplaneEditor:drawPoints()
    ---@diagnostic disable-next-line: param-type-mismatch
    PolygonEditor.drawPoints(self)
end

function WaterplaneEditor:draw()
    if self.mode ~= EditorMode.NONE then
        self:drawLines()
        self:drawPoints()
    end

    WaterplaneEditor:superClass().draw(self)
end

function WaterplaneEditor:updateActionEvents()
    ---@diagnostic disable-next-line: param-type-mismatch
    PolygonEditor.updateActionEvents(self)
end

function WaterplaneEditor:onInputEventPrimary()
    if self.mode == EditorMode.MOVE_AREA then
        local targetPos = self:getPlacementPos()

        if targetPos ~= nil then
            self:setTargetY(targetPos[2])
            self:setHasChanged(true)
            self:updateBorder()
        end
    else
        WaterplaneEditor:superClass().onInputEventPrimary(self)
    end
end

---@param binding Binding
function WaterplaneEditor:onInputEventUpDownAxis(action, _, _, _, _, _, binding)
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
        WaterplaneEditor:superClass().onInputEventUpDownAxis(self, action, nil, nil, nil, nil, nil, binding)
    end
end

---@param binding Binding
function WaterplaneEditor:onInputEventLeftRightAxis(action, _, _, _, _, _, binding)
    local mode = self.mode
    local isPositiveDirection = binding.axisDirection == 1

    if mode == EditorMode.MOVE_AREA then
        if isPositiveDirection then
            self:moveAllPointsXZUsingCamera(-self.stepMoveXZ)
        else
            self:moveAllPointsXZUsingCamera(self.stepMoveXZ)
        end
    else
        WaterplaneEditor:superClass().onInputEventLeftRightAxis(self, action, nil, nil, nil, nil, nil, binding)
    end
end

---@param element TextInputElement
function WaterplaneEditor:onTextInputPressed(element)
    if element == self.targetInputElement then
        local targetY = self:getTargetY()
        local default = targetY ~= math.huge and targetY or nil
        local value = EditorUtils.getTextInputNumber(element, 2, default, 0, 1024)

        if value ~= nil then
            self:setTargetY(value)
            self:setHasChanged(true)
            self:updateBorder()
            self:updateShapes(true)
        end
    else
        WaterplaneEditor:superClass().onTextInputPressed(self, element)
    end
end

---@param state number
---@param element BinaryOptionElement
function WaterplaneEditor:onPressedOption(state, element)
    if element == self.alignWorldAxesOptionElement then
        self.useAlignWorldAxes = element:getIsChecked()
    else
        WaterplaneEditor:superClass().onPressedOption(self, state, element)
    end
end

function WaterplaneEditor:onClickSegmentRotationY(element)
    ---@diagnostic disable-next-line: param-type-mismatch
    PolygonEditor.onClickSegmentRotationY(self, element)
end

---@param element ButtonElement
function WaterplaneEditor:onClickMoveSelectedPoint(element)
    ---@diagnostic disable-next-line: param-type-mismatch
    PolygonEditor.onClickMoveSelectedPoint(self, element)
end

function WaterplaneEditor:onClickSetPointPosition()
    ---@diagnostic disable-next-line: param-type-mismatch
    PolygonEditor.onClickSetPointPosition(self)
end
