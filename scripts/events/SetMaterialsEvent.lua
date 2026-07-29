---@class SetMaterialsEvent : Event
---@field materials string[]
SetMaterialsEvent = {}
SetMaterialsEvent.SEND_NUM_BITS_MATERIALS = 10
SetMaterialsEvent.MAX_NUM_MATERIALS = 2 ^ SetMaterialsEvent.SEND_NUM_BITS_MATERIALS - 1

local SetMaterialsEvent_mt = Class(SetMaterialsEvent, Event)

InitEventClass(SetMaterialsEvent, 'SetMaterialsEvent')

---@return SetMaterialsEvent
---@nodiscard
function SetMaterialsEvent.emptyNew()
    ---@type SetMaterialsEvent
    local self = Event.new(SetMaterialsEvent_mt)
    return self
end

---@param materials string[]
---@return SetMaterialsEvent
function SetMaterialsEvent.new(materials)
    local self = SetMaterialsEvent.emptyNew()

    self.materials = materials

    return self
end

function SetMaterialsEvent:writeStream(streamId, connection)
    local numMaterials = math.min(#self.materials, SetMaterialsEvent.MAX_NUM_MATERIALS)
    streamWriteUIntN(streamId, numMaterials, SetMaterialsEvent.SEND_NUM_BITS_MATERIALS)

    for i = 1, numMaterials do
        streamWriteString(streamId, self.materials[i])
    end
end

function SetMaterialsEvent:readStream(streamId, connection)
    local numMaterials = streamReadUIntN(streamId, SetMaterialsEvent.SEND_NUM_BITS_MATERIALS)

    self.materials = {}

    for _ = 1, numMaterials do
        local name = streamReadString(streamId)
        table.insert(self.materials, name)
    end

    self:run(connection)
end

---@param connection Connection
function SetMaterialsEvent:run(connection)
    if not ModUtils.getEventConnectionIsAdministrator(connection) then
        return
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection)
    end

    g_modSettings:setMaterials(self.materials, true)
end

---@param materials string[]
---@param noEventSend boolean?
function SetMaterialsEvent.sendEvent(materials, noEventSend)
    if not noEventSend then
        local event = SetMaterialsEvent.new(materials)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
