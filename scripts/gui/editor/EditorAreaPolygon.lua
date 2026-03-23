---@class EditorAreaPolygon : EditorScreen
---@field area LandscapingAreaPolygon
---@field heightInput TextInputElement
---@field mode EditorAreaPolygonMode
---@field selectedIndex? number
---@field direction number
---@field maxNumPoints number
---@field superClass fun(): EditorScreen
EditorAreaPolygon = {}
EditorAreaPolygon.CLASS_NAME = 'EditorAreaPolygon'
EditorAreaPolygon.XML_FILENAME = g_modDirectory .. 'data/gui/editor/EditorAreaPolygon.xml'
EditorAreaPolygon.INPUT_CONTEXT = 'AREA_EDITOR_POLYGON'

---@enum EditorAreaPolygonMode
EditorAreaPolygon.MODE = {
    NONE = 0,
    SELECT = 1,
    ADD_POINT = 2,
    MOVE_POINT = 3,
    SET_POSITION = 4,
}

---@type table<EditorAreaPolygonMode, string>
EditorAreaPolygon.MODE_TEXT = {
    [EditorAreaPolygon.MODE.NONE] = 'NONE',
    [EditorAreaPolygon.MODE.SELECT] = 'SELECT',
    [EditorAreaPolygon.MODE.ADD_POINT] = 'ADD_POINT',
    [EditorAreaPolygon.MODE.MOVE_POINT] = 'MOVE_POINT',
    [EditorAreaPolygon.MODE.SET_POSITION] = 'SET_POSITION',
}

local EditorAreaPolygon_mt = Class(EditorAreaPolygon, EditorScreen)

---@param customMt? table
---@return EditorAreaPolygon
---@nodiscard
function EditorAreaPolygon.new(customMt)
    local self = EditorScreen.new(customMt or EditorAreaPolygon_mt)
    ---@cast self EditorAreaPolygon

    self.mode = EditorAreaPolygon.MODE.NONE
    self.selectedIndex = nil
    self.direction = 1
    self.maxNumPoints = LandscapingAreaPolygon.MAX_NUM_POINTS

    return self
end

function EditorAreaPolygon:onOpen()
    EditorScreen.onOpen(self)

    self:setMode(EditorAreaPolygon.MODE.NONE)

    self:updateHeightInput()
    self:updateAreaBorder()
    self:setBorderVisibility(true)
end

function EditorAreaPolygon:onClose()
    self:setBorderVisibility(false)

    EditorScreen.onClose(self)
end

---@param mode EditorAreaPolygonMode
function EditorAreaPolygon:setMode(mode)
    local points = self:getPoints()

    if mode == EditorAreaPolygon.MODE.SELECT and #points == 0 then
        self.selectedIndex = nil
        self.direction = 1
        mode = EditorAreaPolygon.MODE.ADD_POINT
    end

    self.mode = mode

    self:registerMenuActionEvents(self.mode == EditorAreaPolygon.MODE.NONE)
    self:updatePanels()
    self:updatePositionText()
end

---@return boolean
function EditorAreaPolygon:addPoint()
    local points = self:getPoints()

    if #points <= self.maxNumPoints and self.cursor.currentHitTerrain then
        local targetY = self:getTargetY()

        local point = { self.cursor.currentHitX, self.cursor.currentHitZ }
        local selectedIndex = self.selectedIndex
        local index = selectedIndex or 1

        if targetY == math.huge then
            self:setTargetY(self.cursor.currentHitY)
            self:updateHeightInput()
        end

        if selectedIndex ~= nil and self.direction == 1 then
            index = index + 1
        end

        table.insert(points, index, point)

        self:updateAreaBorder()
        self:updatePositionText()
        self:setHasChanged(true)

        self.selectedIndex = index

        self:updateMenuActionEvents()

        return true
    end

    return false
end

---@return boolean
function EditorAreaPolygon:deletePoint()
    local selectedIndex = self.selectedIndex
    local points = self:getPoints()

    if selectedIndex ~= nil and table.remove(points, selectedIndex) ~= nil then
        self:updateAreaBorder()
        self:setHasChanged(true)

        local numPoints = #points

        if numPoints == 0 then
            self:setTargetY(math.huge)
            self.selectedIndex = nil
            self.direction = 1

            self:setMode(EditorAreaPolygon.MODE.ADD_POINT)
        elseif selectedIndex > numPoints then
            self.selectedIndex = numPoints
        end

        self:updatePositionText()

        return true
    end

    return false
end

---@return boolean
function EditorAreaPolygon:movePoint()
    local points = self:getPoints()

    if self.cursor.currentHitTerrain then
        local point = points[self.selectedIndex]

        if point ~= nil then
            point[1], point[2] = self.cursor.currentHitX, self.cursor.currentHitZ

            self:setMode(EditorAreaPolygon.MODE.SELECT)
            self:updateAreaBorder()
            self:updatePositionText()
            self:setHasChanged(true)

            return true
        end
    end

    return false
end

---@param index? number
function EditorAreaPolygon:selectPoint(index)
    if self.selectedIndex ~= index then
        self.selectedIndex = index

        self:updateMenuActionEvents()
        self:updatePositionText()
    end
end

function EditorAreaPolygon:onPressCancel()
    if self.mode == EditorAreaPolygon.MODE.SELECT then
        self:setMode(EditorAreaPolygon.MODE.NONE)
    elseif self.mode == EditorAreaPolygon.MODE.ADD_POINT then
        local points = self:getPoints()

        if #points == 0 then
            self:setMode(EditorAreaPolygon.MODE.NONE)
        else
            self:setMode(EditorAreaPolygon.MODE.SELECT)
        end
    elseif self.mode == EditorAreaPolygon.MODE.MOVE_POINT then
        self:setMode(EditorAreaPolygon.MODE.SELECT)
    elseif self.mode == EditorAreaPolygon.MODE.SET_POSITION then
        self:setMode(EditorAreaPolygon.MODE.NONE)
    end
end

function EditorAreaPolygon:onPressAccept()
    if self.mode == EditorAreaPolygon.MODE.SELECT then
        self:selectPoint(self:getMouseOverIndex())
    elseif self.mode == EditorAreaPolygon.MODE.ADD_POINT then
        self:addPoint()
    elseif self.mode == EditorAreaPolygon.MODE.MOVE_POINT then
        self:movePoint()
    elseif self.mode == EditorAreaPolygon.MODE.SET_POSITION then
        self:setTargetHeight()
    else
        EditorScreen.onPressAccept(self)
    end
end

function EditorAreaPolygon:onPressMove()
    if self.selectedIndex ~= nil and self.mode == EditorAreaPolygon.MODE.SELECT then
        self:setMode(EditorAreaPolygon.MODE.MOVE_POINT)
    end
end

function EditorAreaPolygon:onPressDelete()
    if self.mode == EditorAreaPolygon.MODE.SELECT or self.mode == EditorAreaPolygon.MODE.ADD_POINT then
        self:deletePoint()
    end
end

function EditorAreaPolygon:onMenuPrev()
    if self.selectedIndex ~= nil and (self.mode == EditorAreaPolygon.MODE.SELECT or self.mode == EditorAreaPolygon.MODE.ADD_POINT) then
        self.direction = -1
        self:setMode(EditorAreaPolygon.MODE.ADD_POINT)
    end
end

function EditorAreaPolygon:onMenuNext()
    if self.selectedIndex ~= nil and (self.mode == EditorAreaPolygon.MODE.SELECT or self.mode == EditorAreaPolygon.MODE.ADD_POINT) then
        self.direction = 1
        self:setMode(EditorAreaPolygon.MODE.ADD_POINT)
    end
end

---@return number? index
function EditorAreaPolygon:getMouseOverIndex()
    local targetY = self:getTargetY()

    if self.cursor.currentHitTerrain and (not self.isMouseMode or not self.isMouseInMenu) and targetY ~= math.huge then
        local points = self:getPoints()
        local maxDistance = 0.025
        local mousePosX, mousePosY = self.cursor.mousePosX, self.cursor.mousePosY

        for index, pos in ipairs(points) do
            local sx, sy, sz = project(pos[1], targetY, pos[2])

            if sx > -1 and sx < 2 and sy > -1 and sy < 2 and sz <= 1 then
                local distance = MathUtil.getPointPointDistance(mousePosX, mousePosY, sx, sy)
                if distance < maxDistance then
                    return index
                end
            end
        end
    end
end

---@return number[]? point
---@return number index
function EditorAreaPolygon:getMouseOverPoint()
    local index = self:getMouseOverIndex()
    local points = self:getPoints()

    return points[index], index or 0
end

---@return boolean
function EditorAreaPolygon:setTargetHeight()
    if self.cursor.currentHitTerrain then
        self:setTargetY(self.cursor.currentHitY)

        self:updateHeightInput()
        self:updateAreaBorder()
        self:updatePositionText()
        self:setHasChanged(true)

        return true
    end

    return false
end

---@return number
---@nodiscard
function EditorAreaPolygon:getTargetY()
    return self.area.targetY
end

---@param value number
function EditorAreaPolygon:setTargetY(value)
    self.area.targetY = value
    self:updatePositionText()
end

---@return number[][]
---@nodiscard
function EditorAreaPolygon:getPoints()
    return self.area.points
end

function EditorAreaPolygon:onButtonPrimary()
    if self.mode ~= EditorAreaPolygon.MODE.NONE then
        self:onPressAccept()
    end
end

function EditorAreaPolygon:onButtonSecondary()
    if not self.isMouseMode or not self.isMouseInMenu then
        if self.mode == EditorAreaPolygon.MODE.NONE then
            self:setMode(EditorAreaPolygon.MODE.SELECT)
        else
            self:onPressCancel()
        end
    end
end

---@param value number
---@return boolean
function EditorAreaPolygon:moveSelectedPointY(value)
    local targetY = self:getTargetY()

    if targetY ~= nil then
        self:setTargetY(targetY + value)
        self:updateAreaBorder()
        self:setHasChanged(true)
        self:updateHeightInput()
        self:updatePositionText()

        return true
    end

    return false
end

---@param value number
---@return boolean
function EditorAreaPolygon:moveSelectedPointX(value)
    local targetY = self:getTargetY()
    local points = self:getPoints()

    if targetY ~= nil and #points > 0 then
        local rightX = math.cos(self.camera.cameraRotY) * value
        local rightZ = -math.sin(self.camera.cameraRotY) * value

        for _, pos in ipairs(points) do
            pos[1] = pos[1] + rightX
            pos[2] = pos[2] + rightZ
        end

        self:updateAreaBorder()
        self:updatePositionText()
        self:setHasChanged(true)

        return true
    end

    return false
end

function EditorAreaPolygon:onClickMoveUp()
    self:moveSelectedPointY(0.25)
end

function EditorAreaPolygon:onClickMoveDown()
    self:moveSelectedPointY(-0.25)
end

function EditorAreaPolygon:onClickMoveLeft()
    self:moveSelectedPointX(0.25)
end

function EditorAreaPolygon:onClickMoveRight()
    self:moveSelectedPointX(-0.25)
end

---@param binding Binding
function EditorAreaPolygon:onReleaseUpDown(action, _, _, _, _, _, binding)
    if self.mode == EditorAreaPolygon.MODE.NONE then
        EditorScreen.onReleaseUpDown(self, action)
    elseif self.mode == EditorAreaPolygon.MODE.SET_POSITION then
        if binding.axisDirection == -1 then
            self:onClickMoveDown()
        else
            self:onClickMoveUp()
        end
    end
end

---@param binding Binding
function EditorAreaPolygon:onReleaseLeftRight(action, _, _, _, _, _, binding)
    if self.mode == EditorAreaPolygon.MODE.NONE then
        EditorScreen.onReleaseLeftRight(self, action)
    elseif self.mode == EditorAreaPolygon.MODE.SET_POSITION then
        if binding.axisDirection == -1 then
            self:onClickMoveLeft()
        else
            self:onClickMoveRight()
        end
    end
end

---@return number[]?
---@nodiscard
function EditorAreaPolygon:getSelectedPoint()
    local points = self:getPoints()
    return points[self.selectedIndex]
end

function EditorAreaPolygon:updatePositionText()
    local point = self:getSelectedPoint()

    if self.mode ~= EditorAreaPolygon.MODE.NONE and self.mode ~= EditorAreaPolygon.MODE.SET_POSITION and point ~= nil then
        local targetY = self:getTargetY()

        self.positionText:setVisible(true)
        self.positionText:setText(string.format('x: %.2f  y: %.2f  z: %.2f', point[1], targetY, point[2]))
    else
        self.positionText:setVisible(false)
    end
end

function EditorAreaPolygon:updatePanels()
    local disabled = self.mode ~= EditorAreaPolygon.MODE.NONE

    if self.actionPanel.disabled ~= disabled then
        self.actionPanel:setDisabled(disabled)

        if not disabled then
            self:updateActionPanel()
        end
    end

    if self.optionsPanel.disabled ~= disabled then
        self.optionsPanel:setDisabled(disabled)

        if not disabled then
            self:updateOptionsPanel()
        end
    end
end

function EditorAreaPolygon:updateActionPanel()
    EditorScreen.updateActionPanel(self)

    local disabled = self.mode ~= EditorAreaPolygon.MODE.NONE

    if disabled then
        self.saveButton:setDisabled(true)
    end
end

---@param hasPanelButtons boolean
function EditorAreaPolygon:registerMenuActionEvents(hasPanelButtons)
    if #self.menuEvents > 0 then
        self:removeMenuActionEvents()
    end

    self.menuEvents = {}

    if not hasPanelButtons then
        if self.mode == EditorAreaPolygon.MODE.SELECT or self.mode == EditorAreaPolygon.MODE.MOVE_POINT then
            local _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_DELETE', self, self.onPressDelete, false, true, false, true)
            g_inputBinding:setActionEventText(eventId, EditorScreen.L10N_SYMBOL.DELETE)
            self.deleteButtonEvent = eventId
            table.insert(self.menuEvents, eventId)
        end

        if self.mode == EditorAreaPolygon.MODE.SELECT or self.mode == EditorAreaPolygon.MODE.MOVE_POINT then
            local _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_MOVE', self, self.onPressMove, false, true, false, true)
            g_inputBinding:setActionEventText(eventId, EditorScreen.L10N_SYMBOL.MOVE_POINT)
            self.moveButtonEvent = eventId
            table.insert(self.menuEvents, eventId)
        end

        if self.mode == EditorAreaPolygon.MODE.SELECT or self.mode == EditorAreaPolygon.MODE.ADD_POINT then
            local _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_MENU_PREV', self, self.onMenuPrev, false, true, false, true)
            g_inputBinding:setActionEventText(eventId, EditorScreen.L10N_SYMBOL.CHANGE_DIRECTION)
            table.insert(self.menuEvents, eventId)
            self.menuPrevButtonEvent = eventId

            _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_MENU_NEXT', self, self.onMenuNext, false, true, false, true)
            g_inputBinding:setActionEventText(eventId, EditorScreen.L10N_SYMBOL.CHANGE_DIRECTION)
            table.insert(self.menuEvents, eventId)
            self.menuNextButtonEvent = eventId
        end

        if self.mode == EditorAreaPolygon.MODE.SET_POSITION then
            local _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onReleaseUpDown, true, false, false, true)
            g_inputBinding:setActionEventText(eventId, EditorScreen.L10N_SYMBOL.MOVE_HORIZONTAL)
            table.insert(self.menuEvents, eventId)
            _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onReleaseLeftRight, true, false, false, true)
            g_inputBinding:setActionEventText(eventId, EditorScreen.L10N_SYMBOL.MOVE_VERTICAL)
            table.insert(self.menuEvents, eventId)
        end
    end

    EditorScreen.registerMenuActionEvents(self, hasPanelButtons)

    self:updateMenuActionEvents()
end

function EditorAreaPolygon:updateMenuActionEvents()
    local mode = self.mode
    local inputBinding = g_inputBinding

    local function set(e, active, text)
        inputBinding:setActionEventActive(e, active)
        if text then
            inputBinding:setActionEventText(e, text)
        end
    end

    set(self.primaryButtonEvent, false)
    set(self.secondaryButtonEvent, false)
    set(self.deleteButtonEvent, false)
    set(self.moveButtonEvent, false)
    set(self.menuPrevButtonEvent, false)
    set(self.menuNextButtonEvent, false)

    if mode == EditorAreaPolygon.MODE.NONE then
        set(self.secondaryButtonEvent, true, EditorScreen.L10N_SYMBOL.EDIT_MODE)
    elseif mode == EditorAreaPolygon.MODE.SELECT then
        local hasSelection = self.selectedIndex ~= nil

        set(self.primaryButtonEvent, true, EditorScreen.L10N_SYMBOL.SELECT_POINT)
        set(self.secondaryButtonEvent, true, EditorScreen.L10N_SYMBOL.EXIT_EDIT_MODE)
        set(self.backButtonEvent, true, EditorScreen.L10N_SYMBOL.EXIT_EDIT_MODE)

        set(self.deleteButtonEvent, hasSelection)
        set(self.moveButtonEvent, hasSelection)
        set(self.menuPrevButtonEvent, hasSelection, hasSelection and EditorScreen.L10N_SYMBOL.CREATE_POINT or nil)
        set(self.menuNextButtonEvent, hasSelection, hasSelection and EditorScreen.L10N_SYMBOL.CREATE_POINT or nil)
    elseif mode == EditorAreaPolygon.MODE.ADD_POINT then
        set(self.primaryButtonEvent, true, EditorScreen.L10N_SYMBOL.PLACE_POINT)
        set(self.secondaryButtonEvent, true, EditorScreen.L10N_SYMBOL.CANCEL)
        set(self.backButtonEvent, true, EditorScreen.L10N_SYMBOL.CANCEL)
        set(self.deleteButtonEvent, true)

        local points = self:getPoints()

        if #points > 2 then
            if self.direction == 1 then
                set(self.menuPrevButtonEvent, true, EditorScreen.L10N_SYMBOL.CHANGE_DIRECTION)
            else
                set(self.menuNextButtonEvent, true, EditorScreen.L10N_SYMBOL.CHANGE_DIRECTION)
            end
        end
    elseif mode == EditorAreaPolygon.MODE.MOVE_POINT then
        set(self.primaryButtonEvent, true, EditorScreen.L10N_SYMBOL.SET_POSITION)
        set(self.secondaryButtonEvent, true, EditorScreen.L10N_SYMBOL.CANCEL)
        set(self.backButtonEvent, true, EditorScreen.L10N_SYMBOL.CANCEL)
    elseif mode == EditorAreaPolygon.MODE.SET_POSITION then
        set(self.primaryButtonEvent, true, EditorScreen.L10N_SYMBOL.SET_TARGET_HEIGHT)
        set(self.secondaryButtonEvent, true, EditorScreen.L10N_SYMBOL.CANCEL)
        set(self.backButtonEvent, true, EditorScreen.L10N_SYMBOL.CANCEL)
    end
end

function EditorAreaPolygon:draw()
    if self.mode ~= EditorAreaPolygon.MODE.NONE then
        local COLOR         = self.COLOR
        local innerRadius   = self.INNER_RADIUS
        local outerRadius   = self.OUTER_RADIUS
        local steps         = self.CIRCLE_STEPS

        local x, y, z       = self.cursor.currentHitX, self.cursor.currentHitY, self.cursor.currentHitZ
        local targetY       = self:getTargetY()
        local points        = self:getPoints()
        local selectedIndex = self.selectedIndex
        local numPoints     = #points
        local firstPoint    = points[1]
        local lastPoint     = points[numPoints]

        if self.mode == EditorAreaPolygon.MODE.SELECT and targetY ~= math.huge then
            local pos, index = self:getMouseOverPoint()
            if pos and index ~= self.selectedIndex then
                DebugUtil.drawDebugCircle(pos[1], targetY, pos[2], outerRadius, steps, COLOR.HIGHLIGHT_POINT, nil, nil, false)
            end
        elseif self.mode == EditorAreaPolygon.MODE.ADD_POINT then
            if self.cursor.currentHitTerrain and (not self.isMouseMode or not self.isMouseInMenu) then
                DebugUtil.drawDebugCircle(x, y, z, outerRadius, steps, COLOR.EXTEND_POINT, nil, nil, false)
                ModUtils.drawDebugLine(x, y, z, x, targetY, z, COLOR.EXTEND_POINT, false)

                if numPoints == 0 then
                    ModUtils.drawDebugLine(x, y, z, x, y + 1, z, COLOR.SELECTED_POINT, false)
                    DebugUtil.drawDebugCircle(x, y, z, innerRadius, steps, COLOR.POINT, nil, nil, false)
                elseif self.selectedIndex then
                    local prevPoint, nextPoint = firstPoint, lastPoint

                    if numPoints > 2 then
                        if self.direction == 1 then
                            prevPoint = points[selectedIndex] or lastPoint
                            nextPoint = points[selectedIndex + 1] or firstPoint
                        else
                            prevPoint = points[selectedIndex] or firstPoint
                            nextPoint = points[selectedIndex - 1] or lastPoint
                        end
                    end

                    if prevPoint then
                        ModUtils.drawDebugLine(prevPoint[1], targetY, prevPoint[2], x, targetY, z, COLOR.EXTEND_POINT, false)
                    end
                    if nextPoint then
                        ModUtils.drawDebugLine(nextPoint[1], targetY, nextPoint[2], x, targetY, z, COLOR.EXTEND_POINT, false)
                    end
                end
            end
        elseif self.mode == EditorAreaPolygon.MODE.MOVE_POINT then
            if self.cursor.currentHitTerrain and (not self.isMouseMode or not self.isMouseInMenu) then
                DebugUtil.drawDebugCircle(x, y, z, outerRadius, steps, COLOR.LINE, nil, nil, false)
                ModUtils.drawDebugLine(x, y, z, x, targetY, z, COLOR.LINE, false)

                if numPoints > 0 then
                    local prevPoint, nextPoint = firstPoint, lastPoint

                    if numPoints > 2 then
                        prevPoint = points[selectedIndex - 1] or lastPoint
                        nextPoint = points[selectedIndex + 1] or firstPoint
                    end

                    if prevPoint then
                        ModUtils.drawDebugLine(prevPoint[1], targetY, prevPoint[2], x, targetY, z, COLOR.LINE, false)
                    end
                    if nextPoint then
                        ModUtils.drawDebugLine(nextPoint[1], targetY, nextPoint[2], x, targetY, z, COLOR.LINE, false)
                    end
                end
            end
        elseif self.mode == EditorAreaPolygon.MODE.SET_POSITION then
            DebugUtil.drawDebugCircle(x, y, z, outerRadius, steps, COLOR.LINE, nil, nil, false)
            ModUtils.drawDebugLine(x, y, z, x, targetY, z, COLOR.LINE, false)
            DebugUtil.drawDebugCircle(x, targetY, z, outerRadius, steps, COLOR.LINE, nil, nil, false)
        end

        for index, pos in ipairs(points) do
            DebugUtil.drawDebugCircle(pos[1], targetY, pos[2], innerRadius, steps, COLOR.POINT, nil, nil, false)
            if index == self.selectedIndex and self.mode ~= EditorAreaPolygon.MODE.SET_POSITION then
                DebugUtil.drawDebugCircle(pos[1], targetY, pos[2], outerRadius, steps, COLOR.SELECTED_POINT, nil, nil, false)
            end
        end
    end

    self.cursor:draw()
    EditorScreen.draw(self)
end

function EditorAreaPolygon:updateHeightInput()
    local targetY = self:getTargetY()

    if targetY ~= math.huge then
        self.heightInput:setText(string.format('%.2f', targetY))
    else
        -- TODO
        self.heightInput:setText(string.format('%.2f', 0))
    end
end

function EditorAreaPolygon:onEnterPressedHeightInput()
    local value = tonumber(self.heightInput.text)

    if value ~= nil then
        value = MathUtil.round(value, 2)
        self:setTargetY(value)
        self:updateAreaBorder()
        self:updateHeightInput()
        self:setHasChanged(true)
    end

    self:updateHeightInput()
end

function EditorAreaPolygon:onButtonMenuBack()
    if self.mode ~= EditorAreaPolygon.MODE.NONE then
        self:onPressCancel()
    else
        EditorScreen.onButtonMenuBack(self)
    end
end

function EditorAreaPolygon:onClickSetTargetHeight()
    if self.mode ~= EditorAreaPolygon.MODE.SET_POSITION then
        self:setMode(EditorAreaPolygon.MODE.SET_POSITION)
    end
end

function EditorAreaPolygon:updateAreaData()
    EditorScreen.updateAreaData(self)

    self:updateHeightInput()
end

---@param visible boolean
function EditorAreaPolygon:setBorderVisibility(visible)
    self.borderVisible = visible
    setVisibility(self.rootNode, visible)
end

function EditorAreaPolygon:updateAreaBorder()
    self.area:updateAreaBorder(self.shape, self.rootNode, self.childNodes)
end
