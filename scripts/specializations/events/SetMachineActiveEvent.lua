---@class SetMachineActiveEvent : Event
---@field vehicle Machine
---@field active boolean
SetMachineActiveEvent = {}

local SetMachineActiveEvent_mt = Class(SetMachineActiveEvent, Event)

InitEventClass(SetMachineActiveEvent, 'SetMachineActiveEvent')

---@return SetMachineActiveEvent
---@nodiscard
function SetMachineActiveEvent.emptyNew()
    ---@type SetMachineActiveEvent
    local self = Event.new(SetMachineActiveEvent_mt)
    return self
end

---@param vehicle Machine
---@param active boolean
---@return SetMachineActiveEvent
---@nodiscard
function SetMachineActiveEvent.new(vehicle, active)
    local self = SetMachineActiveEvent.emptyNew()

    self.vehicle = vehicle
    self.active = active

    return self
end

---@param streamId number
---@param connection Connection
function SetMachineActiveEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.active)
end

---@param streamId number
---@param connection Connection
function SetMachineActiveEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.active = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function SetMachineActiveEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setMachineActive(self.active, true)
    end
end

---@param vehicle Machine
---@param active boolean
---@param noEventSend boolean | nil
function SetMachineActiveEvent.sendEvent(vehicle, active, noEventSend)
    if not noEventSend then
        local event = SetMachineActiveEvent.new(vehicle, active)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
