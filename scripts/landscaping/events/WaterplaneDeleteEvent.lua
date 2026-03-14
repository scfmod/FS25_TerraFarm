---@class WaterplaneDeleteEvent : Event
---@field uniqueId string
WaterplaneDeleteEvent = {}

local WaterplaneDeleteEvent_mt = Class(WaterplaneDeleteEvent, Event)

InitEventClass(WaterplaneDeleteEvent, 'WaterplaneDeleteEvent')

---@return WaterplaneDeleteEvent
---@nodiscard
function WaterplaneDeleteEvent.emptyNew()
    ---@type WaterplaneDeleteEvent
    local self = Event.new(WaterplaneDeleteEvent_mt)
    return self
end

function WaterplaneDeleteEvent.new(uniqueId)
    local self = WaterplaneDeleteEvent.emptyNew()

    self.uniqueId = uniqueId

    return self
end

---@param streamId number
---@param connection Connection
function WaterplaneDeleteEvent:writeStream(streamId, connection)
    streamWriteString(streamId, self.uniqueId)
end

---@param streamId number
---@param connection Connection
function WaterplaneDeleteEvent:readStream(streamId, connection)
    self.uniqueId = streamReadString(streamId)

    self:run(connection)
end

---@param connection Connection
function WaterplaneDeleteEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection)
    end

    g_landscapingManager:deleteWaterplaneByUniqueId(self.uniqueId, true)
end

---@param waterplane LandscapingWaterplane
---@param noEventSend? boolean
function WaterplaneDeleteEvent.sendEvent(waterplane, noEventSend)
    if not noEventSend then
        local event = WaterplaneDeleteEvent.new(waterplane.uniqueId)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
