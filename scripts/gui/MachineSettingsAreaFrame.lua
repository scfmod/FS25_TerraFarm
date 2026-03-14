---@class MachineSettingsAreaFrame : TabbedMenuFrameElement
---@field target MachineScreen
---@field boxLayout BoxLayoutElement
---@field selectAreaButton ButtonElement
---@field selectMachineButton ButtonElement
---@field resetButton ButtonElement
---@field statusLayout BoxLayoutElement
---@field statusText TextElement
---@field infoBox BitmapElement
---@field areaImage BitmapElement
---@field areaTitle TextElement
---@field areaText TextElement
---@field ignoreAreaMaterialOption BinaryOptionElement
---@field ignoreAreaGroundTexturesOption BinaryOptionElement
---@field superClass fun(): TabbedMenuFrameElement
MachineSettingsAreaFrame = {}

MachineSettingsAreaFrame.CLASS_NAME = 'MachineSettingsAreaFrame'
MachineSettingsAreaFrame.XML_FILENAME = g_modDirectory .. 'data/gui/MachineSettingsAreaFrame.xml'

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

    self:updateSettings()
    self:updateState()

    self.boxLayout:invalidateLayout()

    local focusedElement = FocusManager:getFocusedElement()

    if focusedElement == nil or focusedElement.name == self.CLASS_NAME or focusedElement.id == 'buttonsPanel' or focusedElement.id == 'header' then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.selectAreaButton)
        self:setSoundSuppressed(false)
    end

    g_messageCenter:subscribe(SetMachineLandscapingAreaEvent, self.updateSettings, self)
    g_messageCenter:subscribe(SetMachineStateEvent, self.updateState, self)
end

function MachineSettingsAreaFrame:onFrameClose()
    self:superClass().onFrameClose(self)

    g_messageCenter:unsubscribeAll(self)
end

---@param vehicle? Machine
function MachineSettingsAreaFrame:updateSettings(vehicle)
    if vehicle == nil or vehicle == self.target.vehicle then
        local area = self.target.vehicle:getMachineLandscapingArea()

        if area ~= nil then
            self.infoBox:setDisabled(false)
            self.areaTitle:setText(area:getName())
            self.areaText:setText(area:getTypeName())
            self.areaImage:setImageSlice(nil, area:getIconSliceId())
            self.areaImage:setVisible(true)
            self.resetButton:setDisabled(false)
        else
            self.infoBox:setDisabled(true)
            self.areaText:setText('')
            self.areaTitle:setText(g_i18n:getText('ui_notSet'))
            self.areaImage:setVisible(false)
            self.resetButton:setDisabled(true)
        end
    end
end

---@param vehicle? Machine
function MachineSettingsAreaFrame:updateState(vehicle)
    if vehicle == nil or vehicle == self.target.vehicle then
        local state = self.target.vehicle:getMachineState()

        self.ignoreAreaMaterialOption:setIsChecked(state.ignoreAreaMaterial)
        self.ignoreAreaGroundTexturesOption:setIsChecked(state.ignoreAreaGroundTextures)
    end
end

function MachineSettingsAreaFrame:onClickSelectArea()
    if self.target.vehicle ~= nil then
        g_selectAreaDialog:setSelectCallback(self.selectAreaCallback, self)
        g_selectAreaDialog:show(self.target.vehicle)
    end
end

---@param area? LandscapingArea
function MachineSettingsAreaFrame:selectAreaCallback(area)
    if self.target.vehicle ~= nil and area ~= nil then
        self.target.vehicle:setMachineLandscapingArea(area.uniqueId)
    end
end

function MachineSettingsAreaFrame:onClickSelectMachine()
    if self.target.vehicle ~= nil then
        g_selectMachineDialog:setSelectCallback(self.selectMachineCallback, self)
        g_selectMachineDialog:show(self.target.vehicle)
    end
end

---@param vehicle Machine
function MachineSettingsAreaFrame:selectMachineCallback(vehicle)
    if self.target.vehicle ~= nil and vehicle ~= nil then
        local area = vehicle:getMachineLandscapingArea()

        if area ~= nil then
            self.target.vehicle:setMachineLandscapingArea(area.uniqueId)
        end
    end
end

function MachineSettingsAreaFrame:onClickReset()
    if self.target.vehicle ~= nil then
        self.target.vehicle:setMachineLandscapingArea(nil)
    end
end

function MachineSettingsAreaFrame:onClickCreateArea()
    LandscapingUtils.createAreaInEditor()
end

function MachineSettingsAreaFrame:onClickEditArea()
    if self.target.vehicle ~= nil then
        local area = self.target.vehicle:getMachineLandscapingArea()

        if area ~= nil then
            LandscapingUtils.openAreaInEditor(area)
        end
    end
end

function MachineSettingsAreaFrame:onClickStateCheckedOption(state, element)
    if element.name ~= nil then
        ---@diagnostic disable-next-line: param-type-mismatch
        MachineSettingsInputFrame.setStateProperty(self, element.name, state == CheckedOptionElement.STATE_CHECKED)
    end
end
