source(g_modDirectory .. 'scripts/hud/elements/HUDMachineDisplayElement.lua')

---@class ModHud
---@field vehicle Machine | nil
---@field isDirty boolean
---@field display HUDMachineDisplayElement
ModHud = {}

ModHud.XML_FILENAME = g_modDirectory .. 'xml/gui/hud/MachineHUD.xml'

local ModHud_mt = Class(ModHud)

---@return ModHud
---@nodiscard
function ModHud.new()
    ---@type ModHud
    local self = setmetatable({}, ModHud_mt)

    self.isDirty = false
    self.display = HUDMachineDisplayElement.new()

    return self
end

function ModHud:delete()
    g_messageCenter:unsubscribeAll(self)
    g_currentMission:removeDrawable(self)
    g_currentMission:removeUpdateable(self)

    self.display:delete()
    self.display = nil
end

function ModHud:reload()
    self:delete()
    self.display = HUDMachineDisplayElement.new()
    self:load()
    self:activate()
    self.vehicle = g_machineManager:getActiveVehicle()
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

function ModHud:activate()
    g_messageCenter:subscribe(MessageType.ACTIVE_MACHINE_CHANGED, self.onActiveMachineChanged, self)

    g_messageCenter:subscribe(SetMachineActiveEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetMachineEnabledEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetMachineFillTypeEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetMachineInputModeEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetMachineOutputModeEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetMachineTerrainLayerEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetMachineSurveyorEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetSurveyorCoordinatesEvent, self.onSurveyorChanged, self)

    g_currentMission:addDrawable(self)
    g_currentMission:addUpdateable(self)
end

---@param surveyor Surveyor
function ModHud:onSurveyorChanged(surveyor)
    if self.vehicle ~= nil then
        local surveyorId = self.vehicle:getSurveyorId()

        if surveyorId ~= nil and surveyorId == surveyor:getSurveyorId() then
            self.isDirty = true
        end
    end
end

---@param vehicle Machine | nil
function ModHud:onActiveMachineChanged(vehicle)
    self.vehicle = vehicle
    self.display:updateDisplay()
end

---@param vehicle Machine | nil
function ModHud:onMachineUpdated(vehicle)
    if self.vehicle ~= nil and self.vehicle == vehicle then
        self.isDirty = true
    end
end

function ModHud:onMapLoaded()
    if g_client ~= nil then
        self:activate()
    end
end

function ModHud:draw()
    if self.vehicle ~= nil and g_modSettings:getIsEnabled() and self.vehicle:getMachineEnabled() then
        self.display:draw()
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
end

---@diagnostic disable-next-line: lowercase-global
g_modHud = ModHud.new()
