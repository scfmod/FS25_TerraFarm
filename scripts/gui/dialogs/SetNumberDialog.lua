---@class SetNumberDialog : TextInputDialog
---@field superClass fun(): TextInputDialog
---@field textElement TextInputElement
---@field dialogTextElement TextElement
---@field precision number
---@field min number
---@field max number
---@field value number
---@field callbackFunc function
---@field callbackTarget any
SetNumberDialog = {}
SetNumberDialog.CLASS_NAME = 'SetNumberDialog'
SetNumberDialog.XML_FILENAME = 'dataS/gui/dialogs/TextInputDialog.xml'

local SetNumberDialog_mt = Class(SetNumberDialog, TextInputDialog)

local function NO_CALLBACK()
    return
end

---@return SetNumberDialog
---@nodiscard
function SetNumberDialog.new()
    ---@type SetNumberDialog
    local self = TextInputDialog.new(nil, SetNumberDialog_mt)

    self.precision = 2
    self.min = 0
    self.max = 100
    self.value = 0

    return self
end

function SetNumberDialog:delete()
    SetNumberDialog:superClass().delete(self)

    FocusManager.guiFocusData[SetNumberDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }
end

function SetNumberDialog:load()
    g_gui:loadGui(SetNumberDialog.XML_FILENAME, SetNumberDialog.CLASS_NAME, self)
end

function SetNumberDialog:onGuiSetupFinished()
    SetNumberDialog:superClass().onGuiSetupFinished(self)

    self.textElement.maxCharacters = 8

    self.dialogTextElement:setText('')
    self:setButtonTexts(g_i18n:getText('button_accept'), g_i18n:getText('button_cancel'))
end

---@param callbackFunc function
---@param callbackTarget any
function SetNumberDialog:setCallback(callbackFunc, callbackTarget)
    self.callbackFunc = callbackFunc or NO_CALLBACK
    self.callbackTarget = callbackTarget
end

---@param value number
---@param min number
---@param max number
---@param precision number
---@param dialogTitle? string
function SetNumberDialog:show(value, min, max, precision, dialogTitle)
    self.value = value
    self.min = min
    self.max = max
    self.precision = precision or 2

    EditorUtils.setTextInputNumber(self.textElement, value, precision)

    self.dialogTextElement:setText(dialogTitle or '')

    g_gui:showDialog(SetNumberDialog.CLASS_NAME)
end

function SetNumberDialog:onClickOk()
    if not self:isInputDisabled() then
        self:updateInput()
        self:sendCallback(true)

        return false
    else
        return true
    end
end

function SetNumberDialog:updateInput()
    local value = EditorUtils.getTextInputNumber(self.textElement, self.precision, self.value, self.min, self.max)
    ---@cast value -?

    EditorUtils.setTextInputNumber(self.textElement, value, self.precision)
end

---@param clickOk boolean
function SetNumberDialog:sendCallback(clickOk)
    self:close()

    if clickOk then
        local value = EditorUtils.getTextInputNumber(self.textElement, self.precision, self.value, self.min, self.max)
        ---@cast value -?

        if self.callbackTarget then
            self.callbackFunc(self.callbackTarget, value)
        else
            self.callbackFunc(value)
        end
    end
end
