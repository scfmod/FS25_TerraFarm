---@class SetMachineSurveyorEvent : Event
---@field vehicle Machine
---@field surveyorId string | nil
SetMachineSurveyorEvent = {}

local SetMachineSurveyorEvent_mt = Class(SetMachineSurveyorEvent, Event)

InitEventClass(SetMachineSurveyorEvent, 'SetMachineSurveyorEvent')

---@return SetMachineSurveyorEvent
---@nodiscard
function SetMachineSurveyorEvent.emptyNew()
    ---@type SetMachineSurveyorEvent
    local self = Event.new(SetMachineSurveyorEvent_mt)
    return self
end

---@param vehicle Machine
---@param surveyorId string | nil
---@return SetMachineSurveyorEvent
function SetMachineSurveyorEvent.new(vehicle, surveyorId)
    local self = SetMachineSurveyorEvent.emptyNew()

    self.vehicle = vehicle
    self.surveyorId = surveyorId

    return self
end

---@param streamId number
---@param connection Connection
function SetMachineSurveyorEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)

    if streamWriteBool(streamId, self.surveyorId ~= nil) then
        streamWriteString(streamId, self.surveyorId)
    end
end

---@param streamId number
---@param connection Connection
function SetMachineSurveyorEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)

    if streamReadBool(streamId) then
        self.surveyorId = streamReadString(streamId)
    else
        self.surveyorId = nil
    end

    self:run(connection)
end

---@param connection Connection
function SetMachineSurveyorEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setSurveyorId(self.surveyorId, true)
    end
end

---@param vehicle Machine
---@param surveyorId string | nil
---@param noEventSend boolean | nil
function SetMachineSurveyorEvent.sendEvent(vehicle, surveyorId, noEventSend)
    if not noEventSend then
        local event = SetMachineSurveyorEvent.new(vehicle, surveyorId)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
