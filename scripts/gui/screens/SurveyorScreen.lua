---@class SurveyorScreen : ScreenElement
---@field menuBox BitmapElement
---@field camera SurveyorCamera
---@field cursor SurveyorCursor
---@field isFirstOpen boolean
---@field isMouseMode boolean
---@field isMouseInMenu boolean
---@field vehicle Surveyor | nil
---@field isDebug boolean
---@field superClass fun(): ScreenElement
---@field backButtonEvent string
---@field primaryButtonEvent string
---@field isCalibrating boolean
---
---@field name string
---@field startPosX number
---@field startPosY number
---@field startPosZ number
---@field startOffset number
---@field endPosX number
---@field endPosY number
---@field endPosZ number
---@field endOffset number
---
---@field calibrateButton ButtonElement
---@field setAngleButton ButtonElement
---@field setLevelButton ButtonElement
---@field resetButton ButtonElement
---@field renameButton ButtonElement
---
---@field applyButton ButtonElement
---@field cancelButton ButtonElement
---@field exitButton ButtonElement
---@field useTerrain boolean
---
---@field detailsBox BitmapElement
---@field vehicleText TextElement
---@field vehicleImage BitmapElement
---@field calibrationText TextElement
---@field calibrationAngleItem GuiElement
---@field useTerrainOption TFBinaryOptionElement
---@field startOffsetText TextElement
---@field endOffsetText TextElement
---
---@field mouseCalibrationDisplay CalibrationDisplay
---@field calibrationDisplay CalibrationDisplay
SurveyorScreen = {}

SurveyorScreen.CLASS_NAME = 'SurveyorScreen'
SurveyorScreen.XML_FILENAME = g_currentModDirectory .. 'xml/gui/screens/SurveyorScreen.xml'
SurveyorScreen.INPUT_CONTEXT = 'SURVEYOR_SCREEN'

SurveyorScreen.L10N_TARGET_POSITION = g_i18n:getText('ui_setTarget')
SurveyorScreen.L10N_EXIT_MENU = g_i18n:getText('input_CONSTRUCTION_EXIT')
SurveyorScreen.L10N_CANCEL_CALIBRATION = g_i18n:getText('button_cancel')
SurveyorScreen.L10N_STATUS_CALIBRATED = g_i18n:getText('ui_calibrated')
SurveyorScreen.L10N_STATUS_NOT_CALIBRATED = g_i18n:getText('ui_notCalibrated')

local SurveyorScreen_mt = Class(SurveyorScreen, ScreenElement)

---@return SurveyorScreen
---@nodiscard
function SurveyorScreen.new()
    local self = ScreenElement.new(nil, SurveyorScreen_mt)
    ---@cast self SurveyorScreen

    self.camera = SurveyorCamera.new()
    self.cursor = SurveyorCursor.new()

    self.useTerrain = true

    self.isFirstOpen = true
    self.isMouseMode = true
    self.isMouseInMenu = false
    self.isCalibrating = false

    self.startOffset = 0
    self.endOffset = 0

    self.calibrationDisplay = CalibrationDisplay.new()
    self.calibrationDisplay:setColor(0.1, 0.3, 1.0)
    self.mouseCalibrationDisplay = CalibrationDisplay.new()
    self.mouseCalibrationDisplay:setColor(1.0, 0.3, 0)

    self:resetPositions()

    return self
end

function SurveyorScreen:load()
    g_gui:loadGui(SurveyorScreen.XML_FILENAME, SurveyorScreen.CLASS_NAME, self)

    self:loadShapes()
end

function SurveyorScreen:loadShapes()
    self.cursorMarkerSource = Shape.new(Shape.TYPE.MARKER)
    self.cursorMarkerTarget = Shape.new(Shape.TYPE.MARKER)
    self.cursorLine = LineShape.new()
    self.lineStart = LineShape.new()
    self.lineEnd = LineShape.new()

    self.cursorMarkerSource:setColor(1, 0.3, 0, 1)
    self.cursorMarkerTarget:setColor(1, 0.3, 0, 1)
    self.cursorLine:setColor(1, 0.3, 0, 1)
    self.lineStart:setScale(4)
    self.lineStart:setEmission(0)
    self.lineEnd:setScale(4)
    self.lineEnd:setEmission(0)
end

---@param vehicle Surveyor
function SurveyorScreen:show(vehicle)
    if vehicle ~= nil then
        self.vehicle = vehicle

        g_gui:changeScreen(nil, SurveyorScreen)
    end
end

function SurveyorScreen:delete()
    self.camera:delete()
    self.cursor:delete()

    FocusManager.guiFocusData[SurveyorScreen.CLASS_NAME] = {
        idToElementMapping = {}
    }

    self:superClass().delete(self)
end

function SurveyorScreen:onOpen()
    self:superClass().onOpen(self)

    g_inputBinding:setContext(SurveyorScreen.INPUT_CONTEXT)
    self:registerMenuActionEvents()

    self.camera:setTerrainRootNode(g_terrainNode)

    local worldPosX, _, worldPosZ = getWorldTranslation(self.vehicle.rootNode)
    self.camera.cameraX, self.camera.cameraZ = worldPosX, worldPosZ
    self.camera.targetCameraX, self.camera.targetCameraZ = worldPosX, worldPosZ

    if self.isFirstOpen then
        self.camera.zoomFactor = 0.025
        self.camera.targetZoomFactor = 0.025
        self.isFirstOpen = false
    end

    self.camera:updatePosition()

    self.camera:activate()
    self.cursor:activate()

    ---@diagnostic disable-next-line: undefined-field
    g_currentMission.hud.ingameMap:setTopDownCamera(self.camera)

    local posY = 1 - self.menuBox.absSize[2]

    g_depthOfFieldManager:pushArea(
        0,
        posY,
        self.menuBox.absSize[1],
        self.menuBox.absSize[2]
    )

    self.calibrationDisplay:setIsEnabled(true)

    self:setPositionsFromVehicle(self.vehicle)
    self:updateSurveyor()
    self:updateOffset()
    self:updateButtons()

    self.useTerrainOption:setIsChecked(self.useTerrain, true, true)

    g_messageCenter:subscribe(MessageType.SURVEYOR_REMOVED, self.onSurveyorRemoved, self)
    g_messageCenter:subscribe(SetSurveyorNameEvent, self.onSurveyorRenamed, self)
    g_messageCenter:subscribe(SetSurveyorCoordinatesEvent, self.onSurveyorChanged, self)
    g_messageCenter:subscribe(SetSurveyorSettingsEvent, self.onOffsetChanged, self)
end

function SurveyorScreen:onClose()
    g_messageCenter:unsubscribeAll(self)

    self.cursor:deactivate()
    self.camera:deactivate()

    ---@diagnostic disable-next-line: undefined-field
    g_currentMission.hud.ingameMap:setTopDownCamera(nil)

    g_depthOfFieldManager:popArea()
    self:removeMenuActionEvents()
    g_inputBinding:revertContext()

    self.vehicle = nil
    self:setIsCalibrating(false)
    self:resetPositions()

    self.calibrationDisplay:setIsEnabled(false)

    self:superClass().onClose(self)
end

---@param dt number
function SurveyorScreen:update(dt)
    self:superClass().update(self, dt)

    self.camera:setCursorLocked(self.cursor.isCatchingCursor)
    self.camera:update(dt)

    if self.isMouseInMenu then
        self.cursor:setCameraRay()
    else
        self.cursor:setCameraRay(self.camera:getPickRay())
    end

    self.cursor:update(dt)
end

---@param x number
---@param y number
function SurveyorScreen:mouseEvent(x, y)
    self.isMouseInMenu = GuiUtils.checkOverlayOverlap(
        x, y,
        self.menuBox.absPosition[1],
        self.menuBox.absPosition[2],
        self.menuBox.absSize[1],
        self.menuBox.absSize[2]
    )

    self.camera.mouseDisabled = self.isMouseInMenu
    self.cursor.mouseDisabled = self.isMouseInMenu

    self.camera:mouseEvent(x, y)
    self.cursor:mouseEvent(x, y)
end

function SurveyorScreen:draw()
    self:superClass().draw(self)

    ---@diagnostic disable-next-line: undefined-field
    g_currentMission.hud:drawInputHelp()

    local cursorIsCalibrating = false

    if not self.isMouseInMenu then
        self.cursor:draw()

        if self.isCalibrating and self.cursor.currentHitId ~= nil then
            --self:drawCursorCalibration()
            self:updateCursorCalibration()
            cursorIsCalibrating = true
        end
    end

    -- self:drawCurrentCalibration(cursorIsCalibrating)
end

function SurveyorScreen:onButtonPrimary(_, inputValue, _, isAnalog, isMouse)
    if isMouse and self.isCalibrating and not self.isMouseInMenu and self.cursor.currentHitId ~= nil then
        ---@type Vehicle | nil
        local hitVehicle = nil
        local endPosX, endPosY, endPosZ = self.cursor.currentHitX, self.cursor.currentHitY, self.cursor.currentHitZ

        if self.cursor.currentHitId ~= g_terrainNode then
            hitVehicle = self.cursor:getHitVehicle()

            if hitVehicle ~= nil then
                endPosX, endPosY, endPosZ = MachineUtils.getVehicleTerrainHeight(hitVehicle)
            else
                return
            end
        elseif not self.useTerrain then
            return
        end

        self.endPosX, self.endPosY, self.endPosZ = endPosX, endPosY, endPosZ

        self:updateCalibration()
    end
end

function SurveyorScreen:onClickUseTerrainOption(state)
    self.useTerrain = state == CheckedOptionElement.STATE_CHECKED

    if self.isCalibrating then
        self:updateCursorRaycast()
    end
end

function SurveyorScreen:onClickStartOffset()
    g_floatInputDialog:setCallback(self.setStartOffsetCallback, self, self.startOffset, -100, 100, 'Set start offset')
    g_gui:showDialog(FloatInputDialog.CLASS_NAME)
end

---@param value number
---@param clickOk boolean
function SurveyorScreen:setStartOffsetCallback(value, clickOk)
    if clickOk and value ~= nil then
        self.startOffset = value

        self.vehicle:setCalibrationOffset(self.startOffset, self.endOffset)
    end
end

function SurveyorScreen:onClickEndOffset()
    g_floatInputDialog:setCallback(self.setEndOffsetCallback, self, self.endOffset, -100, 100, 'Set target offset')
    g_gui:showDialog(FloatInputDialog.CLASS_NAME)
end

---@param value number
---@param clickOk boolean
function SurveyorScreen:setEndOffsetCallback(value, clickOk)
    if clickOk and value ~= nil then
        self.endOffset = value

        self.vehicle:setCalibrationOffset(self.startOffset, self.endOffset)
    end
end

function SurveyorScreen:onButtonMenuBack()
    if self.isCalibrating then
        self:onClickCancel()
    else
        g_gui:showGui(nil)
    end
end

function SurveyorScreen:registerMenuActionEvents()
    local _, eventId = g_inputBinding:registerActionEvent(InputAction.MENU_BACK, self, self.onButtonMenuBack, false, true, false, true)

    g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_LOW)

    self.backButtonEvent = eventId

    _, eventId = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_PRIMARY, self, self.onButtonPrimary, false, true, false, true)
    g_inputBinding:setActionEventText(eventId, SurveyorScreen.L10N_TARGET_POSITION)

    self.primaryButtonEvent = eventId

    self:updateMenuActionEvents()
end

function SurveyorScreen:removeMenuActionEvents()
    if self.primaryButtonEvent ~= nil then
        g_inputBinding:removeActionEvent(self.primaryButtonEvent)
    end

    if self.backButtonEvent ~= nil then
        g_inputBinding:removeActionEvent(self.backButtonEvent)
    end
end

function SurveyorScreen:updateMenuActionEvents()
    if self.primaryButtonEvent ~= nil then
        g_inputBinding:setActionEventTextVisibility(self.primaryButtonEvent, self.isCalibrating)
    else
        Logging.warning('primaryButtonEvent not set')
    end

    if self.backButtonEvent ~= nil then
        g_inputBinding:setActionEventTextVisibility(self.backButtonEvent, true)

        if self.isCalibrating then
            g_inputBinding:setActionEventText(self.backButtonEvent, SurveyorScreen.L10N_CANCEL_CALIBRATION)
        else
            g_inputBinding:setActionEventText(self.backButtonEvent, SurveyorScreen.L10N_EXIT_MENU)
        end
    else
        Logging.warning('backButtonEvent not set')
    end
end

---@param vehicle Surveyor
function SurveyorScreen:onSurveyorRemoved(vehicle)
    if self.vehicle ~= nil and vehicle == self.vehicle then
        g_gui:changeScreen()
    end
end

---@param vehicle Surveyor
---@param name string
function SurveyorScreen:onSurveyorRenamed(vehicle, name)
    if self.vehicle ~= nil and vehicle == self.vehicle then
        self.vehicleText:setText(name)
    end
end

---@param vehicle Surveyor
function SurveyorScreen:onSurveyorChanged(vehicle)
    if self.vehicle ~= nil and self.vehicle == vehicle then
        self:setPositionsFromVehicle(vehicle)
        self:updateSurveyor()
        self:updateButtons()
    end
end

---@param vehicle Surveyor
function SurveyorScreen:onOffsetChanged(vehicle)
    if self.vehicle ~= nil and self.vehicle == vehicle then
        self:updateOffset()

        self.startOffset, self.endOffset = vehicle:getCalibrationOffset()

        self:updateCalibration()
    end
end

---@param isCalibrating boolean
function SurveyorScreen:setIsCalibrating(isCalibrating)
    if self.isCalibrating ~= isCalibrating then
        self.isCalibrating = isCalibrating

        self:updateCursorRaycast()
        self:updateButtons()
        self:updateMenuActionEvents()
        self:updateShapes()

        self.mouseCalibrationDisplay:setIsEnabled(isCalibrating)

        self.isBackAllowed = not isCalibrating
    end
end

---@param forceBack boolean | nil
---@param usedMenuButton boolean | nil
function SurveyorScreen:onClickBack(forceBack, usedMenuButton)
    if self:superClass().onClickBack(self, forceBack, usedMenuButton) and self.isCalibrating then
        self:setPositionsFromVehicle(self.vehicle)
        self:setIsCalibrating(false)
        return false
    end
end

function SurveyorScreen:onClickCalibrate()
    self.startPosX, self.startPosY, self.startPosZ = MachineUtils.getVehicleTerrainHeight(self.vehicle)

    self:setIsCalibrating(true)
    self:updateCalibration()
end

function SurveyorScreen:onClickRename()
    g_nameInputDialog:setCallback(self.renameCallback, self, self.vehicle:getFullName(), g_i18n:getText('button_rename'))
    g_gui:showDialog(NameInputDialog.CLASS_NAME)
end

---@param value string
---@param clickOk boolean
function SurveyorScreen:renameCallback(value, clickOk)
    if clickOk and value ~= nil then
        self.vehicle:setSurveyorName(value)
    end
end

function SurveyorScreen:onClickSetLevel()
    if not self.isCalibrating and self.startPosY ~= math.huge and self.endPosY ~= math.huge then
        self.endPosY = self.startPosY

        self.vehicle:setCalibration(self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ)
    end
end

function SurveyorScreen:onClickSetAngle()
    if self.startPosY ~= math.huge and self.endPosY ~= math.huge then
        local angle = MachineUtils.getAngleBetweenPoints(self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ)

        g_floatInputDialog:setCallback(self.setAngleCallback, self, angle, nil, nil, g_i18n:getText('ui_setAngle'))
        g_gui:showDialog(FloatInputDialog.CLASS_NAME)
    end
end

---@param value number
---@param clickOk boolean
function SurveyorScreen:setAngleCallback(value, clickOk)
    if clickOk and value ~= nil and self.startPosY ~= math.huge and self.endPosY ~= math.huge then
        local adjacent = MathUtil.getPointPointDistance(self.startPosX, self.startPosZ, self.endPosX, self.endPosZ)
        local opposite = adjacent * math.tan(math.rad(value))

        self.endPosY = self.startPosY + opposite

        if not self.isCalibrating then
            self.vehicle:setCalibration(self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ)
        end
    end
end

function SurveyorScreen:onClickReset()
    if not self.isCalibrating then
        self:resetPositions()
        self.vehicle:setCalibration(self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ)
    end
end

function SurveyorScreen:onClickCancel()
    if self.isCalibrating then
        self:setPositionsFromVehicle(self.vehicle)
        self:setIsCalibrating(false)
    end
end

function SurveyorScreen:onClickApply()
    if self.isCalibrating then
        self.vehicle:setCalibration(self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ)
        self:setIsCalibrating(false)
    end
end

function SurveyorScreen:onClickExit()
    self:onButtonMenuBack()
end

---@param vehicle Surveyor
function SurveyorScreen:setPositionsFromVehicle(vehicle)
    self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ = vehicle:getCalibration()
    self.startOffset, self.endOffset = vehicle:getCalibrationOffset()

    self:updateCalibration()
end

function SurveyorScreen:resetPositions()
    self.startPosX = 0
    self.startPosY = math.huge
    self.startPosZ = 0

    self.endPosX = 0
    self.endPosY = math.huge
    self.endPosZ = 0

    self:updateCalibration()
end

function SurveyorScreen:updateCursorRaycast()
    if self.isCalibrating then
        if self.useTerrain then
            self.cursor:setRaycastMode(SurveyorCursor.RAYCAST_MODE.VEHICLE_TERRAIN)
        else
            self.cursor:setRaycastMode(SurveyorCursor.RAYCAST_MODE.VEHICLE)
        end
    else
        self.cursor:setRaycastMode(SurveyorCursor.RAYCAST_MODE.NONE)
    end
end

function SurveyorScreen:updateShapes()
    self.cursorMarkerSource:setIsVisible(self.isCalibrating == true)
    self.cursorMarkerTarget:setIsVisible(self.isCalibrating == true)
    self.cursorLine:setIsVisible(self.isCalibrating == true)

    if not self.isCalibrating then
        self.lineStart:setIsVisible(false)
        self.lineEnd:setIsVisible(false)
    end
end

function SurveyorScreen:updateButtons()
    self.calibrateButton:setDisabled(self.isCalibrating)

    local disableModifyAngle = self.isCalibrating or (self.startPosY == math.huge or self.endPosY == math.huge)

    self.setAngleButton:setDisabled(disableModifyAngle)
    self.setLevelButton:setDisabled(disableModifyAngle)

    self.resetButton:setDisabled(self.isCalibrating or self.startPosY == math.huge)
    self.renameButton:setDisabled(self.isCalibrating)

    self.applyButton:setDisabled(not self.isCalibrating or self.startPosY == math.huge)
    self.cancelButton:setDisabled(not self.isCalibrating)
    self.exitButton:setDisabled(self.isCalibrating)
end

function SurveyorScreen:updateSurveyor()
    if self.vehicle ~= nil then
        local spec = self.vehicle.spec_surveyor

        self.vehicleText:setText(self.vehicle:getFullName())
        self.vehicleImage:setImageFilename(self.vehicle:getImageFilename())

        local sourceX, sourceY, sourceZ, targetX, targetY, targetZ = self.vehicle:getCalibration()
        local sourceOffset, targetOffset = self.vehicle:getCalibrationOffset()

        if sourceY ~= math.huge then
            local angle = MachineUtils.getAngleBetweenPoints(sourceX, sourceY + sourceOffset, sourceZ, targetX, targetY + targetOffset, targetZ)
            -- self.calibrationText:setText(string.format(g_i18n:getText('ui_calibratedAngleFormat'), angle))
            self.calibrationText:setText(string.format('%.2f°', angle))
            -- self.statusText:setText(SurveyorScreen.L10N_STATUS_CALIBRATED)
            self.detailsBox:setDisabled(false)
            self.calibrationAngleItem:setDisabled(false)
        else
            self.calibrationText:setText(SurveyorScreen.L10N_STATUS_NOT_CALIBRATED)
            -- self.statusText:setText(SurveyorScreen.L10N_STATUS_NOT_CALIBRATED)
            self.detailsBox:setDisabled(true)
            self.calibrationAngleItem:setDisabled(true)
        end

        -- self.calibrationDisplay:setIsEnabled(true)
        -- self.calibrationDisplay:update(sourceX, sourceY, sourceZ, sourceOffset, targetX, targetY, targetZ, targetOffset)
    else
        -- self.calibrationDisplay:setIsEnabled(false)
    end
end

function SurveyorScreen:updateOffset()
    if self.vehicle ~= nil then
        local spec = self.vehicle.spec_surveyor

        self.startOffsetText:setText(string.format('%.2fm', spec.startOffset))
        self.endOffsetText:setText(string.format('%.2fm', spec.endOffset))
    end
end

---@param cursorIsCalibrating boolean
function SurveyorScreen:drawCurrentCalibration(cursorIsCalibrating)
    if self.vehicle ~= nil then
        local offsetY = self.vehicle.spec_surveyor.offsetY

        g_modDebug:drawCalibration(self.startPosX, self.startPosY, self.startPosZ, self.startOffset, self.endPosX, self.endPosY, self.endPosZ, self.endOffset, offsetY, not cursorIsCalibrating)
    end
end

function SurveyorScreen:updateCalibration()
    if self.vehicle == nil then
        self.calibrationDisplay:setIsEnabled(false)
        return
    end

    self.calibrationDisplay:update(self.startPosX, self.startPosY, self.startPosZ, self.startOffset, self.endPosX, self.endPosY, self.endPosZ, self.endOffset)
end

function SurveyorScreen:updateCursorCalibration()
    if self.vehicle == nil then
        self.mouseCalibrationDisplay:setIsEnabled(false)
        return
    end

    local sourceX, sourceY, sourceZ = MachineUtils.getVehicleTerrainHeight(self.vehicle)
    local targetX, targetY, targetZ = self.cursor.currentHitX, self.cursor.currentHitY, self.cursor.currentHitZ

    ---@type Vehicle | nil
    local hitVehicle = nil

    if self.cursor.currentHitId ~= g_terrainNode then
        hitVehicle = self.cursor:getHitVehicle()

        if hitVehicle ~= nil then
            targetX, targetY, targetZ = MachineUtils.getVehicleTerrainHeight(hitVehicle)
        else
            self.mouseCalibrationDisplay:setIsEnabled(false)
            return
        end
    elseif not self.useTerrain then
        self.mouseCalibrationDisplay:setIsEnabled(false)
        return
    end

    self.mouseCalibrationDisplay:update(sourceX, sourceY, sourceZ, self.startOffset, targetX, targetY, targetZ, self.endOffset)
end

function SurveyorScreen:drawCursorCalibration()
    if self.vehicle == nil then
        return
    end

    local startPosX, startPosY, startPosZ = MachineUtils.getVehicleTerrainHeight(self.vehicle)
    local endPosX, endPosY, endPosZ = self.cursor.currentHitX, self.cursor.currentHitY, self.cursor.currentHitZ
    -- local distance = MachineUtils.getVector3Distance(startPosX, startPosY, startPosZ, endPosX, endPosY, endPosZ)

    -- if distance < 2 then
    --     return
    -- end

    ---@type Vehicle | nil
    local hitVehicle = nil

    if self.cursor.currentHitId ~= g_terrainNode then
        hitVehicle = self.cursor:getHitVehicle()

        if hitVehicle ~= nil then
            endPosX, endPosY, endPosZ = MachineUtils.getVehicleTerrainHeight(hitVehicle)
        else
            return
        end
    elseif not self.useTerrain then
        return
    end

    local terrainStartY = MachineUtils.getTerrainHeightAtPosition(startPosX, startPosZ)
    local terrainEndY = MachineUtils.getTerrainHeightAtPosition(endPosX, endPosZ)

    local terrainDiffStart = (startPosY + self.startOffset) - terrainStartY
    local terrainDiffEnd = (endPosY + self.endOffset) - terrainEndY

    self.cursorLine:setPosition(startPosX, startPosY + self.startOffset, startPosZ, endPosX, endPosY + self.endOffset, endPosZ)

    if terrainDiffStart < 0 then
        self.cursorMarkerSource:setPosition(startPosX, terrainStartY, startPosZ)
        self.lineStart:setIsVisible(false)

        if terrainDiffStart < 0.05 then
            -- Utils.renderTextAtWorldPosition(startPosX, terrainStartY + 0.25, startPosZ, string.format('%.2fm', terrainDiffStart), 0.012, nil, 1, 1, 1, 1)
            MachineUtils.renderTextAtWorldPosition(startPosX, terrainStartY - 0.5, startPosZ, string.format('%.2fm', terrainDiffStart), 0.015, nil, { 1, 1, 1, 1 })
        end
    else
        self.cursorMarkerSource:setPosition(startPosX, startPosY + self.startOffset, startPosZ)
        self.lineStart:setIsVisible(true)
        self.lineStart:setPosition(startPosX, terrainStartY, startPosZ, startPosX, startPosY + self.startOffset, startPosZ)
    end

    if terrainDiffEnd < 0 then
        self.cursorMarkerTarget:setPosition(endPosX, terrainEndY, endPosZ)
        self.lineEnd:setIsVisible(false)

        if terrainDiffEnd < 0.05 then
            MachineUtils.renderTextAtWorldPosition(endPosX, terrainEndY - 0.5, endPosZ, string.format('%.2fm', terrainDiffEnd), 0.015, nil, { 1, 1, 1, 1 })
            -- Utils.renderTextAtWorldPosition(endPosX, terrainEndY + 0.25, endPosZ, string.format('%.2fm', terrainDiffEnd), 0.012, nil, 1, 1, 1, 1)
        end
    else
        self.cursorMarkerTarget:setPosition(endPosX, endPosY + self.endOffset, endPosZ)
        self.lineEnd:setIsVisible(true)
        self.lineEnd:setPosition(endPosX, terrainEndY, endPosZ, endPosX, endPosY + self.endOffset, endPosZ)
    end


    -- local dx, _, dz, distance = MachineUtils.getVector3Direction(startPosX, startPosY, startPosZ, endPosX, terrainPosY, endPosZ)
    -- local rotY = math.atan2(dx, dz)
    -- local dy = terrainPosY - startPosY
    -- local dist2D = MathUtil.vector2Length(endPosX - startPosX, endPosZ - startPosZ)
    -- local rotX = -math.atan2(dy, dist2D)

    -- setScale(self.cursorLine, 1, 1, distance)
    -- setRotation(self.cursorLine, rotX, rotY, 0)

    -- if self.vehicle ~= nil then
    --     local startPosX, startPosY, startPosZ = MachineUtils.getVehicleTerrainHeight(self.vehicle)
    --     local endPosX, endPosY, endPosZ = self.cursor.currentHitX, self.cursor.currentHitY, self.cursor.currentHitZ
    --     local distance = MachineUtils.getVector3Distance(startPosX, startPosY, startPosZ, endPosX, endPosY, endPosZ)
    --     local offsetY = self.vehicle.spec_surveyor.offsetY

    --     if distance < 2 then
    --         return
    --     end

    --     ---@type Vehicle | nil
    --     local hitVehicle = nil

    --     if self.cursor.currentHitId ~= g_terrainNode then
    --         hitVehicle = self.cursor:getHitVehicle()

    --         if hitVehicle ~= nil then
    --             endPosX, endPosY, endPosZ = MachineUtils.getVehicleTerrainHeight(hitVehicle)
    --         else
    --             return
    --         end
    --     elseif not self.useTerrain then
    --         return
    --     end

    --     g_machineDebug:drawCalibration(startPosX, startPosY, startPosZ, self.startOffset, endPosX, endPosY, endPosZ, self.endOffset, offsetY, true)

    --     if hitVehicle ~= nil then
    --         Utils.renderTextAtWorldPosition(endPosX, endPosY + 2, endPosZ, hitVehicle:getFullName(), 0.016)
    --     end

    --     local textPosX, textPosY = self.cursor.mousePosX, self.cursor.mousePosY + 0.02
    --     local angle = MachineUtils.getAngleBetweenPoints(startPosX, startPosY, startPosZ, endPosX, endPosY, endPosZ)

    --     setTextBold(false)
    --     renderText(textPosX, textPosY, 0.014, string.format('Angle: %.2f', angle))
    -- end
end
