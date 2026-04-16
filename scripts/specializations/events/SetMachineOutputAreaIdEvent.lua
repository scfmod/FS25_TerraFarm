---@class SetMachineOutputAreaIdEvent : Event
---@field vehicle Machine
---@field id? string
SetMachineOutputAreaIdEvent = {}

local SetMachineOutputAreaIdEvent_mt = Class(SetMachineOutputAreaIdEvent, Event)

InitEventClass(SetMachineOutputAreaIdEvent, 'SetMachineOutputAreaIdEvent')

---@return SetMachineOutputAreaIdEvent
---@nodiscard
function SetMachineOutputAreaIdEvent.emptyNew()
    return Event.new(SetMachineOutputAreaIdEvent_mt)
end

---@param vehicle Machine
---@param id? string
---@return SetMachineOutputAreaIdEvent
---@nodiscard
function SetMachineOutputAreaIdEvent.new(vehicle, id)
    local self = SetMachineOutputAreaIdEvent.emptyNew()

    self.vehicle = vehicle
    self.id = id

    return self
end

function SetMachineOutputAreaIdEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)

    if streamWriteBool(streamId, self.id ~= nil) then
        streamWriteString(streamId, self.id)
    end
end

function SetMachineOutputAreaIdEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)

    if streamReadBool(streamId) then
        self.id = streamReadString(streamId)
    else
        self.id = nil
    end

    self:run(connection)
end

function SetMachineOutputAreaIdEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setMachineOutputAreaId(self.id, true)
    end
end

---@param vehicle Machine
---@param id? string
---@param noEventSend? boolean
function SetMachineOutputAreaIdEvent.sendEvent(vehicle, id, noEventSend)
    if not noEventSend then
        local event = SetMachineOutputAreaIdEvent.new(vehicle, id)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
