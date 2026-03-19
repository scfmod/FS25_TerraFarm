---@class InputOption
---@field min number
---@field max number
---@field defaultValue number

---@class SetPositionDialog : YesNoDialog
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
            defaultValue = 0,
        },
        [self.inputElements[2]] = {
            min = 0,
            max = 512,
            defaultValue = 0,
        },
        [self.inputElements[3]] = {
            min = -16384,
            max = 16384,
            defaultValue = 0,
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
---@param y number
---@param z number
function SetPositionDialog:show(x, y, z)
    self:setInitialInputValue(self.inputElements[1], x)
    self:setInitialInputValue(self.inputElements[2], y)
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
    self.options[element].defaultValue = value
    element:setText(string.format('%.2f', value))
end

---@param element TextInputElement
---@return number
---@nodiscard
function SetPositionDialog:getInputValue(element)
    local options = self.options[element]
    local str = element.text

    if str ~= nil then
        local filteredText = str:match('%-?[%d%.]+')

        if filteredText ~= nil then
            local value = tonumber(filteredText)

            if value ~= nil then
                if value < options.min then
                    return options.min
                elseif value > options.max then
                    return options.max
                end

                return value
            end
        end
    end

    return options.defaultValue
end

function SetPositionDialog:updateInputs()
    for _, element in pairs(self.inputElements) do
        local value = self:getInputValue(element)
        element:setText(string.format('%.2f', value))
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
