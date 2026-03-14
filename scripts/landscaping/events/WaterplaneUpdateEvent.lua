---@class WaterplaneUpdateEvent : Event
---@field waterplane LandscapingWaterplane
WaterplaneUpdateEvent = {}

local WaterplaneUpdateEvent_mt = Class(WaterplaneUpdateEvent, Event)

InitEventClass(WaterplaneUpdateEvent, 'WaterplaneUpdateEvent')

---@return WaterplaneUpdateEvent
---@nodiscard
function WaterplaneUpdateEvent.emptyNew()
    ---@type WaterplaneUpdateEvent
    local self = Event.new(WaterplaneUpdateEvent_mt)
    return self
end

---@param waterplane LandscapingWaterplane
---@return WaterplaneUpdateEvent
---@nodiscard
function WaterplaneUpdateEvent.new(waterplane)
    local self = WaterplaneUpdateEvent.emptyNew()

    self.waterplane = waterplane

    return self
end

---@param streamId number
---@param connection Connection
function WaterplaneUpdateEvent:writeStream(streamId, connection)
    streamWriteString(streamId, self.waterplane.uniqueId)

    self.waterplane:writeStream(streamId, connection)
end

---@param streamId number
---@param connection Connection
function WaterplaneUpdateEvent:readStream(streamId, connection)
    local uniqueId = streamReadString(streamId)

    self.waterplane = LandscapingWaterplane.new(uniqueId)
    self.waterplane:readStream(streamId, connection)

    self:run(connection)
end

---@param connection Connection
function WaterplaneUpdateEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection)
    end

    g_landscapingManager:updateWaterplane(self.waterplane, true)
end

---@param waterplane LandscapingWaterplane
---@param noEventSend? boolean
function WaterplaneUpdateEvent.sendEvent(waterplane, noEventSend)
    if not noEventSend then
        local event = WaterplaneUpdateEvent.new(waterplane)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
