---@class SetMachineLandscapingAreaEvent : Event
---@field vehicle Machine
---@field areaId? string
SetMachineLandscapingAreaEvent = {}

local SetMachineLandscapingAreaEvent_mt = Class(SetMachineLandscapingAreaEvent, Event)

InitEventClass(SetMachineLandscapingAreaEvent, 'SetMachineLandscapingAreaEvent')

---@return SetMachineLandscapingAreaEvent
---@nodiscard
function SetMachineLandscapingAreaEvent.emptyNew()
    ---@type SetMachineLandscapingAreaEvent
    local self = Event.new(SetMachineLandscapingAreaEvent_mt)
    return self
end

---@param vehicle Machine
---@param areaId? string
---@return SetMachineLandscapingAreaEvent
---@nodiscard
function SetMachineLandscapingAreaEvent.new(vehicle, areaId)
    local self = SetMachineLandscapingAreaEvent.emptyNew()

    self.vehicle = vehicle
    self.areaId = areaId

    return self
end

---@param streamId number
---@param connection Connection
function SetMachineLandscapingAreaEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)

    if streamWriteBool(streamId, self.areaId ~= nil) then
        streamWriteString(streamId, self.areaId)
    end
end

---@param streamId number
---@param connection Connection
function SetMachineLandscapingAreaEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)

    if streamReadBool(streamId) then
        self.areaId = streamReadString(streamId)
    else
        self.areaId = nil
    end

    self:run(connection)
end

---@param connection Connection
function SetMachineLandscapingAreaEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setMachineLandscapingArea(self.areaId, true)
    end
end

---@param vehicle Machine
---@param areaId? string
---@param noEventSend? boolean
function SetMachineLandscapingAreaEvent.sendEvent(vehicle, areaId, noEventSend)
    if not noEventSend then
        local event = SetMachineLandscapingAreaEvent.new(vehicle, areaId)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
