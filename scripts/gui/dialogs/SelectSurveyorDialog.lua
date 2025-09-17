---@class SurveyorListItem
---@field vehicle Surveyor
---@field distance number
---@field name string

---@class SelectSurveyorDialog : MessageDialog
---@field superClass fun(): MessageDialog
---@field list SmoothListElement
---@field listEmptyText TextElement
---@field items SurveyorListItem[]
---@field vehicle Vehicle | nil
---
---@field selectCallbackFunction function | nil
---@field selectCallbackTarget any
SelectSurveyorDialog = {}

SelectSurveyorDialog.CLASS_NAME = 'SelectSurveyorDialog'
SelectSurveyorDialog.XML_FILENAME = g_modDirectory .. 'xml/gui/dialogs/SelectSurveyorDialog.xml'

local SelectSurveyorDialog_mt = Class(SelectSurveyorDialog, MessageDialog)

---@return SelectSurveyorDialog
---@nodiscard
function SelectSurveyorDialog.new()
    local self = MessageDialog.new(nil, SelectSurveyorDialog_mt)
    ---@cast self SelectSurveyorDialog

    self.items = {}

    return self
end

function SelectSurveyorDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[SelectSurveyorDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }

    g_messageCenter:unsubscribeAll(self)
end

function SelectSurveyorDialog:load()
    g_gui:loadGui(SelectSurveyorDialog.XML_FILENAME, SelectSurveyorDialog.CLASS_NAME, self)
end

function SelectSurveyorDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.list:setDataSource(self)
end

---@param fn function | nil
---@param target any
function SelectSurveyorDialog:setSelectCallback(fn, target)
    self.selectCallbackFunction = fn
    self.selectCallbackTarget = target
end

---@param vehicle Vehicle | nil
function SelectSurveyorDialog:show(vehicle)
    self.vehicle = vehicle
    g_gui:showDialog(SelectSurveyorDialog.CLASS_NAME)
end

function SelectSurveyorDialog:onOpen()
    self:superClass().onOpen(self)

    self:updateItems()

    g_messageCenter:subscribe(MessageType.SURVEYOR_ADDED, self.forceReload, self)
    g_messageCenter:subscribe(MessageType.SURVEYOR_REMOVED, self.forceReload, self)
end

function SelectSurveyorDialog:onClose()
    self:superClass().onClose(self)

    self.items = {}
    self.vehicle = nil

    g_messageCenter:unsubscribeAll(self)
end

function SelectSurveyorDialog:forceReload()
    if self.isOpen then
        self:updateItems()
    end
end

function SelectSurveyorDialog:updateItems()
    local surveyors = g_machineManager:getAccessibleSurveyors()

    self.items = {}

    for _, vehicle in ipairs(surveyors) do
        ---@type SurveyorListItem
        local item = {
            name = vehicle:getFullName(),
            distance = self.vehicle ~= nil and MachineUtils.getVehiclesDistance(self.vehicle, vehicle) or 0,
            vehicle = vehicle
        }

        table.insert(self.items, item)
    end

    table.sort(self.items, function (a, b)
        return a.distance < b.distance
    end)

    self.list:reloadData()

    self.listEmptyText:setVisible(#self.items == 0)
end

function SelectSurveyorDialog:getNumberOfItemsInSection()
    return #self.items
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function SelectSurveyorDialog:populateCellForItemInSection(list, section, index, cell)
    local item = self.items[index]

    if item ~= nil then
        -- local farmName = MachineUtils.getVehicleFarmName(item.vehicle)

        -- cell:setDisabled(not item.vehicle:getIsCalibrated())
        cell:getAttribute('image'):setImageFilename(item.vehicle:getImageFilename())
        cell:getAttribute('name'):setText(item.name)

        if self.vehicle ~= nil then
            cell:getAttribute('text'):setText(string.format(g_i18n:getText('ui_distanceFormat'), item.distance))
        else
            cell:getAttribute('text'):setText('')
        end
        -- cell:getAttribute('farm'):setText(farmName)

        ---@type TextElement
        local statusElement = cell:getAttribute('status')

        if not item.vehicle:getIsCalibrated() then
            statusElement:setText(g_i18n:getText('ui_notCalibrated'))
        else
            statusElement:setText(string.format(g_i18n:getText('ui_calibratedAngleFormat'), item.vehicle:getCalibrationAngle()))
        end
    end
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function SelectSurveyorDialog:onItemDoubleClick(list, section, index, cell)
    self:sendCallback(index)
end

function SelectSurveyorDialog:onClickApply()
    self:sendCallback(self.list:getSelectedIndexInSection())
end

---@param index number | nil
function SelectSurveyorDialog:sendCallback(index)
    local item = self.items[index]

    self:close()

    if self.selectCallbackFunction ~= nil then
        if self.selectCallbackTarget ~= nil then
            self.selectCallbackFunction(self.selectCallbackTarget, item and item.vehicle)
        else
            self.selectCallbackFunction(item and item.vehicle)
        end
    end
end

function SelectSurveyorDialog:onClickBack(forceBack, usedMenuButton)
    if (self.isCloseAllowed or forceBack) and not usedMenuButton then
        self:sendCallback(nil)

        return false
    else
        return true
    end
end
