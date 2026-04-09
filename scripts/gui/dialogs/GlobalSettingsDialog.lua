---@class GlobalSettingsDialog : MessageDialog
---@field boxLayout ScrollingLayoutElement
---@field hudEnabledOption BinaryOptionElement
---@field enabledOption BinaryOptionElement
---@field defaultEnabledOption BinaryOptionElement
---@field settingsButton ButtonElement
---@field debugNodesOption BinaryOptionElement
---@field debugCalibrationOption BinaryOptionElement
---@field resourcesEnabledOption BinaryOptionElement
---@field resourcesEnabledOptionContainer BitmapElement
---@field borderModeOption MultiTextOptionElement
---@field borderVisibilityOption MultiTextOptionElement
---@field extensionStatus TextElement
---@field superClass fun(): MessageDialog
GlobalSettingsDialog = {}

GlobalSettingsDialog.CLASS_NAME = 'GlobalSettingsDialog'
GlobalSettingsDialog.XML_FILENAME = g_modDirectory .. 'data/gui/dialogs/GlobalSettingsDialog.xml'

GlobalSettingsDialog.L10N_SYMBOL = {
    FEATURE_AVAILABLE = g_i18n:getText('ui_mapResourcesAvailable'),
    FEATURE_NOT_AVAILABLE = g_i18n:getText('ui_mapResourcesNotAvailable'),
}

local GlobalSettingsDialog_mt = Class(GlobalSettingsDialog, MessageDialog)

---@return GlobalSettingsDialog
---@nodiscard
function GlobalSettingsDialog.new()
    local self = MessageDialog.new(nil, GlobalSettingsDialog_mt)
    ---@cast self GlobalSettingsDialog

    return self
end

function GlobalSettingsDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[GlobalSettingsDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }

    g_messageCenter:unsubscribeAll(self)
end

function GlobalSettingsDialog:load()
    g_gui:loadGui(GlobalSettingsDialog.XML_FILENAME, GlobalSettingsDialog.CLASS_NAME, self)
end

function GlobalSettingsDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.borderModeOption:setTexts({
        'GROUND_MESH_XRAY',
        'GROUND_MESH_NORMAL',
        'GROUND_ONLY',
        'MESH_ONLY_XRAY',
        'MESH_ONLY_NORMAL',
    })

    self.borderVisibilityOption:setTexts({
        'ALL',
        'ACTIVE_ONLY',
        'NONE'
    })
end

function GlobalSettingsDialog:show()
    g_gui:showDialog(GlobalSettingsDialog.CLASS_NAME)
end

function GlobalSettingsDialog:onOpen()
    self:superClass().onOpen(self)

    self:updateSettings()
    self:updateMenuButtons()

    local focusedElement = FocusManager:getFocusedElement()

    if focusedElement == nil or focusedElement.name == GlobalSettingsDialog.CLASS_NAME then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.enabledOption)
        self:setSoundSuppressed(false)
    end

    g_messageCenter:subscribe(SetDefaultEnabledEvent, self.updateSettings, self)
    g_messageCenter:subscribe(SetEnabledEvent, self.updateSettings, self)
    g_messageCenter:subscribe(SetResourcesEvent, self.updateSettings, self)
    g_messageCenter:subscribe(MessageType.MASTERUSER_ADDED, self.onMasterUserAdded, self)
end

function GlobalSettingsDialog:onClose()
    self:superClass().onClose(self)

    g_messageCenter:unsubscribeAll(self)
end

function GlobalSettingsDialog:updateSettings()
    local canModifySettings = ModUtils.getIsAdministrator()

    self.enabledOption:setIsChecked(g_modSettings:getIsEnabled(), true)
    self.enabledOption:setDisabled(not canModifySettings)

    self.defaultEnabledOption:setDisabled(not canModifySettings)
    self.defaultEnabledOption:setIsChecked(g_modSettings.defaultEnabled, true)

    self.borderVisibilityOption:setState(g_landscapingManager.borderVisibilityMode)
    self.borderModeOption:setState(g_landscapingManager.borderMode)

    self.debugNodesOption:setIsChecked(g_modSettings:getDebugNodes(), true)
    self.debugCalibrationOption:setIsChecked(g_modSettings:getDebugCalibration(), true)

    self.settingsButton:setVisible(canModifySettings)

    local resourcesAvailable = g_resourceManager:getIsAvailable()

    self.resourcesEnabledOptionContainer:setDisabled(not resourcesAvailable)
    self.resourcesEnabledOption:setIsChecked(g_resourceManager:getIsActive(), true)

    self.hudEnabledOption:setIsChecked(g_modHud.display.isVisible, true)

    if resourcesAvailable then
        self.extensionStatus:setText(GlobalSettingsDialog.L10N_SYMBOL.FEATURE_AVAILABLE)
        self.extensionStatus:setDisabled(false)
    else
        self.extensionStatus:setText(GlobalSettingsDialog.L10N_SYMBOL.FEATURE_NOT_AVAILABLE)
        self.extensionStatus:setDisabled(true)
    end
end

function GlobalSettingsDialog:updateMenuButtons()
    self.settingsButton:setVisible(ModUtils.getIsAdministrator())
end

function GlobalSettingsDialog:forceReload()
    self:updateSettings()
    self.boxLayout:invalidateLayout()
end

---@param state number
function GlobalSettingsDialog:onClickHudEnabledOption(state)
    g_modHud.display:setVisible(state == CheckedOptionElement.STATE_CHECKED, false)

    g_modSettings:saveUserSettings()
end

---@param state number
function GlobalSettingsDialog:onClickDebugNodesOption(state)
    g_modSettings:setDebugNodes(state == CheckedOptionElement.STATE_CHECKED)
end

---@param state number
function GlobalSettingsDialog:onClickDebugCalibrationOption(state)
    g_modSettings:setDebugCalibration(state == CheckedOptionElement.STATE_CHECKED)
end

---@param state number
function GlobalSettingsDialog:onClickEnabledOption(state)
    g_modSettings:setIsEnabled(state == CheckedOptionElement.STATE_CHECKED)
end

---@param state number
function GlobalSettingsDialog:onClickDefaultEnabledOption(state)
    g_modSettings:setDefaultEnabled(state == CheckedOptionElement.STATE_CHECKED)
end

---@param state number
function GlobalSettingsDialog:onClickBorderVisibilityOption(state)
    g_landscapingManager:setBorderVisibilityMode(state)
end

---@param state number
function GlobalSettingsDialog:onClickBorderModeOption(state)
    g_landscapingManager:setBorderMode(state)
end

function GlobalSettingsDialog:onClickMaterialSettings()
    g_globalMaterialsDialog:show()
end

---@param state number
function GlobalSettingsDialog:onClickResourcesEnabledOption(state)
    g_resourceManager:setIsActive(state == CheckedOptionElement.STATE_CHECKED)
end

---@param user User
function GlobalSettingsDialog:onMasterUserAdded(user)
    if user:getId() == g_currentMission.playerUserId then
        self:updateSettings()
        self:updateMenuButtons()
    end
end
