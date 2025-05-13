---@class TFButtonElement : ButtonElement
---@field superClass fun(): ButtonElement
---@field ignoreOverlayFocused boolean
TFButtonElement = {}

local TFButtonElement_mt = Class(TFButtonElement, ButtonElement)

function TFButtonElement.new(target, customMt)
    local self = ButtonElement.new(target, customMt or TFButtonElement_mt)
    ---@cast self TFButtonElement

    self.ignoreOverlayFocused = false

    return self
end

function TFButtonElement:loadFromXML(xmlFile, key)
    self:superClass().loadFromXML(self, xmlFile, key)

    self.ignoreOverlayFocused = Utils.getNoNil(getXMLBool(xmlFile, key .. '#ignoreOverlayFocused'), self.ignoreOverlayFocused)
end

function TFButtonElement:loadProfile(profile, applyProfile)
    self:superClass().loadProfile(self, profile, applyProfile)

    self.ignoreOverlayFocused = Utils.getNoNil(profile:getBool('ignoreOverlayFocused'), self.ignoreOverlayFocused)
end

function TFButtonElement:setDisabled(disabled)
    if self.disabled ~= disabled then
        self:superClass().setDisabled(self, disabled)
    end
end

function TFButtonElement:getOverlayState()
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

function TFButtonElement:getTextColor()
    if not self.ignoreOverlayFocused then
        return self:superClass().getTextColor(self)
    end

    local retColor = self.textColor

    if self.disabled and not self.ignoreDisabled then
        retColor = self.textDisabledColor
    elseif self:getIsHighlighted() then
        retColor = self.textHighlightedColor
    end

    if retColor == nil then
        retColor = self.textColor
    end

    return retColor
end

Gui.registerGuiElement('TFButton', TFButtonElement)
Gui.registerGuiElementProcFunction('TFButton', Gui.assignPlaySampleCallback)
