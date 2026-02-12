---@class MachineSettingsFrame : TabbedMenuFrameElement
---@field target MachineScreen
---@field boxLayout ScrollingLayoutElement
---
---@field enabledOption BinaryOptionElement
---@field resourcesEnabledOption BinaryOptionElement
---@field paintModifierOption TextInputElement
---@field densityModifierOption TextInputElement
---@field enableEffectsOption BinaryOptionElement
---@field allowGradingUpOption BinaryOptionElement
---@field forceNodesOption BinaryOptionElement
---@field autoDeactivateOption BinaryOptionElement
---@field drivingDirectionModeOption MultiTextOptionElement
---
---@field superClass fun(): TabbedMenuFrameElement
MachineSettingsFrame = {}

MachineSettingsFrame.CLASS_NAME = 'MachineSettingsFrame'
MachineSettingsFrame.XML_FILENAME = g_modDirectory .. 'xml/gui/frames/MachineSettingsFrame.xml'

local MachineSettingsFrame_mt = Class(MachineSettingsFrame, TabbedMenuFrameElement)

---@param target MachineScreen
---@return MachineSettingsFrame
---@nodiscard
function MachineSettingsFrame.new(target)
    local self = TabbedMenuFrameElement.new(target, MachineSettingsFrame_mt)
    ---@cast self MachineSettingsFrame

    return self
end

function MachineSettingsFrame:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.drivingDirectionModeOption:setTexts({
        g_i18n:getText('ui_forwards'),
        g_i18n:getText('ui_backwards'),
        g_i18n:getText('ui_both'),
        g_i18n:getText('ui_ignore'),
    })
end

function MachineSettingsFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }
end

function MachineSettingsFrame:onFrameOpen()
    self:superClass().onFrameOpen(self)

    self:updateMachine()
    self:updateState()

    self.boxLayout:invalidateLayout()

    g_messageCenter:subscribe(SetMachineEnabledEvent, self.updateMachine, self)
    g_messageCenter:subscribe(SetMachineResourcesEvent, self.updateMachine, self)
    g_messageCenter:subscribe(SetMachineStateEvent, self.updateState, self)

    local focusedElement = FocusManager:getFocusedElement()

    if focusedElement == nil or focusedElement.name == MachineSettingsFrame.CLASS_NAME then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.enabledOption)
        self:setSoundSuppressed(false)
    end
end

function MachineSettingsFrame:onFrameClose()
    self:superClass().onFrameClose(self)

    g_messageCenter:unsubscribeAll(self)
end

---@param vehicle Machine | nil
function MachineSettingsFrame:updateMachine(vehicle)
    if vehicle == nil or vehicle == self.target.vehicle then
        local spec = self.target.vehicle.spec_machine
        local hasManagePermission = MachineUtils.getPlayerHasPermission('manageRights', nil, self.target.vehicle:getOwnerFarmId())
        local resourcesAvailable = g_resourceManager:getIsActive()

        self.enabledOption:setIsChecked(spec.enabled)
        self.enabledOption.parent:setDisabled(not hasManagePermission or not g_modSettings:getIsEnabled())

        self.resourcesEnabledOption:setIsChecked(spec.resourcesEnabled)
        self.resourcesEnabledOption.parent:setDisabled(not resourcesAvailable or not hasManagePermission)

        if not g_resourceManager:getIsAvailable() then
            self.resourcesEnabledOption.parent.elements[3]:setText(g_i18n:getText('ui_notAvailable'))
        else
            self.resourcesEnabledOption.parent.elements[3]:setText(g_i18n:getText('ui_enableMapResourcesTooltip'))
        end
    end
end

---@param vehicle Machine | nil
function MachineSettingsFrame:updateState(vehicle)
    if vehicle == nil or vehicle == self.target.vehicle then
        ---@type SpecializationProperties
        local spec = self.target.vehicle.spec_machine

        self.paintModifierOption:setText(string.format('%.2f', spec.state.paintModifier))
        self.densityModifierOption:setText(string.format('%.2f', spec.state.densityModifier))

        self.enableEffectsOption:setIsChecked(spec.state.enableEffects)
        self.allowGradingUpOption:setIsChecked(spec.state.allowGradingUp)
        self.forceNodesOption:setIsChecked(spec.state.forceNodes)
        self.autoDeactivateOption:setIsChecked(spec.state.autoDeactivate)
        self.drivingDirectionModeOption:setState(spec.state.drivingDirectionMode)

        self.enableEffectsOption.parent:setDisabled(#spec.effects == 0)
        self.drivingDirectionModeOption.parent:setDisabled(not (spec.machineType.useDrivingDirection and #spec.modesInput > 0))

        if #spec.effects == 0 then
            self.enableEffectsOption.parent.elements[3]:setText(g_i18n:getText('ui_notAvailable'))
        else
            self.enableEffectsOption.parent.elements[3]:setText(g_i18n:getText('ui_stateEnableEffectsTooltip'))
        end
    end
end

---@param property string
---@param value number|boolean
function MachineSettingsFrame:setStateProperty(property, value)
    if self.target.vehicle ~= nil then
        local state = self.target.vehicle:getMachineState()

        state:setProperty(self.target.vehicle, property, value)
    end
end

---@param property string
---@param defaultValue? boolean|number
---@return boolean|number?
function MachineSettingsFrame:getStateProperty(property, defaultValue)
    if self.target.vehicle ~= nil then
        local state = self.target.vehicle:getMachineState()

        return state[property] or defaultValue
    end
end

---@param state number
---@param element CheckedOptionElement
function MachineSettingsFrame:onClickStateCheckedOption(state, element)
    if element.name ~= nil then
        self:setStateProperty(element.name, state == CheckedOptionElement.STATE_CHECKED)
    end
end

---@param state number
function MachineSettingsFrame:onClickEnabledOption(state)
    if self.target.vehicle ~= nil then
        self.target.vehicle:setMachineEnabled(state == CheckedOptionElement.STATE_CHECKED)
    end
end

---@param state number
function MachineSettingsFrame:onClickResourcesEnabledOption(state)
    if self.target.vehicle ~= nil then
        self.target.vehicle:setResourcesEnabled(state == CheckedOptionElement.STATE_CHECKED)
    end
end

---@param element TextInputElement
function MachineSettingsFrame:onEnterPressedInput(element)
    if element.name ~= nil then
        if element.text ~= '' then
            local value = tonumber(element.text)

            if value ~= nil then
                self:setStateProperty(element.name, MathUtil.round(math.clamp(value, 0.1, 8), 2))
            end
        end

        element:setText(string.format('%.2f', self:getStateProperty(element.name, 0)))
    end
end

function MachineSettingsFrame:onClickSelectMachine()
    g_selectMachineDialog:setSelectCallback(self.selectMachineCallback, self)
    g_selectMachineDialog:show(self.target.vehicle)
end

---@param vehicle Machine | nil
function MachineSettingsFrame:selectMachineCallback(vehicle)
    if vehicle ~= nil and self.target.vehicle ~= nil then
        local spec = vehicle.spec_machine
        local state = spec.state:clone()

        self.target.vehicle:setMachineState(state)
        self.target.vehicle:setMachineFillTypeIndex(spec.fillTypeIndex)
        self.target.vehicle:setMachineInputLayerId(spec.inputTerrainLayerId)
        self.target.vehicle:setMachineOutputLayerId(spec.outputTerrainLayerId)
    end
end

function MachineSettingsFrame:onClickDrivingDirectionModeOption(state)
    self:setStateProperty('drivingDirectionMode', state)
end
