---@class SetEnabledEvent : Event
---@field enabled boolean
SetEnabledEvent = {}

local SetEnabledEvent_mt = Class(SetEnabledEvent, Event)

InitEventClass(SetEnabledEvent, 'SetEnabledEvent')

---@return SetEnabledEvent
---@nodiscard
function SetEnabledEvent.emptyNew()
    ---@type SetEnabledEvent
    local self = Event.new(SetEnabledEvent_mt)
    return self
end

---@param enabled boolean
---@return SetEnabledEvent
function SetEnabledEvent.new(enabled)
    local self = SetEnabledEvent.emptyNew()

    self.enabled = enabled

    return self
end

---@param streamId number
---@param connection Connection
function SetEnabledEvent:writeStream(streamId, connection)
    streamWriteBool(streamId, self.enabled)
end

---@param streamId number
---@param connection Connection
function SetEnabledEvent:readStream(streamId, connection)
    self.enabled = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function SetEnabledEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection)
    end

    g_modSettings:setIsEnabled(self.enabled, true)
end

---@param enabled boolean
---@param noEventSend boolean | nil
function SetEnabledEvent.sendEvent(enabled, noEventSend)
    if not noEventSend then
        local event = SetEnabledEvent.new(enabled)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
