---@class MachineSettingsInputFrame : TabbedMenuFrameElement
---@field target MachineScreen
---@field boxLayout ScrollingLayoutElement
---
---@field terrainLayerButton ButtonElement
---@field terrainLayerText TextElement
---@field terrainLayerImage TerrainLayerElement
---@field materialButton ButtonElement
---@field materialText TextElement
---@field materialImage BitmapElement
---@field enableMaterialOption BinaryOptionElement
---@field enableTextureOption BinaryOptionElement
---@field ratioOption TextInputElement
---@field radiusOption TextInputElement
---@field strengthOption TextInputElement
---@field hardnessOption TextInputElement
---@field brushShapeOption MultiTextOptionElement
---
---@field superClass fun(): TabbedMenuFrameElement
MachineSettingsInputFrame = {}

MachineSettingsInputFrame.CLASS_NAME = 'MachineSettingsInputFrame'
MachineSettingsInputFrame.XML_FILENAME = g_modDirectory .. 'xml/gui/frames/MachineSettingsInputFrame.xml'

local MachineSettingsInputFrame_mt = Class(MachineSettingsInputFrame, TabbedMenuFrameElement)

---@param target MachineScreen
---@return MachineSettingsInputFrame
---@nodiscard
function MachineSettingsInputFrame.new(target)
    local self = TabbedMenuFrameElement.new(target, MachineSettingsInputFrame_mt)
    ---@cast self MachineSettingsInputFrame

    return self
end

function MachineSettingsInputFrame:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.brushShapeOption:setTexts({
        g_i18n:getText('ui_square'),
        g_i18n:getText('ui_circle')
    })
end

function MachineSettingsInputFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }
end

function MachineSettingsInputFrame:onFrameOpen()
    self:superClass().onFrameOpen(self)

    self:updateState()
    self:updateMaterial()
    self:updateTerrainLayer()

    local disableLayout = #self.target.vehicle.spec_machine.modesInput == 0

    if self.boxLayout.disabled ~= disableLayout then
        self.boxLayout:setDisabled(disableLayout)
    end

    self.boxLayout:invalidateLayout()

    g_messageCenter:subscribe(SetMachineFillTypeEvent, self.updateMaterial, self)
    g_messageCenter:subscribe(SetMachineInputLayerEvent, self.updateTerrainLayer, self)
    g_messageCenter:subscribe(SetMachineStateEvent, self.updateState, self)

    local focusedElement = FocusManager:getFocusedElement()

    if focusedElement == nil or focusedElement.name == MachineSettingsFrame.CLASS_NAME then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.materialButton)
        self:setSoundSuppressed(false)
    end
end

function MachineSettingsInputFrame:onFrameClose()
    self:superClass().onFrameClose(self)

    g_messageCenter:unsubscribeAll(self)
end

function MachineSettingsInputFrame:updateState(vehicle)
    if vehicle == nil or vehicle == self.target.vehicle then
        local state = self.target.vehicle:getMachineState()

        self.enableMaterialOption:setIsChecked(state.enableInputMaterial)
        self.enableTextureOption:setIsChecked(state.enableInputGroundTexture)

        self.ratioOption:setText(string.format('%.2f', state.inputRatio))
        self.radiusOption:setText(string.format('%.2f', state.inputRadius))
        self.strengthOption:setText(string.format('%.2f', state.inputStrength))
        self.hardnessOption:setText(string.format('%.2f', state.inputHardness))
        self.brushShapeOption:setState(state.inputBrushShape)
    end
end

function MachineSettingsInputFrame:updateMaterial(vehicle)
    if vehicle == nil or vehicle == self.target.vehicle then
        local fillType = g_fillTypeManager:getFillTypeByIndex(self.target.vehicle:getMachineFillTypeIndex())

        if fillType ~= nil then
            self.materialText:setText(fillType.title)
            self.materialImage:setImageFilename(fillType.hudOverlayFilename)
        else
            self.materialText:setText('')
            self.materialImage:setImageFilename(nil)
        end
    end
end

function MachineSettingsInputFrame:updateTerrainLayer(vehicle)
    if vehicle == nil or vehicle == self.target.vehicle then
        ---@type SpecializationProperties
        local spec = self.target.vehicle.spec_machine

        local terrainLayer = g_resourceManager:getTerrainLayerById(spec.inputTerrainLayerId)

        if terrainLayer ~= nil then
            self.terrainLayerImage:setTerrainLayer(g_terrainNode, terrainLayer.id)
            self.terrainLayerText:setText(terrainLayer.title)
        else
            self.terrainLayerText:setText(string.format('LAYER %s NOT FOUND', tostring(spec.inputTerrainLayerId)))
        end

        self.terrainLayerButton.parent:setDisabled(#spec.modesInput == 0)
    end
end

---@param property string
---@param value number|boolean
function MachineSettingsInputFrame:setStateProperty(property, value)
    if self.target.vehicle ~= nil then
        local state = self.target.vehicle:getMachineState()

        state:setProperty(self.target.vehicle, property, value)
    end
end

---@param property string
---@param defaultValue? boolean|number
---@return boolean|number?
function MachineSettingsInputFrame:getStateProperty(property, defaultValue)
    if self.target.vehicle ~= nil then
        local state = self.target.vehicle:getMachineState()

        return state[property] or defaultValue
    end
end

---@param state number
---@param element CheckedOptionElement
function MachineSettingsInputFrame:onClickStateCheckedOption(state, element)
    if element.name ~= nil then
        self:setStateProperty(element.name, state == CheckedOptionElement.STATE_CHECKED)
    end
end

---@param state number
function MachineSettingsInputFrame:onClickBrushShapeOption(state)
    self:setStateProperty('inputBrushShape', state)
end

---@param element TextInputElement
function MachineSettingsInputFrame:onEnterPressedInput(element)
    if element.name ~= nil then
        if element.text ~= '' then
            local value = tonumber(element.text)

            if value ~= nil then
                if element.name:endsWith('Radius') then
                    self:setStateProperty(element.name, MathUtil.round(math.clamp(value, 0.5, 16), 2))
                elseif element.name:endsWith('Strength') then
                    self:setStateProperty(element.name, MathUtil.round(math.clamp(value, 0.05, 16), 2))
                elseif element.name:endsWith('Hardness') then
                    self:setStateProperty(element.name, MathUtil.round(math.clamp(value, 0.1, 1), 2))
                elseif element.name:endsWith('Ratio') then
                    self:setStateProperty(element.name, MathUtil.round(math.clamp(value, 0, 100), 2))
                end
            end
        end

        element:setText(string.format('%.2f', self:getStateProperty(element.name, 0)))
    end
end

function MachineSettingsInputFrame:onClickSelectMaterial()
    if self.target.vehicle ~= nil then
        local spec = self.target.vehicle.spec_machine

        g_selectMaterialDialog:setSelectCallback(self.selectMaterialCallback, self)
        g_selectMaterialDialog:show(spec.fillTypeIndex)
    end
end

---@param fillTypeIndex number | nil
function MachineSettingsInputFrame:selectMaterialCallback(fillTypeIndex)
    if self.target.vehicle ~= nil and fillTypeIndex ~= nil then
        self.target.vehicle:setMachineFillTypeIndex(fillTypeIndex)
    end
end

function MachineSettingsInputFrame:onClickSelectTerrainLayer()
    if self.target.vehicle ~= nil then
        local spec = self.target.vehicle.spec_machine

        g_selectTerrainLayerDialog:setSelectCallback(self.selectTerrainLayerCallback, self)
        g_selectTerrainLayerDialog:show(spec.inputTerrainLayerId)
    end
end

---@param terrainLayerId number | nil
function MachineSettingsInputFrame:selectTerrainLayerCallback(terrainLayerId)
    if self.target.vehicle ~= nil and terrainLayerId ~= nil then
        self.target.vehicle:setMachineInputLayerId(terrainLayerId)
    end
end
