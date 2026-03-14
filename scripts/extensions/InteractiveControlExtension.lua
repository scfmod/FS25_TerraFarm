---@class InteractiveFunctions
---@field addFunction fun(name: string, params: InteractiveFunctionsParams)

---@class InteractiveFunctionsParams
---@field posFunc fun(target: Machine, data: any, noEventSend: boolean?)
---@field negFunc? fun(target: Machine, data: any, noEventSend: boolean?)
---@field updateFunc? fun(target: Machine): boolean?
---@field isBlockedFunc? fun(target: Machine): boolean?

---@class InteractiveControlExtension
InteractiveControlExtension = {}

local InteractiveControlExtension_mt = Class(InteractiveControlExtension)

---@return InteractiveControlExtension
---@nodiscard
function InteractiveControlExtension.new()
    ---@type InteractiveControlExtension
    local self = setmetatable({}, InteractiveControlExtension_mt)

    g_modController:subscribe(ModEvent.onModsLoaded, self.onModsLoaded, self)

    return self
end

function InteractiveControlExtension:onModsLoaded()
    local modName = 'FS25_interactiveControl'

    if g_modIsLoaded[modName] then
        local modEnv = _G[modName]
        ---@type InteractiveFunctions?
        local InteractiveFunctions = modEnv['InteractiveFunctions']

        if InteractiveFunctions ~= nil then
            g_modController:debug('"FS25_interactiveControl" mod is active, adding new functions')

            self:registerToggleEnabledFunction(InteractiveFunctions)
            self:registerToggleActiveFunction(InteractiveFunctions)
            self:registerToggleHudFunction(InteractiveFunctions)
            self:registerToggleInputFunction(InteractiveFunctions)
            self:registerToggleOutputFunction(InteractiveFunctions)
            self:registerSettingsFunction(InteractiveFunctions)
            self:registerMaterialFunction(InteractiveFunctions)
            self:registerTextureFunction(InteractiveFunctions)
            self:registerDischargeTextureFunction(InteractiveFunctions)
        end
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerToggleEnabledFunction(icf)
    if icf.addFunction('MACHINE_TOGGLE_ENABLED',
            {
                posFunc = function (target, data, noEventSend)
                    if noEventSend then
                        return
                    end

                    local vehicle = g_machineManager.activeVehicle or target

                    if vehicle.setMachineEnabled ~= nil then
                        vehicle:setMachineEnabled(true)
                    end
                end,
                negFunc = function (target, data, noEventSend)
                    if noEventSend then
                        return
                    end

                    local vehicle = g_machineManager.activeVehicle or target

                    if vehicle.setMachineEnabled ~= nil then
                        vehicle:setMachineEnabled(false)
                    end
                end,
                updateFunc = function (target)
                    local vehicle = g_machineManager.activeVehicle or target

                    if vehicle.getMachineEnabled ~= nil then
                        return vehicle:getMachineEnabled()
                    end
                end,
                isBlockedFunc = function (target)
                    local vehicle = g_machineManager.activeVehicle or target

                    if vehicle.getMachineEnabled ~= nil then
                        return ModUtils.getPlayerHasPermission('manageRights')
                    end
                end
            }
        ) then
        g_modController:debug('Registered interactiveControl function "MACHINE_TOGGLE_ENABLED"')
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerToggleActiveFunction(icf)
    if icf.addFunction('MACHINE_TOGGLE_ACTIVE',
            {
                posFunc = function (target, data, noEventSend)
                    if noEventSend then
                        return
                    end

                    local vehicle = g_machineManager.activeVehicle or target

                    if vehicle.getCanActivateMachine ~= nil and vehicle:getCanActivateMachine() then
                        vehicle:setMachineActive(true)
                    end
                end,
                negFunc = function (target, data, noEventSend)
                    if noEventSend then
                        return
                    end

                    local vehicle = g_machineManager.activeVehicle or target

                    if vehicle.getCanActivateMachine ~= nil and vehicle:getCanActivateMachine() then
                        vehicle:setMachineActive(false)
                    end
                end,
                updateFunc = function (target)
                    local vehicle = g_machineManager.activeVehicle or target

                    if vehicle.getMachineActive ~= nil then
                        return vehicle:getMachineActive()
                    end
                end,
                isBlockedFunc = function (target)
                    local vehicle = g_machineManager.activeVehicle or target

                    if vehicle.getCanActivateMachine ~= nil then
                        return vehicle:getCanActivateMachine()
                    end
                end
            }
        ) then
        g_modController:debug('Registered interactiveControl function "MACHINE_TOGGLE_ACTIVE"')
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerToggleHudFunction(icf)
    if icf.addFunction('MACHINE_TOGGLE_HUD',
            {
                posFunc = function (target, data, noEventSend)
                    if noEventSend then
                        return
                    end

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
        g_modController:debug('Registered interactiveControl function "MACHINE_TOGGLE_HUD"')
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerToggleInputFunction(icf)
    if icf.addFunction('MACHINE_TOGGLE_INPUT',
            {
                posFunc = function (target, data, noEventSend)
                    if noEventSend then
                        return
                    end

                    local vehicle = g_machineManager.activeVehicle or target

                    if vehicle.getCanAccessMachine ~= nil then
                        Machine.actionEventToggleInput(vehicle)
                    end
                end,
                isBlockedFunc = function (target)
                    local vehicle = g_machineManager.activeVehicle or target

                    if vehicle.getCanAccessMachine ~= nil then
                        return vehicle:getCanAccessMachine() and MachineUtils.getNumInputs(vehicle) > 1
                    end
                end
            }
        ) then
        g_modController:debug('Registered interactiveControl function "MACHINE_TOGGLE_INPUT"')
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerToggleOutputFunction(icf)
    if icf.addFunction('MACHINE_TOGGLE_OUTPUT',
            {
                posFunc = function (target, data, noEventSend)
                    if noEventSend then
                        return
                    end

                    local vehicle = g_machineManager.activeVehicle or target

                    if vehicle.getCanAccessMachine ~= nil then
                        Machine.actionEventToggleOutput(vehicle)
                    end
                end,
                isBlockedFunc = function (target)
                    local vehicle = g_machineManager.activeVehicle or target

                    if vehicle.getCanAccessMachine ~= nil then
                        return vehicle:getCanAccessMachine() and MachineUtils.getNumOutputs(vehicle) > 1
                    end
                end
            }
        ) then
        g_modController:debug('Registered interactiveControl function "MACHINE_TOGGLE_OUTPUT"')
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerSettingsFunction(icf)
    if icf.addFunction('MACHINE_SETTINGS',
            {
                posFunc = function (target, data, noEventSend)
                    if noEventSend then
                        return
                    end

                    local vehicle = g_machineManager.activeVehicle or target

                    if vehicle.getCanAccessMachine ~= nil then
                        Machine.actionEventMachineDialog(vehicle)
                    end
                end,
                isBlockedFunc = function (target)
                    local vehicle = g_machineManager.activeVehicle or target

                    if vehicle.getCanAccessMachine ~= nil then
                        return vehicle:getCanAccessMachine()
                    end
                end
            }
        ) then
        g_modController:debug('Registered interactiveControl function "MACHINE_SETTINGS"')
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerMaterialFunction(icf)
    if icf.addFunction('MACHINE_SELECT_MATERIAL',
            {
                posFunc = function (target, data, noEventSend)
                    if noEventSend then
                        return
                    end

                    local vehicle = g_machineManager.activeVehicle or target

                    if vehicle.getCanAccessMachine ~= nil then
                        Machine.actionEventSelectMaterial(vehicle)
                    end
                end,
                isBlockedFunc = function (target)
                    local vehicle = g_machineManager.activeVehicle or target

                    if vehicle.getCanAccessMachine ~= nil then
                        return vehicle:getCanAccessMachine()
                    end
                end
            }
        ) then
        g_modController:debug('Registered interactiveControl function "MACHINE_SELECT_MATERIAL"')
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerTextureFunction(icf)
    if icf.addFunction('MACHINE_SELECT_TEXTURE',
            {
                posFunc = function (target, data, noEventSend)
                    if noEventSend then
                        return
                    end

                    local vehicle = g_machineManager.activeVehicle or target

                    if vehicle.getCanAccessMachine ~= nil then
                        Machine.actionEventSelectTerrainLayer(vehicle)
                    end
                end,
                isBlockedFunc = function (target)
                    local vehicle = g_machineManager.activeVehicle or target

                    if vehicle.getCanAccessMachine ~= nil then
                        return vehicle:getCanAccessMachine() and #vehicle.spec_machine.modesInput > 0
                    end
                end
            }
        ) then
        g_modController:debug('Registered interactiveControl function "MACHINE_SELECT_TEXTURE"')
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerDischargeTextureFunction(icf)
    if icf.addFunction('MACHINE_SELECT_DISCHARGE_TEXTURE',
            {
                posFunc = function (target, data, noEventSend)
                    if noEventSend then
                        return
                    end

                    local vehicle = g_machineManager.activeVehicle or target

                    if vehicle.getCanAccessMachine ~= nil then
                        Machine.actionEventSelectDischargeTerrainLayer(vehicle)
                    end
                end,
                isBlockedFunc = function (target)
                    local vehicle = g_machineManager.activeVehicle or target

                    if vehicle.getCanAccessMachine ~= nil then
                        return vehicle:getCanAccessMachine() and #vehicle.spec_machine.modesOutput > 0
                    end
                end
            }
        ) then
        g_modController:debug('Registered interactiveControl function "MACHINE_SELECT_DISCHARGE_TEXTURE"')
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerSelectAreaFunction(icf)
    if icf.addFunction('MACHINE_SELECT_AREA', {
            posFunc = function (target, data, noEventSend)
                if noEventSend then
                    return
                end

                local vehicle = g_machineManager.activeVehicle or target

                if vehicle.getCanAccessMachine ~= nil then
                    Machine.actionEventSelectArea(vehicle)
                end
            end,
            isBlockedFunc = function (target)
                local vehicle = g_machineManager.activeVehicle or target

                if vehicle.getCanAccessMachine ~= nil and vehicle:getCanAccessMachine() then
                    return true
                end
            end
        }) then
        g_modController:debug('Registered interactiveControl function "MACHINE_SELECT_AREA"')
    end
end

---@diagnostic disable-next-line: lowercase-global
g_interactiveControlExtension = InteractiveControlExtension.new()
