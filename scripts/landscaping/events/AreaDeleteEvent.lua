---@class AreaDeleteEvent : Event
---@field uniqueId string
AreaDeleteEvent = {}

local AreaDeleteEvent_mt = Class(AreaDeleteEvent, Event)

InitEventClass(AreaDeleteEvent, 'AreaDeleteEvent')

---@return AreaDeleteEvent
---@nodiscard
function AreaDeleteEvent.emptyNew()
    ---@type AreaDeleteEvent
    local self = Event.new(AreaDeleteEvent_mt)
    return self
end

---@param uniqueId string
---@return AreaDeleteEvent
---@nodiscard
function AreaDeleteEvent.new(uniqueId)
    local self = AreaDeleteEvent.emptyNew()

    self.uniqueId = uniqueId

    return self
end

---@param streamId number
---@param connection Connection
function AreaDeleteEvent:writeStream(streamId, connection)
    streamWriteString(streamId, self.uniqueId)
end

---@param streamId number
---@param connection Connection
function AreaDeleteEvent:readStream(streamId, connection)
    self.uniqueId = streamReadString(streamId)

    self:run(connection)
end

---@param connection Connection
function AreaDeleteEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection)
    end

    g_landscapingManager:deleteAreaByUniqueId(self.uniqueId, true)
end

---@param uniqueId string
---@param noEventSend? boolean
function AreaDeleteEvent.sendEvent(uniqueId, noEventSend)
    if not noEventSend then
        local event = AreaDeleteEvent.new(uniqueId)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
