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
                Logging.xmlWarning(xmlFile, 'Invalid mode "%s" (%s)', strMode, key)
            end
        end
    end

    return modes
end

---@param xmlFile XMLFile
---@param key string
---@param vehicle Vehicle
---@return number[]?
function MachineUtils.loadUpdateCollisionNodesFromXML(xmlFile, key, vehicle)
    local nodes = {}

    xmlFile:iterate(key, function (_, itemKey)
        local node = xmlFile:getValue(itemKey .. '#node', nil, vehicle.components, vehicle.i3dMappings)

        if node ~= nil then
            table.insert(nodes, node)
        end
    end)

    if #nodes > 0 then
        return nodes
    end
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

---@param vehicle Machine
---@param mode MachineMode
---@return boolean
---@nodiscard
function MachineUtils.getHasInputMode(vehicle, mode)
    local spec = vehicle.spec_machine

    return table.find(spec.modesInput, mode) ~= nil
end

---@param vehicle Machine
---@param mode MachineMode
---@return boolean
---@nodiscard
function MachineUtils.getHasOutputMode(vehicle, mode)
    local spec = vehicle.spec_machine

    return table.find(spec.modesOutput, mode) ~= nil
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

---@param liters number
---@param fillTypeIndex number
---@param workArea MachineWorkArea
function MachineUtils.tipToGroundOverflow(liters, fillTypeIndex, workArea)
    local offsetZ = 1
    local halfWidth = workArea.width / 2
    local outputNode = workArea.outputNode or workArea.referenceNode
    local vehicle = workArea.vehicle

    local levelerNode = vehicle.spec_machine.levelerNode

    if levelerNode ~= nil then
        offsetZ = levelerNode.zOffset
    end

    local sx, sy, sz = localToWorld(outputNode, -halfWidth, 0, offsetZ)
    local ex, ey, ez = localToWorld(outputNode, halfWidth, 0, offsetZ)

    DensityMapHeightUtil.tipToGroundAroundLine(
        nil, liters, fillTypeIndex,
        sx, sy, sz, ex, ey, ez,
        0.5, 1, 0, false
    )
end

---@param liters number
---@param fillTypeIndex number
---@param workArea MachineWorkArea
function MachineUtils.tipToGroundRipper(liters, fillTypeIndex, workArea)
    local offsetZ = -1
    local halfLength = 1
    local halfWidth = 1
    local outputNode = workArea.outputNode or workArea.referenceNode

    local sx, sy, sz = localToWorld(outputNode, -halfWidth, 0, -halfLength + offsetZ)
    local ex, ey, ez = localToWorld(outputNode, halfWidth, 0, halfLength + offsetZ)

    DensityMapHeightUtil.tipToGroundAroundLine(
        workArea.vehicle, liters, fillTypeIndex,
        sx, sy, sz, ex, ey, ez,
        0.5, 2, 0, false
    )
end
