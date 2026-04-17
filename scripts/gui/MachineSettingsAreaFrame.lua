---@class MachineSettingsAreaFrame : TabbedMenuFrameElement
---@field target MachineScreen
---@field boxLayout BoxLayoutElement
---
---@field inputHeaderElement GuiElement
---@field inputPlaceholderElement GuiElement
---@field inputElement GuiElement
---@field inputAreaImageElement BitmapElement
---@field inputAreaTitleElement TextElement
---@field inputAreaTextElement TextElement
---@field inputAreaStateTextElement TextElement
---@field inputMaterialImageElement BitmapElement
---@field inputMaterialTextElement TextElement
---@field inputTerraformImageElement TerrainLayerElement
---@field inputTerraformTextElement TextElement
---@field inputDischargeImageElement TerrainLayerElement
---@field inputDischargeTextElement TextElement
---@field inputRestrictAreaTextElement TextElement
---@field inputSelectButtonElement ButtonElement
---@field inputResetButtonElement ButtonElement
---@field inputEditButtonElement ButtonElement
---@field inputEnabledOptionElement BinaryOptionElement
---
---@field outputHeaderElement GuiElement
---@field outputPlaceholderElement GuiElement
---@field outputElement GuiElement
---@field outputAreaImageElement BitmapElement
---@field outputAreaTitleElement TextElement
---@field outputAreaTextElement TextElement
---@field outputAreaStateTextElement TextElement
---@field outputMaterialImageElement BitmapElement
---@field outputMaterialTextElement TextElement
---@field outputTerraformImageElement TerrainLayerElement
---@field outputTerraformTextElement TextElement
---@field outputDischargeImageElement TerrainLayerElement
---@field outputDischargeTextElement TextElement
---@field outputRestrictAreaTextElement TextElement
---@field outputSelectButtonElement ButtonElement
---@field outputResetButtonElement ButtonElement
---@field outputEditButtonElement ButtonElement
---@field outputEnabledOptionElement BinaryOptionElement
---
---@field superClass fun(): TabbedMenuFrameElement
MachineSettingsAreaFrame = {}

MachineSettingsAreaFrame.CLASS_NAME = 'MachineSettingsAreaFrame'
MachineSettingsAreaFrame.XML_FILENAME = g_modDirectory .. 'data/gui/MachineSettingsAreaFrame.xml'

MachineSettingsAreaFrame.L10N_SYMBOL = {
    NOT_SET = g_i18n:getText('ui_notSet')
}

local MachineSettingsAreaFrame_mt = Class(MachineSettingsAreaFrame, TabbedMenuFrameElement)

---@param target MachineScreen
---@return MachineSettingsAreaFrame
---@nodiscard
function MachineSettingsAreaFrame.new(target)
    local self = TabbedMenuFrameElement.new(target, MachineSettingsAreaFrame_mt)
    ---@cast self MachineSettingsAreaFrame

    return self
end

function MachineSettingsAreaFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }
end

function MachineSettingsAreaFrame:onFrameOpen()
    self:superClass().onFrameOpen(self)

    self:updateDisplay()

    local focusedElement = FocusManager:getFocusedElement()

    if focusedElement == nil or focusedElement.name == self.CLASS_NAME or focusedElement.disabled or not focusedElement.visible or focusedElement.id == 'buttonsPanel' or focusedElement.id == 'header' then
        self:setSoundSuppressed(true)

        if self.inputSelectButtonElement.visible then
            FocusManager:setFocus(self.inputSelectButtonElement)
        elseif self.outputSelectButtonElement.visible then
            FocusManager:setFocus(self.outputSelectButtonElement)
        end

        self:setSoundSuppressed(false)
    end

    g_messageCenter:subscribe(ModMessageType.LANDSCAPING_AREA_DELETE, self.onLandscapingAreaUpdate, self)
    g_messageCenter:subscribe(ModMessageType.LANDSCAPING_AREA_UPDATE, self.onLandscapingAreaUpdate, self)

    g_messageCenter:subscribe(SetMachineInputAreaEnabledEvent, self.onMachineAreaUpdate, self)
    g_messageCenter:subscribe(SetMachineInputAreaIdEvent, self.onMachineAreaUpdate, self)
    g_messageCenter:subscribe(SetMachineOutputAreaEnabledEvent, self.onMachineAreaUpdate, self)
    g_messageCenter:subscribe(SetMachineOutputAreaIdEvent, self.onMachineAreaUpdate, self)
end

function MachineSettingsAreaFrame:onFrameClose()
    self:superClass().onFrameClose(self)

    g_messageCenter:unsubscribeAll(self)
end

function MachineSettingsAreaFrame:onMachineAreaUpdate(vehicle)
    if vehicle ~= nil and vehicle == self.target.vehicle then
        self:updateDisplay()
    end
end

---@param id string
function MachineSettingsAreaFrame:onLandscapingAreaUpdate(id)
    local vehicle = self.target.vehicle

    if vehicle ~= nil and (vehicle:getMachineInputAreaId() == id or vehicle:getMachineOutputAreaId() == id) then
        self:updateDisplay()
    end
end

---@param element ButtonElement
function MachineSettingsAreaFrame:onClickSelectArea(element)
    if element == self.inputSelectButtonElement then
        ---@param id? string
        ---@param clickOk boolean
        local function callback(id, clickOk)
            self.target:setShowOverlay(false)

            if clickOk and id ~= nil then
                self.target.vehicle:setMachineInputAreaId(id)
            end
        end

        self.target:setShowOverlay(true)

        local inputId = self.target.vehicle:getMachineInputAreaId()

        g_selectAreaDialog:setSelectCallback(callback)
        g_selectAreaDialog:show(inputId, Machine.L10N_ACTION_SELECT_INPUT_AREA)
    elseif element == self.outputSelectButtonElement then
        ---@param id? string
        ---@param clickOk boolean
        local function callback(id, clickOk)
            self.target:setShowOverlay(false)

            if clickOk and id ~= nil then
                self.target.vehicle:setMachineOutputAreaId(id)
            end
        end

        self.target:setShowOverlay(true)

        local outputId = self.target.vehicle:getMachineOutputAreaId()

        g_selectAreaDialog:setSelectCallback(callback)
        g_selectAreaDialog:show(outputId, Machine.L10N_ACTION_SELECT_OUTPUT_AREA)
    end
end

---@param element ButtonElement
function MachineSettingsAreaFrame:onClickReset(element)
    if element == self.inputResetButtonElement then
        self.target.vehicle:setMachineInputAreaId(nil)
    elseif element == self.outputResetButtonElement then
        self.target.vehicle:setMachineOutputAreaId(nil)
    end
end

---@param element ButtonElement
function MachineSettingsAreaFrame:onClickEditArea(element)
    ---@type LandscapingArea?
    local area

    if element == self.inputEditButtonElement then
        area = self.target.vehicle:getMachineInputArea()
    elseif element == self.outputEditButtonElement then
        area = self.target.vehicle:getMachineOutputArea()
    end

    if area ~= nil then
        LandscapingUtils.openAreaInEditor(area)
    end
end

---@param state number
---@param element BinaryOptionElement
function MachineSettingsAreaFrame:onClickStateOption(state, element)
    local vehicle = self.target.vehicle

    if vehicle ~= nil then
        if element == self.inputEnabledOptionElement then
            vehicle:setIsMachineInputAreaEnabled(state == CheckedOptionElement.STATE_CHECKED)
        elseif element == self.outputEnabledOptionElement then
            vehicle:setIsMachineOutputAreaEnabled(state == CheckedOptionElement.STATE_CHECKED)
        end
    end
end

function MachineSettingsAreaFrame:updateDisplay()
    local vehicle = self.target.vehicle

    if vehicle ~= nil then
        if MachineUtils.getHasInputs(vehicle) then
            self:updateInputDisplay(vehicle)
            self.inputHeaderElement:setDisabled(false)
            self.inputSelectButtonElement:setDisabled(false)
            self.inputEnabledOptionElement:setDisabled(false)
        else
            self.inputHeaderElement:setDisabled(true)
            self.inputElement:setVisible(false)
            self.inputSelectButtonElement:setDisabled(true)
            self.inputResetButtonElement:setDisabled(true)
            self.inputEditButtonElement:setDisabled(true)
            self.inputEnabledOptionElement:setDisabled(true)
            self.inputPlaceholderElement:setVisible(false)
        end

        if MachineUtils.getHasOutputs(vehicle) then
            self:updateOutputDisplay(vehicle)
            self.outputHeaderElement:setDisabled(false)
            self.outputSelectButtonElement:setDisabled(false)
            self.outputEnabledOptionElement:setDisabled(false)
        else
            self.outputHeaderElement:setDisabled(true)
            self.outputElement:setVisible(false)
            self.outputSelectButtonElement:setDisabled(true)
            self.outputResetButtonElement:setDisabled(true)
            self.outputEditButtonElement:setDisabled(true)
            self.outputEnabledOptionElement:setDisabled(true)
            self.outputPlaceholderElement:setVisible(false)
        end

        self.boxLayout:invalidateLayout()
    end
end

---@param vehicle Machine
function MachineSettingsAreaFrame:updateInputDisplay(vehicle)
    local area, enabled = vehicle:getMachineInputArea()

    if area ~= nil then
        self.inputPlaceholderElement:setVisible(false)
        self.inputElement:setVisible(true)
        self.inputElement:setDisabled(not enabled)
        self.inputResetButtonElement:setDisabled(false)
        self.inputEditButtonElement:setDisabled(false)

        local iconSliceId = area:getIconSliceId()
        self.inputAreaImageElement:setImageSlice(nil, iconSliceId)
        self.inputAreaImageElement:setImageSlice(GuiOverlay.STATE_DISABLED, iconSliceId)

        local r, g, b = area:getDisplayColor()
        self.inputAreaImageElement:setImageColor(nil, r, g, b)
        self.inputAreaImageElement:setImageColor(GuiOverlay.STATE_DISABLED, r, g, b)

        self.inputAreaTitleElement:setText(area:getTypeName())
        self.inputAreaTextElement:setText(area:getName())
        self.inputAreaStateTextElement:setText(area.restrictArea and g_i18n:getText('ui_on') or g_i18n:getText('ui_off'))

        ---@type FillTypeObject?
        local fillType = g_fillTypeManager:getFillTypeByIndex(area.forceFillTypeIndex)

        if fillType ~= nil then
            self.inputMaterialImageElement:setVisible(true)
            self.inputMaterialImageElement:setImageFilename(fillType.hudOverlayFilename)
            self.inputMaterialTextElement:setText(fillType.title)
        else
            self.inputMaterialImageElement:setVisible(false)
            self.inputMaterialTextElement:setText(MachineSettingsAreaFrame.L10N_SYMBOL.NOT_SET)
        end

        local terraformlayer = g_landscapingManager:getTerrainLayerById(area.forceInputLayer)

        if terraformlayer ~= nil then
            self.inputTerraformImageElement:setVisible(true)
            self.inputTerraformImageElement:setTerrainLayer(g_terrainNode, terraformlayer.id)
            self.inputTerraformTextElement:setText(terraformlayer.title)
        else
            self.inputTerraformImageElement:setVisible(false)
            self.inputTerraformTextElement:setText(MachineSettingsAreaFrame.L10N_SYMBOL.NOT_SET)
        end

        local dischargeLayer = g_landscapingManager:getTerrainLayerById(area.forceOutputLayer)

        if dischargeLayer ~= nil then
            self.inputDischargeImageElement:setVisible(true)
            self.inputDischargeImageElement:setTerrainLayer(g_terrainNode, dischargeLayer.id)
            self.inputDischargeTextElement:setText(dischargeLayer.title)
        else
            self.inputDischargeImageElement:setVisible(false)
            self.inputDischargeTextElement:setText(MachineSettingsAreaFrame.L10N_SYMBOL.NOT_SET)
        end
    else
        self.inputPlaceholderElement:setVisible(true)
        self.inputElement:setVisible(false)
        self.inputResetButtonElement:setDisabled(true)
        self.inputEditButtonElement:setDisabled(true)

        self.inputMaterialImageElement:setVisible(false)
        self.inputTerraformImageElement:setVisible(false)
        self.inputDischargeImageElement:setVisible(false)
    end

    self.inputEnabledOptionElement:setIsChecked(enabled)
end

---@param vehicle Machine
function MachineSettingsAreaFrame:updateOutputDisplay(vehicle)
    local area, enabled = vehicle:getMachineOutputArea()

    if area ~= nil then
        self.outputPlaceholderElement:setVisible(false)
        self.outputElement:setVisible(true)
        self.outputElement:setDisabled(not enabled)
        self.outputResetButtonElement:setDisabled(false)
        self.outputEditButtonElement:setDisabled(false)

        local iconSliceId = area:getIconSliceId()
        self.outputAreaImageElement:setImageSlice(nil, iconSliceId)
        self.outputAreaImageElement:setImageSlice(GuiOverlay.STATE_DISABLED, iconSliceId)

        local r, g, b = area:getDisplayColor()
        self.outputAreaImageElement:setImageColor(nil, r, g, b)
        self.outputAreaImageElement:setImageColor(GuiOverlay.STATE_DISABLED, r, g, b)

        self.outputAreaTitleElement:setText(area:getTypeName())
        self.outputAreaTextElement:setText(area:getName())
        self.outputAreaStateTextElement:setText(area.restrictArea and g_i18n:getText('ui_on') or g_i18n:getText('ui_off'))

        ---@type FillTypeObject?
        local fillType = g_fillTypeManager:getFillTypeByIndex(area.forceFillTypeIndex)

        if fillType ~= nil then
            self.outputMaterialImageElement:setVisible(true)
            self.outputMaterialImageElement:setImageFilename(fillType.hudOverlayFilename)
            self.outputMaterialTextElement:setText(fillType.title)
        else
            self.outputMaterialImageElement:setVisible(false)
            self.outputMaterialTextElement:setText(MachineSettingsAreaFrame.L10N_SYMBOL.NOT_SET)
        end

        local terraformLayer = g_landscapingManager:getTerrainLayerById(area.forceInputLayer)

        if terraformLayer ~= nil then
            self.outputTerraformImageElement:setVisible(true)
            self.outputTerraformImageElement:setTerrainLayer(g_terrainNode, terraformLayer.id)
            self.outputTerraformTextElement:setText(terraformLayer.title)
        else
            self.outputTerraformImageElement:setVisible(false)
            self.outputTerraformTextElement:setText(MachineSettingsAreaFrame.L10N_SYMBOL.NOT_SET)
        end

        local dischargeLayer = g_landscapingManager:getTerrainLayerById(area.forceOutputLayer)

        if dischargeLayer ~= nil then
            self.outputDischargeImageElement:setVisible(true)
            self.outputDischargeImageElement:setTerrainLayer(g_terrainNode, dischargeLayer.id)
            self.outputDischargeTextElement:setText(dischargeLayer.title)
        else
            self.outputDischargeImageElement:setVisible(false)
            self.outputDischargeTextElement:setText(MachineSettingsAreaFrame.L10N_SYMBOL.NOT_SET)
        end
    else
        self.outputPlaceholderElement:setVisible(true)
        self.outputElement:setVisible(false)
        self.outputResetButtonElement:setDisabled(true)
        self.outputEditButtonElement:setDisabled(true)

        self.outputMaterialImageElement:setVisible(false)
        self.outputTerraformImageElement:setVisible(false)
        self.outputDischargeImageElement:setVisible(false)
    end

    self.outputEnabledOptionElement:setIsChecked(enabled)
end
