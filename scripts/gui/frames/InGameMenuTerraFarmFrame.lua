---@class InGameMenuTerraFarmFrame : TabbedMenuFrameElement
---@field isOpen boolean
---@field lastUpdate number
---@field backButtonInfo table
---@field frameSliderBox ThreePartBitmapElement
---@field frameSlider SliderElement
---@field vehicles Machine[]
---@field list SmoothListElement
---@field detailBox GuiElement
---@field itemDetailsImage BitmapElement
---@field itemDetailsName TextElement
---@field superClass fun(): TabbedMenuFrameElement
InGameMenuTerraFarmFrame = {}

InGameMenuTerraFarmFrame.CLASS_NAME = 'InGameMenuTerraFarmFrame'
InGameMenuTerraFarmFrame.MENU_PAGE_NAME = 'ingameMenuTerraFarm'
InGameMenuTerraFarmFrame.MENU_ICON_FILENAME = g_modUIFilename
InGameMenuTerraFarmFrame.MENU_ICON_SLICE_ID = 'terraFarm.icon_excavator'
InGameMenuTerraFarmFrame.XML_FILENAME = g_currentModDirectory .. 'xml/gui/frames/InGameMenuTerraFarmFrame.xml'
InGameMenuTerraFarmFrame.UPDATE_INTERVAL = 4000

InGameMenuTerraFarmFrame.L10N_ENABLED = g_i18n:getText('ui_enabled')
InGameMenuTerraFarmFrame.L10N_DISABLED = g_i18n:getText('ui_disabled')

InGameMenuTerraFarmFrame.L10N_ACTION_ENABLE = g_i18n:getText('ui_enable')
InGameMenuTerraFarmFrame.L10N_ACTION_DISABLE = g_i18n:getText('ui_disable')
InGameMenuTerraFarmFrame.L10N_ACTION_SETTINGS = g_i18n:getText('ui_globalSettings')
InGameMenuTerraFarmFrame.L10N_ACTION_MACHINE_SETTINGS = g_i18n:getText('ui_machineSettings')

local InGameMenuTerraFarmFrame_mt = Class(InGameMenuTerraFarmFrame, TabbedMenuFrameElement)

---@return InGameMenuTerraFarmFrame
function InGameMenuTerraFarmFrame.new()
    local self = TabbedMenuFrameElement.new(nil, InGameMenuTerraFarmFrame_mt)
    ---@cast self InGameMenuTerraFarmFrame

    self.isOpen = false
    self.lastUpdate = 0
    self.vehicles = {}

    self.hasCustomMenuButtons = true

    return self
end

function InGameMenuTerraFarmFrame:delete()
    self:superClass().delete(self)

    g_messageCenter:unsubscribeAll(self)

    FocusManager.guiFocusData[InGameMenuTerraFarmFrame.CLASS_NAME] = {
        idToElementMapping = {}
    }
end

function InGameMenuTerraFarmFrame:initialize()
    self.nextPageButtonInfo = {
        ["inputAction"] = InputAction.MENU_PAGE_NEXT,
        ["text"] = g_i18n:getText("ui_ingameMenuNext"),
        ---@diagnostic disable-next-line: undefined-field
        ["callback"] = self.onPageNext
    }

    self.prevPageButtonInfo = {
        ["inputAction"] = InputAction.MENU_PAGE_PREV,
        ["text"] = g_i18n:getText("ui_ingameMenuPrev"),
        ---@diagnostic disable-next-line: undefined-field
        ["callback"] = self.onPagePrevious
    }

    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }

    self.settingsButtonInfo = {
        inputAction = InputAction.MENU_EXTRA_2,
        text = InGameMenuTerraFarmFrame.L10N_ACTION_SETTINGS,
        callback = function ()
            self:onClickGlobalSettings()
        end
    }

    self.machineSettingsButtonInfo = {
        inputAction = InputAction.MENU_ACTIVATE,
        text = InGameMenuTerraFarmFrame.L10N_ACTION_MACHINE_SETTINGS,
        callback = function ()
            self:onClickMachineSettings()
        end
    }

    self.toggleEnabledButtonInfo = {
        inputAction = InputAction.MENU_EXTRA_1,
        text = InGameMenuTerraFarmFrame.L10N_ACTION_ENABLE,
        callback = function ()
            self:onClickToggleEnabled()
        end
    }

    self.list:setDataSource(self)
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

    FocusManager:setFocus(self.list)

    self.detailBox:setVisible(#self.vehicles > 0)

    g_messageCenter:subscribe(MessageType.MACHINE_ADDED, self.onMachineAdded, self)
    g_messageCenter:subscribe(MessageType.MACHINE_REMOVED, self.onMachineRemoved, self)
    g_messageCenter:subscribe(MessageType.MASTERUSER_ADDED, self.onMasterUserAdded, self)
    g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.onPlayerFarmChanged, self)
    g_messageCenter:subscribe(PlayerPermissionsEvent, self.onPlayerPermissionsChanged, self)

    g_machineManager:checkDisplayWarning()
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
            self:updateVehicles()
        end
    end
end

function InGameMenuTerraFarmFrame:updateVehicles()
    self.vehicles = g_machineManager:getAccessibleVehicles()

    table.sort(self.vehicles, function (a, b)
        return a:getName() < b:getName()
    end)

    self.list:reloadData()

    self:updateVehicleDetails()
    self:updateMenuButtons()

    self.lastUpdate = 0
end

---@param list SmoothListElement
---@param section number
---@return number
function InGameMenuTerraFarmFrame:getNumberOfItemsInSection(list, section)
    return #self.vehicles
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell table
function InGameMenuTerraFarmFrame:populateCellForItemInSection(list, section, index, cell)
    local vehicle = self.vehicles[index]

    if vehicle ~= nil then
        local spec = vehicle.spec_machine

        cell:getAttribute('name'):setText(vehicle:getFullName())
        -- cell:getAttribute('licensePlate'):setText(LicensePlates.getSpecValuePlateText(nil, vehicle) or "-")
        cell:getAttribute('age'):setText(Vehicle.getSpecValueAge(nil, vehicle))
        cell:getAttribute('operatingHours'):setText(Vehicle.getSpecValueOperatingTime(nil, vehicle))
        cell:getAttribute('status'):setText(spec.enabled and InGameMenuTerraFarmFrame.L10N_ENABLED or InGameMenuTerraFarmFrame.L10N_DISABLED)
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
    else
        Logging.error("Unable to find machine entry index: %d", index)
    end
end

---@param list SmoothListElement
---@param section number
---@param index number
function InGameMenuTerraFarmFrame:onListSelectionChanged(list, section, index)
    self:updateVehicleDetails()
    self:updateMenuButtons()
end

function InGameMenuTerraFarmFrame:updateMenuButtons()
    self.menuButtonInfo = {
        self.backButtonInfo,
        self.nextPageButtonInfo,
        self.prevPageButtonInfo,
        self.settingsButtonInfo,
    }
    local vehicle = self:getSelectedVehicle()

    if vehicle ~= nil then
        local spec = vehicle.spec_machine

        if spec.enabled then
            self.toggleEnabledButtonInfo.text = InGameMenuTerraFarmFrame.L10N_ACTION_DISABLE
        else
            self.toggleEnabledButtonInfo.text = InGameMenuTerraFarmFrame.L10N_ACTION_ENABLE
        end

        if MachineUtils.getPlayerHasPermission('manageRights') then
            table.insert(self.menuButtonInfo, self.toggleEnabledButtonInfo)
        end

        if MachineUtils.getPlayerHasPermission('landscaping') then
            table.insert(self.menuButtonInfo, self.machineSettingsButtonInfo)
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

---@return Machine | nil
---@nodiscard
function InGameMenuTerraFarmFrame:getSelectedVehicle()
    if self.list ~= nil then
        return self.vehicles[self.list:getSelectedIndexInSection()]
    end
end

---@param vehicle Machine
function InGameMenuTerraFarmFrame:onMachineAdded(vehicle)
    self:updateVehicles()
end

---@param vehicle Machine
function InGameMenuTerraFarmFrame:onMachineRemoved(vehicle)
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

function InGameMenuTerraFarmFrame:onItemDoubleClick()
    self:onClickMachineSettings()
end

---@param user User
function InGameMenuTerraFarmFrame:onMasterUserAdded(user)
    if user:getId() == g_currentMission.playerUserId then
        self:updateVehicles()
    end
end

---@param player Player | nil
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
