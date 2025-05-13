---@class SetMachineStateEvent : Event
---@field vehicle Machine
---@field state MachineState
SetMachineStateEvent = {}

local SetMachineStateEvent_mt = Class(SetMachineStateEvent, Event)

InitEventClass(SetMachineStateEvent, 'SetMachineStateEvent')

---@return SetMachineStateEvent
---@nodiscard
function SetMachineStateEvent.emptyNew()
    ---@type SetMachineStateEvent
    local self = Event.new(SetMachineStateEvent_mt)
    return self
end

---@param vehicle Machine
---@param state MachineState
---@return SetMachineStateEvent
---@nodiscard
function SetMachineStateEvent.new(vehicle, state)
    local self = SetMachineStateEvent.emptyNew()

    self.vehicle = vehicle
    self.state = state

    return self
end

---@param streamId number
---@param connection Connection
function SetMachineStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    self.state:writeStream(streamId, connection)
end

---@param streamId number
---@param connection Connection
function SetMachineStateEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.state = MachineState.new()
    self.state:readStream(streamId, connection)

    self:run(connection)
end

---@param connection Connection
function SetMachineStateEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setMachineState(self.state, true)
    end
end

---@param vehicle Machine
---@param state MachineState
---@param noEventSend boolean | nil
function SetMachineStateEvent.sendEvent(vehicle, state, noEventSend)
    if not noEventSend then
        local event = SetMachineStateEvent.new(vehicle, state)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
