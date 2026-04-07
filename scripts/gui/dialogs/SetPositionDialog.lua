---@class InputOption
---@field min number
---@field max number
---@field default number

---@class SetPositionDialog : YesNoDialog
---@field precision number
---@field inputElements TextInputElement[]
---@field callbackFunc function
---@field callbackTarget any
---@field options table<TextInputElement, InputOption>
---@field superClass fun(): YesNoDialog
SetPositionDialog = {}
SetPositionDialog.CLASS_NAME = 'SetPositionDialog'
SetPositionDialog.XML_FILENAME = g_modDirectory .. 'data/gui/dialogs/SetPositionDialog.xml'

local SetPositionDialog_mt = Class(SetPositionDialog, YesNoDialog)

local function NO_CALLBACK()
    return
end

---@return SetPositionDialog
---@nodiscard
function SetPositionDialog.new()
    ---@type SetPositionDialog
    local self = YesNoDialog.new(nil, SetPositionDialog_mt)

    self.options = {}
    self.precision = 2

    return self
end

function SetPositionDialog:delete()
    SetPositionDialog:superClass().delete(self)

    FocusManager.guiFocusData[SetPositionDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }
end

function SetPositionDialog:load()
    g_gui:loadGui(SetPositionDialog.XML_FILENAME, SetPositionDialog.CLASS_NAME, self)
end

function SetPositionDialog:onGuiSetupFinished()
    SetPositionDialog:superClass().onGuiSetupFinished(self)

    self.options = {
        [self.inputElements[1]] = {
            min = -16384,
            max = 16384,
            default = 0,
        },
        [self.inputElements[2]] = {
            min = 0,
            max = 512,
            default = 0,
        },
        [self.inputElements[3]] = {
            min = -16384,
            max = 16384,
            default = 0,
        }
    }
end

---@param callbackFunc function
---@param callbackTarget any
function SetPositionDialog:setCallback(callbackFunc, callbackTarget)
    self.callbackFunc = callbackFunc or NO_CALLBACK
    self.callbackTarget = callbackTarget
end

---@param x number
---@param y number?
---@param z number
function SetPositionDialog:show(x, y, z)
    self:setInitialInputValue(self.inputElements[1], x)

    if y ~= nil then
        self.inputElements[2]:setVisible(true)
        self:setInitialInputValue(self.inputElements[2], y)
    else
        self.inputElements[2]:setVisible(false)
    end
    self:setInitialInputValue(self.inputElements[3], z)

    g_gui:showDialog(SetPositionDialog.CLASS_NAME)
end

function SetPositionDialog:onClickOk()
    if not self:isInputDisabled() then
        self:updateInputs()
        self:sendCallback(true)

        return false
    end

    return true
end

function SetPositionDialog:onEnterPressedInput()
    self:updateInputs()
end

---@param element TextInputElement
---@param value number
function SetPositionDialog:setInitialInputValue(element, value)
    self.options[element].default = value
    EditorUtils.setTextInputNumber(element, value, self.precision)
end

---@param element TextInputElement
---@return number
---@nodiscard
function SetPositionDialog:getInputValue(element)
    local options = self.options[element]

    ---@diagnostic disable-next-line: return-type-mismatch
    return EditorUtils.getTextInputNumber(element, self.precision, options.default, options.min, options.max)
end

function SetPositionDialog:updateInputs()
    for _, element in pairs(self.inputElements) do
        local value = self:getInputValue(element)
        EditorUtils.setTextInputNumber(element, value, self.precision)
    end
end

---@param clickOk boolean
function SetPositionDialog:sendCallback(clickOk)
    if clickOk then
        local x = self:getInputValue(self.inputElements[1])
        local y = self:getInputValue(self.inputElements[2])
        local z = self:getInputValue(self.inputElements[3])

        self:close()

        if self.callbackTarget ~= nil then
            self.callbackFunc(self.callbackTarget, x, y, z)
        else
            self.callbackFunc(x, y, z)
        end
    else
        self:close()
    end
end
