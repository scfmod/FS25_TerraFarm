---@class SelectAreaDialog : MessageDialog
---@field list SmoothListElement
---@field listEmptyText TextElement
---@field buttonBox BoxLayoutElement
---@field applyButton ButtonElement
---@field items LandscapingArea[]
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

---@param selectId? string
---@param dialogTitle string
function SelectAreaDialog:show(selectId, dialogTitle)
    self:setText(dialogTitle)

    g_gui:showDialog(SelectAreaDialog.CLASS_NAME)

    self:setSelectedId(selectId)
end

function SelectAreaDialog:onOpen()
    self:superClass().onOpen(self)

    self:updateItems()
    self:updateMenuButtons()

    g_messageCenter:subscribe(ModMessageType.LANDSCAPING_AREA_REGISTER, self.forceReload, self)
    g_messageCenter:subscribe(ModMessageType.LANDSCAPING_AREA_UPDATE, self.forceReload, self)
    g_messageCenter:subscribe(ModMessageType.LANDSCAPING_AREA_DELETE, self.forceReload, self)
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
        return a.name:upper() < b.name:upper()
    end)

    self.list:reloadData()
    self.listEmptyText:setVisible(#self.items == 0)
end

---@param id? string
function SelectAreaDialog:setSelectedId(id)
    if id ~= nil then
        for index, area in ipairs(self.items) do
            if area.uniqueId == id then
                self.list:setSelectedIndex(index)
                return
            end
        end
    end
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
        ---@type BitmapElement
        local imageElement = cell:getAttribute('image')
        local r, g, b = area:getDisplayColor()

        imageElement:setImageColor(nil, r, g, b)
        imageElement:setImageColor(GuiOverlay.STATE_SELECTED, r, g, b)
        imageElement:setImageSlice(nil, area:getIconSliceId())

        cell:getAttribute('name'):setText(area:getName())
        cell:getAttribute('text'):setText(area:getTypeName())
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
    local id = item and item.uniqueId or nil

    self:close()

    if self.selectCallbackFunction ~= nil then
        if self.selectCallbackTarget ~= nil then
            self.selectCallbackFunction(self.selectCallbackTarget, id)
        else
            self.selectCallbackFunction(id)
        end
    end
end

function SelectAreaDialog:onClickBack(forceBack, usedMenuButton)
    if (self.isCloseAllowed or forceBack) and not usedMenuButton then
        self:close()

        return false
    else
        return true
    end
end

---@return LandscapingArea?
function SelectAreaDialog:getSelectedItem()
    return self.items[self.list:getSelectedIndexInSection()]
end

function SelectAreaDialog:updateMenuButtons()
    local selectedItem = self:getSelectedItem()

    self.applyButton:setDisabled(selectedItem == nil)
    self.buttonBox:invalidateLayout()
end
