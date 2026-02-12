---@class MachineSettingsOutputFrame : TabbedMenuFrameElement
---@field target MachineScreen
---@field boxLayout ScrollingLayoutElement
---
---@field terrainLayerButton ButtonElement
---@field terrainLayerText TextElement
---@field terrainLayerImage TerrainLayerElement
---@field enableMaterialOption BinaryOptionElement
---@field enableTextureOption BinaryOptionElement
---@field ratioOption TextInputElement
---@field radiusOption TextInputElement
---@field strengthOption TextInputElement
---@field hardnessOption TextInputElement
---@field brushShapeOption MultiTextOptionElement
---
---@field superClass fun(): TabbedMenuFrameElement
MachineSettingsOutputFrame = {}

MachineSettingsOutputFrame.CLASS_NAME = 'MachineSettingsOutputFrame'
MachineSettingsOutputFrame.XML_FILENAME = g_modDirectory .. 'xml/gui/frames/MachineSettingsOutputFrame.xml'

local MachineSettingsOutputFrame_mt = Class(MachineSettingsOutputFrame, TabbedMenuFrameElement)

---@param target MachineScreen
---@return MachineSettingsOutputFrame
function MachineSettingsOutputFrame.new(target)
    local self = TabbedMenuFrameElement.new(target, MachineSettingsOutputFrame_mt)
    ---@cast self MachineSettingsOutputFrame

    return self
end

function MachineSettingsOutputFrame:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.brushShapeOption:setTexts({
        g_i18n:getText('ui_square'),
        g_i18n:getText('ui_circle')
    })
end

function MachineSettingsOutputFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }
end

function MachineSettingsOutputFrame:onFrameOpen()
    self:superClass().onFrameOpen(self)

    self:updateState()
    self:updateTerrainLayer()

    local disableLayout = #self.target.vehicle.spec_machine.modesOutput == 0

    if self.boxLayout.disabled ~= disableLayout then
        self.boxLayout:setDisabled(disableLayout)
    end

    self.boxLayout:invalidateLayout()

    g_messageCenter:subscribe(SetMachineOutputLayerEvent, self.updateTerrainLayer, self)
    g_messageCenter:subscribe(SetMachineStateEvent, self.updateState, self)

    local focusedElement = FocusManager:getFocusedElement()

    if focusedElement == nil or focusedElement.name == MachineSettingsFrame.CLASS_NAME then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.terrainLayerButton)
        self:setSoundSuppressed(false)
    end
end

function MachineSettingsOutputFrame:onFrameClose()
    self:superClass().onFrameClose(self)

    g_messageCenter:unsubscribeAll(self)
end

function MachineSettingsOutputFrame:updateState(vehicle)
    if vehicle == nil or vehicle == self.target.vehicle then
        local state = self.target.vehicle:getMachineState()

        self.enableMaterialOption:setIsChecked(state.enableOutputMaterial)
        self.enableTextureOption:setIsChecked(state.enableOutputGroundTexture)

        self.ratioOption:setText(string.format('%.2f', state.outputRatio))
        self.radiusOption:setText(string.format('%.2f', state.outputRadius))
        self.strengthOption:setText(string.format('%.2f', state.outputStrength))
        self.hardnessOption:setText(string.format('%.2f', state.outputHardness))
        self.brushShapeOption:setState(state.outputBrushShape)
    end
end

function MachineSettingsOutputFrame:updateTerrainLayer(vehicle)
    if vehicle == nil or vehicle == self.target.vehicle then
        ---@type SpecializationProperties
        local spec = self.target.vehicle.spec_machine

        local terrainLayer = g_resourceManager:getTerrainLayerById(spec.outputTerrainLayerId)

        if terrainLayer ~= nil then
            self.terrainLayerImage:setTerrainLayer(g_terrainNode, terrainLayer.id)
            self.terrainLayerText:setText(terrainLayer.title)
        else
            self.terrainLayerText:setText(string.format('LAYER %s NOT FOUND', tostring(spec.outputTerrainLayerId)))
        end

        self.terrainLayerButton.parent:setDisabled(#spec.modesOutput == 0)
    end
end

---@param property string
---@param value number|boolean
function MachineSettingsOutputFrame:setStateProperty(property, value)
    if self.target.vehicle ~= nil then
        local state = self.target.vehicle:getMachineState()

        state:setProperty(self.target.vehicle, property, value)
    end
end

---@param property string
---@param defaultValue? boolean|number
---@return boolean|number?
function MachineSettingsOutputFrame:getStateProperty(property, defaultValue)
    if self.target.vehicle ~= nil then
        local state = self.target.vehicle:getMachineState()

        return state[property] or defaultValue
    end
end

---@param state number
---@param element CheckedOptionElement
function MachineSettingsOutputFrame:onClickStateCheckedOption(state, element)
    if element.name ~= nil then
        self:setStateProperty(element.name, state == CheckedOptionElement.STATE_CHECKED)
    end
end

---@param state number
function MachineSettingsOutputFrame:onClickBrushShapeOption(state)
    self:setStateProperty('outputBrushShape', state)
end

---@param element TextInputElement
function MachineSettingsOutputFrame:onEnterPressedInput(element)
    ---@diagnostic disable-next-line: param-type-mismatch
    MachineSettingsInputFrame.onEnterPressedInput(self, element)
end

function MachineSettingsOutputFrame:onClickSelectTerrainLayer()
    if self.target.vehicle ~= nil then
        local spec = self.target.vehicle.spec_machine

        g_selectTerrainLayerDialog:setSelectCallback(self.selectTerrainLayerCallback, self)
        g_selectTerrainLayerDialog:show(spec.outputTerrainLayerId)
    end
end

---@param terrainLayerId number | nil
function MachineSettingsOutputFrame:selectTerrainLayerCallback(terrainLayerId)
    if self.target.vehicle ~= nil and terrainLayerId ~= nil then
        self.target.vehicle:setMachineOutputLayerId(terrainLayerId)
    end
end
