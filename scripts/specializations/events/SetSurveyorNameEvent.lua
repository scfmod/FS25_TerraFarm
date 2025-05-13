---@class SetSurveyorNameEvent : Event
---@field vehicle Surveyor
---@field name string
SetSurveyorNameEvent = {}

local SetSurveyorNameEvent_mt = Class(SetSurveyorNameEvent, Event)

InitEventClass(SetSurveyorNameEvent, 'SetSurveyorNameEvent')

---@return SetSurveyorNameEvent
---@nodiscard
function SetSurveyorNameEvent.emptyNew()
    ---@type SetSurveyorNameEvent
    local self = Event.new(SetSurveyorNameEvent_mt)
    return self
end

---@param vehicle Surveyor
---@param name string
---@return SetSurveyorNameEvent
function SetSurveyorNameEvent.new(vehicle, name)
    local self = SetSurveyorNameEvent.emptyNew()

    self.vehicle = vehicle
    self.name = name

    return self
end

---@param streamId number
---@param connection Connection
function SetSurveyorNameEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteString(streamId, self.name)
end

---@param streamId number
---@param connection Connection
function SetSurveyorNameEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.name = streamReadString(streamId)

    self:run(connection)
end

---@param connection Connection
function SetSurveyorNameEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setSurveyorName(self.name, true)
    end
end

---@param vehicle Surveyor
---@param name string
---@param noEventSend boolean | nil
function SetSurveyorNameEvent.sendEvent(vehicle, name, noEventSend)
    if not noEventSend then
        local event = SetSurveyorNameEvent.new(vehicle, name)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
