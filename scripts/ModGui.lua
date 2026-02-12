source(g_modDirectory .. 'scripts/gui/dialogs/input/FloatInputDialog.lua')
source(g_modDirectory .. 'scripts/gui/dialogs/input/NameInputDialog.lua')

source(g_modDirectory .. 'scripts/gui/dialogs/SelectSurveyorDialog.lua')
source(g_modDirectory .. 'scripts/gui/dialogs/SelectMachineDialog.lua')
source(g_modDirectory .. 'scripts/gui/dialogs/SelectMaterialDialog.lua')
source(g_modDirectory .. 'scripts/gui/dialogs/SelectTerrainLayerDialog.lua')

source(g_modDirectory .. 'scripts/gui/dialogs/GlobalMaterialsDialog.lua')
source(g_modDirectory .. 'scripts/gui/dialogs/GlobalSettingsDialog.lua')

source(g_modDirectory .. 'scripts/gui/frames/MachineSettingsCalibrationFrame.lua')
source(g_modDirectory .. 'scripts/gui/frames/MachineSettingsLandscapingFrame.lua')
source(g_modDirectory .. 'scripts/gui/frames/MachineSettingsInputFrame.lua')
source(g_modDirectory .. 'scripts/gui/frames/MachineSettingsOutputFrame.lua')
source(g_modDirectory .. 'scripts/gui/frames/MachineSettingsFrame.lua')
source(g_modDirectory .. 'scripts/gui/screens/MachineScreen.lua')

source(g_modDirectory .. 'scripts/gui/screens/SurveyorCamera.lua')
source(g_modDirectory .. 'scripts/gui/screens/SurveyorCursor.lua')
source(g_modDirectory .. 'scripts/gui/screens/SurveyorScreen.lua')

source(g_modDirectory .. 'scripts/gui/elements/TFBinaryOptionElement.lua')
source(g_modDirectory .. 'scripts/gui/elements/TFButtonElement.lua')
source(g_modDirectory .. 'scripts/gui/elements/TFTextInputElement.lua')
source(g_modDirectory .. 'scripts/gui/elements/TFThreePartBitmapElement.lua')

source(g_modDirectory .. 'scripts/gui/frames/InGameMenuTerraFarmFrame.lua')

---@class ModGui
ModGui = {}

ModGui.PROFILES_FILENAME = g_modDirectory .. 'xml/gui/guiProfiles.xml'
ModGui.TEXTURE_CONFIG_FILENAME = g_modDirectory .. 'textures/ui_elements.xml'

local ModGui_mt = Class(ModGui)

---@return ModGui
---@nodiscard
function ModGui.new()
    ---@type ModGui
    local self = setmetatable({}, ModGui_mt)

    if g_client ~= nil then
        addConsoleCommand('tfReloadGui', '', 'consoleReloadGui', self)
        addConsoleCommand('tfGuiReloadMenuFrame', '', 'consoleReloadFrames', self)
    end

    return self
end

function ModGui:delete()
    if g_globalMaterialsDialog.isOpen then
        g_globalMaterialsDialog:close()
    end

    if g_globalSettingsDialog.isOpen then
        g_globalSettingsDialog:close()
    end

    if g_machineScreen.isOpen then
        g_machineScreen:exitMenu()
    end

    if g_selectMaterialDialog.isOpen then
        g_selectMaterialDialog:close()
    end

    if g_selectTerrainLayerDialog.isOpen then
        g_selectTerrainLayerDialog:close()
    end

    if g_selectMachineDialog.isOpen then
        g_selectMachineDialog:close()
    end

    if g_selectSurveyorDialog.isOpen then
        g_selectSurveyorDialog:close()
    end

    if g_nameInputDialog.isOpen then
        g_nameInputDialog:close()
    end

    if g_floatInputDialog.isOpen then
        g_floatInputDialog:close()
    end

    g_gui:showGui(nil)

    g_surveyorScreen:delete()
    g_machineScreen:delete()

    g_selectMaterialDialog:delete()
    g_selectTerrainLayerDialog:delete()
    g_selectMachineDialog:delete()
    g_selectSurveyorDialog:delete()
    g_globalMaterialsDialog:delete()
    g_globalSettingsDialog:delete()

    g_nameInputDialog:delete()
    g_floatInputDialog:delete()
end

function ModGui:load()
    g_gui.currentlyReloading = true

    g_overlayManager.textureConfigs['terraFarm'] = nil
    g_overlayManager:addTextureConfigFile(ModGui.TEXTURE_CONFIG_FILENAME, 'terraFarm')

    self:loadProfiles()
    self:loadDialogs()
    self:loadScreens()

    g_gui.currentlyReloading = false
end

function ModGui:loadProfiles()
    g_gui:loadProfiles(ModGui.PROFILES_FILENAME)
end

function ModGui:loadDialogs()
    ---@diagnostic disable-next-line: lowercase-global
    g_selectMaterialDialog = SelectMaterialDialog.new()
    g_selectMaterialDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_selectTerrainLayerDialog = SelectTerrainLayerDialog.new()
    g_selectTerrainLayerDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_selectMachineDialog = SelectMachineDialog.new()
    g_selectMachineDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_selectSurveyorDialog = SelectSurveyorDialog.new()
    g_selectSurveyorDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_nameInputDialog = NameInputDialog.new()
    g_nameInputDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_floatInputDialog = FloatInputDialog.new()
    g_floatInputDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_globalSettingsDialog = GlobalSettingsDialog.new()
    g_globalSettingsDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_globalMaterialsDialog = GlobalMaterialsDialog.new()
    g_globalMaterialsDialog:load()
end

function ModGui:loadFrames()
    if not self:loadMenuFrame(InGameMenuTerraFarmFrame) then
        Logging.warning('MachineGUI:loadFrames() InGameMenuTerraFarmFrame already loaded')
    end
end

function ModGui:loadMenuFrame(class)
    ---@type InGameMenuTerraFarmFrame
    local pageController = class.new()
    local pageName = class.MENU_PAGE_NAME
    local predicateFunction = function ()
        return true
    end

    if self[pageName] ~= nil then
        return false
    end

    g_gui:loadGui(class.XML_FILENAME, class.CLASS_NAME, pageController, true)

    g_inGameMenu[pageName] = pageController
    g_inGameMenu.pagingElement:addElement(pageController)
    g_inGameMenu:registerPage(pageController, nil, predicateFunction)
    g_inGameMenu:addPageTab(pageController, nil, nil, class.MENU_ICON_SLICE_ID)

    self[pageName] = pageController

    pageController:updateAbsolutePosition()

    g_inGameMenu.pagingTabList:reloadData()

    return true
end

function ModGui:deleteMenuFrame(class)
    local pageName = class.MENU_PAGE_NAME

    if self[pageName] == nil then
        return false
    end

    ---@type InGameMenuTerraFarmFrame
    local pageController = self[pageName]

    g_inGameMenu:setPageEnabled(class, false)

    local _, _, pageRoot, _ = g_inGameMenu:unregisterPage(class)

    g_inGameMenu.pagingElement:removeElement(pageRoot)

    ---@diagnostic disable-next-line: need-check-nil
    pageRoot:delete()
    pageController:delete()

    FocusManager:deleteGuiFocusData(class.CLASS_NAME)

    g_inGameMenu[pageName] = nil

    self[pageName] = nil

    return true
end

function ModGui:deleteFrames()
    if not self:deleteMenuFrame(InGameMenuTerraFarmFrame) then
        return false
    end

    g_inGameMenu:rebuildTabList()
    g_inGameMenu.pagingElement:updatePageMapping()

    return true
end

function ModGui:loadScreens()
    ---@diagnostic disable-next-line: lowercase-global
    g_surveyorScreen = SurveyorScreen.new()
    g_surveyorScreen:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_machineScreen = MachineScreen.new()
    g_machineScreen:load()
end

function ModGui:reload()
    -- local currentGuiName = g_gui.currentGuiName

    local machineScreenIsOpen = g_machineScreen.isOpen
    local globalSettingsDialogIsOpen = g_globalSettingsDialog.isOpen
    local globalMaterialsDialogIsOpen = g_globalMaterialsDialog.isOpen

    local selectedVehicle

    if machineScreenIsOpen then
        selectedVehicle = g_machineScreen.vehicle
    end

    self:delete()
    self:load()

    g_modHud:reload()

    -- if currentGuiName ~= SurveyorScreen.CLASS_NAME then
    --     g_gui:showGui(currentGuiName)
    -- end

    if machineScreenIsOpen and selectedVehicle ~= nil then
        g_machineScreen:show(selectedVehicle)
    end

    if globalSettingsDialogIsOpen then
        g_globalSettingsDialog:show()
    end

    if globalMaterialsDialogIsOpen then
        g_globalMaterialsDialog:show()
    end
end

function ModGui:onMapLoaded()
    if g_client ~= nil then
        -- Make sure we apply a fix for InGameMenu
        -- (it's especially a problem in multiplayer)
        -- SmoothListElement.ALIGN_MIDDLE is of course causing issues
        -- in this specific case when you have "too many" tab items.
        g_inGameMenu.pagingTabList.listItemAlignment = SmoothListElement.ALIGN_START

        self:loadFrames()
    end
end

function ModGui:consoleReloadGui()
    if g_server ~= nil and not g_currentMission.missionDynamicInfo.isMultiplayer then
        self:reload()

        return 'Reloaded GUI'
    end

    return 'Only available in single player'
end

function ModGui:consoleReloadFrames()
    if g_server ~= nil and not g_currentMission.missionDynamicInfo.isMultiplayer then
        g_gui:showGui("InGameMenu")

        local currentIndex = g_inGameMenu.currentPageListIndex

        self:deleteMenuFrame(InGameMenuTerraFarmFrame)

        g_gui.currentlyReloading = true
        self:loadMenuFrame(InGameMenuTerraFarmFrame)
        g_gui.currentlyReloading = false

        g_inGameMenu:rebuildTabList()
        g_inGameMenu.pagingElement:setPage(currentIndex)

        return 'Reloaded InGameMenuTerraFarmFrame'
    end

    return 'Only available in single player'
end

---@diagnostic disable-next-line: lowercase-global
g_modGui = ModGui.new()
