---@class SetMachineResourcesEvent : Event
---@field vehicle Machine
---@field enabled boolean
SetMachineResourcesEvent = {}

local SetMachineResourcesEvent_mt = Class(SetMachineResourcesEvent, Event)

InitEventClass(SetMachineResourcesEvent, 'SetMachineResourcesEvent')

---@return SetMachineResourcesEvent
---@nodiscard
function SetMachineResourcesEvent.emptyNew()
    ---@type SetMachineResourcesEvent
    local self = Event.new(SetMachineResourcesEvent_mt)
    return self
end

---@param vehicle Machine
---@param enabled boolean
---@return SetMachineResourcesEvent
---@nodiscard
function SetMachineResourcesEvent.new(vehicle, enabled)
    local self = SetMachineResourcesEvent.emptyNew()

    self.vehicle = vehicle
    self.enabled = enabled

    return self
end

---@param streamId number
---@param connection Connection
function SetMachineResourcesEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.enabled)
end

---@param streamId number
---@param connection Connection
function SetMachineResourcesEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.enabled = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function SetMachineResourcesEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setResourcesEnabled(self.enabled, true)
    end
end

---@param vehicle Machine
---@param enabled boolean
---@param noEventSend boolean | nil
function SetMachineResourcesEvent.sendEvent(vehicle, enabled, noEventSend)
    if not noEventSend then
        local event = SetMachineResourcesEvent.new(vehicle, enabled)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
