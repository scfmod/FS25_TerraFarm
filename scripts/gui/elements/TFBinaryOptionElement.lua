---@class TFBinaryOptionElement : BinaryOptionElement
---@field ignoreOverlayFocused boolean
---@field superClass fun(): BinaryOptionElement
TFBinaryOptionElement = {}

local TFBinaryOptionElement_mt = Class(TFBinaryOptionElement, BinaryOptionElement)

function TFBinaryOptionElement.new(target)
    local self = BinaryOptionElement.new(target, TFBinaryOptionElement_mt)
    ---@cast self TFBinaryOptionElement

    self.ignoreOverlayFocused = false

    return self
end

function TFBinaryOptionElement:loadFromXML(xmlFile, key)
    self:superClass().loadFromXML(self, xmlFile, key)

    self.ignoreOverlayFocused = Utils.getNoNil(getXMLBool(xmlFile, key .. '#ignoreOverlayFocused'), self.ignoreOverlayFocused)
end

function TFBinaryOptionElement:loadProfile(profile, applyProfile)
    self:superClass().loadProfile(self, profile, applyProfile)

    self.ignoreOverlayFocused = Utils.getNoNil(profile:getBool('ignoreOverlayFocused'), self.ignoreOverlayFocused)
end

function TFBinaryOptionElement:getOverlayState()
    if not self.ignoreOverlayFocused then
        return self:superClass().getOverlayState(self)
    end

    if self:getIsDisabled() then
        return GuiOverlay.STATE_DISABLED
    elseif self:getIsHighlighted() then
        return GuiOverlay.STATE_HIGHLIGHTED
    else
        return GuiOverlay.STATE_NORMAL
    end
end

Gui.registerGuiElement('TFBinaryOption', TFBinaryOptionElement)
Gui.registerGuiElementProcFunction('TFBinaryOption', Gui.assignPlaySampleCallback)
