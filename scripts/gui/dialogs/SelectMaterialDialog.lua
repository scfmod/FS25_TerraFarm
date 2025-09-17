---@class SelectMaterialDialog : MessageDialog
---@field settingsButton ButtonElement
---@field list SmoothListElement
---@field items FillTypeObject[]
---@field superClass fun(): MessageDialog
SelectMaterialDialog = {}

SelectMaterialDialog.CLASS_NAME = 'SelectMaterialDialog'
SelectMaterialDialog.XML_FILENAME = g_modDirectory .. 'xml/gui/dialogs/SelectMaterialDialog.xml'

local SelectMaterialDialog_mt = Class(SelectMaterialDialog, MessageDialog)

---@return SelectMaterialDialog
---@nodiscard
function SelectMaterialDialog.new()
    local self = MessageDialog.new(nil, SelectMaterialDialog_mt)
    ---@cast self SelectMaterialDialog

    self.items = {}

    return self
end

function SelectMaterialDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[SelectMaterialDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }

    g_messageCenter:unsubscribeAll(self)
end

function SelectMaterialDialog:load()
    g_gui:loadGui(SelectMaterialDialog.XML_FILENAME, SelectMaterialDialog.CLASS_NAME, self)
end

function SelectMaterialDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.list:setDataSource(self)
end

---@param fn function | nil
---@param target any
function SelectMaterialDialog:setSelectCallback(fn, target)
    self.selectCallbackFunction = fn
    self.selectCallbackTarget = target
end

---@param selectFillTypeIndex number | nil
function SelectMaterialDialog:show(selectFillTypeIndex)
    g_gui:showDialog(SelectMaterialDialog.CLASS_NAME)

    self:setSelectedItem(selectFillTypeIndex)
end

function SelectMaterialDialog:onOpen()
    self:superClass().onOpen(self)

    self:updateItems()
    self:updateMenuButtons()

    g_messageCenter:subscribe(SetMaterialsEvent, self.updateItems, self)
    g_messageCenter:subscribe(MessageType.MASTERUSER_ADDED, self.onMasterUserAdded, self)
end

function SelectMaterialDialog:onClose()
    self:superClass().onClose(self)

    g_messageCenter:unsubscribeAll(self)
end

function SelectMaterialDialog:updateItems()
    self.items = {}

    for _, fillTypeName in ipairs(g_modSettings.materials) do
        ---@type FillTypeObject | nil
        local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName)

        if fillType ~= nil then
            table.insert(self.items, fillType)
        end
    end

    table.sort(self.items, function (a, b)
        return a.title < b.title
    end)

    self.list:reloadData()
end

function SelectMaterialDialog:updateMenuButtons()
    self.settingsButton:setVisible(MachineUtils.getCanModifySettings())
end

---@param fillTypeIndex number | nil
function SelectMaterialDialog:setSelectedItem(fillTypeIndex)
    if fillTypeIndex ~= nil then
        for index, fillType in ipairs(self.items) do
            if fillType.index == fillTypeIndex then
                self.list:setSelectedIndex(index)
                return
            end
        end
    end

    self.list:setSelectedIndex(1)
end

function SelectMaterialDialog:getNumberOfItemsInSection()
    return #self.items
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function SelectMaterialDialog:populateCellForItemInSection(list, section, index, cell)
    local fillType = self.items[index]

    if fillType ~= nil then
        cell:getAttribute('image'):setImageFilename(fillType.hudOverlayFilename)
        cell:getAttribute('name'):setText(fillType.title)
    end
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function SelectMaterialDialog:onItemDoubleClick(list, section, index, cell)
    self:sendCallback(index)
end

function SelectMaterialDialog:onClickApply()
    self:sendCallback(self.list:getSelectedIndexInSection())
end

function SelectMaterialDialog:onClickMaterialSettings()
    g_globalMaterialsDialog:show()
end

---@param index number | nil
function SelectMaterialDialog:sendCallback(index)
    local item = self.items[index]

    self:close()

    if self.selectCallbackFunction ~= nil then
        if self.selectCallbackTarget ~= nil then
            self.selectCallbackFunction(self.selectCallbackTarget, item and item.index)
        else
            self.selectCallbackFunction(item and item.index)
        end
    end
end

function SelectMaterialDialog:onClickBack(forceBack, usedMenuButton)
    if (self.isCloseAllowed or forceBack) and not usedMenuButton then
        self:sendCallback(nil)

        return false
    else
        return true
    end
end

---@param user User
function SelectMaterialDialog:onMasterUserAdded(user)
    if user:getId() == g_currentMission.playerUserId then
        self:updateMenuButtons()
    end
end
