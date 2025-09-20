---@class CameraTransition
---@field camera number
---@field cameraBaseNode number
---@field isActive boolean
---
---@field time number
---@field duration number
---
---@field useTimeCurve boolean
---@field usePosition boolean
---@field useRotation boolean
---@field useFov boolean
---
---@field posAnimCurve? AnimCurve
---@field rotAnimCurve? AnimCurve
---@field fovAnimCurve? AnimCurve
---
---@field finishedCallback function
---@field finishedCallbackTarget? table
---@field overriddenCamera? number
CameraTransition = {}

local CameraTransition_mt = Class(CameraTransition)

---@param duration? number
---@return CameraTransition
---@nodiscard
function CameraTransition.new(duration)
    ---@type CameraTransition
    local self = setmetatable({}, CameraTransition_mt)

    self.isActive = false
    self.time = 0
    self.duration = duration or 2000
    self.camera, self.cameraBaseNode = self:createCameraNodes()

    self.useFov = true
    self.useRotation = true
    self.usePosition = true
    self.useTimeCurve = true

    g_cameraManager:addCamera(self.camera, nil, false)

    return self
end

function CameraTransition:delete()
    if self.isActive then
        if self.overriddenCamera ~= nil then
            g_cameraManager:setActiveCamera(self.overriddenCamera)
        end

        g_currentMission:removeUpdateable(self)

        self.isActive = false
    end

    g_cameraManager:removeCamera(self.camera)
    delete(self.cameraBaseNode)
    self.camera = nil
    self.cameraBaseNode = nil
end

---@return number camera
---@return number cameraBaseNode
function CameraTransition:createCameraNodes()
    local camera = createCamera('CameraTransition', math.rad(60), 1, 10000)
    local cameraBaseNode = createTransformGroup('cameraTransitionBaseNode')

    link(cameraBaseNode, camera)
    setRotation(camera, 0, 0, 0)
    setTranslation(camera, 0, 0, 0)
    setRotation(cameraBaseNode, 0, 0, 0)
    setTranslation(cameraBaseNode, 0, 0, 0)
    setFastShadowUpdate(camera, true)

    return camera, cameraBaseNode
end

---@param duration number
function CameraTransition:setDuration(duration)
    self.duration = duration
end

---@param callbackFunction function
---@param callbackTarget? any
function CameraTransition:setFinishedCallback(callbackFunction, callbackTarget)
    self.finishedCallback = callbackFunction
    self.finishedCallbackTarget = callbackTarget
end

---@param t number
---@return number
local function curveEaseInOutCubic(t)
    return 1 - math.pow(1 - t, 3)
end

function CameraTransition:updateCamera()
    local time = self.time

    if self.useTimeCurve then
        time = time * curveEaseInOutCubic((1 / self.duration) * time)
    end

    if self.posAnimCurve ~= nil then
        local x, y, z = self.posAnimCurve:get(time)
        setTranslation(self.cameraBaseNode, x, y, z)
    end

    if self.rotAnimCurve ~= nil then
        local qx, qy, qz, qw = self.rotAnimCurve:get(time)
        setQuaternion(self.cameraBaseNode, qx, qy, qz, qw)
    end

    if self.fovAnimCurve ~= nil then
        local fovY = self.fovAnimCurve:get(time)
        setFovY(self.camera, fovY)
    end
end

function CameraTransition:onFinished()
    self.fovAnimCurve = nil
    self.posAnimCurve = nil
    self.rotAnimCurve = nil
    self.speedAnimCurve = nil
    self.isActive = false

    if self.overriddenCamera ~= nil then
        g_cameraManager:setActiveCamera(self.overriddenCamera)
    end

    g_currentMission:removeUpdateable(self)

    if self.finishedCallback ~= nil then
        self.finishedCallback(self.finishedCallbackTarget)
    end
end

---@param startCamera number
---@param endCamera number
function CameraTransition:start(startCamera, endCamera)
    -- assert(startCamera ~= nil and entityExists(startCamera), 'startCamera is invalid')
    -- assert(endCamera ~= nil and entityExists(endCamera), 'endCamera is invalid')

    if self.usePosition then
        local sx, sy, sz = getWorldTranslation(startCamera)
        local ex, ey, ez = getWorldTranslation(endCamera)

        self.posAnimCurve = AnimCurve.new(linearInterpolator3)
        self.posAnimCurve:addKeyframe({
            sx,
            sy,
            sz,
            time = 0
        })
        self.posAnimCurve:addKeyframe({
            ex,
            ey,
            ez,
            time = self.duration
        })
    end

    if self.useRotation then
        local sx, sy, sz = getWorldRotation(startCamera)
        local ex, ey, ez = getWorldRotation(endCamera)

        local sqx, sqy, sqz, sqw = mathEulerToQuaternion(sx, sy, sz)
        local eqx, eqy, eqz, eqw = mathEulerToQuaternion(ex, ey, ez)

        self.rotAnimCurve = AnimCurve.new(quaternionInterpolator)

        self.rotAnimCurve:addKeyframe({
            x = sqx,
            y = sqy,
            z = sqz,
            w = sqw,
            time = 0
        })
        self.rotAnimCurve:addKeyframe({
            x = eqx,
            y = eqy,
            z = eqz,
            w = eqw,
            time = self.duration
        })
    end

    if self.useFov then
        local sy = getFovY(startCamera)
        local ey = getFovY(endCamera)

        self.fovAnimCurve = AnimCurve.new(linearInterpolator1)

        self.fovAnimCurve:addKeyframe({
            sy,
            time = 0
        })
        self.fovAnimCurve:addKeyframe({
            ey,
            time = self.duration
        })
    end

    self.time = 0
    self:updateCamera()
    self.overriddenCamera = g_cameraManager:getActiveCamera()
    self.isActive = true

    g_currentMission:addUpdateable(self)
    g_cameraManager:setActiveCamera(self.camera)
end

---@param dt number
function CameraTransition:update(dt)
    self.time = self.time + dt

    self:updateCamera()

    if self.time > self.duration then
        self:onFinished()
    end
end

function CameraTransition:determineMapPosition()
    local x, y, z = getWorldTranslation(self.cameraBaseNode)
    return x, y, z, 0
end
