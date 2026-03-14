---@class SetLandscapingAreasEvent : Event
---@field areas LandscapingArea[]
SetLandscapingAreasEvent = {}

local SetLandscapingAreasEvent_mt = Class(SetLandscapingAreasEvent, Event)

InitEventClass(SetLandscapingAreasEvent, 'SetLandscapingAreasEvent')

---@return SetLandscapingAreasEvent
---@nodiscard
function SetLandscapingAreasEvent.emptyNew()
    local self = Event.new(SetLandscapingAreasEvent_mt)
    return self
end

---@return SetLandscapingAreasEvent
---@nodiscard
function SetLandscapingAreasEvent.new()
    return SetLandscapingAreasEvent.emptyNew()
end

---@param streamId number
---@param connection Connection
function SetLandscapingAreasEvent:writeStream(streamId, connection)
    local areas = g_landscapingManager:getAreas()

    streamWriteUIntN(streamId, #areas, LandscapingArea.SEND_NUM_BITS_AREAS)

    for _, area in ipairs(areas) do
        streamWriteString(streamId, area.className)
        streamWriteString(streamId, area.uniqueId)
        area:writeStream(streamId, connection)
    end
end

---@param streamId number
---@param connection Connection
function SetLandscapingAreasEvent:readStream(streamId, connection)
    local numAreas = streamReadUIntN(streamId, LandscapingArea.SEND_NUM_BITS_AREAS)

    self.areas = {}

    for _ = 1, numAreas do
        local className = streamReadString(streamId)
        local unqiueId = streamReadString(streamId)
        local area = g_landscapingManager:createArea(className, unqiueId)

        if area ~= nil then
            area:readStream(streamId, connection)

            area.isActive = false

            table.insert(self.areas, area)
        end
    end

    self:run(connection)
end

---@param connection Connection
function SetLandscapingAreasEvent:run(connection)
    if connection:getIsServer() then
        for _, area in ipairs(self.areas) do
            g_landscapingManager:registerArea(area, true)
        end
    end
end
