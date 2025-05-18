---@class ModController
ModController = {}

function ModController:loadMap()
    g_modSettings:onMapLoaded()
    g_modGui:onMapLoaded()
    g_modHud:onMapLoaded()
    g_modDebug:onMapLoaded()
    g_machineManager:onMapLoaded()
end

---@param self nil
function ModController:loadMods()
    g_machineManager:onModsLoaded()
    g_interactiveControlExtension:onModsLoaded()
end

---@param self FSBaseMission
---@param connection Connection
function ModController:sendInitialClientState(connection, user, farm)
    g_modSettings:onSendInitialClientState(connection)
    g_resourceManager:onSendInitialClientState(connection)
end

---@param self FSBaseMission
---@param filename string
function ModController:initTerrain(filename)
    g_resourceManager:onInitTerrain()
    g_modSettings:onInitTerrain()
end

addModEventListener(ModController)

FSBaseMission.initTerrain = Utils.appendedFunction(FSBaseMission.initTerrain, ModController.initTerrain)

if g_server ~= nil then
    FSBaseMission.sendInitialClientState = Utils.appendedFunction(FSBaseMission.sendInitialClientState, ModController.sendInitialClientState)
end

---@diagnostic disable-next-line: undefined-global
g_onCreateUtil.activateOnCreateFunctions = Utils.appendedFunction(g_onCreateUtil.activateOnCreateFunctions, ModController.loadMods)
