---@class CursorRaycast
---@field x number
---@field y number
---@field z number
---@field dx number
---@field dy number
---@field dz number

---@class EditorCursor : GuiTopDownCursor
---@field target EditorScreen
---@field currentHitTerrain boolean
---@field rayMaxDistance number
---
---@field isActive boolean
---@field ray CursorRaycast
---@field rayCollisionMask number
---@field currentHitId? number
---@field currentHitX number
---@field currentHitY number
---@field currentHitZ number
---@field mousePosX number
---@field mousePosY number
---
---@field superClass fun(): GuiTopDownCursor
EditorCursor = {}

local EditorCursor_mt = Class(EditorCursor, GuiTopDownCursor)

---@return EditorCursor
function EditorCursor.new(target)
    ---@type EditorCursor
    local self = GuiTopDownCursor.new(EditorCursor_mt)

    self.target = target
    self.isActive = false
    self.rayMaxDistance = 150

    self.currentHitTerrain = false
    self:setTerrainOnly(true)

    return self
end

function EditorCursor:activate()
    self:superClass().activate(self)

    self:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
end

function EditorCursor:registerActionEvents()
    local _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_CURSOR_ROTATE, self, self.onRotate, false, false, true, false)
    self.rotateEventId = eventId
    g_inputBinding:setActionEventActive(self.rotateEventId, self.rotationEnabled)
    g_inputBinding:setActionEventTextVisibility(eventId, false)
    g_inputBinding:setActionEventTextPriority(self.rotateEventId, GS_PRIO_NORMAL)
end

---@param posX number
---@param posY number
function EditorCursor:mouseEvent(posX, posY)
    self:superClass().mouseEvent(self, posX, posY)

    self.mousePosX = posX
    self.mousePosY = posY
end

function EditorCursor:draw()
    if self.cursorOverlay ~= nil and not self.isMouseMode then
        self.cursorOverlay:render()
    end
end

function EditorCursor:updateRaycast()
    local ray = self.ray

    if ray.x == nil then
        self.currentHitId = nil
        self.currentHitTerrain = false
    else
        self.currentHitId, self.currentHitX, self.currentHitY, self.currentHitZ = RaycastUtil.raycastClosest(ray.x, ray.y, ray.z, ray.dx, ray.dy, ray.dz, self.rayMaxDistance, self.rayCollisionMask)
        self.currentHitTerrain = self.currentHitId == g_terrainNode
    end

    self.currentHitTerrain = self.hitTerrainOnly and self.currentHitId == g_terrainNode
end

function EditorCursor:onInputModeChanged(inputMode)
    self:superClass().onInputModeChanged(self, inputMode)

    if self.isMouseMode then
        g_inputBinding:setShowMouseCursor(true, true)
    else
        g_inputBinding:setShowMouseCursor(false, true)
    end
end
