---@class MachineScreen : TabbedMenuWithDetails
---@field superClass fun(): TabbedMenuWithDetails
MachineScreen = {}

MachineScreen.CLASS_NAME = 'MachineScreen'
MachineScreen.XML_FILENAME = g_currentModDirectory .. 'xml/gui/screens/MachineScreen.xml'

local MachineScreen_mt = Class(MachineScreen, TabbedMenuWithDetails)

function MachineScreen.new(target, customMt)
    local self = TabbedMenuWithDetails.new(target, customMt or MachineScreen_mt)
    ---@cast self MachineScreen

    self.currentPageName = ''

    return self
end

function MachineScreen:load()
    self.settingsFrame = MachineSettingsFrame.new(self)
    self.landscapingSettingsFrame = MachineSettingsLandscapingFrame.new(self)
    self.advancedSettingsFrame = MachineSettingsAdvancedFrame.new(self)
    self.calibrationSettingsFrame = MachineSettingsCalibrationFrame.new(self)

    g_gui:loadGui(MachineSettingsFrame.XML_FILENAME, MachineSettingsFrame.CLASS_NAME, self.settingsFrame, true)
    g_gui:loadGui(MachineSettingsLandscapingFrame.XML_FILENAME, MachineSettingsLandscapingFrame.CLASS_NAME, self.landscapingSettingsFrame, true)
    g_gui:loadGui(MachineSettingsAdvancedFrame.XML_FILENAME, MachineSettingsAdvancedFrame.CLASS_NAME, self.advancedSettingsFrame, true)
    g_gui:loadGui(MachineSettingsCalibrationFrame.XML_FILENAME, MachineSettingsCalibrationFrame.CLASS_NAME, self.calibrationSettingsFrame, true)

    g_gui:loadGui(MachineScreen.XML_FILENAME, MachineScreen.CLASS_NAME, self)
end

function MachineScreen:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.settingsFrame:initialize()
    self.landscapingSettingsFrame:initialize()
    self.advancedSettingsFrame:initialize()
    self.calibrationSettingsFrame:initialize()

    self:setupPages()
end

function MachineScreen:setupPages()
    ---@return boolean
    local function calibrationPredicateFunction()
        if self.vehicle ~= nil and self.vehicle.spec_machine ~= nil then
            return MachineUtils.getHasInputMode(self.vehicle, Machine.MODE.FLATTEN) or MachineUtils.getHasOutputMode(self.vehicle, Machine.MODE.FLATTEN)
        end

        return false
    end

    local pages = {
        {
            self.settingsFrame,
            'gui.icon_options_generalSettings2'
        },
        {
            self.landscapingSettingsFrame,
            'gui.icon_construction_terraforming'
        },
        {
            self.advancedSettingsFrame,
            'gui.icon_options_device'
        },
        {
            self.calibrationSettingsFrame,
            'terraFarm.icon_surveyor',
            calibrationPredicateFunction
        },
    }

    for i, page in ipairs(pages) do
        local element, iconSliceId, enablingPredicateFunction = unpack(page)

        self:registerPage(element, i, enablingPredicateFunction)
        self:addPageTab(element, nil, nil, iconSliceId)
    end
end

function MachineScreen:setupMenuButtonInfo()
    local onButtonBackFunction = self.clickBackCallback
    local onButtonSettingsFunction = self:makeSelfCallback(self.onClickGlobalSettings)

    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK,
        text = g_i18n:getText(InGameMenu.L10N_SYMBOL.BUTTON_BACK),
        callback = onButtonBackFunction
    }

    self.settingsButtonInfo = {
        inputAction = InputAction.MENU_EXTRA_2,
        text = g_i18n:getText('ui_globalSettings'),
        callback = onButtonSettingsFunction
    }

    self.defaultMenuButtonInfo = {
        self.backButtonInfo,
        self.settingsButtonInfo
    }
    self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.backButtonInfo
    self.defaultMenuButtonInfoByActions[InputAction.MENU_EXTRA_2] = self.settingsButtonInfo

    self.defaultButtonActionCallbacks = {
        [InputAction.MENU_BACK] = onButtonBackFunction,
        [InputAction.MENU_EXTRA_2] = onButtonSettingsFunction
    }
end

function MachineScreen:show(vehicle)
    if vehicle ~= nil then
        self.vehicle = vehicle
        g_gui:showDialog(MachineScreen.CLASS_NAME)
    end
end

function MachineScreen:exitMenu()
    self:popToRoot()
    g_gui:closeDialogByName(self.name)
end

function MachineScreen:onOpen()
    ScreenElement.onOpen(self)

    ---@diagnostic disable-next-line: undefined-global
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.PAGING)
    self:setSoundSuppressed(true)

    local top = self:getTopFrame()

    if self:isAtRoot() then
        self:updatePages()
        ---@diagnostic disable-next-line: undefined-field
        self.pageSelector:setState(self.restorePageIndex, true)
    else
        top:onFrameOpen()
        self:updateButtonsPanel(top)
    end

    self:setSoundSuppressed(false)
    self:onMenuOpened()
    self:updateVehicle()

    g_messageCenter:subscribe(MessageType.MACHINE_REMOVED, self.onMachineRemoved, self)

    FocusManager:lockFocusInput(InputAction.MENU_PAGE_NEXT, 150)
    FocusManager:lockFocusInput(InputAction.MENU_PAGE_PREV, 150)
    FocusManager:lockFocusInput(FocusManager.TOP, 150)
    FocusManager:lockFocusInput(FocusManager.BOTTOM, 150)
end

function MachineScreen:onClose()
    if self.currentPage ~= nil then
        self.currentPage:onFrameClose()
    end

    ScreenElement.onClose(self)

    g_inputBinding:storeEventBindings()
    self:clearMenuButtonActions()

    ---@diagnostic disable-next-line: undefined-field
    self.restorePageIndex = self.pageSelector:getState()
    ---@diagnostic disable-next-line: undefined-field
    self.restorePageScrollOffset = self.pagingTabList.viewOffset

    self.vehicle = nil

    g_messageCenter:unsubscribeAll(self)
end

function MachineScreen:onClickBack()
    if self.currentPage:requestClose(self.clickBackCallback) then
        self:exitMenu()
        return false
    end

    return true
end

---@param vehicle Machine
function MachineScreen:onMachineRemoved(vehicle)
    if vehicle ~= nil and vehicle == self.vehicle then
        self:exitMenu()
    end
end

function MachineScreen:updateVehicle()
    -- if self.vehicle ~= nil then
    --     local spec = self.vehicle.spec_machine

    --     self.vehicleImage:setImageFilename(self.vehicle:getImageFilename())
    --     self.machineTypeName:setText(spec.machineType.name)
    --     self.vehicleName:setText(self.vehicle:getName())

    --     if self.vehicle.brand ~= nil then
    --         self.vehicleBrandName:setText(self.vehicle.brand.title)
    --     else
    --         self.vehicleBrandName:setText('Unknown')
    --     end
    -- end
end

---@param dt number
function MachineScreen:update(dt)
    ScreenElement.update(self, dt)

    if FocusManager.currentGui ~= self.currentPageName and #g_gui.dialogs == 1 then
        FocusManager:setGui(self.currentPageName)
    end

    if self.currentPage ~= nil then
        if self.currentPage:isMenuButtonInfoDirty() then
            self:assignMenuButtonInfo(self.currentPage:getMenuButtonInfo())
            self.currentPage:clearMenuButtonInfoDirty()
        end

        if self.currentPage:isTabbingMenuVisibleDirty() then
            self:updatePagingVisibility(self.currentPage:getTabbingMenuVisible())
        end
    end
end

function MachineScreen:onClickGlobalSettings()
    g_globalSettingsDialog:show()
end

function MachineScreen:getStack(page)
    local pageId = self.currentPageId
    if page ~= nil then
        ---@diagnostic disable-next-line: undefined-field
        pageId = self.pagingElement:getPageIndexByElement(page)
    else
        ---@diagnostic disable-next-line: undefined-field
        page = self.pagingElement:getPageElementByIndex(pageId)
    end

    if self.stacks[pageId] == nil then
        self.stacks[pageId] = {}

        local root = {
            page = page,
            pageId = pageId,
            isRoot = true,
        }

        table.insert(self.stacks[pageId], root)
    end

    return self.stacks[pageId]
end

---@param self TabbedMenuWithDetails
---@diagnostic disable-next-line: lowercase-global
function MachineScreen:reset()
    TabbedMenu.reset(self)

    self.currentPageName = ''
    self.stacks = {}
end

function MachineScreen:onPageChange(pageIndex, pageMappingIndex, element, skipTabVisualUpdate)
    -- If the new page is a detail page, then do not update
    if self.isChangingDetail then
        skipTabVisualUpdate = true
    else
        self:popToRoot()
    end

    if self.currentPage ~= nil then
        self.currentPage:onFrameClose()
        self.currentPage:setVisible(false)
    end

    g_inputBinding:storeEventBindings() -- reset any disabled bindings for page custom input in menu context

    ---@diagnostic disable-next-line: undefined-field
    local page = self.pagingElement:getPageElementByIndex(pageIndex)
    self.currentPage = page
    self.currentPageName = page.name -- store page name for FocusManager GUI context override in update()
    self.currentPageListIndex = pageMappingIndex

    if not skipTabVisualUpdate then
        self.currentPageId = pageIndex
        ---@diagnostic disable-next-line: undefined-field
        self.pagingTabList:setSelectedIndex(pageMappingIndex)
    end

    page:setVisible(true)
    page:setSoundSuppressed(true)
    FocusManager:setGui(page.name)
    page:setSoundSuppressed(false)

    self:updateButtonsPanel(page)
    self:updateTabDisplay()

    page:onFrameOpen()
end
