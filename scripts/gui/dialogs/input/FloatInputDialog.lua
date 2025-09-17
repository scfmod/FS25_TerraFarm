---@class FloatInputDialog : TextInputDialog
---@field value number
---@field minValue number
---@field maxValue number
---@field textElement TextInputElement
---@field dialogTextElement TextElement
---@field yesButton ButtonElement
---@field noButton ButtonElement
---@field precision number
---@field defaultText string
---@field superClass fun(): TextInputDialog
FloatInputDialog = {}

FloatInputDialog.CLASS_NAME = 'FloatInputDialog'
FloatInputDialog.XML_FILENAME = g_modDirectory .. 'xml/gui/dialogs/TextInputDialog.xml'

local FloatInputDialog_mt = Class(FloatInputDialog, TextInputDialog)

local function NO_CALLBACK()
    return
end

---@return FloatInputDialog
---@nodiscard
function FloatInputDialog.new()
    local self = TextInputDialog.new(nil, FloatInputDialog_mt)
    ---@cast self FloatInputDialog

    self.precision = 2
    self.minValue = 0
    self.maxValue = 45
    self.value = 0

    self.applyTextFilter = false

    return self
end

function FloatInputDialog:load()
    g_gui:loadGui(FloatInputDialog.XML_FILENAME, FloatInputDialog.CLASS_NAME, self)
end

function FloatInputDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    if self.textElement ~= nil then
        self.textElement.maxCharacters = 8
    end
end

function FloatInputDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[FloatInputDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }

    g_messageCenter:unsubscribeAll(self)
end

---@param onTextEntered function
---@param target table | nil
---@param defaultValue number | nil
---@param minValue number | nil
---@param maxValue number | nil
---@param dialogPrompt string | nil
---@param callbackArgs any
function FloatInputDialog:setCallback(onTextEntered, target, defaultValue, minValue, maxValue, dialogPrompt, callbackArgs)
    self.onTextEntered = onTextEntered or NO_CALLBACK
    self.target = target
    self.callbackArgs = callbackArgs
    self.minValue = minValue or 0
    self.maxValue = maxValue or 45

    self.textElement:setText(string.format('%.2f', self:getValidInput(defaultValue or self.minValue)))

    if dialogPrompt ~= nil then
        self.dialogTextElement:setText(dialogPrompt)
    end
end

function FloatInputDialog:onClickOk()
    if not self:isInputDisabled() then
        self:updateTextInput()
        self:sendCallback(true)

        return false
    else
        return true
    end
end

function FloatInputDialog:onTextInputChanged()
    self:updateTextInput()
end

---@param value number
---@return number
---@nodiscard
function FloatInputDialog:getValidInput(value)
    if value == nil then
        value = self.minValue
    elseif value > self.maxValue then
        value = self.maxValue
    end

    return value
end

---@param str string
---@return number
---@nodiscard
function FloatInputDialog:getValidInputFromString(str)
    if str ~= nil then
        local filteredText = str:match('%-?[%d%.]+')

        if filteredText ~= nil then
            local value = tonumber(filteredText)

            if value ~= nil then
                return self:getValidInput(value)
            end
        end
    end

    return self.minValue
end

---@return number
function FloatInputDialog:updateTextInput()
    local value = self:getValidInputFromString(self.textElement.text)

    self.textElement:setText(string.format('%.2f', value))

    return value
end

---@param clickOk boolean | nil
function FloatInputDialog:sendCallback(clickOk)
    local value = self:getValidInputFromString(self.textElement.text)

    self:close()

    if self.target ~= nil then
        self.onTextEntered(self.target, value, clickOk)
    else
        self.onTextEntered(value, clickOk)
    end
end
