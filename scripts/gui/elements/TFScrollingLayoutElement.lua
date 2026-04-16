---@class TFScrollingLayoutElement : ScrollingLayoutElement
---@field superClass fun(): ScrollingLayoutElement
---@field firstElement GuiElement
---@field lastElement GuiElement
TFScrollingLayoutElement = {}

local TFScrollingLayoutElement_mt = Class(TFScrollingLayoutElement, ScrollingLayoutElement)

---@param target any
---@return TFScrollingLayoutElement
---@nodiscard
function TFScrollingLayoutElement.new(target)
    ---@type TFScrollingLayoutElement
    local self = ScrollingLayoutElement.new(target, TFScrollingLayoutElement_mt)

    return self
end

---@param ignoreVisibility? boolean
function TFScrollingLayoutElement:updateLayoutCells(ignoreVisibility)
    self.firstElement = nil
    self.lastElement = nil

    TFScrollingLayoutElement:superClass().updateLayoutCells(self, ignoreVisibility)
end

local function findFirstFocusableSearch(element, checkReceiveFocus)
    if not element.focusFallthrough and (element:getIsVisibleNonRec() and (not checkReceiveFocus or element:canReceiveFocus())) then
        return element
    end
    for i = 1, #element.elements do
        if element.elements[i]:getIsVisibleNonRec() then
            local result = findFirstFocusableSearch(element.elements[i], checkReceiveFocus)
            if result == nil then
                continue
            end
            return result
        end
    end
    return nil
end

---@param element GuiElement
function TFScrollingLayoutElement:addFocusListener(element)
    local focusElement = findFirstFocusableSearch(element, true)
    element = focusElement or element

    if focusElement ~= nil then
        if self.firstElement == nil then
            self.firstElement = element
        end
        if element ~= self.firstElement then
            self.lastElement = element
        end
    end

    if element.scrollingFocusEnter_orig == nil then
        element.scrollingFocusEnter_orig = element.onFocusEnter
    end

    function element.onFocusEnter(e)
        ---@diagnostic disable-next-line: undefined-field
        e.scrollingFocusEnter_orig(e)

        if e == self.firstElement then
            self:smoothScrollTo(0)
        elseif e == self.lastElement then
            self:smoothScrollToEnd()
        else
            self:scrollToMakeElementVisible(e)
        end
    end
end

function TFScrollingLayoutElement:smoothScrollToEnd()
    if self.scrollDirection == "vertical" then
        self:smoothScrollTo(math.max(self.contentSize - self.absSize[2], 0))
    else
        self:smoothScrollTo(-math.max(self.contentSize - self.absSize[1], 0))
    end
end

Gui.registerGuiElement('TFScrollingLayout', TFScrollingLayoutElement)
