---@class SetMachineDischargeTerrainLayerEvent : Event
---@field vehicle Machine
---@field terrainLayerId number
SetMachineDischargeTerrainLayerEvent = {}

local SetMachineDischargeTerrainLayerEvent_mt = Class(SetMachineDischargeTerrainLayerEvent, Event)

InitEventClass(SetMachineDischargeTerrainLayerEvent, 'SetMachineDischargeTerrainLayerEvent')

---@return SetMachineDischargeTerrainLayerEvent
---@nodiscard
function SetMachineDischargeTerrainLayerEvent.emptyNew()
    return Event.new(SetMachineDischargeTerrainLayerEvent_mt)
end

---@param vehicle Machine
---@param terrainLayerId number
---@return SetMachineDischargeTerrainLayerEvent
---@nodiscard
function SetMachineDischargeTerrainLayerEvent.new(vehicle, terrainLayerId)
    local self = SetMachineDischargeTerrainLayerEvent.emptyNew()

    self.vehicle = vehicle
    self.terrainLayerId = terrainLayerId

    return self
end

---@param streamId number
---@param connection Connection
function SetMachineDischargeTerrainLayerEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.terrainLayerId, TerrainDeformation.LAYER_SEND_NUM_BITS)
end

---@param streamId number
---@param connection Connection
function SetMachineDischargeTerrainLayerEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.terrainLayerId = streamReadUIntN(streamId, TerrainDeformation.LAYER_SEND_NUM_BITS)

    self:run(connection)
end

---@param connection Connection
function SetMachineDischargeTerrainLayerEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setMachineDischargeTerrainLayerId(self.terrainLayerId, true)
    end
end

---@param vehicle Machine
---@param terrainLayerId number
---@param noEventSend? boolean
function SetMachineDischargeTerrainLayerEvent.sendEvent(vehicle, terrainLayerId, noEventSend)
    if not noEventSend then
        local event = SetMachineDischargeTerrainLayerEvent.new(vehicle, terrainLayerId)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
