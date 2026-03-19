---@class EditorAreaPath : EditorScreen
---@field area LandscapingAreaPath
---@field mode EditorAreaPathMode
---@field superClass fun(): EditorScreen
---@field addPointButton ButtonElement
---@field removeButton ButtonElement
---@field widthInput TextInputElement
---@field selectedIndex? number
---@field direction number
---@field maxNumPoints number
---
---@field upDownButtonEvent string
---@field menuPrevButtonEvent? string
---@field menuNextButtonEvent? string
---
---@field directionButtonIsDown boolean
---@field angleButtonIsDown boolean
---@field levelButtonIsDown boolean
---@field infoDisplay BoxLayoutElement
EditorAreaPath = {}
EditorAreaPath.CLASS_NAME = 'EditorAreaPath'
EditorAreaPath.XML_FILENAME = g_modDirectory .. 'data/gui/editor/EditorAreaPath.xml'
EditorAreaPath.INPUT_CONTEXT = 'AREA_EDITOR_PATH'

---@enum EditorAreaPathMode
EditorAreaPath.MODE = {
    NONE = 0,
    SELECT = 1,
    ADD_POINT = 2,
    MOVE_POINT = 3,
}

---@type table<EditorAreaPathMode, string>
EditorAreaPath.MODE_TEXT = {
    [EditorAreaPath.MODE.NONE] = 'NONE',
    [EditorAreaPath.MODE.SELECT] = 'SELECT',
    [EditorAreaPath.MODE.ADD_POINT] = 'ADD_POINT',
    [EditorAreaPath.MODE.MOVE_POINT] = 'MOVE_POINT',
}

local EditorAreaPath_mt = Class(EditorAreaPath, EditorScreen)

---@return EditorAreaPath
---@nodiscard
function EditorAreaPath.new()
    local self = EditorScreen.new(EditorAreaPath_mt)
    ---@cast self EditorAreaPath

    self.mode = EditorAreaPath.MODE.NONE

    self.directionButtonIsDown = false
    self.angleButtonIsDown = false
    self.levelButtonIsDown = false

    self.selectedIndex = nil
    self.direction = 1
    self.maxNumPoints = LandscapingAreaPath.MAX_NUM_POINTS

    return self
end

function EditorAreaPath:onOpen()
    self:superClass().onOpen(self)

    self:setMode(EditorAreaPath.MODE.NONE)

    self:updateWidthInput()
    self:updateAreaBorder()
    self:setBorderVisibility(true)
end

function EditorAreaPath:onClose()
    self:setBorderVisibility(false)

    self:superClass().onClose(self)
end

---@param mode EditorAreaPathMode
function EditorAreaPath:setMode(mode)
    local points = self:getPoints()

    if mode == EditorAreaPath.MODE.SELECT and #points == 0 then
        self.selectedIndex = nil
        self.direction = 1
        mode = EditorAreaPath.MODE.ADD_POINT
    end

    self.mode = mode

    self:registerMenuActionEvents(self.mode == EditorAreaPath.MODE.NONE)
    self:updatePanels()
end

function EditorAreaPath:addPoint()
    local points = self:getPoints()

    if #points <= self.maxNumPoints and self.cursor.currentHitTerrain then
        local x, y, z = self:getTargetPosition()
        local selectedIndex = self.selectedIndex
        local index = selectedIndex or 1

        if selectedIndex ~= nil and self.direction == 1 then
            index = index + 1
        end

        table.insert(points, index, { x, y, z })

        self:updateAreaBorder()
        self:setHasChanged(true)

        self.selectedIndex = index

        self:updateMenuActionEvents()
        self:updatePanels()
    end
end

function EditorAreaPath:deletePoint()
    local selectedIndex = self.selectedIndex
    local points = self:getPoints()

    if selectedIndex ~= nil and table.remove(points, selectedIndex) ~= nil then
        self:updateAreaBorder()
        self:setHasChanged(true)

        local numPoints = #points

        if numPoints == 0 then
            self.selectedIndex = nil
            self.direction = 1

            self:setMode(EditorAreaPath.MODE.ADD_POINT)
        elseif selectedIndex > numPoints then
            self.selectedIndex = numPoints
        end

        self:updatePanels()
    end
end

function EditorAreaPath:movePoint()
    if self.cursor.currentHitTerrain then
        local points = self:getPoints()
        local point = points[self.selectedIndex]

        if point ~= nil then
            point[1], point[2], point[3] = self:getTargetPosition()

            self:setMode(EditorAreaPath.MODE.SELECT)
            self:updateAreaBorder()
            self:setHasChanged(true)
        end
    end
end

---@param index? number
function EditorAreaPath:selectPoint(index)
    if self.selectedIndex ~= index then
        self.selectedIndex = index

        self:updateMenuActionEvents()
    end
end

function EditorAreaPath:onPressCancel()
    if self.mode == EditorAreaPath.MODE.SELECT then
        self:setMode(EditorAreaPath.MODE.NONE)
    elseif self.mode == EditorAreaPath.MODE.ADD_POINT then
        if #self.area.points == 0 then
            self:setMode(EditorAreaPath.MODE.NONE)
        else
            self:setMode(EditorAreaPath.MODE.SELECT)
        end
    elseif self.mode == EditorAreaPath.MODE.MOVE_POINT then
        self:setMode(EditorAreaPath.MODE.SELECT)
    end
end

function EditorAreaPath:onPressAccept()
    if self.mode == EditorAreaPath.MODE.SELECT then
        if not self.isMouseMode or not self.isMouseInMenu then
            self:selectPoint(self:getMouseOverIndex())
        end
    elseif self.mode == EditorAreaPath.MODE.ADD_POINT then
        self:addPoint()
    elseif self.mode == EditorAreaPath.MODE.MOVE_POINT then
        self:movePoint()
    else
        self:superClass().onPressAccept(self)
    end
end

function EditorAreaPath:onPressMove()
    if self.selectedIndex ~= nil and self.mode == EditorAreaPath.MODE.SELECT then
        self:setMode(EditorAreaPath.MODE.MOVE_POINT)
    end
end

function EditorAreaPath:onPressDelete()
    if self.mode == EditorAreaPath.MODE.SELECT or self.mode == EditorAreaPath.MODE.ADD_POINT then
        self:deletePoint()
    end
end

function EditorAreaPath:onMenuPrev()
    if self.selectedIndex ~= nil and (self.mode == EditorAreaPath.MODE.SELECT or self.mode == EditorAreaPath.MODE.ADD_POINT) then
        self.direction = -1
        self:setMode(EditorAreaPath.MODE.ADD_POINT)
    end
end

function EditorAreaPath:onMenuNext()
    if self.selectedIndex ~= nil and (self.mode == EditorAreaPath.MODE.SELECT or self.mode == EditorAreaPath.MODE.ADD_POINT) then
        self.direction = 1
        self:setMode(EditorAreaPath.MODE.ADD_POINT)
    end
end

---@return number? index
function EditorAreaPath:getMouseOverIndex()
    if self.cursor.currentHitTerrain and (not self.isMouseMode or not self.isMouseInMenu) then
        local maxDistance = 0.025
        local mousePosX, mousePosY = self.cursor.mousePosX, self.cursor.mousePosY
        local points = self:getPoints()

        for index, point in ipairs(points) do
            local sx, sy, sz = project(point[1], point[2], point[3])

            if sx > -1 and sx < 2 and sy > -1 and sy < 2 and sz <= 1 then
                local distance = MathUtil.getPointPointDistance(mousePosX, mousePosY, sx, sy)
                if distance < maxDistance then
                    return index
                end
            end
        end
    end
end

---@return number[][]
---@nodiscard
function EditorAreaPath:getPoints()
    return self.area.points
end

---@return number[]? point
---@return number index
function EditorAreaPath:getMouseOverPoint()
    local index = self:getMouseOverIndex()
    local points = self:getPoints()

    return points[index], index or 0
end

function EditorAreaPath:onButtonPrimary()
    if self.mode ~= EditorAreaPath.MODE.NONE then
        self:onPressAccept()
    end
end

function EditorAreaPath:onButtonSecondary()
    if not self.isMouseMode or not self.isMouseInMenu then
        if self.mode == EditorAreaPath.MODE.NONE then
            self:setMode(EditorAreaPath.MODE.SELECT)
        else
            self:onPressCancel()
        end
    end
end

function EditorAreaPath:updatePanels()
    local disabled = self.mode ~= EditorAreaPath.MODE.NONE

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

    local enabled = self.selectedIndex ~= nil and (self.mode == EditorAreaPath.MODE.SELECT or self.mode == EditorAreaPath.MODE.MOVE_POINT)

    self.positionPanel:setDisabled(not enabled)

    if self.mode == EditorAreaPath.MODE.ADD_POINT then
        self.infoDisplay:setVisible(true)

        local points = self:getPoints()
        local visible = (self.selectedIndex == 1 and self.direction == -1) or (self.selectedIndex == #points and self.direction == 1)

        self.infoDisplay.elements[1]:setVisible(visible)
        self.infoDisplay.elements[2]:setVisible(visible)
        self.infoDisplay:invalidateLayout()
    elseif self.mode == EditorAreaPath.MODE.MOVE_POINT then
        self.infoDisplay:setVisible(true)
        self.infoDisplay.elements[1]:setVisible(false)
        self.infoDisplay.elements[2]:setVisible(false)
        self.infoDisplay:invalidateLayout()
    else
        self.infoDisplay:setVisible(false)
    end
end

function EditorAreaPath:updateActionPanel()
    self:superClass().updateActionPanel(self)

    local disabled = self.mode ~= EditorAreaPath.MODE.NONE

    if disabled then
        self.saveButton:setDisabled(true)
    end
end

---@param hasPanelButtons boolean
function EditorAreaPath:registerMenuActionEvents(hasPanelButtons)
    if #self.menuEvents > 0 then
        self:removeMenuActionEvents()
    end

    self.menuEvents = {}

    self:superClass().registerMenuActionEvents(self, hasPanelButtons)

    if not hasPanelButtons then
        if self.mode == EditorAreaPath.MODE.MOVE_POINT then
            local _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onReleaseLeftRight, true, false, false, true)
            g_inputBinding:setActionEventText(eventId, EditorScreen.L10N_SYMBOL.MOVE_HORIZONTAL)
            table.insert(self.menuEvents, eventId)
        end
        if self.mode ~= EditorAreaPath.MODE.NONE then
            local _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onReleaseUpDown, true, false, false, true)
            g_inputBinding:setActionEventText(eventId, EditorScreen.L10N_SYMBOL.MOVE_VERTICAL)
            table.insert(self.menuEvents, eventId)
            self.upDownButtonEvent = eventId
        end

        if self.mode == EditorAreaPath.MODE.SELECT or self.mode == EditorAreaPath.MODE.MOVE_POINT then
            local _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_MOVE', self, self.onPressMove, false, true, false, true)
            g_inputBinding:setActionEventText(eventId, EditorScreen.L10N_SYMBOL.MOVE_POINT)
            self.moveButtonEvent = eventId
            table.insert(self.menuEvents, eventId)
        end

        if self.mode == EditorAreaPath.MODE.SELECT or self.mode == EditorAreaPath.MODE.ADD_POINT then
            local _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_MENU_PREV', self, self.onMenuPrev, false, true, false, true)
            g_inputBinding:setActionEventText(eventId, EditorScreen.L10N_SYMBOL.CHANGE_DIRECTION)
            table.insert(self.menuEvents, eventId)
            self.menuPrevButtonEvent = eventId

            _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_MENU_NEXT', self, self.onMenuNext, false, true, false, true)
            g_inputBinding:setActionEventText(eventId, EditorScreen.L10N_SYMBOL.CHANGE_DIRECTION)
            table.insert(self.menuEvents, eventId)
            self.menuNextButtonEvent = eventId

            _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_DELETE', self, self.onPressDelete, false, true, false, true)
            g_inputBinding:setActionEventText(eventId, EditorScreen.L10N_SYMBOL.DELETE)
            self.deleteButtonEvent = eventId
            table.insert(self.menuEvents, eventId)
        end

        if self.mode == EditorAreaPath.MODE.ADD_POINT or self.mode == EditorAreaPath.MODE.MOVE_POINT then
            local _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_DIRECTION', self, self.onDirectionButtonStateChanged, true, true, false, true)
            g_inputBinding:setActionEventTextVisibility(eventId, false)
            g_inputBinding:setActionEventText(eventId, EditorScreen.L10N_SYMBOL.KEEP_DIRECTION)
            table.insert(self.menuEvents, eventId)

            _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_ANGLE', self, self.onAngleButtonStateChanged, true, true, false, true)
            g_inputBinding:setActionEventTextVisibility(eventId, false)
            g_inputBinding:setActionEventText(eventId, EditorScreen.L10N_SYMBOL.FOLLOW_ANGLE)

            table.insert(self.menuEvents, eventId)
            _, eventId = g_inputBinding:registerActionEvent('AREA_EDITOR_LEVEL', self, self.onLevelButtonStateChanged, true, true, false, true)
            g_inputBinding:setActionEventTextVisibility(eventId, false)
            g_inputBinding:setActionEventText(eventId, EditorScreen.L10N_SYMBOL.LEVEL)
            table.insert(self.menuEvents, eventId)
        end
    end


    self:updateMenuActionEvents()
end

function EditorAreaPath:updateMenuActionEvents()
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
    set(self.upDownButtonEvent, false)

    local hasSelection = self.selectedIndex ~= nil

    if mode == EditorAreaPath.MODE.NONE then
        set(self.secondaryButtonEvent, true, EditorScreen.L10N_SYMBOL.EDIT_MODE)
    elseif mode == EditorAreaPath.MODE.SELECT then
        set(self.primaryButtonEvent, true, EditorScreen.L10N_SYMBOL.SELECT_POINT)
        set(self.secondaryButtonEvent, true, EditorScreen.L10N_SYMBOL.EXIT_EDIT_MODE)
        set(self.backButtonEvent, true, EditorScreen.L10N_SYMBOL.EXIT_EDIT_MODE)

        set(self.upDownButtonEvent, hasSelection)
        set(self.deleteButtonEvent, hasSelection)
        set(self.moveButtonEvent, hasSelection)
        set(self.menuPrevButtonEvent, hasSelection, hasSelection and EditorScreen.L10N_SYMBOL.CREATE_POINT or nil)
        set(self.menuNextButtonEvent, hasSelection, hasSelection and EditorScreen.L10N_SYMBOL.CREATE_POINT or nil)
    elseif mode == EditorAreaPath.MODE.ADD_POINT then
        set(self.primaryButtonEvent, true, EditorScreen.L10N_SYMBOL.PLACE_POINT)
        set(self.secondaryButtonEvent, true, EditorScreen.L10N_SYMBOL.CANCEL)
        set(self.backButtonEvent, true, EditorScreen.L10N_SYMBOL.CANCEL)

        if hasSelection then
            set(self.deleteButtonEvent, true)
        end
        set(self.moveButtonEvent, hasSelection)
        set(self.upDownButtonEvent, hasSelection)

        local points = self:getPoints()

        if #points > 1 then
            if self.direction == 1 then
                set(self.menuPrevButtonEvent, true, EditorScreen.L10N_SYMBOL.CHANGE_DIRECTION)
            else
                set(self.menuNextButtonEvent, true, EditorScreen.L10N_SYMBOL.CHANGE_DIRECTION)
            end
        end
    elseif mode == EditorAreaPath.MODE.MOVE_POINT then
        set(self.primaryButtonEvent, true, EditorScreen.L10N_SYMBOL.SET_POSITION)
        set(self.secondaryButtonEvent, true, EditorScreen.L10N_SYMBOL.CANCEL)
        set(self.backButtonEvent, true, EditorScreen.L10N_SYMBOL.CANCEL)
        set(self.upDownButtonEvent, hasSelection)
    end

    self:superClass().updateMenuActionEvents(self)
end

function EditorAreaPath:updateWidthInput()
    self.widthInput:setText(string.format('%.1f', self.area.width))
end

function EditorAreaPath:onEnterPressedWidthInput()
    local value = tonumber(self.widthInput.text)

    if value ~= nil then
        value = MathUtil.round(math.clamp(value, 2, 100), 1)
        self.area.width = value

        self:updateAreaBorder()
        self:setHasChanged(true)
    end

    self:updateWidthInput()
end

function EditorAreaPath:updateAreaData()
    self:superClass().updateAreaData(self)

    self:updateWidthInput()
end

---@param value number
function EditorAreaPath:moveSelectedPointY(value)
    local points = self:getPoints()
    local point = points[self.selectedIndex]

    if point ~= nil then
        point[2] = point[2] + value

        self:updateAreaBorder()
        self:setHasChanged(true)
    end
end

---@param value number
function EditorAreaPath:moveSelectedPointX(value)
    local points = self:getPoints()
    local point = points[self.selectedIndex]

    if point ~= nil then
        local rightX = math.cos(self.camera.cameraRotY)
        local rightZ = -math.sin(self.camera.cameraRotY)

        point[1] = point[1] + rightX * value
        point[3] = point[3] + rightZ * value

        self:updateAreaBorder()
        self:setHasChanged(true)
    end
end

function EditorAreaPath:onClickMoveUp()
    self:moveSelectedPointY(0.125)
end

function EditorAreaPath:onClickMoveDown()
    self:moveSelectedPointY(-0.125)
end

function EditorAreaPath:onClickMoveLeft()
    self:moveSelectedPointX(0.25)
end

function EditorAreaPath:onClickMoveRight()
    self:moveSelectedPointX(-0.25)
end

function EditorAreaPath:onClickSetPosition()
    local points = self:getPoints()
    local point = points[self.selectedIndex]

    if point ~= nil then
        g_setPositionDialog:setCallback(self.setPositionCallback, self)
        g_setPositionDialog:show(point[1], point[2], point[3])
    end
end

---@param x number
---@param y number
---@param z number
function EditorAreaPath:setPositionCallback(x, y, z)
    local points = self:getPoints()
    local point = points[self.selectedIndex]

    if point ~= nil then
        point[1] = x
        point[2] = y
        point[3] = z

        self:updateAreaBorder()
        self:setHasChanged(true)
    end
end

function EditorAreaPath:onDirectionButtonStateChanged(action, value)
    self.directionButtonIsDown = value == 1
end

function EditorAreaPath:onAngleButtonStateChanged(action, value)
    self.angleButtonIsDown = value == 1
end

function EditorAreaPath:onLevelButtonStateChanged(action, value)
    self.levelButtonIsDown = value == 1
end

---@param binding Binding
function EditorAreaPath:onReleaseUpDown(action, _, _, _, _, _, binding)
    if self.mode == EditorAreaPath.MODE.NONE then
        self:superClass().onReleaseUpDown(self, action)
    elseif self.mode == EditorAreaPath.MODE.MOVE_POINT or self.mode == EditorAreaPath.MODE.ADD_POINT or self.mode == EditorAreaPath.MODE.SELECT then
        if binding.axisDirection == -1 then
            self:onClickMoveDown()
        else
            self:onClickMoveUp()
        end
    end
end

---@param binding Binding
function EditorAreaPath:onReleaseLeftRight(action, _, _, _, _, _, binding)
    if self.mode == EditorAreaPath.MODE.NONE then
        self:superClass().onReleaseLeftRight(self, action)
    elseif self.mode == EditorAreaPath.MODE.MOVE_POINT then
        if binding.axisDirection == -1 then
            self:onClickMoveLeft()
        else
            self:onClickMoveRight()
        end
    end
end

function EditorAreaPath:draw()
    if self.mode ~= EditorAreaPath.MODE.NONE then
        local COLOR         = self.COLOR
        local innerRadius   = self.INNER_RADIUS
        local outerRadius   = self.OUTER_RADIUS
        local steps         = self.CIRCLE_STEPS

        local points        = self:getPoints()
        local selectedIndex = self.selectedIndex
        local selectedPoint = points[selectedIndex]
        local numPoints     = #points

        if self.mode == EditorAreaPath.MODE.SELECT then
            local pos, index = self:getMouseOverPoint()
            if pos and index ~= self.selectedIndex then
                DebugUtil.drawDebugCircle(pos[1], pos[2], pos[3], outerRadius, steps, COLOR.HIGHLIGHT_POINT, nil, nil, false)
            end

            if selectedPoint ~= nil then
                local prevPoint = points[selectedIndex - 1]
                local nextPoint = points[selectedIndex + 1]

                if prevPoint then
                    LandscapingUtils.renderAngleTextBetween(prevPoint[1], prevPoint[2], prevPoint[3], selectedPoint[1], selectedPoint[2], selectedPoint[3], COLOR.EXTEND_POINT)
                end
                if nextPoint then
                    LandscapingUtils.renderAngleTextBetween(nextPoint[1], nextPoint[2], nextPoint[3], selectedPoint[1], selectedPoint[2], selectedPoint[3], COLOR.EXTEND_POINT)
                end
            end
        elseif self.cursor.currentHitTerrain and (not self.isMouseMode or not self.isMouseInMenu) then
            local x, y, z    = self.cursor.currentHitX, self.cursor.currentHitY, self.cursor.currentHitZ
            local tx, ty, tz = self:getTargetPosition()

            if self.mode == EditorAreaPath.MODE.ADD_POINT then
                local th         = LandscapingUtils.getTerrainHeightAt(tx, tz)
                local firstPoint = points[1]
                local lastPoint  = points[numPoints]

                DebugUtil.drawDebugCircle(x, y, z, outerRadius, steps, COLOR.EXTEND_POINT, nil, nil, false)
                ModUtils.drawDebugLine(tx, ty, tz, tx, th, tz, COLOR.EXTEND_POINT, false)

                if numPoints == 0 then
                    ModUtils.drawDebugLine(x, y, z, x, y + 1, z, COLOR.SELECTED_POINT, false)
                    DebugUtil.drawDebugCircle(x, y, z, innerRadius, steps, COLOR.POINT, nil, nil, false)
                elseif selectedIndex then
                    ---@type number[]?, number[]?
                    local prevPoint, nextPoint = firstPoint, lastPoint

                    if selectedIndex == 1 and self.direction == -1 then
                        prevPoint = points[1]
                        nextPoint = nil
                    elseif selectedIndex == numPoints and self.direction == 1 then
                        prevPoint = points[numPoints]
                        nextPoint = nil
                    else
                        if self.direction == 1 then
                            prevPoint = points[selectedIndex]
                            nextPoint = points[selectedIndex + 1]
                        else
                            prevPoint = points[selectedIndex]
                            nextPoint = points[selectedIndex - 1]
                        end
                    end

                    if prevPoint then
                        ModUtils.drawDebugLine(prevPoint[1], prevPoint[2], prevPoint[3], tx, ty, tz, COLOR.EXTEND_POINT, false)
                        LandscapingUtils.renderAngleTextBetween(prevPoint[1], prevPoint[2], prevPoint[3], tx, ty, tz, COLOR.EXTEND_POINT)
                    end
                    if nextPoint then
                        ModUtils.drawDebugLine(nextPoint[1], nextPoint[2], nextPoint[3], tx, ty, tz, COLOR.EXTEND_POINT, false)
                        LandscapingUtils.renderAngleTextBetween(nextPoint[1], nextPoint[2], nextPoint[3], tx, ty, tz, COLOR.EXTEND_POINT)
                    end
                end
            elseif self.mode == EditorAreaPath.MODE.MOVE_POINT then
                DebugUtil.drawDebugCircle(tx, ty, tz, outerRadius, steps, COLOR.LINE, nil, nil, false)
                ModUtils.drawDebugLine(x, y, z, tx, ty, tz, COLOR.LINE, false)

                if numPoints > 0 then
                    local prevPoint = points[selectedIndex - 1]
                    local nextPoint = points[selectedIndex + 1]

                    if prevPoint then
                        ModUtils.drawDebugLine(prevPoint[1], prevPoint[2], prevPoint[3], tx, ty, tz, COLOR.LINE, false)
                        LandscapingUtils.renderAngleTextBetween(prevPoint[1], prevPoint[2], prevPoint[3], tx, ty, tz, COLOR.EXTEND_POINT)
                    end
                    if nextPoint then
                        ModUtils.drawDebugLine(nextPoint[1], nextPoint[2], nextPoint[3], tx, ty, tz, COLOR.LINE, false)
                        LandscapingUtils.renderAngleTextBetween(nextPoint[1], nextPoint[2], nextPoint[3], tx, ty, tz, COLOR.EXTEND_POINT)
                    end
                end
            end
        end

        for index, pos in ipairs(points) do
            DebugUtil.drawDebugCircle(pos[1], pos[2], pos[3], innerRadius, steps, COLOR.POINT, nil, nil, false)

            if index == selectedIndex then
                DebugUtil.drawDebugCircle(pos[1], pos[2], pos[3], outerRadius, steps, COLOR.SELECTED_POINT, nil, nil, false)
            end

            local nextPoint = points[index + 1]

            if nextPoint ~= nil then
                ModUtils.drawDebugLine(
                    pos[1], pos[2], pos[3],
                    nextPoint[1], nextPoint[2], nextPoint[3],
                    COLOR.LINE, false
                )
            end
        end
    end

    self.cursor:draw()
    self:superClass().draw(self)
end

function EditorAreaPath:onButtonMenuBack()
    if self.mode ~= EditorAreaPath.MODE.NONE then
        self:onPressCancel()
    else
        self:superClass().onButtonMenuBack(self)
    end
end

---@param visible boolean
function EditorAreaPath:setBorderVisibility(visible)
    self.borderVisible = visible
    setVisibility(self.rootNode, visible)
end

function EditorAreaPath:updateAreaBorder()
    self.area:updateAreaBorder(self.shape, self.rootNode, self.childNodes)
end

---@return number x
---@return number y
---@return number z
function EditorAreaPath:getTargetPosition()
    local x, y, z       = self.cursor.currentHitX, self.cursor.currentHitY, self.cursor.currentHitZ
    local points        = self:getPoints()
    local numPoints     = #points
    local selectedIndex = self.selectedIndex
    ---@type number[]?
    local selectedPoint = points[selectedIndex]

    local shift         = self.directionButtonIsDown
    local ctrl          = self.angleButtonIsDown
    local alt           = self.levelButtonIsDown

    if not (shift or ctrl or alt) or selectedPoint == nil then
        return x, y, z
    elseif numPoints == 1 or (selectedIndex > 1 and selectedIndex < numPoints) or self.mode == EditorAreaPath.MODE.MOVE_POINT or (selectedIndex == 1 and self.direction == 1) or (selectedIndex == numPoints and self.direction == -1) then
        if alt then
            return x, selectedPoint[2], z
        end
        return x, y, z
    end

    local sp = points[#points - 1]
    local ep = points[#points]

    if self.direction == -1 then
        sp = points[2]
        ep = points[1]
    end

    local sx, sy, sz = sp[1], sp[2], sp[3]
    local ex, ey, ez = ep[1], ep[2], ep[3]

    local dx, dy, dz = ex - sx, ey - sy, ez - sz

    local function project(projX, projY, projZ)
        local tNum = (projX and (x - sx) * dx or 0) +
            (projY and (y - sy) * dy or 0) +
            (projZ and (z - sz) * dz or 0)

        local distSq = MathUtil.vector3LengthSq(projX and dx or 0, projY and dy or 0, projZ and dz or 0)

        if distSq ~= 0 then
            local t = tNum / distSq
            return sx + t * dx, sy + t * dy, sz + t * dz
        else
            return ex, ey, ez
        end
    end

    if shift and not ctrl and not alt then
        x, _, z = project(true, false, true)
    elseif ctrl and not shift and not alt then
        local dist = MathUtil.vector2Length(dx, dz)
        if dist ~= 0 then
            local b = MathUtil.vector2Length(ex - x, ez - z)
            y = ey + b * (dy / dist)
        else
            y = ey
        end
    elseif alt and not shift and not ctrl then
        y = ey
    elseif shift and ctrl and not alt then
        x, y, z = project(true, true, true)
    elseif (shift and alt and not ctrl) or (shift and ctrl and alt) then
        x, _, z = project(true, false, true)
        y = ey
    elseif ctrl and alt and not shift then
        y = ey
    end

    return x, y, z
end
