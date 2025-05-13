---@class ModDebug
ModDebug = {}

ModDebug.NODE_TEXT = '↓'
ModDebug.NODE_TEXT_SIZE = getCorrectTextSize(0.01)

ModDebug.NODE_WORK_AREA = 0

ModDebug.NODE_COLOR = {
    DEFAULT = { 0.8, 0.42, 1, 1 },
    TERRAIN = { 0, 1, 0, 1 },
    INACTIVE = { 0.4, 0.4, 0.4, 1 },
    INACTIVE_TERRAIN = { 0.9, 0.3, 0.3, 1 }
}

ModDebug.CALIBRATION_COLOR = {
    INACTIVE = { 0.35, 0.35, 0.35, 1.0 },
    POSITION_START = { 0.7, 0.64, 1, 1 },
    POSITION_END = { 0.7, 0.64, 1, 1 },
    TERRAIN_LINE = { 1, 1, 1, 1 },
    OFFSET_LINE = { 0.5, 0.5, 0.5, 1.0 },
    TARGET = { 0.3, 1, 0.3, 1 }
}

ModDebug.CALIBRATION_RADIUS = 1
ModDebug.CALIBRATION_STEPS = 16
ModDebug.CALIBRATION_TEXT_SIZE = getCorrectTextSize(0.025)

ModDebug.CALIBRATION_SOURCE_COLOR = { 0.8, 0.2, 0.8, 1.0 }
ModDebug.CALIBRATION_LINE_COLOR = { 0.01, 0.8, 0.9, 1.0 }

local ModDebug_mt = Class(ModDebug)

---@return ModDebug
---@nodiscard
function ModDebug.new()
    ---@type ModDebug
    local self = setmetatable({}, ModDebug_mt)

    return self
end

---@param str string
---@param ... unknown
function ModDebug:debug(str, ...)
    print('DEBUG:  ' .. string.format(str, ...))
end

function ModDebug:onMachineChanged()
    self:updateCalibration()
end

function ModDebug:onSurveyorChanged()
    self:updateCalibration()
end

function ModDebug:updateCalibration()
    local vehicle = g_machineManager:getActiveVehicle()

    if vehicle == nil or not g_modSettings:getIsEnabled() or not g_modSettings:getDebugCalibration() or not vehicle:getMachineEnabled() then
        self.calibrationDisplay:setIsEnabled(false)
        return
    end

    local inputMode = vehicle:getInputMode()
    local outputMode = vehicle:getOutputMode()

    if not (inputMode == Machine.MODE.FLATTEN or outputMode == Machine.MODE.FLATTEN) then
        self.calibrationDisplay:setIsEnabled(false)
        return
    end

    local surveyor = vehicle:getSurveyor()

    if surveyor == nil or not surveyor:getIsCalibrated() then
        self.calibrationDisplay:setIsEnabled(false)
        return
    end

    local sourceX, sourceY, sourceZ, targetX, targetY, targetZ = surveyor:getCalibration()
    local sourceOffset, targetOffset = surveyor:getCalibrationOffset()

    self.calibrationDisplay:setIsEnabled(true)
    self.calibrationDisplay:update(sourceX, sourceY, sourceZ, sourceOffset, targetX, targetY, targetZ, targetOffset)
end

function ModDebug:draw()
    local vehicle = g_machineManager.activeVehicle

    if vehicle ~= nil and g_modSettings:getIsEnabled() and vehicle:getMachineEnabled() then
        local spec = vehicle.spec_machine

        if g_modSettings:getDebugNodes() then
            for _, node in ipairs(spec.workArea.nodes) do
                self:drawNode(vehicle, spec.workArea.nodePosition[node], spec.workArea.nodeActive[node])
            end
        end

        if g_modSettings:getDebugCalibration() and (spec.inputMode == Machine.MODE.FLATTEN or spec.outputMode == Machine.MODE.FLATTEN) then
            -- self:drawMachineCalibration(vehicle)
            self:drawMachineTarget(vehicle)
        end

        -- self:drawTerrainDebug(vehicle)
    else
        self.calibrationDisplay:setIsEnabled(false)
    end
end

---@param vehicle Machine
function ModDebug:drawMachineTarget(vehicle)
    local surveyor = vehicle:getSurveyor()

    if surveyor ~= nil and surveyor:getIsCalibrated() then
        local spec = vehicle.spec_machine
        local targetHeight = spec.workArea:getTargetTerrainHeight()
        local x, y, z = spec.workArea:getPosition()

        DebugUtil.drawDebugCircle(x, targetHeight, z, 1.25, 16, ModDebug.NODE_COLOR.DEFAULT, false, true, true)
    end
end

---@param vehicle Machine
---@param position Position
---@param active boolean
function ModDebug:drawNode(vehicle, position, active)
    local spec = vehicle.spec_machine

    if position ~= nil then
        local color = ModDebug.NODE_COLOR.DEFAULT

        if active then
            if spec.active then
                color = ModDebug.NODE_COLOR.TERRAIN
            else
                color = ModDebug.NODE_COLOR.INACTIVE_TERRAIN
            end
        elseif not spec.active then
            color = ModDebug.NODE_COLOR.INACTIVE
        end

        MachineUtils.renderTextAtWorldPosition(
            position[1], position[2], position[3],
            ModDebug.NODE_TEXT, ModDebug.NODE_TEXT_SIZE, 0, color, true
        )
    end
end

---@param startPosX number
---@param startPosY number
---@param startPosZ number
---@param startOffset number
---@param endPosX number
---@param endPosY number
---@param endPosZ number
---@param endOffset number
---@param offsetY number
---@param isActive boolean | nil
function ModDebug:drawCalibration(startPosX, startPosY, startPosZ, startOffset, endPosX, endPosY, endPosZ, endOffset, offsetY, isActive)
    if startPosY == math.huge then
        return
    end

    if isActive == nil then
        isActive = true
    end

    local textColor = isActive and ModDebug.CALIBRATION_COLOR.TARGET or ModDebug.CALIBRATION_COLOR.INACTIVE

    local terrainHeightStart = MachineUtils.getTerrainHeightAtPosition(startPosX, startPosZ)
    local terrainHeightEnd = MachineUtils.getTerrainHeightAtPosition(endPosX, endPosZ)

    ---@type Calibration
    local source = {
        terrainHeight = terrainHeightStart,
        heightDiff = startPosY + startOffset - terrainHeightStart,
        heightWithOffset = startPosY + startOffset,
        x = startPosX,
        y = startPosY,
        z = startPosZ
    }

    if source.heightDiff < -0.01 then
        local heightDiffText = string.format('%.2f', source.heightDiff)
        MachineUtils.renderTextAtWorldPosition(source.x, source.terrainHeight, source.z, heightDiffText, getCorrectTextSize(0.018), 0, { 1, 1, 1, 1 }, false)
        Utils.renderTextAtWorldPosition(source.x, source.terrainHeight, source.z, ModDebug.NODE_TEXT, ModDebug.CALIBRATION_TEXT_SIZE, 0, textColor)
    else
        DebugUtil.drawDebugCircle(source.x, source.heightWithOffset, source.z, ModDebug.CALIBRATION_RADIUS, ModDebug.CALIBRATION_STEPS, textColor)
        Utils.renderTextAtWorldPosition(source.x, source.heightWithOffset, source.z, ModDebug.NODE_TEXT, ModDebug.CALIBRATION_TEXT_SIZE, 0, textColor)
    end

    DebugUtil.drawDebugLine(source.x, source.heightWithOffset, source.z, source.x, source.y + offsetY, source.z, textColor[1], textColor[2], textColor[3])

    if endPosY == math.huge then
        return
    end

    ---@type Calibration
    local target = {
        terrainHeight = terrainHeightEnd,
        heightDiff = endPosY + endOffset - terrainHeightEnd,
        heightWithOffset = endPosY + endOffset,
        x = endPosX,
        y = endPosY,
        z = endPosZ
    }

    DebugUtil.drawDebugLine(target.x, target.heightWithOffset, target.z, target.x, target.y + offsetY, target.z, textColor[1], textColor[2], textColor[3])
    DebugUtil.drawDebugLine(source.x, source.heightWithOffset, source.z, target.x, target.heightWithOffset, target.z, textColor[1], textColor[2], textColor[3])

    if target.heightDiff < -0.01 then
        local heightDiffText = string.format('%.2f', target.heightDiff)
        MachineUtils.renderTextAtWorldPosition(target.x, target.terrainHeight, target.z, heightDiffText, getCorrectTextSize(0.018), 0, { 1, 1, 1, 1 }, false)
        Utils.renderTextAtWorldPosition(target.x, target.terrainHeight, target.z, ModDebug.NODE_TEXT, ModDebug.CALIBRATION_TEXT_SIZE, 0, textColor)
    else
        DebugUtil.drawDebugCircle(target.x, target.heightWithOffset, target.z, ModDebug.CALIBRATION_RADIUS, ModDebug.CALIBRATION_STEPS, textColor)
        Utils.renderTextAtWorldPosition(target.x, target.heightWithOffset, target.z, ModDebug.NODE_TEXT, ModDebug.CALIBRATION_TEXT_SIZE, 0, textColor)
    end
end

function ModDebug:onMapLoaded()
    if g_client ~= nil then
        g_currentMission:addDrawable(self)

        self.calibrationDisplay = CalibrationDisplay.new()

        g_messageCenter:subscribe(MessageType.ACTIVE_MACHINE_CHANGED, self.onMachineChanged, self)
        g_messageCenter:subscribe(SetMachineSurveyorEvent, self.onMachineChanged, self)
        g_messageCenter:subscribe(SetMachineInputModeEvent, self.onMachineChanged, self)
        g_messageCenter:subscribe(SetMachineOutputModeEvent, self.onMachineChanged, self)
        g_messageCenter:subscribe(SetSurveyorCoordinatesEvent, self.onSurveyorChanged, self)
        g_messageCenter:subscribe(SetSurveyorSettingsEvent, self.onSurveyorChanged, self)
    end
end

---@diagnostic disable-next-line: lowercase-global
g_modDebug = ModDebug.new()
