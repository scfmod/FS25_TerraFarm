---@class SetMachineFillTypeEvent : Event
---@field vehicle Machine
---@field fillTypeIndex number
SetMachineFillTypeEvent = {}

local SetMachineFillTypeEvent_mt = Class(SetMachineFillTypeEvent, Event)

InitEventClass(SetMachineFillTypeEvent, 'SetMachineFillTypeEvent')

---@return SetMachineFillTypeEvent
---@nodiscard
function SetMachineFillTypeEvent.emptyNew()
    ---@type SetMachineFillTypeEvent
    local self = Event.new(SetMachineFillTypeEvent_mt)
    return self
end

---@param vehicle Machine
---@param fillTypeIndex number
---@return SetMachineFillTypeEvent
function SetMachineFillTypeEvent.new(vehicle, fillTypeIndex)
    local self = SetMachineFillTypeEvent.emptyNew()

    self.vehicle = vehicle
    self.fillTypeIndex = fillTypeIndex

    return self
end

---@param streamId number
---@param connection Connection
function SetMachineFillTypeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
end

---@param streamId number
---@param connection Connection
function SetMachineFillTypeEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

    self:run(connection)
end

---@param connection Connection
function SetMachineFillTypeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setMachineFillTypeIndex(self.fillTypeIndex, true)
    end
end

---@param vehicle Machine
---@param fillTypeIndex number
---@param noEventSend boolean | nil
function SetMachineFillTypeEvent.sendEvent(vehicle, fillTypeIndex, noEventSend)
    if not noEventSend then
        local event = SetMachineFillTypeEvent.new(vehicle, fillTypeIndex)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
