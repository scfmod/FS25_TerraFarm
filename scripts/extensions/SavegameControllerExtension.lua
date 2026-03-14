local function post_SavegameController_onSaveComplete(self, errorCode)
    if errorCode == Savegame.ERROR_OK and g_modSettings ~= nil then
        pcall(function ()
            g_modSettings:saveSettings()
            g_landscapingManager:saveAreasToXML()
        end)
    end
end

SavegameController.onSaveComplete = Utils.appendedFunction(SavegameController.onSaveComplete, post_SavegameController_onSaveComplete)
