---@class SetMachineEnabledEvent : Event
---@field vehicle Machine
---@field enabled boolean
SetMachineEnabledEvent = {}

local SetMachineEnabledEvent_mt = Class(SetMachineEnabledEvent, Event)

InitEventClass(SetMachineEnabledEvent, 'SetMachineEnabledEvent')

---@return SetMachineEnabledEvent
---@nodiscard
function SetMachineEnabledEvent.emptyNew()
    ---@type SetMachineEnabledEvent
    local self = Event.new(SetMachineEnabledEvent_mt)
    return self
end

---@param vehicle Machine
---@param enabled boolean
---@return SetMachineEnabledEvent
---@nodiscard
function SetMachineEnabledEvent.new(vehicle, enabled)
    local self = SetMachineEnabledEvent.emptyNew()

    self.vehicle = vehicle
    self.enabled = enabled

    return self
end

---@param streamId number
---@param connection Connection
function SetMachineEnabledEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.enabled)
end

---@param streamId number
---@param connection Connection
function SetMachineEnabledEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.enabled = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function SetMachineEnabledEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setMachineEnabled(self.enabled, true)
    end
end

---@param vehicle Machine
---@param enabled boolean
---@param noEventSend boolean | nil
function SetMachineEnabledEvent.sendEvent(vehicle, enabled, noEventSend)
    if not noEventSend then
        local event = SetMachineEnabledEvent.new(vehicle, enabled)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
