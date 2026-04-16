---@class SetMachineInputAreaIdEvent : Event
---@field vehicle Machine
---@field id? string
SetMachineInputAreaIdEvent = {}

local SetMachineInputAreaIdEvent_mt = Class(SetMachineInputAreaIdEvent, Event)

InitEventClass(SetMachineInputAreaIdEvent, 'SetMachineInputAreaIdEvent')

---@return SetMachineInputAreaIdEvent
---@nodiscard
function SetMachineInputAreaIdEvent.emptyNew()
    return Event.new(SetMachineInputAreaIdEvent_mt)
end

---@param vehicle Machine
---@param id? string
---@return SetMachineInputAreaIdEvent
---@nodiscard
function SetMachineInputAreaIdEvent.new(vehicle, id)
    local self = SetMachineInputAreaIdEvent.emptyNew()

    self.vehicle = vehicle
    self.id = id

    return self
end

function SetMachineInputAreaIdEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)

    if streamWriteBool(streamId, self.id ~= nil) then
        streamWriteString(streamId, self.id)
    end
end

function SetMachineInputAreaIdEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)

    if streamReadBool(streamId) then
        self.id = streamReadString(streamId)
    else
        self.id = nil
    end

    self:run(connection)
end

function SetMachineInputAreaIdEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setMachineInputAreaId(self.id, true)
    end
end

---@param vehicle Machine
---@param id? string
---@param noEventSend? boolean
function SetMachineInputAreaIdEvent.sendEvent(vehicle, id, noEventSend)
    if not noEventSend then
        local event = SetMachineInputAreaIdEvent.new(vehicle, id)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
