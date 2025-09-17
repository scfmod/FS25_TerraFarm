---@class HUDMachineDisplayElement
---@field isVisible boolean
---@field isEnabled boolean
---@field animation TweenSequence
---@field animateDuration number
---@field boxLayout BoxLayoutElement
---
---@field inputItem BitmapElement
---@field inputTitle TextElement
---@field inputImage BitmapElement
---@field inputText TextElement
---@field outputItem BitmapElement
---@field outputImage BitmapElement
---@field outputText TextElement
---@field materialItem BitmapElement
---@field materialImage BitmapElement
---@field materialText TextElement
---@field textureItem BitmapElement
---@field textureImage TerrainLayerElement
---@field textureText TextElement
---@field dischargeTextureItem BitmapElement
---@field dischargeTextureImage TerrainLayerElement
---@field dischargeTextureText TextElement
---@field surveyorItem BitmapElement
---@field surveyorImage BitmapElement
---@field surveyorTitle TextElement
---@field surveyorText TextElement
---@field vehicleItem BitmapElement
---@field vehicleImage BitmapElement
---@field vehicleText TextElement
---@field elements table<string, GuiElement>
---@field posX number
---@field posY number
HUDMachineDisplayElement = {}

HUDMachineDisplayElement.ANIMATE_DURATION = 150
HUDMachineDisplayElement.CONTROLS = {
    'vehicleItem',
    'vehicleImage',
    'vehicleText',
    'inputItem',
    'inputImage',
    'inputTitle',
    'inputText',
    'outputItem',
    'outputImage',
    'outputTitle',
    'outputText',
    'materialItem',
    'materialImage',
    'materialText',
    'textureItem',
    'textureImage',
    'textureText',
    'dischargeTextureItem',
    'dischargeTextureImage',
    'dischargeTextureText',
    'surveyorItem',
    'surveyorImage',
    'surveyorTitle',
    'surveyorText'
}

local MachineHUDDisplay_mt = Class(HUDMachineDisplayElement)

---@return HUDMachineDisplayElement
---@nodiscard
function HUDMachineDisplayElement.new()
    ---@type HUDMachineDisplayElement
    local self = setmetatable({}, MachineHUDDisplay_mt)

    self.isVisible = true
    self.isEnabled = true
    self.elements = {}

    self.posX = 1
    self.posY = 0.5
    self.animateDuration = HUDMachineDisplayElement.ANIMATE_DURATION

    self.animation = TweenSequence.NO_SEQUENCE

    return self
end

function HUDMachineDisplayElement:delete()
    if self.boxLayout ~= nil then
        self.boxLayout:delete()
        self.boxLayout = nil
    end

    self.animation = nil
end

---@param xmlFile XMLFile
---@param key string
function HUDMachineDisplayElement:loadFromXMLFile(xmlFile, key)
    local profile = xmlFile:getString(key .. '#profile')

    g_gui:loadProfileSet(xmlFile.handle, 'HUD.GuiProfiles', g_gui.presets)

    self.boxLayout = BoxLayoutElement.new()
    self.boxLayout:loadFromXML(xmlFile.handle, key)

    self:loadHUDElements(xmlFile, key, self.boxLayout)
    self:setVisible(g_modSettings.hudEnabled, false)

    self.boxLayout:updateAbsolutePosition()
    self.boxLayout:onGuiSetupFinished()

    self:savePosition()

    self.animateDuration = xmlFile:getFloat('HUD#animateDuration', self.animateDuration)

    for _, id in ipairs(HUDMachineDisplayElement.CONTROLS) do
        if self.elements[id] ~= nil then
            self[id] = self.elements[id]
        else
            Logging.warning('MachineHUDDisplay:loadFromXMLFile() Element with id "%s" not found', id)
        end
    end

    self.elements = {}
end

---@param xmlFile XMLFile
---@param xmlKey string
---@param parent GuiElement
function HUDMachineDisplayElement:loadHUDElements(xmlFile, xmlKey, parent)
    for index = 0, getXMLNumOfChildren(xmlFile.handle, xmlKey) - 1 do
        local key = string.format("%s.*(%i)", xmlKey, index)
        local typeName = getXMLElementName(xmlFile.handle, key)
        -- local class = Gui.CONFIGURATION_CLASS_MAPPING[typeName:upper()] or GuiElement
        local class = Gui.CONFIGURATION_CLASS_MAPPING[typeName:upper()]

        if class == nil then
            Logging.xmlError(xmlFile, "Invalid HUD element \"%s\" (%s)", tostring(class), key)
            return
        end

        local element = class.new()
        local profile = xmlFile:getString(key .. '#profile')

        element.typeName = typeName
        element.handleFocus = false
        element.soundDisabled = true

        parent:addElement(element)
        element:loadFromXML(xmlFile.handle, key)

        self:loadHUDElements(xmlFile, key, element)

        self:onCreateElement(element)
    end
end

---@param element GuiElement
function HUDMachineDisplayElement:onCreateElement(element)
    if element.id ~= nil then
        self.elements[element.id] = element
    end
end

---@param isVisible any
---@param animate boolean | nil
function HUDMachineDisplayElement:setVisible(isVisible, animate)
    if animate and self.animation:getFinished() then
        if isVisible then
            self:animateShow()
        else
            self:animateHide()
        end
    else
        self.animation:stop()

        self.boxLayout:setVisible(isVisible)

        local posX, posY = self:getBasePosition()
        local hideX, hideY = self:getHidingPosition()

        if isVisible then
            self:setPosition(posX, posY)
        else
            self:setPosition(hideX, hideY)
        end
    end

    self.isVisible = isVisible
end

function HUDMachineDisplayElement:setIsEnabled(isEnabled)
    if self.isEnabled ~= isEnabled then
        self.isEnabled = isEnabled

        self.boxLayout:setDisabled(not isEnabled)
    end
end

function HUDMachineDisplayElement:savePosition()
    self.posX, self.posY = self.boxLayout.absPosition[1], self.boxLayout.absPosition[2]
end

---@return number
---@return number
function HUDMachineDisplayElement:getHidingPosition()
    return 1, self.posY
end

---@return number
---@return number
function HUDMachineDisplayElement:getBasePosition()
    return self.posX, self.posY
end

---@return number
---@return number
function HUDMachineDisplayElement:getPosition()
    return self.boxLayout.absPosition[1], self.boxLayout.absPosition[2]
end

---@param posX any
---@param posY any
function HUDMachineDisplayElement:setPosition(posX, posY)
    self.boxLayout:setAbsolutePosition(posX, posY)
end

function HUDMachineDisplayElement:animateShow()
    self.boxLayout:setVisible(true)

    local targetX, targetY = self:getBasePosition()
    local posX, posY = self:getPosition()
    ---@type TweenSequence
    local sequence = TweenSequence.new(self)

    sequence:insertTween(MultiValueTween.new(self.setPosition, { posX, posY }, { targetX, targetY }, self.animateDuration), 0)
    sequence:addCallback(self.onAnimateFinished, true)
    sequence:setCurve(HUDMachineDisplayElement.CURVE_EASE_OUT_CUBIC)
    sequence:start()

    self.animation = sequence
end

---@param t number
---@return number
HUDMachineDisplayElement.CURVE_EASE_OUT_CUBIC = function (t)
    return 1 - math.pow(1 - t, 3)
end

function HUDMachineDisplayElement:animateHide()
    local targetX, targetY = self:getHidingPosition()
    local posX, posY = self:getPosition()
    ---@type TweenSequence
    local sequence = TweenSequence.new(self)

    sequence:insertTween(MultiValueTween.new(self.setPosition, { posX, posY }, { targetX, targetY }, self.animateDuration), 0)
    sequence:addCallback(self.onAnimateFinished, false)
    sequence:setCurve(Tween.CURVE.LINEAR)
    sequence:start()

    self.animation = sequence
end

function HUDMachineDisplayElement:onAnimateFinished(isVisible)
    if not isVisible then
        self.boxLayout:setVisible(false)
    end
end

function HUDMachineDisplayElement:draw()
    if self.boxLayout ~= nil and (self.isVisible or not self.animation:getFinished()) then
        self.boxLayout:draw()
    end
end

---@param dt number
function HUDMachineDisplayElement:update(dt)
    if self.animation ~= nil then
        self.animation:update(dt)
    end
end

function HUDMachineDisplayElement:updateDisplay()
    local vehicle = g_modHud.vehicle

    if vehicle ~= nil then
        local active = vehicle:getMachineActive() and vehicle:getCanActivateMachine()

        self:setIsEnabled(active)

        self:updateVehicleDisplay()
        self:updateModeDisplay()
        self:updateMaterialDisplay()
        self:updateTextureDisplay()
        self:updateDischargeTextureDisplay()
        self:updateSurveyorDisplay()

        self.boxLayout:invalidateLayout()
    end
end

function HUDMachineDisplayElement:updateModeDisplay()
    local spec = g_modHud.vehicle.spec_machine

    if #spec.modesInput > 0 then
        self.inputItem:setVisible(true)
        self.inputImage:setImageSlice(nil, Machine.MODE_ICON_SLICE_ID[spec.inputMode])
        self.inputText:setText(Machine.L10N_MODE[spec.inputMode])
    else
        self.inputItem:setVisible(false)
    end

    if #spec.modesOutput > 0 then
        self.outputItem:setVisible(true)
        self.outputImage:setImageSlice(nil, Machine.MODE_ICON_SLICE_ID[spec.outputMode])
        self.outputText:setText(Machine.L10N_MODE[spec.outputMode])
    else
        self.outputItem:setVisible(false)
    end
end

function HUDMachineDisplayElement:updateMaterialDisplay()
    local spec = g_modHud.vehicle.spec_machine

    ---@type FillTypeObject | nil
    local fillType = g_fillTypeManager:getFillTypeByIndex(spec.fillTypeIndex)

    if fillType ~= nil and spec.machineType.useFillUnit then
        self.materialItem:setVisible(true)
        self.materialImage:setImageFilename(fillType.hudOverlayFilename)
        self.materialText:setText(fillType.title)
    else
        self.materialItem:setVisible(false)
    end
end

function HUDMachineDisplayElement:updateTextureDisplay()
    local spec = g_modHud.vehicle.spec_machine

    if #spec.modesInput > 0 then
        local terrainLayer = g_resourceManager:getTerrainLayerById(spec.terrainLayerId)

        self.textureItem:setVisible(true)
        self.textureImage:setTerrainLayer(g_terrainNode, terrainLayer.id)
        self.textureText:setText(terrainLayer.title)
    else
        self.textureItem:setVisible(false)
    end
end

function HUDMachineDisplayElement:updateDischargeTextureDisplay()
    local spec = g_modHud.vehicle.spec_machine

    if #spec.modesOutput > 0 then
        local terrainLayer = g_resourceManager:getTerrainLayerById(spec.dischargeTerrainLayerId)

        self.dischargeTextureItem:setVisible(true)
        self.dischargeTextureImage:setTerrainLayer(g_terrainNode, terrainLayer.id)
        self.dischargeTextureText:setText(terrainLayer.title)
    else
        self.dischargeTextureItem:setVisible(false)
    end
end

function HUDMachineDisplayElement:updateVehicleDisplay()
    local vehicle = g_modHud.vehicle

    ---@diagnostic disable-next-line: need-check-nil
    self.vehicleImage:setImageFilename(vehicle:getImageFilename())
    ---@diagnostic disable-next-line: need-check-nil
    self.vehicleText:setText(vehicle.spec_machine.machineType.name)
end

function HUDMachineDisplayElement:updateSurveyorDisplay()
    local vehicle = g_modHud.vehicle

    if vehicle ~= nil then
        if vehicle:getInputMode() == Machine.MODE.FLATTEN or vehicle:getOutputMode() == Machine.MODE.FLATTEN then
            local surveyor = vehicle:getSurveyor()

            if surveyor ~= nil then
                self.surveyorItem:setVisible(true)
                self.surveyorImage:setImageFilename(surveyor:getImageFilename())
                self.surveyorTitle:setText(surveyor:getFullName())

                if surveyor:getIsCalibrated() then
                    local angle = surveyor:getCalibrationAngle()

                    if angle ~= 0 then
                        self.surveyorText:setText(string.format(g_i18n:getText('ui_calibratedFormat'), angle))
                    else
                        self.surveyorText:setText(g_i18n:getText('construction_item_level'))
                    end
                else
                    self.surveyorText:setText(SurveyorScreen.L10N_STATUS_NOT_CALIBRATED)
                end
            else
                self.surveyorItem:setVisible(false)
            end
        else
            self.surveyorItem:setVisible(false)
        end
    end
end
