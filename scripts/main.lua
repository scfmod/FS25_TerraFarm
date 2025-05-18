---@diagnostic disable-next-line: undefined-global
if g_gameVersion < 8 then
    Logging.error('TerraFarm requires FS25 patch 1.7.0.0 or newer.')
    return
end

MessageType.MACHINE_ADDED = nextMessageTypeId()
MessageType.MACHINE_REMOVED = nextMessageTypeId()
MessageType.ACTIVE_MACHINE_CHANGED = nextMessageTypeId()
MessageType.SURVEYOR_ADDED = nextMessageTypeId()
MessageType.SURVEYOR_REMOVED = nextMessageTypeId()

---@diagnostic disable-next-line: lowercase-global
g_modUIFilename = g_currentModDirectory .. 'textures/ui_elements.png'
---@diagnostic disable-next-line: lowercase-global
g_previewMaskFilename = g_currentModDirectory .. 'textures/preview_mask.png'

g_overlayManager:addTextureConfigFile(g_currentModDirectory .. 'textures/ui_elements.xml', 'terraFarm', nil)

source(g_currentModDirectory .. 'scripts/ModDebug.lua')
source(g_currentModDirectory .. 'scripts/ModGui.lua')
source(g_currentModDirectory .. 'scripts/ModHud.lua')
source(g_currentModDirectory .. 'scripts/ModSettings.lua')

source(g_currentModDirectory .. 'scripts/managers/MachineManager.lua')
source(g_currentModDirectory .. 'scripts/managers/ResourceManager.lua')

source(g_currentModDirectory .. 'scripts/MachineLandscaping.lua')
source(g_currentModDirectory .. 'scripts/MachineState.lua')
source(g_currentModDirectory .. 'scripts/MachineTypes.lua')
source(g_currentModDirectory .. 'scripts/MachineUtils.lua')
source(g_currentModDirectory .. 'scripts/MachineWorkArea.lua')

source(g_currentModDirectory .. 'scripts/events/SetDefaultEnabledEvent.lua')
source(g_currentModDirectory .. 'scripts/events/SetEnabledEvent.lua')
source(g_currentModDirectory .. 'scripts/events/SetMaterialsEvent.lua')
source(g_currentModDirectory .. 'scripts/events/SetResourcesEvent.lua')

source(g_currentModDirectory .. 'scripts/extensions/GuiOverlayExtension.lua')
source(g_currentModDirectory .. 'scripts/extensions/InteractiveControlExtension.lua')
source(g_currentModDirectory .. 'scripts/extensions/SavegameControllerExtension.lua')
source(g_currentModDirectory .. 'scripts/extensions/ShopControllerExtension.lua')
source(g_currentModDirectory .. 'scripts/extensions/VehicleExtension.lua')

source(g_currentModDirectory .. 'scripts/landscaping/LandscapingFlatten.lua')
source(g_currentModDirectory .. 'scripts/landscaping/LandscapingFlattenDischarge.lua')
source(g_currentModDirectory .. 'scripts/landscaping/LandscapingLower.lua')
source(g_currentModDirectory .. 'scripts/landscaping/LandscapingPaint.lua')
source(g_currentModDirectory .. 'scripts/landscaping/LandscapingPaintDischarge.lua')
source(g_currentModDirectory .. 'scripts/landscaping/LandscapingRaise.lua')
source(g_currentModDirectory .. 'scripts/landscaping/LandscapingSmooth.lua')
source(g_currentModDirectory .. 'scripts/landscaping/LandscapingSmoothDischarge.lua')

source(g_currentModDirectory .. 'scripts/visualization/CalibrationDisplay.lua')
source(g_currentModDirectory .. 'scripts/visualization/Shape.lua')
source(g_currentModDirectory .. 'scripts/visualization/ShapeLine.lua')

if g_client ~= nil then
    g_modSettings:loadUserSettings()
    g_modGui:load()
    g_modHud:load()
end

source(g_currentModDirectory .. 'scripts/ModController.lua')
