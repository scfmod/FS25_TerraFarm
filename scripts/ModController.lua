source(g_modDirectory .. 'scripts/events/SetDefaultEnabledEvent.lua')
source(g_modDirectory .. 'scripts/events/SetEnabledEvent.lua')
source(g_modDirectory .. 'scripts/events/SetLandscapingAreasEvent.lua')
source(g_modDirectory .. 'scripts/events/SetMaterialsEvent.lua')
source(g_modDirectory .. 'scripts/events/SetResourcesEvent.lua')
source(g_modDirectory .. 'scripts/events/SetWaterplanesEvent.lua')

---@class SubscriberItem
---@field fn function
---@field target? table

---@class ModController
---@field subscribers table<ModEvent, SubscriberItem[]>
ModController = {}

---@enum ModEvent
ModEvent = {
    onMapLoaded = "onMapLoaded",
    onModsLoaded = "onModsLoaded",
    onSendInitialClientState = "onSendInitialClientState",
    onTerrainInit = "onTerrainInit",
    onPostTerrainInit = "onPostTerrainInit",
}

local ModController_mt = Class(ModController)

---@return ModController
---@nodiscard
function ModController.new()
    ---@type ModController
    local self = setmetatable({}, ModController_mt)

    self.subscribers = {}

    return self
end

---@param str string
---@param ... any
function ModController:debug(str, ...)
    print('DEBUG:  ' .. string.format(str, ...))
end

---@param event ModEvent
---@param fn function
---@param target? table
function ModController:subscribe(event, fn, target)
    if self.subscribers[event] == nil then
        self.subscribers[event] = {}
    end

    table.insert(self.subscribers[event], {
        fn = fn,
        target = target
    })
end

---@param event ModEvent
---@param target table
function ModController:unsubscribe(event, target)
    if self.subscribers[event] ~= nil then
        for i = #self.subscribers[event], 1, -1 do
            local t = self.subscribers[event]
            if t[i].target == target then
                table.remove(t, i)
            end
        end
    end
end

---@param target table
function ModController:unsubscribeAll(target)
    for event, _ in pairs(self.subscribers) do
        self:unsubscribe(event, target)
    end
end

---@private
---@param event ModEvent
---@param ... any
function ModController:dispatch(event, ...)
    if self.subscribers[event] ~= nil then
        -- g_modController:debug('ModController:dispatch() "%s"', event)
        for _, item in ipairs(self.subscribers[event]) do
            if item.target ~= nil then
                item.fn(item.target, ...)
            else
                item.fn(...)
            end
        end
    end
end

---@private
function ModController:loadMap()
    g_modController:dispatch(ModEvent.onMapLoaded)
end

---@private
---@param self nil
function ModController:loadMods()
    g_modController:dispatch(ModEvent.onModsLoaded)
end

---@private
---@param self FSBaseMission
---@param connection Connection
function ModController:sendInitialClientState(connection, user, farm)
    g_modController:dispatch(ModEvent.onSendInitialClientState, connection, user, farm)
end

---@private
---@param self FSBaseMission
---@param filename string
function ModController:initTerrain(filename)
    g_modController:dispatch(ModEvent.onTerrainInit, filename)
    g_modController:dispatch(ModEvent.onPostTerrainInit)
end

---@diagnostic disable-next-line: lowercase-global
g_modController = ModController.new()

addModEventListener(ModController)

FSBaseMission.initTerrain = Utils.appendedFunction(FSBaseMission.initTerrain, ModController.initTerrain)

if g_server ~= nil then
    FSBaseMission.sendInitialClientState = Utils.appendedFunction(FSBaseMission.sendInitialClientState, ModController.sendInitialClientState)
end

---@diagnostic disable-next-line: undefined-global
g_onCreateUtil.activateOnCreateFunctions = Utils.appendedFunction(g_onCreateUtil.activateOnCreateFunctions, ModController.loadMods)
