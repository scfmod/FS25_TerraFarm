---@class SetMachineTerrainLayerEvent : Event
---@field vehicle Machine
---@field terrainLayerId number
SetMachineTerrainLayerEvent = {}

local SetMachineTerrainLayerEvent_mt = Class(SetMachineTerrainLayerEvent, Event)

InitEventClass(SetMachineTerrainLayerEvent, 'SetMachineTerrainLayerEvent')

---@return SetMachineTerrainLayerEvent
---@nodiscard
function SetMachineTerrainLayerEvent.emptyNew()
    ---@type SetMachineTerrainLayerEvent
    local self = Event.new(SetMachineTerrainLayerEvent_mt)
    return self
end

---@param vehicle Machine
---@param terrainLayerId number
---@return SetMachineTerrainLayerEvent
---@nodiscard
function SetMachineTerrainLayerEvent.new(vehicle, terrainLayerId)
    local self = SetMachineTerrainLayerEvent.emptyNew()

    self.vehicle = vehicle
    self.terrainLayerId = terrainLayerId

    return self
end

---@param streamId number
---@param connection Connection
function SetMachineTerrainLayerEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.terrainLayerId, TerrainDeformation.LAYER_SEND_NUM_BITS)
end

---@param streamId number
---@param connection Connection
function SetMachineTerrainLayerEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.terrainLayerId = streamReadUIntN(streamId, TerrainDeformation.LAYER_SEND_NUM_BITS)

    self:run(connection)
end

---@param connection Connection
function SetMachineTerrainLayerEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setMachineTerrainLayerId(self.terrainLayerId, true)
    end
end

---@param vehicle Machine
---@param terrainLayerId number
---@param noEventSend boolean | nil
function SetMachineTerrainLayerEvent.sendEvent(vehicle, terrainLayerId, noEventSend)
    if not noEventSend then
        local event = SetMachineTerrainLayerEvent.new(vehicle, terrainLayerId)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
