---@class SetMaterialsEvent : Event
---@field materials string[]
SetMaterialsEvent = {}

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
    streamWriteInt32(streamId, #self.materials)

    for _, name in ipairs(self.materials) do
        streamWriteString(streamId, name)
    end
end

function SetMaterialsEvent:readStream(streamId, connection)
    local numMaterials = streamReadInt32(streamId)

    self.materials = {}

    if numMaterials > 0 then
        for i = 1, numMaterials do
            local name = streamReadString(streamId)
            table.insert(self.materials, name)
        end
    end

    self:run(connection)
end

---@param connection Connection
function SetMaterialsEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection)
    end

    g_modSettings:setMaterials(self.materials, true)
end

---@param materials string[]
---@param noEventSend boolean | nil
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
