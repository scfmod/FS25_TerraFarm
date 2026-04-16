---@class HUDMachineDisplayElement
---@field isVisible boolean
---@field isEnabled boolean
---@field animation TweenSequence
---@field animateDuration number
---@field boxLayout BoxLayoutElement
---
---@field vehicleDisplayElement BitmapElement
---@field vehicleDisplayImageElement BitmapElement
---@field vehicleDisplayTitleElement TextElement
---@field vehicleDisplayTextElement TextElement
---
---@field materialDisplayElement BitmapElement
---@field materialDisplayImageElement BitmapElement
---@field materialDisplayTitleElement TextElement
---@field materialDisplayTextElement TextElement
---
---@field inputDisplayElement BoxLayoutElement
---
---@field inputDisplayModeElement BitmapElement
---@field inputDisplayModeImageElement BitmapElement
---@field inputDisplayModeTitleElement TextElement
---@field inputDisplayModeTextElement TextElement
---
---@field inputDisplayTextureElement BitmapElement
---@field inputDisplayTextureImageElement TerrainLayerElement
---@field inputDisplayTextureTitleElement TextElement
---@field inputDisplayTextureTextElement TextElement
---
---@field inputDisplayAreaElement BitmapElement
---@field inputDisplayAreaImageElement BitmapElement
---@field inputDisplayAreaTitleElement TextElement
---@field inputDisplayAreaTextElement TextElement
---@field inputDisplayAreaColorElement BitmapElement
---
---@field outputDisplayElement BoxLayoutElement
---
---@field outputDisplayModeElement BitmapElement
---@field outputDisplayModeImageElement BitmapElement
---@field outputDisplayModeTitleElement TextElement
---@field outputDisplayModeTextElement TextElement
---
---@field outputDisplayTextureElement BitmapElement
---@field outputDisplayTextureImageElement TerrainLayerElement
---@field outputDisplayTextureTitleElement TextElement
---@field outputDisplayTextureTextElement TextElement
---
---@field outputDisplayAreaElement BitmapElement
---@field outputDisplayAreaImageElement BitmapElement
---@field outputDisplayAreaTitleElement TextElement
---@field outputDisplayAreaTextElement TextElement
---@field outputDisplayAreaColorElement BitmapElement
---
---@field elements table<string, GuiElement>
---@field posX number
---@field posY number
HUDMachineDisplayElement = {}

HUDMachineDisplayElement.ANIMATE_DURATION = 150

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
    self.elements = {}
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
end

---@param xmlFile XMLFile
---@param xmlKey string
---@param parent GuiElement
function HUDMachineDisplayElement:loadHUDElements(xmlFile, xmlKey, parent)
    for index = 0, getXMLNumOfChildren(xmlFile.handle, xmlKey) - 1 do
        local key = string.format("%s.*(%i)", xmlKey, index)
        local typeName = getXMLElementName(xmlFile.handle, key)
        local class = Gui.CONFIGURATION_CLASS_MAPPING[typeName:upper()]

        if class == nil then
            Logging.xmlError(xmlFile, "Invalid HUD element \"%s\" (%s)", tostring(class), key)
            return
        end

        local element = class.new()

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
        self[element.id] = element
    end
end

---@param isVisible any
---@param animate boolean?
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
    local vehicle = g_machineManager.activeVehicle

    if vehicle ~= nil then
        local active = vehicle:getMachineActive() and vehicle:getCanActivateMachine()

        self:setIsEnabled(active)

        self:updateVehicleDisplay(vehicle)
        self:updateMaterialDisplay(vehicle)

        self:updateInputDisplay(vehicle)
        self:updateOutputDisplay(vehicle)

        self.boxLayout:invalidateLayout()
    end
end

---@param vehicle Machine
function HUDMachineDisplayElement:updateInputDisplay(vehicle)
    if MachineUtils.getHasInputs(vehicle) then
        local area, areaEnabled = vehicle:getMachineInputArea()
        local layerId = vehicle:getMachineInputLayerId()

        if area and areaEnabled then
            layerId = area.forceInputLayer or layerId

            local iconSliceId = area:getIconSliceId()

            self.inputDisplayAreaImageElement:setImageSlice(nil, iconSliceId)
            self.inputDisplayAreaTitleElement:setText(area:getTypeName())
            self.inputDisplayAreaTextElement:setText(area:getName())

            local r, g, b = area:getDisplayColor()
            self.inputDisplayAreaColorElement:setImageColor(nil, r, g, b)
            self.inputDisplayAreaColorElement:setImageColor(GuiOverlay.STATE_DISABLED, r, g, b)

            self.inputDisplayAreaElement:setVisible(true)
        else
            self.inputDisplayAreaElement:setVisible(false)
        end

        self:updateInputMode(vehicle)
        self:updateInputTexture(layerId)

        self.inputDisplayElement:setSize(nil, self.inputDisplayElement:invalidateLayout())
        self.inputDisplayElement:setVisible(true)
    else
        self.inputDisplayElement:setVisible(false)
    end
end

---@param vehicle Machine
function HUDMachineDisplayElement:updateInputMode(vehicle)
    local mode = vehicle:getInputMode()

    self.inputDisplayModeImageElement:setImageSlice(nil, Machine.MODE_ICON_SLICE_ID[mode])
    self.inputDisplayModeTextElement:setText(Machine.L10N_MODE[mode])
end

---@param layerId number
function HUDMachineDisplayElement:updateInputTexture(layerId)
    local terrainLayer = g_landscapingManager:getTerrainLayerById(layerId)

    if terrainLayer ~= nil then
        self.inputDisplayTextureImageElement:setTerrainLayer(g_terrainNode, layerId)
        self.inputDisplayTextureTextElement:setText(terrainLayer.title)
    else
        self.inputDisplayTextureTextElement:setText(string.format('LAYER %s NOT FOUND', tostring(layerId)))
    end
end

---@param vehicle Machine
function HUDMachineDisplayElement:updateOutputDisplay(vehicle)
    if MachineUtils.getHasOutputs(vehicle) then
        local area, areaEnabled = vehicle:getMachineOutputArea()
        local layerId = vehicle:getMachineOutputLayerId()

        if area and areaEnabled then
            layerId = area.forceOutputLayer or layerId

            local iconSliceId = area:getIconSliceId()

            self.outputDisplayAreaImageElement:setImageSlice(nil, iconSliceId)
            self.outputDisplayAreaTitleElement:setText(area:getTypeName())
            self.outputDisplayAreaTextElement:setText(area:getName())

            local r, g, b = area:getDisplayColor()
            self.outputDisplayAreaColorElement:setImageColor(nil, r, g, b)
            self.outputDisplayAreaColorElement:setImageColor(GuiOverlay.STATE_DISABLED, r, g, b)

            self.outputDisplayAreaElement:setVisible(true)
        else
            self.outputDisplayAreaElement:setVisible(false)
        end

        self:updateOutputMode(vehicle)
        self:updateOutputTexture(layerId)

        self.outputDisplayElement:setSize(nil, self.outputDisplayElement:invalidateLayout())
        self.outputDisplayElement:setVisible(true)
    else
        self.outputDisplayElement:setVisible(false)
    end
end

---@param vehicle Machine
function HUDMachineDisplayElement:updateOutputMode(vehicle)
    local mode = vehicle:getOutputMode()

    self.outputDisplayModeImageElement:setImageSlice(nil, Machine.MODE_ICON_SLICE_ID[mode])
    self.outputDisplayModeTextElement:setText(Machine.L10N_MODE[mode])
end

---@param layerId number
function HUDMachineDisplayElement:updateOutputTexture(layerId)
    local terrainLayer = g_landscapingManager:getTerrainLayerById(layerId)

    if terrainLayer ~= nil then
        self.outputDisplayTextureImageElement:setTerrainLayer(g_terrainNode, layerId)
        self.outputDisplayTextureTextElement:setText(terrainLayer.title)
    else
        self.outputDisplayTextureTextElement:setText(string.format('LAYER %s NOT FOUND', tostring(layerId)))
    end
end

---@param vehicle Machine
function HUDMachineDisplayElement:updateVehicleDisplay(vehicle)
    local machineType = vehicle:getMachineType()

    self.vehicleDisplayImageElement:setImageFilename(vehicle:getImageFilename())
    self.vehicleDisplayTitleElement:setText(machineType.name)
    self.vehicleDisplayTextElement:setText(vehicle:getName())
end

---@param vehicle Machine
function HUDMachineDisplayElement:updateMaterialDisplay(vehicle)
    local machineType = vehicle:getMachineType()

    if machineType.useInput then
        local fillTypeIndex = vehicle:getMachineFillTypeIndex()
        local area, areaEnabled = vehicle:getMachineInputArea()

        if area ~= nil and areaEnabled and area.forceFillTypeIndex ~= nil then
            fillTypeIndex = area.forceFillTypeIndex
        end

        ---@type FillTypeObject?
        local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

        if fillType ~= nil then
            self.materialDisplayImageElement:setImageFilename(fillType.hudOverlayFilename)
            self.materialDisplayTextElement:setText(fillType.title)
        else
            self.materialDisplayTextElement:setText(string.format('UNKNOWN FILLTYPEINDEX %s', tostring(fillTypeIndex)))
        end

        self.materialDisplayElement:setVisible(true)
    else
        self.materialDisplayElement:setVisible(false)
    end
end
