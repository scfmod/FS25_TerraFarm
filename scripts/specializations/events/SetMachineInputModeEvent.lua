---@class SetMachineInputModeEvent : Event
---@field vehicle Machine
---@field mode MachineMode
SetMachineInputModeEvent = {}

local SetMachineInputModeEvent_mt = Class(SetMachineInputModeEvent, Event)

InitEventClass(SetMachineInputModeEvent, 'SetMachineInputModeEvent')

---@return SetMachineInputModeEvent
---@nodiscard
function SetMachineInputModeEvent.emptyNew()
    ---@type SetMachineInputModeEvent
    local self = Event.new(SetMachineInputModeEvent_mt)
    return self
end

---@param vehicle Machine
---@param mode MachineMode
---@return SetMachineInputModeEvent
---@nodiscard
function SetMachineInputModeEvent.new(vehicle, mode)
    local self = SetMachineInputModeEvent.emptyNew()

    self.vehicle = vehicle
    self.mode = mode

    return self
end

---@param streamId number
---@param connection Connection
function SetMachineInputModeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.mode, Machine.NUM_BITS_MODE)
end

---@param streamId number
---@param connection Connection
function SetMachineInputModeEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.mode = streamReadUIntN(streamId, Machine.NUM_BITS_MODE)

    self:run(connection)
end

---@param connection Connection
function SetMachineInputModeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setInputMode(self.mode, true)
    end
end

---@param vehicle Machine
---@param mode MachineMode
---@param noEventSend boolean | nil
function SetMachineInputModeEvent.sendEvent(vehicle, mode, noEventSend)
    if not noEventSend then
        local event = SetMachineInputModeEvent.new(vehicle, mode)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
