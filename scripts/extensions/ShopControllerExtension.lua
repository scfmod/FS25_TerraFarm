---@param self ShopController
---@param superFunc function
---@param storeItem StoreItem
---@param realItem any
---@param configurations any
---@param saleItem any
---@return ShopDisplayItem
local function inj_ShopController_makeDisplayItem(self, superFunc, storeItem, realItem, configurations, saleItem)
    ---@type ShopDisplayItem
    local displayItem = superFunc(self, storeItem, realItem, configurations, saleItem)

    ---@diagnostic disable-next-line: undefined-global
    if storeItem.species == StoreSpecies.VEHICLE and (storeItem.specs == nil or storeItem.specs.machine == nil) then
        local xmlFilename = MachineUtils.getStoreItemModFilename(storeItem)

        if xmlFilename ~= nil then
            local xmlFilenameConfig = g_machineManager:getConfigurationXMLFilename(xmlFilename)

            if xmlFilenameConfig ~= nil then
                table.insert(displayItem.attributeIconProfiles, 'tf_shopListAttributeIconMachine')
                table.insert(displayItem.attributeValues, g_i18n:getText('displayItem_machine'))
            end
        end
    end

    return displayItem
end

ShopController.makeDisplayItem = Utils.overwrittenFunction(ShopController.makeDisplayItem, inj_ShopController_makeDisplayItem)
