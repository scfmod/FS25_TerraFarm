---@class SelectAreaDialog : MessageDialog
---@field list SmoothListElement
---@field listEmptyText TextElement
---@field buttonBox BoxLayoutElement
---@field applyButton ButtonElement
---@field createAreaButton ButtonElement
---@field editAreaButton ButtonElement
---@field items LandscapingArea[]
---@field vehicle? Vehicle
---@field superClass fun(): MessageDialog
SelectAreaDialog = {}

SelectAreaDialog.CLASS_NAME = 'SelectAreaDialog'
SelectAreaDialog.XML_FILENAME = g_modDirectory .. 'data/gui/dialogs/SelectAreaDialog.xml'

local SelectAreaDialog_mt = Class(SelectAreaDialog, MessageDialog)

---@return SelectAreaDialog
---@nodiscard
function SelectAreaDialog.new()
    local self = MessageDialog.new(nil, SelectAreaDialog_mt)
    ---@cast self SelectAreaDialog

    self.items = {}

    return self
end

function SelectAreaDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[SelectAreaDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }

    g_messageCenter:unsubscribeAll(self)
end

function SelectAreaDialog:load()
    g_gui:loadGui(SelectAreaDialog.XML_FILENAME, SelectAreaDialog.CLASS_NAME, self)
end

function SelectAreaDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.list:setDataSource(self)
end

---@param fn function?
---@param target table?
function SelectAreaDialog:setSelectCallback(fn, target)
    self.selectCallbackFunction = fn
    self.selectCallbackTarget = target
end

---@param vehicle Vehicle?
function SelectAreaDialog:show(vehicle)
    self.vehicle = vehicle
    g_gui:showDialog(SelectAreaDialog.CLASS_NAME)
end

function SelectAreaDialog:onOpen()
    self:superClass().onOpen(self)

    self:updateItems()
    self:updateMenuButtons()

    g_messageCenter:subscribe(ModMessageType.LANDSCAPING_AREA_REGISTERED, self.forceReload, self)
    g_messageCenter:subscribe(ModMessageType.LANDSCAPING_AREA_UPDATED, self.forceReload, self)
    g_messageCenter:subscribe(ModMessageType.LANDSCAPING_AREA_DELETED, self.forceReload, self)
end

function SelectAreaDialog:onClose()
    self:superClass().onClose(self)

    self.items = {}
    self.vehicle = nil

    g_messageCenter:unsubscribeAll(self)
end

function SelectAreaDialog:forceReload()
    if self.isOpen then
        self:updateItems()
    end
end

function SelectAreaDialog:updateItems()
    self.items = g_landscapingManager:getAreas()

    table.sort(self.items, function (a, b)
        return a.name < b.name
    end)

    self.list:reloadData()
    self.listEmptyText:setVisible(#self.items == 0)
end

function SelectAreaDialog:getNumberOfItemsInSection()
    return #self.items
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function SelectAreaDialog:populateCellForItemInSection(list, section, index, cell)
    local area = self.items[index]

    if area ~= nil then
        cell:getAttribute('image'):setImageSlice(nil, area:getIconSliceId())
        cell:getAttribute('name'):setText(area:getName())
        cell:getAttribute('text'):setText(area:getTypeName())
        cell:getAttribute('status'):setText(area.visible and g_i18n:getText('ui_visible') or g_i18n:getText('ui_hidden'))
    end
end

function SelectAreaDialog:onListSelectionChanged()
    self:updateMenuButtons()
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function SelectAreaDialog:onItemDoubleClick(list, section, index, cell)
    self:sendCallback(index)
end

function SelectAreaDialog:onClickApply()
    self:sendCallback(self.list:getSelectedIndexInSection())
end

---@param index number?
function SelectAreaDialog:sendCallback(index)
    local item = self.items[index]

    self:close()

    if self.selectCallbackFunction ~= nil then
        if self.selectCallbackTarget ~= nil then
            self.selectCallbackFunction(self.selectCallbackTarget, item)
        else
            self.selectCallbackFunction(item)
        end
    end
end

function SelectAreaDialog:onClickBack(forceBack, usedMenuButton)
    if (self.isCloseAllowed or forceBack) and not usedMenuButton then
        self:sendCallback(nil)

        return false
    else
        return true
    end
end

function SelectAreaDialog:onClickCreateArea()
    LandscapingUtils.createAreaInEditor(false)
end

function SelectAreaDialog:onClickEditArea()
    local selectedItem = self:getSelectedItem()

    if selectedItem ~= nil then
        LandscapingUtils.openAreaInEditor(selectedItem, false)
    end
end

---@return LandscapingArea?
function SelectAreaDialog:getSelectedItem()
    return self.items[self.list:getSelectedIndexInSection()]
end

function SelectAreaDialog:updateMenuButtons()
    local selectedItem = self:getSelectedItem()
    local hasPermission = ModUtils.getPlayerHasPermission('landscaping')

    self.applyButton:setDisabled(selectedItem == nil)
    self.createAreaButton:setVisible(hasPermission and g_landscapingManager:getCanCreateArea())
    self.editAreaButton:setVisible(hasPermission and selectedItem ~= nil)
    self.buttonBox:invalidateLayout()
end
