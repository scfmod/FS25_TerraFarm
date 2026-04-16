---@class InGameMenuTerraFarmFrame : TabbedMenuFrameElement
---@field isOpen boolean
---@field lastUpdate number
---@field backButtonInfo table
---@field frameSliderBox ThreePartBitmapElement
---@field frameSlider SliderElement
---@field vehicles Machine[]
---@field areas LandscapingArea[]
---@field waterplanes LandscapingWaterplane[]
---@field machinesList SmoothListElement
---@field areasList SmoothListElement
---@field waterplanesList SmoothListElement
---@field detailBox GuiElement
---@field itemDetailsImage BitmapElement
---@field itemDetailsName TextElement
---@field subCategoryBox BoxLayoutElement
---@field subCategoryTabs ButtonElement[]
---@field subCategoryPaging MultiTextOptionElement
---@field subCategoryPages GuiElement[]
---@field superClass fun(): TabbedMenuFrameElement
---@field onPageNext function
---@field onPagePrevious function
---@field listSlider SliderElement
InGameMenuTerraFarmFrame = {}

InGameMenuTerraFarmFrame.CLASS_NAME = 'InGameMenuTerraFarmFrame'
InGameMenuTerraFarmFrame.MENU_PAGE_NAME = 'ingameMenuTerraFarm'
InGameMenuTerraFarmFrame.MENU_ICON_SLICE_ID = 'terraFarm.icon_excavator'
InGameMenuTerraFarmFrame.XML_FILENAME = g_modDirectory .. 'data/gui/InGameMenuTerraFarmFrame.xml'
InGameMenuTerraFarmFrame.UPDATE_INTERVAL = 4000

InGameMenuTerraFarmFrame.L10N_SYMBOL = {
    ACTION_DISABLE = g_i18n:getText('ui_disable'),
    ACTION_ENABLE = g_i18n:getText('ui_enable'),
    ACTION_MACHINE_SETTINGS = g_i18n:getText('ui_machineSettings'),
    ACTION_SETTINGS = g_i18n:getText('ui_globalSettings'),
    DISABLED = g_i18n:getText('ui_disabled'),
    ENABLED = g_i18n:getText('ui_enabled'),
}

local InGameMenuTerraFarmFrame_mt = Class(InGameMenuTerraFarmFrame, TabbedMenuFrameElement)

---@return InGameMenuTerraFarmFrame
function InGameMenuTerraFarmFrame.new()
    local self = TabbedMenuFrameElement.new(nil, InGameMenuTerraFarmFrame_mt)
    ---@cast self InGameMenuTerraFarmFrame

    self.isOpen = false
    self.lastUpdate = 0
    self.vehicles = {}
    self.areas = {}
    self.waterplanes = {}

    self.hasCustomMenuButtons = true

    return self
end

function InGameMenuTerraFarmFrame:delete()
    self:superClass().delete(self)

    g_messageCenter:unsubscribeAll(self)

    FocusManager.guiFocusData[InGameMenuTerraFarmFrame.MENU_PAGE_NAME] = {
        idToElementMapping = {}
    }
end

function InGameMenuTerraFarmFrame:initialize()
    self:superClass().initialize(self)

    for index, button in pairs(self.subCategoryTabs) do
        button:getDescendantByName("background").getIsSelected = function ()
            return index == self.subCategoryPaging:getState()
        end
        function button.getIsSelected()
            return index == self.subCategoryPaging:getState()
        end
    end

    self.nextPageButtonInfo = {
        inputAction = InputAction.MENU_PAGE_NEXT,
        text = g_i18n:getText("ui_ingameMenuNext"),
        callback = self.onPageNext
    }

    self.prevPageButtonInfo = {
        inputAction = InputAction.MENU_PAGE_PREV,
        text = g_i18n:getText("ui_ingameMenuPrev"),
        callback = self.onPagePrevious
    }

    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }

    self.settingsButtonInfo = {
        inputAction = InputAction.MENU_EXTRA_1,
        text = InGameMenuTerraFarmFrame.L10N_SYMBOL.ACTION_SETTINGS,
        callback = function ()
            self:onClickGlobalSettings()
        end
    }

    self.machineSettingsButtonInfo = {
        inputAction = InputAction.MENU_ACCEPT,
        text = InGameMenuTerraFarmFrame.L10N_SYMBOL.ACTION_MACHINE_SETTINGS,
        callback = function ()
            self:onClickMachineSettings()
        end
    }

    self.toggleEnabledButtonInfo = {
        inputAction = InputAction.MENU_ACTIVATE,
        text = InGameMenuTerraFarmFrame.L10N_SYMBOL.ACTION_ENABLE,
        callback = function ()
            self:onClickToggleEnabled()
        end
    }

    self.createAreaButtonInfo = {
        inputAction = InputAction.MENU_EXTRA_1,
        text = Editor.L10N_SYMBOL.CREATE_AREA,
        callback = function ()
            self:onClickCreateArea()
        end
    }

    self.editAreaButtonInfo = {
        inputAction = InputAction.MENU_ACCEPT,
        text = Editor.L10N_SYMBOL.EDIT,
        callback = function ()
            self:onClickEditArea()
        end
    }

    self.toggleActiveButtonInfo = {
        inputAction = InputAction.MENU_ACTIVATE,
        text = Editor.L10N_SYMBOL.SET_VISIBLE,
        callback = function ()
            self:onClickToggleActive()
        end
    }

    self.deleteAreaButtonInfo = {
        inputAction = InputAction.MENU_CANCEL,
        text = Editor.L10N_SYMBOL.DELETE,
        callback = function ()
            self:onClickDeleteArea()
        end
    }

    self.machinesList:setDataSource(self)
    self.areasList:setDataSource(self)

    self.subCategoryPaging:setState(1)
end

function InGameMenuTerraFarmFrame:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self:initialize()
end

function InGameMenuTerraFarmFrame:getMenuButtonInfo()
    return self.menuButtonInfo
end

function InGameMenuTerraFarmFrame:onFrameOpen()
    self:superClass().onFrameOpen(self)

    self.isOpen = true

    self:updateVehicles()
    self:updateAreas()
    self:updateWaterplanes()

    self.detailBox:setVisible(#self.vehicles > 0)

    g_messageCenter:subscribe(ModMessageType.MACHINE_ADD, self.onMachineAdd, self)
    g_messageCenter:subscribe(ModMessageType.MACHINE_REMOVE, self.onMachineRemove, self)

    g_messageCenter:subscribe(ModMessageType.LANDSCAPING_AREA_DELETE, self.updateAreas, self)
    g_messageCenter:subscribe(ModMessageType.LANDSCAPING_AREA_REGISTER, self.updateAreas, self)
    g_messageCenter:subscribe(ModMessageType.LANDSCAPING_AREA_UPDATE, self.updateAreas, self)

    g_messageCenter:subscribe(ModMessageType.WATERPLANE_DELETE, self.updateWaterplanes, self)
    g_messageCenter:subscribe(ModMessageType.WATERPLANE_REGISTER, self.updateWaterplanes, self)
    g_messageCenter:subscribe(ModMessageType.WATERPLANE_UPDATE, self.updateWaterplanes, self)

    g_messageCenter:subscribe(MessageType.MASTERUSER_ADDED, self.onMasterUserAdded, self)
    g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.onPlayerFarmChanged, self)
    g_messageCenter:subscribe(PlayerPermissionsEvent, self.onPlayerPermissionsChanged, self)

    g_machineManager:checkDisplayWarning()

    self.subCategoryBox:invalidateLayout()
    self.subCategoryPaging:setTexts({ '1', '2', '3' })
    self.subCategoryPaging:setSize(self.subCategoryBox.maxFlowSize + 140 * g_pixelSizeScaledX)

    local subCategoryIndex = self.subCategoryPaging:getState()
    self:updateSubCategoryPages(subCategoryIndex)

    if subCategoryIndex == 1 then
        FocusManager:setFocus(self.machinesList)
    elseif subCategoryIndex == 2 then
        FocusManager:setFocus(self.areasList)
    elseif subCategoryIndex == 3 then
        FocusManager:setFocus(self.waterplanesList)
    end
end

function InGameMenuTerraFarmFrame:onFrameClose()
    self.isOpen = false
    g_messageCenter:unsubscribeAll(self)

    self:superClass().onFrameClose(self)
end

---@param dt number
function InGameMenuTerraFarmFrame:update(dt)
    self:superClass().update(self, dt)

    if self.isOpen then
        self.lastUpdate = self.lastUpdate + dt

        if self.lastUpdate > InGameMenuTerraFarmFrame.UPDATE_INTERVAL then
            local subCategoryIndex = self.subCategoryPaging:getState()

            if subCategoryIndex == 1 then
                self:updateVehicles()
            elseif subCategoryIndex == 2 then
                self:updateAreas()
            elseif subCategoryIndex == 3 then
                self:updateWaterplanes()
            end

            self.lastUpdate = 0
        end
    end
end

function InGameMenuTerraFarmFrame:updateVehicles()
    self.vehicles = g_machineManager:getAccessibleVehicles()

    ---@param a Machine
    ---@param b Machine
    local function sortFn(a, b)
        return a:getFullName():upper() < b:getFullName():upper()
    end

    table.sort(self.vehicles, sortFn)

    self.machinesList:reloadData()

    self:updateVehicleDetails()
    self:updateMenuButtons()

    self.lastUpdate = 0
end

function InGameMenuTerraFarmFrame:updateAreas()
    self.areas = g_landscapingManager:getAreas()

    ---@param a LandscapingArea
    ---@param b LandscapingArea
    local function sortFn(a, b)
        return a:getName():upper() < b:getName():upper()
    end

    table.sort(self.areas, sortFn)

    self.areasList:reloadData()
    self:updateMenuButtons()
    self.lastUpdate = 0
end

function InGameMenuTerraFarmFrame:updateWaterplanes()
    self.waterplanes = g_landscapingManager:getWaterplanes()

    ---@param a LandscapingWaterplane
    ---@param b LandscapingWaterplane
    local function sortFn(a, b)
        return a:getName():upper() < b:getName():upper()
    end

    table.sort(self.waterplanes, sortFn)

    self.waterplanesList:reloadData()
    self:updateMenuButtons()
    self.lastUpdate = 0
end

---@param list SmoothListElement
---@param section number
---@return number
function InGameMenuTerraFarmFrame:getNumberOfItemsInSection(list, section)
    if list == self.areasList then
        return #self.areas
    elseif list == self.machinesList then
        return #self.vehicles
    elseif list == self.waterplanesList then
        return #self.waterplanes
    end

    return 0
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell table
function InGameMenuTerraFarmFrame:populateCellForItemInSection(list, section, index, cell)
    if list == self.areasList then
        local area = self.areas[index]

        if area ~= nil then
            local r, g, b = area:getDisplayColor()
            ---@type BitmapElement
            local imageElement = cell:getAttribute('icon')

            imageElement:setImageColor(nil, r, g, b)
            imageElement:setImageSlice(nil, area:getIconSliceId())

            cell:getAttribute('name'):setText(area:getName())
            cell:getAttribute('type'):setText(area:getTypeName())
            cell:getAttribute('status'):setText(area.visible and Editor.L10N_SYMBOL.VISIBLE or Editor.L10N_SYMBOL.HIDDEN)
        end
    elseif list == self.waterplanesList then
        local waterplane = self.waterplanes[index]

        if waterplane ~= nil then
            cell:getAttribute('name'):setText(waterplane:getName())
            cell:getAttribute('status'):setText(waterplane.visible and Editor.L10N_SYMBOL.VISIBLE or Editor.L10N_SYMBOL.HIDDEN)
        end
    elseif list == self.machinesList then
        local vehicle = self.vehicles[index]

        if vehicle ~= nil then
            local spec = vehicle.spec_machine

            cell:getAttribute('name'):setText(vehicle:getFullName())
            cell:getAttribute('age'):setText(Vehicle.getSpecValueAge(nil, vehicle))
            cell:getAttribute('operatingHours'):setText(Vehicle.getSpecValueOperatingTime(nil, vehicle))
            cell:getAttribute('status'):setText(spec.enabled and InGameMenuTerraFarmFrame.L10N_SYMBOL.ENABLED or InGameMenuTerraFarmFrame.L10N_SYMBOL.DISABLED)
            cell:getAttribute('type'):setText(spec.machineType.name)

            if SpecializationUtil.hasSpecialization(Wearable, vehicle.specializations) then
                ---@diagnostic disable-next-line: undefined-field
                local amount = (1 - vehicle:getDamageAmount()) * 100

                cell:getAttribute('damage'):setText(g_i18n:formatNumber(math.ceil(amount), 0) .. " %")
            else
                cell:getAttribute('damage'):setText('-')
            end

            ---@type Enterable
            ---@diagnostic disable-next-line: assign-type-mismatch
            local rootVehicle = vehicle:getRootVehicle()

            if rootVehicle.getIsControlled ~= nil and rootVehicle:getIsControlled() then
                cell:getAttribute('operator'):setText(rootVehicle:getControllerName())
            else
                cell:getAttribute('operator'):setText('-')
            end
        end
    end
end

---@param list SmoothListElement
---@param section number
---@param index number
function InGameMenuTerraFarmFrame:onListSelectionChanged(list, section, index)
    if list ~= self.areasList then
        self:updateVehicleDetails()
    end

    self:updateMenuButtons()
end

function InGameMenuTerraFarmFrame:updateMenuButtons()
    self.menuButtonInfo = {
        self.backButtonInfo,
        self.nextPageButtonInfo,
        self.prevPageButtonInfo,
    }

    local subCategoryIndex = self.subCategoryPaging:getState()

    if subCategoryIndex == 1 then
        table.insert(self.menuButtonInfo, self.settingsButtonInfo)

        local vehicle = self:getSelectedVehicle()

        if vehicle ~= nil then
            local spec = vehicle.spec_machine

            if spec.enabled then
                self.toggleEnabledButtonInfo.text = InGameMenuTerraFarmFrame.L10N_SYMBOL.ACTION_DISABLE
            else
                self.toggleEnabledButtonInfo.text = InGameMenuTerraFarmFrame.L10N_SYMBOL.ACTION_ENABLE
            end

            if ModUtils.getPlayerHasPermission('manageRights') then
                table.insert(self.menuButtonInfo, self.toggleEnabledButtonInfo)
            end

            if ModUtils.getPlayerHasPermission('landscaping') then
                table.insert(self.menuButtonInfo, self.machineSettingsButtonInfo)
            end
        end
    elseif subCategoryIndex == 2 then
        if ModUtils.getPlayerHasPermission('landscaping') then
            table.insert(self.menuButtonInfo, self.createAreaButtonInfo)
            self.createAreaButtonInfo.text = Editor.L10N_SYMBOL.CREATE_AREA
        end

        local area = self:getSelectedArea()

        if area ~= nil then
            if area.visible then
                self.toggleActiveButtonInfo.text = Editor.L10N_SYMBOL.SET_HIDDEN
            else
                self.toggleActiveButtonInfo.text = Editor.L10N_SYMBOL.SET_VISIBLE
            end

            table.insert(self.menuButtonInfo, self.toggleActiveButtonInfo)

            if ModUtils.getPlayerHasPermission('landscaping') then
                table.insert(self.menuButtonInfo, self.deleteAreaButtonInfo)
                self.deleteAreaButtonInfo.text = Editor.L10N_SYMBOL.DELETE
                table.insert(self.menuButtonInfo, self.editAreaButtonInfo)
                self.editAreaButtonInfo.text = Editor.L10N_SYMBOL.EDIT
            end
        end
    elseif subCategoryIndex == 3 then
        if ModUtils.getPlayerHasPermission('landscaping') then
            table.insert(self.menuButtonInfo, self.createAreaButtonInfo)
            self.createAreaButtonInfo.text = Editor.L10N_SYMBOL.CREATE_WATERPLANE

            local waterplane = self:getSelectedWaterplane()

            if waterplane ~= nil then
                if waterplane.visible then
                    self.toggleActiveButtonInfo.text = Editor.L10N_SYMBOL.SET_HIDDEN
                else
                    self.toggleActiveButtonInfo.text = Editor.L10N_SYMBOL.SET_VISIBLE
                end

                table.insert(self.menuButtonInfo, self.toggleActiveButtonInfo)
                table.insert(self.menuButtonInfo, self.deleteAreaButtonInfo)
                self.deleteAreaButtonInfo.text = Editor.L10N_SYMBOL.DELETE
                table.insert(self.menuButtonInfo, self.editAreaButtonInfo)
                self.editAreaButtonInfo.text = Editor.L10N_SYMBOL.EDIT
            end
        end
    end

    self:setMenuButtonInfoDirty()
end

function InGameMenuTerraFarmFrame:updateVehicleDetails()
    local vehicle = self:getSelectedVehicle()

    if vehicle ~= nil then
        self.detailBox:setVisible(true)
        self.itemDetailsImage:setImageFilename(vehicle:getImageFilename())
        self.itemDetailsName:setText(vehicle:getFullName())
    else
        self.detailBox:setVisible(false)
    end
end

---@return Machine?
---@nodiscard
function InGameMenuTerraFarmFrame:getSelectedVehicle()
    if self.machinesList ~= nil then
        return self.vehicles[self.machinesList:getSelectedIndexInSection()]
    end
end

---@return LandscapingArea?
---@nodiscard
function InGameMenuTerraFarmFrame:getSelectedArea()
    if self.areasList ~= nil then
        return self.areas[self.areasList:getSelectedIndexInSection()]
    end
end

---@return LandscapingWaterplane?
---@nodiscard
function InGameMenuTerraFarmFrame:getSelectedWaterplane()
    if self.waterplanesList ~= nil then
        return self.waterplanes[self.waterplanesList:getSelectedIndexInSection()]
    end
end

---@param vehicle Machine
function InGameMenuTerraFarmFrame:onMachineAdd(vehicle)
    self:updateVehicles()
end

---@param vehicle Machine
function InGameMenuTerraFarmFrame:onMachineRemove(vehicle)
    if table.hasElement(self.vehicles, vehicle) then
        self:updateVehicles()
    end
end

function InGameMenuTerraFarmFrame:onClickGlobalSettings()
    g_globalSettingsDialog:show()
end

function InGameMenuTerraFarmFrame:onClickMachineSettings()
    local vehicle = self:getSelectedVehicle()

    if vehicle ~= nil then
        g_machineScreen:show(vehicle)
    end
end

function InGameMenuTerraFarmFrame:onClickToggleEnabled()
    local vehicle = self:getSelectedVehicle()

    if vehicle ~= nil then
        vehicle:setMachineEnabled(not vehicle:getMachineEnabled())
        self:updateVehicles()
    end
end

function InGameMenuTerraFarmFrame:onClickEditArea()
    local subCategoryIndex = self.subCategoryPaging:getState()

    if subCategoryIndex == 2 then
        local area = self:getSelectedArea()

        if area ~= nil then
            LandscapingUtils.openAreaInEditor(area, true)
        end
    elseif subCategoryIndex == 3 then
        local waterplane = self:getSelectedWaterplane()

        if waterplane ~= nil then
            g_waterplaneEditor:show(waterplane:clone(), true)
        end
    end
end

function InGameMenuTerraFarmFrame:onClickCreateArea()
    local subCategoryIndex = self.subCategoryPaging:getState()

    if subCategoryIndex == 2 then
        if g_landscapingManager:getCanCreateArea() then
            LandscapingUtils.createAreaInEditor(true)
        else
            InfoDialog.show(g_i18n:getText('ui_areasLimitWarning'), nil, nil, DialogElement.TYPE_WARNING)
        end
    elseif subCategoryIndex == 3 then
        if g_landscapingManager:getCanCreateWaterplane() then
            local waterplane = LandscapingWaterplane.new()
            g_waterplaneEditor:show(waterplane, true)
        else
            InfoDialog.show(g_i18n:getText('ui_waterplanesLimitWarning'), nil, nil, DialogElement.TYPE_WARNING)
        end
    end
end

function InGameMenuTerraFarmFrame:onClickDeleteArea()
    local subCategoryIndex = self.subCategoryPaging:getState()

    if subCategoryIndex == 2 then
        local area = self:getSelectedArea()

        if area ~= nil then
            ---@param yes boolean
            local callbackFn = function (yes)
                if yes then
                    g_landscapingManager:deleteAreaByUniqueId(area.uniqueId)
                end
            end
            local title = string.format('%s "%s"', g_i18n:getText('ui_area'), area:getName())
            YesNoDialog.show(callbackFn, nil,
                g_i18n:getText('ui_areaConfirmDeleteText'), title,
                g_i18n:getText("button_ok"),
                g_i18n:getText("button_cancel")
            )
        end
    elseif subCategoryIndex == 3 then
        local waterplane = self:getSelectedWaterplane()

        if waterplane ~= nil then
            ---@param yes boolean
            local callbackFn = function (yes)
                if yes then
                    g_landscapingManager:deleteWaterplaneByUniqueId(waterplane.uniqueId)
                end
            end
            local title = string.format('%s "%s"', g_i18n:getText('ui_waterPlane'), waterplane:getName())
            YesNoDialog.show(callbackFn, nil,
                g_i18n:getText('ui_waterplaneConfirmDeleteText'), title,
                g_i18n:getText("button_ok"),
                g_i18n:getText("button_cancel")
            )
        end
    end
end

function InGameMenuTerraFarmFrame:onClickToggleActive()
    local subCategoryIndex = self.subCategoryPaging:getState()

    if subCategoryIndex == 2 then
        local area = self:getSelectedArea()

        if area ~= nil then
            area:setIsVisible(not area.visible)
            self:updateAreas()
        end
    elseif subCategoryIndex == 3 then
        local waterplane = self:getSelectedWaterplane()

        if waterplane ~= nil then
            g_landscapingManager:setWaterplaneVisible(waterplane.uniqueId, not waterplane.visible)
            self:updateWaterplanes()
        end
    end
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function InGameMenuTerraFarmFrame:onItemDoubleClick(list, section, index, cell)
    if list == self.machinesList then
        self:onClickMachineSettings()
    elseif list == self.areasList then
        self:onClickEditArea()
    elseif list == self.waterplanesList then
        self:onClickEditArea()
    end
end

---@param user User
function InGameMenuTerraFarmFrame:onMasterUserAdded(user)
    if user:getId() == g_currentMission.playerUserId then
        self:updateVehicles()
    end
end

---@param player Player?
function InGameMenuTerraFarmFrame:onPlayerFarmChanged(player)
    if player ~= nil and player.userId == g_currentMission.playerUserId then
        self:updateVehicles()
    end
end

---@param userId number
function InGameMenuTerraFarmFrame:onPlayerPermissionsChanged(userId)
    if userId == g_currentMission.playerUserId then
        self:updateMenuButtons()
    end
end

function InGameMenuTerraFarmFrame:onClickMachines()
    self.subCategoryPaging:setState(1, true)
end

function InGameMenuTerraFarmFrame:onClickLandscapingAreas()
    self.subCategoryPaging:setState(2, true)
end

function InGameMenuTerraFarmFrame:onClickWaterplanes()
    self.subCategoryPaging:setState(3, true)
end

---@param subCategoryIndex? number
function InGameMenuTerraFarmFrame:updateSubCategoryPages(subCategoryIndex)
    for index, page in pairs(self.subCategoryPages) do
        page:setVisible(index == subCategoryIndex)
    end

    if subCategoryIndex == 1 then
        self.listSlider:setDataElement(self.machinesList)
    elseif subCategoryIndex == 2 then
        self.listSlider:setDataElement(self.areasList)
    elseif subCategoryIndex == 3 then
        self.listSlider:setDataElement(self.waterplanesList)
    end

    FocusManager:setFocus(self.subCategoryPaging)
    self:updateMenuButtons()
end
