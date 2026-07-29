local function saveTerraFarmFile(filename, callback)
    local success, errorMessage = pcall(callback)

    if not success then
        local absFilename = ModUtils.getSavegameDirectoryFilename(filename) or filename
        Logging.error('Could not save TerraFarm data to "%s": %s', absFilename, tostring(errorMessage))
    end
end

local function post_SavegameController_onSaveComplete(self, errorCode)
    if errorCode == Savegame.ERROR_OK and g_modSettings ~= nil then
        saveTerraFarmFile('terraFarmSettings.xml', function ()
            g_modSettings:saveSettings()
        end)

        saveTerraFarmFile('terraFarmAreas.xml', function ()
            g_landscapingManager:saveAreasToXML()
        end)
    end
end

SavegameController.onSaveComplete = Utils.appendedFunction(SavegameController.onSaveComplete, post_SavegameController_onSaveComplete)
