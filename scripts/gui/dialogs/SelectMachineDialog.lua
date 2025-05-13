---@class MachineListItem
---@field vehicle Machine
---@field distance number
---@field name string
---@field brand string

---@class SelectMachineDialog : MessageDialog
---@field list SmoothListElement
---@field listEmptyText TextElement
---@field items MachineListItem[]
---@field vehicle Vehicle | nil
---@field superClass fun(): MessageDialog
SelectMachineDialog = {}

SelectMachineDialog.CLASS_NAME = 'SelectMachineDialog'
SelectMachineDialog.XML_FILENAME = g_currentModDirectory .. 'xml/gui/dialogs/SelectMachineDialog.xml'

local SelectMachineDialog_mt = Class(SelectMachineDialog, MessageDialog)

---@return SelectMachineDialog
---@nodiscard
function SelectMachineDialog.new()
    local self = MessageDialog.new(nil, SelectMachineDialog_mt)
    ---@cast self SelectMachineDialog

    self.items = {}

    return self
end

function SelectMachineDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[SelectMachineDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }

    g_messageCenter:unsubscribeAll(self)
end

function SelectMachineDialog:load()
    g_gui:loadGui(SelectMachineDialog.XML_FILENAME, SelectMachineDialog.CLASS_NAME, self)
end

function SelectMachineDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.list:setDataSource(self)
end

---@param fn function | nil
---@param target any
function SelectMachineDialog:setSelectCallback(fn, target)
    self.selectCallbackFunction = fn
    self.selectCallbackTarget = target
end

---@param vehicle Vehicle | nil
function SelectMachineDialog:show(vehicle)
    self.vehicle = vehicle
    g_gui:showDialog(SelectMachineDialog.CLASS_NAME)
end

function SelectMachineDialog:onOpen()
    self:superClass().onOpen(self)

    self:updateItems()

    g_messageCenter:subscribe(MessageType.MACHINE_ADDED, self.forceReload, self)
    g_messageCenter:subscribe(MessageType.MACHINE_REMOVED, self.forceReload, self)
end

function SelectMachineDialog:onClose()
    self:superClass().onClose(self)

    self.items = {}
    self.vehicle = nil

    g_messageCenter:unsubscribeAll(self)
end

function SelectMachineDialog:forceReload()
    if self.isOpen then
        self:updateItems()
    end
end

function SelectMachineDialog:updateItems()
    local machines = g_machineManager:getAccessibleVehicles()

    self.items = {}

    for _, vehicle in ipairs(machines) do
        local brand = g_brandManager:getBrandByIndex(vehicle:getBrand())
        local brandName = brand and brand.title or ''

        ---@type MachineListItem
        local item = {
            name = vehicle:getName(),
            brand = brandName,
            distance = self.vehicle ~= nil and MachineUtils.getVehiclesDistance(self.vehicle, vehicle) or 1,
            vehicle = vehicle
        }

        if item.distance > 0 then
            table.insert(self.items, item)
        end
    end

    table.sort(self.items, function (a, b)
        return a.distance < b.distance
    end)

    self.list:reloadData()

    self.listEmptyText:setVisible(#self.items == 0)
end

function SelectMachineDialog:getNumberOfItemsInSection()
    return #self.items
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function SelectMachineDialog:populateCellForItemInSection(list, section, index, cell)
    local item = self.items[index]

    if item ~= nil then
        -- local farmName = MachineUtils.getVehicleFarmName(item.vehicle)

        cell:getAttribute('image'):setImageFilename(item.vehicle:getImageFilename())
        cell:getAttribute('name'):setText(item.name)
        cell:getAttribute('brand'):setText(item.brand)
        -- cell:getAttribute('farm'):setText(farmName)

        if self.vehicle ~= nil then
            cell:getAttribute('text'):setText(string.format(g_i18n:getText('ui_distanceFormat'), item.distance))
        else
            cell:getAttribute('text'):setText('')
        end
    end
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function SelectMachineDialog:onItemDoubleClick(list, section, index, cell)
    self:sendCallback(index)
end

function SelectMachineDialog:onClickApply()
    self:sendCallback(self.list:getSelectedIndexInSection())
end

---@param index number | nil
function SelectMachineDialog:sendCallback(index)
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

function SelectMachineDialog:onClickBack(forceBack, usedMenuButton)
    if (self.isCloseAllowed or forceBack) and not usedMenuButton then
        self:sendCallback(nil)

        return false
    else
        return true
    end
end
