---@class SetMachineInputAreaEnabledEvent : Event
---@field vehicle Machine
---@field enabled boolean
SetMachineInputAreaEnabledEvent = {}

local SetMachineInputAreaEnabledEvent_mt = Class(SetMachineInputAreaEnabledEvent, Event)

InitEventClass(SetMachineInputAreaEnabledEvent, 'SetMachineInputAreaEnabledEvent')

---@return SetMachineInputAreaEnabledEvent
---@nodiscard
function SetMachineInputAreaEnabledEvent.emptyNew()
    return Event.new(SetMachineInputAreaEnabledEvent_mt)
end

---@param vehicle Machine
---@param enabled boolean
---@return SetMachineInputAreaEnabledEvent
---@nodiscard
function SetMachineInputAreaEnabledEvent.new(vehicle, enabled)
    local self = SetMachineInputAreaEnabledEvent.emptyNew()

    self.vehicle = vehicle
    self.enabled = enabled

    return self
end

function SetMachineInputAreaEnabledEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.enabled)
end

function SetMachineInputAreaEnabledEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.enabled = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function SetMachineInputAreaEnabledEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setIsMachineInputAreaEnabled(self.enabled, true)
    end
end

---@param vehicle Machine
---@param enabled boolean
---@param noEventSend? boolean
function SetMachineInputAreaEnabledEvent.sendEvent(vehicle, enabled, noEventSend)
    if not noEventSend then
        local event = SetMachineInputAreaEnabledEvent.new(vehicle, enabled)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
