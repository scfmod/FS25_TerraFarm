if g_gameVersion < 8 then
    Logging.error('TerraFarm requires FS25 patch 1.7.0.0 or newer.')
    return
end

g_modName = g_currentModName
g_modDirectory = g_currentModDirectory
g_modDirectorySettings = g_currentModSettingsDirectory
g_previewMaskFilename = g_modDirectory .. 'textures/preview_mask.png'
g_overlayManager:addTextureConfigFile(g_modDirectory .. 'textures/ui_elements.xml', 'terraFarm', nil)

MessageType.MACHINE_ADDED = nextMessageTypeId()
MessageType.MACHINE_REMOVED = nextMessageTypeId()
MessageType.ACTIVE_MACHINE_CHANGED = nextMessageTypeId()
MessageType.SURVEYOR_ADDED = nextMessageTypeId()
MessageType.SURVEYOR_REMOVED = nextMessageTypeId()

source(g_modDirectory .. 'scripts/ModDebug.lua')
source(g_modDirectory .. 'scripts/ModGui.lua')
source(g_modDirectory .. 'scripts/ModHud.lua')
source(g_modDirectory .. 'scripts/ModI3DManager.lua')
source(g_modDirectory .. 'scripts/ModSettings.lua')

source(g_modDirectory .. 'scripts/managers/MachineManager.lua')
source(g_modDirectory .. 'scripts/managers/ResourceManager.lua')

source(g_modDirectory .. 'scripts/MachineLandscaping.lua')
source(g_modDirectory .. 'scripts/MachineState.lua')
source(g_modDirectory .. 'scripts/MachineTypes.lua')
source(g_modDirectory .. 'scripts/MachineUtils.lua')
source(g_modDirectory .. 'scripts/MachineWorkArea.lua')

source(g_modDirectory .. 'scripts/events/SetDefaultEnabledEvent.lua')
source(g_modDirectory .. 'scripts/events/SetEnabledEvent.lua')
source(g_modDirectory .. 'scripts/events/SetMaterialsEvent.lua')
source(g_modDirectory .. 'scripts/events/SetResourcesEvent.lua')

source(g_modDirectory .. 'scripts/extensions/GuiOverlayExtension.lua')
source(g_modDirectory .. 'scripts/extensions/InteractiveControlExtension.lua')
source(g_modDirectory .. 'scripts/extensions/SavegameControllerExtension.lua')
source(g_modDirectory .. 'scripts/extensions/ShopControllerExtension.lua')
source(g_modDirectory .. 'scripts/extensions/VehicleExtension.lua')

source(g_modDirectory .. 'scripts/landscaping/LandscapingFlatten.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingFlattenDischarge.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingLower.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingPaint.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingPaintDischarge.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingRaise.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingSlope.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingSlopeDischarge.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingSmooth.lua')
source(g_modDirectory .. 'scripts/landscaping/LandscapingSmoothDischarge.lua')

source(g_modDirectory .. 'scripts/misc/CameraTransition.lua')

source(g_modDirectory .. 'scripts/visualization/CalibrationDisplay.lua')
source(g_modDirectory .. 'scripts/visualization/Shape.lua')
source(g_modDirectory .. 'scripts/visualization/ShapeLine.lua')

if g_client ~= nil then
    g_modSettings:loadUserSettings()
    g_modGui:load()
    g_modHud:load()
end

source(g_modDirectory .. 'scripts/ModController.lua')
