source(g_modDirectory .. 'scripts/gui/dialogs/SelectAreaDialog.lua')
source(g_modDirectory .. 'scripts/gui/dialogs/SelectAreaTypeDialog.lua')
source(g_modDirectory .. 'scripts/gui/dialogs/SelectMachineDialog.lua')
source(g_modDirectory .. 'scripts/gui/dialogs/SelectMaterialDialog.lua')
source(g_modDirectory .. 'scripts/gui/dialogs/SelectTerrainLayerDialog.lua')
source(g_modDirectory .. 'scripts/gui/dialogs/SetPositionDialog.lua')

source(g_modDirectory .. 'scripts/gui/dialogs/GlobalMaterialsDialog.lua')
source(g_modDirectory .. 'scripts/gui/dialogs/GlobalSettingsDialog.lua')

source(g_modDirectory .. 'scripts/gui/elements/TFIconOptionElement.lua')

source(g_modDirectory .. 'scripts/gui/InGameMenuTerraFarmFrame.lua')

source(g_modDirectory .. 'scripts/gui/MachineScreen.lua')
source(g_modDirectory .. 'scripts/gui/MachineSettingsAreaFrame.lua')
source(g_modDirectory .. 'scripts/gui/MachineSettingsLandscapingFrame.lua')
source(g_modDirectory .. 'scripts/gui/MachineSettingsInputFrame.lua')
source(g_modDirectory .. 'scripts/gui/MachineSettingsOutputFrame.lua')
source(g_modDirectory .. 'scripts/gui/MachineSettingsFrame.lua')

---@class ModGui
ModGui = {}

ModGui.PROFILES_FILENAME = g_modDirectory .. 'data/gui/guiProfiles.xml'
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

    g_modController:subscribe(ModEvent.onMapLoaded, self.onMapLoaded, self)

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

    if g_selectAreaTypeDialog.isOpen then
        g_selectAreaTypeDialog:close()
    end

    if g_selectAreaDialog.isOpen then
        g_selectAreaDialog:close()
    end

    if g_setPositionDialog.isOpen then
        g_setPositionDialog:close()
    end

    g_gui:showGui(nil)

    g_machineScreen:delete()
    g_editorAreaPolygon:delete()
    g_editorAreaPath:delete()
    g_editorWaterplane:delete()

    g_selectMaterialDialog:delete()
    g_selectTerrainLayerDialog:delete()
    g_selectMachineDialog:delete()
    g_globalMaterialsDialog:delete()
    g_globalSettingsDialog:delete()
    g_selectAreaTypeDialog:delete()
    g_selectAreaDialog:delete()
    g_setPositionDialog:delete()
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
    g_globalSettingsDialog = GlobalSettingsDialog.new()
    g_globalSettingsDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_globalMaterialsDialog = GlobalMaterialsDialog.new()
    g_globalMaterialsDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_selectAreaTypeDialog = SelectAreaTypeDialog.new()
    g_selectAreaTypeDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_selectAreaDialog = SelectAreaDialog.new()
    g_selectAreaDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_setPositionDialog = SetPositionDialog.new()
    g_setPositionDialog:load()
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

    g_gui:loadGui(class.XML_FILENAME, class.MENU_PAGE_NAME, pageController, true)

    g_inGameMenu[pageName] = pageController
    g_inGameMenu.pagingElement:addElement(pageController)
    g_inGameMenu.pagingElement:updateAbsolutePosition()
    g_inGameMenu.pagingElement:updatePageMapping()

    g_inGameMenu:registerPage(pageController, nil, predicateFunction)
    g_inGameMenu:addPageTab(pageController, nil, nil, class.MENU_ICON_SLICE_ID)
    self[pageName] = pageController

    pageController:updateAbsolutePosition()
    g_inGameMenu:rebuildTabList()

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
    g_machineScreen = MachineScreen.new()
    g_machineScreen:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_editorAreaPolygon = EditorAreaPolygon.new()
    g_editorAreaPolygon:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_editorAreaPath = EditorAreaPath.new()
    g_editorAreaPath:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_editorWaterplane = EditorWaterplane.new()
    g_editorWaterplane:load()
end

function ModGui:reload()
    -- local currentGuiName = g_gui.currentGuiName

    local machineScreenIsOpen = g_machineScreen.isOpen
    local globalSettingsDialogIsOpen = g_globalSettingsDialog.isOpen
    local globalMaterialsDialogIsOpen = g_globalMaterialsDialog.isOpen
    local selectTypeDialogIsOpen = g_selectAreaTypeDialog.isOpen

    local selectedVehicle

    if machineScreenIsOpen then
        selectedVehicle = g_machineScreen.vehicle
    end

    self:delete()
    self:load()

    g_modHud:reload()

    if machineScreenIsOpen and selectedVehicle ~= nil then
        g_machineScreen:show(selectedVehicle)
    end

    if globalSettingsDialogIsOpen then
        g_globalSettingsDialog:show()
    end

    if globalMaterialsDialogIsOpen then
        g_globalMaterialsDialog:show()
    end

    if selectTypeDialogIsOpen then
        g_selectAreaTypeDialog:show()
    end
end

function ModGui:onMapLoaded()
    if g_client ~= nil then
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
