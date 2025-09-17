---@class GlobalMaterialsDialog : MessageDialog
---@field hasChanged boolean
---@field forceUpdate boolean
---@field enabledList SmoothListElement
---@field enabledItems FillTypeObject[]
---@field disabledList SmoothListElement
---@field disabledItems FillTypeObject[]
---@field applyButton ButtonElement
---@field actionButton ButtonElement
---@field buttonBox BoxLayoutElement
---
---@field superClass fun(): MessageDialog
GlobalMaterialsDialog = {}

GlobalMaterialsDialog.CLASS_NAME = 'GlobalMaterialsDialog'
GlobalMaterialsDialog.XML_FILENAME = g_modDirectory .. 'xml/gui/dialogs/GlobalMaterialsDialog.xml'

GlobalMaterialsDialog.L10N_ACTION_ENABLE = g_i18n:getText('ui_enable')
GlobalMaterialsDialog.L10N_ACTION_DISABLE = g_i18n:getText('ui_disable')

local GlobalMaterialsDialog_mt = Class(GlobalMaterialsDialog, MessageDialog)

---@return GlobalMaterialsDialog
---@nodiscard
function GlobalMaterialsDialog.new()
    local self = MessageDialog.new(nil, GlobalMaterialsDialog_mt)
    ---@cast self GlobalMaterialsDialog

    self.hasChanged = false
    self.forceUpdate = true

    self.enabledItems = {}
    self.disabledItems = {}

    g_messageCenter:subscribe(SetMaterialsEvent, self.forceReload, self)

    return self
end

function GlobalMaterialsDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[GlobalMaterialsDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }

    g_messageCenter:unsubscribeAll(self)
end

function GlobalMaterialsDialog:load()
    g_gui:loadGui(GlobalMaterialsDialog.XML_FILENAME, GlobalMaterialsDialog.CLASS_NAME, self)
end

function GlobalMaterialsDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.enabledList:setDataSource(self)
    self.disabledList:setDataSource(self)

    self.enabledList.needExternalClick = true
    self.disabledList.needExternalClick = true
end

function GlobalMaterialsDialog:show()
    g_gui:showDialog(GlobalMaterialsDialog.CLASS_NAME)
end

function GlobalMaterialsDialog:onOpen()
    self:superClass().onOpen(self)

    if self.forceUpdate then
        self:updateItems()
    end

    self.hasChanged = false

    self:updateActionButtons()

    self.enabledList:makeSelectedCellVisible()
    self.disabledList:makeSelectedCellVisible()

    FocusManager:setFocus(self.enabledList)
end

function GlobalMaterialsDialog:onClose()
    self:superClass().onClose(self)

    if self.hasChanged then
        self.forceUpdate = true
    end
end

function GlobalMaterialsDialog:forceReload()
    if self.isOpen then
        self:updateItems()
        self.hasChanged = false
        self:updateActionButtons()
    else
        self.forceUpdate = true
    end
end

function GlobalMaterialsDialog:updateItems()
    self.enabledItems = {}
    self.disabledItems = {}

    for _, index in ipairs(g_fillTypeManager:getFillTypesByCategoryNames('SHOVEL')) do
        ---@type FillTypeObject | nil
        local fillType = g_fillTypeManager:getFillTypeByIndex(index)

        if fillType ~= nil then
            if table.hasElement(g_modSettings.materials, fillType.name) then
                table.insert(self.enabledItems, fillType)
            else
                table.insert(self.disabledItems, fillType)
            end
        end
    end

    table.sort(self.enabledItems, function (a, b)
        return a.title < b.title
    end)

    table.sort(self.disabledItems, function (a, b)
        return a.title < b.title
    end)

    self.enabledList:reloadData()
    self.disabledList:reloadData()

    self.forceUpdate = false
end

---@param index number
---@param fillType FillTypeObject
function GlobalMaterialsDialog:enableItem(index, fillType)
    table.remove(self.disabledItems, index)
    table.insert(self.enabledItems, fillType)

    table.sort(self.enabledItems, function (a, b)
        return a.title < b.title
    end)

    self.enabledList:reloadData()
    self.disabledList:reloadData()

    self.hasChanged = true

    self:updateActionButtons()
end

---@param index number
---@param fillType FillTypeObject
function GlobalMaterialsDialog:disableItem(index, fillType)
    table.remove(self.enabledItems, index)
    table.insert(self.disabledItems, fillType)

    table.sort(self.disabledItems, function (a, b)
        return a.title < b.title
    end)

    self.disabledList:reloadData()
    self.enabledList:reloadData()

    self.hasChanged = true

    self:updateActionButtons()
end

---@param list SmoothListElement
---@param section number
function GlobalMaterialsDialog:getNumberOfItemsInSection(list, section)
    if list == self.enabledList then
        return #self.enabledItems
    else
        return #self.disabledItems
    end
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function GlobalMaterialsDialog:populateCellForItemInSection(list, section, index, cell)
    local fillType = nil

    if list == self.enabledList then
        fillType = self.enabledItems[index]
    else
        fillType = self.disabledItems[index]
    end

    if fillType ~= nil then
        cell:getAttribute('icon'):setImageFilename(fillType.hudOverlayFilename)
        cell:getAttribute('name'):setText(fillType.title)
    end
end

---@param list SmoothListElement
---@param section number
---@param index number
function GlobalMaterialsDialog:onListSelectionChanged(list, section, index)
    self:updateActionButtons()
end

---@param list SmoothListElement
---@param section number
---@param index number
function GlobalMaterialsDialog:onItemDoubleClick(list, section, index)
    if list == self.enabledList then
        local fillType = self.enabledItems[index]

        if fillType ~= nil then
            self:disableItem(index, fillType)
        end
    else
        local fillType = self.disabledItems[index]

        if fillType ~= nil then
            self:enableItem(index, fillType)
        end
    end
end

function GlobalMaterialsDialog:updateActionButtons()
    local focusedElement = FocusManager:getFocusedElement()

    self.applyButton:setVisible(self.hasChanged)

    if focusedElement == self.enabledList then
        self.actionButton:setText(GlobalMaterialsDialog.L10N_ACTION_DISABLE)
        self.actionButton:setVisible(true)
    elseif focusedElement == self.disabledList then
        self.actionButton:setText(GlobalMaterialsDialog.L10N_ACTION_ENABLE)
        self.actionButton:setVisible(true)
    else
        self.actionButton:setVisible(false)
    end

    self.buttonBox:invalidateLayout()
end

function GlobalMaterialsDialog:onClickAction()
    local focusedElement = FocusManager:getFocusedElement()

    if focusedElement == self.enabledList then
        local index = self.enabledList:getSelectedIndexInSection()
        local fillType = self.enabledItems[index]

        if fillType ~= nil then
            self:disableItem(index, fillType)
        end
    elseif focusedElement == self.disabledList then
        local index = self.disabledList:getSelectedIndexInSection()
        local fillType = self.disabledItems[index]

        if fillType ~= nil then
            self:enableItem(index, fillType)
        end
    end
end

function GlobalMaterialsDialog:onClickApply()
    ---@type string[]
    local materials = {}

    for _, fillType in ipairs(self.enabledItems) do
        table.insert(materials, fillType.name)
    end

    g_modSettings:setMaterials(materials)

    self:close()
end
