---@class InteractiveFunctions
---@field addFunction fun(name: string, params: InteractiveFunctionsParams)

---@class InteractiveFunctionsParams
---@field posFunc fun(target: Machine, data: any, noEventSend: boolean | nil)
---@field negFunc? fun(target: Machine, data: any, noEventSend: boolean | nil)
---@field updateFunc? fun(target: Machine): boolean | nil
---@field isBlockedFunc? fun(target: Machine): boolean

---@class InteractiveControlExtension
InteractiveControlExtension = {}

local InteractiveControlExtension_mt = Class(InteractiveControlExtension)

---@return InteractiveControlExtension
---@nodiscard
function InteractiveControlExtension.new()
    ---@type InteractiveControlExtension
    local self = setmetatable({}, InteractiveControlExtension_mt)

    return self
end

function InteractiveControlExtension:onModsLoaded()
    local modName = 'FS25_interactiveControl'

    if g_modIsLoaded[modName] then
        local modEnv = _G[modName]
        ---@type InteractiveFunctions | nil
        local InteractiveFunctions = modEnv['InteractiveFunctions']

        if InteractiveFunctions ~= nil then
            g_modDebug:debug('"FS25_interactiveControl" mod is active, adding new functions')

            self:registerToggleEnabledFunction(InteractiveFunctions)
            self:registerToggleActiveFunction(InteractiveFunctions)
            self:registerToggleHudFunction(InteractiveFunctions)
            self:registerToggleInputFunction(InteractiveFunctions)
            self:registerToggleOutputFunction(InteractiveFunctions)
            self:registerSettingsFunction(InteractiveFunctions)
            self:registerMaterialFunction(InteractiveFunctions)
            self:registerTextureFunction(InteractiveFunctions)
            self:registerDischargeTextureFunction(InteractiveFunctions)
            self:registerSelectSurveyorFunction(InteractiveFunctions)
        end
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerToggleEnabledFunction(icf)
    if icf.addFunction('MACHINE_TOGGLE_ENABLED',
            {
                posFunc = function ()
                    local vehicle = g_machineManager.activeVehicle

                    if vehicle ~= nil then
                        vehicle:setMachineEnabled(true)
                    end
                end,
                negFunc = function ()
                    local vehicle = g_machineManager.activeVehicle

                    if vehicle ~= nil then
                        vehicle:setMachineEnabled(false)
                    end
                end,
                updateFunc = function ()
                    local vehicle = g_machineManager.activeVehicle

                    if vehicle ~= nil then
                        return vehicle:getMachineEnabled()
                    end
                end,
                isBlockedFunc = function ()
                    if g_machineManager.activeVehicle ~= nil then
                        return MachineUtils.getPlayerHasPermission('manageRights')
                    end

                    return false
                end
            }
        ) then
        g_modDebug:debug('Registered interactiveControl function "MACHINE_TOGGLE_ENABLED"')
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerToggleActiveFunction(icf)
    if icf.addFunction('MACHINE_TOGGLE_ACTIVE',
            {
                posFunc = function ()
                    local vehicle = g_machineManager.activeVehicle

                    if vehicle ~= nil and vehicle:getCanActivateMachine() then
                        vehicle:setMachineActive(true)
                    end
                end,
                negFunc = function ()
                    local vehicle = g_machineManager.activeVehicle

                    if vehicle ~= nil and vehicle:getCanActivateMachine() then
                        vehicle:setMachineActive(false)
                    end
                end,
                updateFunc = function ()
                    local vehicle = g_machineManager.activeVehicle

                    if vehicle ~= nil then
                        return vehicle:getMachineActive()
                    end
                end,
                isBlockedFunc = function ()
                    local vehicle = g_machineManager.activeVehicle

                    if vehicle ~= nil then
                        return vehicle:getCanActivateMachine()
                    end

                    return false
                end
            }
        ) then
        g_modDebug:debug('Registered interactiveControl function "MACHINE_TOGGLE_ACTIVE"')
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerToggleHudFunction(icf)
    if icf.addFunction('MACHINE_TOGGLE_HUD',
            {
                posFunc = function ()
                    g_modHud.display:setVisible(not g_modHud.display.isVisible, true)
                end,
                updateFunc = function ()
                    return g_modHud.display.isVisible
                end,
                isBlockedFunc = function ()
                    return g_machineManager.activeVehicle ~= nil
                end
            }
        ) then
        g_modDebug:debug('Registered interactiveControl function "MACHINE_TOGGLE_HUD"')
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerToggleInputFunction(icf)
    if icf.addFunction('MACHINE_TOGGLE_INPUT',
            {
                posFunc = function ()
                    local vehicle = g_machineManager.activeVehicle

                    if vehicle ~= nil then
                        Machine.actionEventToggleInput(vehicle)
                    end
                end,
                isBlockedFunc = function ()
                    local vehicle = g_machineManager.activeVehicle

                    if vehicle ~= nil then
                        return vehicle:getCanAccessMachine() and MachineUtils.getNumInputs(vehicle) > 1
                    end

                    return false
                end
            }
        ) then
        g_modDebug:debug('Registered interactiveControl function "MACHINE_TOGGLE_INPUT"')
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerToggleOutputFunction(icf)
    if icf.addFunction('MACHINE_TOGGLE_OUTPUT',
            {
                posFunc = function ()
                    local vehicle = g_machineManager.activeVehicle

                    if vehicle ~= nil then
                        Machine.actionEventToggleOutput(vehicle)
                    end
                end,
                isBlockedFunc = function ()
                    local vehicle = g_machineManager.activeVehicle

                    if vehicle ~= nil then
                        return vehicle:getCanAccessMachine() and MachineUtils.getNumOutputs(vehicle) > 1
                    end

                    return false
                end
            }
        ) then
        g_modDebug:debug('Registered interactiveControl function "MACHINE_TOGGLE_OUTPUT"')
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerSettingsFunction(icf)
    if icf.addFunction('MACHINE_SETTINGS',
            {
                posFunc = function ()
                    local vehicle = g_machineManager.activeVehicle

                    if vehicle ~= nil then
                        Machine.actionEventMachineDialog(vehicle)
                    end
                end,
                isBlockedFunc = function ()
                    local vehicle = g_machineManager.activeVehicle

                    if vehicle ~= nil then
                        return vehicle:getCanAccessMachine()
                    end

                    return false
                end
            }
        ) then
        g_modDebug:debug('Registered interactiveControl function "MACHINE_SETTINGS"')
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerMaterialFunction(icf)
    if icf.addFunction('MACHINE_SELECT_MATERIAL',
            {
                posFunc = function ()
                    local vehicle = g_machineManager.activeVehicle

                    if vehicle ~= nil then
                        Machine.actionEventSelectMaterial(vehicle)
                    end
                end,
                isBlockedFunc = function ()
                    local vehicle = g_machineManager.activeVehicle

                    if vehicle ~= nil then
                        return vehicle:getCanAccessMachine()
                    end

                    return false
                end
            }
        ) then
        g_modDebug:debug('Registered interactiveControl function "MACHINE_SELECT_MATERIAL"')
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerTextureFunction(icf)
    if icf.addFunction('MACHINE_SELECT_TEXTURE',
            {
                posFunc = function ()
                    local vehicle = g_machineManager.activeVehicle

                    if vehicle ~= nil then
                        Machine.actionEventSelectTerrainLayer(vehicle)
                    end
                end,
                isBlockedFunc = function ()
                    local vehicle = g_machineManager.activeVehicle
                    if vehicle ~= nil then
                        return vehicle:getCanAccessMachine() and #vehicle.spec_machine.modesInput > 0
                    end

                    return false
                end
            }
        ) then
        g_modDebug:debug('Registered interactiveControl function "MACHINE_SELECT_TEXTURE"')
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerDischargeTextureFunction(icf)
    if icf.addFunction('MACHINE_SELECT_DISCHARGE_TEXTURE',
            {
                posFunc = function ()
                    local vehicle = g_machineManager.activeVehicle

                    if vehicle ~= nil then
                        Machine.actionEventSelectDischargeTerrainLayer(vehicle)
                    end
                end,
                isBlockedFunc = function ()
                    local vehicle = g_machineManager.activeVehicle
                    if vehicle ~= nil then
                        return vehicle:getCanAccessMachine() and #vehicle.spec_machine.modesOutput > 0
                    end

                    return false
                end
            }
        ) then
        g_modDebug:debug('Registered interactiveControl function "MACHINE_SELECT_DISCHARGE_TEXTURE"')
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerSelectSurveyorFunction(icf)
    if icf.addFunction('MACHINE_SELECT_SURVEYOR',
            {
                posFunc = function ()
                    local vehicle = g_machineManager.activeVehicle

                    if vehicle ~= nil then
                        Machine.actionEventSelectSurveyor(vehicle)
                    end
                end,
                isBlockedFunc = function ()
                    local vehicle = g_machineManager.activeVehicle

                    if vehicle ~= nil and vehicle:getCanAccessMachine() then
                        return MachineUtils.getHasInputMode(vehicle, Machine.MODE.FLATTEN) or MachineUtils.getHasOutputMode(vehicle, Machine.MODE.FLATTEN)
                    end

                    return false
                end
            }
        ) then
        g_modDebug:debug('Registered interactiveControl function "MACHINE_SELECT_SURVEYOR"')
    end
end

---@diagnostic disable-next-line: lowercase-global
g_interactiveControlExtension = InteractiveControlExtension.new()
