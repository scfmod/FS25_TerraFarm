source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineActiveEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineEnabledEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineFillTypeEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineInputModeEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineOutputModeEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineResourcesEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineStateEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineSurveyorEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineTerrainLayerEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineDischargeTerrainLayerEvent.lua')

---@class Machine : Vehicle, FillUnit, FillVolume, TurnOnVehicle, Cylindered, Enterable, Dischargeable, Shovel
---@field spec_attachable AttachableSpecialization
---@field spec_dischargeable DischargeableSpecialization
---@field spec_fillUnit FillUnitSpecialization
---@field spec_leveler LevelerSpecialization
---@field spec_shovel ShovelSpecialization
---@field spec_trailer TrailerSpecialization
---@field spec_machine SpecializationProperties
Machine = {}

Machine.MOD_NAME = g_currentModName
Machine.MOD_FOLDER = g_currentModDirectory
Machine.MOD_SETTINGS_FOLDER = g_currentModSettingsDirectory
Machine.MOD_CONFIGURATIONS_FILE = g_currentModDirectory .. 'xml/machines/index.xml'
Machine.SPEC_NAME = string.format('spec_%s.machine', g_currentModName)
Machine.DEFAULT_FILLTYPE = 'STONE'
Machine.DEFAULT_TERRAIN_LAYERS = {
    'DIRT',
    'GRAVEL'
}
---@enum MachineMode
Machine.MODE = {
    MATERIAL = 0,
    RAISE = 1,
    LOWER = 2,
    SMOOTH = 3,
    FLATTEN = 4,
    PAINT = 5
}

Machine.NUM_BITS_MODE = 3

Machine.FILLUNIT_UNKNOWN = 0
Machine.FILLUNIT_VEHICLE = 1
Machine.FILLUNIT_ROOT_VEHICLE = 2
Machine.FILLUNIT_NOT_FOUND = 3

---@enum FillUnitSourceType
Machine.FILLUNIT_SOURCE = {
    VEHICLE = 0,
    ROOT_VEHICLE = 1
}

Machine.L10N_ACTION_ACTIVATE = g_i18n:getText('ui_machineActivate')
Machine.L10N_ACTION_DEACTIVATE = g_i18n:getText('ui_machineDeactivate')
Machine.L10N_ACTION_TOGGLE_INPUT = g_i18n:getText('ui_machineToggleInput')
Machine.L10N_ACTION_TOGGLE_OUTPUT = g_i18n:getText('ui_machineToggleOutput')
Machine.L10N_ACTION_MACHINE_SETTINGS = g_i18n:getText('ui_machineSettings')
Machine.L10N_ACTION_SELECT_MATERIAL = g_i18n:getText('ui_changeMaterial')
Machine.L10N_ACTION_SELECT_GROUND_TEXTURE = g_i18n:getText('ui_changeTexture')
Machine.L10N_ACTION_SELECT_DISCHARGE_GROUND_TEXTURE = g_i18n:getText('ui_changeDischargeTexture')
Machine.L10N_ACTION_SELECT_SURVEYOR = g_i18n:getText('ui_selectSurveyor')
Machine.L10N_ACTION_GLOBAL_SETTINGS = g_i18n:getText('ui_globalSettings')
Machine.L10N_ACTION_TOGGLE_HUD = g_i18n:getText('ui_toggleHud')

Machine.ACTION_TOGGLE_ACTIVE = 'MACHINE_TOGGLE_ACTIVE'
Machine.ACTION_TOGGLE_INPUT = 'MACHINE_TOGGLE_INPUT'
Machine.ACTION_TOGGLE_OUTPUT = 'MACHINE_TOGGLE_OUTPUT'
Machine.ACTION_SETTINGS = 'MACHINE_SETTINGS'
Machine.ACTION_SELECT_MATERIAL = 'MACHINE_SELECT_MATERIAL'
Machine.ACTION_SELECT_TEXTURE = 'MACHINE_SELECT_TEXTURE'
Machine.ACTION_SELECT_DISCHARGE_TEXTURE = 'MACHINE_SELECT_DISCHARGE_TEXTURE'
Machine.ACTION_SELECT_SURVEYOR = 'MACHINE_SELECT_SURVEYOR'
Machine.ACTION_GLOBAL_SETTINGS = 'MACHINE_GLOBAL_SETTINGS'
Machine.ACTION_TOGGLE_HUD = 'MACHINE_TOGGLE_HUD'

---@type table<MachineMode, string>
Machine.MODE_ICON_SLICE_ID = {
    [Machine.MODE.MATERIAL] = 'terraFarm.mode_material',
    [Machine.MODE.RAISE] = 'terraFarm.mode_raise',
    [Machine.MODE.LOWER] = 'terraFarm.mode_lower',
    [Machine.MODE.SMOOTH] = 'terraFarm.mode_smooth',
    [Machine.MODE.FLATTEN] = 'terraFarm.mode_grade',
    [Machine.MODE.PAINT] = 'terraFarm.mode_paint',
}

---@type table<MachineMode, string>
Machine.L10N_MODE = {
    [Machine.MODE.MATERIAL] = g_i18n:getText('ui_modeMaterial'),
    [Machine.MODE.RAISE] = g_i18n:getText('ui_raise'),
    [Machine.MODE.LOWER] = g_i18n:getText('ui_modeLower'),
    [Machine.MODE.SMOOTH] = g_i18n:getText('ui_modeSmooth'),
    [Machine.MODE.FLATTEN] = g_i18n:getText('ui_modeFlatten'),
    [Machine.MODE.PAINT] = g_i18n:getText('ui_modePaint'),
}

---@type table<MachineMode, string>
Machine.STR_MODE = {
    [Machine.MODE.MATERIAL] = 'MATERIAL',
    [Machine.MODE.RAISE] = 'RAISE',
    [Machine.MODE.LOWER] = 'LOWER',
    [Machine.MODE.SMOOTH] = 'SMOOTH',
    [Machine.MODE.FLATTEN] = 'FLATTEN',
    [Machine.MODE.PAINT] = 'PAINT',
}

---@param schema XMLSchema
---@param key string
function Machine.registerXMLPaths(schema, key)
    schema:setXMLSpecializationType('Machine')

    schema:register(XMLValueType.STRING, key .. '#type', 'Machine type name', nil, true)
    schema:register(XMLValueType.BOOL, key .. '#requireTurnedOn', 'Require vehicle to be turned on to function', true)
    schema:register(XMLValueType.BOOL, key .. '#requirePoweredOn', 'Require vehicle to be powered on to function', true)

    schema:register(XMLValueType.STRING, key .. '#fillUnitSource', 'Fill unit source', 'VEHICLE')
    schema:register(XMLValueType.INT, key .. '#fillUnitIndex', 'Fill unit index')

    schema:register(XMLValueType.INT, key .. '#levelerNodeIndex', '', 1)
    schema:register(XMLValueType.INT, key .. '#shovelNodeIndex', '', 1)
    schema:register(XMLValueType.INT, key .. '#dischargeNodeIndex')

    schema:register(XMLValueType.STRING, key .. '.input#modes')
    schema:register(XMLValueType.STRING, key .. '.output#modes')

    MachineWorkArea.registerXMLPaths(schema, key .. '.workArea')

    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, key .. ".stateObjectChanges")

    schema:register(XMLValueType.BOOL, key .. '#playSound', 'Play work sound', true)
    SoundManager.registerSampleXMLPaths(schema, key, 'workSound')

    schema:register(XMLValueType.FLOAT, key .. '.effects#effectTurnOffThreshold', '', 0.25)
    EffectManager.registerEffectXMLPaths(schema, key .. '.effects')
    AnimationManager.registerAnimationNodesXMLPaths(schema, key .. '.effectAnimations')

    schema:setXMLSpecializationType()
end

---@param schema XMLSchema
---@param key string
function Machine.registerSavegameXMLPaths(schema, key)
    schema:setXMLSpecializationType('Machine')

    schema:register(XMLValueType.BOOL, key .. '#enabled')
    schema:register(XMLValueType.BOOL, key .. '#resourcesEnabled')
    schema:register(XMLValueType.STRING, key .. '#surveyorId')
    schema:register(XMLValueType.STRING, key .. '#fillType')
    schema:register(XMLValueType.STRING, key .. '#terrainLayer')
    schema:register(XMLValueType.STRING, key .. '#dischargeTerrainLayer')
    schema:register(XMLValueType.STRING, key .. '#inputMode')
    schema:register(XMLValueType.STRING, key .. '#outputMode')

    MachineState.registerSavegameXMLPaths(schema, key .. '.state')

    schema:setXMLSpecializationType()
end

---@return boolean
function Machine.prerequisitesPresent()
    return true
end

---@param vehicleType table
function Machine.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, 'onLoad', Machine)
    SpecializationUtil.registerEventListener(vehicleType, 'onPostLoad', Machine)
    SpecializationUtil.registerEventListener(vehicleType, 'onDelete', Machine)
    SpecializationUtil.registerEventListener(vehicleType, 'onUpdate', Machine)
    SpecializationUtil.registerEventListener(vehicleType, 'onUpdateTick', Machine)

    SpecializationUtil.registerEventListener(vehicleType, 'onRegisterActionEvents', Machine)

    SpecializationUtil.registerEventListener(vehicleType, 'onWriteStream', Machine)
    SpecializationUtil.registerEventListener(vehicleType, 'onReadStream', Machine)
    SpecializationUtil.registerEventListener(vehicleType, 'onWriteUpdateStream', Machine)
    SpecializationUtil.registerEventListener(vehicleType, 'onReadUpdateStream', Machine)
end

---@param vehicleType table
function Machine.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, 'setMachineState', Machine.setMachineState)
    SpecializationUtil.registerFunction(vehicleType, 'getMachineState', Machine.getMachineState)

    SpecializationUtil.registerFunction(vehicleType, 'setMachineEnabled', Machine.setMachineEnabled)
    SpecializationUtil.registerFunction(vehicleType, 'getMachineEnabled', Machine.getMachineEnabled)
    SpecializationUtil.registerFunction(vehicleType, 'setMachineActive', Machine.setMachineActive)
    SpecializationUtil.registerFunction(vehicleType, 'getMachineActive', Machine.getMachineActive)
    SpecializationUtil.registerFunction(vehicleType, 'setMachineEffectActive', Machine.setMachineEffectActive)
    SpecializationUtil.registerFunction(vehicleType, 'updateMachineSound', Machine.updateMachineSound)

    SpecializationUtil.registerFunction(vehicleType, 'setInputMode', Machine.setInputMode)
    SpecializationUtil.registerFunction(vehicleType, 'getInputMode', Machine.getInputMode)
    SpecializationUtil.registerFunction(vehicleType, 'setOutputMode', Machine.setOutputMode)
    SpecializationUtil.registerFunction(vehicleType, 'getOutputMode', Machine.getOutputMode)

    SpecializationUtil.registerFunction(vehicleType, 'setMachineFillTypeIndex', Machine.setMachineFillTypeIndex)
    SpecializationUtil.registerFunction(vehicleType, 'getMachineFillTypeIndex', Machine.getMachineFillTypeIndex)

    SpecializationUtil.registerFunction(vehicleType, 'setMachineTerrainLayerId', Machine.setMachineTerrainLayerId)
    SpecializationUtil.registerFunction(vehicleType, 'getMachineTerrainLayerId', Machine.getMachineTerrainLayerId)

    SpecializationUtil.registerFunction(vehicleType, 'setMachineDischargeTerrainLayerId', Machine.setMachineDischargeTerrainLayerId)
    SpecializationUtil.registerFunction(vehicleType, 'getMachineDichargeTerrainLayerId', Machine.getMachineDischargeTerrainLayerId)

    SpecializationUtil.registerFunction(vehicleType, 'getCanAccessMachine', Machine.getCanAccessMachine)
    SpecializationUtil.registerFunction(vehicleType, 'getCanActivateMachine', Machine.getCanActivateMachine)
    SpecializationUtil.registerFunction(vehicleType, 'getIsAvailable', Machine.getIsAvailable)
    SpecializationUtil.registerFunction(vehicleType, 'getIsEmpty', Machine.getIsEmpty)
    SpecializationUtil.registerFunction(vehicleType, 'getIsFull', Machine.getIsFull)

    SpecializationUtil.registerFunction(vehicleType, 'updateWorkArea', Machine.updateWorkArea)
    SpecializationUtil.registerFunction(vehicleType, 'workAreaInput', Machine.workAreaInput)
    SpecializationUtil.registerFunction(vehicleType, 'setResourcesEnabled', Machine.setResourcesEnabled)

    SpecializationUtil.registerFunction(vehicleType, 'setSurveyorId', Machine.setSurveyorId)
    SpecializationUtil.registerFunction(vehicleType, 'getSurveyorId', Machine.getSurveyorId)
    SpecializationUtil.registerFunction(vehicleType, 'getSurveyor', Machine.getSurveyor)
    SpecializationUtil.registerFunction(vehicleType, 'getSurveyorCalibration', Machine.getSurveyorCalibration)
end

function Machine.initSpecialization()
    g_storeManager:addSpecType('machine', 'tf_shopListAttributeIconMachine', Machine.loadSpecValue, Machine.getSpecValue)

    Machine.registerXMLPaths(Vehicle.xmlSchema, 'vehicle.machine')
    Machine.registerSavegameXMLPaths(Vehicle.xmlSchemaSavegame, string.format('vehicles.vehicle(?).%s.machine', Machine.MOD_NAME))
end

---@param xmlFile XMLFile
---@param customEnvironment string | nil
---@param baseDir string
function Machine.loadSpecValue(xmlFile, customEnvironment, baseDir)
    local rootName = xmlFile:getRootName()

    if rootName == 'vehicle' then
        local machineTypeId = xmlFile:getValue('vehicle.machine#type')

        if xmlFile:hasProperty('vehicle.machine.input#modes') then
            local machineType = g_machineManager:getMachineTypeById(machineTypeId)

            if machineType ~= nil then
                return {
                    machineType = machineType
                }
            end
        end
    end
end

---@param storeItem StoreItem
---@param realItem any
---@param configurations any
---@param saleItem any
---@param returnValues any
---@param returnRange any
---@return string | nil
function Machine.getSpecValue(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
    if storeItem ~= nil and storeItem.specs ~= nil and storeItem.specs.machine ~= nil then
        ---@type MachineType | nil
        local machineType = storeItem.specs.machine.machineType

        if machineType ~= nil then
            return g_i18n:getText('displayItem_machine')
        end
    end
end

function Machine:onLoad()
    ---@type SpecializationProperties
    local spec = self[Machine.SPEC_NAME]

    ---@type XMLFile
    local xmlFile = self.xmlFile

    if spec.isExternal then
        local xmlFileExternal = XMLFile.loadIfExists('machineConfiguration', spec.xmlFilenameConfig, Vehicle.xmlSchema)

        if xmlFileExternal ~= nil then
            xmlFile = xmlFileExternal
        else
            Logging.error('Failed to load machine configuration file: %s', tostring(spec.xmlFilenameConfig))
            return false
        end
    else
        spec.isExternal = false
    end

    self.spec_machine = spec

    spec.dirtyFlagEffect = self:getNextDirtyFlag()
    spec.machineTypeId = xmlFile:getValue('vehicle.machine#type')
    spec.machineType = g_machineManager:getMachineTypeById(spec.machineTypeId)

    if spec.machineType == nil then
        Logging.error('Invalid machine type name: %s', tostring(spec.machineTypeId))

        if spec.isExternal then
            xmlFile:delete()
        end

        return false
    end

    spec.surveyorId = nil
    spec.enabled = g_modSettings:getDefaultEnabled()
    spec.resourcesEnabled = true
    spec.active = false
    spec.updateInterval = 50
    spec.lastIntervalUpdate = 0
    spec.state = MachineState.new()

    spec.inputMode = Machine.MODE.MATERIAL
    spec.outputMode = Machine.MODE.MATERIAL

    spec.terrainLayerId = g_resourceManager:getDefaultTerrainLayerId()
    spec.dischargeTerrainLayerId = g_resourceManager:getDefaultTerrainLayerId()
    spec.fillTypeIndex = g_resourceManager:getDefaultFillTypeIndex()

    spec.hasAttachable = SpecializationUtil.hasSpecialization(Attachable, self.specializations)
    spec.hasDischargeable = SpecializationUtil.hasSpecialization(Dischargeable, self.specializations)
    spec.hasDrivable = SpecializationUtil.hasSpecialization(Drivable, self.specializations)
    spec.hasEnterable = SpecializationUtil.hasSpecialization(Enterable, self.specializations)
    spec.hasFillUnit = SpecializationUtil.hasSpecialization(FillUnit, self.specializations)
    spec.hasLeveler = SpecializationUtil.hasSpecialization(Leveler, self.specializations)
    spec.hasMotorized = SpecializationUtil.hasSpecialization(Motorized, self.specializations)
    spec.hasShovel = SpecializationUtil.hasSpecialization(Shovel, self.specializations)
    spec.hasTurnOnVehicle = SpecializationUtil.hasSpecialization(TurnOnVehicle, self.specializations)
    spec.hasTrailer = SpecializationUtil.hasSpecialization(Trailer, self.specializations)

    if spec.machineType.useFillUnit then
        spec.fillUnitSource = Machine.FILLUNIT_SOURCE[xmlFile:getValue('vehicle.machine#fillUnitSource')] or Machine.FILLUNIT_SOURCE.VEHICLE
    end

    if spec.hasAttachable then
        SpecializationUtil.registerEventListener(self, 'onPostAttach', Machine)
        SpecializationUtil.registerEventListener(self, 'onPostDetach', Machine)
        SpecializationUtil.registerEventListener(self, 'onLeaveRootVehicle', Machine)
    end

    if spec.hasDischargeable and #self.spec_dischargeable.dischargeNodes > 0 then
        self.getCanDischargeToGround = Utils.overwrittenFunction(self.getCanDischargeToGround, Machine.getCanDischargeToGround)

        if MachineUtils.getIsDischargeable(self) then
            self.discharge = Utils.overwrittenFunction(self.discharge, Machine.discharge)
        end

        if spec.machineType.useDischargeable then
            local dischargeNodeIndex = xmlFile:getValue('vehicle.machine#dischargeNodeIndex')

            if dischargeNodeIndex == nil and not spec.hasShovel and spec.hasTrailer then
                local tipSide = self.spec_trailer.tipSides[1]

                if tipSide ~= nil then
                    spec.dischargeNode = self.spec_dischargeable.dischargeNodes[tipSide.dischargeNodeIndex]
                else
                    spec.dischargeNode = self.spec_dischargeable.dischargeNodes[1]
                end

                if spec.dischargeNode ~= nil then
                    spec.fillUnitIndex = spec.dischargeNode.fillUnitIndex
                end
            else
                spec.dischargeNode = self.spec_dischargeable.dischargeNodes[dischargeNodeIndex]
            end
        end
    end

    if spec.hasEnterable then
        SpecializationUtil.registerEventListener(self, 'onLeaveVehicle', Machine)
    end

    if spec.hasLeveler and spec.machineType.useLeveler and #self.spec_leveler.nodes > 0 then
        local levelerNodeIndex = xmlFile:getValue('vehicle.machine#levelerNodeIndex', 1)

        spec.levelerNode = self.spec_leveler.nodes[levelerNodeIndex]

        if spec.machineType.useFillUnit and spec.fillUnitSource == Machine.FILLUNIT_SOURCE.VEHICLE and spec.levelerNode ~= nil and spec.levelerNode.fillUnitIndex ~= nil and spec.fillUnitIndex ~= spec.levelerNode.fillUnitIndex then
            spec.fillUnitIndex = spec.levelerNode.fillUnitIndex
        end
    end

    if spec.hasMotorized then
        SpecializationUtil.registerEventListener(self, 'onStartMotor', Machine)
        SpecializationUtil.registerEventListener(self, 'onStopMotor', Machine)
    end

    if spec.hasShovel and spec.machineType.useShovel and #self.spec_shovel.shovelNodes > 0 then
        local shovelNodeIndex = xmlFile:getValue('vehicle.machine#shovelNodeIndex', 1)

        spec.shovelNode = self.spec_shovel.shovelNodes[shovelNodeIndex]

        if spec.machineType.useFillUnit and spec.fillUnitSource == Machine.FILLUNIT_SOURCE.VEHICLE and spec.shovelNode ~= nil and spec.shovelNode.fillUnitIndex ~= nil and spec.fillUnitIndex ~= spec.shovelNode.fillUnitIndex then
            spec.fillUnitIndex = spec.shovelNode.fillUnitIndex
        end

        if spec.hasDischargeable and spec.dischargeNode == nil then
            local dischargeNodeIndex = self.spec_shovel.shovelDischargeInfo.dischargeNodeIndex

            spec.dischargeNode = self.spec_dischargeable.dischargeNodes[dischargeNodeIndex]
        end
    end

    if spec.hasTurnOnVehicle then
        SpecializationUtil.registerEventListener(self, 'onTurnedOn', Machine)
        SpecializationUtil.registerEventListener(self, 'onTurnedOff', Machine)
    end

    if spec.machineType.useFillUnit and spec.fillUnitIndex == nil and spec.fillUnitSource == Machine.FILLUNIT_SOURCE.VEHICLE then
        if spec.hasFillUnit then
            if xmlFile:hasProperty('vehicle.machine#fillUnitIndex') then
                spec.fillUnitIndex = xmlFile:getValue('vehicle.machine#fillUnitIndex')
            end
        else
            Logging.xmlWarning(xmlFile, 'Missing fillUnit specialization')
        end
    end

    if spec.fillUnitIndex ~= nil and spec.fillUnitSource == Machine.FILLUNIT_SOURCE.VEHICLE then
        spec.fillUnit = self:getFillUnitByIndex(spec.fillUnitIndex)

        if spec.fillUnit == nil then
            Logging.xmlWarning(xmlFile, 'Unable to find fillUnit index: %i', spec.fillUnitIndex)
        elseif spec.dischargeNode == nil and spec.machineType.useDischargeable and spec.hasDischargeable then
            spec.dischargeNode = self.spec_dischargeable.fillUnitDischargeNodeMapping[spec.fillUnit.fillUnitIndex]
        end
    end

    spec.requirePoweredOn = xmlFile:getValue('vehicle.machine#requirePoweredOn', true) and spec.hasMotorized
    spec.requireTurnedOn = xmlFile:getValue('vehicle.machine#requireTurnedOn', true) and spec.hasTurnOnVehicle

    spec.modesInput = MachineUtils.loadMachineModesFromXML(xmlFile, 'vehicle.machine.input#modes')
    spec.modesOutput = {}

    if MachineUtils.getIsDischargeable(self) then
        table.insert(spec.modesOutput, Machine.MODE.MATERIAL)
        table.insert(spec.modesOutput, Machine.MODE.RAISE)
        table.insert(spec.modesOutput, Machine.MODE.FLATTEN)
        table.insert(spec.modesOutput, Machine.MODE.SMOOTH)
        table.insert(spec.modesOutput, Machine.MODE.PAINT)

        if MachineUtils.getIsShovel(self) and not MachineUtils.getHasInputMode(self, Machine.MODE.MATERIAL) then
            table.insert(spec.modesInput, Machine.MODE.MATERIAL)
        end
    end

    spec.effectTurnOffThreshold = xmlFile:getValue('vehicle.machine.effects#effectTurnOffThreshold', 0.25)
    spec.effects = g_effectManager:loadEffect(xmlFile, 'vehicle.machine.effects', self.components, self, self.i3dMappings)

    spec.lastEffect = spec.effects[#spec.effects]
    spec.isEffectActive = false
    spec.isEffectActiveSent = false

    for _, effect in ipairs(spec.effects) do
        if effect.setFillType ~= nil then
            effect:setFillType(spec.fillTypeIndex)
        end
    end

    spec.stateObjectChanges = {}

    ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, 'vehicle.machine.stateObjectChanges', spec.stateObjectChanges, self.components, self)

    if #spec.stateObjectChanges == 0 then
        spec.stateObjectChanges = nil
    else
        ObjectChangeUtil.setObjectChanges(spec.stateObjectChanges, false)
    end

    if self.isClient then
        spec.effectAnimationNodes = g_animationManager:loadAnimations(self.xmlFile, 'vehicle.machine.effectAnimations', self.components, self, self.i3dMappings)
        spec.playSound = xmlFile:getValue('vehicle.machine#playSound', true)

        if #spec.effects > 0 and spec.playSound then
            spec.sample = g_soundManager:loadSampleFromXML(self.xmlFile, 'vehicle.machine', 'workSound', self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        end

        if spec.sample == nil then
            spec.playSound = false
        end
    end

    spec.workArea = MachineWorkArea.new(self)
    spec.workArea:loadFromXMLFile(xmlFile, 'vehicle.machine.workArea')
    spec.workArea:initialize()

    if spec.isExternal then
        xmlFile:delete()
    end
end

---@param savegame SavegameObject | nil
function Machine:onPostLoad(savegame)
    local spec = self.spec_machine

    if self.isServer then
        if savegame ~= nil and savegame.xmlFile.filename ~= nil then
            local key = savegame.key .. '.' .. Machine.MOD_NAME .. '.machine'

            Machine.loadFromXMLFile(self, savegame.xmlFile, key)

            if spec.machineType.id == 'leveler' and spec.fillUnit ~= nil then
                spec.fillUnit.fillLevel = 0
            end
        end

        if #spec.modesInput > 0 and not table.hasElement(spec.modesInput, spec.inputMode) then
            self:setInputMode(spec.modesInput[1], true)
        end

        if #spec.modesOutput > 0 and not table.hasElement(spec.modesOutput, spec.outputMode) then
            self:setOutputMode(spec.modesOutput[1], true)
        end
    end

    if self.propertyState ~= 5 then
        g_machineManager:registerVehicle(self)
        g_messageCenter:subscribe(MessageType.SURVEYOR_REMOVED, Machine.onSurveyorRemoved, self)
        g_messageCenter:subscribe(MessageType.MASTERUSER_ADDED, Machine.onMasterUserAdded, self)
        g_messageCenter:subscribe(PlayerPermissionsEvent, Machine.onPlayerPermissionsChanged, self)
    end
end

function Machine:onDelete()
    local spec = self.spec_machine

    g_effectManager:deleteEffects(spec.effects)
    g_soundManager:deleteSample(spec.sample)
    g_animationManager:deleteAnimations(spec.effectAnimationNodes)

    spec.effects = {}
    spec.sample = nil
    spec.effectAnimationNodes = {}
    spec.dischargeNode = nil
    spec.levelerNode = nil
    spec.shovelNode = nil

    spec.fillUnit = nil
    spec.fillType = nil

    g_machineManager:unregisterVehicle(self)
end

---@param xmlFile XMLFile
---@param key string
function Machine:saveToXMLFile(xmlFile, key)
    local spec = self.spec_machine

    xmlFile:setValue(key .. '#enabled', spec.enabled)
    xmlFile:setValue(key .. '#resourcesEnabled', spec.resourcesEnabled)
    xmlFile:setValue(key .. '#inputMode', Machine.STR_MODE[spec.inputMode])
    xmlFile:setValue(key .. '#outputMode', Machine.STR_MODE[spec.outputMode])

    if self:getSurveyor() ~= nil then
        xmlFile:setValue(key .. '#surveyorId', spec.surveyorId)
    end

    ---@type FillTypeObject | nil
    local fillType = g_fillTypeManager:getFillTypeByIndex(spec.fillTypeIndex)

    if fillType ~= nil then
        xmlFile:setValue(key .. '#fillType', fillType.name)
    end

    if spec.terrainLayerId ~= nil then
        local layerName = getTerrainLayerName(g_terrainNode, spec.terrainLayerId)

        if layerName ~= nil then
            xmlFile:setValue(key .. '#terrainLayer', layerName)
        end
    end

    if spec.dischargeTerrainLayerId ~= nil then
        local layerName = getTerrainLayerName(g_terrainNode, spec.dischargeTerrainLayerId)

        if layerName ~= nil then
            xmlFile:setValue(key .. '#dischargeTerrainLayer', layerName)
        end
    end

    spec.state:saveToXMLFile(xmlFile, key .. '.state')
end

---@param xmlFile XMLFile
---@param key string
function Machine:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_machine

    self:setSurveyorId(xmlFile:getValue(key .. '#surveyorId', spec.surveyorId), true)
    self:setMachineEnabled(xmlFile:getValue(key .. '#enabled', spec.enabled), true)
    self:setResourcesEnabled(xmlFile:getValue(key .. '#resourcesEnabled', spec.resourcesEnabled), true)

    local inputModeStr = xmlFile:getValue(key .. '#inputMode')

    if inputModeStr ~= nil and Machine.MODE[inputModeStr] ~= nil then
        self:setInputMode(Machine.MODE[inputModeStr], true)
    end

    local outputModeStr = xmlFile:getValue(key .. '#outputMode')

    if outputModeStr ~= nil and Machine.MODE[outputModeStr] ~= nil then
        self:setOutputMode(Machine.MODE[outputModeStr], true)
    end

    local fillTypeName = xmlFile:getValue(key .. '#fillType')

    if fillTypeName ~= nil then
        ---@type FillTypeObject | nil
        local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName)

        if fillType ~= nil then
            self:setMachineFillTypeIndex(fillType.index, true)
        end
    end

    local terrainLayerName = xmlFile:getValue(key .. '#terrainLayer')

    if terrainLayerName ~= nil then
        local layer = g_resourceManager:getTerrainLayerByName(terrainLayerName)

        if layer ~= nil then
            self:setMachineTerrainLayerId(layer.id, true)
        end
    end

    local dischargeTerrainLayerName = xmlFile:getValue(key .. '#dischargeTerrainLayer')

    if dischargeTerrainLayerName ~= nil then
        local layer = g_resourceManager:getTerrainLayerByName(dischargeTerrainLayerName)

        if layer ~= nil then
            self:setMachineDischargeTerrainLayerId(layer.id, true)
        end
    end

    spec.state:loadFromXMLFile(xmlFile, key .. '.state')
end

---@param enabled boolean
---@param noEventSend boolean | nil
function Machine:setMachineEnabled(enabled, noEventSend)
    local spec = self.spec_machine

    if spec.enabled ~= enabled then
        SetMachineEnabledEvent.sendEvent(self, enabled, noEventSend)

        spec.enabled = enabled

        if self.isServer and not enabled then
            self:setMachineActive(false)
        end

        g_messageCenter:publish(SetMachineEnabledEvent, self, enabled)
    end
end

---@return boolean
---@nodiscard
function Machine:getMachineEnabled()
    return self.spec_machine.enabled
end

---@param active boolean
---@param noEventSend boolean | nil
function Machine:setMachineActive(active, noEventSend)
    local spec = self.spec_machine

    if spec.active ~= active then
        SetMachineActiveEvent.sendEvent(self, active, noEventSend)

        spec.active = active

        if self.isServer and not active then
            self:setMachineEffectActive(false)
        end

        if spec.stateObjectChanges ~= nil then
            ObjectChangeUtil.setObjectChanges(spec.stateObjectChanges, active)
        end

        self:requestActionEventUpdate()

        g_messageCenter:publish(SetMachineActiveEvent, self, active)
    end
end

---@return boolean
---@nodiscard
function Machine:getMachineActive()
    return self.spec_machine.active
end

function Machine:setMachineState(state, noEventSend)
    local spec = self.spec_machine

    if spec.state ~= state then
        SetMachineStateEvent.sendEvent(self, state, noEventSend)

        spec.state = state

        g_messageCenter:publish(SetMachineStateEvent, self, state)
    end
end

---@return MachineState
---@nodiscard
function Machine:getMachineState()
    return self.spec_machine.state
end

---@param enabled boolean
---@param noEventSend boolean | nil
function Machine:setResourcesEnabled(enabled, noEventSend)
    local spec = self.spec_machine

    if spec.resourcesEnabled ~= enabled then
        SetMachineResourcesEvent.sendEvent(self, enabled, noEventSend)

        spec.resourcesEnabled = enabled

        g_messageCenter:publish(SetMachineResourcesEvent, self, enabled)
    end
end

---@param mode MachineMode
---@param noEventSend boolean | nil
function Machine:setInputMode(mode, noEventSend)
    local spec = self.spec_machine

    if spec.inputMode ~= mode then
        SetMachineInputModeEvent.sendEvent(self, mode, noEventSend)

        spec.inputMode = mode

        g_messageCenter:publish(SetMachineInputModeEvent, self, mode)
    end
end

---@return MachineMode
---@nodiscard
function Machine:getInputMode()
    return self.spec_machine.inputMode
end

---@param mode MachineMode
---@param noEventSend boolean | nil
function Machine:setOutputMode(mode, noEventSend)
    local spec = self.spec_machine

    if spec.outputMode ~= mode then
        SetMachineOutputModeEvent.sendEvent(self, mode, noEventSend)

        spec.outputMode = mode

        g_messageCenter:publish(SetMachineOutputModeEvent, self, mode)
    end
end

---@return MachineMode
---@nodiscard
function Machine:getOutputMode()
    return self.spec_machine.outputMode
end

---@param fillTypeIndex number
---@param noEventSend boolean | nil
function Machine:setMachineFillTypeIndex(fillTypeIndex, noEventSend)
    local spec = self.spec_machine

    if spec.fillTypeIndex ~= fillTypeIndex then
        SetMachineFillTypeEvent.sendEvent(self, fillTypeIndex, noEventSend)

        spec.fillTypeIndex = fillTypeIndex

        g_messageCenter:publish(SetMachineFillTypeEvent, self, fillTypeIndex)

        for _, effect in ipairs(spec.effects) do
            if effect.setFillType ~= nil then
                effect:setFillType(fillTypeIndex)
            end
        end
    end
end

---@return number
---@nodiscard
function Machine:getMachineFillTypeIndex()
    return self.spec_machine.fillTypeIndex
end

---@param terrainLayerId number
---@param noEventSend boolean | nil
function Machine:setMachineTerrainLayerId(terrainLayerId, noEventSend)
    local spec = self.spec_machine

    if spec.terrainLayerId ~= terrainLayerId then
        SetMachineTerrainLayerEvent.sendEvent(self, terrainLayerId, noEventSend)

        spec.terrainLayerId = terrainLayerId

        g_messageCenter:publish(SetMachineTerrainLayerEvent, self, terrainLayerId)
    end
end

---@return number
---@nodiscard
function Machine:getMachineTerrainLayerId()
    return self.spec_machine.terrainLayerId
end

---@param terrainLayerId number
---@param noEventSend boolean | nil
function Machine:setMachineDischargeTerrainLayerId(terrainLayerId, noEventSend)
    local spec = self.spec_machine

    if spec.dischargeTerrainLayerId ~= terrainLayerId then
        SetMachineDischargeTerrainLayerEvent.sendEvent(self, terrainLayerId, noEventSend)

        spec.dischargeTerrainLayerId = terrainLayerId

        g_messageCenter:publish(SetMachineDischargeTerrainLayerEvent, self, terrainLayerId)
    end
end

---@return number
---@nodiscard
function Machine:getMachineDischargeTerrainLayerId()
    return self.spec_machine.dischargeTerrainLayerId
end

---@param isActive boolean
---@param force boolean | nil
---@param noEventSend boolean | nil
function Machine:setMachineEffectActive(isActive, force, noEventSend)
    local spec = self.spec_machine

    if isActive then
        if not spec.isEffectActive and spec.state.enableEffects then
            g_effectManager:startEffects(spec.effects)
            g_animationManager:startAnimations(spec.effectAnimationNodes)

            spec.isEffectActive = true
        end

        spec.stopEffectTime = nil
    elseif not force then
        if spec.stopEffectTime == nil then
            spec.stopEffectTime = g_time + spec.effectTurnOffThreshold
        end
    elseif spec.isEffectActive then
        g_effectManager:stopEffects(spec.effects)
        g_animationManager:stopAnimations(spec.effectAnimationNodes)

        spec.isEffectActive = false
    end

    if self.isServer and spec.isEffectActive ~= spec.isEffectActiveSent then
        spec.isEffectActiveSent = spec.isEffectActive

        self:raiseDirtyFlags(spec.dirtyFlagEffect)
    end
end

---@param dt number
function Machine:updateMachineSound(dt)
    local spec = self.spec_machine

    local isEffectActive = spec.isEffectActive
    local lastEffectVisible = spec.lastEffect == nil or spec.lastEffect:getIsVisible()
    local effectsStillActive = spec.lastEffect ~= nil and spec.lastEffect:getIsVisible()

    if (isEffectActive or effectsStillActive) and lastEffectVisible then
        if spec.playSound and not g_soundManager:getIsSamplePlaying(spec.sample) then
            g_soundManager:playSample(spec.sample)
        end

        spec.turnOffSoundTimer = 250
    elseif spec.turnOffSoundTimer ~= nil and spec.turnOffSoundTimer > 0 then
        spec.turnOffSoundTimer = spec.turnOffSoundTimer - dt

        if spec.turnOffSoundTimer <= 0 then
            if spec.playSound and g_soundManager:getIsSamplePlaying(spec.sample) then
                g_soundManager:stopSample(spec.sample)
            end

            spec.turnOffSoundTimer = 0
        end
    end
end

function Machine:updateWorkArea()
    self.spec_machine.workArea:update()
end

---@param liters number
---@param fillTypeIndex number
function Machine:workAreaInput(liters, fillTypeIndex)
    local spec = self.spec_machine

    if spec.hasFillUnit and spec.fillUnit ~= nil then
        liters = liters * spec.state.inputRatio

        self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnit.fillUnitIndex, liters, fillTypeIndex, ToolType.UNDEFINED)
    elseif (spec.machineType.id == 'ripper' or spec.machineType.id == 'excavatorRipper') and spec.state.enableOutputMaterial then
        local offsetZ = -1
        local halfLength = 1
        local halfWidth = 1

        local sx, sy, sz = localToWorld(spec.workArea.referenceNode, -halfWidth, 0, -halfLength + offsetZ)
        local ex, ey, ez = localToWorld(spec.workArea.referenceNode, halfWidth, 0, halfLength + offsetZ)

        DensityMapHeightUtil.tipToGroundAroundLine(
            self, liters, fillTypeIndex or spec.fillTypeIndex,
            sx, sy, sz, ex, ey, ez,
            0.5, 2, 0, false
        )
    end
end

---@param emptyLiters number
---@return number dischargedLiters
---@return boolean minDropReached
---@return boolean hasMinDropFillLevel
function Machine:dischargeToGround(emptyLiters)
    local spec = self.spec_machine

    if emptyLiters == 0 then
        return 0, false, false
    end

    if spec.machineTypeId == 'discharger' and spec.outputMode ~= Machine.MODE.FLATTEN then
        emptyLiters = math.max(12, emptyLiters)
    end

    ---@type number, number
    local fillTypeIndex, factor = self:getDischargeFillType(spec.dischargeNode)
    local fillLevel = self:getFillUnitFillLevel(spec.dischargeNode.fillUnitIndex)
    local minLiterToDrop = g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex)

    spec.dischargeNode.litersToDrop = math.min(spec.dischargeNode.litersToDrop + emptyLiters, math.max(spec.dischargeNode.emptySpeed * 250, minLiterToDrop))

    local minDropReached = minLiterToDrop < spec.dischargeNode.litersToDrop
    local hasMinDropFillLevel = minLiterToDrop < fillLevel
    local dischargedLiters = 0

    local dropped = 0

    if spec.outputMode == Machine.MODE.RAISE then
        dropped = spec.workArea:raise(spec.dischargeNode.litersToDrop * factor, fillTypeIndex)
    elseif spec.outputMode == Machine.MODE.FLATTEN then
        dropped = spec.workArea:flattenDischarge(spec.dischargeNode.litersToDrop * factor, fillTypeIndex)
    elseif spec.outputMode == Machine.MODE.SMOOTH then
        dropped = spec.workArea:smoothDischarge(spec.dischargeNode.litersToDrop * factor, fillTypeIndex)
    elseif spec.outputMode == Machine.MODE.PAINT then
        dropped = spec.workArea:paintDischarge()
    end

    dropped = dropped / factor
    spec.dischargeNode.litersToDrop = math.max(0, spec.dischargeNode.litersToDrop - dropped)

    if dropped > 0 then
        local unloadInfo = self:getFillVolumeUnloadInfo(spec.dischargeNode.unloadInfoIndex)

        dischargedLiters = self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.dischargeNode.fillUnitIndex, -dropped, self:getFillUnitFillType(spec.dischargeNode.fillUnitIndex), ToolType.UNDEFINED, unloadInfo)
    end

    fillLevel = self:getFillUnitFillLevel(spec.dischargeNode.fillUnitIndex)

    if fillLevel > 0 and fillLevel <= minLiterToDrop then
        spec.dischargeNode.litersToDrop = minLiterToDrop
    end

    return dischargedLiters, minDropReached, hasMinDropFillLevel
end

--
-- Get whether available for input using terrain deformations or not
--
---@return boolean
---@nodiscard
function Machine:getIsAvailable()
    local spec = self.spec_machine

    if g_modSettings:getIsEnabled() and spec.enabled and spec.active and spec.inputMode ~= Machine.MODE.MATERIAL and (spec.inputMode == Machine.MODE.PAINT or not self:getIsFull()) then
        return Machine.getDrivingDirection(self) > 0
    end

    return false
end

---@return boolean
---@nodiscard
function Machine:getIsEmpty()
    local spec = self.spec_machine

    if spec.hasFillUnit and spec.fillUnit ~= nil then
        return spec.fillUnit.fillLevel < 0.01
    end

    return true
end

---@return boolean
---@nodiscard
function Machine:getIsFull()
    local spec = self.spec_machine

    if spec.hasFillUnit and spec.fillUnit ~= nil then
        return spec.fillUnit.capacity - spec.fillUnit.fillLevel < 0.01
    elseif spec.machineType.id == 'ripper' or spec.machineType.id == 'excavatorRipper' or spec.machineType.id == 'compactor' then
        return false
    end

    return true
end

---@return boolean
---@nodiscard
function Machine:getCanAccessMachine()
    -- if self.isServer then
    --     return MachineUtils.getPlayerHasPermission('landscaping', self:getOwner())
    -- else
    --     return MachineUtils.getPlayerHasPermission('landscaping')
    -- end
    return MachineUtils.getPlayerHasPermission('landscaping')
end

---@return boolean
---@nodiscard
function Machine:getCanActivateMachine()
    local spec = self.spec_machine

    if g_modSettings:getIsEnabled() and spec.enabled and self:getCanAccessMachine() then
        if spec.requirePoweredOn and self.getIsPowered ~= nil and not self:getIsPowered() then
            return false
        end

        if spec.requireTurnedOn and self.getIsTurnedOn ~= nil and not self:getIsTurnedOn() then
            return false
        end

        return true
    end

    return false
end

---@param dt number
---@param isActiveForInput boolean
---@param isActiveForInputIgnoreSelection boolean
---@param isSelected boolean
function Machine:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_machine

    if (self.isServer and spec.active) or (self.isClient and g_modSettings:getIsEnabled() and spec.enabled and g_modSettings:getDebugNodes()) then
        self:updateWorkArea()
    end

    if self.isServer then
        if self:getIsAvailable() then
            if spec.workArea.isActive and spec.lastIntervalUpdate >= spec.updateInterval then
                if spec.inputMode == Machine.MODE.FLATTEN then
                    spec.workArea:flatten()
                elseif spec.inputMode == Machine.MODE.SMOOTH then
                    spec.workArea:smooth()
                elseif spec.inputMode == Machine.MODE.LOWER then
                    spec.workArea:lower()
                elseif spec.inputMode == Machine.MODE.PAINT then
                    spec.workArea:paint()
                end

                spec.lastIntervalUpdate = 0
            else
                spec.lastIntervalUpdate = spec.lastIntervalUpdate + dt
            end

            self:setMachineEffectActive(spec.workArea.isActive)
        else
            self:setMachineEffectActive(false)
        end
    end
end

---@param dt number
---@param isActiveForInput boolean
---@param isActiveForInputIgnoreSelection boolean
---@param isSelected boolean
function Machine:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_machine

    if self.isClient then
        self:updateMachineSound(dt)
    end

    if self.isServer then
        if spec.stopEffectTime ~= nil and spec.stopEffectTime < g_time then
            self:setMachineEffectActive(false, true)
            spec.stopEffectTime = nil
        end
    end
end

-- NOTE: not a registered function
---@return number
---@nodiscard
function Machine:getDrivingDirection()
    local spec = self.spec_machine

    if spec.machineType.useDrivingDirection then
        if spec.hasAttachable then
            ---@type DrivableVehicle | nil
            ---@diagnostic disable-next-line: assign-type-mismatch
            local rootVehicle = self:findRootVehicle()

            if rootVehicle ~= nil and rootVehicle.getDrivingDirection ~= nil then
                return rootVehicle:getDrivingDirection()
            end
        elseif spec.hasDrivable then
            ---@diagnostic disable-next-line: param-type-mismatch
            return Drivable.getDrivingDirection(self)
        end

        return 0
    end

    return 1
end

function Machine:onLeaveVehicle()
    if self.isServer then
        self:setMachineActive(false)
    end
end

function Machine:onLeaveRootVehicle()
    if self.isServer then
        self:setMachineActive(false)
    end
end

function Machine:onPostAttach()
end

function Machine:onPostDetach()
    if self.isServer then
        self:setMachineActive(false)
    end
end

function Machine:onStartMotor()
    local spec = self.spec_machine

    if self.isClient and spec.requirePoweredOn then
        self:requestActionEventUpdate()
    end
end

function Machine:onStopMotor()
    local spec = self.spec_machine

    if self.isServer and spec.requirePoweredOn then
        self:setMachineActive(false)
    end
end

function Machine:onTurnedOn()
    local spec = self.spec_machine

    if self.isClient and spec.requireTurnedOn then
        self:requestActionEventUpdate()
    end
end

function Machine:onTurnedOff()
    local spec = self.spec_machine

    if self.isServer and spec.requireTurnedOn then
        self:setMachineActive(false)
    end
end

---@param streamId number
---@param connection Connection
function Machine:onWriteStream(streamId, connection)
    local spec = self.spec_machine

    if not connection:getIsServer() then
        streamWriteBool(streamId, spec.isEffectActiveSent)

        if streamWriteBool(streamId, spec.surveyorId ~= nil) then
            streamWriteString(streamId, spec.surveyorId)
        end

        streamWriteBool(streamId, spec.enabled)
        streamWriteBool(streamId, spec.resourcesEnabled)
        streamWriteBool(streamId, spec.active)
        streamWriteUIntN(streamId, spec.inputMode, Machine.NUM_BITS_MODE)
        streamWriteUIntN(streamId, spec.outputMode, Machine.NUM_BITS_MODE)
        streamWriteUIntN(streamId, spec.fillTypeIndex or 0, FillTypeManager.SEND_NUM_BITS)
        streamWriteUIntN(streamId, spec.terrainLayerId or 0, TerrainDeformation.LAYER_SEND_NUM_BITS)
        streamWriteUIntN(streamId, spec.dischargeTerrainLayerId or 0, TerrainDeformation.LAYER_SEND_NUM_BITS)

        spec.state:writeStream(streamId, connection)
    end
end

---@param streamId number
---@param connection Connection
function Machine:onReadStream(streamId, connection)
    local spec = self.spec_machine

    if connection:getIsServer() then
        self:setMachineEffectActive(streamReadBool(streamId), true, true)

        if streamReadBool(streamId) then
            self:setSurveyorId(streamReadString(streamId), true)
        else
            self:setSurveyorId(nil, true)
        end

        self:setMachineEnabled(streamReadBool(streamId), true)
        self:setResourcesEnabled(streamReadBool(streamId), true)
        self:setMachineActive(streamReadBool(streamId), true)
        self:setInputMode(streamReadUIntN(streamId, Machine.NUM_BITS_MODE), true)
        self:setOutputMode(streamReadUIntN(streamId, Machine.NUM_BITS_MODE), true)
        self:setMachineFillTypeIndex(streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS), true)
        self:setMachineTerrainLayerId(streamReadUIntN(streamId, TerrainDeformation.LAYER_SEND_NUM_BITS), true)
        self:setMachineDischargeTerrainLayerId(streamReadUIntN(streamId, TerrainDeformation.LAYER_SEND_NUM_BITS), true)

        spec.state:readStream(streamId, connection)
    end
end

---@param streamId number
---@param connection Connection
---@param dirtyMask number
function Machine:onWriteUpdateStream(streamId, connection, dirtyMask)
    local spec = self.spec_machine

    if not connection:getIsServer() then
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlagEffect) ~= 0) then
            streamWriteBool(streamId, spec.isEffectActiveSent)
        end
    end
end

---@param streamId number
---@param timestamp number
---@param connection Connection
function Machine:onReadUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            self:setMachineEffectActive(streamReadBool(streamId), true, true)
        end
    end
end

---@param isActiveForInput boolean
---@param isActiveForInputIgnoreSelection boolean
function Machine:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_machine
        local canActivate = self:getCanActivateMachine()
        local addActionEvents = isActiveForInput

        self:clearActionEventsTable(spec.actionEvents)

        if not addActionEvents then
            return
        end

        local action = InputAction[Machine.ACTION_TOGGLE_ACTIVE]

        if action ~= nil then
            local _, eventId = self:addActionEvent(spec.actionEvents, action, self, Machine.actionEventToggleActive, false, true, false, true)

            if canActivate then
                g_inputBinding:setActionEventText(eventId, Machine.L10N_ACTION_DEACTIVATE)
            else
                g_inputBinding:setActionEventText(eventId, Machine.L10N_ACTION_ACTIVATE)
            end

            g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_NORMAL)
        end

        if #spec.modesInput > 1 then
            action = InputAction[Machine.ACTION_TOGGLE_INPUT]

            if action ~= nil then
                local _, eventId = self:addActionEvent(spec.actionEvents, action, self, Machine.actionEventToggleInput, false, true, false, true)

                g_inputBinding:setActionEventText(eventId, Machine.L10N_ACTION_TOGGLE_INPUT)
                g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_NORMAL)
            end
        end

        if #spec.modesOutput > 1 then
            action = InputAction[Machine.ACTION_TOGGLE_OUTPUT]

            if action ~= nil then
                local _, eventId = self:addActionEvent(spec.actionEvents, action, self, Machine.actionEventToggleOutput, false, true, false, true)

                g_inputBinding:setActionEventText(eventId, Machine.L10N_ACTION_TOGGLE_OUTPUT)
                g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_NORMAL)
            end
        end

        action = InputAction[Machine.ACTION_SETTINGS]

        if action ~= nil then
            local _, eventId = self:addActionEvent(spec.actionEvents, action, self, Machine.actionEventMachineDialog, false, true, false, true)

            g_inputBinding:setActionEventText(eventId, Machine.L10N_ACTION_MACHINE_SETTINGS)
            g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_NORMAL)
        end

        action = InputAction[Machine.ACTION_SELECT_MATERIAL]

        if action ~= nil then
            local _, eventId = self:addActionEvent(spec.actionEvents, action, self, Machine.actionEventSelectMaterial, false, true, false, true)

            g_inputBinding:setActionEventText(eventId, Machine.L10N_ACTION_SELECT_MATERIAL)
            g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_LOW)
        end

        action = InputAction[Machine.ACTION_SELECT_TEXTURE]

        if action ~= nil then
            local _, eventId = self:addActionEvent(spec.actionEvents, action, self, Machine.actionEventSelectTerrainLayer, false, true, false, true)

            g_inputBinding:setActionEventText(eventId, Machine.L10N_ACTION_SELECT_GROUND_TEXTURE)
            g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_LOW)
        end

        action = InputAction[Machine.ACTION_SELECT_DISCHARGE_TEXTURE]

        if action ~= nil then
            local _, eventId = self:addActionEvent(spec.actionEvents, action, self, Machine.actionEventSelectDischargeTerrainLayer, false, true, false, true)

            g_inputBinding:setActionEventText(eventId, Machine.L10N_ACTION_SELECT_DISCHARGE_GROUND_TEXTURE)
            g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_LOW)
        end

        action = InputAction[Machine.ACTION_SELECT_SURVEYOR]

        if action ~= nil and (MachineUtils.getHasInputMode(self, Machine.MODE.FLATTEN) or MachineUtils.getHasOutputMode(self, Machine.MODE.FLATTEN)) then
            local _, eventId = self:addActionEvent(spec.actionEvents, action, self, Machine.actionEventSelectSurveyor, false, true, false, true)

            g_inputBinding:setActionEventText(eventId, Machine.L10N_ACTION_SELECT_SURVEYOR)
            g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_LOW)
        end

        action = InputAction[Machine.ACTION_GLOBAL_SETTINGS]

        if action ~= nil then
            local _, eventId = self:addActionEvent(spec.actionEvents, action, self, Machine.actionEventGlobalSettings, false, true, false, true)

            g_inputBinding:setActionEventText(eventId, Machine.L10N_ACTION_GLOBAL_SETTINGS)
            g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_LOW)
        end

        action = InputAction[Machine.ACTION_TOGGLE_HUD]

        if action ~= nil then
            local _, eventId = self:addActionEvent(spec.actionEvents, action, self, Machine.actionEventToggleHUD, false, true, false, true)

            g_inputBinding:setActionEventText(eventId, Machine.L10N_ACTION_TOGGLE_HUD)
            g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_LOW)
        end

        Machine.updateActionEvents(self)
    end
end

function Machine:updateActionEvents()
    if self.isClient then
        local spec = self.spec_machine
        local canActivate = self:getCanActivateMachine()
        local hasAccess = self:getCanAccessMachine()
        local isActive = self:getIsActiveForInput()

        local action = InputAction[Machine.ACTION_TOGGLE_ACTIVE]

        if action ~= nil then
            local event = spec.actionEvents[action]

            if event ~= nil then
                if isActive and canActivate then
                    g_inputBinding:setActionEventActive(event.actionEventId, true)

                    if spec.active then
                        g_inputBinding:setActionEventText(event.actionEventId, Machine.L10N_ACTION_DEACTIVATE)
                    else
                        g_inputBinding:setActionEventText(event.actionEventId, Machine.L10N_ACTION_ACTIVATE)
                    end
                else
                    g_inputBinding:setActionEventActive(event.actionEventId, false)
                end
            end
        end

        action = InputAction[Machine.ACTION_TOGGLE_INPUT]

        if action ~= nil then
            local event = spec.actionEvents[action]

            if event ~= nil then
                g_inputBinding:setActionEventActive(event.actionEventId, isActive and (canActivate or hasAccess))
            end
        end

        action = InputAction[Machine.ACTION_TOGGLE_OUTPUT]

        if action ~= nil then
            local event = spec.actionEvents[action]

            if event ~= nil then
                g_inputBinding:setActionEventActive(event.actionEventId, isActive and (canActivate or hasAccess))
            end
        end

        action = InputAction[Machine.ACTION_SETTINGS]

        if action ~= nil then
            local event = spec.actionEvents[action]

            if event ~= nil then
                g_inputBinding:setActionEventActive(event.actionEventId, isActive and hasAccess)
            end
        end

        action = InputAction[Machine.ACTION_SELECT_MATERIAL]

        if action ~= nil then
            local event = spec.actionEvents[action]

            if event ~= nil then
                g_inputBinding:setActionEventActive(event.actionEventId, isActive and (canActivate or hasAccess))
            end
        end

        action = InputAction[Machine.ACTION_SELECT_TEXTURE]

        if action ~= nil then
            local event = spec.actionEvents[action]

            if event ~= nil then
                g_inputBinding:setActionEventActive(event.actionEventId, #spec.modesInput > 0 and isActive and (canActivate or hasAccess))
            end
        end

        action = InputAction[Machine.ACTION_SELECT_DISCHARGE_TEXTURE]

        if action ~= nil then
            local event = spec.actionEvents[action]

            if event ~= nil then
                g_inputBinding:setActionEventActive(event.actionEventId, #spec.modesOutput > 0 and isActive and (canActivate or hasAccess))
            end
        end

        action = InputAction[Machine.ACTION_SELECT_SURVEYOR]

        if action ~= nil then
            local event = spec.actionEvents[action]

            if event ~= nil then
                g_inputBinding:setActionEventActive(event.actionEventId, isActive and (canActivate or hasAccess))
            end
        end

        action = InputAction[Machine.ACTION_GLOBAL_SETTINGS]

        if action ~= nil then
            local event = spec.actionEvents[action]

            if event ~= nil then
                g_inputBinding:setActionEventActive(event.actionEventId, true)
            end
        end

        action = InputAction[Machine.ACTION_TOGGLE_HUD]

        if action ~= nil then
            local event = spec.actionEvents[action]

            if event ~= nil then
                g_inputBinding:setActionEventActive(event.actionEventId, true)
            end
        end
    end
end

function Machine:actionEventToggleHUD()
    g_modHud.display:setVisible(not g_modHud.display.isVisible, true)

    g_modSettings:saveUserSettings()
end

function Machine:actionEventToggleActive()
    self:setMachineActive(not self.spec_machine.active)
end

function Machine:actionEventToggleInput()
    local spec = self.spec_machine

    local currentIndex = table.find(spec.modesInput, spec.inputMode)

    if currentIndex >= #spec.modesInput then
        self:setInputMode(spec.modesInput[1])
    else
        self:setInputMode(spec.modesInput[currentIndex + 1])
    end
end

function Machine:actionEventToggleOutput()
    local spec = self.spec_machine

    local currentIndex = table.find(spec.modesOutput, spec.outputMode)

    if currentIndex >= #spec.modesOutput then
        self:setOutputMode(spec.modesOutput[1])
    else
        self:setOutputMode(spec.modesOutput[currentIndex + 1])
    end
end

function Machine:actionEventMachineDialog()
    g_machineScreen:show(self)
end

function Machine:actionEventSelectMaterial()
    local spec = self.spec_machine

    g_selectMaterialDialog:setSelectCallback(Machine.selectMaterialCallback, self)
    g_selectMaterialDialog:show(spec.fillTypeIndex)
end

---@param fillTypeIndex number | nil
function Machine:selectMaterialCallback(fillTypeIndex)
    if fillTypeIndex ~= nil then
        self:setMachineFillTypeIndex(fillTypeIndex)
    end
end

function Machine:actionEventSelectTerrainLayer()
    local spec = self.spec_machine

    g_selectTerrainLayerDialog:setSelectCallback(Machine.selectTerrainLayerCallback, self)
    g_selectTerrainLayerDialog:show(spec.terrainLayerId)
end

---@param terrainLayerId number | nil
function Machine:selectTerrainLayerCallback(terrainLayerId)
    if terrainLayerId ~= nil then
        self:setMachineTerrainLayerId(terrainLayerId)
    end
end

function Machine:actionEventSelectDischargeTerrainLayer()
    local spec = self.spec_machine

    g_selectTerrainLayerDialog:setSelectCallback(Machine.selectDischargeTerrainLayerCallback, self)
    g_selectTerrainLayerDialog:show(spec.dischargeTerrainLayerId, g_i18n:getText('ui_changeDischargeTexture'))
end

---@param terrainLayerId number | nil
function Machine:selectDischargeTerrainLayerCallback(terrainLayerId)
    if terrainLayerId ~= nil then
        self:setMachineDischargeTerrainLayerId(terrainLayerId)
    end
end

function Machine:actionEventSelectSurveyor()
    g_selectSurveyorDialog:setSelectCallback(Machine.selectSurveyorCallback, self)
    g_selectSurveyorDialog:show(self)
end

function Machine:actionEventGlobalSettings()
    g_globalSettingsDialog:show()
end

---@param vehicle Surveyor
function Machine:selectSurveyorCallback(vehicle)
    if vehicle ~= nil and vehicle.getSurveyorId ~= nil then
        self:setSurveyorId(vehicle:getSurveyorId())
    end
end

---@param dischargeNode DischargeNode
---@return boolean
function Machine:getCanDischargeToGround(superFunc, dischargeNode)
    local spec = self.spec_machine

    if dischargeNode == spec.dischargeNode then
        if spec.outputMode == Machine.MODE.MATERIAL then
            if not spec.state.enableOutputMaterial then
                return false
            end
        elseif MachineUtils.getIsDischargeable(self) and g_modSettings:getIsEnabled() and self:getMachineEnabled() then
            if self:getMachineActive() then
                if spec.outputMode == Machine.MODE.PAINT then
                    return true
                end

                return spec.workArea:getCanOutput()
            elseif not spec.state.enableOutputMaterial then
                return false
            end
        end
    end

    return superFunc(self, dischargeNode)
end

---@return number dischargedLiters
---@return boolean minDropReached
---@return boolean hasMinDropFillLevel
function Machine:discharge(superFunc, dischargeNode, emptyLiters)
    local spec = self.spec_machine

    if dischargeNode == spec.dischargeNode and self.spec_dischargeable.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND then
        if g_modSettings:getIsEnabled() and self:getMachineActive() and spec.outputMode ~= Machine.MODE.MATERIAL then
            return Machine.dischargeToGround(self, emptyLiters)
        end
    end

    return superFunc(self, dischargeNode, emptyLiters)
end

---@param id string | nil
---@param noEventSend boolean | nil
function Machine:setSurveyorId(id, noEventSend)
    local spec = self.spec_machine

    if spec.surveyorId ~= id then
        SetMachineSurveyorEvent.sendEvent(self, id, noEventSend)

        spec.surveyorId = id

        g_messageCenter:publish(SetMachineSurveyorEvent, self, id)
    end
end

---@return string|nil
---@nodiscard
function Machine:getSurveyorId()
    return self.spec_machine.surveyorId
end

---@return Surveyor | nil
---@nodiscard
function Machine:getSurveyor()
    local spec = self.spec_machine

    return g_machineManager:getSurveyorById(spec.surveyorId)
end

---@return number startPosX
---@return number startPosX
---@return number startPosX
---@return number endPosX
---@return number endPosY
---@return number endPosX
---@return boolean isLinked
function Machine:getSurveyorCalibration()
    local surveyor = self:getSurveyor()

    if surveyor ~= nil then
        local spec = surveyor.spec_surveyor

        return spec.startPosX, spec.startPosY, spec.startPosZ, spec.endPosX, spec.endPosY, spec.endPosZ, true
    end

    return 0, math.huge, 0, 0, math.huge, 0, false
end

---@param vehicle Surveyor
function Machine:onSurveyorRemoved(vehicle)
    if self.isServer and vehicle ~= nil then
        local surveyorId = vehicle.spec_surveyor.surveyorId

        if surveyorId ~= nil and self:getSurveyorId() == surveyorId then
            self:setSurveyorId(nil)
        end
    end
end

---@param user User
function Machine:onMasterUserAdded(user)
    if user:getId() == g_currentMission.playerUserId then
        Machine.updateActionEvents(self)
    end
end

---@param userId number
function Machine:onPlayerPermissionsChanged(userId)
    if userId == g_currentMission.playerUserId then
        Machine.updateActionEvents(self)

        if self:getMachineActive() and not self:getCanAccessMachine() then
            self:setMachineActive(false)
        end
    end
end
