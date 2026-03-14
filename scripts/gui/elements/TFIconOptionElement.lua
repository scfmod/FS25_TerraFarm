---@class TFIconOptionElement : MultiTextOptionElement
---@field iconElement BitmapElement
TFIconOptionElement = {}

local TFIconOptionElement_mt = Class(TFIconOptionElement, MultiTextOptionElement)

---@param target any
---@return TFIconOptionElement
---@nodiscard
function TFIconOptionElement.new(target)
    ---@type TFIconOptionElement
    local self = MultiTextOptionElement.new(target, TFIconOptionElement_mt)

    return self
end

function TFIconOptionElement:updateContentElement()
    local value = self.texts[self.state]

    local useIcon = false
    if self.iconElement ~= nil then
        if value ~= nil then
            if self.isImageMode then
                self.iconElement:setImageSlice(nil, value)
                self.iconElement:setVisible(true)
                for i = 1, #self.gradientElements do
                    self.gradientElements[i]:setVisible(false)
                end
                useIcon = true
            end
        end

        if not useIcon then
            self.iconElement:setVisible(false)
            for i = 1, #self.gradientElements do
                self.gradientElements[i]:setVisible(true)
            end
        end
    end

    if self.textElement ~= nil then
        if not useIcon and value ~= nil and not self.isImageMode then
            self.textElement:setText(value)
        else
            self.textElement:setText("")
        end
    end

    if self.disableButtonsOnSingleText then
        self:setDisabled(#self.texts <= 1)
    end

    if self.hideButtonOnLimitReached and not self.wrap then
        if self.leftButtonElement ~= nil then
            self.leftButtonElement:setVisible(self.state ~= 1)
        end
        if self.rightButtonElement ~= nil then
            self.rightButtonElement:setVisible(self.state ~= #self.texts)
        end
    end
end

Gui.registerGuiElement('TFIconOption', TFIconOptionElement)
Gui.registerGuiElementProcFunction('TFIconOption', Gui.assignPlaySampleCallback)
