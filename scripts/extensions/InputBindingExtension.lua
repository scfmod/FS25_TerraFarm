--[[
    Make sure that input bindings are never outdated.
    Iterate bindings in modDesc.xml, delete any existing action binding
    entries and add action bindings loaded from XML file.

    Because there is no built-in persistent="false" (or similar) attribute in modDesc.xml for
    actions, FS will always save and restore bindings making it quite impossible
    to be able to update inputs for static actions between mod versions..
    So this for working around this problem.
]]

---@param xmlFile XMLFile
---@param key string
local function replaceInputBindingsFromXMLFile(xmlFile, key)
    local handle = xmlFile.handle

    xmlFile:iterate(key, function (_, actionBindingKey)
        local actionName = getXMLString(handle, actionBindingKey .. '#action')

        if actionName ~= nil and actionName:startsWith('AREA_EDITOR_') then
            ---@type InputAction?
            local action = g_inputBinding:getActionByName(actionName)

            if action ~= nil then
                local numBindings = #action.bindings

                for i = numBindings, 1, -1 do
                    local binding = action.bindings[i]

                    g_inputBinding:deleteBinding(binding.deviceId, action.name, binding.index, binding.axisComponent)

                    local lastAxisName = binding.axisNames[#binding.axisNames]

                    if InputBinding.getIsPhysicalFullAxis(lastAxisName) then
                        g_inputBinding:deleteBinding(binding.deviceId, action.name, binding.index, Binding.getOppositeAxisComponent(binding.axisComponent))
                    end
                end

                xmlFile:iterate(actionBindingKey .. '.binding', function (_, bindingKey)
                    local binding = Binding.createFromXML(xmlFile.handle, bindingKey)
                    g_inputBinding:addBinding(action, binding)
                end)
            end
        end
    end)
end

local xmlFile = XMLFile.loadIfExists('replaceBindingsModDesc', g_modDirectory .. 'modDesc.xml')

if xmlFile ~= nil then
    replaceInputBindingsFromXMLFile(xmlFile, 'modDesc.inputBinding.actionBinding')
    xmlFile:delete()
else
    Logging.error('replaceInputBindingsFromXMLFile() Failed to load modDesc.xml')
end
