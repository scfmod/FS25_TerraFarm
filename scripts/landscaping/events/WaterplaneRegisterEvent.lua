---@class WaterplaneRegisterEvent : Event
---@field waterplane LandscapingWaterplane
WaterplaneRegisterEvent = {}

local WaterplaneRegisterEvent_mt = Class(WaterplaneRegisterEvent, Event)

InitEventClass(WaterplaneRegisterEvent, 'WaterplaneRegisterEvent')

---@return WaterplaneRegisterEvent
---@nodiscard
function WaterplaneRegisterEvent.emptyNew()
    ---@type WaterplaneRegisterEvent
    local self = Event.new(WaterplaneRegisterEvent_mt)
    return self
end

---@param waterplane LandscapingWaterplane
---@return WaterplaneRegisterEvent
---@nodiscard
function WaterplaneRegisterEvent.new(waterplane)
    local self = WaterplaneRegisterEvent.emptyNew()

    self.waterplane = waterplane

    return self
end

---@param streamId number
---@param connection Connection
function WaterplaneRegisterEvent:writeStream(streamId, connection)
    streamWriteString(streamId, self.waterplane.uniqueId)

    self.waterplane:writeStream(streamId, connection)
end

---@param streamId number
---@param connection Connection
function WaterplaneRegisterEvent:readStream(streamId, connection)
    local uniqueId = streamReadString(streamId)

    self.waterplane = LandscapingWaterplane.new(uniqueId)
    self.waterplane:readStream(streamId, connection)

    self:run(connection)
end

---@param connection Connection
function WaterplaneRegisterEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection)
    end

    g_landscapingManager:registerWaterplane(self.waterplane, true)
end

---@param waterplane LandscapingWaterplane
---@param noEventSend? boolean
function WaterplaneRegisterEvent.sendEvent(waterplane, noEventSend)
    if not noEventSend then
        local event = WaterplaneRegisterEvent.new(waterplane)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
