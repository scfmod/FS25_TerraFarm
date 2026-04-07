---@class AreaEditor: Editor
---@field superClass fun(): Editor
---
---@field area LandscapingArea
---@field iconOptionElement TFIconOptionElement
---@field colorOptionElement MultiTextOptionElement
---@field restrictOptionElement BinaryOptionElement
---@field materialImageElement BitmapElement
---@field materialTextElement TextElement
---@field materialButtonElement ButtonElement
---@field materialResetButtonElement ButtonElement
---@field inputLayerImageElement TerrainLayerElement
---@field inputLayerTextElement TextElement
---@field inputLayerButtonElement ButtonElement
---@field inputLayerResetButtonElement ButtonElement
---@field outputLayerImageElement TerrainLayerElement
---@field outputLayerTextElement TextElement
---@field outputLayerButtonElement ButtonElement
---@field outputLayerResetButtonElement ButtonElement
AreaEditor = {}

local AreaEditor_mt = Class(AreaEditor, Editor)

---@param customMt table
---@return AreaEditor
---@nodiscard
function AreaEditor.new(customMt)
    local self = Editor.new(customMt)
    ---@cast self AreaEditor

    return self
end

function AreaEditor:onGuiSetupFinished()
    AreaEditor:superClass().onGuiSetupFinished(self)

    self.iconOptionElement:setIcons(table.clone(LandscapingUtils.AREA_ICON_SLICE_IDS))
    self.colorOptionElement:setTexts(table.clone(LandscapingUtils.AREA_COLOR_NAMES))
end

---@param area LandscapingArea
---@param showInGameMenuWhenClosed? boolean
function AreaEditor:show(area, showInGameMenuWhenClosed)
    self.area = area
    self.points = area.points
    self.showInGameMenuWhenClosed = showInGameMenuWhenClosed or false

    if g_selectAreaDialog.isOpen then
        g_selectAreaDialog:close()
    end

    g_gui:showGui(self.CLASS_NAME)
end

function AreaEditor:onOpen()
    AreaEditor:superClass().onOpen(self)

    self:setMode(EditorMode.NONE)

    g_landscapingManager:updateAreaBorderVisibility(self.area, false)

    self:updateBorderColor()
    self:updateBorder()
    self:setBorderVisibility(true)
    self:updateDisplayText()

    ---@type GuiElement?
    local focusedElement = FocusManager:getFocusedElement()

    if focusedElement == nil or focusedElement.name == self.CLASS_NAME or focusedElement.disabled then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.nameInputElement)
        self:setSoundSuppressed(false)
    end
end

function AreaEditor:onClose()
    g_landscapingManager:updateAreaBorderVisibility(self.area)

    self:setBorderVisibility(false)

    self.area = nil
    self.points = nil

    AreaEditor:superClass().onClose(self)
end

---@param mode EditorMode
function AreaEditor:setMode(mode)
    local previousMode = self.mode

    if mode == EditorMode.SELECT_POINT and #self.points == 0 then
        self.selectedIndex = nil
        self.placementDirection = EditorDirection.POSITIVE
        mode = EditorMode.CREATE_POINT
    end

    self.mode = mode

    if mode ~= previousMode and (mode == EditorMode.NONE or previousMode == EditorMode.NONE) then
        self:registerActionEvents()
        self:updateBorderColor()
    else
        self:updateActionEvents()
    end

    self:updatePanels()
    self:updateDisplayText()
end

function AreaEditor:updateBorder()
    self.area:updateAreaBorder(self.borderShape, self.borderRootNode, self.borderChildNodes)
end

---@return string
---@nodiscard
function AreaEditor:getName()
    return self.area.name or self.area.uniqueId
end

---@param name string
function AreaEditor:setName(name)
    self.area.name = name
end

---@return number x
---@return number z
function AreaEditor:getCameraFocusWorldPositionXZ()
    return self.area:getCameraFocusWorldPositionXZ()
end

function AreaEditor:updateData()
    self.iconOptionElement:setState(self.area.icon)
    self.colorOptionElement:setState(self.area.color)
    self.restrictOptionElement:setIsChecked(self.area.restrictArea, true)

    self:updateFillTypeInput(self.area.forceFillTypeIndex, self.materialImageElement, self.materialTextElement, self.materialResetButtonElement)
    self:updateTerrainLayerInput(self.area.forceInputLayer, self.inputLayerImageElement, self.inputLayerTextElement, self.inputLayerResetButtonElement)
    self:updateTerrainLayerInput(self.area.forceOutputLayer, self.outputLayerImageElement, self.outputLayerTextElement, self.outputLayerResetButtonElement)

    AreaEditor:superClass().updateData(self)
end

function AreaEditor:updateControlPanel()
    local visible = self.mode == EditorMode.NONE

    self.controlPanelElement:setVisible(visible)

    if visible then
        local disabled = not (self.area:getIsValid() and self.hasChanged)

        self.saveButtonElement:setDisabled(disabled)

        if self.area:getIsRegistered() then
            self.saveButtonElement:setText(Editor.L10N_SYMBOL.SAVE_CHANGES)
        else
            self.saveButtonElement:setText(Editor.L10N_SYMBOL.SAVE)
        end

        if self:isa(PathEditor) then
            self.moveButtonElement:setDisabled(#self.points < 2)
        else
            self.moveButtonElement:setDisabled(#self.points < 3)
        end
    end
end

function AreaEditor:updateDataPanel()
    self.dataPanelElement:setVisible(self.mode == EditorMode.NONE)

    AreaEditor:superClass().updateDataPanel(self)
end

---@param state number
---@param element BinaryOptionElement
function AreaEditor:onPressedOption(state, element)
    if element == self.restrictOptionElement then
        self.area.restrictArea = element:getIsChecked()
        self:setHasChanged(true)
    elseif element == self.iconOptionElement then
        self.area.icon = state
        self:setHasChanged(true)
    else
        AreaEditor:superClass().onPressedOption(self, state, element)
    end
end

---@param state number
function AreaEditor:onClickColorOption(state)
    self.area.color = state
    self:setHasChanged(true)
    self:updateBorderColor()
end

function AreaEditor:updateBorderColor()
    setVisibility(self.borderRootNode, false)

    if self.mode == EditorMode.NONE then
        local diffuseColor, decalColor = self.area:getBorderColor()
        LandscapingUtils.setAreaBorderColor(self.borderRootNode, diffuseColor, nil, decalColor, nil)
    else
        LandscapingUtils.setAreaBorderColor(self.borderRootNode, self.editBorderColor, nil, self.editBorderDecalColor, nil)
    end

    setVisibility(self.borderRootNode, true)
end

function AreaEditor:onClickSave()
    if self.area:getIsValid() then
        if self.area:getIsRegistered() then
            g_landscapingManager:updateArea(self.area:clone())
            g_landscapingManager:updateAreaBorderVisibility(self.area, false)
        else
            if g_landscapingManager:getCanCreateArea() then
                g_landscapingManager:registerArea(self.area:clone())
                g_landscapingManager:updateAreaBorderVisibility(self.area, false)
            else
                InfoDialog.show(g_i18n:getText('ui_areasLimitWarning'), nil, nil, DialogElement.TYPE_WARNING)
                return
            end
        end

        self:setHasChanged(false)
    end
end

---@param element ButtonElement
function AreaEditor:onPressedDataButton(element)
    if element == self.materialButtonElement then
        local function callback(fillTypeIndex)
            if fillTypeIndex ~= nil then
                self.area.forceFillTypeIndex = fillTypeIndex
                self:updateFillTypeInput(fillTypeIndex, self.materialImageElement, self.materialTextElement, self.materialResetButtonElement)
                self:setHasChanged(true)
            end
        end

        g_selectMaterialDialog:setSelectCallback(callback)
        g_selectMaterialDialog:show(self.area.forceFillTypeIndex)
    elseif element == self.inputLayerButtonElement then
        local function callback(layerId)
            if layerId ~= nil then
                self.area.forceInputLayer = layerId
                self:updateTerrainLayerInput(layerId, self.inputLayerImageElement, self.inputLayerTextElement, self.inputLayerResetButtonElement)
                self:setHasChanged(true)
            end
        end

        g_selectTerrainLayerDialog:setSelectCallback(callback)
        g_selectTerrainLayerDialog:show(self.area.forceInputLayer)
    elseif element == self.outputLayerButtonElement then
        local function callback(layerId)
            if layerId ~= nil then
                self.area.forceOutputLayer = layerId
                self:updateTerrainLayerInput(layerId, self.outputLayerImageElement, self.outputLayerTextElement, self.outputLayerResetButtonElement)
                self:setHasChanged(true)
            end
        end

        g_selectTerrainLayerDialog:setSelectCallback(callback)
        g_selectTerrainLayerDialog:show(self.area.forceOutputLayer)
    end
end

---@param element ButtonElement
function AreaEditor:onPressedDataResetButton(element)
    if element == self.materialResetButtonElement then
        self.area.forceFillTypeIndex = nil
        self:updateFillTypeInput(nil, self.materialImageElement, self.materialTextElement, self.materialResetButtonElement)
        self:setHasChanged(true)
    elseif element == self.inputLayerResetButtonElement then
        self.area.forceInputLayer = nil
        self:updateTerrainLayerInput(nil, self.inputLayerImageElement, self.inputLayerTextElement, self.inputLayerResetButtonElement)
        self:setHasChanged(true)
    elseif element == self.outputLayerResetButtonElement then
        self.area.forceOutputLayer = nil
        self:updateTerrainLayerInput(nil, self.outputLayerImageElement, self.outputLayerTextElement, self.outputLayerResetButtonElement)
        self:setHasChanged(true)
    end
end
