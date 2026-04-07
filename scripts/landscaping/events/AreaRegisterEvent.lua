---@class AreaRegisterEvent : Event
---@field area LandscapingArea
AreaRegisterEvent = {}

local AreaRegisterEvent_mt = Class(AreaRegisterEvent, Event)

InitEventClass(AreaRegisterEvent, 'AreaRegisterEvent')

---@return AreaRegisterEvent
---@nodiscard
function AreaRegisterEvent.emptyNew()
    ---@type AreaRegisterEvent
    local self = Event.new(AreaRegisterEvent_mt)
    return self
end

---@param area LandscapingArea
---@return AreaRegisterEvent
---@nodiscard
function AreaRegisterEvent.new(area)
    local self = AreaRegisterEvent.emptyNew()

    self.area = area

    return self
end

---@param streamId number
---@param connection Connection
function AreaRegisterEvent:writeStream(streamId, connection)
    streamWriteString(streamId, self.area.className)
    streamWriteString(streamId, self.area.uniqueId)

    self.area:writeStream(streamId, connection)
end

---@param streamId number
---@param connection Connection
function AreaRegisterEvent:readStream(streamId, connection)
    local className = streamReadString(streamId)
    local uniqueId = streamReadString(streamId)

    ---@diagnostic disable-next-line: assign-type-mismatch
    self.area = g_landscapingManager:createArea(className, uniqueId)
    self.area:readStream(streamId, connection)

    self:run(connection)
end

---@param connection Connection
function AreaRegisterEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection)
    end

    g_landscapingManager:registerArea(self.area, true)
end

---@param area LandscapingArea
---@param noEventSend? boolean
function AreaRegisterEvent.sendEvent(area, noEventSend)
    if not noEventSend then
        local event = AreaRegisterEvent.new(area)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
