---@class WaterplaneSetVisibleEvent : Event
---@field uniqueId string
---@field visible boolean
WaterplaneSetVisibleEvent = {}

local WaterplaneSetVisibleEvent_mt = Class(WaterplaneSetVisibleEvent, Event)

InitEventClass(WaterplaneSetVisibleEvent, 'WaterplaneSetVisibleEvent')

---@return WaterplaneSetVisibleEvent
---@nodiscard
function WaterplaneSetVisibleEvent.emptyNew()
    ---@type WaterplaneSetVisibleEvent
    local self = Event.new(WaterplaneSetVisibleEvent_mt)
    return self
end

---@param uniqueId string
---@param visible boolean
function WaterplaneSetVisibleEvent.new(uniqueId, visible)
    local self = WaterplaneSetVisibleEvent.emptyNew()

    self.uniqueId = uniqueId
    self.visible = visible

    return self
end

---@param streamId number
---@param connection Connection
function WaterplaneSetVisibleEvent:writeStream(streamId, connection)
    streamWriteString(streamId, self.uniqueId)
    streamWriteBool(streamId, self.visible)
end

---@param streamId number
---@param connection Connection
function WaterplaneSetVisibleEvent:readStream(streamId, connection)
    self.uniqueId = streamReadString(streamId)
    self.visible = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function WaterplaneSetVisibleEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection)
    end

    g_landscapingManager:setWaterplaneVisible(self.uniqueId, self.visible, true)
end

---@param waterplane LandscapingWaterplane
---@param visible boolean
---@param noEventSend? boolean
function WaterplaneSetVisibleEvent.sendEvent(waterplane, visible, noEventSend)
    if not noEventSend then
        local event = WaterplaneSetVisibleEvent.new(waterplane.uniqueId, visible)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
