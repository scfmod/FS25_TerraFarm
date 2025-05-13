---@class SetMachineOutputModeEvent : Event
---@field vehicle Machine
---@field mode MachineMode
SetMachineOutputModeEvent = {}

local SetMachineOutputModeEvent_mt = Class(SetMachineOutputModeEvent, Event)

InitEventClass(SetMachineOutputModeEvent, 'SetMachineOutputModeEvent')

---@return SetMachineOutputModeEvent
---@nodiscard
function SetMachineOutputModeEvent.emptyNew()
    ---@type SetMachineOutputModeEvent
    local self = Event.new(SetMachineOutputModeEvent_mt)
    return self
end

---@param vehicle Machine
---@param mode MachineMode
---@return SetMachineOutputModeEvent
---@nodiscard
function SetMachineOutputModeEvent.new(vehicle, mode)
    local self = SetMachineOutputModeEvent.emptyNew()

    self.vehicle = vehicle
    self.mode = mode

    return self
end

---@param streamId number
---@param connection Connection
function SetMachineOutputModeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.mode, Machine.NUM_BITS_MODE)
end

---@param streamId number
---@param connection Connection
function SetMachineOutputModeEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.mode = streamReadUIntN(streamId, Machine.NUM_BITS_MODE)

    self:run(connection)
end

---@param connection Connection
function SetMachineOutputModeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setOutputMode(self.mode, true)
    end
end

---@param vehicle Machine
---@param mode MachineMode
---@param noEventSend boolean | nil
function SetMachineOutputModeEvent.sendEvent(vehicle, mode, noEventSend)
    if not noEventSend then
        local event = SetMachineOutputModeEvent.new(vehicle, mode)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
