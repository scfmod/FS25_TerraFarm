---@class SetMachineOutputAreaEnabledEvent : Event
---@field vehicle Machine
---@field enabled boolean
SetMachineOutputAreaEnabledEvent = {}

local SetMachineOutputAreaEnabledEvent_mt = Class(SetMachineOutputAreaEnabledEvent, Event)

InitEventClass(SetMachineOutputAreaEnabledEvent, 'SetMachineOutputAreaEnabledEvent')

---@return SetMachineOutputAreaEnabledEvent
---@nodiscard
function SetMachineOutputAreaEnabledEvent.emptyNew()
    return Event.new(SetMachineOutputAreaEnabledEvent_mt)
end

---@param vehicle Machine
---@param enabled boolean
---@return SetMachineOutputAreaEnabledEvent
---@nodiscard
function SetMachineOutputAreaEnabledEvent.new(vehicle, enabled)
    local self = SetMachineOutputAreaEnabledEvent.emptyNew()

    self.vehicle = vehicle
    self.enabled = enabled

    return self
end

function SetMachineOutputAreaEnabledEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.enabled)
end

function SetMachineOutputAreaEnabledEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.enabled = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function SetMachineOutputAreaEnabledEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setIsMachineOutputAreaEnabled(self.enabled, true)
    end
end

---@param vehicle Machine
---@param enabled boolean
---@param noEventSend? boolean
function SetMachineOutputAreaEnabledEvent.sendEvent(vehicle, enabled, noEventSend)
    if not noEventSend then
        local event = SetMachineOutputAreaEnabledEvent.new(vehicle, enabled)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
