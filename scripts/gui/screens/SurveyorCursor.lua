---@class RaycastResult
---@field x number
---@field y number
---@field z number
---@field dx number
---@field dy number
---@field dz number

---@class SurveyorCursor : GuiTopDownCursor
---@field isActive boolean
---@field cursorOverlay Overlay
---@field ray RaycastResult
---@field errorMessage string|nil
---@field errorTime number
---@field raycastMode CursorRaycastMode
---@field raycastCollisionMask number
---@field raycastMaxDistance number
---@field currentHitX number
---@field currentHitY number
---@field currentHitZ number
---
---@field superClass fun(): GuiTopDownCursor
SurveyorCursor = {}

---@enum CursorRaycastMode
SurveyorCursor.RAYCAST_MODE = {
    NONE = 0,
    VEHICLE = 1,
    VEHICLE_TERRAIN = 2,
}

local SurveyorCursor_mt = Class(SurveyorCursor, GuiTopDownCursor)

---@return SurveyorCursor
---@nodiscard
function SurveyorCursor.new()
    local self = GuiTopDownCursor.new(SurveyorCursor_mt)
    ---@cast self SurveyorCursor

    self:loadOverlay()

    self.raycastMode = SurveyorCursor.RAYCAST_MODE.NONE
    self.raycastCollisionMask = 0
    self.raycastMaxDistance = 150
    self.currentHitId = nil
    self.currentHitX = 0
    self.currentHitY = 0
    self.currentHitZ = 0

    return self
end

function SurveyorCursor:loadOverlay()
    local uiScale = g_gameSettings:getValue("uiScale")
    local width, height = getNormalizedScreenValues(20 * uiScale, 20 * uiScale)
    self.cursorOverlay = Overlay.new(g_baseHUDFilename, 0.5, 0.5, width, height)

    self.cursorOverlay:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
    self.cursorOverlay:setUVs(GuiUtils.getUVs({
        0,
        48,
        48,
        48
    }))
    self.cursorOverlay:setColor(1, 1, 1, 0.3)
end

---@param mode CursorRaycastMode
function SurveyorCursor:setRaycastMode(mode)
    if self.raycastMode ~= mode then
        if mode == SurveyorCursor.RAYCAST_MODE.VEHICLE_TERRAIN then
            -- self.raycastCollisionMask = CollisionFlag.TERRAIN + CollisionFlag.TERRAIN_DELTA + CollisionFlag.VEHICLE
            self.raycastCollisionMask = CollisionFlag.TERRAIN + CollisionFlag.VEHICLE
        elseif mode == SurveyorCursor.RAYCAST_MODE.VEHICLE then
            self.raycastCollisionMask = CollisionFlag.VEHICLE
        else
            self.raycastCollisionMask = 0
        end

        self.currentHitId = nil
        self.currentHitX = 0
        self.currentHitY = 0
        self.currentHitZ = 0
    end
end

function SurveyorCursor:activate()
    self.isActive = true

    self:onInputModeChanged({
        g_inputBinding:getLastInputMode()
    })

    self:registerActionEvents()
    g_messageCenter:subscribe(MessageType.INPUT_MODE_CHANGED, self.onInputModeChanged, self)
end

function SurveyorCursor:deactivate()
    self.isActive = false
    g_messageCenter:unsubscribeAll(self)
    self:removeActionEvents()
end

---@param r number
---@param g number
---@param b number
---@param a number|nil
function SurveyorCursor:setOverlayColor(r, g, b, a)
    self.cursorOverlay:setColor(r, g, b, a or 1)
end

---@param message string|nil
---@param duration number|nil
function SurveyorCursor:setErrorMessage(message, duration)
    if message ~= nil then
        duration = duration or 2000

        self.errorMessage = message
        self.errorTime = g_time + duration
    else
        self.errorMessage = nil
        self.errorTime = 0
    end
end

function SurveyorCursor:draw()
    if not self.isMouseMode then
        self.cursorOverlay:render()
    end
end

function SurveyorCursor:updateRaycast()
    local ray = self.ray
    local cursorShouldBeVisible = false

    if ray.x == nil then
        self.currentHitId = nil
    else
        local id, x, y, z = RaycastUtil.raycastClosest(ray.x, ray.y, ray.z, ray.dx, ray.dy, ray.dz, self.raycastMaxDistance, self.raycastCollisionMask)

        self.currentHitId, self.currentHitX, self.currentHitY, self.currentHitZ = id, x, y, z

        if id ~= nil then
            cursorShouldBeVisible = not self.hitTerrainOnly or g_terrainNode == id
        end
    end

    self:setVisible(cursorShouldBeVisible)
end

---@return Surveyor | nil
function SurveyorCursor:getHitVehicle()
    if self.currentHitId ~= nil and self.currentHitId ~= g_terrainNode then
        ---@type Surveyor | nil
        local object = g_currentMission:getNodeObject(self.currentHitId)

        if object ~= nil and object:isa(Vehicle) then
            return object
        end
    end
end
