---@class SetSurveyorSettingsEvent : Event
---@field object Surveyor
---@field startOffset number
---@field endOffset number
SetSurveyorSettingsEvent = {}

local SetSurveyorSettingsEvent_mt = Class(SetSurveyorSettingsEvent, Event)

InitEventClass(SetSurveyorSettingsEvent, 'SetSurveyorSettingsEvent')

---@return SetSurveyorSettingsEvent
function SetSurveyorSettingsEvent.emptyNew()
    local self = Event.new(SetSurveyorSettingsEvent_mt)
    return self
end

---@param object Surveyor
---@param startOffset number
---@param endOffset number
---@return SetSurveyorSettingsEvent
function SetSurveyorSettingsEvent.new(object, startOffset, endOffset)
    local self = SetSurveyorSettingsEvent.emptyNew()

    self.object = object
    self.startOffset = startOffset
    self.endOffset = endOffset

    return self
end

---@param streamId number
---@param connection Connection
function SetSurveyorSettingsEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)

    streamWriteFloat32(streamId, self.startOffset)
    streamWriteFloat32(streamId, self.endOffset)
end

---@param streamId number
---@param connection Connection
function SetSurveyorSettingsEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)

    self.startOffset = streamReadFloat32(streamId)
    self.endOffset = streamReadFloat32(streamId)

    self:run(connection)
end

---@param connection Connection
function SetSurveyorSettingsEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setCalibrationOffset(self.startOffset, self.endOffset, true)
    end
end

---@param object Surveyor
---@param startOffset number
---@param endOffset number
---@param noEventSend boolean|nil
function SetSurveyorSettingsEvent.sendEvent(object, startOffset, endOffset, noEventSend)
    if not noEventSend then
        local event = SetSurveyorSettingsEvent.new(object, startOffset, endOffset)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
