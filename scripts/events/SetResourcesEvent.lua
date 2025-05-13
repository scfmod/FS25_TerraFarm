---@class SetResourcesEvent : Event
---@field active boolean
---@field available boolean
SetResourcesEvent = {}

local SetResourcesEvent_mt = Class(SetResourcesEvent, Event)

InitEventClass(SetResourcesEvent, 'SetResourcesEvent')

---@return SetResourcesEvent
---@nodiscard
function SetResourcesEvent.emptyNew()
    ---@type SetResourcesEvent
    local self = Event.new(SetResourcesEvent_mt)
    return self
end

---@param available boolean
---@param active boolean
---@return SetResourcesEvent
function SetResourcesEvent.new(available, active)
    local self = SetResourcesEvent.emptyNew()

    self.available = available
    self.active = active

    return self
end

---@param streamId number
---@param connection Connection
function SetResourcesEvent:writeStream(streamId, connection)
    streamWriteBool(streamId, self.available)
    streamWriteBool(streamId, self.active)
end

---@param streamId number
---@param connection Connection
function SetResourcesEvent:readStream(streamId, connection)
    self.available = streamReadBool(streamId)
    self.active = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function SetResourcesEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection)
    end

    g_resourceManager.available = self.available
    g_resourceManager:setIsActive(self.active, true)
end

---@param available boolean
---@param active boolean
---@param noEventSend boolean | nil
function SetResourcesEvent.sendEvent(available, active, noEventSend)
    if not noEventSend then
        local event = SetResourcesEvent.new(available, active)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
