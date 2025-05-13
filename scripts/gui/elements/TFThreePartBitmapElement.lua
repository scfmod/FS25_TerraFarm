---@class TFThreePartBitmapElement : ThreePartBitmapElement
---@field superClass fun(): ThreePartBitmapElement
---@field ignoreOverlayFocused boolean
---@field parent GuiElement
TFThreePartBitmapElement = {}

local TFThreePartBitmapElement_mt = Class(TFThreePartBitmapElement, ThreePartBitmapElement)

function TFThreePartBitmapElement.new(target, customMt)
    local self = ThreePartBitmapElement.new(target, customMt or TFThreePartBitmapElement_mt)
    ---@cast self TFThreePartBitmapElement

    self.ignoreOverlayFocused = true

    return self
end

function TFThreePartBitmapElement:loadFromXML(xmlFile, key)
    self:superClass().loadFromXML(self, xmlFile, key)

    self.ignoreOverlayFocused = Utils.getNoNil(getXMLBool(xmlFile, key .. '#ignoreOverlayFocused'), self.ignoreOverlayFocused)
end

function TFThreePartBitmapElement:loadProfile(profile, applyProfile)
    self:superClass().loadProfile(self, profile, applyProfile)

    self.ignoreOverlayFocused = Utils.getNoNil(profile:getBool('ignoreOverlayFocused'), self.ignoreOverlayFocused)
end

function TFThreePartBitmapElement:getOverlayState()
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

Gui.registerGuiElement('TFThreePartBitmap', TFThreePartBitmapElement)
