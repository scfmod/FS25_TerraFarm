---@class EditorWaterplane : EditorAreaPolygon
---@field area nil
---@field hasPointsChanged boolean
---@field editPoints boolean
---@field planeRootNode number
---@field waterplane LandscapingWaterplane
---@field visibleOption BinaryOptionElement
---@field colorOption MultiTextOptionElement
---@field superClass fun(): EditorAreaPolygon
EditorWaterplane = {}
EditorWaterplane.CLASS_NAME = 'EditorWaterplane'
EditorWaterplane.XML_FILENAME = g_modDirectory .. 'data/gui/editor/EditorWaterplane.xml'
EditorWaterplane.INPUT_CONTEXT = 'WATERPLANE_EDITOR'

EditorWaterplane.COLOR = {
    POINT = { 0, 0.25, 0.451 },
    SELECTED_POINT = { 1, 0.765, 0 },
    EXTEND_POINT = { 1, 1, 1 },
    HIGHLIGHT_POINT = { 0, 0.25, 0.451 },
    LINE = { 0, 0.25, 0.451 },
}

local EditorWaterplane_mt = Class(EditorWaterplane, EditorAreaPolygon)

---@return EditorWaterplane
---@nodiscard
function EditorWaterplane.new()
    local self = EditorAreaPolygon.new(EditorWaterplane_mt)
    ---@cast self EditorWaterplane

    self.hasPointsChanged = false
    self.editPoints = false

    self.planeRootNode = createTransformGroup('editor_waterplane_root')
    link(getRootNode(), self.planeRootNode)

    return self
end

function EditorWaterplane:loadShapes()
    self.borderDecalColor = { 0, 0.1, 0.6, 0.75 }
    self.borderColor = { 0, 0.25, 0.8, 1 }

    EditorAreaPolygon.loadShapes(self)
end

function EditorWaterplane:delete()
    LandscapingUtils.deleteWaterplaneShapes(self.planeRootNode)
    delete(self.planeRootNode)

    EditorAreaPolygon.delete(self)
end

function EditorWaterplane:onGuiSetupFinished()
    ScreenElement.onGuiSetupFinished(self)

    local texts = {}

    for _, data in pairs(LandscapingWaterplane.COLOR_DATA) do
        table.insert(texts, data.name)
    end

    self.colorOption:setTexts(texts)
end

---@param waterplane LandscapingWaterplane
---@param fromMenu? boolean
function EditorWaterplane:show(waterplane, fromMenu)
    self.waterplane = waterplane
    self.openMenuAfterClose = fromMenu == true

    g_gui:showGui(self.CLASS_NAME)
end

function EditorWaterplane:onOpen()
    EditorAreaPolygon.onOpen(self)

    g_landscapingManager:setWaterplanesVisible(false)
    self:updatePlaneShapes()
end

function EditorWaterplane:onClose()
    EditorAreaPolygon.onClose(self)

    LandscapingUtils.deleteWaterplaneShapes(self.planeRootNode)
    g_landscapingManager:setWaterplanesVisible(true)
end

---@param mode EditorAreaPolygonMode
function EditorWaterplane:setMode(mode)
    local points = self:getPoints()

    if mode == EditorAreaPolygon.MODE.SELECT and #points == 0 then
        self.selectedIndex = nil
        self.direction = 1
        mode = EditorAreaPolygon.MODE.ADD_POINT
    elseif self.mode ~= mode and mode == EditorAreaPolygon.MODE.NONE then
        if self.editPoints then
            self:updatePlaneShapes()
            self.editPoints = false
        end
    end

    self.mode = mode

    setVisibility(self.planeRootNode, self.mode == EditorAreaPolygon.MODE.NONE)
    self:registerMenuActionEvents(self.mode == EditorAreaPolygon.MODE.NONE)
    self:updatePanels()
    self:updatePositionText()
end

function EditorWaterplane:addPoint()
    if EditorAreaPolygon.addPoint(self) then
        self.hasPointsChanged = true
        self.editPoints = true
    end
end

function EditorWaterplane:deletePoint()
    if EditorAreaPolygon.deletePoint(self) then
        self.hasPointsChanged = true
        self.editPoints = true
    end
end

function EditorWaterplane:movePoint()
    if EditorAreaPolygon.movePoint(self) then
        self.hasPointsChanged = true
        self.editPoints = true
    end
end

function EditorWaterplane:setTargetHeight()
    if EditorAreaPolygon.setTargetHeight(self) then
        self.hasPointsChanged = true
        self.editPoints = true
    end
end

---@param value number
function EditorWaterplane:moveSelectedPointY(value)
    if EditorAreaPolygon.moveSelectedPointY(self, value) then
        self.hasPointsChanged = true
        self.editPoints = true
    end
end

---@param value number
function EditorWaterplane:moveSelectedPointX(value)
    if EditorAreaPolygon.moveSelectedPointX(self, value) then
        self.hasPointsChanged = true
        self.editPoints = true
    end
end

function EditorWaterplane:updateAreaData()
    self.nameInput:setText(self.waterplane.name or self.waterplane.uniqueId)
    self.visibleOption:setIsChecked(self.waterplane.visible)
    self.colorOption:setState(self.waterplane.color)

    self:updateHeightInput()
end

function EditorWaterplane:updateOptionsPanel()
    -- void, not needed
end

function EditorWaterplane:onEnterPressedHeightInput()
    local value = tonumber(self.heightInput.text)

    if value ~= nil then
        value = MathUtil.round(value, 2)
        self:setTargetY(value)
        self:updateAreaBorder()
        self:updateHeightInput()
        self:setHasChanged(true)
        self:updatePlaneShapes()
    end

    self:updateHeightInput()
end

function EditorWaterplane:onClickVisibleOption(state)
    self.waterplane.visible = state == CheckedOptionElement.STATE_CHECKED
    self:setHasChanged(true)
end

function EditorWaterplane:onClickColorOption(state)
    self.waterplane.color = state
    self:updatePlaneShapes()
    self:setHasChanged(true)
end

function EditorWaterplane:onClickSave()
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

function EditorWaterplane:setHasChanged(changed)
    if changed == false then
        self.hasPointsChanged = false
    end

    EditorAreaPolygon.setHasChanged(self, changed)
end

function EditorWaterplane:updateAreaBorder()
    self.waterplane:updateAreaBorder(self.shape, self.rootNode, self.childNodes)
end

---@return [number, number][]
---@nodiscard
function EditorWaterplane:getPoints()
    return self.waterplane.points
end

---@return number
---@nodiscard
function EditorWaterplane:getTargetY()
    return self.waterplane.targetY
end

---@param value number
function EditorWaterplane:setTargetY(value)
    self.waterplane.targetY = value
    self:updatePositionText()
end

---@param value string
function EditorWaterplane:setName(value)
    self.waterplane.name = value
end

---@return string
---@nodiscard
function EditorWaterplane:getName()
    return self.waterplane.name or self.waterplane.uniqueId
end

function EditorWaterplane:loadPlaneAttributes()
    self.waterMaterial = g_materialManager:getBaseMaterialByName("riceFieldWaterSimulation")
    self.waterMirrorMaterial = g_materialManager:getBaseMaterialByName("riceFieldWaterInMirror")
end

function EditorWaterplane:updatePlaneShapes()
    LandscapingUtils.deleteWaterplaneShapes(self.planeRootNode)

    if self.waterplane.targetY ~= math.huge and #self.waterplane.points > 2 then
        local vertices = self.waterplane:getVertices()
        LandscapingUtils.createWaterplaneShapesFromVertices(self.planeRootNode, vertices, self.waterplane.color)

        setWorldTranslation(self.planeRootNode, 0, self.waterplane.targetY, 0)
    end
end

function EditorWaterplane:updateActionPanel()
    if self.mode ~= EditorAreaPolygon.MODE.NONE then
        self.saveButton:setDisabled(true)
    else
        local isRegistered = self.waterplane:getIsRegistered()
        local isValid = self.waterplane:getIsValid()
        local hasChanged = self.hasChanged

        if isRegistered then
            self.saveButton:setText(EditorScreen.L10N_SYMBOL.SAVE_CHANGES)
        else
            self.saveButton:setText(EditorScreen.L10N_SYMBOL.SAVE)
        end
        self.saveButton:setDisabled(not (isValid and hasChanged))
    end
end

function EditorWaterplane:getCameraFocusWorldPositionXZ()
    return self.waterplane:getCameraFocusWorldPositionXZ()
end
