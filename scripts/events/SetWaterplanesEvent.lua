---@class SetWaterplanesEvent : Event
---@field waterplanes LandscapingWaterplane[]
SetWaterplanesEvent = {}

local SetWaterplanesEvent_mt = Class(SetWaterplanesEvent, Event)

InitEventClass(SetWaterplanesEvent, 'SetWaterplanesEvent')

---@return SetWaterplanesEvent
---@nodiscard
function SetWaterplanesEvent.emptyNew()
    local self = Event.new(SetWaterplanesEvent_mt)
    return self
end

---@return SetWaterplanesEvent
---@nodiscard
function SetWaterplanesEvent.new()
    return SetWaterplanesEvent.emptyNew()
end

---@param streamId number
---@param connection Connection
function SetWaterplanesEvent:writeStream(streamId, connection)
    local waterplanes = g_landscapingManager:getWaterplanes()

    streamWriteUIntN(streamId, #waterplanes, LandscapingWaterplane.SEND_NUM_BITS_PLANES)

    for _, waterplane in ipairs(waterplanes) do
        streamWriteString(streamId, waterplane.uniqueId)
        waterplane:writeStream(streamId, connection)
    end
end

---@param streamId number
---@param connection Connection
function SetWaterplanesEvent:readStream(streamId, connection)
    local numWaterPlanes = streamReadUIntN(streamId, LandscapingWaterplane.SEND_NUM_BITS_PLANES)

    self.waterplanes = {}

    for _ = 1, numWaterPlanes do
        local uniqueId = streamReadString(streamId)
        local waterplane = LandscapingWaterplane.new(uniqueId)

        waterplane:readStream(streamId, connection)

        table.insert(self.waterplanes, waterplane)
    end

    self:run(connection)
end

---@param connection Connection
function SetWaterplanesEvent:run(connection)
    if connection:getIsServer() then
        for _, waterplane in ipairs(self.waterplanes) do
            g_landscapingManager:registerWaterplane(waterplane, true)
        end
    end
end
