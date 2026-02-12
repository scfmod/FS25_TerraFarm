---@param vehicle Vehicle
---@param eventName string
---@param spec any
local function registerEventListener(vehicle, eventName, spec)
    if vehicle.eventListeners[eventName] ~= nil then
        assert(spec[eventName] ~= nil, "Error: Event listener function '" .. tostring(eventName) .. "' not defined in specialization 'Machine'!")

        local wasFound = false

        for _, specEntry in pairs(vehicle.eventListeners[eventName]) do
            if specEntry == spec then
                wasFound = true
                break
            end
        end

        assert(not wasFound, "Error: Eventlistener for '" .. eventName .. "' already registered in specialization 'Machine'!")

        table.insert(vehicle.eventListeners[eventName], spec)
    end
end

---@param vehicle Vehicle
local function registerMachineFunctions(vehicle)
    vehicle['setMachineState'] = Machine.setMachineState
    vehicle['getMachineState'] = Machine.getMachineState

    vehicle['setMachineEnabled'] = Machine.setMachineEnabled
    vehicle['getMachineEnabled'] = Machine.getMachineEnabled
    vehicle['setMachineActive'] = Machine.setMachineActive
    vehicle['getMachineActive'] = Machine.getMachineActive
    vehicle['setMachineEffectActive'] = Machine.setMachineEffectActive
    vehicle['updateMachineSound'] = Machine.updateMachineSound

    vehicle['setInputMode'] = Machine.setInputMode
    vehicle['getInputMode'] = Machine.getInputMode
    vehicle['setOutputMode'] = Machine.setOutputMode
    vehicle['getOutputMode'] = Machine.getOutputMode

    vehicle['setMachineFillTypeIndex'] = Machine.setMachineFillTypeIndex
    vehicle['getMachineFillTypeIndex'] = Machine.getMachineFillTypeIndex

    vehicle['setMachineInputLayerId'] = Machine.setMachineInputLayerId
    vehicle['getMachineInputLayerId'] = Machine.getMachineInputLayerId
    vehicle['setMachineOutputLayerId'] = Machine.setMachineOutputLayerId
    vehicle['getMachineOutputLayerId'] = Machine.getMachineOutputLayerId

    vehicle['getCanAccessMachine'] = Machine.getCanAccessMachine
    vehicle['getCanActivateMachine'] = Machine.getCanActivateMachine
    vehicle['getIsAvailable'] = Machine.getIsAvailable
    vehicle['getIsFull'] = Machine.getIsFull

    vehicle['handleDeformationInput'] = Machine.handleDeformationInput
    vehicle['setResourcesEnabled'] = Machine.setResourcesEnabled

    vehicle['setSurveyorId'] = Machine.setSurveyorId
    vehicle['getSurveyorId'] = Machine.getSurveyorId
    vehicle['getSurveyor'] = Machine.getSurveyor
    vehicle['getSurveyorCalibration'] = Machine.getSurveyorCalibration
end

---@param vehicle Vehicle
local function registerMachineEventListeners(vehicle)
    registerEventListener(vehicle, 'onLoad', Machine)
    registerEventListener(vehicle, 'onPostLoad', Machine)
    registerEventListener(vehicle, 'onDelete', Machine)
    registerEventListener(vehicle, 'onUpdate', Machine)
    registerEventListener(vehicle, 'onUpdateTick', Machine)

    registerEventListener(vehicle, 'onRegisterActionEvents', Machine)

    registerEventListener(vehicle, 'onWriteStream', Machine)
    registerEventListener(vehicle, 'onReadStream', Machine)
    registerEventListener(vehicle, 'onWriteUpdateStream', Machine)
    registerEventListener(vehicle, 'onReadUpdateStream', Machine)
end

--[[

    PROPERTY_STATE_SHOP_CONFIG = 5

    VEHICLE_LOAD_OK = 1
    VEHICLE_LOAD_ERROR = 2
    VEHICLE_LOAD_DELAYED = 3
    VEHICLE_LOAD_NO_SPACE = 4
]]


---@param vehicle Vehicle
---@param superFunc any
---@param ... any
local function inj_Vehicle_load(vehicle, superFunc, vehicleData, ...)
    -- g_modDebug:debug('inj_Vehicle_load() propertyState: %s', tostring(vehicleData.propertyState))

    if vehicleData.propertyState == 5 then
        -- g_modDebug:debug('inj_Vehicle_load: propertyState is not valid for adding Machine specialization (%i)', vehicleData.propertyState)
        return superFunc(vehicle, vehicleData, ...)
    end

    local vehicleLoadingState = superFunc(vehicle, vehicleData, ...)

    -- g_modDebug:debug('inj_Vehicle_load() loadingState: %d', tostring(vehicle.loadingState))

    if vehicle.loadingState ~= 1 then
        -- g_modDebug:debug('inj_Vehicle_load: loadingState is not valid for adding Machine specialization (%i)', vehicle.loadingState)
        return
    end

    if SpecializationUtil.hasSpecialization(Machine, vehicle.specializations) then
        -- g_modDebug:debug('inj_Vehicle_load: Vehicle already has Machine specialization')
        return vehicleLoadingState
    end

    local xmlFilenameConfig, vehicleFile = MachineUtils.getVehicleConfiguration(vehicle)

    if xmlFilenameConfig == nil then
        g_modDebug:debug('No configuration found for "%s"', vehicleFile)
        return vehicleLoadingState
    else
        g_modDebug:debug('Found configuration for "%s"', vehicleFile)
    end

    -- g_modDebug:debug('inj_Vehicle_load: Trying to add Machine specialization to: %s', vehicle.configFileNameClean)

    local specEntryName = Machine.SPEC_NAME

    if vehicle[specEntryName] == nil then
        local specName = g_modName .. '.machine'
        local spec = g_specializationManager:getSpecializationObjectByName(specName)

        if spec ~= nil then
            -- g_modDebug:debug('inj_Vehicle_load: Found specialization object, adding to vehicle')

            -- Make sure we copy these tables in order to not alter the typeDef specializations
            vehicle.specializations = table.clone(vehicle.specializations)
            vehicle.specializationNames = table.clone(vehicle.specializationNames)
            vehicle.specializationsByName = table.clone(vehicle.specializationsByName)

            -- Add specialization to vehicle
            table.insert(vehicle.specializations, spec)
            table.insert(vehicle.specializationNames, specName)
            vehicle.specializationsByName[specName] = spec

            local env = {}

            setmetatable(env, {
                __index = vehicle
            })

            env.actionEvents = {}
            env.xmlFilenameConfig = xmlFilenameConfig
            env.isExternal = true

            vehicle[specEntryName] = env

            -- g_modDebug:debug('inj_Vehicle_load: Added Machine specialization to vehicle, registering ..')

            registerMachineFunctions(vehicle)
            -- registerMachineEvents(vehicle)
            registerMachineEventListeners(vehicle)

            -- g_modDebug:debug('inj_Vehicle_load: Registered specialization functions and events')
            -- g_modDebug:debug('Injected machine specialization to vehicle: %s', vehicleFile)
        else
            Logging.error('inj_Vehicle_load() Failed to find specialization object: "%s"', specEntryName)
        end
    else
        Logging.warning('inj_Vehicle_load() "%s" already added, skipping', specEntryName)
    end

    return vehicleLoadingState
end

Vehicle.load = Utils.overwrittenFunction(Vehicle.load, inj_Vehicle_load)
