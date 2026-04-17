source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineActiveEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineEnabledEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineFillTypeEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineInputAreaEnabledEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineInputAreaIdEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineInputLayerEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineInputModeEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineOutputAreaEnabledEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineOutputAreaIdEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineOutputLayerEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineOutputModeEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineResourcesEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetMachineStateEvent.lua')

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
Machine.SPEC_NAME = string.format('spec_%s.machine', g_currentModName)
Machine.DEFAULT_FILLTYPE = 'STONE'

---@enum MachineMode
Machine.MODE = {
    RAISE = 1,
    LOWER = 2,
    SMOOTH = 3,
    FLATTEN = 4,
    PAINT = 5,
    MATERIAL = 6,
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
Machine.L10N_ACTION_GLOBAL_SETTINGS = g_i18n:getText('ui_globalSettings')
Machine.L10N_ACTION_TOGGLE_HUD = g_i18n:getText('ui_toggleHud')
Machine.L10N_ACTION_SELECT_INPUT_AREA = g_i18n:getText('input_MACHINE_SELECT_INPUT_AREA')
Machine.L10N_ACTION_SELECT_OUTPUT_AREA = g_i18n:getText('input_MACHINE_SELECT_OUTPUT_AREA')
Machine.L10N_ACTION_TOGGLE_INPUT_AREA_STATE = g_i18n:getText('input_MACHINE_TOGGLE_INPUT_AREA_STATE')
Machine.L10N_ACTION_TOGGLE_OUTPUT_AREA_STATE = g_i18n:getText('input_MACHINE_TOGGLE_OUTPUT_AREA_STATE')
Machine.L10N_ACTION_TOGGLE_GLOBAL_BORDER = g_i18n:getText('input_MACHINE_GLOBAL_TOGGLE_BORDER')

Machine.ACTION_TOGGLE_ACTIVE = 'MACHINE_TOGGLE_ACTIVE'
Machine.ACTION_TOGGLE_INPUT = 'MACHINE_TOGGLE_INPUT'
Machine.ACTION_TOGGLE_OUTPUT = 'MACHINE_TOGGLE_OUTPUT'
Machine.ACTION_SETTINGS = 'MACHINE_SETTINGS'
Machine.ACTION_SELECT_MATERIAL = 'MACHINE_SELECT_MATERIAL'
Machine.ACTION_SELECT_TEXTURE = 'MACHINE_SELECT_TEXTURE'
Machine.ACTION_SELECT_DISCHARGE_TEXTURE = 'MACHINE_SELECT_DISCHARGE_TEXTURE'
Machine.ACTION_GLOBAL_SETTINGS = 'MACHINE_GLOBAL_SETTINGS'
Machine.ACTION_TOGGLE_HUD = 'MACHINE_TOGGLE_HUD'
Machine.ACTION_SELECT_INPUT_AREA = 'MACHINE_SELECT_INPUT_AREA'
Machine.ACTION_SELECT_OUTPUT_AREA = 'MACHINE_SELECT_OUTPUT_AREA'
Machine.ACTION_TOGGLE_INPUT_AREA_STATE = 'MACHINE_TOGGLE_INPUT_AREA_STATE'
Machine.ACTION_TOGGLE_OUTPUT_AREA_STATE = 'MACHINE_TOGGLE_OUTPUT_AREA_STATE'
Machine.ACTION_GLOBAL_TOGGLE_BORDER = 'MACHINE_GLOBAL_TOGGLE_BORDER'

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
Machine.MODE_NAME = {
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

    schema:register(XMLValueType.NODE_INDEX, key .. '.updateCollisionNodes.updateNode(?)#node')

    schema:setXMLSpecializationType()
end

---@param schema XMLSchema
---@param key string
function Machine.registerSavegameXMLPaths(schema, key)
    schema:setXMLSpecializationType('Machine')

    schema:register(XMLValueType.BOOL, key .. '#enabled')
    schema:register(XMLValueType.BOOL, key .. '#resourcesEnabled')
    schema:register(XMLValueType.STRING, key .. '#fillType')
    schema:register(XMLValueType.STRING, key .. '#terrainLayer')
    schema:register(XMLValueType.STRING, key .. '#dischargeTerrainLayer')
    schema:register(XMLValueType.STRING, key .. '#inputMode')
    schema:register(XMLValueType.STRING, key .. '#outputMode')

    schema:register(XMLValueType.STRING, key .. '#inputAreaId')
    schema:register(XMLValueType.BOOL, key .. '#inputAreaEnabled')
    schema:register(XMLValueType.STRING, key .. '#outputAreaId')
    schema:register(XMLValueType.BOOL, key .. '#outputAreaEnabled')

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

    SpecializationUtil.registerFunction(vehicleType, 'setMachineInputLayerId', Machine.setMachineInputLayerId)
    SpecializationUtil.registerFunction(vehicleType, 'getMachineInputLayerId', Machine.getMachineInputLayerId)

    SpecializationUtil.registerFunction(vehicleType, 'setMachineOutputLayerId', Machine.setMachineOutputLayerId)
    SpecializationUtil.registerFunction(vehicleType, 'getMachineOutputLayerId', Machine.getMachineOutputLayerId)

    SpecializationUtil.registerFunction(vehicleType, 'getCanAccessMachine', Machine.getCanAccessMachine)
    SpecializationUtil.registerFunction(vehicleType, 'getCanActivateMachine', Machine.getCanActivateMachine)
    SpecializationUtil.registerFunction(vehicleType, 'getIsAvailable', Machine.getIsAvailable)
    SpecializationUtil.registerFunction(vehicleType, 'getIsFull', Machine.getIsFull)

    SpecializationUtil.registerFunction(vehicleType, 'handleDeformationInput', Machine.handleDeformationInput)
    SpecializationUtil.registerFunction(vehicleType, 'setResourcesEnabled', Machine.setResourcesEnabled)

    SpecializationUtil.registerFunction(vehicleType, 'setMachineInputAreaId', Machine.setMachineInputAreaId)
    SpecializationUtil.registerFunction(vehicleType, 'getMachineInputAreaId', Machine.getMachineInputAreaId)
    SpecializationUtil.registerFunction(vehicleType, 'getMachineInputArea', Machine.getMachineInputArea)

    SpecializationUtil.registerFunction(vehicleType, 'setIsMachineInputAreaEnabled', Machine.setIsMachineInputAreaEnabled)
    SpecializationUtil.registerFunction(vehicleType, 'getIsMachineInputAreaEnabled', Machine.getIsMachineInputAreaEnabled)

    SpecializationUtil.registerFunction(vehicleType, 'setMachineOutputAreaId', Machine.setMachineOutputAreaId)
    SpecializationUtil.registerFunction(vehicleType, 'getMachineOutputAreaId', Machine.getMachineOutputAreaId)
    SpecializationUtil.registerFunction(vehicleType, 'getMachineOutputArea', Machine.getMachineOutputArea)

    SpecializationUtil.registerFunction(vehicleType, 'setIsMachineOutputAreaEnabled', Machine.setIsMachineOutputAreaEnabled)
    SpecializationUtil.registerFunction(vehicleType, 'getIsMachineOutputAreaEnabled', Machine.getIsMachineOutputAreaEnabled)

    SpecializationUtil.registerFunction(vehicleType, 'getMachineType', Machine.getMachineType)
    SpecializationUtil.registerFunction(vehicleType, 'getMachineWorkArea', Machine.getMachineWorkArea)
end

function Machine.initSpecialization()
    g_storeManager:addSpecType('machine', 'tf_shopListAttributeIconMachine', Machine.loadSpecValue, Machine.getSpecValue)

    Machine.registerXMLPaths(Vehicle.xmlSchema, 'vehicle.machine')
    Machine.registerSavegameXMLPaths(Vehicle.xmlSchemaSavegame, string.format('vehicles.vehicle(?).%s.machine', Machine.MOD_NAME))
end

---@param xmlFile XMLFile
---@param customEnvironment string?
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
---@return string?
function Machine.getSpecValue(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
    if storeItem ~= nil and storeItem.specs ~= nil and storeItem.specs.machine ~= nil then
        ---@type MachineType?
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
            Logging.error('Machine:onLoad() Failed to load machine configuration file: %s', tostring(spec.xmlFilenameConfig))
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
        Logging.xmlError(xmlFile, 'Machine:onLoad() Invalid machine type name: %s', tostring(spec.machineTypeId))

        if spec.isExternal then
            xmlFile:delete()
        end

        return false
    end

    spec.enabled = g_modSettings:getDefaultEnabled()
    spec.resourcesEnabled = true
    spec.active = false
    spec.updateInterval = 50
    spec.lastIntervalUpdate = 0
    spec.state = MachineState.new()

    spec.inputMode = Machine.MODE.LOWER
    spec.outputMode = Machine.MODE.RAISE

    spec.inputAreaEnabled = true
    spec.outputAreaEnabled = true

    spec.inputTerrainLayerId = g_landscapingManager:getDefaultTerrainLayerId()
    spec.outputTerrainLayerId = g_landscapingManager:getDefaultTerrainLayerId()
    spec.fillTypeIndex = g_landscapingManager:getDefaultFillTypeIndex()
    spec.collisionNodes = MachineUtils.loadUpdateCollisionNodesFromXML(xmlFile, 'vehicle.machine.updateCollisionNodes.updateNode', self)

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

    if spec.hasDischargeable and #self.spec_dischargeable.dischargeNodes > 0 then
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

    if spec.hasLeveler and spec.machineType.useLeveler and #self.spec_leveler.nodes > 0 then
        local levelerNodeIndex = xmlFile:getValue('vehicle.machine#levelerNodeIndex', 1)

        spec.levelerNode = self.spec_leveler.nodes[levelerNodeIndex]

        if spec.machineType.useFillUnit and spec.fillUnitSource == Machine.FILLUNIT_SOURCE.VEHICLE and spec.levelerNode ~= nil and spec.levelerNode.fillUnitIndex ~= nil and spec.fillUnitIndex ~= spec.levelerNode.fillUnitIndex then
            spec.fillUnitIndex = spec.levelerNode.fillUnitIndex
        end
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

    if spec.machineType.useDischargeable then
        table.insert(spec.modesOutput, Machine.MODE.MATERIAL)
        table.insert(spec.modesOutput, Machine.MODE.RAISE)
        table.insert(spec.modesOutput, Machine.MODE.FLATTEN)
        table.insert(spec.modesOutput, Machine.MODE.SMOOTH)
        table.insert(spec.modesOutput, Machine.MODE.PAINT)

        if (spec.machineTypeId == 'shovel' or spec.machineTypeId == 'excavatorShovel') and not MachineUtils.getHasInputMode(self, Machine.MODE.MATERIAL) then
            table.insert(spec.modesInput, Machine.MODE.MATERIAL)
        end
    end

    spec.workArea = MachineWorkArea.new(self)
    spec.workArea:loadFromXMLFile(xmlFile, 'vehicle.machine.workArea')

    if spec.workArea:initialize() then
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

        if spec.hasAttachable then
            SpecializationUtil.registerEventListener(self, 'onPostAttach', Machine)
            SpecializationUtil.registerEventListener(self, 'onPostDetach', Machine)
            SpecializationUtil.registerEventListener(self, 'onLeaveRootVehicle', Machine)
        end

        if spec.hasEnterable then
            SpecializationUtil.registerEventListener(self, 'onLeaveVehicle', Machine)
        end

        if spec.hasMotorized then
            SpecializationUtil.registerEventListener(self, 'onStartMotor', Machine)
            SpecializationUtil.registerEventListener(self, 'onStopMotor', Machine)
        end

        if spec.hasTurnOnVehicle then
            SpecializationUtil.registerEventListener(self, 'onTurnedOn', Machine)
            SpecializationUtil.registerEventListener(self, 'onTurnedOff', Machine)
        end

        if spec.hasDischargeable and #self.spec_dischargeable.dischargeNodes > 0 then
            self.getCanDischargeToGround = Utils.overwrittenFunction(self.getCanDischargeToGround, Machine.getCanDischargeToGround)

            if spec.machineType.useDischargeable then
                self.discharge = Utils.overwrittenFunction(self.discharge, Machine.discharge)
            end
        end
    else
        -- WorkArea initialize() failed, remove event listeners
        SpecializationUtil.removeEventListener(self, 'onPostLoad', Machine)
        SpecializationUtil.removeEventListener(self, 'onDelete', Machine)
        SpecializationUtil.removeEventListener(self, 'onUpdate', Machine)
        SpecializationUtil.removeEventListener(self, 'onUpdateTick', Machine)
        SpecializationUtil.removeEventListener(self, 'onRegisterActionEvents', Machine)
        SpecializationUtil.removeEventListener(self, 'onWriteStream', Machine)
        SpecializationUtil.removeEventListener(self, 'onReadStream', Machine)
        SpecializationUtil.removeEventListener(self, 'onWriteUpdateStream', Machine)
        SpecializationUtil.removeEventListener(self, 'onReadUpdateStream', Machine)
    end

    if spec.isExternal then
        xmlFile:delete()
    end
end

---@param savegame SavegameObject?
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

    g_machineManager:unregisterMachine(self)
end

---@param xmlFile XMLFile
---@param key string
function Machine:saveToXMLFile(xmlFile, key)
    local spec = self.spec_machine

    xmlFile:setValue(key .. '#enabled', spec.enabled)
    xmlFile:setValue(key .. '#resourcesEnabled', spec.resourcesEnabled)
    xmlFile:setValue(key .. '#inputMode', Machine.MODE_NAME[spec.inputMode])
    xmlFile:setValue(key .. '#outputMode', Machine.MODE_NAME[spec.outputMode])

    xmlFile:setValue(key .. '#inputAreaEnabled', spec.inputAreaEnabled)
    xmlFile:setValue(key .. '#outputAreaEnabled', spec.outputAreaEnabled)

    if spec.inputAreaId ~= nil then
        xmlFile:setValue(key .. '#inputAreaId', spec.inputAreaId)
    end

    if spec.outputAreaId ~= nil then
        xmlFile:setValue(key .. '#outputAreaId', spec.outputAreaId)
    end

    ---@type FillTypeObject?
    local fillType = g_fillTypeManager:getFillTypeByIndex(spec.fillTypeIndex)

    if fillType ~= nil then
        xmlFile:setValue(key .. '#fillType', fillType.name)
    end

    if spec.inputTerrainLayerId ~= nil then
        local layerName = getTerrainLayerName(g_terrainNode, spec.inputTerrainLayerId)

        if layerName ~= nil then
            xmlFile:setValue(key .. '#terrainLayer', layerName)
        end
    end

    if spec.outputTerrainLayerId ~= nil then
        local layerName = getTerrainLayerName(g_terrainNode, spec.outputTerrainLayerId)

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

    spec.inputAreaEnabled = xmlFile:getValue(key .. '#inputAreaEnabled', spec.inputAreaEnabled)
    spec.outputAreaEnabled = xmlFile:getValue(key .. '#outputAreaEnabled', spec.outputAreaEnabled)

    spec.inputAreaId = xmlFile:getValue(key .. '#inputAreaId', nil)
    spec.outputAreaId = xmlFile:getValue(key .. '#outputAreaId', nil)

    local fillTypeName = xmlFile:getValue(key .. '#fillType')

    if fillTypeName ~= nil then
        ---@type FillTypeObject?
        local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName)

        if fillType ~= nil then
            self:setMachineFillTypeIndex(fillType.index, true)
        end
    end

    local terrainLayerName = xmlFile:getValue(key .. '#terrainLayer')

    if terrainLayerName ~= nil then
        local layer = g_landscapingManager:getTerrainLayerByName(terrainLayerName)

        if layer ~= nil then
            self:setMachineInputLayerId(layer.id, true)
        end
    end

    local dischargeTerrainLayerName = xmlFile:getValue(key .. '#dischargeTerrainLayer')

    if dischargeTerrainLayerName ~= nil then
        local layer = g_landscapingManager:getTerrainLayerByName(dischargeTerrainLayerName)

        if layer ~= nil then
            self:setMachineOutputLayerId(layer.id, true)
        end
    end

    spec.state:loadFromXMLFile(xmlFile, key .. '.state')
end

---@param enabled boolean
---@param noEventSend boolean?
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
---@param noEventSend boolean?
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

        Machine.updateCollisionNodes(self)

        self:requestActionEventUpdate()

        g_messageCenter:publish(SetMachineActiveEvent, self, active)
    end
end

---@return boolean
---@nodiscard
function Machine:getMachineActive()
    return self.spec_machine.active
end

function Machine:updateCollisionNodes()
    local spec = self.spec_machine

    if spec.collisionNodes ~= nil then
        local scale = spec.active and 0 or 1

        if not spec.state.updateCollisions then
            scale = 1
        end

        for _, node in ipairs(spec.collisionNodes) do
            setScale(node, scale, scale, scale)
        end
    end
end

function Machine:setMachineState(state, noEventSend)
    local spec = self.spec_machine

    if spec.state ~= state then
        SetMachineStateEvent.sendEvent(self, state, noEventSend)

        spec.state = state

        Machine.updateCollisionNodes(self)

        g_messageCenter:publish(SetMachineStateEvent, self, state)
    end
end

---@return MachineState
---@nodiscard
function Machine:getMachineState()
    return self.spec_machine.state
end

---@return MachineType
---@nodiscard
function Machine:getMachineType()
    return self.spec_machine.machineType
end

---@return MachineWorkArea
---@nodiscard
function Machine:getMachineWorkArea()
    return self.spec_machine.workArea
end

---@param id string?
---@param noEventSend? boolean
function Machine:setMachineInputAreaId(id, noEventSend)
    local spec = self.spec_machine

    if spec.inputAreaId ~= id then
        SetMachineInputAreaIdEvent.sendEvent(self, id, noEventSend)

        spec.inputAreaId = id

        g_messageCenter:publish(SetMachineInputAreaIdEvent, self, id)
    end
end

---@return string?
---@return boolean isEnabled
---@nodiscard
function Machine:getMachineInputAreaId()
    local spec = self.spec_machine

    return spec.inputAreaId, spec.inputAreaEnabled
end

---@return LandscapingArea?
---@return boolean isEnabled
---@nodiscard
function Machine:getMachineInputArea()
    local spec = self.spec_machine

    return g_landscapingManager:getAreaByUniqueId(spec.inputAreaId), spec.inputAreaEnabled
end

---@param enabled boolean
---@param noEventSend? boolean
function Machine:setIsMachineInputAreaEnabled(enabled, noEventSend)
    local spec = self.spec_machine

    if spec.inputAreaEnabled ~= enabled then
        SetMachineInputAreaEnabledEvent.sendEvent(self, enabled, noEventSend)

        spec.inputAreaEnabled = enabled

        g_messageCenter:publish(SetMachineInputAreaEnabledEvent, self, enabled)
    end
end

---@return boolean
---@nodiscard
function Machine:getIsMachineInputAreaEnabled()
    return self.spec_machine.inputAreaEnabled
end

---@param id string?
---@param noEventSend? boolean
function Machine:setMachineOutputAreaId(id, noEventSend)
    local spec = self.spec_machine

    if spec.outputAreaId ~= id then
        SetMachineOutputAreaIdEvent.sendEvent(self, id, noEventSend)

        spec.outputAreaId = id

        g_messageCenter:publish(SetMachineOutputAreaIdEvent, self, id)
    end
end

---@return string?
---@return boolean isEnabled
---@nodiscard
function Machine:getMachineOutputAreaId()
    local spec = self.spec_machine

    return spec.outputAreaId, spec.outputAreaEnabled
end

---@return LandscapingArea?
---@return boolean isEnabled
---@nodiscard
function Machine:getMachineOutputArea()
    local spec = self.spec_machine

    return g_landscapingManager:getAreaByUniqueId(spec.outputAreaId), spec.outputAreaEnabled
end

---@param enabled boolean
---@param noEventSend? boolean
function Machine:setIsMachineOutputAreaEnabled(enabled, noEventSend)
    local spec = self.spec_machine

    if spec.outputAreaEnabled ~= enabled then
        SetMachineOutputAreaEnabledEvent.sendEvent(self, enabled, noEventSend)

        spec.outputAreaEnabled = enabled

        g_messageCenter:publish(SetMachineOutputAreaEnabledEvent, self, enabled)
    end
end

---@return boolean
---@nodiscard
function Machine:getIsMachineOutputAreaEnabled()
    return self.spec_machine.outputAreaEnabled
end

---@param enabled boolean
---@param noEventSend boolean?
function Machine:setResourcesEnabled(enabled, noEventSend)
    local spec = self.spec_machine

    if spec.resourcesEnabled ~= enabled then
        SetMachineResourcesEvent.sendEvent(self, enabled, noEventSend)

        spec.resourcesEnabled = enabled

        g_messageCenter:publish(SetMachineResourcesEvent, self, enabled)
    end
end

---@param mode MachineMode
---@param noEventSend boolean?
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
---@param noEventSend boolean?
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
---@param noEventSend boolean?
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
---@param noEventSend boolean?
function Machine:setMachineInputLayerId(terrainLayerId, noEventSend)
    local spec = self.spec_machine

    if spec.inputTerrainLayerId ~= terrainLayerId then
        SetMachineInputLayerEvent.sendEvent(self, terrainLayerId, noEventSend)

        spec.inputTerrainLayerId = terrainLayerId

        g_messageCenter:publish(SetMachineInputLayerEvent, self, terrainLayerId)
    end
end

---@return number
---@nodiscard
function Machine:getMachineInputLayerId()
    return self.spec_machine.inputTerrainLayerId
end

---@param terrainLayerId number
---@param noEventSend boolean?
function Machine:setMachineOutputLayerId(terrainLayerId, noEventSend)
    local spec = self.spec_machine

    if spec.outputTerrainLayerId ~= terrainLayerId then
        SetMachineOutputLayerEvent.sendEvent(self, terrainLayerId, noEventSend)

        spec.outputTerrainLayerId = terrainLayerId

        g_messageCenter:publish(SetMachineOutputLayerEvent, self, terrainLayerId)
    end
end

---@return number
---@nodiscard
function Machine:getMachineOutputLayerId()
    return self.spec_machine.outputTerrainLayerId
end

---@param isActive boolean
---@param force boolean?
---@param noEventSend boolean?
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

---@param liters number
---@param fillTypeIndex number
function Machine:handleDeformationInput(liters, fillTypeIndex)
    local spec = self.spec_machine

    if spec.hasFillUnit and spec.fillUnit ~= nil then
        liters = liters * spec.state.inputRatio

        self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnit.fillUnitIndex, liters, fillTypeIndex, ToolType.UNDEFINED)
    elseif (spec.machineType.id == 'ripper' or spec.machineType.id == 'excavatorRipper') and spec.state.enableOutputMaterial then
        local offsetZ = -1
        local halfLength = 1
        local halfWidth = 1
        local outputNode = spec.workArea.outputNode or spec.workArea.referenceNode

        local sx, sy, sz = localToWorld(outputNode, -halfWidth, 0, -halfLength + offsetZ)
        local ex, ey, ez = localToWorld(outputNode, halfWidth, 0, halfLength + offsetZ)

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
    local fillTypeIndex, conversionFactor = self:getDischargeFillType(spec.dischargeNode)
    local fillLevel = self:getFillUnitFillLevel(spec.dischargeNode.fillUnitIndex)
    local minLiterToDrop = g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex)

    spec.dischargeNode.litersToDrop = math.min(spec.dischargeNode.litersToDrop + emptyLiters, math.max(spec.dischargeNode.emptySpeed * 250, minLiterToDrop))

    local minDropReached = minLiterToDrop < spec.dischargeNode.litersToDrop
    local hasMinDropFillLevel = minLiterToDrop < fillLevel
    local dischargedLiters = 0

    local dropped = spec.workArea:output(spec.outputMode, spec.dischargeNode.litersToDrop * conversionFactor, fillTypeIndex)

    dropped = dropped / conversionFactor
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
        if spec.state.drivingDirectionMode == DrivingDirectionMode.FORWARDS then
            return Machine.getDrivingDirection(self) > 0
        elseif spec.state.drivingDirectionMode == DrivingDirectionMode.BACKWARDS then
            return Machine.getDrivingDirection(self) < 0
        elseif spec.state.drivingDirectionMode == DrivingDirectionMode.BOTH then
            return Machine.getDrivingDirection(self) ~= 0
        else
            return true
        end
    end

    return false
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
    return ModUtils.getPlayerHasPermission('landscaping')
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
        spec.workArea:update()
    end

    if self.isServer then
        if self:getIsAvailable() then
            if spec.workArea.isAreaNodeActive and spec.lastIntervalUpdate >= spec.updateInterval then
                spec.workArea:input(spec.inputMode)
                spec.lastIntervalUpdate = 0
            else
                spec.lastIntervalUpdate = spec.lastIntervalUpdate + dt
            end

            self:setMachineEffectActive(spec.workArea.isAreaNodeActive)
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
            ---@type DrivableVehicle?
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
    local state = self:getMachineState()

    if self.isServer and state.autoDeactivate then
        self:setMachineActive(false)
    end
end

function Machine:onLeaveRootVehicle()
    local state = self:getMachineState()

    if self.isServer and state.autoDeactivate then
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
        if not spec.state.autoDeactivate and g_currentMission.missionInfo.automaticMotorStartEnabled and self.getIsControlled ~= nil and not self:getIsControlled() then
            return
        end

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

        streamWriteBool(streamId, spec.enabled)
        streamWriteBool(streamId, spec.resourcesEnabled)
        streamWriteBool(streamId, spec.active)
        streamWriteUIntN(streamId, spec.inputMode, Machine.NUM_BITS_MODE)
        streamWriteUIntN(streamId, spec.outputMode, Machine.NUM_BITS_MODE)
        streamWriteUIntN(streamId, spec.fillTypeIndex or 0, FillTypeManager.SEND_NUM_BITS)
        streamWriteUIntN(streamId, spec.inputTerrainLayerId or 0, TerrainDeformation.LAYER_SEND_NUM_BITS)
        streamWriteUIntN(streamId, spec.outputTerrainLayerId or 0, TerrainDeformation.LAYER_SEND_NUM_BITS)
        streamWriteBool(streamId, spec.inputAreaEnabled)
        streamWriteBool(streamId, spec.outputAreaEnabled)

        if streamWriteBool(streamId, spec.inputAreaId ~= nil) then
            streamWriteString(streamId, spec.inputAreaId)
        end

        if streamWriteBool(streamId, spec.outputAreaId ~= nil) then
            streamWriteString(streamId, spec.outputAreaId)
        end

        spec.state:writeStream(streamId, connection)
    end
end

---@param streamId number
---@param connection Connection
function Machine:onReadStream(streamId, connection)
    local spec = self.spec_machine

    if connection:getIsServer() then
        self:setMachineEffectActive(streamReadBool(streamId), true, true)

        self:setMachineEnabled(streamReadBool(streamId), true)
        self:setResourcesEnabled(streamReadBool(streamId), true)
        self:setMachineActive(streamReadBool(streamId), true)
        self:setInputMode(streamReadUIntN(streamId, Machine.NUM_BITS_MODE), true)
        self:setOutputMode(streamReadUIntN(streamId, Machine.NUM_BITS_MODE), true)
        self:setMachineFillTypeIndex(streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS), true)
        self:setMachineInputLayerId(streamReadUIntN(streamId, TerrainDeformation.LAYER_SEND_NUM_BITS), true)
        self:setMachineOutputLayerId(streamReadUIntN(streamId, TerrainDeformation.LAYER_SEND_NUM_BITS), true)

        spec.inputAreaEnabled = streamReadBool(streamId)
        spec.outputAreaEnabled = streamReadBool(streamId)

        if streamReadBool(streamId) then
            spec.inputAreaId = streamReadString(streamId)
        else
            spec.inputAreaId = nil
        end

        if streamReadBool(streamId) then
            spec.outputAreaId = streamReadString(streamId)
        else
            spec.outputAreaId = nil
        end

        spec.state:readStream(streamId, connection)

        Machine.updateCollisionNodes(self)
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

        if MachineUtils.getHasInputs(self) then
            action = InputAction[Machine.ACTION_SELECT_INPUT_AREA]

            if action ~= nil then
                local _, eventId = self:addActionEvent(spec.actionEvents, action, self, Machine.actionEventSelectInputArea, false, true, false, true)

                g_inputBinding:setActionEventText(eventId, Machine.L10N_ACTION_SELECT_INPUT_AREA)
                g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_LOW)
            end

            action = InputAction[Machine.ACTION_TOGGLE_INPUT_AREA_STATE]

            if action ~= nil then
                local _, eventId = self:addActionEvent(spec.actionEvents, action, self, Machine.actionEventToggleInputAreaState, false, true, false, true)

                g_inputBinding:setActionEventText(eventId, Machine.L10N_ACTION_TOGGLE_INPUT_AREA_STATE)
                g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_LOW)
            end
        end

        if MachineUtils.getHasOutputs(self) then
            action = InputAction[Machine.ACTION_SELECT_OUTPUT_AREA]

            if action ~= nil then
                local _, eventId = self:addActionEvent(spec.actionEvents, action, self, Machine.actionEventSelectOutputArea, false, true, false, true)

                g_inputBinding:setActionEventText(eventId, Machine.L10N_ACTION_SELECT_OUTPUT_AREA)
                g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_LOW)
            end

            action = InputAction[Machine.ACTION_TOGGLE_OUTPUT_AREA_STATE]

            if action ~= nil then
                local _, eventId = self:addActionEvent(spec.actionEvents, action, self, Machine.actionEventToggleOutputAreaState, false, true, false, true)

                g_inputBinding:setActionEventText(eventId, Machine.L10N_ACTION_TOGGLE_OUTPUT_AREA_STATE)
                g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_LOW)
            end
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

        action = InputAction[Machine.ACTION_GLOBAL_TOGGLE_BORDER]

        if action ~= nil then
            local _, eventId = self:addActionEvent(spec.actionEvents, action, self, Machine.actionEventToggleGlobalBorder, false, true, false, true)

            g_inputBinding:setActionEventText(eventId, Machine.L10N_ACTION_TOGGLE_GLOBAL_BORDER)
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

function Machine:actionEventToggleGlobalBorder()
    local visibilityMode = g_landscapingManager.borderVisibilityMode

    if visibilityMode == BorderVisibilityMode.ALL then
        g_landscapingManager:setBorderVisibilityMode(BorderVisibilityMode.ACTIVE_ONLY)
    elseif visibilityMode == BorderVisibilityMode.ACTIVE_ONLY then
        g_landscapingManager:setBorderVisibilityMode(BorderVisibilityMode.NONE)
    else
        g_landscapingManager:setBorderVisibilityMode(BorderVisibilityMode.ALL)
    end
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

---@param fillTypeIndex number?
---@param clickOk boolean
function Machine:selectMaterialCallback(fillTypeIndex, clickOk)
    if clickOk and fillTypeIndex ~= nil then
        self:setMachineFillTypeIndex(fillTypeIndex)
    end
end

function Machine:actionEventSelectTerrainLayer()
    local spec = self.spec_machine

    g_selectTerrainLayerDialog:setSelectCallback(Machine.selectTerrainLayerCallback, self)
    g_selectTerrainLayerDialog:show(spec.inputTerrainLayerId)
end

---@param terrainLayerId number?
---@param clickOk boolean
function Machine:selectTerrainLayerCallback(terrainLayerId, clickOk)
    if clickOk and terrainLayerId ~= nil then
        self:setMachineInputLayerId(terrainLayerId)
    end
end

function Machine:actionEventSelectDischargeTerrainLayer()
    local spec = self.spec_machine

    g_selectTerrainLayerDialog:setSelectCallback(Machine.selectDischargeTerrainLayerCallback, self)
    g_selectTerrainLayerDialog:show(spec.outputTerrainLayerId, g_i18n:getText('ui_changeDischargeTexture'))
end

---@param terrainLayerId number?
---@param clickOk boolean
function Machine:selectDischargeTerrainLayerCallback(terrainLayerId, clickOk)
    if clickOk and terrainLayerId ~= nil then
        self:setMachineOutputLayerId(terrainLayerId)
    end
end

function Machine:actionEventSelectInputArea()
    local spec = self.spec_machine

    g_selectAreaDialog:setSelectCallback(Machine.selectInputAreaCallback, self)
    g_selectAreaDialog:show(spec.inputAreaId, Machine.L10N_ACTION_SELECT_INPUT_AREA)
end

---@param id? string
---@param clickOk boolean
function Machine:selectInputAreaCallback(id, clickOk)
    if clickOk and id ~= nil then
        self:setMachineInputAreaId(id)
    end
end

function Machine:actionEventToggleInputAreaState()
    local spec = self.spec_machine

    self:setIsMachineInputAreaEnabled(not spec.inputAreaEnabled)
end

function Machine:actionEventSelectOutputArea()
    local spec = self.spec_machine

    g_selectAreaDialog:setSelectCallback(Machine.selectOutputAreaCallback, self)
    g_selectAreaDialog:show(spec.outputAreaId, Machine.L10N_ACTION_SELECT_OUTPUT_AREA)
end

---@param id? string
---@param clickOk boolean
function Machine:selectOutputAreaCallback(id, clickOk)
    if clickOk and id ~= nil then
        self:setMachineOutputAreaId(id)
    end
end

function Machine:actionEventToggleOutputAreaState()
    local spec = self.spec_machine

    self:setIsMachineOutputAreaEnabled(not spec.outputAreaEnabled)
end

function Machine:actionEventGlobalSettings()
    g_globalSettingsDialog:show()
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
        elseif spec.machineType.useDischargeable and g_modSettings:getIsEnabled() and self:getMachineEnabled() then
            if self:getMachineActive() then
                if spec.outputMode == Machine.MODE.PAINT then
                    return true
                end

                return spec.workArea:getCanOutputToTerrain()
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
