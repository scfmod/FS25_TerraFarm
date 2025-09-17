---@class NameInputDialog : TextInputDialog
---@field valid boolean
---@field dialogTextElement TextElement
---@field textElement TextInputElement
---@field yesButton ButtonElement
---@field noButton ButtonElement
---@field minLength number
---@field maxLength number
---@field defaultText string
---@field superClass fun(): TextInputDialog
NameInputDialog = {}

NameInputDialog.CLASS_NAME = 'NameInputDialog'
NameInputDialog.XML_FILENAME = g_modDirectory .. 'xml/gui/dialogs/TextInputDialog.xml'

local NameInputDialog_mt = Class(NameInputDialog, TextInputDialog)

local function NO_CALLBACK()
    return
end

---@return NameInputDialog
---@nodiscard
function NameInputDialog.new()
    local self = TextInputDialog.new(nil, NameInputDialog_mt)
    ---@cast self NameInputDialog

    self.valid = false
    self.minLength = 2
    self.maxLength = 24

    -- self.isPasswordDialog = false
    self.applyTextFilter = true

    return self
end

function NameInputDialog:load()
    g_gui:loadGui(NameInputDialog.XML_FILENAME, NameInputDialog.CLASS_NAME, self)
end

function NameInputDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    if self.textElement ~= nil then
        self.textElement.maxCharacters = self.maxLength

        if self.textElement.target ~= nil then
            self.textElement.onTextChangedCallback = self.onTextInputChanged
        end
    end
end

function NameInputDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[NameInputDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }

    g_messageCenter:unsubscribeAll(self)
end

function NameInputDialog:setCallback(onTextEntered, target, defaultInputText, dialogPrompt, callbackArgs)
    self.onTextEntered = onTextEntered or NO_CALLBACK
    self.target = target
    self.callbackArgs = callbackArgs

    self.textElement:setText(defaultInputText or '')
    self:onTextInputChanged()

    if dialogPrompt ~= nil then
        self.dialogTextElement:setText(dialogPrompt)
    end
end

---@param clickOk boolean | nil
function NameInputDialog:sendCallback(clickOk)
    local text = self.textElement.text

    self:close()

    if self.target ~= nil then
        self.onTextEntered(self.target, text, clickOk, self.valid)
    else
        self.onTextEntered(text, clickOk, self.valid)
    end
end

---@return string filteredText
---@return string baseText
---@return boolean isValid boolean
---@return number length
function NameInputDialog:getValidatedText()
    local baseText = self.textElement.text
    local filteredText = baseText:trim()
    local length = filteredText:len()

    if length > self.maxLength then
        filteredText = filteredText:sub(1, self.maxLength)
    end

    return filteredText, baseText, length >= self.minLength, length
end

---@return boolean
---@nodiscard
function NameInputDialog:onClickOk()
    if not self:isInputDisabled() then
        self:updateTextInput()

        if not self.valid then
            self.reactivateNextFrame = true
            self:updateButtons()

            return false
        end

        self:sendCallback(true)
        self:updateButtons()

        return false
    else
        return true
    end
end

function NameInputDialog:onTextInputChanged()
    local _, _, valid = self:getValidatedText()
    self.valid = valid

    self:updateButtons()
end

function NameInputDialog:updateButtons()
    if self.yesButton ~= nil then
        self.yesButton:setDisabled(not self.valid)
    end
end

---@return boolean isValid
function NameInputDialog:updateTextInput()
    local _, filteredText, valid = self:getValidatedText()

    self.valid = valid
    self.textElement:setText(filteredText)

    return valid
end
