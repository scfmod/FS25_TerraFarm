---@class TFTextInputElement : TextInputElement
---@field superClass fun(): TextInputElement
---@field customFocusSample any
---@field hasFrameWhenFocused boolean
TFTextInputElement = {}

local TFTextInputElement_mt = Class(TFTextInputElement, TextInputElement)

function TFTextInputElement.new(target)
    local self = TextInputElement.new(target, TFTextInputElement_mt)
    ---@cast self TFTextInputElement

    self.customFocusSample = nil
    self.hasFrameWhenFocused = true

    return self
end

function TFTextInputElement:loadFromXML(xmlFile, key)
    self:superClass().loadFromXML(self, xmlFile, key)

    self.hasFrameWhenFocused = Utils.getNoNil(getXMLBool(xmlFile, key .. '#hasFrameWhenFocused'), self.hasFrameWhenFocused)
end

function TFTextInputElement:loadProfile(profile, applyProfile)
    self:superClass().loadProfile(self, profile, applyProfile)

    self.hasFrameWhenFocused = Utils.getNoNil(profile:getBool('hasFrameWhenFocused'), self.hasFrameWhenFocused)
end

function TFTextInputElement:draw(...)
    if self.hasFrame and self.hasFrameWhenFocused then
        local drawFrame = self:getOverlayState() == GuiOverlay.STATE_FOCUSED

        self.frameOverlayVisible[1] = drawFrame
        self.frameOverlayVisible[2] = drawFrame
        self.frameOverlayVisible[3] = drawFrame
        self.frameOverlayVisible[4] = drawFrame
    end

    self:superClass().draw(self, ...)
end

Gui.registerGuiElement('TFTextInput', TFTextInputElement)
Gui.registerGuiElementProcFunction('TFTextInput', Gui.assignPlaySampleCallback)
