---@class MachineUtils
MachineUtils = {}

---@param targetVehicle Machine
---@return Machine?
function MachineUtils.getActiveVehicle(targetVehicle)
    if targetVehicle == nil then
        return nil
    end

    ---@type Machine?
    local selectedVehicle = targetVehicle:getSelectedVehicle()

    if selectedVehicle == nil then
        return nil
    end

    if selectedVehicle.spec_machine ~= nil then
        return selectedVehicle
    end

    ---@type Machine
    ---@diagnostic disable-next-line: assign-type-mismatch
    local rootVehicle = selectedVehicle:findRootVehicle()

    ---@type Machine[]
    local childVehicles = rootVehicle:getChildVehicles()

    if #childVehicles == 0 then
        if rootVehicle.spec_machine ~= nil then
            return rootVehicle
        end
    else
        for _, vehicle in ipairs(childVehicles) do
            if vehicle.spec_machine ~= nil then
                if vehicle.spec_machine.hasAttachable then
                    if vehicle:getIsActiveForInput() then
                        return vehicle
                    end
                elseif vehicle:getIsActiveForInput(true) then
                    return vehicle
                end
            end
        end
    end

    return nil
end

---@param targetVehicle Machine
---@return Machine[]
---@nodiscard
function MachineUtils.getAvailableVehicles(targetVehicle)
    ---@type Machine[]
    local result = {}

    ---@type Machine
    ---@diagnostic disable-next-line: assign-type-mismatch
    local rootVehicle = targetVehicle:findRootVehicle()

    if rootVehicle.spec_machine ~= nil then
        table.insert(result, targetVehicle)
    end

    ---@type Machine[]
    local childVehicles = rootVehicle:getChildVehicles()

    for _, vehicle in ipairs(childVehicles) do
        if vehicle.spec_machine ~= nil then
            table.insert(result, vehicle)
        end
    end


    return result
end

---@param vehicle Machine
---@return number
---@nodiscard
function MachineUtils.getVehicleTargetHeight(vehicle)
    local spec = vehicle.spec_machine

    if spec.hasAttachable then
        ---@diagnostic disable-next-line: cast-local-type
        vehicle = vehicle:findRootVehicle()
    end

    local x, _, z = getWorldTranslation(vehicle.rootNode)

    return getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
end

---@return number worldPosX
---@return number worldPosY
---@return number worldPosZ
---@return number terrainHeight
function MachineUtils.getVehicleTargetWorldTerrainPosition(vehicle)
    local spec = vehicle.spec_machine

    if spec.hasAttachable then
        ---@diagnostic disable-next-line: cast-local-type
        vehicle = vehicle:findRootVehicle()
    end

    local x, y, z = getWorldTranslation(vehicle.rootNode)
    local terrainHeight = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)

    return x, y, z, terrainHeight
end

---@param vehicle Vehicle
---@return string? xmlFilename
---@return string modFilename
---@nodiscard
function MachineUtils.getVehicleConfiguration(vehicle)
    local modFilename = MachineUtils.getVehicleModFilename(vehicle)

    return g_machineManager:getConfigurationXMLFilename(modFilename), modFilename
end

---@param vehicle Vehicle
---@return string
---@nodiscard
function MachineUtils.getVehicleModFilename(vehicle)
    ---@type string
    local xmlFilename = vehicle.configFileName
    local modName, baseDirectory = Utils.getModNameAndBaseDirectory(xmlFilename)

    if baseDirectory == '' then
        return xmlFilename
    elseif modName ~= nil and modName:startsWith('pdlc') then
        return modName .. xmlFilename:sub(baseDirectory:len())
    else
        return xmlFilename:sub(g_modsDirectory:len() + 1)
    end
end

---@param storeItem StoreItem
function MachineUtils.getStoreItemModFilename(storeItem)
    if storeItem ~= nil and storeItem.xmlFilename ~= nil then
        local modName, baseDirectory = Utils.getModNameAndBaseDirectory(storeItem.xmlFilename)

        if baseDirectory == '' then
            return storeItem.xmlFilename
        elseif modName ~= nil and modName:startsWith('pdlc') then
            return modName .. storeItem.xmlFilename:sub(baseDirectory:len())
        else
            return storeItem.xmlFilename:sub(g_modsDirectory:len() + 1)
        end
    end
end

---@param vehicle Vehicle
---@param defaultText string?
---@return string
---@nodiscard
function MachineUtils.getVehicleFarmName(vehicle, defaultText)
    if vehicle ~= nil then
        local farm = g_farmManager:getFarmById(vehicle:getOwnerFarmId())

        if farm ~= nil then
            return farm.name
        end
    end

    return defaultText or 'Unknown'
end

---@param xmlFile XMLFile
---@param key string
---@return MachineMode[]
function MachineUtils.loadMachineModesFromXML(xmlFile, key)
    local modes = {}
    local str = xmlFile:getValue(key)

    if str ~= nil then
        local arr = str:split(' ')

        for _, strMode in ipairs(arr) do
            if Machine.MODE[strMode] ~= nil then
                table.insert(modes, Machine.MODE[strMode])
            else
                Logging.xmlWarning('Invalid mode "%s" (%s)', strMode, key)
            end
        end
    else
        -- Logging.xmlError(xmlFile, 'No modes defined (%s)', key)
    end

    return modes
end

---@param sVehicle Vehicle
---@param tVehicle Vehicle
---@return number
---@nodiscard
function MachineUtils.getVehiclesDistance(sVehicle, tVehicle)
    local sx, sy, sz = getWorldTranslation(sVehicle.rootNode)
    local tx, ty, tz = getWorldTranslation(tVehicle.rootNode)

    return ModUtils.getPointsDistance(sx, sy, sz, tx, ty, tz)
end

---@param vehicle Vehicle
---@return number worldPosX
---@return number worldPosY
---@return number worldPosZ
function MachineUtils.getVehicleTerrainHeight(vehicle)
    local worldPosX, _, worldPosZ = getWorldTranslation(vehicle.rootNode)
    local worldPosY = LandscapingUtils.getTerrainHeightAt(worldPosX, worldPosZ)

    return worldPosX, worldPosY, worldPosZ
end

---@param vehicle Machine
---@param mode MachineMode
---@return boolean
---@nodiscard
function MachineUtils.getHasInputMode(vehicle, mode)
    local spec = vehicle.spec_machine

    return table.hasElement(spec.modesInput, mode)
end

---@param vehicle Machine
---@param mode MachineMode
---@return boolean
---@nodiscard
function MachineUtils.getHasOutputMode(vehicle, mode)
    local spec = vehicle.spec_machine

    return table.hasElement(spec.modesOutput, mode)
end

---@param vehicle Machine
---@return boolean
---@nodiscard
function MachineUtils.getHasInputs(vehicle)
    local spec = vehicle.spec_machine

    return #spec.modesInput > 0
end

---@param vehicle Machine
---@return boolean
---@nodiscard
function MachineUtils.getHasOutputs(vehicle)
    local spec = vehicle.spec_machine

    return #spec.modesOutput > 0
end

---@param vehicle Machine
---@return number
---@nodiscard
function MachineUtils.getNumInputs(vehicle)
    local spec = vehicle.spec_machine

    return #spec.modesInput
end

---@param vehicle Machine
---@return number
---@nodiscard
function MachineUtils.getNumOutputs(vehicle)
    local spec = vehicle.spec_machine

    return #spec.modesOutput
end
