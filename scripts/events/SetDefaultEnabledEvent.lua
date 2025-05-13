---@class SetDefaultEnabledEvent : Event
---@field defaultEnabled boolean
SetDefaultEnabledEvent = {}

local SetDefaultEnabledEvent_mt = Class(SetDefaultEnabledEvent, Event)

InitEventClass(SetDefaultEnabledEvent, 'SetDefaultEnabledEvent')

---@return SetDefaultEnabledEvent
---@nodiscard
function SetDefaultEnabledEvent.emptyNew()
    ---@type SetDefaultEnabledEvent
    local self = Event.new(SetDefaultEnabledEvent_mt)
    return self
end

---@param defaultEnabled boolean
---@return SetDefaultEnabledEvent
---@nodiscard
function SetDefaultEnabledEvent.new(defaultEnabled)
    local self = SetDefaultEnabledEvent.emptyNew()

    self.defaultEnabled = defaultEnabled

    return self
end

---@param streamId number
---@param connection Connection
function SetDefaultEnabledEvent:writeStream(streamId, connection)
    streamWriteBool(streamId, self.defaultEnabled)
end

---@param streamId number
---@param connection Connection
function SetDefaultEnabledEvent:readStream(streamId, connection)
    self.defaultEnabled = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function SetDefaultEnabledEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection)
    end

    g_modSettings:setDefaultEnabled(self.defaultEnabled, true)
end

---@param defaultEnabled boolean
---@param noEventSend boolean | nil
function SetDefaultEnabledEvent.sendEvent(defaultEnabled, noEventSend)
    if not noEventSend then
        local event = SetDefaultEnabledEvent.new(defaultEnabled)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
