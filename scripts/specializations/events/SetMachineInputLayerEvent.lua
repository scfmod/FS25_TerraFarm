---@class SetMachineInputLayerEvent : Event
---@field vehicle Machine
---@field terrainLayerId number
SetMachineInputLayerEvent = {}

local SetMachineInputLayerEvent_mt = Class(SetMachineInputLayerEvent, Event)

InitEventClass(SetMachineInputLayerEvent, 'SetMachineInputLayerEvent')

---@return SetMachineInputLayerEvent
---@nodiscard
function SetMachineInputLayerEvent.emptyNew()
    ---@type SetMachineInputLayerEvent
    local self = Event.new(SetMachineInputLayerEvent_mt)
    return self
end

---@param vehicle Machine
---@param terrainLayerId number
---@return SetMachineInputLayerEvent
---@nodiscard
function SetMachineInputLayerEvent.new(vehicle, terrainLayerId)
    local self = SetMachineInputLayerEvent.emptyNew()

    self.vehicle = vehicle
    self.terrainLayerId = terrainLayerId

    return self
end

---@param streamId number
---@param connection Connection
function SetMachineInputLayerEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.terrainLayerId, TerrainDeformation.LAYER_SEND_NUM_BITS)
end

---@param streamId number
---@param connection Connection
function SetMachineInputLayerEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.terrainLayerId = streamReadUIntN(streamId, TerrainDeformation.LAYER_SEND_NUM_BITS)

    self:run(connection)
end

---@param connection Connection
function SetMachineInputLayerEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setMachineInputLayerId(self.terrainLayerId, true)
    end
end

---@param vehicle Machine
---@param terrainLayerId number
---@param noEventSend boolean | nil
function SetMachineInputLayerEvent.sendEvent(vehicle, terrainLayerId, noEventSend)
    if not noEventSend then
        local event = SetMachineInputLayerEvent.new(vehicle, terrainLayerId)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
