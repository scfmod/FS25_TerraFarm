---@class SetMachineOutputLayerEvent : Event
---@field vehicle Machine
---@field terrainLayerId number
SetMachineOutputLayerEvent = {}

local SetMachineOutputLayerEvent_mt = Class(SetMachineOutputLayerEvent, Event)

InitEventClass(SetMachineOutputLayerEvent, 'SetMachineOutputLayerEvent')

---@return SetMachineOutputLayerEvent
---@nodiscard
function SetMachineOutputLayerEvent.emptyNew()
    return Event.new(SetMachineOutputLayerEvent_mt)
end

---@param vehicle Machine
---@param terrainLayerId number
---@return SetMachineOutputLayerEvent
---@nodiscard
function SetMachineOutputLayerEvent.new(vehicle, terrainLayerId)
    local self = SetMachineOutputLayerEvent.emptyNew()

    self.vehicle = vehicle
    self.terrainLayerId = terrainLayerId

    return self
end

---@param streamId number
---@param connection Connection
function SetMachineOutputLayerEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.terrainLayerId, TerrainDeformation.LAYER_SEND_NUM_BITS)
end

---@param streamId number
---@param connection Connection
function SetMachineOutputLayerEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.terrainLayerId = streamReadUIntN(streamId, TerrainDeformation.LAYER_SEND_NUM_BITS)

    self:run(connection)
end

---@param connection Connection
function SetMachineOutputLayerEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setMachineOutputLayerId(self.terrainLayerId, true)
    end
end

---@param vehicle Machine
---@param terrainLayerId number
---@param noEventSend? boolean
function SetMachineOutputLayerEvent.sendEvent(vehicle, terrainLayerId, noEventSend)
    if not noEventSend then
        local event = SetMachineOutputLayerEvent.new(vehicle, terrainLayerId)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
