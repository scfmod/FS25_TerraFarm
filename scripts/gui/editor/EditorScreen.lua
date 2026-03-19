---@class EditorScreen : ScreenElement
---@field isMouseInMenu boolean
---@field menuBox BitmapElement
---@field camera EditorCamera
---@field cursor EditorCursor
---@field openMenuAfterClose boolean
---@field area? LandscapingArea
---
---@field positionText TextElement
---@field positionPanel GuiElement
---@field optionsPanel BoxLayoutElement
---@field actionPanel BoxLayoutElement
---@field selectOptionButtons ButtonElement[]
---@field resetOptionButtons ButtonElement[]
---@field saveButton ButtonElement
---@field exitButton ButtonElement
---@field helpDisplay GuiElement
---@field originalSafeFrameOffsetX number
---@field nameInput TextInputElement
---@field iconOption TFIconOptionElement
---@field restrictAreaOption BinaryOptionElement
---@field fillTypeImage BitmapElement
---@field fillTypeText TextElement
---@field inputTerrainLayer TerrainLayerElement
---@field inputTerrainLayerText TextElement
---@field outputTerrainLayer TerrainLayerElement
---@field outputTerrainLayerText TextElement
---@field isMouseMode boolean
---@field hasChanged boolean
---@field originalInputHelpVisibility boolean
---
---@field borderIntensity number[]
---@field borderDash number[]
---@field borderColor number[]
---@field borderDecalColor number[]
---
---@field borderIsVisible boolean
---@field shape number
---@field rootNode number
---@field childNodes number[]
EditorScreen = {}
EditorScreen.CLASS_NAME = ''
EditorScreen.XML_FILENAME = ''
EditorScreen.INPUT_CONTEXT = 'AREA_EDITOR'

EditorScreen.COLOR = {
    POINT = { 1, 0.765, 0 },
    SELECTED_POINT = { 0, 0.25, 0.451 },
    EXTEND_POINT = { 1, 1, 1 },
    HIGHLIGHT_POINT = { 1, 0.765, 0 },
    LINE = { 0.5, 0.9, 0 },
}

EditorScreen.INNER_RADIUS = 0.2
EditorScreen.OUTER_RADIUS = 0.3
EditorScreen.CIRCLE_STEPS = 16

---@type table<string, string>
EditorScreen.L10N_SYMBOL = {
    CANCEL = g_i18n:getText('button_cancel'),
    CHANGE_DIRECTION = g_i18n:getText('input_DIRECTION_CHANGE'),
    CREATE_AREA = g_i18n:getText('ui_createArea'),
    CREATE_POINT = g_i18n:getText('ui_createPoint'),
    CREATE_WATERPLANE = g_i18n:getText('ui_createWaterplane'),
    DELETE = g_i18n:getText('button_delete'),
    EDIT = g_i18n:getText('ui_edit'),
    EDIT_MODE = g_i18n:getText('ui_editMode'),
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
    SET_POSITION = g_i18n:getText('ui_setPosition'),
    SET_TARGET_HEIGHT = g_i18n:getText('ui_setTargetHeight'),
    SET_VISIBLE = g_i18n:getText('ui_setVisible'),
    VISIBLE = g_i18n:getText('ui_visible')
}

local EditorScreen_mt = Class(EditorScreen, ScreenElement)

---@param customMt table
---@return EditorScreen
---@nodiscard
function EditorScreen.new(customMt)
    ---@type EditorScreen
    local self = ScreenElement.new(nil, customMt)

    self.isMouseInMenu = false
    self.isMouseMode = true
    self.menuEvents = {}

    self.camera = EditorCamera.new(self)
    self.camera.zoomFactor = 0.025
    self.camera.targetZoomFactor = 0.025
    self.cursor = EditorCursor.new(self)

    self.childNodes = {}
    self.borderIsVisible = false
    self.rootNode = createTransformGroup('editor_root_node')
    link(getRootNode(), self.rootNode)
    setVisibility(self.rootNode, false)

    self.borderIntensity = { 1, 1, 4, 1 }
    self.borderDash = { 16, 1, 0, 0 }
    self.borderColor = { 1, 0.765, 0, 1 }
    self.borderDecalColor = { 1, 0.865, 0, 1 }

    self:loadShapes()

    return self
end

function EditorScreen:loadShapes()
    local i3dNode = g_i3DManager:loadSharedI3DFile(LandscapingManager.BORDER_SHAPE_FILENAME, false, false)

    if i3dNode ~= 0 then
        local node = getChildAt(i3dNode, 0)

        self.shape = node

        local borderIntensity = self.borderIntensity
        local borderDash = self.borderDash
        local borderColor = self.borderColor
        local borderDecalColor = self.borderDecalColor

        link(self.rootNode, node)

        setIsTerrainDecal(node, true)
        setShaderParameter(node, 'diffuseColor', borderColor[1], borderColor[2], borderColor[3], borderColor[4], false)
        setShaderParameter(node, 'decalColor', borderDecalColor[1], borderDecalColor[2], borderDecalColor[3], borderDecalColor[4], false)

        setShaderParameter(node, 'intensitySize', borderIntensity[1], borderIntensity[2], borderIntensity[3], borderIntensity[4], false)
        setShaderParameter(node, 'dashNumLength', borderDash[1], borderDash[2], borderDash[3], borderDash[4], true)
    end
end

function EditorScreen:delete()
    delete(self.rootNode)
    self.childNodes = {}

    self.camera:delete()
    self.cursor:delete()

    FocusManager.guiFocusData[self.CLASS_NAME] = {
        idToElementMapping = {}
    }

    ScreenElement.delete(self)
end

function EditorScreen:load()
    g_gui:loadGui(self.XML_FILENAME, self.CLASS_NAME, self)
end

function EditorScreen:onGuiSetupFinished()
    ScreenElement.onGuiSetupFinished(self)

    self.iconOption:setIcons(table.clone(LandscapingUtils.AREA_ICON_SLICE_IDS))
end

---@param area LandscapingArea
---@param fromMenu? boolean
function EditorScreen:show(area, fromMenu)
    self.area = area
    self.openMenuAfterClose = fromMenu == true

    if g_selectAreaDialog.isOpen then
        g_selectAreaDialog:close()
    end

    g_gui:showGui(self.CLASS_NAME)
end

function EditorScreen:onOpen()
    ScreenElement.onOpen(self)

    self.isMouseMode = g_inputBinding.lastInputMode == GS_INPUT_HELP_MODE_KEYBOARD

    g_inputBinding:setContext(self.INPUT_CONTEXT)
    g_messageCenter:subscribe(MessageType.INPUT_MODE_CHANGED, self.onInputModeChanged, self)

    self:setHasChanged(false)
    self:registerMenuActionEvents(true)

    local viewPortStartX = self.menuBox.absPosition[1] + self.menuBox.absSize[1]

    self.camera:setTerrainRootNode(g_terrainNode)
    self.camera:setEdgeScrollingOffset(viewPortStartX, 0, 1, 1)
    self.camera:activate()

    local mapX, mapZ = self:getCameraFocusWorldPositionXZ()

    if mapX ~= math.huge then
        self.camera:setCameraPosition(mapX, mapZ)
    end

    self.cursor:activate()

    self.originalSafeFrameOffsetX = g_safeFrameOffsetX
    g_safeFrameOffsetX = viewPortStartX + g_safeFrameOffsetX

    self:updateAreaData()

    if self.area ~= nil then
        g_landscapingManager:updateAreaBorderVisibility(self.area, false)
    end

    ---@type GuiElement?
    local focusedElement = FocusManager:getFocusedElement()

    if focusedElement == nil or focusedElement.name == self.CLASS_NAME or focusedElement.disabled then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.nameInput)
        self:setSoundSuppressed(false)
    end

    self.originalInputHelpVisibility = g_currentMission.hud.inputHelp:getVisible()
    g_currentMission.hud:setInputHelpVisible(true, true)
end

function EditorScreen:onClose()
    g_messageCenter:unsubscribeAll(self)

    g_safeFrameOffsetX = self.originalSafeFrameOffsetX
    self.camera:setEdgeScrollingOffset(0, 0, 1, 1)

    self.cursor:deactivate()
    self.camera:deactivate()

    if self.area ~= nil then
        g_landscapingManager:updateAreaBorderVisibility(self.area)
    end

    self.area = nil

    self:removeMenuActionEvents()
    g_currentMission.hud:setInputHelpVisible(self.originalInputHelpVisibility)
    g_inputBinding:revertContext()


    ScreenElement.onClose(self)
end

function EditorScreen:onInputModeChanged(inputMode)
    self.isMouseMode = inputMode[1] == GS_INPUT_HELP_MODE_KEYBOARD
end

---@return number x
---@return number z
function EditorScreen:getCameraFocusWorldPositionXZ()
    return self.area:getCameraFocusWorldPositionXZ()
end

---@param dt number
function EditorScreen:update(dt)
    ScreenElement.update(self, dt)

    g_currentMission.hud.sideNotifications:update(dt)

    self.camera:setCursorLocked(self.cursor.isCatchingCursor)
    self.camera:update(dt)

    if not self.isMouseMode or not self.isMouseInMenu then
        self.cursor:setCameraRay(self.camera:getPickRay())
    else
        self.cursor:setCameraRay()
    end

    self.cursor:update(dt)
end

---@param posX number
---@param posY number
function EditorScreen:mouseEvent(posX, posY)
    self.isMouseInMenu = GuiUtils.checkOverlayOverlap(
        posX, posY,
        self.menuBox.absPosition[1],
        self.menuBox.absPosition[2],
        self.menuBox.absSize[1],
        self.menuBox.absSize[2]
    )

    self.camera.mouseDisabled = self.isMouseInMenu
    self.cursor.mouseDisabled = self.isMouseInMenu

    self.camera:mouseEvent(posX, posY)
    self.cursor:mouseEvent(posX, posY)
end

function EditorScreen:draw()
    ScreenElement.draw(self)

    g_currentMission.hud:drawInputHelp(self.helpDisplay.position[1], self.helpDisplay.position[2])
    g_currentMission.hud.gameInfoDisplay:draw() -- TODO optional
    g_currentMission.hud:drawSideNotification() -- TODO optional
end

function EditorScreen:onButtonPrimary()
    -- void
end

function EditorScreen:onButtonSecondary()
    -- void
end

function EditorScreen:onButtonMenuBack()
    self:requestClose()
end

function EditorScreen:onPressMove()
    -- void
end

function EditorScreen:onPressDelete()
    -- void
end

function EditorScreen:onPressPagePrev()
    -- void
end

function EditorScreen:onPressPageNext()
    -- void
end

---@param hasPanelButtons boolean
function EditorScreen:registerMenuActionEvents(hasPanelButtons)
    local _, eventId = g_inputBinding:registerActionEvent(InputAction.MENU_BACK, self, self.onButtonMenuBack, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_LOW)
    self.backButtonEvent = eventId
    table.insert(self.menuEvents, eventId)

    _, eventId = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_PRIMARY, self, self.onButtonPrimary, false, true, false, true)
    g_inputBinding:setActionEventText(eventId, 'Primary action')
    self.primaryButtonEvent = eventId
    table.insert(self.menuEvents, eventId)

    _, eventId = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_SECONDARY, self, self.onButtonSecondary, false, true, false, true)
    g_inputBinding:setActionEventText(eventId, 'Secondary action')
    self.secondaryButtonEvent = eventId
    table.insert(self.menuEvents, eventId)

    if hasPanelButtons then
        _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onMenuUpDown, false, true, true, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
        table.insert(self.menuEvents, eventId)
        _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onMenuLeftRight, false, true, true, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
        table.insert(self.menuEvents, eventId)
        _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onReleaseUpDown, true, false, false, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
        table.insert(self.menuEvents, eventId)
        _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onReleaseLeftRight, true, false, false, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
        table.insert(self.menuEvents, eventId)
        _, eventId = g_inputBinding:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onPressAccept, false, true, false, true)
        g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_LOW)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
    end
end

function EditorScreen:onMenuUpDown(action, inputValue)
    g_gui:onMenuInput(InputAction.MENU_AXIS_UP_DOWN, inputValue)
end

function EditorScreen:onMenuLeftRight(action, inputValue)
    g_gui:onMenuInput(InputAction.MENU_AXIS_LEFT_RIGHT, inputValue)
end

function EditorScreen:onReleaseUpDown(action)
    g_gui:onReleaseMovement(InputAction.MENU_AXIS_UP_DOWN)
end

function EditorScreen:onReleaseLeftRight(action)
    g_gui:onReleaseMovement(InputAction.MENU_AXIS_LEFT_RIGHT)
end

function EditorScreen:onPressAccept()
    g_gui:notifyControls("MENU_ACCEPT")
end

function EditorScreen:updateMenuActionEvents()
    -- void
end

function EditorScreen:removeMenuActionEvents()
    for _, event in ipairs(self.menuEvents) do
        g_inputBinding:removeActionEvent(event)
    end

    self.menuEvents = {}

    self.primaryButtonEvent = nil
    self.backButtonEvent = nil
    self.secondaryButtonEvent = nil
    self.deleteButtonEvent = nil
    self.moveButtonEvent = nil
end

function EditorScreen:updateAreaData()
    self.nameInput:setText(self.area.name or self.area.uniqueId)
    self.iconOption:setState(self.area.icon)
    self.restrictAreaOption:setIsChecked(self.area.restrictArea, true)

    self:updateOptionsPanel()
end

function EditorScreen:updateFillType()
    ---@type FillTypeObject?
    local fillType = g_fillTypeManager:getFillTypeByIndex(self.area.forceFillTypeIndex)
    local valid = fillType ~= nil

    if fillType ~= nil then
        self.fillTypeImage:setImageFilename(fillType.hudOverlayFilename)
        self.fillTypeText:setText(fillType.title)
    else
        self.fillTypeText:setText(EditorScreen.L10N_SYMBOL.NOT_SET)
    end

    self.fillTypeImage:setVisible(valid)
    self.fillTypeText:setDisabled(not valid)
    self.resetOptionButtons[1]:setDisabled(not valid)
end

function EditorScreen:updateInputLayer()
    local inputLayer = g_landscapingManager:getTerrainLayerById(self.area.forceInputLayer)
    local valid = inputLayer ~= nil

    if inputLayer ~= nil then
        self.inputTerrainLayer:setTerrainLayer(g_terrainNode, inputLayer.id)
        self.inputTerrainLayerText:setText(tostring(inputLayer.title))
    else
        self.inputTerrainLayerText:setText(EditorScreen.L10N_SYMBOL.NOT_SET)
    end

    self.inputTerrainLayer:setVisible(valid)
    self.inputTerrainLayerText:setDisabled(not valid)
    self.resetOptionButtons[2]:setDisabled(not valid)
end

function EditorScreen:updateOutputLayer()
    local outputLayer = g_landscapingManager:getTerrainLayerById(self.area.forceOutputLayer)
    local valid = outputLayer ~= nil

    if outputLayer ~= nil then
        self.outputTerrainLayer:setTerrainLayer(g_terrainNode, outputLayer.id)
        self.outputTerrainLayerText:setText(tostring(outputLayer.title))
    else
        self.outputTerrainLayerText:setText(EditorScreen.L10N_SYMBOL.NOT_SET)
    end

    self.outputTerrainLayer:setVisible(valid)
    self.outputTerrainLayerText:setDisabled(not valid)
    self.resetOptionButtons[3]:setDisabled(not valid)
end

function EditorScreen:updateOptionsPanel()
    self:updateFillType()
    self:updateInputLayer()
    self:updateOutputLayer()
end

function EditorScreen:updateActionPanel()
    local isRegistered = self.area:getIsRegistered()
    local isValid = self.area:getIsValid()
    local hasChanged = self.hasChanged

    if isRegistered then
        self.saveButton:setText(EditorScreen.L10N_SYMBOL.SAVE_CHANGES)
    else
        self.saveButton:setText(EditorScreen.L10N_SYMBOL.SAVE)
    end

    self.saveButton:setDisabled(not (isValid and hasChanged))
end

---@return number[][]
---@nodiscard
function EditorScreen:getPoints()
    -- implemented by inherited class
    return {}
end

---@return string
---@nodiscard
function EditorScreen:getName()
    return self.area.name or self.area.uniqueId
end

---@param value string
function EditorScreen:setName(value)
    self.area.name = value
end

function EditorScreen:onEnterPressedNameInput()
    ---@type string?
    local value = self.nameInput.text
    if value ~= nil then
        value = value:trim()
        if value:len() > 1 then
            self:setName(value)
            self.nameInput:setText(value)
            self:setHasChanged(true)
            return
        end
    end

    self.nameInput:setText(self:getName())
end

function EditorScreen:onClickExit()
    self:requestClose()
end

---@param state number
function EditorScreen:onClickIconOption(state)
    self.area.icon = state
    self:setHasChanged(true)
end

---@param state number
function EditorScreen:onClickRestrictAreaOption(state)
    self.area.restrictArea = state == CheckedOptionElement.STATE_CHECKED
    self:setHasChanged(true)
end

---@param element ButtonElement
function EditorScreen:onClickSelectOption(element)
    if element == self.selectOptionButtons[1] then
        self:onClickSelectFillType()
    elseif element == self.selectOptionButtons[2] then
        self:onClickSelectInputLayer()
    elseif element == self.selectOptionButtons[3] then
        self:onClickSelectOutputLayer()
    end
end

---@param element ButtonElement
function EditorScreen:onClickResetOption(element)
    if element == self.resetOptionButtons[1] then
        self.area.forceFillTypeIndex = nil
        self:updateFillType()
    elseif element == self.resetOptionButtons[2] then
        self.area.forceInputLayer = nil
        self:updateInputLayer()
    elseif element == self.resetOptionButtons[3] then
        self.area.forceOutputLayer = nil
        self:updateOutputLayer()
    end

    self:setHasChanged(true)
end

function EditorScreen:onClickSelectInputLayer()
    g_selectTerrainLayerDialog:setSelectCallback(self.selectInputLayerCallback, self)
    g_selectTerrainLayerDialog:show(self.area.forceInputLayer)
end

---@param terrainLayerId? number
function EditorScreen:selectInputLayerCallback(terrainLayerId)
    if terrainLayerId ~= nil then
        self.area.forceInputLayer = terrainLayerId
        self:updateInputLayer()
        self:setHasChanged(true)
    end
end

function EditorScreen:onClickSelectOutputLayer()
    g_selectTerrainLayerDialog:setSelectCallback(self.selectOutputLayerCallback, self)
    g_selectTerrainLayerDialog:show(self.area.forceOutputLayer)
end

---@param terrainLayerId? number
function EditorScreen:selectOutputLayerCallback(terrainLayerId)
    if terrainLayerId ~= nil then
        self.area.forceOutputLayer = terrainLayerId
        self:updateOutputLayer()
        self:setHasChanged(true)
    end
end

function EditorScreen:onClickSelectFillType()
    g_selectMaterialDialog:setSelectCallback(self.selectFillTypeCallback, self)
    g_selectMaterialDialog:show(self.area.forceFillTypeIndex)
end

---@param fillTypeIndex? number
function EditorScreen:selectFillTypeCallback(fillTypeIndex)
    if fillTypeIndex ~= nil then
        self.area.forceFillTypeIndex = fillTypeIndex
        self:updateFillType()
        self:setHasChanged(true)
    end
end

function EditorScreen:onClickSave()
    if self.area:getIsValid() then
        if self.area:getIsRegistered() then
            g_landscapingManager:updateArea(self.area:clone())
        else
            if g_landscapingManager:getCanCreateArea() then
                g_landscapingManager:registerArea(self.area:clone())
            else
                InfoDialog.show(g_i18n:getText('ui_areasLimitWarning'), nil, nil, DialogElement.TYPE_WARNING)
                return
            end
        end

        self:setHasChanged(false)
    end
end

---@param changed boolean
function EditorScreen:setHasChanged(changed)
    self.hasChanged = changed
    self:updateActionPanel()
end

function EditorScreen:requestClose()
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

function EditorScreen:closeScreen()
    if self.openMenuAfterClose then
        g_gui:showGui('InGameMenu')
    else
        g_gui:showGui(nil)
    end
end
