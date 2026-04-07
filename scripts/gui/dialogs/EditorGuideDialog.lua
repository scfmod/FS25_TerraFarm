---@class EditorGuideDialog : MessageDialog
---@field guideImages BitmapElement[]
---@field superClass fun(): MessageDialog
EditorGuideDialog = {}
EditorGuideDialog.CLASS_NAME = 'EditorGuideDialog'
EditorGuideDialog.XML_FILENAME = g_modDirectory .. 'data/gui/dialogs/EditorGuideDialog.xml'

local EditorGuideDialog_mt = Class(EditorGuideDialog, MessageDialog)

---@return EditorGuideDialog
---@nodiscard
function EditorGuideDialog.new()
    ---@type EditorGuideDialog
    local self = MessageDialog.new(nil, EditorGuideDialog_mt)

    return self
end

function EditorGuideDialog:delete()
    EditorGuideDialog:superClass().delete(self)

    FocusManager.guiFocusData[EditorGuideDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }
end

function EditorGuideDialog:load()
    g_gui:loadGui(EditorGuideDialog.XML_FILENAME, EditorGuideDialog.CLASS_NAME, self)
end

function EditorGuideDialog:show()
    g_gui:showDialog(EditorGuideDialog.CLASS_NAME)
end
