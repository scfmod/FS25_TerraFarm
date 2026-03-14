---@class AreaUpdateEvent : Event
---@field area LandscapingArea
AreaUpdateEvent = {}

local AreaUpdateEvent_mt = Class(AreaUpdateEvent, Event)

InitEventClass(AreaUpdateEvent, 'AreaUpdateEvent')

---@return AreaUpdateEvent
---@nodiscard
function AreaUpdateEvent.emptyNew()
    ---@type AreaUpdateEvent
    local self = Event.new(AreaUpdateEvent_mt)
    return self
end

---@param area LandscapingArea
---@return AreaUpdateEvent
---@nodiscard
function AreaUpdateEvent.new(area)
    local self = AreaUpdateEvent.emptyNew()

    self.area = area

    return self
end

---@param streamId number
---@param connection Connection
function AreaUpdateEvent:writeStream(streamId, connection)
    streamWriteString(streamId, self.area.uniqueId)

    self.area:writeStream(streamId, connection)
end

---@param streamId number
---@param connection Connection
function AreaUpdateEvent:readStream(streamId, connection)
    local uniqueId = streamReadString(streamId)
    ---@diagnostic disable-next-line: assign-type-mismatch
    self.area = g_landscapingManager:getAreaByUniqueId(uniqueId)

    if self.area ~= nil then
        self.area:readStream(streamId, connection)
        self:run(connection)
    else
        Logging.error('AreaUpdateEvent:readStream() Area uniqueId "%s" not found', uniqueId)
    end
end

---@param connection Connection
function AreaUpdateEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection)
    end

    g_landscapingManager:updateArea(self.area, true)
end

---@param area LandscapingArea
---@param noEventSend? boolean
function AreaUpdateEvent.sendEvent(area, noEventSend)
    if not noEventSend then
        local event = AreaUpdateEvent.new(area)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
