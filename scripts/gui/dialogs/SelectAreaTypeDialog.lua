---@class AreaTypeItem
---@field title string
---@field description string
---@field imageSliceId string
---@field className string

---@class SelectAreaTypeDialog : MessageDialog
---@field list SmoothListElement
---@field items AreaTypeItem[]
---@field superClass fun(): MessageDialog
SelectAreaTypeDialog = {}
SelectAreaTypeDialog.CLASS_NAME = 'SelectAreaTypeDialog'
SelectAreaTypeDialog.XML_FILENAME = g_modDirectory .. 'data/gui/dialogs/SelectAreaTypeDialog.xml'

local SelectAreaTypeDialog_mt = Class(SelectAreaTypeDialog, MessageDialog)

---@return SelectAreaTypeDialog
---@nodiscard
function SelectAreaTypeDialog.new()
    local self = MessageDialog.new(nil, SelectAreaTypeDialog_mt)
    ---@cast self SelectAreaTypeDialog

    self.items = {
        {
            title = g_i18n:getText('ui_areaPath'),
            description = g_i18n:getText('ui_areaPathText'),
            imageSliceId = 'terraFarm.icon_path',
            className = 'LandscapingAreaPath'
        },
        {
            title = g_i18n:getText('ui_areaPolygon'),
            description = g_i18n:getText('ui_areaPolygonText'),
            imageSliceId = 'terraFarm.icon_polygon',
            className = 'LandscapingAreaPolygon'
        },
    }

    return self
end

function SelectAreaTypeDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[SelectAreaTypeDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }

    g_messageCenter:unsubscribeAll(self)
end

function SelectAreaTypeDialog:load()
    g_gui:loadGui(SelectAreaTypeDialog.XML_FILENAME, SelectAreaTypeDialog.CLASS_NAME, self)
end

function SelectAreaTypeDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.list:setDataSource(self)
end

function SelectAreaTypeDialog:show()
    g_gui:showDialog(SelectAreaTypeDialog.CLASS_NAME)
end

function SelectAreaTypeDialog:onOpen()
    self:superClass().onOpen(self)

    if self.list.totalItemCount == 0 then
        self.list:reloadData()
    end

    FocusManager:setFocus(self.list)
end

---@param fn function?
---@param target any
function SelectAreaTypeDialog:setSelectCallback(fn, target)
    self.selectCallbackFunction = fn
    self.selectCallbackTarget = target
end

function SelectAreaTypeDialog:getNumberOfItemsInSection()
    return #self.items
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function SelectAreaTypeDialog:populateCellForItemInSection(list, section, index, cell)
    local item = self.items[index]

    if item ~= nil then
        cell:getAttribute('title'):setText(item.title)
        cell:getAttribute('text'):setText(item.description)
        cell:getAttribute('image'):setImageSlice(nil, item.imageSliceId)
    end
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function SelectAreaTypeDialog:onItemDoubleClick(list, section, index, cell)
    self:sendCallback(index)
end

function SelectAreaTypeDialog:onClickSelect()
    self:sendCallback(self.list:getSelectedIndexInSection())
end

---@param index number?
function SelectAreaTypeDialog:sendCallback(index)
    local item = self.items[index]

    self:close()

    if self.selectCallbackFunction ~= nil then
        if self.selectCallbackTarget ~= nil then
            self.selectCallbackFunction(self.selectCallbackTarget, item)
        else
            self.selectCallbackFunction(item)
        end
    end

    self.selectCallbackFunction = nil
    self.selectCallbackTarget = nil
end

function SelectAreaTypeDialog:onClickBack(forceBack, usedMenuButton)
    if (self.isCloseAllowed or forceBack) and not usedMenuButton then
        self:sendCallback(nil)

        return false
    else
        return true
    end
end
