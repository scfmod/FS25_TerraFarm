---@diagnostic disable: lowercase-global

if g_gameVersion < 8 then
    Logging.error('TerraFarm requires FS25 patch 1.7.0.0 or newer.')
    return
end

g_modName = g_currentModName
g_modDirectory = g_currentModDirectory
g_modDirectorySettings = g_currentModSettingsDirectory
g_previewMaskFilename = g_modDirectory .. 'data/textures/preview_mask.png'
g_overlayManager:addTextureConfigFile(g_modDirectory .. 'data/textures/ui_elements.xml', 'terraFarm', nil)

---@class ModMessageType
ModMessageType = {}
ModMessageType.MACHINE_ADDED = nextMessageTypeId()
ModMessageType.MACHINE_REMOVED = nextMessageTypeId()
ModMessageType.ACTIVE_MACHINE_CHANGED = nextMessageTypeId()
ModMessageType.ACTIVE_AREA_CHANGED = nextMessageTypeId()
ModMessageType.LANDSCAPING_AREA_REGISTERED = nextMessageTypeId()
ModMessageType.LANDSCAPING_AREA_UPDATED = nextMessageTypeId()
ModMessageType.LANDSCAPING_AREA_DELETED = nextMessageTypeId()
ModMessageType.WATERPLANE_REGISTERED = nextMessageTypeId()
ModMessageType.WATERPLANE_UPDATED = nextMessageTypeId()
ModMessageType.WATERPLANE_DELETED = nextMessageTypeId()

source(g_modDirectory .. 'scripts/ModController.lua')

source(g_modDirectory .. 'scripts/ModUtils.lua')
source(g_modDirectory .. 'scripts/ModGui.lua')
source(g_modDirectory .. 'scripts/ModHud.lua')
source(g_modDirectory .. 'scripts/ModSettings.lua')

source(g_modDirectory .. 'scripts/MachineManager.lua')
source(g_modDirectory .. 'scripts/MachineTypes.lua')

source(g_modDirectory .. 'scripts/ResourceManager.lua')

source(g_modDirectory .. 'scripts/landscaping/LandscapingUtils.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingManager.lua')

source(g_modDirectory .. 'scripts/extensions/GuiOverlayExtension.lua')
source(g_modDirectory .. 'scripts/extensions/InGameMenuExtension.lua')
source(g_modDirectory .. 'scripts/extensions/InputBindingExtension.lua')
source(g_modDirectory .. 'scripts/extensions/InteractiveControlExtension.lua')
source(g_modDirectory .. 'scripts/extensions/SavegameControllerExtension.lua')
source(g_modDirectory .. 'scripts/extensions/ShopControllerExtension.lua')
source(g_modDirectory .. 'scripts/extensions/VehicleExtension.lua')

if g_client ~= nil then
    g_modSettings:loadUserSettings()
    g_modGui:load()
    g_modHud:load()
end
