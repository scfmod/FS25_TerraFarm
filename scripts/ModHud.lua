source(g_modDirectory .. 'scripts/gui/elements/HUDMachineDisplayElement.lua')

---@class ModHud
---@field isDirty boolean
---@field display HUDMachineDisplayElement
---@field targetInputShape number
---@field targetOutputShape number
ModHud = {}

ModHud.XML_FILENAME = g_modDirectory .. 'data/gui/MachineHUD.xml'
ModHud.TARGET_SHAPES_FILENAME = g_modDirectory .. 'data/visualTarget.i3d'

ModHud.NODE_TEXT = '↓'
ModHud.NODE_TEXT_SIZE = getCorrectTextSize(0.01)
ModHud.NODE_COLOR = {
    DEFAULT = { 1, 0.3, 0, 1 },
    TERRAIN = { 1, 0, 0, 1 },
    INACTIVE = { 0.4, 0.4, 0.4, 1 },
    INACTIVE_TERRAIN = { 0.9, 0.3, 0.3, 1 }
}

local ModHud_mt = Class(ModHud)

---@return ModHud
---@nodiscard
function ModHud.new()
    ---@type ModHud
    local self = setmetatable({}, ModHud_mt)

    self.isDirty = false
    self.display = HUDMachineDisplayElement.new()

    self:loadShapes()

    g_modController:subscribe(ModEvent.onMapLoaded, self.onMapLoaded, self)

    return self
end

function ModHud:delete()
    g_messageCenter:unsubscribeAll(self)
    g_currentMission:removeDrawable(self)
    g_currentMission:removeUpdateable(self)

    self.display:delete()
    self.display = nil

    delete(self.targetInputShape)
    delete(self.targetOutputShape)
end

function ModHud:reload()
    self:delete()
    self.display = HUDMachineDisplayElement.new()
    self:load()
    self:loadShapes()
    self:activate()
    self.display:updateDisplay()
end

function ModHud:load()
    local xmlFile = XMLFile.load('machineHud', ModHud.XML_FILENAME)

    if xmlFile == nil then
        Logging.error('MachineHUD:loadHUD() Failed to load HUD file "%s"', ModHud.XML_FILENAME)
        return
    end

    g_gui.currentlyReloading = true

    self.display:loadFromXMLFile(xmlFile, 'HUD.BoxLayout')

    g_gui.currentlyReloading = false

    xmlFile:delete()
end

function ModHud:loadShapes()
    local i3dNode = g_i3DManager:loadI3DFile(ModHud.TARGET_SHAPES_FILENAME, false, false)

    if i3dNode ~= 0 then
        self.targetInputShape = getChildAt(i3dNode, 0)

        link(getRootNode(), self.targetInputShape)
        setVisibility(self.targetInputShape, false)

        self.targetOutputShape = clone(self.targetInputShape, true, false, false)

        delete(i3dNode)
    end
end

function ModHud:activate()
    g_messageCenter:subscribe(ModMessageType.SET_ACTIVE_MACHINE, self.onSetActiveMachine, self)
    g_messageCenter:subscribe(ModMessageType.LANDSCAPING_AREA_UPDATE, self.onAreaUpdated, self)
    g_messageCenter:subscribe(ModMessageType.LANDSCAPING_AREA_DELETE, self.onAreaUpdated, self)

    g_messageCenter:subscribe(SetMachineActiveEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetMachineEnabledEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetMachineFillTypeEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetMachineInputModeEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetMachineOutputModeEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetMachineInputLayerEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetMachineOutputLayerEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetMachineInputAreaIdEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetMachineOutputAreaIdEvent, self.onMachineUpdated, self)

    g_messageCenter:subscribe(SetMachineInputAreaEnabledEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetMachineOutputAreaEnabledEvent, self.onMachineUpdated, self)

    g_currentMission:addDrawable(self)
    g_currentMission:addUpdateable(self)
end

---@param vehicle Machine?
function ModHud:onSetActiveMachine(vehicle)
    self.display:updateDisplay()
end

---@param vehicle Machine?
function ModHud:onMachineUpdated(vehicle)
    local activeVehicle = g_machineManager.activeVehicle

    if activeVehicle ~= nil and activeVehicle == vehicle then
        self.isDirty = true
    end
end

---@param areaOrUniqueId? string | LandscapingArea
function ModHud:onAreaUpdated(areaOrUniqueId)
    self.isDirty = true
end

function ModHud:onMapLoaded()
    if g_client ~= nil then
        self:activate()
    end
end

function ModHud:draw()
    local activeVehicle = g_machineManager.activeVehicle

    if activeVehicle ~= nil and g_modSettings:getIsEnabled() and activeVehicle:getMachineEnabled() then
        self.display:draw()

        if g_modSettings:getDebugNodes() then
            self:drawInputNodes(activeVehicle)
            self:drawOutputNode(activeVehicle)
        end
    end
end

---@private
---@param vehicle Machine
function ModHud:drawInputNodes(vehicle)
    local workArea = vehicle.spec_machine.workArea

    for _, node in ipairs(workArea.areaNodes) do
        self:drawInputNode(node, vehicle)
    end
end

---@private
---@param node number
---@param vehicle Machine
function ModHud:drawInputNode(node, vehicle)
    local workArea = vehicle.spec_machine.workArea

    local color = ModHud.NODE_COLOR.DEFAULT
    local position = workArea.areaNodePosition[node]
    local isActive = workArea.areaNodeActive[node]

    if isActive then
        if vehicle:getMachineActive() then
            color = ModHud.NODE_COLOR.TERRAIN
        else
            color = ModHud.NODE_COLOR.INACTIVE_TERRAIN
        end
    elseif not vehicle:getMachineActive() then
        color = ModHud.NODE_COLOR.INACTIVE
    end

    ModUtils.renderTextAtWorldPosition(
        position[1], position[2], position[3],
        ModHud.NODE_TEXT, ModHud.NODE_TEXT_SIZE, 0, color, true
    )
end

---@private
---@param vehicle Machine
function ModHud:drawOutputNode(vehicle)
    local workArea = vehicle.spec_machine.workArea

    if workArea.outputNode ~= nil then
        local position = workArea.outputNodePosition
        local color = ModHud.NODE_COLOR.DEFAULT

        if workArea.outputNodeActive then
            if vehicle:getMachineActive() then
                color = ModHud.NODE_COLOR.TERRAIN
            else
                color = ModHud.NODE_COLOR.INACTIVE_TERRAIN
            end
        elseif not vehicle:getMachineActive() then
            color = ModHud.NODE_COLOR.INACTIVE
        end

        ModUtils.renderTextAtWorldPosition(
            position[1], position[2], position[3],
            'X', ModHud.NODE_TEXT_SIZE, 0, color, true
        )
    end
end

---@param dt number
function ModHud:update(dt)
    if self.display ~= nil then
        if self.isDirty then
            self.display:updateDisplay()

            self.isDirty = false
        end

        self.display:update(dt)
    end

    local activeVehicle = g_machineManager.activeVehicle

    if activeVehicle ~= nil and g_modSettings:getIsEnabled() and activeVehicle:getMachineEnabled() then
        if g_modSettings:getDebugCalibration() and activeVehicle:getMachineActive() then
            self:updateTarget(true)
            return
        end
    end

    self:updateTarget(false)
end

---@param vehicle Machine
function ModHud:updateInputTarget(vehicle)
    local mode = vehicle:getInputMode()

    if MachineUtils.getHasInputs(vehicle) and (mode == Machine.MODE.LOWER or mode == Machine.MODE.FLATTEN) then
        local workArea = vehicle:getMachineWorkArea()

        local x, _, z = workArea:getPosition()
        local targetY = workArea:getInputTargetHeight()

        if targetY ~= nil then
            setWorldTranslation(self.targetInputShape, x, targetY, z)
            setVisibility(self.targetInputShape, true)
            return
        end
    end

    setVisibility(self.targetInputShape, false)
end

---@param vehicle Machine
function ModHud:updateOutputTarget(vehicle)
    local mode = vehicle:getOutputMode()

    if MachineUtils.getHasOutputs(vehicle) and (mode == Machine.MODE.RAISE or mode == Machine.MODE.FLATTEN) then
        local workArea = vehicle:getMachineWorkArea()

        local x, _, z = workArea:getOutputPosition()
        local targetY = workArea:getOutputTargetHeight()

        if targetY ~= nil then
            setWorldTranslation(self.targetOutputShape, x, targetY, z)
            setVisibility(self.targetOutputShape, true)
            return
        end
    end

    setVisibility(self.targetOutputShape, false)
end

---@param enabled boolean
function ModHud:updateTarget(enabled)
    local vehicle = g_machineManager.activeVehicle

    if enabled and vehicle ~= nil and g_gui.currentGui == nil then
        self:updateInputTarget(vehicle)
        self:updateOutputTarget(vehicle)
    else
        setVisibility(self.targetInputShape, false)
        setVisibility(self.targetOutputShape, false)
    end
end

function ModHud:updateTargetColor()
    -- TODO

    local r1, g1, b1 = 0.75, 0.75, 0.75
    local r2, g2, b2 = 0.75, 0.75, 0.75

    local inputArea, inputEnabled = g_landscapingManager:getActiveInputArea()
    local outputArea, outputEnabled = g_landscapingManager:getActiveOutputArea()

    if inputArea ~= nil then
        r1, g1, b1 = inputArea:getDisplayColor()
    end

    if outputArea ~= nil then
        r2, g2, b2 = outputArea:getDisplayColor()
    end

    setShaderParameter(self.targetInputShape, 'lineColor', r1, g1, b1, 0.5)
    setShaderParameter(self.targetOutputShape, 'lineColor', r2, g2, b2, 0.5)
end

---@diagnostic disable-next-line: lowercase-global
g_modHud = ModHud.new()
